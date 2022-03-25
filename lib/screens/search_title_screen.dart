import 'package:flutter/material.dart';
import 'package:pansy/screens/components/content_builder.dart';
import 'package:pansy/screens/components/pixiv_image.dart';
import 'package:pansy/screens/search_screen.dart';

import '../types.dart';

class PixivSearchScreen extends StatefulWidget {
  const PixivSearchScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PixivSearchScreenState();
}

class _PixivSearchScreenState extends State<PixivSearchScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<IllustTrendingTags> _future = illustTrendingTags();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ContentBuilder(
      future: _future,
      onRefresh: () async {
        setState(() {
          _future = illustTrendingTags();
        });
      },
      successBuilder:
          (BuildContext context, AsyncSnapshot<IllustTrendingTags> snapshot) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            var space = 3;
            var size = (constraints.maxWidth - space) / 3;
            var children = snapshot.requireData.trendTags
                .map(
                  (e) => GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (BuildContext context) {
                        return SearchScreen(
                          mode: ILLUST_SEARCH_MODE_EXACT_MATCH_FOR_TAGS,
                          word: e.tag,
                        );
                      }));
                    },
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: Stack(
                        children: [
                          PixivImage(
                            e.illust.imageUrls.squareMedium,
                            width: size,
                            height: size,
                          ),
                          Container(color: Colors.black.withOpacity(.3)),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                "#${e.tag}",
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList();
            return ListView(
              children: [
                Container(height: 10),
                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  runSpacing: space / 3,
                  children: children,
                ),
                Container(height: 10),
              ],
            );
          },
        );
      },
    );
  }
}
