import 'package:flutter/material.dart';
import 'package:pansy/basic/config/in_china.dart';
import 'package:pansy/screens/app_screen.dart';
import 'package:pansy/states/pixiv_login.dart';
import '../basic/platform.dart';
import '../cross.dart';
import '../src/rust/api/api.dart';

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
    await init(
      root: await cross.root(),
      downloadsTo: await cross.downloads(),
    );
    await initInChina();
    setPixivLogin(await preLogin());
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
