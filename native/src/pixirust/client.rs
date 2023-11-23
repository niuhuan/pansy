pub use anyhow::Error;
pub use anyhow::Result;
use base64::Engine;
use serde_json::json;
use super::utils::*;
pub use super::entities::*;

const APP_SERVER: &'static str = "app-api.pixiv.net";
const APP_SERVER_IP: &'static str = "210.140.131.199";
const OAUTH_SERVER: &'static str = "oauth.secure.pixiv.net";
const OAUTH_SERVER_IP: &'static str = "210.140.131.199";
const IMG_SERVER: &'static str = "i.pximg.net";
const IMG_SERVER_IP: &'static str = "s.pximg.net";

struct Server {
    pub server: &'static str,
    pub ip: &'static str,
}

const APP: Server = Server {
    server: APP_SERVER,
    ip: APP_SERVER_IP,
};

const OAUTH: Server = Server {
    server: OAUTH_SERVER,
    ip: OAUTH_SERVER_IP,
};

const IMG: Server = Server {
    server: IMG_SERVER,
    ip: IMG_SERVER_IP,
};

const SALT: &'static str = "28c1fdd170a5204386cb1313c7077b34f83e4aaf4aa829ce78c231e05b0bae2c";
const CLIENT_ID: &'static str = "MOBrBDS8blbauoSck0ZfDbtuzpyT";
const CLIENT_SECRET: &'static str = "lsACyCD94FhDUtGTXi3QzcFE2uU1hqtDaKeqrdwj";

pub struct Client {
    pub access_token: String,
    agent: reqwest::Client,
    agent_free: bool,
}

impl Client {
    /// 创建客户端
    pub fn new() -> Self {
        Self {
            agent: reqwest::ClientBuilder::new().build().unwrap(),
            agent_free: false,
            access_token: String::default(),
        }
    }

    /// 免代理客户端
    pub fn new_agent_free() -> Self {
        Self {
            agent: reqwest::ClientBuilder::new()
                .danger_accept_invalid_certs(true)
                .build()
                .unwrap(),
            agent_free: true,
            access_token: String::default(),
        }
    }

    /// pixiv的base64格式
    fn base64_pixiv<T: AsRef<[u8]>>(&self, src: T) -> String {
        base64::prelude::BASE64_STANDARD
            .encode(src)
            .replace("=", "")
            .replace("+", "-")
            .replace("/", "_")
    }

    /// ISO时间
    fn iso_time(&self) -> String {
        chrono::Local::now()
            .format("%Y-%m-%dT%H:%M:%S%Z")
            .to_string()
    }

    /// 新建VerifyCode
    fn code_verify(&self) -> String {
        self.base64_pixiv(uuid::Uuid::new_v4().to_string().replace("-", ""))
    }

    /// 对VerifyCode加密
    fn code_challenge(&self, code: &String) -> String {
        self.base64_pixiv(sha256(code.clone()))
    }

    /// 创建一个登录用的url
    pub fn create_login_url(&self) -> LoginUrl {
        let verify = self.code_verify();
        let url = format!("https://app-api.pixiv.net/web/v1/login?code_challenge={}&code_challenge_method=S256&client=pixiv-android",self.code_challenge(&verify));
        LoginUrl { verify, url }
    }

    /// 创建一个注册用的url
    pub fn create_register_url(&self) -> LoginUrl {
        let verify = self.code_verify();
        let url = format!("https://app-api.pixiv.net/web/v1/provisional-accounts/create?code_challenge={}&code_challenge_method=S256&client=pixiv-android",self.code_challenge(&verify));
        LoginUrl { verify, url }
    }

    /// 请求并获得结果
    async fn load_token(&self, body: serde_json::Value) -> Result<Token> {
        let req = match self.agent_free {
            true => self
                .agent
                .request(
                    reqwest::Method::POST,
                    format!("https://{}/auth/token", OAUTH.ip).as_str(),
                )
                .header("Host", OAUTH.server),
            false => self.agent.request(
                reqwest::Method::POST,
                format!("https://{}/auth/token", OAUTH.server).as_str(),
            ),
        };
        let rsp = req.form(&body).send().await;
        match rsp {
            Ok(resp) => {
                let status = resp.status();
                match status.as_u16() {
                    200 => Ok(serde_json::from_str(resp.text().await?.as_str())?),
                    _ => {
                        let err: LoginErrorResponse =
                            serde_json::from_str(resp.text().await?.as_str())?;
                        Err(Error::msg(err.errors.system.message))
                    }
                }
            }
            Err(err) => Err(Error::msg(err)),
        }
    }

