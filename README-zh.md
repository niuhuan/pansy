PANSY
======
[English](README.md) | 简体中文

一个简洁的二次元插图社区客户端, 适配 mac, windows, linux, ios, Android.

## 软件截图

#### 发现与热门

![](images/discovery.png)
![](images/rank.png)

#### 插画详情

![](images/info_screen.png)
![](images/info_screen2.png)

#### 搜索与分类

![](images/search.png)
![](images/search_screen.png)

## 详情

### 支持的平台

|   平台   | 最小版本 |
|:------------:|:---------------:|
|   Android    |   API 30 (10)   |
|    Macos     |      10.15      |
| iOS / iPadOS |       13        |
|   Windows    |   10 (64bit)    |
|    Linux     |     - 64bit     |

## 网络

- `设置 > 网络 > 图片站点`：切换图片加载域名（默认 / 代理 / 自定义）。
- `设置 > 网络 > 绕过 SNI（不安全）`：通过直连 Pixiv 的 IP 尝试绕过基于 SNI 的干扰；会关闭 TLS 证书校验。
- `设置 > 网络 > SNI 绕过映射`：维护绕过 SNI 时使用的 域名→IP 映射。

## 技术架构

- [rust](https://github.com/rust-lang/rust)
- [flutter](https://github.com/flutter/flutter)
- [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge) 
  - 您必须将它从**github**克隆到本地, 并在codeGen中运行" ***cargo install --path .*** "

![](https://raw.githubusercontent.com/fzyzcjy/flutter_rust_bridge/master/book/logo.png)
