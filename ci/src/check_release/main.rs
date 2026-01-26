use anyhow::Result;
use std::collections::HashMap;
use std::process::exit;

const UA: &str = "actions ci";

#[tokio::main]
async fn main() -> Result<()> {
    let gh_token = std::env::var("GITHUB_TOKEN")?;
    if gh_token.is_empty() {
        panic!("Please set GITHUB_TOKEN");
    }

    let repo = std::env::var("GITHUB_REPOSITORY")?;
    if repo.is_empty() {
        panic!("Can't got repo path");
    }

    let branch = std::env::var("GITHUB_HEAD_REF")?;
    if repo.is_empty() {
        panic!("Can't got repo branch");
    }

    let mut code = std::env::var("RELEASE_TAG").unwrap_or_default();
    if code.trim().is_empty() {
        code = tokio::fs::read_to_string("version.tag.txt").await.unwrap_or_default();
    }
    let code = code.trim();
    if code.is_empty() {
        panic!("Missing RELEASE_TAG (or ci/version.tag.txt)");
    }

    let info_txt = tokio::fs::read_to_string("changelog.txt").await?;
    let info = info_txt.trim();

    let client = reqwest::ClientBuilder::new().user_agent(UA).build()?;

    let release_url = format!("https://api.github.com/repos/{repo}/releases/tags/{code}");
    let check_response = client.get(release_url)
        .header("Authorization", format!("token {}", gh_token)).send().await?;

    match check_response.status().as_u16() {
        200 => {
            println!("release exists");
            exit(0);
        }
        404 => (),
        code => {
            let text = check_response.text().await?;
            panic!("error for check release : {} : {}", code, text);
        }
    }
    drop(check_response);

    // 404

    let releases_url = format!("https://api.github.com/repos/{repo}/releases");
    let check_response = client
        .post(releases_url)
        .header("Authorization", format!("token {}", gh_token))
        .json(&{
            let mut params = HashMap::<String, String>::new();
            params.insert("tag_name".to_string(), code.to_string());
            params.insert("target_commitish".to_string(), branch);
            params.insert("name".to_string(), code.to_string());
            params.insert("body".to_string(), info.to_string());
            params
        })
        .send()
        .await?;

    match check_response.status().as_u16() {
        201 => (),
        code => {
            let text = check_response.text().await?;
            panic!("error for create release : {} : {}", code, text);
        }
    }
    Ok(())
}
