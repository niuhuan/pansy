import 'dart:developer';
import 'package:date_format/date_format.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pansy/basic/commons.dart';
import 'package:pansy/basic/cross.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pansy/ffi.dart';
import '../basic/config/download_to.dart';
import 'components/pixiv_image.dart';
import 'components/shadow_icon_button.dart';
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
      appBar: _buildAuthorAppBar(),
      body: ListView(
        children: [
          ..._buildPictures(),
          _buildInfos(),
          _buildTags(),
          _buildAuthor(),
        ],
      ),
    );
  }

  AppBar _buildAuthorAppBar() {
    return AppBar(
      centerTitle: false,
      elevation: 0.1,
      title: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
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
                    url: widget.illust.user.profileImageUrls.medium,
                  ),
                ),
              ),
            ),
            WidgetSpan(child: Container(width: 10)),
            TextSpan(text: widget.illust.user.name),
          ],
        ),
      ),
      actions: [
        _moreButton(),
      ],
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

  Widget _buildTags() {
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

  Widget _buildAuthor() {
    return Container(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.only(left: 10, right: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.illust.title),
                Text(widget.illust.createDate),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: widget.illust.user.name),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    margin: EdgeInsets.all(10),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 3,
                          style: BorderStyle.solid,
                        )),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                      child: ScalePixivImage(
                        url: widget.illust.user.profileImageUrls.medium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moreButton() {
    return PopupMenuButton<int>(
      icon: const DecoratedIcon(
        Icons.more_vert,
        size: 24,
        shadows: [
          BoxShadow(
            color: Colors.black,
            offset: Offset(1.0, 1.0),
            blurRadius: 5.0,
          ),
        ],
        color: Colors.white,
      ),
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            child: Text(
              AppLocalizations.of(context)!.downloadAllOriginalImagesToFiles,
            ),
            value: 1,
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
            await api.appendToDownload(values: metas);
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
