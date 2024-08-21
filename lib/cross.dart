import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:pansy/src/rust/frb_generated.dart';
import 'package:url_launcher/url_launcher.dart';

const cross = Cross._();

class Cross {
  const Cross._();

  static const _channel = MethodChannel("cross");

  Future<String> root() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await _channel.invokeMethod("root");
    }
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return await desktopRoot();
    }
    throw "没有适配的平台";
  }

  Future<String> downloads() async {
    if (Platform.isIOS) {
      return await _channel.invokeMethod("downloads_to");
    } else if (Platform.isAndroid) {
      return await _channel.invokeMethod("downloads_to");
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return await downloadsTo();
    }
    throw "没有适配的平台";
  }

  Future saveImageToGallery(String path) async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await _channel.invokeMethod("saveImageToGallery", path);
    }
    throw "没有适配的平台";
  }

  Future<int> androidGetVersion() async {
    return await _channel.invokeMethod("androidGetVersion");
  }
}

/// 打开web页面
Future<dynamic> openUrl(String url) async {
  if (await canLaunch(url)) {
    await launch(
      url,
      forceSafariVC: false,
    );
  }
}
