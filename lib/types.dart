import 'dart:convert';

import 'package:pansy/ffi.dart';



Future<IllustRecommendedResponse> illustPageByUrl(String url) async {
  var j = await api.requestUrl(params: url);
  print(j);
  return IllustRecommendedResponse.fromJson(
    jsonDecode(j),
  );
}

Future<IllustTrendingTags> illustTrendingTags() async {
  return IllustTrendingTags.fromJson(jsonDecode(
    await api.requestUrl(params: await api.illustTrendingTagsUrl()),
  ));
}

class VerifyUrl {
  late String verify;
  late String url;

  VerifyUrl.fromJson(Map<String, dynamic> json) {
    verify = json["verify"];
    url = json["url"];
  }
}

class IllustRecommendedResponse {
  late List<Illust> illusts;
  late String nextUrl;

  IllustRecommendedResponse.fromJson(Map<String, dynamic> json) {
    this.illusts = List.of(json["illusts"])
        .map((e) => Map<String, dynamic>.of(e))
        .map((e) => Illust.fromJson(e))
        .toList();
    this.nextUrl = json["next_url"];
  }
}

class UserPreview {
  late int id;
  late String name;
  late String account;
  late bool isFollowed;
  late UserAuthorProfileImageUrls profileImageUrls;

  UserPreview.fromJson(Map<String, dynamic> json) {
    this.id = json["id"];
    this.name = json["name"];
    this.account = json["account"];
    this.isFollowed = json["is_followed"];
    this.profileImageUrls =
        UserAuthorProfileImageUrls.fromJson(json["profile_image_urls"]);
  }
}

class UserAuthorProfileImageUrls {
  late String medium;

  UserAuthorProfileImageUrls.fromJson(Map<String, dynamic> json) {
    this.medium = json["medium"];
  }
}

class Illust {
  late int id;
  late String title;
  late String type;
  late int width;
  late int height;
  late ImageUrls imageUrls;
  late List<MetaPage> metaPages;
  late MetaSinglePage metaSinglePage;
  late UserPreview user;
  late DateTime createDate;

  Illust.fromJson(Map<String, dynamic> json) {
    this.id = json["id"];
    this.title = json["title"];
    this.type = json["type"];
    this.width = json["width"];
    this.height = json["height"];
    this.imageUrls = ImageUrls.fromJson(json["image_urls"]);
    this.metaPages = List.of(json["meta_pages"])
        .map((e) => Map<String, dynamic>.of(e))
        .map((e) => MetaPage.fromJson(e))
        .toList();
    this.metaSinglePage = MetaSinglePage.fromJson(json["meta_single_page"]);
    this.user = UserPreview.fromJson(json["user"]);
    this.createDate = DateTime.parse(json["create_date"]);
  }
}

class ImageUrls {
  late String squareMedium;
  late String medium;
  late String large;

  ImageUrls.fromJson(Map<String, dynamic> json) {
    this.squareMedium = json["square_medium"];
    this.medium = json["medium"];
    this.large = json["large"];
  }

  ImageUrls(
      {required this.squareMedium, required this.medium, required this.large});
}

class MetaImageUrls extends ImageUrls {
  late String original;

  MetaImageUrls.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.original = json["original"];
  }

  MetaImageUrls({
    required String squareMedium,
    required String medium,
    required String large,
    required this.original,
  }) : super(
          squareMedium: squareMedium,
          medium: medium,
          large: large,
        );
}

class MetaPage {
  late MetaImageUrls imageUrls;

  MetaPage.fromJson(Map<String, dynamic> json) {
    imageUrls = MetaImageUrls.fromJson(json["image_urls"]);
  }

  MetaPage(this.imageUrls);
}

class MetaSinglePage {
  late String? originalImageUrl;

  MetaSinglePage.fromJson(Map<String, dynamic> json) {
    originalImageUrl = json["original_image_url"];
  }
}

class PixivProfile {
  PixivProfile.fromJson(jsonDecode) {}
}

class IllustTrendingTags {
  late List<TrendTag> trendTags;

  IllustTrendingTags.fromJson(json) {
    trendTags = List.of(json["trend_tags"])
        .map((e) => TrendTag.fromJson(e))
        .toList()
        .cast<TrendTag>();
  }
}

class TrendTag {
  late String tag;
  late String? translatedName;
  late Illust illust;

  TrendTag.fromJson(json) {
    tag = json["tag"];
    translatedName = json["translated_name"];
    illust = Illust.fromJson(json["illust"]);
  }
}
