use std::ops::Deref;
use sea_orm::entity::prelude::*;
use sea_orm::{DeleteResult, EntityTrait, IntoActiveModel, Order, QueryOrder, QuerySelect, UpdateResult};
use sea_orm::sea_query::OnConflict;
use crate::entities::{create_index_a, create_table_if_not_exists, DOWNLOADS_DB, index_exists};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "download_image")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub hash: String,
    pub append_time: i64,
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

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}

pub(crate) async fn init(db: &DatabaseConnection) {
    create_table_if_not_exists(&db, Entity).await;
    if !index_exists(db, "download_image", "download_image_idx_append_time").await {
        create_index_a(db, "download_image", vec!["append_time"], "download_image_idx_append_time", true).await;
    }
}

pub(crate) async fn first_need_download() -> anyhow::Result<Option<Model>> {
    Ok(Entity::find()
        .filter(Column::DownloadStatus.eq(0))
        .order_by(Column::AppendTime, Order::Asc)
        .limit(1)
        .one(DOWNLOADS_DB.get().unwrap().lock().await.deref()).await?)
}

pub(crate) async fn delete_by_hash(hash: &str) -> anyhow::Result<DeleteResult> {
    Ok(Entity::delete_by_id(hash).exec(DOWNLOADS_DB.get().unwrap().lock().await.deref()).await?)
}

pub(crate) async fn set_status_and_error_msg(hash: &str, status: i32, error_msg: String) -> anyhow::Result<UpdateResult> {
    Ok(Entity::update_many()
        .filter(Column::Hash.eq(hash))
        .col_expr(Column::DownloadStatus, Expr::value(status))
        .col_expr(Column::ErrorMsg, Expr::value(error_msg))
        .exec(DOWNLOADS_DB.get().unwrap().lock().await.deref()).await?)
}

pub(crate) async fn batch_save(values: impl Iterator<Item=Model>) -> anyhow::Result<()> {
    let db = DOWNLOADS_DB.get().unwrap().lock().await;
    Entity::insert_many(values.map(|e| e.into_active_model()))
        .on_conflict(OnConflict::column(Column::Hash).do_nothing().to_owned())
        .exec(db.deref()).await?;
    Ok(())
}

pub(crate) async fn reset_failed_downloads() -> anyhow::Result<()> {
    let db = DOWNLOADS_DB.get().unwrap().lock().await;
    Entity::update_many()
        .filter(Column::DownloadStatus.eq(2))
        .col_expr(Column::DownloadStatus, Expr::value(0))
        .exec(db.deref()).await?;
    Ok(())
}
