import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:pansy/src/rust/frb_generated.dart';
import 'package:pansy/screens/components/pixiv_image.dart';
import 'package:pansy/screens/components/shadow_icon_button.dart';
import 'package:pansy/screens/illust_info_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../src/rust/pixirust/entities.dart';
import 'user_illusts_screen.dart';
import 'user_following_screen.dart';
import 'user_bookmarks_screen.dart';

class UserInfoScreen extends StatefulWidget {
  final UserSample userSample;
  const UserInfoScreen(this.userSample, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _UserInfoScreenState();
}

const _backdropHeight = 220.0;
const _avatarSize = 95.0;

class _UserInfoScreenState extends State<UserInfoScreen> {
  late Future<UserDetail> _future;
  late ScrollController _scrollController;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  bool _isOwnProfile = false;

  @override
  void initState() {
    _future = userDetail(userId: widget.userSample.id);
    _scrollController = ScrollController();
    _scrollController.addListener(_setState);
    _isFollowing = widget.userSample.isFollowed ?? false;
    _checkIfOwnProfile();
    super.initState();
  }

  Future<void> _checkIfOwnProfile() async {
    final currentUserInfo = await currentUser();
    if (currentUserInfo != null && currentUserInfo.userId == widget.userSample.id) {
      setState(() {
        _isOwnProfile = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_setState);
    _scrollController.dispose();
    super.dispose();
  }

  void _setState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserDetail>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildUserDetail(snapshot.data!);
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(""),
            ),
            body: Text("${widget.userSample.id} : ${snapshot.error}"),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text(""),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildUserDetail(UserDetail userDetail) {
    var statusBarAndAppBarHeight =
        MediaQuery.of(context).padding.top + kBottomNavigationBarHeight;
    var maxPosition = statusBarAndAppBarHeight - _backdropHeight; // 是个负数
    var currentPosition = _scrollController.positions.length != 1
        ? .0
        : max(-_scrollController.offset,
            maxPosition); // 是个负数，所以max得到是绝对值较小那个数的相反数
    var start = 50.0;
    var end = 0 - maxPosition; // 0 到 maxPosition之间的距离便是总长度, 得到一个正数
    var current =
        0 - currentPosition - start; // 0 到 currentPosition之间的距离便是当前长度, 得到一个正数
    var maxValue = end - start; // 总长度
    double percent = max(0, current / maxValue); // 当前长度占总长度的百分比
    // 滑动距离越长颜色越深，越模糊
    double appBarBlur = 10 * percent;

    return Scaffold(
      body: Stack(
        children: [
          _backImage(userDetail),
          SizedBox(
            height: statusBarAndAppBarHeight,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: appBarBlur,
                  sigmaY: appBarBlur,
                ),
                child: Container(),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildAuthorAppBar(),
            body: _buildBody(userDetail),
          ),
        ],
      ),
    ); // kBottomNavigationBarHeight
  }

