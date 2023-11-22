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
    if (androidVersion < 30) {
      defaultToast(
        context,
        AppLocalizations.of(context)!.androidApi29AndLowerNotSupport,
      );
      return false;
    } else {
      var g = await Permission.manageExternalStorage.request().isGranted;
      if (!g) {
        defaultToast(
          context,
          AppLocalizations.of(context)!.permissionDenied,
        );
        return false;
      }
    }
    var recreateDownloadsTo =
        await api.loadProperty(k: "recreate_downloads_to");
    if (recreateDownloadsTo.isEmpty) {
      try {
        await api.recreateDownloadsTo();
        await api.saveProperty(k: "recreate_downloads_to", v: "1");
        return true;
      } catch (e, s) {
        defaultToast(
          context,
          AppLocalizations.of(context)!.setDownloadsToFailed + '\n$e',
        );
        return false;
      }
    }
  } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    var recreateDownloadsTo =
        await api.loadProperty(k: "recreate_downloads_to");
    if (recreateDownloadsTo.isEmpty) {
      final choose = await FilePicker.platform.getDirectoryPath(
        dialogTitle: AppLocalizations.of(context)!.selectDownloadsTo,
        initialDirectory: await api.downloadsTo(),
        lockParentWindow: true,
      );
      if (choose != null) {
        try {
          await api.setDownloadsTo(newDownloadsTo: choose);
          await api.saveProperty(k: "recreate_downloads_to", v: "1");
          return true;
        } catch (e, s) {
          defaultToast(
            context,
            AppLocalizations.of(context)!.setDownloadsToFailed + '\n$e',
          );
          return false;
        }
      }
      return true;
    }
  }
  return true;
}
