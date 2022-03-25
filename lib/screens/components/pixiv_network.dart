const ImageHost = "i.pximg.net";
const ImageCatHost = "i.pixiv.re";
const ImageSHost = "s.pximg.net";

Map<String, dynamic> _constMap = {
  "app-api.pixiv.net": "210.140.131.199",
  "oauth.secure.pixiv.net": "210.140.131.199",
  "i.pximg.net": "210.140.92.143",
  "s.pximg.net": "210.140.92.140",
  "doh": "1.0.0.1",
};

String pixivUrl(String url) {
  return url.replaceFirst(ImageHost, "s.pximg.net");
}

Map<String, String> pixivHeader(String url) {
  return {
    "referer": "https://app-api.pixiv.net/",
    "User-Agent": "PixivIOSApp/5.8.0",
    "Host": "i.pximg.net",
  };
}
