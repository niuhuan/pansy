import 'package:flutter/material.dart';
import 'package:pansy/screens/components/mouse_and_touch_scroll_behavior.dart';
import 'package:pansy/screens/init_screen.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: mouseAndTouchScrollBehavior,
      home: const InitScreen(),
    );
  }
}
