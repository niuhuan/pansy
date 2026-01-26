use crate::entities::{network_image, property, download_task};
use crate::local::{
    client, get_in_china_, hash_lock, init_bypass_sni_settings, join_paths,
    load_in_china, load_token, set_bypass_sni_cache, set_bypass_sni_hosts_cache, set_in_china_,
    set_token,
};
use crate::pixirust::client::{IllustTrendingTags, UserDetail};
use crate::pixirust::entities::{IllustResponse, UserPreviewsResponse};
use crate::pixirust::entities::LoginUrl;
use crate::udto::*;
use crate::get_network_image_dir;
use anyhow::{Context, Ok, Result};
use std::collections::HashMap;
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

pub fn init(root: String) -> Result<()> {
    crate::init_root(&root);
    block_on(async {
        load_in_china().await;
        init_bypass_sni_settings().await;
    });
    Ok(())
}

pub fn save_property(k: String, v: String) -> Result<()> {
    block_on(async move {
        let key = k.clone();
        let value = v.clone();
        property::save_property(k, v).await?;
        if key == "bypass_sni" {
            let vv = value.trim().to_lowercase();
            let parsed = vv == "true" || vv == "1" || vv == "yes";
            set_bypass_sni_cache(parsed).await;
        } else if key == "bypass_sni_hosts" {
            if let std::result::Result::Ok(map) =
                serde_json::from_str::<HashMap<String, String>>(&value)
            {
                set_bypass_sni_hosts_cache(map).await;
            }
        }        
        Ok(())
    })    
}

pub fn load_property(k: String) -> Result<String> {
    block_on(async move { Ok(property::load_property(k).await?) })
}

fn block_on<T>(f: impl Future<Output = T>) -> T {
    crate::RUNTIME.block_on(f)
}

pub fn copy_image_to(src_path: String, to_dir: String) -> Result<()> {
    let src = Path::new(&src_path);
    let name = src.file_name().unwrap().to_str().unwrap();
    let final_name = if src.extension().is_some() {
        name.to_owned()
    } else {
        let ext = image::ImageReader::open(&src_path)?
            .with_guessed_format()?
            .format()
            .with_context(|| anyhow::Error::msg("img format error"))?
            .extensions_str()[0];
        format!("{}.{}", name, ext)
    };
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

pub fn user_previews_from_url(url: String) -> Result<UserPreviewsResponse> {
    block_on(async {
        let result = client(2).await?.user_previews_from_url(url).await?;
        Ok(result.into())
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
        let url = client(-1)
            .await?
            .illust_search_first_url(query.word, query.search_target, query.sort);
        println!("Search URL: {}", url);
        Ok(url)
    })
}

pub fn illust_rank_first_url(query: UiIllustRankQuery) -> Result<String> {
    block_on(async {
        Ok(client(-1)
            .await?
            .illust_rank_first_url(query.mode, query.date))
    })
}

pub fn user_illusts_first_url(user_id: i64) -> Result<String> {
    block_on(async {
        Ok(client(-1).await?.user_illusts_first_url(user_id))
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
            // 有缓存直接使用（如果文件仍存在）
            Some(db_image) => {
                let local = join_paths(vec![get_network_image_dir().as_str(), &db_image.path]);
                if Path::new(&local).exists() {
                    db_image.path
                } else {
                    // db 有记录但文件被清理/丢失，删除记录并重新下载
                    let _ = network_image::delete_by_url(url.clone()).await;
                    let now = chrono::Local::now().timestamp_millis();
                    let client = crate::local::client(0).await?;
                    let data: bytes::Bytes = client.load_image_data(url.clone()).await?;
                    drop(client);
                    let f = image::guess_format(data.as_ref())?;
                    let ext = f.extensions_str()[0];
                    let path = format!(
                        "{}_{}.{}",
                        hex::encode(md5::compute(url.clone()).to_vec()),
                        &now,
                        ext,
                    );
                    let local = join_paths(vec![get_network_image_dir().as_str(), &path]);
                    std::fs::write(local, data).unwrap();
                    network_image::insert(url.clone(), path.clone(), now.clone()).await?;
                    path
                }
            }
            // 没有缓存则下载
            None => {
                let now = chrono::Local::now().timestamp_millis();
                let client = crate::local::client(0).await?;
                let data: bytes::Bytes = client.load_image_data(url.clone()).await?;
                drop(client);
                let f = image::guess_format(data.as_ref())?;
                let ext = f.extensions_str()[0];
                let path = format!(
                    "{}_{}.{}",
                    hex::encode(md5::compute(url.clone()).to_vec()),
                    &now,
                    ext,
                );
                let local = join_paths(vec![get_network_image_dir().as_str(), &path]);
                std::fs::write(local, data).unwrap();
                network_image::insert(url.clone(), path.clone(), now.clone()).await?;
                path
            }
        };
        Ok(join_paths(vec![get_network_image_dir().as_str(), &path]))
    })
}

