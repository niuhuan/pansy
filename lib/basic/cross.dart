/// 与平台交互的操作

import 'dart:io';
import 'package:clipboard/clipboard.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pansy/ffi.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'commons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

const _cross = _Cross._();

class _Cross {
  const _Cross._();

  final _channel = const MethodChannel("cross");

  Future saveImageFileToGallery(String path) {
    return _channel.invokeMethod("saveImageToGallery", path);
  }
}

/// 复制内容到剪切板
void copyToClipBoard(BuildContext context, String string) {
  FlutterClipboard.copy(string);
  defaultToast(context, AppLocalizations.of(context)!.copied);
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

Future<dynamic> savePixivImage(String url, BuildContext context) async {
  var path = await api.loadPixivImage(url: url);
  await saveImageFileToGallery(path, context);
}

Future saveImageFileToGallery(String path, BuildContext context) async {
  if (Platform.isAndroid) {
    if (!(await Permission.storage.request()).isGranted) {
      return;
    }
  }
  if (Platform.isIOS || Platform.isAndroid) {
    try {
      await _cross.saveImageFileToGallery(path);
      defaultToast(
        context,
        AppLocalizations.of(context)!.success,
      );
    } catch (e) {
      errorToast(
        context,
        "${AppLocalizations.of(context)!.failed} : $e",
      );
    }
  } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      try {
        await api.copyImageTo(srcPath: path, toDir: selectedDirectory);
        defaultToast(
          context,
          AppLocalizations.of(context)!.success,
        );
      } catch (e) {
        errorToast(
          context,
          "${AppLocalizations.of(context)!.failed} : $e",
        );
      }
    }
  }
}

void confirmCopy(BuildContext context, String content) async {
  if (await confirmDialog(
      context, AppLocalizations.of(context)!.copy, content)) {
    copyToClipBoard(context, content);
  }
}
