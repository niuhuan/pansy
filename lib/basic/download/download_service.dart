import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pansy/basic/config/download_dir.dart';
import 'package:pansy/basic/config/download_save_target.dart';
import 'package:pansy/basic/download/download_manager.dart';
import 'package:pansy/basic/platform.dart';
import 'package:pansy/cross.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:pansy/src/rust/pixirust/entities.dart';

class DownloadResult {
  final List<String> files;
  final int savedToAlbumCount;

  const DownloadResult({required this.files, required this.savedToAlbumCount});
}

class DownloadService {
  /// 下载插画（立即下载）
  static Future<DownloadResult> downloadIllust(
    Illust illust, {
    required bool allPages,
    required DownloadSaveTarget target,
  }) async {
    await _ensurePermissionsIfNeeded(target);

    final dir =
        Platform.isAndroid
            ? null
            : (Platform.isIOS
                ? await effectiveDownloadDir()
                : (downloadDirSignal.value.trim().isEmpty
                    ? null
                    : downloadDirSignal.value.trim()));
    if (!Platform.isAndroid &&
        (target == DownloadSaveTarget.file ||
            target == DownloadSaveTarget.fileAndAlbum)) {
      if (!Platform.isIOS && dir == null) {
        throw 'download_dir_not_set';
      }
      await Directory(dir!).create(recursive: true);
    }

    final urls = <String>[];
    if (illust.metaPages.isNotEmpty) {
      for (final page in illust.metaPages) {
        urls.add(page.imageUrls.original);
        if (!allPages) break;
      }
    } else {
      final u = illust.metaSinglePage.originalImageUrl;
      if (u != null && u.trim().isNotEmpty) urls.add(u);
    }

    final saved = <String>[];
    var savedToAlbumCount = 0;
    for (var i = 0; i < urls.length; i++) {
      final url = urls[i];
      final cachedPath = await loadPixivImage(url: url);

      if (target == DownloadSaveTarget.album ||
          target == DownloadSaveTarget.fileAndAlbum) {
        final ok = await cross.saveImageToGallery(cachedPath);
        if (ok) savedToAlbumCount++;
      }

      if (target == DownloadSaveTarget.file ||
          target == DownloadSaveTarget.fileAndAlbum) {
        final ext =
            _extensionFromUrl(url) ?? _extensionFromPath(cachedPath) ?? 'jpg';
        final title = _sanitizeFileName(illust.title);
        final baseName =
            title.isEmpty
                ? '${illust.id}_p$i.$ext'
                : '${illust.id}_p${i}_$title.$ext';
        if (Platform.isAndroid) {
          final subDir =
              downloadDirSignal.value.trim().isEmpty
                  ? 'Pansy'
                  : downloadDirSignal.value.trim();
          final ref = await cross.saveFileToDownloads(
            path: cachedPath,
            fileName: baseName,
            subDir: subDir,
          );
          if (ref != null) saved.add(ref);
        } else {
          final targetPath = await _uniquePath(dir!, baseName);
          await File(cachedPath).copy(targetPath);
          saved.add(targetPath);
        }
      }
    }
    return DownloadResult(files: saved, savedToAlbumCount: savedToAlbumCount);
  }

  /// 下载插画（添加到队列）
  static Future<void> downloadIllustQueued(
    Illust illust, {
    required bool allPages,
    required DownloadSaveTarget target,
  }) async {
    final urls = <String>[];
    if (illust.metaPages.isNotEmpty) {
      for (final page in illust.metaPages) {
        urls.add(page.imageUrls.original);
        if (!allPages) break;
      }
    } else {
      final u = illust.metaSinglePage.originalImageUrl;
      if (u != null && u.trim().isNotEmpty) urls.add(u);
    }

    await downloadManager.addTasks(
      illustId: illust.id,
      illustTitle: illust.title,
      urls: urls,
      saveTarget: target,
    );
  }

