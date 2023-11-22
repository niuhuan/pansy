use std::time;
use image::EncodableLayout;
use crate::DOWNLOADS_DIR;
use crate::entities::download_image;
use crate::local::{join_paths, no_authed_client};

pub(crate) async fn download_demon() {
    loop {
        if let Some(info) = download_image::first_need_download().await.unwrap() {
            down_post(info).await;
        } else {
            tokio::time::sleep(time::Duration::from_secs(3)).await;
        }
    }
}

async fn down_post(downloading: download_image::Model) {
    match down(&downloading).await {
        Ok(_) => {
            download_image::delete_by_hash(downloading.hash.as_str()).await.unwrap();
            ()
        }
        Err(err) => {
            download_image::set_status_and_error_msg(downloading.hash.as_str(), 2, err.to_string()).await.unwrap();
            ()
        }
    };
}

async fn down(downloading: &download_image::Model) -> anyhow::Result<()> {
    let data = no_authed_client().await.load_image_data(downloading.original.clone()).await?;
    let f = image::guess_format(data.as_bytes())?;
    let path = format!("{}.{}", downloading.hash, f.extensions_str()[0]);
    let local = join_paths(vec![DOWNLOADS_DIR.get().unwrap().as_str(), path.as_str()]);
    tokio::fs::write(local, data).await?;
    Ok(())
}
