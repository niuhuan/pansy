import 'package:flutter/material.dart';
import 'package:pansy/screens/components/content_builder.dart';
import 'package:pansy/screens/components/pixiv_image.dart';
import 'package:pansy/screens/search_screen.dart';

import '../types.dart';

class SearchTitleScreen extends StatefulWidget {
  const SearchTitleScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SearchTitleScreenState();
}

class _SearchTitleScreenState extends State<SearchTitleScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _editController = TextEditingController();
  var _mode = ILLUST_SEARCH_MODE_TITLE_AND_CAPTION;
  Future<IllustTrendingTags> _future = illustTrendingTags();

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

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
                        }),
                      );
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
                Row(children: [
                  SizedBox(
                    width: 50,
                    child: MaterialButton(
                      onPressed: () async {
                        var mode = await chooseMode(context);
                        if (mode != null) {
                          setState(() {
                            _mode = mode;
                          });
                        }
                      },
                      child: Column(
                        children: [
                          const Icon(Icons.style,size: 20),
                          Container(height: 2),
                          Text(
                            tagModeNameAlias(_mode),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextFormField(
                        controller: _editController,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _editController.text = _editController.text.trim();
                      if (_editController.text.isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (BuildContext context) {
                            return SearchScreen(
                              mode: _mode,
                              word: _editController.text,
                            );
                          }),
                        );
                      }
                    },
                    icon: const Icon(Icons.search,size: 24),
                  ),
                ]),
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
