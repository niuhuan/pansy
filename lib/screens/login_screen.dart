import 'package:flutter/material.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:pansy/screens/hello_screen.dart';
import 'package:pansy/screens/components/content_builder.dart';
import 'package:pansy/screens/settings_screen.dart';
import 'package:pansy/states/pixiv_login.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../src/rust/udto.dart';

class LoginScreen extends StatefulWidget {
  final String verify;
  final String code;

  const LoginScreen({Key? key, required this.verify, required this.code})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late Future<void> _future = _init();

  Future<void> _init() async {
    await loginByCode(
        query: UiLoginByCodeQuery(code: widget.code, verify: widget.verify));
    await clearPendingPixivLogin();
    setPixivLogin(true);
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HelloScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ContentBuilder(
        future: _future,
        onRefresh: () async {
          setState(() {
            _future = _init();
          });
        },
        successBuilder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.success),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HelloScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            ),
          );
        },
        loadingLabel: AppLocalizations.of(context)!.logging,
      ),
    );
  }
}
