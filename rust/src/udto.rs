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
