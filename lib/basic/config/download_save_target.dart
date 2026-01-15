import 'dart:io';

import 'package:pansy/src/rust/api/api.dart';
import 'package:signals_flutter/signals_flutter.dart';

const downloadSaveTargetKey = 'download_save_target';

enum DownloadSaveTarget { file, album, fileAndAlbum }

final downloadSaveTargetSignal = signal<DownloadSaveTarget>(
  Platform.isAndroid || Platform.isIOS
      ? DownloadSaveTarget.fileAndAlbum
      : DownloadSaveTarget.file,
);

bool get platformSupportsAlbum => Platform.isAndroid || Platform.isIOS;

Future<void> initDownloadSaveTarget() async {
  final raw = (await loadProperty(k: downloadSaveTargetKey)).trim();
  final target = switch (raw) {
    'file' => DownloadSaveTarget.file,
    'album' => DownloadSaveTarget.album,
    'fileAndAlbum' => DownloadSaveTarget.fileAndAlbum,
    _ => null,
  };

  if (target == null) return;
  if (!platformSupportsAlbum && target != DownloadSaveTarget.file) return;
  downloadSaveTargetSignal.value = target;
}

Future<void> setDownloadSaveTarget(DownloadSaveTarget target) async {
  final v = switch (target) {
    DownloadSaveTarget.file => 'file',
    DownloadSaveTarget.album => 'album',
    DownloadSaveTarget.fileAndAlbum => 'fileAndAlbum',
  };
  await saveProperty(k: downloadSaveTargetKey, v: v);
  downloadSaveTargetSignal.value = target;
}