/// 清除图片缓存（Pixiv 图片缓存 + 索引表）
pub fn clear_image_cache() -> Result<()> {
    block_on(async {
        // 先清理索引表（避免并发读取到旧记录）
        let _ = network_image::delete_all().await?;
        // 再删除实际缓存文件
        let dir = get_network_image_dir().clone();
        if Path::new(dir.as_str()).exists() {
            for entry in std::fs::read_dir(dir.as_str())? {
                let entry = entry?;
                let path = entry.path();
                if path.is_file() {
                    let _ = std::fs::remove_file(path);
                }
            }
        }
        Ok(())
    })
}

pub fn user_detail(user_id: i64) -> Result<UserDetail> {
    block_on(async { crate::local::client(2).await?.user_detail(user_id).await })
}

pub fn follow_user(user_id: i64, restrict: String) -> Result<()> {
    block_on(async { crate::local::client(2).await?.follow_user(user_id, restrict).await })
}

pub fn unfollow_user(user_id: i64) -> Result<()> {
    block_on(async { crate::local::client(2).await?.unfollow_user(user_id).await })
}

pub fn user_following(user_id: i64, restrict: String) -> Result<UserPreviewsResponse> {
    block_on(async { 
        crate::local::client(2).await?.user_following(user_id, restrict).await
    })
}

pub fn user_bookmarks(user_id: i64, restrict: String, tag: Option<String>) -> Result<IllustResponse> {
    block_on(async {
        let result = crate::local::client(2).await?.user_bookmarks(user_id, restrict, tag).await?;
        Ok(result.into())
    })
}

pub fn add_bookmark(illust_id: i64, restrict: String) -> Result<()> {
    block_on(async { crate::local::client(2).await?.add_bookmark(illust_id, restrict).await })
}

pub fn delete_bookmark(illust_id: i64) -> Result<()> {
    block_on(async { crate::local::client(2).await?.delete_bookmark(illust_id).await })
}

pub fn current_user() -> Result<Option<UiCurrentUser>> {
    block_on(async {
        let period = crate::local::TOKEN.lock().await;
        if period.created_time == 0 {
            return Ok(None);
        }
        let user = &period.token.user;
        Ok(Some(UiCurrentUser {
            user_id: user.id.parse().unwrap_or(0),
            name: user.name.clone(),
            account: user.account.clone(),
            profile_image_url: user.profile_image_urls.px_170x170.clone(),
            is_premium: user.is_premium,
        }))
    })
}

// ============= Download Task Management =============

pub fn create_download_task(
    illust_id: i64,
    illust_title: String,
    page_index: i32,
    page_count: i32,
    url: String,
    target_path: String,
    save_target: String,
) -> Result<i64> {
    block_on(async {
        let task = download_task::insert(
            illust_id,
            illust_title,
            page_index,
            page_count,
            url,
            target_path,
            save_target,
        )
        .await?;
        Ok(task.id)
    })
}

