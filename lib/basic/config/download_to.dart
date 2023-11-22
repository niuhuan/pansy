import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pansy/basic/commons.dart';
import 'package:pansy/ffi.dart';
import 'package:permission_handler/permission_handler.dart';

import '../platform.dart';

Future<bool> checkDownloadsTo(BuildContext context) async {
  if (Platform.isAndroid) {
    if (Platform.isAndroid) {
      late bool g;
      if (androidVersion < 30) {
        g = await Permission.storage.request().isGranted;
      } else {
        g = await Permission.manageExternalStorage.request().isGranted;
      }
      if (!g) {
        defaultToast(
          context,
          AppLocalizations.of(context)!.permissionDenied,
        );
        return false;
      }
    }
    var downloadsTo = await api.loadProperty(k: "downloads_to");
    if (downloadsTo.isEmpty) {
      String? newDownloadsTo = await FilePicker.platform.getDirectoryPath(
        dialogTitle: AppLocalizations.of(context)!.selectDownloadsTo,
      );
      if (newDownloadsTo != null) {
        try {
          await api.setDownloadsTo(newDownloadsTo: newDownloadsTo);
        } catch (e, s) {
          defaultToast(
            context,
            AppLocalizations.of(context)!.setDownloadsToFailed + '\n$e',
          );
          return false;
        }
      } else {
        defaultToast(
          context,
          AppLocalizations.of(context)!.mustChooseDownloadsTo,
        );
        return false;
      }
    }
  }
  return true;
}
