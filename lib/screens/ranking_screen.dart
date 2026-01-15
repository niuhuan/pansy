import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pansy/basic/ranks.dart';
import 'package:pansy/screens/components/illust_card.dart';
import 'package:pansy/screens/illust_info_screen.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:pansy/src/rust/pixirust/entities.dart';
import 'package:pansy/src/rust/udto.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// 排行榜页面 - 带Tab切换
class RankingScreen extends StatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: ranks.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 2)),
      firstDate: DateTime(2007, 9, 13),
      lastDate: DateTime.now().subtract(const Duration(days: 1)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              pinned: true,
              title: Text(AppLocalizations.of(context)!.ranking),
              actions: [
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: () => _selectDate(context),
                  tooltip: AppLocalizations.of(context)!.selectDate,
                ),
                if (_selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                      });
                    },
                  ),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: ranks.map((mode) => Tab(text: _getRankName(context, mode))).toList(),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: ranks.map((mode) {
            return _RankingTab(
              mode: mode,
              date: _selectedDate != null ? _formatDate(_selectedDate!) : '',
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getRankName(BuildContext context, String mode) {
    final names = {
      'day': '日榜',
      'week': '周榜',
      'month': '月榜',
      'day_male': '男性向',
      'day_female': '女性向',
      'week_original': '原创',
      'week_rookie': '新人',
      'day_r18': 'R18日榜',
      'day_male_r18': 'R18男性',
      'day_female_r18': 'R18女性',
      'week_r18': 'R18周榜',
      'week_r18g': 'R18G',
    };
    return names[mode] ?? mode;
  }
}

class _RankingTab extends StatefulWidget {
  final String mode;
  final String date;

  const _RankingTab({
    required this.mode,
    required this.date,
  });

  @override
  State<_RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<_RankingTab>
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
    _loadRanking();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(_RankingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _loadRanking();
    }
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

  Future<void> _loadRanking() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final firstUrl = await illustRankFirstUrl(
        query: UiIllustRankQuery(mode: widget.mode, date: widget.date),
      );
      final result = await illustFromUrl(url: firstUrl);
      setState(() {
        _illusts.clear();
        _illusts.addAll(result.illusts);
        _nextUrl = result.nextUrl;
        _isLoading = false;
      });
    } catch (e) {
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              onPressed: _loadRanking,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRanking,
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
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    return 2;
  }
}
