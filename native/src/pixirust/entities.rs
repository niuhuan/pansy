use serde::{Deserialize, Serialize};

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct LoginUrl {
    pub verify: String,
    pub url: String,
}

// user 和 response 省略
#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Token {
    pub access_token: String,
    pub expires_in: i64,
    pub token_type: String,
    pub scope: String,
    pub refresh_token: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct LoginErrorResponse {
    pub has_error: bool,
    pub errors: Errors,
    pub error: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Errors {
    pub system: System,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct System {
    pub message: String,
    pub code: i64,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AppError {
    pub error: ErrorBody,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ErrorBody {
    pub user_message: String,
    pub message: String,
    pub reason: String,
    pub user_message_details: UserMessageDetails,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct UserMessageDetails {}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct IllustResponse {
    pub illusts: Vec<Illust>,
    pub next_url: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Illust {
    pub id: i64,
    pub title: String,
    #[serde(rename = "type")]
    pub illust_type: String,
    pub image_urls: MainImageUrls,
    pub caption: String,
    pub restrict: i64,
    pub user: User,
    pub tags: Vec<Tag>,
    pub tools: Vec<String>,
    pub create_date: String,
    pub page_count: i64,
    pub width: i64,
    pub height: i64,
    pub sanity_level: i64,
    pub x_restrict: i64,
    pub series: Option<Series>,
    pub meta_single_page: MetaSinglePage,
    pub meta_pages: Vec<MetaPage>,
    pub total_view: i64,
    pub total_bookmarks: i64,
    pub is_bookmarked: bool,
    pub visible: bool,
    pub is_muted: bool,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Series {
    pub id: i64,
    pub title: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MainImageUrls {
    pub square_medium: String,
    pub medium: String,
    pub large: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct User {
    pub id: i64,
    pub name: String,
    pub account: String,
    pub profile_image_urls: ProfileImageUrls,
    pub is_followed: bool,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ProfileImageUrls {
    pub medium: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Tag {
    pub name: String,
    pub translated_name: Option<String>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MetaSinglePage {
    pub original_image_url: Option<String>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MetaPage {
    pub image_urls: MetaPageImageUrls,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MetaPageImageUrls {
    pub square_medium: String,
    pub medium: String,
    pub large: String,
    pub original: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct IllustTrendingTags {
    pub trend_tags: Vec<TrendTag>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TrendTag {
    pub tag: String,
    pub translated_name: Option<String>,
    pub illust: Illust,
}

#[allow(dead_code)]
pub const ILLUST_SEARCH_MODE_PARTIAL_MATCH_FOR_TAGS: &'static str = "partial_match_for_tags";
#[allow(dead_code)]
pub const ILLUST_SEARCH_MODE_EXACT_MATCH_FOR_TAGS: &'static str = "exact_match_for_tags";
#[allow(dead_code)]
pub const ILLUST_SEARCH_MODE_TITLE_AND_CAPTION: &'static str = "title_and_caption";
