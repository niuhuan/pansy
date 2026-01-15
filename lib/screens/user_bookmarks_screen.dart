import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pansy/basic/config/illust_display.dart';
import 'package:pansy/screens/components/illust_card.dart';
import 'package:pansy/screens/illust_info_screen.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:pansy/src/rust/pixirust/entities.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// 用户收藏作品列表页面
class UserBookmarksScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final bool isOwnProfile;

  const UserBookmarksScreen({
    Key? key,
    required this.userId,
    required this.userName,
    this.isOwnProfile = false,
  }) : super(key: key);

  @override
  State<UserBookmarksScreen> createState() => _UserBookmarksScreenState();
}

class _UserBookmarksScreenState extends State<UserBookmarksScreen> {
  final List<Illust> _illusts = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _nextUrl;
  final ScrollController _scrollController = ScrollController();
  String _restrict = 'public';

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
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

  Future<void> _loadBookmarks() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await userBookmarks(
        userId: widget.userId,
        restrict: _restrict,
        tag: null,
      );
      setState(() {
        _illusts.clear();
        _illusts.addAll(result.illusts);
        _nextUrl = result.nextUrl;
        _isLoading = false;
      });
    } catch (e) {
      print('Load bookmarks error: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName} - ${AppLocalizations.of(context)!.bookmarks}'),
        actions: widget.isOwnProfile ? [
          TextButton(
            onPressed: () {
              setState(() {
                _restrict = _restrict == 'public' ? 'private' : 'public';
              });
              _loadBookmarks();
            },
            child: Text(
              _restrict == 'public' 
                ? AppLocalizations.of(context)!.public 
                : AppLocalizations.of(context)!.private,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ] : null,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {

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
                onPressed: _loadBookmarks,
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
        onRefresh: _loadBookmarks,
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
