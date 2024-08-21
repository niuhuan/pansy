use crate::entities::PROPERTIES_DB;
use crate::entities::{create_index_a, create_table_if_not_exists, index_exists};
use sea_orm::entity::prelude::*;
use sea_orm::{EntityTrait, Set};
use std::ops::Deref;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Default)]
#[sea_orm(table_name = "property")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub k: String,
    pub v: String,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}

pub(crate) async fn init(db: &DatabaseConnection) {
    create_table_if_not_exists(&db, Entity).await;
    if !index_exists(db, "property", "property_uk_k").await {
        create_index_a(db, "property", vec!["k"], "property_uk_k", true).await;
    }
}

pub(crate) async fn save_property(k: String, v: String) -> Result<(), DbErr> {
    let db = PROPERTIES_DB.get().unwrap().lock().await;
    let in_db = Entity::find_by_id(k.clone()).one(db.deref()).await?;
    match in_db {
        Some(in_db) => {
            let mut data: ActiveModel = in_db.into();
            data.k = Set(k.clone());
            data.v = Set(v.clone());
            data.update(db.deref()).await?;
        }
        None => {
            let insert = ActiveModel {
                k: Set(k.clone()),
                v: Set(v.clone()),
                ..Default::default()
            };
            insert.insert(db.deref()).await?;
        }
    };
    drop(db);
    Ok(())
}

pub(crate) async fn load_property(k: String) -> Result<String, DbErr> {
    let in_db: Option<Model> = Entity::find_by_id(k.clone())
        .one(PROPERTIES_DB.get().unwrap().lock().await.deref())
        .await?;
    Ok(in_db.unwrap_or(Model::default()).v)
}

pub(crate) async fn load_i64_property(k: String) -> Result<i64, anyhow::Error> {
    let value = load_property(k).await?;
    Ok(if value.eq("") { 0 } else { value.parse()? })
}

pub(crate) async fn save_i64_property(k: String, v: i64) -> Result<(), DbErr> {
    save_property(k, format!("{}", v)).await
}

pub(crate) async fn load_bool_property(k: String) -> Result<bool, anyhow::Error> {
    let value = load_property(k).await?;
    Ok(if value.eq("") { false } else { value.parse()? })
}

pub(crate) async fn save_bool_property(k: String, v: bool) -> Result<(), DbErr> {
    save_property(k, format!("{}", v)).await
}