  AppBar _buildAuthorAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      leading: ShadowIconButton(
        icon: Icons.arrow_back,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Transform.translate(
        offset: Offset(
            0,
            max(
                0,
                _backdropHeight -
                    (_scrollController.positions.length != 1
                        ? .0
                        : _scrollController.offset))),
        child: Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                    child: ScalePixivImage(
                      url: widget.userSample.profileImageUrls.medium,
                    ),
                  ),
                ),
              ),
              WidgetSpan(child: Container(width: 10)),
              TextSpan(
                text: widget.userSample.name,
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (!_isOwnProfile)
          _isFollowLoading
              ? Container(
                  padding: const EdgeInsets.all(12),
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : ShadowIconButton(
                  icon: _isFollowing ? Icons.person_remove : Icons.person_add,
                  onPressed: _toggleFollow,
                ),
        Container(width: 8),
      ],
    );
  }

  Future<void> _toggleFollow() async {
    if (_isFollowLoading) return;
    
    setState(() {
      _isFollowLoading = true;
    });

    try {
      if (_isFollowing) {
        await unfollowUser(userId: widget.userSample.id);
        setState(() {
          _isFollowing = false;
          _isFollowLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.unfollow),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        await followUser(userId: widget.userSample.id, restrict: "public");
        setState(() {
          _isFollowing = true;
          _isFollowLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.following),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isFollowLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildBody(UserDetail userDetail) {
    // _avatarSize
    var statusBarAndAppBarHeight =
        MediaQuery.of(context).padding.top + kBottomNavigationBarHeight;
    return ListView(
      controller: _scrollController,
      children: [
        Container(
            height: _backdropHeight -
                statusBarAndAppBarHeight -
                _avatarSize / 2 -
                3),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [.0, .45, .55, 1],
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).textTheme.bodyMedium?.color ??
                        Colors.black,
                    Theme.of(context).textTheme.bodyMedium?.color ??
                        Colors.black,
                  ],
                ),
                // border: Border.all(
                //   color: Colors.white,
                //   style: BorderStyle.solid,
                //   width: 3,
                // ),
              ),
              child: SizedBox(
                width: _avatarSize,
                height: _avatarSize,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(150)),
                  child: PixivImage(
                    widget.userSample.profileImageUrls.medium,
                    width: _avatarSize,
                    height: _avatarSize,
                  ),
                ),
              ),
            ),
          ],
        ),
        Container(height: 10),
        Center(
          child: Text(
            userDetail.user.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Container(height: 10),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 25,
            runSpacing: 8,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => UserFollowingScreen(
                      userId: widget.userSample.id,
                      userName: widget.userSample.name,
                      isOwnProfile: _isOwnProfile,
                    ),
                  ));
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${userDetail.profile.totalFollowUsers}",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const Text(" "),
                    Text(
                      AppLocalizations.of(context)!.followers,
                      style: const TextStyle(),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => UserBookmarksScreen(
                      userId: widget.userSample.id,
                      userName: widget.userSample.name,
                      isOwnProfile: _isOwnProfile,
                    ),
                  ));
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (userDetail.profile.totalIllustBookmarksPublic > 0) ...[
                      Text(
                        "${userDetail.profile.totalIllustBookmarksPublic}",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const Text(" "),
                    ],
                    Text(
                      AppLocalizations.of(context)!.bookmarks,
                      style: const TextStyle(),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${userDetail.profile.totalMypixivUsers}",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const Text(" "),
                  Text(
                    AppLocalizations.of(context)!.pFriends,
                    style: const TextStyle(),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(height: 20),
        _buildInfos(userDetail),
        Container(height: 20),
        _buildIllusts(userDetail),
        SafeArea(
          top: false,
          child: Container(),
        ),
      ],
    );
  }

  Widget _backImage(UserDetail userDetail) {
    return LayoutBuilder(builder: (context, constraints) {
      var width = constraints.maxWidth;
      var positionOfY = _scrollController.positions.length != 1
          ? .0
          : max(
              -_scrollController.offset,
              MediaQuery.of(context).padding.top +
                  kBottomNavigationBarHeight -
                  _backdropHeight);
      positionOfY = min(positionOfY, 0);
      late Widget backdrop;
      if (userDetail.profile.backgroundImageUrl != null) {
        backdrop = PixivImage(
          userDetail.profile.backgroundImageUrl!,
          height: _backdropHeight,
          width: width,
          fit: BoxFit.cover,
        );
      } else if (userDetail.workspace.workspaceImageUrl != null) {
        backdrop = PixivImage(
          userDetail.workspace.workspaceImageUrl!,
          height: _backdropHeight,
          width: width,
          fit: BoxFit.cover,
        );
      } else {
        backdrop = SizedBox(
          height: _backdropHeight,
          child: ClipRect(
            child: Stack(
              children: [
                PixivImage(
                  userDetail.user.profileImageUrls.medium,
                  height: _backdropHeight,
                  width: width,
                  fit: BoxFit.cover,
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 410,
                    sigmaY: 410,
                  ),
                  child: Container(),
                ),
              ],
            ),
          ),
        );
      }
      return Transform.translate(
        offset: Offset(0, positionOfY),
        child: backdrop,
      );
    });
  }

  Widget _buildInfos(UserDetail userDetail) {
    List<Widget> infos = [];
    if (userDetail.user.comment.isNotEmpty) {
      infos.add(Text(
        userDetail.user.comment,
        style: const TextStyle(
          height: 1.2,
        ),
      ));
      infos.add(Container(height: 10));
    }
    if (userDetail.profile.webpage?.isNotEmpty ?? false) {
      infos.add(_buildUserProperty(
        AppLocalizations.of(context)!.webpage,
        userDetail.profile.webpage!,
      ));
    }
    if (userDetail.profile.gender.isNotEmpty) {
      infos.add(_buildUserProperty(
        AppLocalizations.of(context)!.gender,
        userDetail.profile.gender,
      ));
    }
    if (userDetail.profile.job.isNotEmpty) {
      infos.add(_buildUserProperty(
        AppLocalizations.of(context)!.job,
        userDetail.profile.job,
      ));
    }
    if (userDetail.profile.region.isNotEmpty) {
      infos.add(_buildUserProperty(
        AppLocalizations.of(context)!.region,
        userDetail.profile.region,
      ));
    }

    return LayoutBuilder(builder: (context, constraints) {
      var expandable = infos.length > 3 ||
          _textPainter(userDetail.user.comment, constraints) > 45;

      if (expandable) {
        if (_infoExpand) {
          return Column(
            children: [
              ...infos,
              IconButton(
                  onPressed: () {
                    setState(() {
                      _infoExpand = false;
                    });
                  },
                  icon: Icon(
                    Icons.arrow_upward,
                    color: Theme.of(context).colorScheme.secondary,
                  ))
            ],
          );
        } else {
          return SizedBox(
            height: 14 * 5,
            child: ClipRect(
              child: Stack(
                children: [
                  ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [.0, .45, 1],
                        colors: [
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                      ).createShader(rect);
                    },
                    child: Column(
                      children: infos,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      children: [
                        Expanded(child: Container()),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _infoExpand = true;
                            });
                          },
                          icon: Icon(
                            Icons.arrow_downward,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        Expanded(child: Container()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }

      return Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            ...infos,
          ],
        ),
      );
    });
  }

  bool _infoExpand = false;

  double _textPainter(String text, BoxConstraints constraints) {
    final span = TextSpan(
      text: text,
      style: const TextStyle(
        height: 1.2,
      ),
    );
    final max = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    );
    max.layout(maxWidth: constraints.maxWidth);
    return max.height;
  }

  Widget _buildUserProperty(String title, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(width: 5),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }

  Widget _buildIllusts(UserDetail userDetail) {
    return UserIllusts(userDetail,
        key: Key("USER_INFO_SCREEN::" + userDetail.user.id.toString()));
  }
}

