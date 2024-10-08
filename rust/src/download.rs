use std::time;
use image::EncodableLayout;

use crate::DOWNLOADS_DIR;
use crate::entities::download_image;
use crate::local::join_paths;
use crate::udto::*;

pub(crate) async fn download_demon() {
    loop {
        if let Some(info) = download_image::first_need_download().await .unwrap() {
            down_post(info).await ;
        } else {
            tokio::time::sleep(time::Duration::from_secs(3)).await ;
        }
    }
}

async fn down_post(downloading: download_image::Model) {
    match down(&downloading).await {
        Ok(_) => {
            download_image::delete_by_hash(downloading.hash.as_str()).await .unwrap();
            ()
        }
        Err(err) => {
            download_image::set_status_and_error_msg(downloading.hash.as_str(), 2, err.to_string()).await.unwrap();
            ()
        }
    };
}

async fn down(downloading: &download_image::Model) -> anyhow::Result<()> {
    let data = crate::local::client(0).await?.load_image_data(downloading.original.clone()).await?;
    let f = image::guess_format(data.as_bytes())?;
    let path = format!("{}.{}", downloading.hash, f.extensions_str()[0]);
    let dd_lock = DOWNLOADS_DIR.lock().await;
    let local = join_paths(vec![dd_lock.as_str(), path.as_str()]);
    drop(dd_lock);
    tokio::fs::write(local, data).await?;
    Ok(())
}

pub async fn append_to_download(values: Vec<UiAppendToDownload>) -> anyhow::Result<()> {
    download_image::batch_save(
        values.into_iter().map(|e| download_image::Model {
            hash: hex::encode(md5::compute(e.original.as_bytes()).0),
            append_time: chrono::Local::now().timestamp(),
            illust_id: e.illust_id,
            illust_title: e.illust_title,
            illust_type: e.illust_type,
            image_idx: e.image_idx,
            square_medium: e.square_medium,
            medium: e.medium,
            large: e.large,
            original: e.original,
            download_status: 0,
            error_msg: String::default(),
        })
    ).await?;
    Ok(())
}

pub(crate) async fn reset_failed_downloads() -> anyhow::Result<()> {
    download_image::reset_failed_downloads().await
}

pub(crate) async fn downloading_list() -> anyhow::Result<Vec<UiDownloading>> {
    Ok(download_image::all().await?.into_iter().map(|e| UiDownloading {
        hash: e.hash,
        illust_id: e.illust_id,
        illust_title: e.illust_title,
        illust_type: e.illust_type,
        image_idx: e.image_idx,
        square_medium: e.square_medium,
        medium: e.medium,
        large: e.large,
        original: e.original,
        download_status: e.download_status,
        error_msg: e.error_msg,
    }).collect())
}

