import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pansy/basic/cross.dart';
import 'package:pansy/screens/inapp_webview_login_screen.dart';
import 'package:pansy/screens/login_screen.dart';
import 'package:pansy/screens/pc_login_screen.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../src/rust/api/api.dart';
import '../src/rust/pixirust/entities.dart';

const pixivLoginVerifyKey = 'pixiv_login_verify';

final pixivLoginSignal = signal<bool>(false);
bool get pixivLogin => pixivLoginSignal.value;

void setPixivLogin(bool login) {
  pixivLoginSignal.value = login;
}

LoginUrl? verifyUrl;

final appLinks = AppLinks();
StreamSubscription? _sub;

enum PixivLoginMethod {
  inAppWebView,
  externalBrowser,
  manualCode,
}

String? extractPixivLoginCode(Uri uri) {
  // Expected: pixiv://account/login?code=...&via=login
  if (uri.scheme != 'pixiv') return null;
  if (uri.host != 'account') return null;
  if (uri.path.isNotEmpty && uri.path != '/login') return null;
  final code = uri.queryParameters['code'];
  if (code == null || code.isEmpty) return null;
  return code;
}

Future<String?> _loadPendingVerify() async {
  final v = await loadProperty(k: pixivLoginVerifyKey);
  if (v.trim().isEmpty) return null;
  return v;
}

Future<void> clearPendingPixivLogin() async {
  await saveProperty(k: pixivLoginVerifyKey, v: '');
}

Future<void> _handlePixivLoginUri(BuildContext context, Uri? uri) async {
  if (uri == null) return;
  final code = extractPixivLoginCode(uri);
  if (code == null) return;

  final verify = verifyUrl?.verify ?? await _loadPendingVerify();
  if (verify == null) return;

  _sub?.cancel();
  _sub = null;

  if (!context.mounted) return;
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (BuildContext context) {
    return LoginScreen(verify: verify, code: code);
  }));
}

Future<void> pixivLoginAction(
  BuildContext context, {
  required PixivLoginMethod method,
}) async {
  verifyUrl = await createLoginUrl();

  switch (_pickMethodForPlatform(method)) {
    case PixivLoginMethod.inAppWebView:
      await saveProperty(k: pixivLoginVerifyKey, v: verifyUrl!.verify);
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) =>
              InAppWebViewLoginScreen(loginUrl: verifyUrl!),
        ),
      );
      break;
    case PixivLoginMethod.externalBrowser:
      await saveProperty(k: pixivLoginVerifyKey, v: verifyUrl!.verify);
      _sub?.cancel();
      _sub = appLinks.uriLinkStream.listen((uri) {
        _handlePixivLoginUri(context, uri);
      }, onError: (err) {
        print("ERR : $err");
      });
      openUrl(verifyUrl!.url);
      break;
    case PixivLoginMethod.manualCode:
      if (!context.mounted) return;
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (BuildContext context) {
        return PcLoginScreen(verifyUrl!);
      }));
      break;
  }
}

PixivLoginMethod _pickMethodForPlatform(PixivLoginMethod requested) {
  if (Platform.isLinux && requested != PixivLoginMethod.manualCode) {
    return PixivLoginMethod.manualCode;
  }
  if ((Platform.isAndroid || Platform.isIOS) &&
      requested == PixivLoginMethod.manualCode) {
    return PixivLoginMethod.externalBrowser;
  }
  if ((Platform.isWindows || Platform.isMacOS) &&
      requested == PixivLoginMethod.externalBrowser) {
    return PixivLoginMethod.inAppWebView;
  }
  return requested;
}
