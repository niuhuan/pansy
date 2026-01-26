import 'package:flutter/material.dart';
import 'package:pansy/screens/components/pixiv_image.dart';
import 'package:pansy/screens/search_result_screen.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:pansy/src/rust/pixirust/entities.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// 搜索页面 - 带热门标签和搜索历史
class SearchHomeScreen extends StatefulWidget {
  const SearchHomeScreen({Key? key}) : super(key: key);

  @override
  State<SearchHomeScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchHomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  final List<String> _searchHistory = [];
  List<TrendTag>? _trendingTags;
  bool _isLoadingTags = false;

  @override
  void initState() {
    super.initState();
    _loadTrendingTags();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingTags() async {
    setState(() {
      _isLoadingTags = true;
    });

    try {
      final result = await illustTrendingTags();
      setState(() {
        _trendingTags = result.trendTags;
        _isLoadingTags = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTags = false;
      });
    }
  }

  void _onSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();

    if (!_searchHistory.contains(trimmed)) {
      setState(() {
        _searchHistory.insert(0, trimmed);
        if (_searchHistory.length > 20) {
          _searchHistory.removeLast();
        }
      });
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchResultScreen(query: trimmed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              title: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.search,
                  border: InputBorder.none,
                ),
                onSubmitted: _onSearch,
              ),
            ),
          ];
        },
        body: ListView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.searchHistory,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchHistory.clear();
                    });
                  },
                  child: Text(AppLocalizations.of(context)!.clear),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory.map((query) {
                return Chip(
                  label: Text(query),
                  onDeleted: () {
                    setState(() {
                      _searchHistory.remove(query);
                    });
                  },
                  deleteIcon: const Icon(Icons.close, size: 18),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.trendingTags,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadTrendingTags,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingTags)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_trendingTags != null)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _trendingTags!.length,
              itemBuilder: (context, index) {
                final tag = _trendingTags![index];
                return InkWell(
                  onTap: () {
                    _searchController.text = tag.tag;
                    _onSearch(tag.tag);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: tag.illust.imageUrls.squareMedium.isNotEmpty
                          ? DecorationImage(
                              image: PixivUrlImageProvider(
                                tag.illust.imageUrls.squareMedium,
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        tag.tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
        ),
      ),
    );
  }
}
