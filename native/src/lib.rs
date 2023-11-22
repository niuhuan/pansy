use std::io;
use std::path::Path;
use std::sync::Mutex;
use tokio::time::Duration;
use crate::local::join_paths;
use once_cell::sync::OnceCell;
use crate::entities::{init_databases, property};

mod api;
mod bridge_generated;

mod entities;
mod local;

mod download;

static ROOT: OnceCell<String> = OnceCell::new();
static NETWORK_IMAGE_DIR: OnceCell<String> = OnceCell::new();
static DOWNLOADS_DIR: OnceCell<String> = OnceCell::new();

lazy_static::lazy_static! {
    static ref INIT_ED: Mutex<bool> = Mutex::new(false);
    static ref RUNTIME: tokio::runtime::Runtime = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .thread_keep_alive(Duration::new(60, 0))
        .max_blocking_threads(30).build().unwrap();
}

pub(crate) fn init_root(path: &str, downloads_to: &str) {
    let mut lock = INIT_ED.lock().unwrap();
    if *lock {
        return;
    }
    *lock = true;
    println!("Init application with root : {path} , downloads_to : {downloads_to}");
    ROOT.set(path.to_owned()).unwrap();
    NETWORK_IMAGE_DIR
        .set(join_paths(vec![path, "network_image"]))
        .unwrap();
    DOWNLOADS_DIR.set(downloads_to.to_owned()).unwrap();
    create_dir_if_not_exists(ROOT.get().unwrap()).unwrap();
    create_dir_if_not_exists(NETWORK_IMAGE_DIR.get().unwrap()).unwrap();
    RUNTIME.block_on(init_databases());
    RUNTIME.block_on(async {
        let downloads_to = property::load_property("downloads_to".to_owned()).await.unwrap();
        if !downloads_to.is_empty() {
            let _ = DOWNLOADS_DIR.set(downloads_to.clone());
        }
    });
    let _ = create_dir_if_not_exists(DOWNLOADS_DIR.get().unwrap());
    let _ = RUNTIME.spawn(download::download_demon());
}

pub async fn set_downloads_to(new_downloads_to: String) -> anyhow::Result<()> {
    create_dir_if_not_exists(&new_downloads_to)?;
    let _ = DOWNLOADS_DIR.set(new_downloads_to.clone());
    property::save_property("downloads_to".to_owned(), new_downloads_to).await.unwrap();
    Ok(())
}

fn create_dir_if_not_exists(path: &String) -> io::Result<()> {
    if !Path::new(path).exists() {
        return std::fs::create_dir_all(path);
    }
    return Ok(());
}

pub(crate) fn get_root() -> &'static String {
    ROOT.get().unwrap()
}

pub(crate) fn get_network_image_dir() -> &'static String {
    NETWORK_IMAGE_DIR.get().unwrap()
}