pub fn get_all_download_tasks() -> Result<Vec<DownloadTaskDto>> {
    block_on(async {
        let tasks = download_task::find_all().await?;
        Ok(tasks.into_iter().map(|t| DownloadTaskDto {
            id: t.id,
            illust_id: t.illust_id,
            illust_title: t.illust_title,
            page_index: t.page_index,
            page_count: t.page_count,
            url: t.url,
            target_path: t.target_path,
            save_target: t.save_target,
            status: t.status,
            progress: t.progress,
            error_message: t.error_message,
            retry_count: t.retry_count,
            created_time: t.created_time,
            updated_time: t.updated_time,
        }).collect())
    })
}

pub fn get_pending_download_tasks() -> Result<Vec<DownloadTaskDto>> {
    block_on(async {
        let tasks = download_task::find_pending().await?;
        Ok(tasks.into_iter().map(|t| DownloadTaskDto {
            id: t.id,
            illust_id: t.illust_id,
            illust_title: t.illust_title,
            page_index: t.page_index,
            page_count: t.page_count,
            url: t.url,
            target_path: t.target_path,
            save_target: t.save_target,
            status: t.status,
            progress: t.progress,
            error_message: t.error_message,
            retry_count: t.retry_count,
            created_time: t.created_time,
            updated_time: t.updated_time,
        }).collect())
    })
}

pub fn update_download_task_status(
    id: i64,
    status: String,
    progress: i32,
    error_message: String,
) -> Result<()> {
    block_on(async {
        download_task::update_status(id, status, progress, error_message).await?;
        Ok(())
    })
}

pub fn retry_download_task(id: i64) -> Result<()> {
    block_on(async {
        download_task::retry_failed_task(id).await?;
        Ok(())
    })
}

pub fn delete_download_task(id: i64) -> Result<()> {
    block_on(async {
        download_task::delete_by_id(id).await?;
        Ok(())
    })
}

pub fn delete_completed_download_tasks() -> Result<()> {
    block_on(async {
        download_task::delete_completed().await?;
        Ok(())
    })
}

pub fn execute_download_task(id: i64) -> Result<()> {
    block_on(async {
        let task = download_task::find_by_id(id).await?;
        if let Some(task) = task {
            // Update status to downloading
            download_task::update_status(id, "downloading".to_string(), 0, "".to_string()).await?;
            
            match _execute_single_download(&task).await {
                std::result::Result::Ok(_) => {
                    download_task::update_status(id, "completed".to_string(), 100, "".to_string()).await?;
                }
                Err(e) => {
                    let error_msg = format!("{:?}", e);
                    download_task::update_status(id, "failed".to_string(), 0, error_msg).await?;
                    download_task::update_retry_count(id, task.retry_count + 1).await?;
                }
            }
        }
        Ok(())
    })
}

async fn _execute_single_download(task: &download_task::Model) -> Result<()> {
    // Download the image to cache first
    let _lock = hash_lock(&task.url).await;
    let db_image = network_image::find_by_url(task.url.clone()).await?;
    let _cached_path = match db_image {
        Some(db_image) => {
            join_paths(vec![get_network_image_dir().as_str(), &db_image.path])
        }
        None => {
            let now = chrono::Local::now().timestamp_millis();
            let client = crate::local::client(0).await?;
            let data: bytes::Bytes = client.load_image_data(task.url.clone()).await?;
            drop(client);
            let f = image::guess_format(data.as_ref())?;
            let ext = f.extensions_str()[0];
            let path = format!(
                "{}_{}.{}",
                hex::encode(md5::compute(task.url.clone()).to_vec()),
                &now,
                ext,
            );
            let local = join_paths(vec![get_network_image_dir().as_str(), &path]);
            std::fs::write(&local, data)?;
            network_image::insert(task.url.clone(), path.clone(), now).await?;
            local
        }
    };

    // The actual saving to target will be handled by Flutter side
    // This just ensures the image is cached
    Ok(())
}
