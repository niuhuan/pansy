import 'package:flutter/material.dart';
import 'package:pansy/basic/cross.dart';
import 'package:pansy/bridge_generated.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
        title: Text(AppLocalizations.of(context)!.login),
      ),
      body: ListView(children: [
        Container(
          padding: const EdgeInsets.all(10),
          child: Text(
            '1. 请您打开VPN或代理, 然后点击下面的打开登录链接\n'
            '2. 打开浏览器后按F12呼出浏览器的调试菜单, 找到network或网络\n'
            '3. 您登录成功后将显示红色pixiv开头的url \n'
            '4. 请将CODE部分填入下面的位置点击确定 (code=*CODE*&via=login)',
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
          padding: EdgeInsets.all(10),
          child: MaterialButton(
            color: Theme.of(context).colorScheme.secondary,
            textColor: Theme.of(context).scaffoldBackgroundColor,
            onPressed: () {
              copyToClipBoard(context, widget.verifyUrl.url);
            },
            child: Container(
              padding: EdgeInsets.all(10),
              child: Text('复制登录链接'),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(10),
          child: TextField(
            controller: _inputController,
            decoration: const InputDecoration(
              labelText: 'Code *',
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(10),
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
              padding: EdgeInsets.all(10),
              child: Text('确认'),
            ),
          ),
        ),
      ]),
    );
  }

  var _inputController = TextEditingController();
}
