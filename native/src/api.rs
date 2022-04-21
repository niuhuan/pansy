use crate::entities::network_image;
use crate::get_network_image_dir;
use crate::local::{
    authed_client, get_in_china_, hash_lock, join_paths, load_in_china, load_token,
    no_authed_client, set_in_china_, set_token,
};
use anyhow::{Context, Result};
use serde_derive::*;
use std::future::Future;
use std::path::Path;
use std::time::Duration;

pub fn desktop_root() -> Result<String> {
    #[cfg(target_os = "windows")]
    {
        Ok(join_paths(vec![
            std::env::current_exe()?
                .parent()
                .with_context(|| "error")?
                .to_str()
                .with_context(|| "error")?,
            "data",
        ]))
    }
    #[cfg(target_os = "macos")]
    {
        let home = std::env::var_os("HOME")
            .with_context(|| "error")?
            .to_str()
            .with_context(|| "error")?
            .to_string();
        Ok(join_paths(vec![
            home.as_str(),
            "Library",
            "Application Support",
            "niuhuan",
            "daisy",
        ]))
    }
    #[cfg(target_os = "linux")]
    {
        let home = std::env::var_os("HOME")
            .with_context(|| "error")?
            .to_str()
            .with_context(|| "error")?
            .to_string();
        Ok(join_paths(vec![home.as_str(), ".niuhuan", "daisy"]))
    }
    #[cfg(not(any(target_os = "linux", target_os = "windows", target_os = "macos")))]
    panic!("未支持的平台")
}

pub fn init(root:String)->Result<()>{
    crate::init_root(&root);
    Ok(())
}

#[derive(Debug, Deserialize, Serialize)]
pub struct LoginByCodeQuery {
    pub code: String,
    pub verify: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct IllustSearchQuery {
    pub mode: String,
    pub word: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct IllustRankQuery {
    pub mode: String,
    pub date: String,
}

lazy_static::lazy_static! {
    static ref RUNTIME: tokio::runtime::Runtime = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .thread_keep_alive(Duration::new(60, 0))
        .max_blocking_threads(30).build().unwrap();
}

fn block_on<T>(f: impl Future<Output = T>) -> T {
    RUNTIME.block_on(f)
}

pub fn copy_image_to(src_path: String, to_dir: String) -> Result<()> {
    let name = Path::new(&src_path)
        .file_name()
        .unwrap()
        .to_str()
        .unwrap()
        .to_owned();
    let ext = image::io::Reader::open(&src_path)?
        .with_guessed_format()?
        .format()
        .with_context(|| anyhow::Error::msg("img format error"))?
        .extensions_str()[0];
    let final_name = format!("{}.{}", name, ext);
    let target = join_paths(vec![to_dir.as_str(), final_name.as_str()]);
    std::fs::copy(src_path.as_str(), target.as_str())?;
    Ok(())
}

pub fn set_in_china(value: bool) {
    block_on(set_in_china_(value))
}

pub fn get_in_china() -> bool {
    block_on(get_in_china_())
}

pub fn per_in_china() {
    println!("I AM IN RUST");
    block_on(async {
        load_in_china().await;
    });
}

pub fn pre_login() -> Result<bool> {
    block_on(async { load_token().await })
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct LoginUrl {
    pub verify: String,
    pub url: String,
}

pub fn create_login_url() -> LoginUrl {
    block_on(async {
        let raw = no_authed_client().await.create_login_url();
        LoginUrl {
            verify: raw.verify,
            url: raw.url,
        }
    })
}

pub fn login_by_code(query: LoginByCodeQuery) -> Result<bool> {
    block_on(async {
        let token = no_authed_client()
            .await
            .load_token_by_code(query.code, query.verify)
            .await?;
        set_token(token, chrono::Local::now().timestamp_millis()).await;
        Ok(true)
    })
}

pub fn request_url(params: String) -> Result<String> {
    block_on(async { authed_client().await?.get_from_pixiv_raw(params).await })
}

pub fn illust_recommended_first_url() -> Result<String> {
    block_on(async { Ok(no_authed_client().await.illust_recommended_first_url()) })
}

pub fn illust_search_first_url(query: IllustSearchQuery) -> Result<String> {
    block_on(async {
        Ok(no_authed_client()
            .await
            .illust_search_first_url(query.word, query.mode))
    })
}

pub fn illust_rank_first_url(query: IllustRankQuery) -> Result<String> {
    block_on(async {
        Ok(no_authed_client()
            .await
            .illust_rank_first_url(query.mode, query.date))
    })
}

pub fn illust_trending_tags_url() -> String {
    block_on(async { no_authed_client().await.illust_trending_tags_url() })
}

/// 下载pixiv的图片
pub fn load_pixiv_image(url: String) -> Result<String> {
    block_on(async {
        // hash锁
        let _lock = hash_lock(&url).await;
        // 查找图片是否有缓存
        let db_image = network_image::find_by_url(url.clone()).await?;
        let path = match db_image {
            // 有缓存直接使用
            Some(db_image) => db_image.path,
            // 没有缓存则下载
            None => {
                let now = chrono::Local::now().timestamp_millis();
                let path = format!(
                    "{}{}",
                    hex::encode(md5::compute(url.clone()).to_vec()),
                    &now,
                );
                let client = no_authed_client().await;
                let data: bytes::Bytes = client.load_image_data(url.clone()).await?;
                drop(client);
                let local = join_paths(vec![get_network_image_dir().as_str(), &path]);
                std::fs::write(local, data).unwrap();
                network_image::insert(url.clone(), path.clone(), now.clone()).await?;
                path
            }
        };
        Ok(join_paths(vec![get_network_image_dir().as_str(), &path]))
    })
}
