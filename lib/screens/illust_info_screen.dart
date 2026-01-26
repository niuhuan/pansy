import 'dart:io';
import 'dart:developer';

import 'package:date_format/date_format.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pansy/basic/commons.dart';
import 'package:pansy/basic/config/download_dir.dart';
import 'package:pansy/basic/config/download_save_target.dart';
import 'package:pansy/basic/config/use_download_queue.dart';
import 'package:pansy/basic/cross.dart';
import 'package:pansy/basic/download/download_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../src/rust/pixirust/entities.dart';
import 'components/appbar.dart';
import 'components/pixiv_image.dart';
import 'search_common.dart';
import 'search_result_screen.dart';
import 'user_info_screen.dart';

class IllustInfoScreen extends StatefulWidget {
  final Illust illust;

  const IllustInfoScreen(this.illust, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _IllustInfoScreenState();
}

class _IllustInfoScreenState extends State<IllustInfoScreen> {
  static const _sectionMargin = EdgeInsets.only(top: .5, bottom: .5);
  static const _sectionShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
  );

  final GlobalKey _moreMenuKey = GlobalKey();
  late bool _isBookmarked;
  bool _isBookmarkLoading = false;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.illust.isBookmarked;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final foregroundColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            snap: false,
            expandedHeight: kToolbarHeight + MediaQuery.of(context).padding.top,
            collapsedHeight: kToolbarHeight,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: foregroundColor,
            elevation: 0,
            leading: _buildFloatingBackButton(context, foregroundColor),
            actions: [
              _buildFloatingIconButton(_bookmarkButton()),
              _buildFloatingIconButton(_moreButton()),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final expandRatio = _calculateExpandRatio(constraints);
                final animation = AlwaysStoppedAnimation(expandRatio);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildAppBarBackground(context, animation),
                    _buildAppBarTitle(context, animation),
                  ],
                );
              },
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              ..._buildPictures(),
              _buildTitleAuthor(),
              _buildInfos(),
              if (_plainCaption(widget.illust.caption).isNotEmpty)
                _buildCaption(),
              _buildTags(),
              if (widget.illust.tools.isNotEmpty) _buildTools(l10n),
              SafeArea(top: false, child: Container()),
            ]),
          ),
        ],
      ),
    );
  }

  double _calculateExpandRatio(BoxConstraints constraints) {
    final expandedHeight =
        kToolbarHeight + MediaQuery.of(context).padding.top;
    final collapsedHeight =
        kToolbarHeight + MediaQuery.of(context).padding.top;
    final maxScrollExtent = expandedHeight - collapsedHeight;
    final currentExtent = constraints.maxHeight - collapsedHeight;
    return (currentExtent / (maxScrollExtent == 0 ? 1 : maxScrollExtent))
        .clamp(0.0, 1.0);
  }

  Widget _buildFloatingBackButton(BuildContext context, Color foregroundColor) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(Icons.arrow_back, color: foregroundColor),
        onPressed: () => Navigator.of(context).pop(),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildFloatingIconButton(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }

  Widget _buildAppBarBackground(
      BuildContext context, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarTitle(BuildContext context, Animation<double> animation) {
    final theme = Theme.of(context);
    final foregroundColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding,
      left: 56,
      right: 100,
      height: kToolbarHeight,
      child: FadeTransition(
        opacity: animation,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => UserInfoScreen(widget.illust.user),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                    style: BorderStyle.solid,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                  child: ScalePixivImage(
                      url: widget.illust.user.profileImageUrls.medium),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.illust.user.name,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
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
          onLongPressStart: (details) {
            _showPageActions(
              pageIndex: i,
              url: metas[i].original,
              sharePositionOrigin: _rectFromGlobal(details.globalPosition),
            );
          },
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
      margin: _sectionMargin,
      shape: _sectionShape,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 14,
          runSpacing: 10,
          children: [
            _infoPill(
              icon: Icons.calendar_today_outlined,
              text: formatDate(
                DateTime.parse(widget.illust.createDate),
                [yyyy, '-', mm, '-', dd],
              ),
              color: textColor,
            ),
            _infoPill(
              icon: Icons.image_outlined,
              text: '${widget.illust.pageCount}P',
              color: textColor,
            ),
            _infoPill(
              icon: Icons.photo_size_select_large_outlined,
              text: '${widget.illust.width}×${widget.illust.height}',
              color: textColor,
            ),
            _infoPill(
              icon: Icons.remove_red_eye_outlined,
              text: widget.illust.totalView.toString(),
              color: textColor,
            ),
            _infoPill(
              icon: Icons.favorite_border,
              text: widget.illust.totalBookmarks.toString(),
              color: textColorTitle.withOpacity(.85),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAuthor() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = (theme.textTheme.bodySmall?.color ?? Colors.black)
        .withOpacity(.7);

    return Card(
      elevation: 0,
      margin: _sectionMargin,
      shape: _sectionShape,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.illust.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(50)),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: ScalePixivImage(
                    url: widget.illust.user.profileImageUrls.medium,
                  ),
                ),
              ),
              title: Text(widget.illust.user.name),
              subtitle:
                  widget.illust.series == null
                      ? Text('${l10n.illustId}: ${widget.illust.id}',
                          style: TextStyle(color: muted))
                      : Text(
                        '${l10n.illustId}: ${widget.illust.id} · ${widget.illust.series!.title}',
                        style: TextStyle(color: muted),
                      ),
              trailing: IconButton(
                tooltip: l10n.webpage,
                icon: const Icon(Icons.open_in_new),
                onPressed: _openInWeb,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserInfoScreen(widget.illust.user),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTags() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium;

    return Card(
      elevation: 0,
      margin: _sectionMargin,
      shape: _sectionShape,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.tags, style: titleStyle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  widget.illust.tags.map((e) {
                    final label =
                        e.translatedName == null
                            ? '#${e.name}'
                            : '#${e.name}  ${e.translatedName}';
                    return ActionChip(
                      label: Text(label),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) {
                              return SearchResultScreen(
                                query: e.name,
                                mode: ILLUST_SEARCH_MODE_EXACT_MATCH_FOR_TAGS,
                                onOpenIllust: (context, illust) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => IllustInfoScreen(illust),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTools(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: _sectionMargin,
      shape: _sectionShape,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.tools, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  widget.illust.tools
                      .map((t) => Chip(label: Text(t)))
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaption() {
    final l10n = AppLocalizations.of(context)!;
    final caption = _plainCaption(widget.illust.caption);
    return Card(
      elevation: 0,
      margin: _sectionMargin,
      shape: _sectionShape,
      child: ExpansionTile(
        title: Text(l10n.caption),
        initiallyExpanded: caption.length <= 120,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SelectableText(caption),
          ),
        ],
      ),
    );
  }

  Widget _infoPill({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color.withOpacity(.9)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }

  String _plainCaption(String raw) {
    var s = raw;
    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    s = s.replaceAll('&amp;', '&');
    s = s.replaceAll('&lt;', '<');
    s = s.replaceAll('&gt;', '>');
    s = s.replaceAll('&quot;', '"');
    s = s.replaceAll('&#39;', "'");
    return s.trim();
  }

  Future<void> _openInWeb() async {
    final uri = Uri.parse('https://www.pixiv.net/artworks/${widget.illust.id}');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        defaultToast(context, AppLocalizations.of(context)!.failed);
      }
    } catch (e) {
      if (mounted) {
        defaultToast(context, AppLocalizations.of(context)!.failed + "\n$e");
      }
    }
  }

  Widget _bookmarkButton() {
    return IconButton(
      icon: _isBookmarkLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _isBookmarked ? Icons.favorite : Icons.favorite_border,
              color: _isBookmarked ? Colors.red : null,
            ),
      onPressed: _isBookmarkLoading ? null : _toggleBookmark,
    );
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarkLoading) return;

    setState(() {
      _isBookmarkLoading = true;
    });

    try {
      if (_isBookmarked) {
        await deleteBookmark(illustId: widget.illust.id);
        setState(() {
          _isBookmarked = false;
          _isBookmarkLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.unbookmark),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        await addBookmark(illustId: widget.illust.id, restrict: "public");
        setState(() {
          _isBookmarked = true;
          _isBookmarkLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.bookmarked),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isBookmarkLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _moreButton() {
    return PopupMenuButton<int>(
      key: _moreMenuKey,
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
          PopupMenuItem(
            value: 5,
            child: Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    baseline: TextBaseline.alphabetic,
                    child: Opacity(
                      opacity: .8,
                      child: Icon(
                        widget.illust.metaPages.length > 1
                            ? Icons.collections_outlined
                            : Icons.download_outlined,
                      ),
                    ),
                  ),
                  const TextSpan(text: "  "),
                  TextSpan(
                    text:
                        widget.illust.metaPages.length > 1
                            ? AppLocalizations.of(context)!.downloadAllPages
                            : AppLocalizations.of(context)!.downloadImage,
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
            await SharePlus.instance.share(
              ShareParams(text: link, sharePositionOrigin: _shareOriginRect()),
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

            final useQueue = useDownloadQueueSignal.value;
            if (useQueue) {
              // 使用下载队列
              await DownloadService.downloadIllustQueued(
                widget.illust,
                allPages: widget.illust.metaPages.length > 1,
                target: target,
              );
              if (!mounted) return;
              defaultToast(
                context,
                AppLocalizations.of(context)!.addedToDownloadQueue,
              );
              return;
            }

            // 立即下载
            final result = await DownloadService.downloadIllust(
              widget.illust,
              allPages: widget.illust.metaPages.length > 1,
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

  Rect _shareOriginRect() {
    final menuContext = _moreMenuKey.currentContext;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final buttonBox = menuContext?.findRenderObject() as RenderBox?;
    if (overlayBox != null && buttonBox != null) {
      final topLeft = buttonBox.localToGlobal(
        Offset.zero,
        ancestor: overlayBox,
      );
      return topLeft & buttonBox.size;
    }

    final size = MediaQuery.of(context).size;
    return Rect.fromLTWH(size.width / 2, size.height / 2, 1, 1);
  }

  Rect _rectFromGlobal(Offset globalPosition) =>
      Rect.fromCenter(center: globalPosition, width: 1, height: 1);

  Future<void> _showPageActions({
    required int pageIndex,
    required String url,
    required Rect sharePositionOrigin,
  }) async {
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
                leading: const Icon(Icons.download_outlined),
                title: Text(l10n.downloadImage),
                onTap: () => Navigator.of(context).pop(1),
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(l10n.shareImage),
                onTap: () => Navigator.of(context).pop(2),
              ),
            ],
          ),
        );
      },
    );

    if (action == null) return;
    if (action == 1) {
      await _downloadSingleImage(pageIndex: pageIndex, url: url);
      return;
    }
    if (action == 2) {
      await _shareSingleImage(url: url, sharePositionOrigin: sharePositionOrigin);
      return;
    }
  }

  Future<void> _shareSingleImage({
    required String url,
    required Rect sharePositionOrigin,
  }) async {
    final link = "https://www.pixiv.net/artworks/${widget.illust.id}";
    try {
      final cached = await loadPixivImage(url: url);
      await SharePlus.instance.share(
        ShareParams(
          text: link,
          files: [XFile(cached)],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e, s) {
      log("$e\n$s");
      if (!mounted) return;
      defaultToast(context, AppLocalizations.of(context)!.failed + "\n$e");
    }
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

  Future<void> _downloadSingleImage({
    required int pageIndex,
    required String url,
  }) async {
    try {
      final target = await _chooseSaveTarget();
      if (target == null) return;
      if (!await _ensureFileDownloadDirSelectedIfNeeded(target)) return;

      final useQueue = useDownloadQueueSignal.value;
      if (useQueue) {
        // 使用下载队列
        await DownloadService.downloadSingleImageQueued(
          widget.illust,
          pageIndex: pageIndex,
          url: url,
          target: target,
        );
        if (!mounted) return;
        defaultToast(
          context,
          AppLocalizations.of(context)!.addedToDownloadQueue,
        );
        return;
      }

      // 立即下载
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
