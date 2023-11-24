use crate::entities::{network_image, property};
use crate::local::{
    client, get_in_china_, hash_lock, join_paths, load_in_china, load_token, set_in_china_,
    set_token,
};
use crate::pixirust::client::{IllustTrendingTags, UserDetail};
use crate::pixirust::entities::IllustResponse;
use crate::pixirust::entities::LoginUrl;
use crate::udto::*;
use crate::{download, get_network_image_dir};
use anyhow::{Context, Ok, Result};
use std::future::Future;
use std::path::Path;

pub fn desktop_root() -> Result<String> {
    #[cfg(target_os = "windows")]
    {
        Ok(join_paths(vec![
            std::env::current_exe()?
                .parent()
                .with_context(|| "error")?
                .to_str()
                .with_context(|| "error")?,
            "data",
        ]))
    }
    #[cfg(target_os = "macos")]
    {
        let home = std::env::var_os("HOME")
            .with_context(|| "error")?
            .to_str()
            .with_context(|| "error")?
            .to_string();
        Ok(join_paths(vec![
            home.as_str(),
            "Library",
            "Application Support",
            "niuhuan",
            "pansy",
        ]))
    }
    #[cfg(target_os = "linux")]
    {
        let home = std::env::var_os("HOME")
            .with_context(|| "error")?
            .to_str()
            .with_context(|| "error")?
            .to_string();
        Ok(join_paths(vec![home.as_str(), ".niuhuan", "pansy"]))
    }
    #[cfg(not(any(target_os = "linux", target_os = "windows", target_os = "macos")))]
    panic!("未支持的平台")
}

// get downloads dir form env
pub fn downloads_to() -> Result<String> {
    #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
    {
        Ok(directories::UserDirs::new()
            .unwrap()
            .download_dir()
            .unwrap()
            .join("pansy")
            .to_str()
            .unwrap()
            .to_owned())
    }
    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    {
        Err(anyhow::Error::msg("not support os"))
    }
}

pub fn init(root: String, downloads_to: String) -> Result<()> {
    crate::init_root(&root, &downloads_to);
    Ok(())
}

pub fn recreate_downloads_to() -> Result<()> {
    block_on(crate::recreate_downloads_to())
}

pub fn set_downloads_to(new_downloads_to: String) -> Result<()> {
    block_on(crate::set_downloads_to(new_downloads_to))
}

pub fn save_property(k: String, v: String) -> Result<()> {
    block_on(async move { Ok(property::save_property(k, v).await?) })
}

pub fn load_property(k: String) -> Result<String> {
    block_on(async move { Ok(property::load_property(k).await?) })
}

fn block_on<T>(f: impl Future<Output = T>) -> T {
    crate::RUNTIME.block_on(f)
}

pub fn copy_image_to(src_path: String, to_dir: String) -> Result<()> {
    let name = Path::new(&src_path)
        .file_name()
        .unwrap()
        .to_str()
        .unwrap()
        .to_owned();
    let ext = image::io::Reader::open(&src_path)?
        .with_guessed_format()?
        .format()
        .with_context(|| anyhow::Error::msg("img format error"))?
        .extensions_str()[0];
    let final_name = format!("{}.{}", name, ext);
    let target = join_paths(vec![to_dir.as_str(), final_name.as_str()]);
    std::fs::copy(src_path.as_str(), target.as_str())?;
    Ok(())
}

pub fn set_in_china(value: bool) {
    block_on(set_in_china_(value))
}

pub fn get_in_china() -> bool {
    block_on(get_in_china_())
}

pub fn per_in_china() {
    println!("I AM IN RUST");
    block_on(async {
        load_in_china().await;
    });
}

pub fn pre_login() -> Result<bool> {
    block_on(async { load_token().await })
}

pub fn create_login_url() -> LoginUrl {
    block_on(async {
        let raw = crate::local::client(-1).await.unwrap().create_login_url();
        LoginUrl {
            verify: raw.verify,
            url: raw.url,
        }
    })
}

pub fn login_by_code(query: UiLoginByCodeQuery) -> Result<bool> {
    block_on(async {
        let token = client(-1)
            .await
            .unwrap()
            .load_token_by_code(query.code, query.verify)
            .await?;
        set_token(token, chrono::Local::now().timestamp_millis()).await;
        Ok(true)
    })
}

pub fn create_register_url() -> Result<LoginUrl> {
    block_on(async { Ok(crate::local::client(1).await?.create_register_url()) })
}

pub fn request_url(params: String) -> Result<String> {
    block_on(async { client(2).await?.get_from_pixiv_raw(params).await })
}

pub fn illust_from_url(url: String) -> Result<IllustResponse> {
    block_on(async {
        let illust = client(2).await?.illust_from_url(url).await?;
        Ok(illust.into())
    })
}

pub fn illust_recommended_first_url() -> Result<String> {
    block_on(async {
        Ok(crate::local::client(1)
            .await?
            .illust_recommended_first_url())
    })
}

pub fn illust_search_first_url(query: UiIllustSearchQuery) -> Result<String> {
    block_on(async {
        Ok(client(-1)
            .await?
            .illust_search_first_url(query.word, query.mode))
    })
}

pub fn illust_rank_first_url(query: UiIllustRankQuery) -> Result<String> {
    block_on(async {
        Ok(client(-1)
            .await?
            .illust_rank_first_url(query.mode, query.date))
    })
}

pub fn illust_trending_tags() -> Result<IllustTrendingTags> {
    block_on(async { crate::local::client(1).await?.illust_trending_tags().await })
}

pub fn illust_trending_tags_url() -> String {
    block_on(async {
        crate::local::client(-1)
            .await
            .unwrap()
            .illust_trending_tags_url()
    })
}

/// 下载pixiv的图片
pub fn load_pixiv_image(url: String) -> Result<String> {
    block_on(async {
        // hash锁
        let _lock = hash_lock(&url).await;
        // 查找图片是否有缓存
        let db_image = network_image::find_by_url(url.clone()).await?;
        let path = match db_image {
            // 有缓存直接使用
            Some(db_image) => db_image.path,
            // 没有缓存则下载
            None => {
                let now = chrono::Local::now().timestamp_millis();
                let path = format!(
                    "{}{}",
                    hex::encode(md5::compute(url.clone()).to_vec()),
                    &now,
                );
                let client = crate::local::client(0).await?;
                let data: bytes::Bytes = client.load_image_data(url.clone()).await?;
                drop(client);
                let local = join_paths(vec![get_network_image_dir().as_str(), &path]);
                std::fs::write(local, data).unwrap();
                network_image::insert(url.clone(), path.clone(), now.clone()).await?;
                path
            }
        };
        Ok(join_paths(vec![get_network_image_dir().as_str(), &path]))
    })
}

pub fn user_detail(user_id: i64) -> Result<UserDetail> {
    block_on(async { crate::local::client(2).await?.user_detail(user_id).await })
}

pub fn append_to_download(values: Vec<UiAppendToDownload>) -> Result<()> {
    block_on(download::append_to_download(values))
}

pub fn reset_failed_downloads() -> Result<()> {
    block_on(download::reset_failed_downloads())
}

pub fn downloading_list() -> Result<Vec<UiDownloading>> {
    block_on(download::downloading_list())
}
