import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'package:pansy/basic/commons.dart';

import '../ffi.dart';
import 'components/content_builder.dart';
import 'components/first_url_illust_flow.dart';

const ILLUST_SEARCH_MODE_PARTIAL_MATCH_FOR_TAGS = "partial_match_for_tags";
const ILLUST_SEARCH_MODE_EXACT_MATCH_FOR_TAGS = "exact_match_for_tags";
const ILLUST_SEARCH_MODE_TITLE_AND_CAPTION = "title_and_caption";

class SearchScreen extends StatefulWidget {
  final String mode;
  final String word;

  const SearchScreen({Key? key, required this.mode, required this.word})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late Future<String> _future = api.illustSearchFirstUrl(
      query: IllustSearchQuery(mode: widget.mode, word: widget.word));

  late final TextEditingController _textEditController =
      TextEditingController(text: widget.word);

  late final SearchBar _searchBar = SearchBar(
    hintText: '搜索',
    controller: _textEditController,
    inBar: false,
    setState: setState,
    onSubmitted: (value) {
      if (value.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SearchScreen(
              mode: widget.mode,
              word: value,
            ),
          ),
        );
      }
    },
    buildDefaultAppBar: (BuildContext context) {
      return AppBar(
        title: Text(" ${widget.word}"),
        actions: [
          IconButton(
            onPressed: () async {
              String? mode = await chooseMapDialog(
                  context,
                  {
                    "标签部分一致": "partial_match_for_tags",
                    "标签完全一致": "exact_match_for_tags",
                    "标题说明文": "title_and_caption",
                  },
                  "选择匹配模式");
              if (mode != null && mode != widget.mode) {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (BuildContext context) {
                  return SearchScreen(mode: mode, word: widget.word);
                }));
              }
            },
            icon: const Icon(Icons.style),
          ),
          _searchBar.getSearchAction(context),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _searchBar.build(context),
      body: ContentBuilder(
        future: _future,
        onRefresh: () async {
          setState(() {
            _future = api.illustSearchFirstUrl(
                query: IllustSearchQuery(mode: widget.mode, word: widget.word));
          });
        },
        successBuilder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          return FirstUrlIllustFlow(firstUrl: snapshot.requireData);
        },
      ),
    );
  }
}
