pub use super::entities::*;
use super::utils::*;
pub use anyhow::Error;
pub use anyhow::Result;
use base64::Engine;
use reqwest::header;
use serde_json::json;

const APP_SERVER: &'static str = "app-api.pixiv.net";
const OAUTH_SERVER: &'static str = "oauth.secure.pixiv.net";
const IMG_SERVER: &'static str = "i.pximg.net";

struct Server {
    pub server: &'static str,
}

const APP: Server = Server {
    server: APP_SERVER,
};

const OAUTH: Server = Server {
    server: OAUTH_SERVER,
};

const IMG: Server = Server {
    server: IMG_SERVER,
};

const SALT: &'static str = "28c1fdd170a5204386cb1313c7077b34f83e4aaf4aa829ce78c231e05b0bae2c";
const CLIENT_ID: &'static str = "MOBrBDS8blbauoSck0ZfDbtuzpyT";
const CLIENT_SECRET: &'static str = "lsACyCD94FhDUtGTXi3QzcFE2uU1hqtDaKeqrdwj";

pub struct Client {
    pub access_token: String,
    agent: reqwest::Client,
    agent_sni_bypass: reqwest::Client,
}

impl Client {
    /// 创建客户端
    pub fn new() -> Self {
        Self {
            agent: reqwest::ClientBuilder::new().build().unwrap(),
            agent_sni_bypass: reqwest::ClientBuilder::new()
                .danger_accept_invalid_certs(true)
                .danger_accept_invalid_hostnames(true)
                .http1_only()
                .build()
                .unwrap(),
            access_token: String::default(),
        }
    }

    async fn build_request(
        &self,
        method: reqwest::Method,
        url: &str,
    ) -> reqwest::RequestBuilder {
        let bypass = crate::local::get_bypass_sni_().await;
        if !bypass {
            return self.agent.request(method, url);
        }

        let parsed = reqwest::Url::parse(url);
        if let Ok(mut parsed) = parsed {
            if parsed.scheme() != "https" {
                return self.agent.request(method, parsed);
            }
            let host = parsed.host_str().map(|h| h.to_string());
            if let Some(host) = host {
                if let Some(ip) = crate::local::get_bypass_sni_ip_for_host(&host).await {
                    if parsed.set_host(Some(ip.as_str())).is_ok() {
                        return self
                            .agent_sni_bypass
                            .request(method, parsed)
                            .header(header::HOST, host);
                    }
                }
            }
            return self.agent.request(method, parsed);
        }
        self.agent.request(method, url)
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
        let url = format!("https://{}/auth/token", OAUTH.server);
        let req = self.build_request(reqwest::Method::POST, url.as_str()).await;
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
        let req = self.build_request(reqwest::Method::GET, url.as_str()).await;
        let req = self.sign_request(req);
        let rsp = req.send().await?;
        match &rsp.status().as_u16() {
            200 => {
                let text = rsp.text().await?;
                Ok(text)
            },
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

    async fn post_form_pixiv<T: for<'de> serde::Deserialize<'de>>(&self, url: String, form: Vec<(&str, String)>) -> Result<T> {
        let req = self.build_request(reqwest::Method::POST, url.as_str()).await;
        let req = self.sign_request(req);
        let rsp = req.form(&form).send().await?;
        match &rsp.status().as_u16() {
            200 => {
                let text = rsp.text().await?;
                Ok(serde_json::from_str(text.as_str())?)
            },
            _ => {
                let ae: AppError = serde_json::from_str(rsp.text().await?.as_str())?;
                Err(Error::msg(ae.error.message))
            }
        }
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

    pub fn user_illusts_first_url(&self, user_id: i64) -> String {
        format!(
            "https://{}/v1/user/illusts?filter=for_android&user_id={}&type=illust",
            APP.server, user_id,
        )
    }

    pub async fn illust_from_url(&self, url: String) -> Result<IllustResponse> {
        self.get_from_pixiv(url).await
    }

    pub async fn user_previews_from_url(&self, url: String) -> Result<UserPreviewsResponse> {
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
    pub fn illust_search_first_url(&self, word: String, search_target: String, sort: String) -> String {
        format!(
            "https://{}/v1/search/illust?word={}&search_target={}&sort={}&merge_plain_keyword_results=true&filter=for_ios",
            APP.server,
            urlencoding::encode(word.as_str()),
            search_target,
            sort,
        )
    }

    pub async fn user_detail(&self, user_id: i64) -> Result<UserDetail> {
        self.get_from_pixiv(format!(
            "https://{}/v1/user/detail?filter=for_android&user_id={}",
            APP.server, user_id,
        ))
        .await
    }

    pub async fn follow_user(&self, user_id: i64, restrict: String) -> Result<()> {
        let _result: serde_json::Value = self.post_form_pixiv(
            format!("https://{}/v1/user/follow/add", APP.server),
            vec![
                ("user_id", user_id.to_string()),
                ("restrict", restrict),
            ],
        )
        .await?;
        Ok(())
    }

    pub async fn unfollow_user(&self, user_id: i64) -> Result<()> {
        let _result: serde_json::Value = self.post_form_pixiv(
            format!("https://{}/v1/user/follow/delete", APP.server),
            vec![("user_id", user_id.to_string())],
        )
        .await?;
        Ok(())
    }

    pub async fn user_following(&self, user_id: i64, restrict: String) -> Result<UserPreviewsResponse> {
        self.get_from_pixiv(format!(
            "https://{}/v1/user/following?filter=for_android&user_id={}&restrict={}",
            APP.server, user_id, restrict,
        ))
        .await
    }

    pub async fn user_bookmarks(&self, user_id: i64, restrict: String, tag: Option<String>) -> Result<IllustResponse> {
        let tag_param = tag.map(|t| format!("&tag={}", urlencoding::encode(&t))).unwrap_or_default();
        self.get_from_pixiv(format!(
            "https://{}/v1/user/bookmarks/illust?user_id={}&restrict={}{}",
            APP.server, user_id, restrict, tag_param,
        ))
        .await
    }

    pub async fn add_bookmark(&self, illust_id: i64, restrict: String) -> Result<()> {
        let _result: serde_json::Value = self.post_form_pixiv(
            format!("https://{}/v2/illust/bookmark/add", APP.server),
            vec![
                ("illust_id", illust_id.to_string()),
                ("restrict", restrict),
            ],
        )
        .await?;
        Ok(())
    }

    pub async fn delete_bookmark(&self, illust_id: i64) -> Result<()> {
        let _result: serde_json::Value = self.post_form_pixiv(
            format!("https://{}/v1/illust/bookmark/delete", APP.server),
            vec![("illust_id", illust_id.to_string())],
        )
        .await?;
        Ok(())
    }

    pub async fn load_image_data(&self, url: String) -> Result<bytes::Bytes> {
        let req = self.build_request(reqwest::Method::GET, url.as_str()).await;
        let req = self.sign_request(req);
        let rsp = req.send().await?;
        let status = rsp.status();
        match status.as_u16() {
            200 => Ok(rsp.bytes().await?),
            _ => Err(Error::msg(rsp.text().await?)),
        }
    }
}
