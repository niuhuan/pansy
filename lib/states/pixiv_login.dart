import 'dart:io';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:pansy/basic/cross.dart';
import 'package:pansy/screens/login_screen.dart';
import 'package:pansy/screens/pc_login_screen.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';

import '../src/rust/api/api.dart';
import '../src/rust/pixirust/entities.dart';
import '../src/rust/udto.dart';

bool pixivLogin = false;
Event pixivLoginEvent = Event();

void setPixivLogin(bool login) {
  pixivLogin = login;
  pixivLoginEvent.broadcast();
}

LoginUrl? verifyUrl;

final appLinks = AppLinks();
StreamSubscription? _sub;

Future<void> pixivLoginAction(BuildContext context) async {
  verifyUrl = await createLoginUrl();
  if (Platform.isAndroid || Platform.isIOS) {
    _sub?.cancel();
    _sub = appLinks.uriLinkStream.listen((uri) {
      if (verifyUrl != null && uri != null) {
        var link = uri.toString();
        String link1 = link.replaceAll("pixiv://account/login?code=", "");
        link1 = link1.replaceAll("&via=login", "");
        if (link1 != link) {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (BuildContext context) {
            return LoginScreen(verify: verifyUrl!.verify, code: link1);
          }));
          loginByCode(
              query:
                  UiLoginByCodeQuery(code: link1, verify: verifyUrl!.verify));
        }
      }
    }, onError: (err) {
      print("ERR : $err");
    });
    openUrl(verifyUrl!.url);
  } else {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      return PcLoginScreen(verifyUrl!);
    }));
  }
}
