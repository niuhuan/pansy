import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pansy/basic/config/illust_display.dart';
import 'package:pansy/screens/search_screen.dart' show chooseMode, tagModeNameAlias, ILLUST_SEARCH_MODE_PARTIAL_MATCH_FOR_TAGS;
import 'package:pansy/screens/components/illust_card.dart';
import 'package:pansy/screens/components/pixiv_image.dart';
import 'package:pansy/screens/illust_info_screen.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:pansy/src/rust/pixirust/entities.dart';
import 'package:pansy/src/rust/udto.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// 搜索页面 - 带热门标签和搜索历史
class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
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
    if (query.trim().isEmpty) return;

    if (!_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 20) {
          _searchHistory.removeLast();
        }
      });
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchResultScreen(query: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.search,
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
              },
            ),
          ),
          onSubmitted: _onSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _onSearch(_searchController.text),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
    );
  }
}

/// 搜索结果页面
class SearchResultScreen extends StatefulWidget {
  final String query;
  final String mode;

  const SearchResultScreen({
    Key? key,
    required this.query,
    this.mode = ILLUST_SEARCH_MODE_PARTIAL_MATCH_FOR_TAGS,
  }) : super(key: key);

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _sortOptions = ['date_desc'];
  bool _isVip = false;

  @override
  void initState() {
    super.initState();
    _checkVipStatus();
  }

  Future<void> _checkVipStatus() async {
    try {
      final user = await currentUser();
      final isVip = user?.isPremium ?? false;
      setState(() {
        _isVip = isVip;
        _sortOptions = isVip ? ['date_desc', 'popular_desc'] : ['date_desc'];
        _tabController = TabController(length: _sortOptions.length, vsync: this);
      });
    } catch (e) {
      setState(() {
        _tabController = TabController(length: _sortOptions.length, vsync: this);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.query),
        actions: [
          Column(
            children: [
              Expanded(child: Container()),
              MaterialButton(
                minWidth: 50,
                onPressed: () async {
                  String? mode = await chooseMode(context);
                  if (mode != null && mode != widget.mode) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (BuildContext context) {
                          return SearchResultScreen(
                            query: widget.query,
                            mode: mode,
                          );
                        },
                      ),
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
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _sortOptions.map((sort) {
            if (sort == 'date_desc') {
              return Tab(text: AppLocalizations.of(context)!.latest);
            } else {
              return Tab(text: AppLocalizations.of(context)!.popular);
            }
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _sortOptions.map((sort) {
          return _SearchResultTab(
            query: widget.query,
            sort: sort,
            mode: widget.mode,
          );
        }).toList(),
      ),
    );
  }
}

class _SearchResultTab extends StatefulWidget {
  final String query;
  final String sort;
  final String mode;

  const _SearchResultTab({
    required this.query,
    required this.sort,
    required this.mode,
  });

  @override
  State<_SearchResultTab> createState() => _SearchResultTabState();
}

class _SearchResultTabState extends State<_SearchResultTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<Illust> _illusts = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _nextUrl;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadResults();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      if (!_isLoading && _nextUrl != null) {
        _loadMore();
      }
    }
  }

  Future<void> _loadResults() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      print('Search query: word=${widget.query}, searchTarget=${widget.mode}, sort=${widget.sort}');
      final firstUrl = await illustSearchFirstUrl(
        query: UiIllustSearchQuery(
          word: widget.query,
          searchTarget: widget.mode,
          sort: widget.sort,
        ),
      );
      print('First URL: $firstUrl');
      final result = await illustFromUrl(url: firstUrl);
      setState(() {
        _illusts.clear();
        _illusts.addAll(result.illusts);
        _nextUrl = result.nextUrl;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load search results',
        name: 'SEARCH_ERROR',
        error: e,
        stackTrace: stackTrace,
      );
      print('Search load error: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _nextUrl == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await illustFromUrl(url: _nextUrl!);
      setState(() {
        _illusts.addAll(result.illusts);
        _nextUrl = result.nextUrl;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load more search results',
        name: 'SEARCH_ERROR',
        error: e,
        stackTrace: stackTrace,
      );
      print('Search load more error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Watch((context) {
      final onlyImages = illustOnlyShowImagesSignal.value;

      if (_hasError && _illusts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.loadFailed),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadResults,
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        );
      }

      if (_illusts.isEmpty && !_isLoading) {
        return Center(
          child: Text(AppLocalizations.of(context)!.noResults),
        );
      }

      return RefreshIndicator(
        onRefresh: _loadResults,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(4),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: _getCrossAxisCount(context),
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childCount: _illusts.length,
                itemBuilder: (context, index) {
                  final illust = _illusts[index];
                  return IllustCard(
                    illust: illust,
                    onlyShowImages: onlyImages,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => IllustInfoScreen(illust),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      );
    });
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    return 2;
  }
}
