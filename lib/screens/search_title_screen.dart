import 'package:flutter/material.dart';
import 'package:pansy/bridge/pixiv.dart';
import 'package:pansy/basic/stores/tag_history_store.dart';
import 'package:pansy/screens/components/content_builder.dart';
import 'package:pansy/screens/components/pixiv_image.dart';
import 'package:pansy/screens/search_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:signals_flutter/signals_flutter.dart';

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
                      recordTag(e.tag);
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
                _historySection(),
                Row(children: [
                  SizedBox(
                    width: 80,
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
                  Container(width: 10),
                  IconButton(
                    onPressed: () {
                      _editController.text = _editController.text.trim();
                      if (_editController.text.isNotEmpty) {
                        recordTag(_editController.text);
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
                  Container(width: 10),
                ]),
                Container(height: 10),
                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  runSpacing: space / 3,
                  children: children,
                ),
                Container(height: 20),
              ],
            );
          },
        );
      },
    );
  }

  Widget _historySection() {
    return Watch((context) {
      final pinned = pinnedTags.map((e) => e.tag).toList();
      final recent = recentTags.map((e) => e.tag).toList();
      if (pinned.isEmpty && recent.isEmpty) return const SizedBox.shrink();
      final tags = [...pinned, ...recent.take(12)];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.tags,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => clearTagHistory(),
                  child: Text(AppLocalizations.of(context)!.clear),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tags.map((t) {
                final isPinned = pinned.contains(t);
                return GestureDetector(
                  onLongPress: () => togglePinTag(t),
                  child: ActionChip(
                    avatar: isPinned ? const Icon(Icons.push_pin, size: 16) : null,
                    label: Text('#$t'),
                    onPressed: () {
                      recordTag(t);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) {
                          return SearchScreen(
                            mode: ILLUST_SEARCH_MODE_EXACT_MATCH_FOR_TAGS,
                            word: t,
                          );
                        }),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }
}
