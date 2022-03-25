import 'package:event/event.dart';
import 'package:flutter/material.dart';

Event themeEvent = Event();

var theme = _themes[0];

var _themes = [
  ThemeData.light().copyWith(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      secondary: Colors.pink.shade200,
    ),
    appBarTheme: AppBarTheme(
      color: Colors.pink.shade200,
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Colors.pink[300],
      unselectedItemColor: Colors.grey[500],
    ),
    dividerColor: Colors.grey.shade200,
  ),
  ThemeData.light(),
  ThemeData.light().copyWith(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      secondary: Colors.pink.shade200,
    ),
    appBarTheme: AppBarTheme(
      color: Colors.grey.shade800,
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey[400],
      backgroundColor: Colors.grey.shade800,
    ),
    dividerColor: Colors.grey.shade200,
  )
];
