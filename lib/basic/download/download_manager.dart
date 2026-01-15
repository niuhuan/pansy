import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pansy/basic/config/download_dir.dart';
import 'package:pansy/basic/config/download_save_target.dart';
import 'package:pansy/cross.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:pansy/src/rust/udto.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// 下载任务状态
enum DownloadTaskStatus {
  pending,
  downloading,
  completed,
  failed;

  static DownloadTaskStatus fromString(String status) {
    return switch (status) {
      'pending' => DownloadTaskStatus.pending,
      'downloading' => DownloadTaskStatus.downloading,
      'completed' => DownloadTaskStatus.completed,
      'failed' => DownloadTaskStatus.failed,
      _ => DownloadTaskStatus.pending,
    };
  }

  String toApiString() {
    return switch (this) {
      DownloadTaskStatus.pending => 'pending',
      DownloadTaskStatus.downloading => 'downloading',
      DownloadTaskStatus.completed => 'completed',
      DownloadTaskStatus.failed => 'failed',
    };
  }
}

/// 下载管理器
class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final tasksSignal = signal<List<DownloadTaskDto>>([]);
  final isProcessingSignal = signal<bool>(false);
  Timer? _processingTimer;
  bool _isProcessing = false;

  /// 初始化下载管理器
  Future<void> init() async {
    await refreshTasks();
    // 启动定时处理器
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      processQueue();
    });
  }

  /// 刷新任务列表
  Future<void> refreshTasks() async {
    try {
      final tasks = await getAllDownloadTasks();
      tasksSignal.value = tasks;
    } catch (e) {
      debugPrint('Failed to refresh download tasks: $e');
    }
  }

  /// 添加下载任务
  Future<void> addTask({
    required int illustId,
    required String illustTitle,
    required int pageIndex,
    required int pageCount,
    required String url,
    required DownloadSaveTarget saveTarget,
  }) async {
    try {
      // 生成目标路径（用于显示，实际保存时会处理）
      final targetPath = await _generateTargetPath(
        illustId: illustId,
        illustTitle: illustTitle,
        pageIndex: pageIndex,
        url: url,
      );

      await createDownloadTask(
        illustId: illustId,
        illustTitle: illustTitle,
        pageIndex: pageIndex,
        pageCount: pageCount,
        url: url,
        targetPath: targetPath,
        saveTarget: _saveTargetToString(saveTarget),
      );

      await refreshTasks();
      processQueue();
    } catch (e) {
      debugPrint('Failed to add download task: $e');
      rethrow;
    }
  }

  /// 批量添加任务
  Future<void> addTasks({
    required int illustId,
    required String illustTitle,
    required List<String> urls,
    required DownloadSaveTarget saveTarget,
  }) async {
    for (var i = 0; i < urls.length; i++) {
      await addTask(
        illustId: illustId,
        illustTitle: illustTitle,
        pageIndex: i,
        pageCount: urls.length,
        url: urls[i],
        saveTarget: saveTarget,
      );
    }
  }

  /// 处理下载队列
  Future<void> processQueue() async {
    if (_isProcessing) return;
    if (isProcessingSignal.value) return;

    try {
      _isProcessing = true;
      isProcessingSignal.value = true;

      final pendingTasks = await getPendingDownloadTasks();
      if (pendingTasks.isEmpty) {
        isProcessingSignal.value = false;
        _isProcessing = false;
        return;
      }

      // 并发处理最多3个任务
      final processingTasks = pendingTasks.take(3).toList();
      await Future.wait(
        processingTasks.map((task) => _processTask(task)),
      );

      await refreshTasks();
    } catch (e) {
      debugPrint('Error processing download queue: $e');
    } finally {
      _isProcessing = false;
      isProcessingSignal.value = false;
    }
  }

  /// 处理单个任务
  Future<void> _processTask(DownloadTaskDto task) async {
    try {
      // 首先下载到缓存
      await executeDownloadTask(id: task.id);
      
      // 获取缓存路径
      final cachedPath = await loadPixivImage(url: task.url);
      
      // 根据保存目标保存文件
      final saveTarget = _stringToSaveTarget(task.saveTarget);
      await _saveFile(
        task: task,
        cachedPath: cachedPath,
        saveTarget: saveTarget,
      );

      // 更新为完成状态
      await updateDownloadTaskStatus(
        id: task.id,
        status: 'completed',
        progress: 100,
        errorMessage: '',
      );
    } catch (e) {
      debugPrint('Failed to process task ${task.id}: $e');
      await updateDownloadTaskStatus(
        id: task.id,
        status: 'failed',
        progress: 0,
        errorMessage: e.toString(),
      );
    }
  }

  /// 保存文件
  Future<void> _saveFile({
    required DownloadTaskDto task,
    required String cachedPath,
    required DownloadSaveTarget saveTarget,
  }) async {
    if (saveTarget == DownloadSaveTarget.album ||
        saveTarget == DownloadSaveTarget.fileAndAlbum) {
      await cross.saveImageToGallery(cachedPath);
    }

    if (saveTarget == DownloadSaveTarget.file ||
        saveTarget == DownloadSaveTarget.fileAndAlbum) {
      if (Platform.isAndroid) {
        final subDir =
            downloadDirSignal.value.trim().isEmpty
                ? 'Pansy'
                : downloadDirSignal.value.trim();
        final baseName = _generateFileName(task);
        await cross.saveFileToDownloads(
          path: cachedPath,
          fileName: baseName,
          subDir: subDir,
        );
      } else {
        final dir =
            Platform.isIOS
                ? await effectiveDownloadDir()
                : (downloadDirSignal.value.trim().isEmpty
                    ? throw 'download_dir_not_set'
                    : downloadDirSignal.value.trim());
        await Directory(dir).create(recursive: true);
        final baseName = _generateFileName(task);
        final targetPath = await _uniquePath(dir, baseName);
        await File(cachedPath).copy(targetPath);
      }
    }
  }

  /// 重试任务
  Future<void> retryTask(int taskId) async {
    try {
      await retryDownloadTask(id: taskId);
      await refreshTasks();
      processQueue();
    } catch (e) {
      debugPrint('Failed to retry task: $e');
      rethrow;
    }
  }

  /// 删除任务
  Future<void> deleteTask(int taskId) async {
    try {
      await deleteDownloadTask(id: taskId);
      await refreshTasks();
    } catch (e) {
      debugPrint('Failed to delete task: $e');
      rethrow;
    }
  }

  /// 清除已完成的任务
  Future<void> clearCompleted() async {
    try {
      await deleteCompletedDownloadTasks();
      await refreshTasks();
    } catch (e) {
      debugPrint('Failed to clear completed tasks: $e');
      rethrow;
    }
  }

  /// 获取统计信息
  Map<String, int> getStatistics() {
    final tasks = tasksSignal.value;
    return {
      'total': tasks.length,
      'pending': tasks.where((t) => t.status == 'pending').length,
      'downloading': tasks.where((t) => t.status == 'downloading').length,
      'completed': tasks.where((t) => t.status == 'completed').length,
      'failed': tasks.where((t) => t.status == 'failed').length,
    };
  }

  /// 生成文件名
  String _generateFileName(DownloadTaskDto task) {
    final ext = _extensionFromUrl(task.url) ?? 'jpg';
    final title = _sanitizeFileName(task.illustTitle);
    return title.isEmpty
        ? '${task.illustId}_p${task.pageIndex}.$ext'
        : '${task.illustId}_p${task.pageIndex}_$title.$ext';
  }

  /// 生成目标路径
  Future<String> _generateTargetPath({
    required int illustId,
    required String illustTitle,
    required int pageIndex,
    required String url,
  }) async {
    final ext = _extensionFromUrl(url) ?? 'jpg';
    final title = _sanitizeFileName(illustTitle);
    final baseName =
        title.isEmpty
            ? '${illustId}_p$pageIndex.$ext'
            : '${illustId}_p${pageIndex}_$title.$ext';

    if (Platform.isAndroid) {
      return baseName;
    } else {
      final dir =
          Platform.isIOS
              ? await effectiveDownloadDir()
              : downloadDirSignal.value.trim();
      return '$dir/$baseName';
    }
  }

  String? _extensionFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final path = uri?.path ?? url;
    final idx = path.lastIndexOf('.');
    if (idx < 0 || idx == path.length - 1) return null;
    final ext = path.substring(idx + 1).toLowerCase();
    if (ext.length > 5) return null;
    if (!RegExp(r'^[a-z0-9]+$').hasMatch(ext)) return null;
    return ext;
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .trim()
        .substring(0, name.length > 100 ? 100 : name.length);
  }

  Future<String> _uniquePath(String dir, String baseName) async {
    final dotIdx = baseName.lastIndexOf('.');
    final nameWithoutExt =
        dotIdx > 0 ? baseName.substring(0, dotIdx) : baseName;
    final ext = dotIdx > 0 ? baseName.substring(dotIdx) : '';

    var candidate = '$dir/$baseName';
    var counter = 1;
    while (await File(candidate).exists()) {
      candidate = '$dir/${nameWithoutExt}_$counter$ext';
      counter++;
    }
    return candidate;
  }

  String _saveTargetToString(DownloadSaveTarget target) {
    return switch (target) {
      DownloadSaveTarget.file => 'file',
      DownloadSaveTarget.album => 'album',
      DownloadSaveTarget.fileAndAlbum => 'fileAndAlbum',
    };
  }

  DownloadSaveTarget _stringToSaveTarget(String str) {
    return switch (str) {
      'file' => DownloadSaveTarget.file,
      'album' => DownloadSaveTarget.album,
      'fileAndAlbum' => DownloadSaveTarget.fileAndAlbum,
      _ => DownloadSaveTarget.file,
    };
  }

  void dispose() {
    _processingTimer?.cancel();
  }
}

/// 全局下载管理器实例
final downloadManager = DownloadManager();