    /// 使用code登录
    pub async fn load_token_by_code(&self, code: String, verify: String) -> Result<Token> {
        self.load_token(json!({
        "code":           code,
        "code_verifier":  verify,
        "redirect_uri":   "https://app-api.pixiv.net/web/v1/users/auth/pixiv/callback",
        "grant_type":     "authorization_code",
        "include_policy": "true",
        "client_id":      CLIENT_ID,
        "client_secret":  CLIENT_SECRET,
        }))
        .await
    }

    /// 刷新token
    pub async fn refresh_token(&self, refresh_token: &String) -> Result<Token> {
        self.load_token(json!({
        "refresh_token":  refresh_token,
        "grant_type":     "refresh_token",
        "include_policy": "true",
        "client_id":      CLIENT_ID,
        "client_secret":  CLIENT_SECRET,
        }))
        .await
    }

    fn sign_request(&self, request: reqwest::RequestBuilder) -> reqwest::RequestBuilder {
        let time = self.iso_time();
        request
            .header("x-client-time", &time.clone())
            .header("x-client-hash", hex::encode(format!("{}{}", time, SALT)))
            .header("accept-language", "zh-CN")
            .header(
                "User-Agent",
                "PixivAndroidApp/5.0.234 (Android 10.0; Pixel C)",
            )
            .header("App-OS-Version", "Android 10.0")
            .header("Referer", "https://app-api.pixiv.net/")
            .bearer_auth(&self.access_token)
    }

    pub async fn get_from_pixiv_raw(&self, url: String) -> Result<String> {
        let req = match self.agent_free {
            true => {
                if url.starts_with(format!("https://{}", APP.server).as_str()) {
                    self.agent
                        .get(url.replacen(APP.server, APP.ip, 1))
                        .header("Host", APP.server)
                } else {
                    self.agent.get(url)
                }
            }
            false => self.agent.get(url),
        };
        let req = self.sign_request(req);
        let rsp = req.send().await?;
        match &rsp.status().as_u16() {
            200 => Ok(rsp.text().await?),
            _ => {
                let ae: AppError = serde_json::from_str(rsp.text().await?.as_str())?;
                Err(Error::msg(ae.error.message))
            }
        }
    }

    async fn get_from_pixiv<T: for<'de> serde::Deserialize<'de>>(&self, url: String) -> Result<T> {
        let text = self.get_from_pixiv_raw(url).await?;
        Ok(serde_json::from_str(text.as_str())?)
    }

    pub fn illust_recommended_first_url(&self) -> String {
        format!(
            "https://{}/v1/illust/recommended?filter=for_ios&include_ranking_label=true",
            APP.server
        )
    }

    pub fn illust_rank_first_url(&self, mode: String, date: String) -> String {
        format!(
            "https://{}/v1/illust/ranking?filter=for_android&mode={}&date={}",
            APP.server, mode, date,
        )
    }

    pub async fn illust_from_url(&self, url: String) -> Result<IllustResponse> {
        self.get_from_pixiv(url).await
    }

    pub fn illust_trending_tags_url(&self) -> String {
        format!(
            "https://{}/v1/trending-tags/illust?filter=for_android",
            APP.server,
        )
    }

    pub async fn illust_trending_tags(&self) -> Result<IllustTrendingTags> {
        self.get_from_pixiv(self.illust_trending_tags_url()).await
    }

    ///
    /// mode:
    /// partial_match_for_tags  - 标签部分一致
    /// exact_match_for_tags    - 标签完全一致
    /// title_and_caption       - 标题说明文
    ///
    /// sort: [date_desc, date_asc, popular_desc] - popular_desc为会员的热门排序
    ///
    pub fn illust_search_first_url(&self, word: String, mode: String) -> String {
        format!(
            "https://{}/v1/search/illust?word={}&search_target={}&filter=for_ios",
            APP.server,
            urlencoding::encode(word.as_str()),
            mode,
        )
    }

    pub async fn load_image_data(&self, url: String) -> Result<bytes::Bytes> {
        let req = match self.agent_free {
            true => {
                if url.starts_with(format!("https://{}", IMG.server).as_str()) {
                    self.agent
                        .get(url.replacen(IMG.server, IMG.ip, 1))
                        .header("Host", IMG.server)
                } else {
                    self.agent.get(url)
                }
            }
            false => self.agent.get(url),
        };
        let req = self.sign_request(req);
        let rsp = req.send().await?;
        let status = rsp.status();
        match status.as_u16() {
            200 => Ok(rsp.bytes().await?),
            _ => Err(Error::msg(rsp.text().await?)),
        }
    }
}
