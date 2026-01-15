pub mod api;
mod frb_generated;

mod entities;
mod local;
mod udto;
mod pixirust;

use crate::entities::{init_databases, property};
use crate::local::join_paths;
use once_cell::sync::OnceCell;
use std::path::Path;
use std::sync::Mutex;
use tokio::time::Duration;

static ROOT: OnceCell<String> = OnceCell::new();
static NETWORK_IMAGE_DIR: OnceCell<String> = OnceCell::new();

lazy_static::lazy_static! {
    static ref INIT_ED: Mutex<bool> = Mutex::new(false);
    static ref RUNTIME: tokio::runtime::Runtime = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .thread_keep_alive(Duration::new(60, 0))
        .max_blocking_threads(30).build().unwrap();
}

pub(crate) fn init_root(path: &str) {
    let mut lock = INIT_ED.lock().unwrap();
    if *lock {
        return;
    }
    *lock = true;
    println!("Init application with root : {path}");
    ROOT.set(path.to_owned()).unwrap();
    NETWORK_IMAGE_DIR
        .set(join_paths(vec![path, "network_image"]))
        .unwrap();
    create_dir_if_not_exists(ROOT.get().unwrap()).unwrap();
    create_dir_if_not_exists(NETWORK_IMAGE_DIR.get().unwrap()).unwrap();
    RUNTIME.block_on(init_databases());
}

fn create_dir_if_not_exists(path: &String) -> std::io::Result<()> {
    if !Path::new(path).exists() {
        return std::fs::create_dir_all(path);
    }
    Ok(())
}

pub(crate) fn get_root() -> &'static String {
    ROOT.get().unwrap()
}

pub(crate) fn get_network_image_dir() -> &'static String {
    NETWORK_IMAGE_DIR.get().unwrap()
}
