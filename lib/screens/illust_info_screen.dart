import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:pansy/basic/commons.dart';
import 'package:pansy/basic/cross.dart';
import 'package:pansy/screens/illust_gallery_screen.dart';

import '../types.dart';
import 'components/empty_app_bar.dart';
import 'components/pixiv_image.dart';
import 'components/shadow_icon_button.dart';

class IllustInfoScreen extends StatefulWidget {
  final Illust illust;

  const IllustInfoScreen(this.illust, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _IllustInfoScreenState();
}

class _IllustInfoScreenState extends State<IllustInfoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EmptyAppBar(),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              List<MetaImageUrls> metas = [];
              if (widget.illust.metaPages.isNotEmpty) {
                // 多张图片
                metas.addAll(widget.illust.metaPages.map((e) => e.imageUrls));
              } else {
                // 单张图片
                metas.add(MetaImageUrls(
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
                    originSize: Size(widget.illust.width.toDouble(),
                        widget.illust.height.toDouble()),
                  );
                } else {
                  pic = ScalePixivImage(
                    url: metas[i].large,
                  );
                }
                pic = GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (BuildContext context) {
                        return IllustGalleryScreen(
                          metas.map((e) => MetaPage(e)).toList(),
                          i,
                        );
                      }),
                    );
                  },
                  onLongPress: () async {
                    String? action =
                        await chooseListDialog(context, "请选择", ["保存图片"]);
                    if ("保存图片" == action) {
                      await savePixivImage(metas[i].original, context);
                    }
                  },
                  child: pic,
                );
                pictures.add(pic);
              }
              return Stack(
                children: [
                  ListView(
                    children: [
                      ...pictures,
                      _buildAuthor(),
                    ],
                  ),
                  ..._buildNavBar(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNavBar() {
    return [
      SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: ShadowIconButton(
              icon: Icons.arrow_back,
              onPressed: () {
                Navigator.of(context).pop();
              }),
        ),
      ),
      SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ShadowIconButton(
                icon: Icons.share,
                onPressed: () {},
              ),
              ShadowIconButton(
                icon: Icons.more_vert,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    ];
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
                Text(formatDate(
                    widget.illust.createDate, [yyyy, "-", mm, "-", dd])),
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
}
