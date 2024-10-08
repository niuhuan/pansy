import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pansy/screens/components/mouse_and_touch_scroll_behavior.dart';
import 'package:pansy/screens/init_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pansy/src/rust/frb_generated.dart';

void main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      scrollBehavior: mouseAndTouchScrollBehavior,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const InitScreen(),
    );
  }
}
