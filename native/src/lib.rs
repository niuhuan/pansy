use std::path::Path;
use std::sync::Mutex;

use crate::local::join_paths;
use once_cell::sync::OnceCell;

mod api;
mod bridge_generated;

mod entities;
mod local;

#[cfg(test)]
mod tests;

static ROOT: OnceCell<String> = OnceCell::new();
static NETWORK_IMAGE_DIR: OnceCell<String> = OnceCell::new();

lazy_static::lazy_static! {
    static ref INIT_ED: Mutex<bool> = Mutex::new(false);
}

pub(crate) fn init_root(path: &str) {
    let mut lock = INIT_ED.lock().unwrap();
    if *lock {
        return;
    }
    *lock = true;
    println!("Init application with root : {}", path);
    ROOT.set(path.to_owned()).unwrap();
    NETWORK_IMAGE_DIR
        .set(join_paths(vec![path, "network_image"]))
        .unwrap();
    create_dir_if_not_exists(ROOT.get().unwrap());
    create_dir_if_not_exists(NETWORK_IMAGE_DIR.get().unwrap());
}

fn create_dir_if_not_exists(path: &String) {
    if !Path::new(path).exists() {
        std::fs::create_dir_all(path).unwrap();
    }
}

pub(crate) fn get_root() -> &'static String {
    ROOT.get().unwrap()
}

pub(crate) fn get_network_image_dir() -> &'static String {
    NETWORK_IMAGE_DIR.get().unwrap()
}
