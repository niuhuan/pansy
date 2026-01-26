import 'package:flutter/material.dart';
import 'package:pansy/screens/components/first_url_illust_flow.dart';
import 'package:pansy/screens/components/pixiv_image.dart';
import 'package:pansy/screens/user_info_screen.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:pansy/src/rust/pixirust/entities.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// 推荐页面 - 采用瀑布流布局
class RecommendScreen extends StatefulWidget {
  const RecommendScreen({Key? key}) : super(key: key);

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _firstUrl;
  bool _isLoading = true;
  bool _hasError = false;
  int _refreshKey = 0;

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
      final url = await illustRecommendedFirstUrl();
      setState(() {
        _firstUrl = url;
        _isLoading = false;
        _refreshKey++;
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
    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              leading: FutureBuilder(
                future: currentUser(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final user = snapshot.data!;
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => UserInfoScreen(
                              UserSample(
                                id: user.userId,
                                name: user.name,
                                account: user.account,
                                profileImageUrls: ProfileImageUrls(
                                  medium: user.profileImageUrl,
                                ),
                                isFollowed: false,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: PixivUrlImageProvider(
                                user.profileImageUrl,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              title: Align(
                alignment: Alignment.centerRight,
                child: Text(AppLocalizations.of(context)!.discover),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadFirstUrl,
                ),
              ],
            ),
          ];
        },
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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
      key: ValueKey(_refreshKey),
      firstUrl: _firstUrl!,
    );
  }
}
