/// 与平台交互的操作

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'commons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

void confirmCopy(BuildContext context, String content) async {
  if (await confirmDialog(
      context, AppLocalizations.of(context)!.copy, content)) {
    copyToClipBoard(context, content);
  }
}
