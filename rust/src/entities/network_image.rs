use std::ops::Deref;
use sea_orm::entity::prelude::*;
use sea_orm::{EntityTrait, Set};
use crate::entities::{create_index_a, create_table_if_not_exists, IMAGE_CACHE_DB, index_exists};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "network_image")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub url: String,
    pub path: String,
    pub cache_time: i64,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}

pub(crate) async fn find_by_url(url: String) -> Result<Option<Model>, sea_orm::DbErr> {
    Entity::find_by_id(url)
        .one(IMAGE_CACHE_DB.get().unwrap().lock().await.deref())
        .await
}

pub(crate) async fn insert(url: String, path: String, cache_time: i64) -> Result<Model, sea_orm::DbErr> {
    ActiveModel {
        url: Set(url),
        path: Set(path),
        cache_time: Set(cache_time),
        ..Default::default()
    }.insert(IMAGE_CACHE_DB.get().unwrap().lock().await.deref()).await
}

pub(crate) async fn delete_by_url(url: String) -> Result<u64, sea_orm::DbErr> {
    let res = Entity::delete_by_id(url)
        .exec(IMAGE_CACHE_DB.get().unwrap().lock().await.deref())
        .await?;
    Ok(res.rows_affected)
}

pub(crate) async fn delete_all() -> Result<u64, sea_orm::DbErr> {
    let res = Entity::delete_many()
        .exec(IMAGE_CACHE_DB.get().unwrap().lock().await.deref())
        .await?;
    Ok(res.rows_affected)
}

pub(crate) async fn init(db: &DatabaseConnection) {
    create_table_if_not_exists(&db, Entity).await;
    if !index_exists(db, "network_image", "network_image_uk_url").await {
        create_index_a(db, "network_image", vec!["url"], "network_image_uk_url", true).await;
    }
}