  /// 下载单张图片（立即下载）
  static Future<DownloadResult> downloadSingleImage(
    Illust illust, {
    required int pageIndex,
    required String url,
    required DownloadSaveTarget target,
  }) async {
    await _ensurePermissionsIfNeeded(target);

    final dir =
        Platform.isAndroid
            ? null
            : (Platform.isIOS
                ? await effectiveDownloadDir()
                : (downloadDirSignal.value.trim().isEmpty
                    ? null
                    : downloadDirSignal.value.trim()));
    if (!Platform.isAndroid &&
        (target == DownloadSaveTarget.file ||
            target == DownloadSaveTarget.fileAndAlbum)) {
      if (!Platform.isIOS && dir == null) {
        throw 'download_dir_not_set';
      }
      await Directory(dir!).create(recursive: true);
    }

    final cachedPath = await loadPixivImage(url: url);
    final saved = <String>[];
    var savedToAlbumCount = 0;

    if (target == DownloadSaveTarget.album ||
        target == DownloadSaveTarget.fileAndAlbum) {
      final ok = await cross.saveImageToGallery(cachedPath);
      if (ok) savedToAlbumCount++;
    }

    if (target == DownloadSaveTarget.file ||
        target == DownloadSaveTarget.fileAndAlbum) {
      final ext =
          _extensionFromUrl(url) ?? _extensionFromPath(cachedPath) ?? 'jpg';
      final title = _sanitizeFileName(illust.title);
      final baseName =
          title.isEmpty
              ? '${illust.id}_p$pageIndex.$ext'
              : '${illust.id}_p${pageIndex}_$title.$ext';

      if (Platform.isAndroid) {
        final subDir =
            downloadDirSignal.value.trim().isEmpty
                ? 'Pansy'
                : downloadDirSignal.value.trim();
        final ref = await cross.saveFileToDownloads(
          path: cachedPath,
          fileName: baseName,
          subDir: subDir,
        );
        if (ref != null) saved.add(ref);
      } else {
        final targetPath = await _uniquePath(dir!, baseName);
        await File(cachedPath).copy(targetPath);
        saved.add(targetPath);
      }
    }

    return DownloadResult(files: saved, savedToAlbumCount: savedToAlbumCount);
  }

  /// 下载单张图片（添加到队列）
  static Future<void> downloadSingleImageQueued(
    Illust illust, {
    required int pageIndex,
    required String url,
    required DownloadSaveTarget target,
  }) async {
    await downloadManager.addTask(
      illustId: illust.id,
      illustTitle: illust.title,
      pageIndex: pageIndex,
      pageCount: illust.metaPages.length > 0 ? illust.metaPages.length : 1,
      url: url,
      saveTarget: target,
    );
  }

  static Future<void> _ensurePermissionsIfNeeded(
    DownloadSaveTarget target,
  ) async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      if (androidVersion <= 28) {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }
      return;
    }

    if (Platform.isIOS &&
        (target == DownloadSaveTarget.album ||
            target == DownloadSaveTarget.fileAndAlbum)) {
      final status = await Permission.photosAddOnly.status;
      if (!status.isGranted) {
        await Permission.photosAddOnly.request();
      }
      return;
    }
  }

  static String? _extensionFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final path = uri?.path ?? url;
    final idx = path.lastIndexOf('.');
    if (idx < 0 || idx == path.length - 1) return null;
    final ext = path.substring(idx + 1).toLowerCase();
    if (ext.length > 5) return null;
    if (!RegExp(r'^[a-z0-9]+$').hasMatch(ext)) return null;
    return ext;
  }

  static String? _extensionFromPath(String path) {
    final idx = path.lastIndexOf('.');
    if (idx < 0 || idx == path.length - 1) return null;
    final ext = path.substring(idx + 1).toLowerCase();
    if (ext.length > 5) return null;
    if (!RegExp(r'^[a-z0-9]+$').hasMatch(ext)) return null;
    return ext;
  }

  static String _sanitizeFileName(String input, {int maxLength = 80}) {
    final s =
        input
            .trim()
            .replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t]'), '_')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    if (s.isEmpty) return '';
    if (s.length <= maxLength) return s;
    return s.substring(0, maxLength).trim();
  }

  static Future<String> _uniquePath(String dir, String fileName) async {
    final sep = Platform.pathSeparator;
    final dot = fileName.lastIndexOf('.');
    final stem = dot > 0 ? fileName.substring(0, dot) : fileName;
    final ext = dot > 0 ? fileName.substring(dot) : '';

    var candidate = '$dir$sep$fileName';
    if (!await File(candidate).exists()) return candidate;

    for (var i = 1; i < 1000; i++) {
      candidate = '$dir$sep$stem ($i)$ext';
      if (!await File(candidate).exists()) return candidate;
    }
    throw 'Too many duplicated files';
  }
}
