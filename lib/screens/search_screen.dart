import 'dart:async';

import 'package:flutter/material.dart';
import './components/flutter_search_bar.dart' as sb;
import 'package:pansy/basic/commons.dart';
import 'package:pansy/basic/stores/tag_history_store.dart';

import '../src/rust/api/api.dart';
import '../src/rust/udto.dart';
import 'components/content_builder.dart';
import 'components/first_url_illust_flow.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

const ILLUST_SEARCH_MODE_PARTIAL_MATCH_FOR_TAGS = "partial_match_for_tags";
const ILLUST_SEARCH_MODE_EXACT_MATCH_FOR_TAGS = "exact_match_for_tags";
const ILLUST_SEARCH_MODE_TITLE_AND_CAPTION = "title_and_caption";

String tagModeNameAlias(String mode) {
  switch (mode) {
    case ILLUST_SEARCH_MODE_PARTIAL_MATCH_FOR_TAGS:
      return "PT";
    case ILLUST_SEARCH_MODE_EXACT_MATCH_FOR_TAGS:
      return "ET";
    case ILLUST_SEARCH_MODE_TITLE_AND_CAPTION:
      return "TAC";
  }
  return "";
}

Future<String?> chooseMode(BuildContext context) async {
  return await chooseMapDialog(
    context,
    {
      AppLocalizations.of(context)!.partial_match_for_tags:
          ILLUST_SEARCH_MODE_PARTIAL_MATCH_FOR_TAGS,
      AppLocalizations.of(context)!.exact_match_for_tags:
          ILLUST_SEARCH_MODE_EXACT_MATCH_FOR_TAGS,
      AppLocalizations.of(context)!.title_and_caption:
          ILLUST_SEARCH_MODE_TITLE_AND_CAPTION,
    },
    AppLocalizations.of(context)!.chooseMatchMode,
  );
}

class SearchScreen extends StatefulWidget {
  final String mode;
  final String word;

  const SearchScreen({Key? key, required this.mode, required this.word})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  void initState() {
    recordTag(widget.word);
    super.initState();
  }

  late Future<String> _future = illustSearchFirstUrl(
      query: UiIllustSearchQuery(mode: widget.mode, word: widget.word));

  late final TextEditingController _textEditController =
      TextEditingController(text: widget.word);

  late final sb.SearchBar _searchBar = sb.SearchBar(
    hintText: AppLocalizations.of(context)!.search,
    controller: _textEditController,
    inBar: false,
    setState: setState,
    onSubmitted: (value) {
      if (value.isNotEmpty) {
        recordTag(value);
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
          Column(children: [
            Expanded(child: Container()),
            MaterialButton(
              minWidth: 50,
              onPressed: () async {
                String? mode = await chooseMode(context);
                if (mode != null && mode != widget.mode) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (BuildContext context) {
                      return SearchScreen(mode: mode, word: widget.word);
                    }),
                  );
                }
              },
              child: Column(
                children: [
                  const Icon(
                    Icons.style,
                    size: 20,
                  ),
                  Text(
                    tagModeNameAlias(widget.mode),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            Expanded(child: Container()),
          ],),
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
            _future = illustSearchFirstUrl(
                query: UiIllustSearchQuery(mode: widget.mode, word: widget.word));
          });
        },
        successBuilder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          return FirstUrlIllustFlow(firstUrl: snapshot.requireData);
        },
      ),
    );
  }
}
