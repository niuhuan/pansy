import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pansy/screens/components/avatar.dart';
import 'package:pansy/states/pixiv_login.dart';

import '../../../types.dart';

class PixivAccountCard extends StatefulWidget {
  const PixivAccountCard({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PixivAccountCardState();
}

class _PixivAccountCardState extends State<PixivAccountCard> {
  late Future<PixivProfile?> _future = _init();

  Future<PixivProfile?> _init() async {
    if (pixivLogin) {
      return PixivProfile.fromJson(jsonDecode("{}"));
    }
    return null;
  }

  @override
  void initState() {
    pixivLoginEvent.subscribe(_onLoginChange);
    super.initState();
  }

  @override
  void dispose() {
    pixivLoginEvent.unsubscribe(_onLoginChange);
    super.dispose();
  }

  void _onLoginChange(_) {
    setState(() {
      _future = _init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: Stack(
        children: [
          Container(
            child: Container(
              padding: EdgeInsets.only(top: 3),
              child: Card(
                child: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  return Container(
                    width: constraints.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 8),
                        Container(
                          padding: EdgeInsets.only(left: 80),
                          child: Text(
                            pixivLogin ? '已登录' : '未登录',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(height: 6),
                        Container(
                          padding: EdgeInsets.only(left: 100),
                          child: Text(
                            '这个家伙很懒, 什么也没留下',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withAlpha(100),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Container(height: 20),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 15),
            child: Avatar(image: AssetImage('lib/assets/default_avatar.png')),
          ),
          Container(
            margin: EdgeInsets.only(right: 20),
            height: 70,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withAlpha(150),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 15),
            height: 34,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '插画账号',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black.withAlpha(50),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
