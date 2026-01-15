import 'dart:io';
import 'dart:developer';

import 'package:date_format/date_format.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pansy/basic/commons.dart';
import 'package:pansy/basic/config/download_dir.dart';
import 'package:pansy/basic/config/download_save_target.dart';
import 'package:pansy/basic/cross.dart';
import 'package:pansy/basic/download/download_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:share_plus/share_plus.dart';
import '../src/rust/pixirust/entities.dart';
import 'components/appbar.dart';
import 'components/pixiv_image.dart';
import 'search_screen.dart';

class IllustInfoScreen extends StatefulWidget {
  final Illust illust;

  const IllustInfoScreen(this.illust, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _IllustInfoScreenState();
}

class _IllustInfoScreenState extends State<IllustInfoScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildUserSampleAppBar(context, widget.illust.user, [
        _moreButton(),
      ]),
      body: ListView(
        children: [
          ..._buildPictures(),
          _buildInfos(),
          _buildTitle(),
          _buildTags(),
          SafeArea(top: false, child: Container()),
        ],
      ),
    );
  }

  List<Widget> _buildPictures() {
    List<MetaPageImageUrls> metas = [];
    if (widget.illust.metaPages.isNotEmpty) {
      // 多张图片
      metas.addAll(widget.illust.metaPages.map((e) => e.imageUrls));
    } else {
      // 单张图片
      metas.add(
        MetaPageImageUrls(
          squareMedium: widget.illust.imageUrls.squareMedium,
          medium: widget.illust.imageUrls.medium,
          large: widget.illust.imageUrls.large,
          original: widget.illust.metaSinglePage.originalImageUrl!,
        ),
      );
    }
    List<Widget> pictures = [];
    for (var i = 0; i < metas.length; i++) {
      late Widget pic;
      if (i == 0) {
        pic = ScalePixivImage(
          url: widget.illust.imageUrls.large,
          originSize: Size(
            widget.illust.width.toDouble(),
            widget.illust.height.toDouble(),
          ),
        );
      } else {
        pic = ScalePixivImage(url: metas[i].large);
      }
      pictures.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress:
              () => _downloadSingleImage(pageIndex: i, url: metas[i].original),
          child: pic,
        ),
      );
    }
    return pictures;
  }

  Widget _buildInfos() {
    final theme = Theme.of(context);
    final textColor = (theme.textTheme.bodyMedium?.color ?? Colors.black)
        .withOpacity(.85);
    final textColorTitle = (theme.textTheme.titleMedium?.color ?? Colors.black);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: .5, bottom: .5),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        margin: const EdgeInsets.all(10),
        child: Row(
          children: [
            Text(
              formatDate(
                DateTime.parse(widget.illust.createDate),
                [
                  yyyy,
                  '-',
                  mm,
                  '-',
                  dd,
                ], // [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn, ':', ss],
              ),
              style: TextStyle(color: textColor),
            ),
            Container(width: 10),
            Text(
              "${widget.illust.totalView} ${AppLocalizations.of(context)!.totalViews}",
              style: TextStyle(color: textColor),
            ),
            Container(width: 10),
            Text(
              "${widget.illust.totalBookmarks} ",
              style: TextStyle(color: textColorTitle),
            ),
            Text(
              AppLocalizations.of(context)!.totalBookmarks,
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Text(widget.illust.title),
    );
  }

  Widget _buildTags() {
    final theme = Theme.of(context);
    final textColor = (theme.textTheme.bodyMedium?.color ?? Colors.black)
        .withOpacity(.85);
    final textColorTitle = theme.colorScheme.primary;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: .5, bottom: .5),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        margin: const EdgeInsets.all(10),
        child: Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          children:
              widget.illust.tags
                  .map(
                    (e) => Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "#${e.name}",
                            style: TextStyle(color: textColorTitle),
                            recognizer:
                                TapGestureRecognizer()
                                  ..onTap = () async {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (BuildContext context) {
                                          return SearchScreen(
                                            mode:
                                                ILLUST_SEARCH_MODE_EXACT_MATCH_FOR_TAGS,
                                            word: e.name,
                                          );
                                        },
                                      ),
                                    );
                                    ;
                                  },
                          ),
                          ...e.translatedName != null
                              ? [
                                const TextSpan(text: " "),
                                TextSpan(
                                  text: e.translatedName!,
                                  style: TextStyle(color: textColor),
                                ),
                              ]
                              : [],
                          const TextSpan(text: "    "),
                        ],
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _moreButton() {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert, size: 24),
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            value: 1,
            child: Text.rich(
              TextSpan(
                children: [
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    baseline: TextBaseline.alphabetic,
                    child: Opacity(opacity: .8, child: Icon(Icons.link)),
                  ),
                  const TextSpan(text: "  "),
                  TextSpan(text: AppLocalizations.of(context)!.shareLink),
                ],
              ),
            ),
          ),
          PopupMenuItem(
            value: 2,
            child: Text.rich(
              TextSpan(
                children: [
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    baseline: TextBaseline.alphabetic,
                    child: Opacity(
                      opacity: .8,
                      child: Icon(Icons.image_outlined),
                    ),
                  ),
                  const TextSpan(text: "  "),
                  TextSpan(text: AppLocalizations.of(context)!.shareImage),
                ],
              ),
            ),
          ),
          PopupMenuItem(
            value: 3,
            child: Text.rich(
              TextSpan(
                children: [
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    baseline: TextBaseline.alphabetic,
                    child: Opacity(opacity: .8, child: Icon(Icons.copy)),
                  ),
                  const TextSpan(text: "  "),
                  TextSpan(text: AppLocalizations.of(context)!.copyLink),
                ],
              ),
            ),
          ),
          if (widget.illust.metaPages.length > 1)
            PopupMenuItem(
              value: 5,
              child: Text.rich(
                TextSpan(
                  children: [
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      baseline: TextBaseline.alphabetic,
                      child: Opacity(
                        opacity: .8,
                        child: Icon(Icons.collections_outlined),
                      ),
                    ),
                    const TextSpan(text: "  "),
                    TextSpan(
                      text: AppLocalizations.of(context)!.downloadAllPages,
                    ),
                  ],
                ),
              ),
            ),
        ];
      },
      onSelected: (value) async {
        final link = "https://www.pixiv.net/artworks/${widget.illust.id}";
        if (value == 1) {
          try {
            await SharePlus.instance.share(ShareParams(text: link));
          } catch (e, s) {
            log("$e\n$s");
            if (!mounted) return;
            if (e.toString() == 'download_dir_not_set') {
              defaultToast(
                context,
                AppLocalizations.of(context)!.downloadDirRequired,
              );
              return;
            }
            defaultToast(
              context,
              AppLocalizations.of(context)!.failed + "\n$e",
            );
          }
          return;
        }
        if (value == 2) {
          try {
            final imageUrl =
                widget.illust.metaPages.isNotEmpty
                    ? widget.illust.metaPages.first.imageUrls.original
                    : widget.illust.metaSinglePage.originalImageUrl!;
            final cached = await loadPixivImage(url: imageUrl);
            await SharePlus.instance.share(
              ShareParams(text: link, files: [XFile(cached)]),
            );
          } catch (e, s) {
            log("$e\n$s");
            if (!mounted) return;
            defaultToast(
              context,
              AppLocalizations.of(context)!.failed + "\n$e",
            );
          }
          return;
        }
        if (value == 3) {
          copyToClipBoard(context, link);
          return;
        }
        if (value == 5) {
          try {
            final target = await _chooseSaveTarget();
            if (target == null) return;
            if (!await _ensureFileDownloadDirSelectedIfNeeded(target)) return;

            final result = await DownloadService.downloadIllust(
              widget.illust,
              allPages: value == 5,
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
              defaultToast(context, AppLocalizations.of(context)!.failed);
              return;
            }

            final l10n = AppLocalizations.of(context)!;
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
            defaultToast(
              context,
              AppLocalizations.of(context)!.failed + "\n$e",
            );
          }
          return;
        }
      },
    );
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
    final l10n = AppLocalizations.of(context)!;
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: l10n.chooseDownloadDir,
    );
    if (dir == null || dir.trim().isEmpty) {
      defaultToast(context, l10n.downloadDirRequired);
      return false;
    }
    await setDownloadDir(dir);
    return true;
  }

  Future<void> _downloadSingleImage({
    required int pageIndex,
    required String url,
  }) async {
    try {
      final target = await _chooseSaveTarget();
      if (target == null) return;
      if (!await _ensureFileDownloadDirSelectedIfNeeded(target)) return;

      final result = await DownloadService.downloadSingleImage(
        widget.illust,
        pageIndex: pageIndex,
        url: url,
        target: target,
      );
      if (!mounted) return;
      if (result.files.isEmpty && result.savedToAlbumCount == 0) {
        defaultToast(context, AppLocalizations.of(context)!.failed);
        return;
      }

      final l10n = AppLocalizations.of(context)!;
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
              : l10n.downloadSavedToFileAndAlbum(
                File(result.files.first).parent.path,
              ),
        );
        return;
      }
      if (Platform.isAndroid) {
        defaultToast(
          context,
          l10n.downloadSavedTo(
            l10n.downloadDirAndroidDesc(
              l10n.downloadsFolder,
              downloadDirSignal.value.trim().isEmpty
                  ? 'Pansy'
                  : downloadDirSignal.value.trim(),
            ),
          ),
        );
        return;
      }
      defaultToast(
        context,
        l10n.downloadSavedTo(File(result.files.first).parent.path),
      );
    } catch (e, s) {
      log("$e\n$s");
      if (!mounted) return;
      if (e.toString() == 'download_dir_not_set') {
        defaultToast(
          context,
          AppLocalizations.of(context)!.downloadDirRequired,
        );
        return;
      }
      defaultToast(context, AppLocalizations.of(context)!.failed + "\n$e");
    }
  }
}
