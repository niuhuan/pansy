import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pansy/basic/commons.dart';
import 'package:pansy/basic/config/download_dir.dart';
import 'package:pansy/basic/config/download_save_target.dart';
import 'package:pansy/basic/config/use_download_queue.dart';
import 'package:pansy/basic/config/illust_display.dart';
import 'package:pansy/basic/cross.dart';
import 'package:pansy/basic/download/download_service.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:waterfall_flow/waterfall_flow.dart';
import '../../src/rust/pixirust/entities.dart';
import '../illust_info_screen.dart';
import 'illust_card.dart';

class IllustFlow extends StatefulWidget {
  final FutureOr<List<Illust>> Function() nextPage;

  const IllustFlow({required this.nextPage, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _IllustFlowState();
}

class _IllustFlowState extends State<IllustFlow> {
  late ScrollController _controller;
  late Future _joinFuture;
  late var _joining = false;
  final List<Illust> _data = [];

  Future _join() async {
    try {
      setState(() {
        _joining = true;
      });
      _data.addAll(await widget.nextPage());
    } finally {
      setState(() {
        _joining = false;
      });
    }
  }

  @override
  void initState() {
    _controller = ScrollController();
    _controller.addListener(_onScroll);
    _joinFuture = _join();
    super.initState();
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_joining) {
      return;
    }
    if (_controller.position.pixels < _controller.position.maxScrollExtent) {
      return;
    }
    setState(() {
      _joinFuture = _join();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Watch((context) {
        final onlyImages = illustOnlyShowImagesSignal.value;
        return _buildFlow(onlyImages: onlyImages);
      }),
    );
  }

  Widget _buildFlow({required bool onlyImages}) {
    return WaterfallFlow.builder(
      controller: _controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      itemCount: _data.length + 1,
      gridDelegate: const SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
      itemBuilder: (BuildContext context, int index) {
        if (index >= _data.length) {
          return _buildLoadingCard();
        }
        return _buildImageCard(_data[index], onlyImages: onlyImages);
      },
    );
  }

  Widget _buildLoadingCard() {
    return FutureBuilder(
      future: _joinFuture,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Card(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: const CupertinoActivityIndicator(radius: 14),
                ),
                const Text('加载中'),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          print("${snapshot.error}\n${snapshot.stackTrace}");
          return Card(
            child: InkWell(
              onTap: () {
                setState(() {
                  _joinFuture = _join();
                });
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: const Icon(Icons.sync_problem_rounded),
                  ),
                  const Text('出错, 点击重试'),
                ],
              ),
            ),
          );
        }
        return Container();
      },
    );
  }

  Widget _buildImageCard(Illust item, {required bool onlyImages}) {
    return IllustCard(
      illust: item,
      onlyShowImages: onlyImages,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return IllustInfoScreen(item);
            },
          ),
        );
      },
      onLongPress: () => _showIllustActions(item),
    );
  }

  Future<void> _showIllustActions(Illust illust) async {
    final link = "https://www.pixiv.net/artworks/${illust.id}";
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.link),
                title: Text(l10n.shareLink),
                onTap: () => Navigator.of(context).pop(1),
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(l10n.shareImage),
                onTap: () => Navigator.of(context).pop(2),
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(l10n.copyLink),
                onTap: () => Navigator.of(context).pop(3),
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: Text(l10n.downloadImage),
                onTap: () => Navigator.of(context).pop(4),
              ),
              if (illust.metaPages.length > 1)
                ListTile(
                  leading: const Icon(Icons.collections_outlined),
                  title: Text(l10n.downloadAllPages),
                  onTap: () => Navigator.of(context).pop(5),
                ),
            ],
          ),
        );
      },
    );
    if (action == null) return;
    if (action == 1) {
      try {
        await SharePlus.instance.share(
          ShareParams(text: link, sharePositionOrigin: _shareOriginRect()),
        );
      } catch (e, s) {
        log("$e\n$s");
        if (!mounted) return;
        defaultToast(context, l10n.failed + "\n$e");
      }
      return;
    }
    if (action == 3) {
      copyToClipBoard(context, link);
      return;
    }
    if (action == 2) {
      try {
        final imageUrl =
            illust.metaPages.isNotEmpty
                ? illust.metaPages.first.imageUrls.original
                : illust.metaSinglePage.originalImageUrl!;
        final cached = await loadPixivImage(url: imageUrl);
        await SharePlus.instance.share(
          ShareParams(
            text: link,
            files: [XFile(cached)],
            sharePositionOrigin: _shareOriginRect(),
          ),
        );
      } catch (e, s) {
        log("$e\n$s");
        if (!mounted) return;
        defaultToast(context, l10n.failed + "\n$e");
      }
      return;
    }
    if (action == 4 || action == 5) {
      try {
        final target = await _chooseSaveTarget();
        if (target == null) return;
        if (!await _ensureFileDownloadDirSelectedIfNeeded(target)) return;

        final useQueue = useDownloadQueueSignal.value;
        if (useQueue) {
          // 使用下载队列
          await DownloadService.downloadIllustQueued(
            illust,
            allPages: action == 5,
            target: target,
          );
          if (!mounted) return;
          defaultToast(context, l10n.addedToDownloadQueue);
          return;
        }

        // 立即下载
        final result = await DownloadService.downloadIllust(
          illust,
          allPages: action == 5,
          target: target,
        );
        if (!mounted) return;
        final dir =
            result.files.isEmpty
                ? null
                : (Platform.isAndroid
                    ? null
                    : File(result.files.first).parent.path);
        if (result.files.isEmpty && result.savedToAlbumCount == 0) {
          defaultToast(context, l10n.failed);
          return;
        }

        if (target == DownloadSaveTarget.album) {
          defaultToast(context, l10n.downloadSavedToAlbum);
          return;
        }
        if (target == DownloadSaveTarget.fileAndAlbum) {
          final androidDir = l10n.downloadDirAndroidDesc(
            l10n.downloadsFolder,
            downloadDirSignal.value.trim().isEmpty
                ? 'Pansy'
                : downloadDirSignal.value.trim(),
          );
          defaultToast(
            context,
            Platform.isAndroid
                ? l10n.downloadSavedToFileAndAlbum(androidDir)
                : l10n.downloadSavedToFileAndAlbum(dir ?? ''),
          );
          return;
        }
        defaultToast(
          context,
          Platform.isAndroid
              ? l10n.downloadSavedTo(
                l10n.downloadDirAndroidDesc(
                  l10n.downloadsFolder,
                  downloadDirSignal.value.trim().isEmpty
                      ? 'Pansy'
                      : downloadDirSignal.value.trim(),
                ),
              )
              : l10n.downloadSavedTo(dir ?? ''),
        );
      } catch (e, s) {
        log("$e\n$s");
        if (!mounted) return;
        if (e.toString() == 'download_dir_not_set') {
          defaultToast(context, l10n.downloadDirRequired);
          return;
        }
        defaultToast(context, l10n.failed + "\n$e");
      }
      return;
    }
  }

  Rect _shareOriginRect() {
    final box = context.findRenderObject() as RenderBox?;
    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box != null && overlayBox != null) {
      final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
      return topLeft & box.size;
    }

    final size = MediaQuery.of(context).size;
    return Rect.fromLTWH(size.width / 2, size.height / 2, 1, 1);
  }

  Future<DownloadSaveTarget?> _chooseSaveTarget() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return DownloadSaveTarget.file;
    }

    final l10n = AppLocalizations.of(context)!;
    final selected = downloadSaveTargetSignal.value;
    final action = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(l10n.saveToFile),
                selected: selected == DownloadSaveTarget.file,
                trailing:
                    selected == DownloadSaveTarget.file
                        ? const Icon(Icons.check)
                        : null,
                onTap: () => Navigator.of(context).pop(1),
              ),
              ListTile(
                leading: const Icon(Icons.photo_outlined),
                title: Text(l10n.saveToAlbum),
                selected: selected == DownloadSaveTarget.album,
                trailing:
                    selected == DownloadSaveTarget.album
                        ? const Icon(Icons.check)
                        : null,
                onTap: () => Navigator.of(context).pop(2),
              ),
              ListTile(
                leading: const Icon(Icons.save_outlined),
                title: Text(l10n.saveToFileAndAlbum),
                selected: selected == DownloadSaveTarget.fileAndAlbum,
                trailing:
                    selected == DownloadSaveTarget.fileAndAlbum
                        ? const Icon(Icons.check)
                        : null,
                onTap: () => Navigator.of(context).pop(3),
              ),
            ],
          ),
        );
      },
    );

    final target = switch (action) {
      1 => DownloadSaveTarget.file,
      2 => DownloadSaveTarget.album,
      3 => DownloadSaveTarget.fileAndAlbum,
      _ => null,
    };

    if (target != null) {
      await setDownloadSaveTarget(target);
    }
    return target;
  }

  Future<bool> _ensureFileDownloadDirSelectedIfNeeded(
    DownloadSaveTarget target,
  ) async {
    if (Platform.isAndroid) return true;
    if (Platform.isIOS) return true;
    if (target == DownloadSaveTarget.album) return true;

    if (downloadDirSignal.value.trim().isNotEmpty) return true;
    
    // 不再弹出选择对话框，直接提示用户去设置
    final l10n = AppLocalizations.of(context)!;
    defaultToast(context, l10n.downloadDirRequired);
    return false;
  }
}
