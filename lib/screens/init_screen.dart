import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:pansy/basic/config/download_dir.dart';
import 'package:pansy/basic/config/download_save_target.dart';
import 'package:pansy/basic/config/use_download_queue.dart';
import 'package:pansy/basic/config/illust_display.dart';
import 'package:pansy/basic/config/picture_source.dart';
import 'package:pansy/basic/config/sni_bypass.dart';
import 'package:pansy/basic/stores/tag_history_store.dart';
import 'package:pansy/screens/hello_screen.dart';
import 'package:pansy/screens/login_screen.dart';
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
  final _appLinks = AppLinks();

  @override
  void initState() {
    _init();
    super.initState();
  }

  Future<bool> _maybeHandleInitialPixivLogin() async {
    final uri = await _appLinks.getInitialLink();
    if (uri == null) return false;
    if (uri.scheme != 'pixiv') return false;
    if (uri.host != 'account') return false;
    if (uri.path.isNotEmpty && uri.path != '/login') return false;
    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) return false;

    final verify = await loadProperty(k: pixivLoginVerifyKey);
    if (verify.trim().isEmpty) return false;

    if (!mounted) return true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (BuildContext context) => LoginScreen(verify: verify, code: code),
      ),
    );
    return true;
  }

  Future<void> _init() async {
    await initPlatform();
    await init(root: await cross.root());
    await initPictureSource();
    await initSniBypass();
    await initSniBypassHosts();
    await initDownloadDir();
    await initDownloadSaveTarget();
    await initUseDownloadQueue();
    await initIllustOnlyShowImages();
    await initTagHistory();
    setPixivLogin(await preLogin());

    if (await _maybeHandleInitialPixivLogin()) {
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (BuildContext context) => const HelloScreen()),
    );
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
              child: Image.asset("lib/assets/startup.png", fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}
