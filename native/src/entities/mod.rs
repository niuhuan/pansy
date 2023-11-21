use crate::get_root;
use crate::local::join_paths;
use sea_orm::prelude::DatabaseConnection;
use sea_orm::{ConnectionTrait, EntityTrait, Schema, Statement};
use std::time::Duration;
use once_cell::sync::OnceCell;
use tokio::sync::Mutex;

pub(crate) mod network_image;
pub(crate) mod property;

static IMAGE_CACHE_DB: OnceCell<Mutex<DatabaseConnection>> = OnceCell::new();
static PROPERTIES_DB: OnceCell<Mutex<DatabaseConnection>> = OnceCell::new();

pub(crate) async fn init_databases(){
    {
        let path = join_paths(vec![get_root().as_str(),"image_cache.db"]);
        let db = connect_db(&path).await;
        setup_image_cache_db(&db).await;
        IMAGE_CACHE_DB.set(Mutex::new(db)).unwrap();
    }
    {
        let path = join_paths(vec![get_root().as_str(),"properties.db"]);
        let db = connect_db(&path).await;
        setup_properties_db(&db).await;
        PROPERTIES_DB.set(Mutex::new(db)).unwrap();
    }
}

pub(crate) async fn connect_db(path: &str) -> DatabaseConnection {
    println!("CONNECT TO DB : {}", path);
    let url = format!("sqlite:{}?mode=rwc", path);
    let mut opt = sea_orm::ConnectOptions::new(url);
    opt.max_connections(20)
        .min_connections(5)
        .connect_timeout(Duration::from_secs(8))
        .idle_timeout(Duration::from_secs(8))
        .sqlx_logging(true);
    sea_orm::Database::connect(opt).await.unwrap()
}

pub(crate) async fn create_table_if_not_exists<E>(db: &DatabaseConnection, entity: E)
where
    E: EntityTrait,
{
    if !has_table(db, entity.table_name()).await {
        create_table(db, entity).await;
    };
}

pub(crate) async fn has_table(db: &DatabaseConnection, table_name: &str) -> bool {
    let stmt = Statement::from_string(
        db.get_database_backend(),
        format!(
            "SELECT COUNT(*) AS c FROM sqlite_master WHERE type='table' AND name='{}';",
            table_name,
        ),
    );
    let rsp = db.query_one(stmt).await.unwrap().unwrap();
    let count: i32 = rsp.try_get("", "c").unwrap();
    count > 0
}

pub(crate) async fn create_table<E>(db: &DatabaseConnection, entity: E)
where
    E: EntityTrait,
{
    let builder = db.get_database_backend();
    let schema = Schema::new(builder);
    let stmt = &schema.create_table_from_entity(entity);
    let stmt = builder.build(stmt);
    db.execute(stmt).await.unwrap();
}

pub(crate) async fn index_exists(
    db: &DatabaseConnection,
    table_name: &str,
    index_name: &str,
) -> bool {
    let stmt = Statement::from_string(
        db.get_database_backend(),
        format!(
            "select COUNT(*) AS c from sqlite_master where type='index' AND tbl_name='{}' AND name='{}';",
            table_name, index_name,
        ),
    );
    db.query_one(stmt)
        .await
        .unwrap()
        .unwrap()
        .try_get::<i32>("", "c")
        .unwrap()
        > 0
}

pub(crate) async fn create_index_a(
    db: &DatabaseConnection,
    table_name: &str,
    columns: Vec<&str>,
    index_name: &str,
    uk: bool,
) {
    let stmt = Statement::from_string(
        db.get_database_backend(),
        format!(
            "CREATE {} INDEX {} ON {}({});",
            if uk { "UNIQUE" } else { "" },
            index_name,
            table_name,
            columns.join(","),
        ),
    );
    db.execute(stmt).await.unwrap();
}

#[allow(dead_code)]
pub(crate) async fn create_index(
    db: &DatabaseConnection,
    table_name: &str,
    columns: Vec<&str>,
    index_name: &str,
) {
    create_index_a(db, table_name, columns, index_name, false).await
}

async fn setup_image_cache_db(db: &DatabaseConnection) {
    network_image::init(db).await
}

async fn setup_properties_db(db: &DatabaseConnection) {
    property::init(db).await
}
