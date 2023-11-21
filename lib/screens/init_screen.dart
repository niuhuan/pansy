import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pansy/basic/config/in_china.dart';
import 'package:pansy/ffi.dart';
import 'package:pansy/screens/app_screen.dart';
import 'package:pansy/states/pixiv_login.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../basic/commons.dart';
import '../basic/platform.dart';
import '../cross.dart';

class InitScreen extends StatefulWidget {
  const InitScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  @override
  void initState() {
    _init();
    super.initState();
  }

  Future<void> _init() async {
    await initPlatform();
    if (Platform.isAndroid) {
      late bool g;
      if (androidVersion < 30) {
        g = await Permission.storage.request().isGranted;
      } else {
        g = await Permission.manageExternalStorage.request().isGranted;
      }
      if (!g) {
        defaultToast(
          context,
          AppLocalizations.of(context)!.permissionDenied,
        );
        exit(0);
      }
    }
    await api.init(
      root: await cross.root(),
      downloadsTo: await cross.downloads(),
    );
    await initInChina();
    setPixivLogin(await api.preLogin());
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (BuildContext context) => const AppScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffdfdff2),
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            child: Center(
              child: Image.asset(
                "lib/assets/startup.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
