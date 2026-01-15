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
    #[serde(default)]
    pub next_url: Option<String>,
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
    pub user: UserSample,
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
pub struct UserSample {
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

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct UserDetail {
    pub profile: Profile,
    pub profile_publicity: ProfilePublicity,
    pub user: User,
    pub workspace: Workspace,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Profile {
    pub address_id: i64,
    pub background_image_url: Option<String>,
    pub birth: String,
    pub birth_day: String,
    pub birth_year: i64,
    pub country_code: String,
    pub gender: String,
    pub is_premium: bool,
    pub is_using_custom_profile_image: bool,
    pub job: String,
    pub job_id: i64,
    pub pawoo_url: Option<String>,
    pub region: String,
    pub total_follow_users: i64,
    pub total_illust_bookmarks_public: i64,
    pub total_illust_series: i64,
    pub total_illusts: i64,
    pub total_manga: i64,
    pub total_mypixiv_users: i64,
    pub total_novel_series: i64,
    pub total_novels: i64,
    pub twitter_account: String,
    pub twitter_url: Option<String>,
    pub webpage: Option<String>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ProfilePublicity {
    pub birth_day: String,
    pub birth_year: String,
    pub gender: String,
    pub job: String,
    pub pawoo: bool,
    pub region: String,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct User {
    pub account: String,
    pub comment: String,
    pub id: i64,
    pub is_access_blocking_user: bool,
    pub is_followed: bool,
    pub name: String,
    pub profile_image_urls: ProfileImageUrls,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Workspace {
    pub chair: String,
    pub comment: String,
    pub desk: String,
    pub desktop: String,
    pub monitor: String,
    pub mouse: String,
    pub music: String,
    pub pc: String,
    pub printer: String,
    pub scanner: String,
    pub tablet: String,
    pub tool: String,
    pub workspace_image_url: Option<String>,
}

// User following response
#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct UserPreviewsResponse {
    pub user_previews: Vec<UserPreview>,
    #[serde(default)]
    pub next_url: Option<String>,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct UserPreview {
    pub user: UserSample,
    pub illusts: Vec<Illust>,
    pub is_muted: bool,
}
