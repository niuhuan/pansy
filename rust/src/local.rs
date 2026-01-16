use crate::entities::property::{
    load_bool_property, load_i64_property, load_property, save_bool_property, save_i64_property,
    save_property,
};
use crate::pixirust::client::Client;
use crate::pixirust::entities::Token;
use anyhow::{Result, Ok};
use serde_derive::{Deserialize, Serialize};
use std::collections::HashMap;
use std::collections::hash_map::DefaultHasher;
use std::hash::Hasher;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tokio::sync::{Mutex, MutexGuard};
use tokio::sync::RwLock;

#[allow(dead_code)]
pub(crate) fn join_paths<P: AsRef<Path>>(paths: Vec<P>) -> String {
    match paths.len() {
        0 => String::default(),
        _ => {
            let mut path: PathBuf = PathBuf::new();
            for x in paths {
                path = path.join(x);
            }
            return path.to_str().unwrap().to_string();
        }
    }
}

lazy_static::lazy_static! {
    pub(crate) static ref TOKEN:Mutex<TokenPeriod> = Mutex::<TokenPeriod>::new(
        TokenPeriod{
            token:Token{
                access_token: String::default(),
                expires_in: 0,
                token_type: String::default(),
                scope: String::default(),
                refresh_token: String::default(),
                user: crate::pixirust::entities::TokenUser{
                    profile_image_urls: crate::pixirust::entities::TokenProfileImageUrls{
                        px_16x16: String::default(),
                        px_50x50: String::default(),
                        px_170x170: String::default(),
                    },
                    id: String::default(),
                    name: String::default(),
                    account: String::default(),
                    mail_address: String::default(),
                    is_premium: false,
                    x_restrict: 0,
                    is_mail_authorized: false,
                },
            },
            created_time:0,
        }
    );
    static ref IN_CHINA: Mutex<bool> = Mutex::new(false);
    static ref CLIENT: Arc<RwLock<Client>> = Arc::new(RwLock::new(Client::new()));
    static ref BYPASS_SNI_INITED: Mutex<bool> = Mutex::new(false);
    static ref BYPASS_SNI: RwLock<bool> = RwLock::new(false);
    static ref BYPASS_SNI_HOSTS: RwLock<HashMap<String,String>> = RwLock::new(HashMap::new());
    static ref HASH_LOCK: Vec<Mutex::<()>> = {
        let mut mutex_vec: Vec<Mutex::<()>>  = vec![];
        for _ in 0..16 {
            mutex_vec.push(Mutex::<()>::new(()));
        }
        mutex_vec
    };
}

#[derive(Debug, Deserialize, Serialize)]
pub struct TokenPeriod {
    pub token: Token,
    pub created_time: i64,
}

pub(crate) async fn hash_lock(url: &String) -> MutexGuard<'static, ()> {
    let mut s = DefaultHasher::new();
    s.write(url.as_bytes());
    HASH_LOCK[(s.finish() % 16) as usize].lock().await
}

/// 
/// param: auth_level:
///   -1: no auth
///    0: no auth or auth fail is ok
///    1: ok at no auth, but error at auth fail
///    2: must authed success
pub(crate) async fn client(auth_level: i32) -> Result<tokio::sync::RwLockReadGuard<'static, Client>> {
    if -1 == auth_level {
        return Ok(CLIENT.read().await);
    }
    let period = TOKEN.lock().await;
    if period.created_time == 0 {
        if auth_level == 2 {
            return Err(anyhow::Error::msg("no authed"));
        }
    }
    match reload_auth(period).await {
        Err(err) => {
            if auth_level >= 1 {
                return Err(err);
            }
        }
        _ => {}
    }
    Ok(CLIENT.read().await)
}

async fn reload_auth(mut period: tokio::sync::MutexGuard<'_, TokenPeriod>) -> Result<()> {
    let now = chrono::Local::now().timestamp_millis();
    let mut check_lock = CLIENT.write().await;
    if period.token.expires_in + period.created_time < now {
        let new_token = check_lock
            .refresh_token(&period.token.refresh_token)
            .await?;
        write_token(&new_token, &now).await;
        period.created_time = now;
        period.token = new_token;
        (*check_lock).access_token = period.token.access_token.clone();
    }
    drop(check_lock);
    Ok(())
}

