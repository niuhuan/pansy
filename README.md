PANSY
======
English | [简体中文](README-zh.md)

A beautiful illustration clients, support mac, windows, linux, ios, Android.

## Screenshoots

#### Discovery and Ranks

![](images/discovery.png)
![](images/rank.png)

#### Illustration info

![](images/info_screen.png)
![](images/info_screen2.png)

#### Search and categories

![](images/search.png)
![](images/search_screen.png)

## Details

### Supported Platforms

|   Platform   | minimum version |
|:------------:|:---------------:|
|   Android    |   API 30 (10)   |
|    Macos     |      10.15      |
| iOS / iPadOS |       13        |
|   Windows    |   10 (64bit)    |
|    Linux     |     - 64bit     |

## Network

- `Settings > Network > Image host`: switch image CDN host (default / proxy / custom).
- `Settings > Network > Bypass SNI (insecure)`: connects to Pixiv IP directly to avoid SNI-based blocking; disables TLS certificate verification.
- `Settings > Network > SNI bypass hosts`: maintain the domain → IP mapping used by SNI bypass.

## Technical structure

- [rust](https://github.com/rust-lang/rust)
- [flutter](https://github.com/flutter/flutter)
- [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge) 
  - Clone form **github** and run " ***cargo install --path .*** " on code gen.

![](https://raw.githubusercontent.com/fzyzcjy/flutter_rust_bridge/master/book/logo.png)

## Icons

Run `bash resources/icon/update_icons.sh` to regenerate platform icons from `resources/icon/background.svg` and `resources/icon/foreground.svg`.
