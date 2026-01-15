use std::ops::Deref;
use sea_orm::entity::prelude::*;
use sea_orm::{EntityTrait, Set, QueryOrder};
use crate::entities::{create_index_a, create_table_if_not_exists, DOWNLOAD_TASK_DB, index_exists};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "download_task")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = true)]
    pub id: i64,
    pub illust_id: i64,
    pub illust_title: String,
    pub page_index: i32,
    pub page_count: i32,
    pub url: String,
    pub target_path: String,
    pub save_target: String, // file, album, fileAndAlbum
    pub status: String, // pending, downloading, completed, failed
    pub progress: i32, // 0-100
    pub error_message: String,
    pub retry_count: i32,
    pub created_time: i64,
    pub updated_time: i64,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}

pub(crate) async fn find_all() -> Result<Vec<Model>, sea_orm::DbErr> {
    Entity::find()
        .order_by_desc(Column::CreatedTime)
        .all(DOWNLOAD_TASK_DB.get().unwrap().lock().await.deref())
        .await
}

pub(crate) async fn find_pending() -> Result<Vec<Model>, sea_orm::DbErr> {
    Entity::find()
        .filter(Column::Status.eq("pending"))
        .order_by_asc(Column::CreatedTime)
        .all(DOWNLOAD_TASK_DB.get().unwrap().lock().await.deref())
        .await
}

pub(crate) async fn find_by_id(id: i64) -> Result<Option<Model>, sea_orm::DbErr> {
    Entity::find_by_id(id)
        .one(DOWNLOAD_TASK_DB.get().unwrap().lock().await.deref())
        .await
}

pub(crate) async fn insert(
    illust_id: i64,
    illust_title: String,
    page_index: i32,
    page_count: i32,
    url: String,
    target_path: String,
    save_target: String,
) -> Result<Model, sea_orm::DbErr> {
    let now = chrono::Local::now().timestamp_millis();
    ActiveModel {
        illust_id: Set(illust_id),
        illust_title: Set(illust_title),
        page_index: Set(page_index),
        page_count: Set(page_count),
        url: Set(url),
        target_path: Set(target_path),
        save_target: Set(save_target),
        status: Set("pending".to_string()),
        progress: Set(0),
        error_message: Set("".to_string()),
        retry_count: Set(0),
        created_time: Set(now),
        updated_time: Set(now),
        ..Default::default()
    }
    .insert(DOWNLOAD_TASK_DB.get().unwrap().lock().await.deref())
    .await
}

pub(crate) async fn update_status(
    id: i64,
    status: String,
    progress: i32,
    error_message: String,
) -> Result<(), sea_orm::DbErr> {
    let now = chrono::Local::now().timestamp_millis();
    let task = find_by_id(id).await?;
    if let Some(task) = task {
        let mut active: ActiveModel = task.into();
        active.status = Set(status);
        active.progress = Set(progress);
        active.error_message = Set(error_message);
        active.updated_time = Set(now);
        active.update(DOWNLOAD_TASK_DB.get().unwrap().lock().await.deref()).await?;
    }
    Ok(())
}

pub(crate) async fn update_retry_count(id: i64, count: i32) -> Result<(), sea_orm::DbErr> {
    let now = chrono::Local::now().timestamp_millis();
    let task = find_by_id(id).await?;
    if let Some(task) = task {
        let mut active: ActiveModel = task.into();
        active.retry_count = Set(count);
        active.updated_time = Set(now);
        active.update(DOWNLOAD_TASK_DB.get().unwrap().lock().await.deref()).await?;
    }
    Ok(())
}

pub(crate) async fn delete_by_id(id: i64) -> Result<(), sea_orm::DbErr> {
    Entity::delete_by_id(id)
        .exec(DOWNLOAD_TASK_DB.get().unwrap().lock().await.deref())
        .await?;
    Ok(())
}

pub(crate) async fn delete_completed() -> Result<(), sea_orm::DbErr> {
    Entity::delete_many()
        .filter(Column::Status.eq("completed"))
        .exec(DOWNLOAD_TASK_DB.get().unwrap().lock().await.deref())
        .await?;
    Ok(())
}

pub(crate) async fn retry_failed_task(id: i64) -> Result<(), sea_orm::DbErr> {
    let now = chrono::Local::now().timestamp_millis();
    let task = find_by_id(id).await?;
    if let Some(task) = task {
        let retry_count = task.retry_count;
        let mut active: ActiveModel = task.into();
        active.status = Set("pending".to_string());
        active.progress = Set(0);
        active.error_message = Set("".to_string());
        active.retry_count = Set(retry_count + 1);
        active.updated_time = Set(now);
        active.update(DOWNLOAD_TASK_DB.get().unwrap().lock().await.deref()).await?;
    }
    Ok(())
}

pub(crate) async fn init(db: &DatabaseConnection) {
    create_table_if_not_exists(&db, Entity).await;
    if !index_exists(db, "download_task", "download_task_idx_status").await {
        create_index_a(db, "download_task", vec!["status"], "download_task_idx_status", false).await;
    }
    if !index_exists(db, "download_task", "download_task_idx_illust_id").await {
        create_index_a(db, "download_task", vec!["illust_id"], "download_task_idx_illust_id", false).await;
    }
}
