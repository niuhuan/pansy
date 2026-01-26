import 'package:flutter/material.dart';
import 'package:pansy/basic/cross.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pansy/screens/settings_screen.dart';
import '../src/rust/pixirust/entities.dart';
import 'login_screen.dart';

class PcLoginScreen extends StatefulWidget {
  final LoginUrl verifyUrl;

  const PcLoginScreen(this.verifyUrl, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PcLoginScreenState();
}

class _PcLoginScreenState extends State<PcLoginScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.loginWithManualCode),
      ),
      body: ListView(children: [
        Container(
          padding: const EdgeInsets.all(10),
          child: Text(
            AppLocalizations.of(context)!.pcLoginNotice,
            style: TextStyle(fontSize: 16),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          child: MaterialButton(
            color: Theme.of(context).colorScheme.secondary,
            textColor: Theme.of(context).scaffoldBackgroundColor,
            onPressed: () {
              openUrl(widget.verifyUrl.url);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Text(AppLocalizations.of(context)!.openLoginUrl),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          child: MaterialButton(
            color: Theme.of(context).colorScheme.secondary,
            textColor: Theme.of(context).scaffoldBackgroundColor,
            onPressed: () {
              copyToClipBoard(context, widget.verifyUrl.url);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Text(AppLocalizations.of(context)!.copyLoginUrl),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          child: TextField(
            controller: _inputController,
            decoration: const InputDecoration(
              labelText: 'Code *',
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          child: MaterialButton(
            color: Theme.of(context).colorScheme.secondary,
            textColor: Theme.of(context).scaffoldBackgroundColor,
            onPressed: () {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (BuildContext context) {
                return LoginScreen(
                    verify: widget.verifyUrl.verify,
                    code: _inputController.text);
              }));
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ),
        ),
      ]),
    );
  }

  static final _inputController = TextEditingController();
}