class UserIllusts extends StatefulWidget {
  final UserDetail userDetail;
  const UserIllusts(this.userDetail, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _UserIllustsState();
}

class _UserIllustsState extends State<UserIllusts> {
  late Future<List<Illust>> _future;

  Future<List<Illust>> _fetchIllusts() {
    return userIllustsFirstUrl(userId: widget.userDetail.user.id)
        .then((value) => illustFromUrl(url: value))
        .then((value) => value.illusts);
  }

  @override
  void initState() {
    _future = _fetchIllusts();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Illust>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildIllusts(snapshot.data!);
        } else if (snapshot.hasError) {
          return Text("${widget.userDetail.user.id} : ${snapshot.error}");
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildIllusts(List<Illust> illusts) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => UserIllustsScreen(UserSample(
                      id: widget.userDetail.user.id,
                      name: widget.userDetail.user.name,
                      profileImageUrls: widget.userDetail.user.profileImageUrls,
                      account: widget.userDetail.user.account,
                      isFollowed: widget.userDetail.user.isFollowed,
                    )))),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.illusts,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(width: 5),
                const Text("("),
                Text(
                  "${widget.userDetail.profile.totalIllusts}",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const Text(")"),
                Expanded(
                  child: Container(),
                ),
                Text(
                  AppLocalizations.of(context)!.viewMore,
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
          ),
          Container(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            const scpace = 15;
            var maxWidth = constraints.maxWidth - scpace;
            var height = maxWidth / 3;
            return Wrap(
              spacing: scpace / 2,
              runSpacing: scpace / 2,
              children: [
                for (var illust in illusts.take(15))
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => IllustInfoScreen(illust))),
                    child: SizedBox(
                      width: height,
                      height: height,
                      child: SizedBox(
                        width: height,
                        height: height,
                        child: PixivImage(
                          illust.imageUrls.squareMedium,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
