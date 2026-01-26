import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pansy/screens/components/first_url_illust_flow.dart';
import 'package:pansy/screens/search_common.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:pansy/src/rust/udto.dart';

/// 搜索结果页面
class SearchResultScreen extends StatefulWidget {
  final String query;
  final String mode;

  const SearchResultScreen({
    super.key,
    required this.query,
    this.mode = ILLUST_SEARCH_MODE_PARTIAL_MATCH_FOR_TAGS,
  });

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _query;
  List<String> _sortOptions = ['date_desc'];
  bool _isVip = false;

  @override
  void initState() {
    super.initState();
    _query = widget.query;
    _tabController = TabController(length: _sortOptions.length, vsync: this);
    _checkVipStatus();
  }

  Future<void> _editQuery() async {
    final controller = TextEditingController(text: _query);
    try {
      final next = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.search),
            content: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(controller.text.trim()),
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
              ),
            ],
          );
        },
      );
      final trimmed = next?.trim() ?? '';
      if (!mounted) return;
      if (trimmed.isEmpty || trimmed == _query) return;
      setState(() {
        _query = trimmed;
      });
    } finally {
      controller.dispose();
    }
  }

  Future<void> _checkVipStatus() async {
    try {
      final user = await currentUser();
      final isVip = user?.isPremium ?? false;
      final nextOptions = isVip ? ['date_desc', 'popular_desc'] : ['date_desc'];
      if (!mounted) return;

      if (_isVip == isVip && _sortOptions.length == nextOptions.length) {
        return;
      }

      setState(() {
        _isVip = isVip;
        _sortOptions = nextOptions;
        if (_tabController.length != _sortOptions.length) {
          final old = _tabController;
          _tabController =
              TabController(length: _sortOptions.length, vsync: this);
          old.dispose();
        }
      });
    } catch (e) {
      // Ignore VIP status failure; default to non-VIP sort options.
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasTabs = _sortOptions.length > 1;
    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              title: InkWell(
                onTap: _editQuery,
                child: Text(
                  _query,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              actions: [
                Column(
                  children: [
                    const Expanded(child: SizedBox.shrink()),
                    MaterialButton(
                      minWidth: 50,
                      onPressed: () async {
                        String? mode = await chooseMode(context);
                        if (mode != null && mode != widget.mode) {
                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (BuildContext context) {
                                return SearchResultScreen(
                                  query: _query,
                                  mode: mode,
                                );
                              },
                            ),
                          );
                        }
                      },
                      child: Column(
                        children: [
                          const Icon(Icons.style, size: 20),
                          Text(
                            tagModeNameAlias(widget.mode),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ],
              bottom: hasTabs
                  ? TabBar(
                      controller: _tabController,
                      tabs: _sortOptions.map((sort) {
                        if (sort == 'date_desc') {
                          return Tab(text: AppLocalizations.of(context)!.latest);
                        } else {
                          return Tab(text: AppLocalizations.of(context)!.popular);
                        }
                      }).toList(),
                    )
                  : null,
            ),
          ];
        },
        body: hasTabs
            ? TabBarView(
                controller: _tabController,
                children: _sortOptions.map((sort) {
                  return _SearchResultTab(
                    key: ValueKey('$_query|${widget.mode}|$sort'),
                    query: _query,
                    sort: sort,
                    mode: widget.mode,
                  );
                }).toList(),
              )
            : _SearchResultTab(
                key: ValueKey('$_query|${widget.mode}|${_sortOptions.first}'),
                query: _query,
                sort: _sortOptions.first,
                mode: widget.mode,
              ),
      ),
    );
  }
}

class _SearchResultTab extends StatefulWidget {
  final String query;
  final String sort;
  final String mode;

  const _SearchResultTab({
    super.key,
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

  String? _firstUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadFirstUrl();
  }

  Future<void> _loadFirstUrl() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final url = await illustSearchFirstUrl(
        query: UiIllustSearchQuery(
          word: widget.query,
          searchTarget: widget.mode,
          sort: widget.sort,
        ),
      );
      setState(() {
        _firstUrl = url;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError || _firstUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.loadFailed),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFirstUrl,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    return FirstUrlIllustFlow(
      firstUrl: _firstUrl!,
    );
  }
}
