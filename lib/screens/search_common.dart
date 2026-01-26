import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pansy/basic/commons.dart';

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
  return chooseMapDialog(
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

