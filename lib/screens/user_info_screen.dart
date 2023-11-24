import 'dart:ui';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pansy/ffi.dart';
import 'package:pansy/screens/components/pixiv_image.dart';

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

  @override
  void initState() {
    _future = api.userDetail(userId: widget.userSample.id);
    _scrollController = ScrollController();
    _scrollController.addListener(_setState);
    super.initState();
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
              title: const Text("用户信息"),
            ),
            body: Text("${widget.userSample.id} : ${snapshot.error}"),
          );
        }
        return const Center(child: CircularProgressIndicator());
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
    var end = 0 - maxPosition; // 0 到 maxPosition之间的距离便是总长度, 得到一个正数
    var current = 0 - currentPosition; // 0 到 currentPosition之间的距离便是当前长度, 得到一个正数
    double percent = max(0, current / end); // 当前长度占总长度的百分比
    // 滑动距离越长颜色越深，越模糊
    double appBarOpacity = 0.2 * percent;
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
    );
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
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    style: BorderStyle.solid,
                    width: 3,
                  )),
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
            style: Theme.of(context).textTheme.headline6,
          ),
        ),
        Container(height: 10),
        Row(children: [
          Expanded(
            child: Container(),
          ),
          Text(
            "${userDetail.profile.totalFollowUsers} 关注",
            style: Theme.of(context).textTheme.subtitle1,
          ),
          Container(width: 5),
          Text(
            "${userDetail.profile.totalMypixivUsers} P友",
            style: Theme.of(context).textTheme.subtitle1,
          ),
          Expanded(
            child: Container(),
          ),
        ]),
        Container(height: 10),
        _buildIllusts(userDetail),
        Container(
          height: 3000,
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

  Widget _buildIllusts(UserDetail userDetail) {
    return Column();
  }
}
