/// 平台信息

import 'dart:io';
import '../cross.dart';

int androidVersion = 0;

Future<void> initPlatform()async{
  if (Platform.isAndroid) {
    androidVersion = await cross.androidGetVersion();
  }
}