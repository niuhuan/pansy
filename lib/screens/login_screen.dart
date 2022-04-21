import 'package:flutter/material.dart';
import 'package:pansy/ffi.dart';
import 'package:pansy/screens/components/content_builder.dart';
import 'package:pansy/states/pixiv_login.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    await api.loginByCode(query: LoginByCodeQuery(code: widget.code, verify: widget.verify));
    setPixivLogin(true);
    Navigator.of(context).pop();
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
          return Container();
        },
        loadingLabel: AppLocalizations.of(context)!.logging,
      ),
    );
  }
}
