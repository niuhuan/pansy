import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:signals_flutter/signals_flutter.dart';

const downloadDirKey = 'download_dir';

/// Empty means using platform default.
final downloadDirSignal = signal<String>('');

/// macOS sandbox permissions may be lost across restarts; force a per-session
/// folder re-pick the first time the user downloads to file.
final downloadDirSessionConfirmedSignal = signal<bool>(false);

Future<void> initDownloadDir() async {
  final v = await loadProperty(k: downloadDirKey);
  if (v.trim().isNotEmpty) {
    downloadDirSignal.value = v.trim();
  }
  downloadDirSessionConfirmedSignal.value = false;
}

Future<void> setDownloadDir(String dir) async {
  final v = dir.trim();
  await saveProperty(k: downloadDirKey, v: v);
  downloadDirSignal.value = v;
}

Future<void> resetDownloadDir() => setDownloadDir('');

void confirmDownloadDirForSession() {
  downloadDirSessionConfirmedSignal.value = true;
}

Future<String> effectiveDownloadDir() async {
  final configured = downloadDirSignal.value.trim();
  if (configured.isNotEmpty) return configured;

  Directory base;
  if (Platform.isAndroid) {
    base =
        (await getExternalStorageDirectory()) ??
        (await getApplicationDocumentsDirectory());
  } else if (Platform.isIOS) {
    base = await getApplicationDocumentsDirectory();
  } else {
    base =
        (await getDownloadsDirectory()) ??
        (await getApplicationDocumentsDirectory());
  }

  return '${base.path}${Platform.pathSeparator}pansy_downloads';
}
