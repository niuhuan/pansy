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

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct DownloadTaskDto {
    pub id: i64,
    pub illust_id: i64,
    pub illust_title: String,
    pub page_index: i32,
    pub page_count: i32,
    pub url: String,
    pub target_path: String,
    pub save_target: String,
    pub status: String,
    pub progress: i32,
    pub error_message: String,
    pub retry_count: i32,
    pub created_time: i64,
    pub updated_time: i64,
}

