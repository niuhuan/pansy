import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pansy/src/rust/api/api.dart';
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

  Future<int> androidGetVersion() async {
    if (!Platform.isAndroid) return 0;
    return await _channel.invokeMethod("androidGetVersion");
  }

  Future<bool> saveImageToGallery(String path) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return false;
    final ok = await _channel.invokeMethod("saveImageToGallery", {
      "path": path,
    });
    return ok == true;
  }

  Future<String?> saveFileToDownloads({
    required String path,
    required String fileName,
    required String subDir,
  }) async {
    if (!Platform.isAndroid) return null;
    final result = await _channel.invokeMethod("saveFileToDownloads", {
      "path": path,
      "fileName": fileName,
      "subDir": subDir,
    });
    return result is String ? result : null;
  }
}

/// 打开web页面
Future<dynamic> openUrl(String url) async {
  if (await canLaunch(url)) {
    await launch(url, forceSafariVC: false);
  }
}
