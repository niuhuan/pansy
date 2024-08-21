import 'dart:developer';
import 'package:date_format/date_format.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pansy/basic/commons.dart';
import 'package:pansy/basic/cross.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pansy/src/rust/api/api.dart';
import '../basic/config/download_to.dart';
import '../src/rust/pixirust/entities.dart';
import '../src/rust/udto.dart';
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
      appBar: buildUserSampleAppBar(
        context,
        widget.illust.user,
        [
          _moreButton(),
        ],
      ),
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
      metas.add(MetaPageImageUrls(
          squareMedium: widget.illust.imageUrls.squareMedium,
          medium: widget.illust.imageUrls.medium,
          large: widget.illust.imageUrls.large,
          original: widget.illust.metaSinglePage.originalImageUrl!));
    }
    List<Widget> pictures = [];
    for (var i = 0; i < metas.length; i++) {
      late Widget pic;
      if (i == 0) {
        pic = ScalePixivImage(
          url: widget.illust.imageUrls.large,
          originSize: Size(
              widget.illust.width.toDouble(), widget.illust.height.toDouble()),
        );
      } else {
        pic = ScalePixivImage(
          url: metas[i].large,
        );
      }
      pic = GestureDetector(
        onLongPress: () async {
          int? action = await chooseMapDialog(
            context,
            {
              AppLocalizations.of(context)!.downloadAndSaveOrigin: 1,
            },
            AppLocalizations.of(context)!.choose,
          );
          if (1 == action) {
            await savePixivImage(metas[i].original, context);
          }
        },
        child: pic,
      );
      pictures.add(pic);
    }
    return pictures;
  }

  Widget _buildInfos() {
    final theme = Theme.of(context);
    final textColor =
        (theme.textTheme.bodyMedium?.color ?? Colors.black).withOpacity(.85);
    final textColorTitle = (theme.textTheme.titleMedium?.color ?? Colors.black);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: .5, bottom: .5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
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
                  dd
                ], // [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn, ':', ss],
              ),
              style: TextStyle(
                color: textColor,
              ),
            ),
            Container(
              width: 10,
            ),
            Text(
              "${widget.illust.totalView} ${AppLocalizations.of(context)!.totalViews}",
              style: TextStyle(
                color: textColor,
              ),
            ),
            Container(
              width: 10,
            ),
            Text(
              "${widget.illust.totalBookmarks} ",
              style: TextStyle(
                color: textColorTitle,
              ),
            ),
            Text(
              AppLocalizations.of(context)!.totalBookmarks,
              style: TextStyle(
                color: textColor,
              ),
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
    final textColor =
        (theme.textTheme.bodyMedium?.color ?? Colors.black).withOpacity(.85);
    final textColorTitle = theme.colorScheme.primary;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: .5, bottom: .5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Container(
        margin: const EdgeInsets.all(10),
        child: Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: widget.illust.tags
                .map(
                  (e) => Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "#${e.name}",
                          style: TextStyle(
                            color: textColorTitle,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (BuildContext context) {
                                  return SearchScreen(
                                    mode:
                                        ILLUST_SEARCH_MODE_EXACT_MATCH_FOR_TAGS,
                                    word: e.name,
                                  );
                                }),
                              );
                              ;
                            },
                        ),
                        ...e.translatedName != null
                            ? [
                                const TextSpan(
                                  text: " ",
                                ),
                                TextSpan(
                                  text: e.translatedName!,
                                  style: TextStyle(
                                    color: textColor,
                                  ),
                                ),
                              ]
                            : [],
                        const TextSpan(
                          text: "    ",
                        ),
                      ],
                    ),
                  ),
                )
                .toList()),
      ),
    );
  }

  Widget _moreButton() {
    return PopupMenuButton<int>(
      icon: const Icon(
        Icons.more_vert,
        size: 24,
      ),
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            value: 1,
            child: Text.rich(TextSpan(children: [
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                baseline: TextBaseline.alphabetic,
                child: Opacity(
                  opacity: .8,
                  child: Icon(Icons.download),
                ),
              ),
              const TextSpan(text: "  "),
              TextSpan(
                text: AppLocalizations.of(context)!
                    .downloadAllOriginalImagesToFiles,
              )
            ])),
          ),
        ];
      },
      onSelected: (value) async {
        if (value == 1) {
          if (!await checkDownloadsTo(context)) {
            return;
          }
          List<UiAppendToDownload> metas = [];
          if (widget.illust.metaPages.isNotEmpty) {
            // 多张图片
            var i = 0;
            metas.addAll(widget.illust.metaPages.map((e) => UiAppendToDownload(
                  illustId: widget.illust.id,
                  illustTitle: widget.illust.title,
                  illustType: widget.illust.illustType,
                  imageIdx: i++,
                  squareMedium: e.imageUrls.squareMedium,
                  medium: e.imageUrls.medium,
                  large: e.imageUrls.large,
                  original: e.imageUrls.original,
                )));
          } else {
            // 单张图片
            metas.add(UiAppendToDownload(
              illustId: widget.illust.id,
              illustTitle: widget.illust.title,
              illustType: widget.illust.illustType,
              imageIdx: 0,
              squareMedium: widget.illust.imageUrls.squareMedium,
              medium: widget.illust.imageUrls.medium,
              large: widget.illust.imageUrls.large,
              original: widget.illust.metaSinglePage.originalImageUrl!,
            ));
          }
          try {
            await appendToDownload(values: metas);
            defaultToast(context, AppLocalizations.of(context)!.success);
          } catch (e, s) {
            log("$e\n$s");
            defaultToast(
              context,
              AppLocalizations.of(context)!.failed + "\n$e",
            );
          }
        }
      },
    );
  }
}
