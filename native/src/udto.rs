use serde_derive::*;

#[derive(Debug, Deserialize, Serialize)]
pub struct UiLoginByCodeQuery {
    pub code: String,
    pub verify: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct UiIllustSearchQuery {
    pub mode: String,
    pub word: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct UiIllustRankQuery {
    pub mode: String,
    pub date: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct UiAppendToDownload {
    pub illust_id: i64,
    pub illust_title: String,
    pub illust_type: String,
    pub image_idx: i64,
    pub square_medium: String,
    pub medium: String,
    pub large: String,
    pub original: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct UiDownloading {
    pub hash: String,
    pub illust_id: i64,
    pub illust_title: String,
    pub illust_type: String,
    pub image_idx: i64,
    pub square_medium: String,
    pub medium: String,
    pub large: String,
    pub original: String,
    pub download_status: i32,
    pub error_msg: String,
}
