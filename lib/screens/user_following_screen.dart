import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pansy/screens/components/pixiv_image.dart';
import 'package:pansy/screens/user_info_screen.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:pansy/src/rust/pixirust/entities.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// 用户关注列表页面
class UserFollowingScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const UserFollowingScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<UserFollowingScreen> createState() => _UserFollowingScreenState();
}

class _UserFollowingScreenState extends State<UserFollowingScreen> {
  final List<UserSample> _users = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _nextUrl;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
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

  Future<void> _loadUsers() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await userFollowing(
        userId: widget.userId,
        restrict: 'public',
      );
      setState(() {
        _users.clear();
        // Extract users from UserPreview list
        _users.addAll(result.userPreviews.map((preview) => preview.user));
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
      final result = await userPreviewsFromUrl(url: _nextUrl!);
      setState(() {
        // Add more users
        _users.addAll(result.userPreviews.map((preview) => preview.user));
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
        title: Text('${widget.userName} - ${AppLocalizations.of(context)!.following}'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {

    if (_hasError && _users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.loadFailed),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty && !_isLoading) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noResults),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _users.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _users.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final user = _users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: PixivUrlImageProvider(
                user.profileImageUrls.medium,
              ),
            ),
            title: Text(user.name),
            subtitle: Text('@${user.account}'),
            onTap: () {
              // Navigate to user detail
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserInfoScreen(
                    UserSample(
                      id: user.id,
                      name: user.name,
                      profileImageUrls: user.profileImageUrls,
                      account: user.account,
                      isFollowed: user.isFollowed,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