async fn write_token(token: &Token, time: &i64) {
    save_property(
        "token.json".to_owned(),
        serde_json::to_string(token).unwrap(),
    )
    .await
    .unwrap();
    save_i64_property("token_time".to_owned(), time.clone())
        .await
        .unwrap();
}

pub(crate) async fn load_in_china() {
    let mut lock = IN_CHINA.lock().await;
    *lock = load_bool_property("in_china".to_owned()).await.unwrap();
}

pub(crate) async fn load_token() -> Result<bool> {
    let token_json_str = load_property("token.json".to_owned()).await?;
    if token_json_str == "" {
        return Ok(false);
    }
    let token: Token = serde_json::from_str(&token_json_str)?;
    let time: i64 = load_i64_property("token_time".to_string()).await?;
    // 读取完成
    let mut period = TOKEN.lock().await;
    period.token = token;
    period.created_time = time;
    CLIENT.write().await.access_token = period.token.access_token.clone();
    Ok(true)
}

pub(crate) async fn set_token(token: Token, time: i64) {
    write_token(&token, &time).await;
    // 读取完成
    let mut period = TOKEN.lock().await;
    period.token = token;
    period.created_time = time;
    CLIENT.write().await.access_token = period.token.access_token.clone();
}

pub(crate) async fn get_in_china_() -> bool {
    *(IN_CHINA.lock().await)
}

pub(crate) async fn set_in_china_(value: bool) {
    save_bool_property("in_china".to_owned(), value)
        .await
        .unwrap();
    let mut ic = IN_CHINA.lock().await;
    *ic = value;
    // Do not change network behavior automatically; "China mode" is only a user preference flag.
}

fn default_bypass_sni_hosts() -> HashMap<String, String> {
    HashMap::from([
        ("app-api.pixiv.net".to_owned(), "210.140.139.155".to_owned()),
        ("oauth.secure.pixiv.net".to_owned(), "210.140.139.155".to_owned()),
        ("i.pximg.net".to_owned(), "210.140.139.133".to_owned()),
        ("s.pximg.net".to_owned(), "210.140.139.133".to_owned()),
    ])
}

pub(crate) async fn init_bypass_sni_settings() {
    let mut inited = BYPASS_SNI_INITED.lock().await;
    if *inited {
        return;
    }
    *inited = true;

    let bypass = load_bool_property("bypass_sni".to_owned()).await.unwrap_or(false);
    *BYPASS_SNI.write().await = bypass;

    let raw = load_property("bypass_sni_hosts".to_owned()).await.unwrap_or_default();
    let parsed: Option<HashMap<String, String>> = if raw.trim().is_empty() {
        None
    } else {
        serde_json::from_str::<HashMap<String, String>>(&raw).ok()
    };
    let parsed_valid = parsed.as_ref().is_some_and(|m| !m.is_empty());
    let hosts = if parsed_valid {
        parsed.unwrap()
    } else {
        default_bypass_sni_hosts()
    };

    if raw.trim().is_empty() || !parsed_valid {
        let _ = save_property(
            "bypass_sni_hosts".to_owned(),
            serde_json::to_string(&hosts).unwrap_or_default(),
        )
        .await;
    }
    *BYPASS_SNI_HOSTS.write().await = hosts;
}

pub(crate) async fn set_bypass_sni_cache(value: bool) {
    *BYPASS_SNI.write().await = value;
}

pub(crate) async fn set_bypass_sni_hosts_cache(value: HashMap<String, String>) {
    let mut normalized: HashMap<String, String> = HashMap::new();
    for (k, v) in value {
        let kk = k.trim();
        let vv = v.trim();
        if kk.is_empty() || vv.is_empty() {
            continue;
        }
        normalized.insert(kk.to_owned(), vv.to_owned());
    }
    if normalized.is_empty() {
        normalized = default_bypass_sni_hosts();
    }
    *BYPASS_SNI_HOSTS.write().await = normalized;
}

pub(crate) async fn get_bypass_sni_() -> bool {
    init_bypass_sni_settings().await;
    *BYPASS_SNI.read().await
}

pub(crate) async fn get_bypass_sni_ip_for_host(host: &str) -> Option<String> {
    init_bypass_sni_settings().await;
    if let Some(v) = BYPASS_SNI_HOSTS.read().await.get(host) {
        let vv = v.trim();
        if !vv.is_empty() {
            return Some(vv.to_owned());
        }
    }
    default_bypass_sni_hosts().get(host).cloned()
}
