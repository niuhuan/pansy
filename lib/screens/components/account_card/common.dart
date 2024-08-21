import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../avatar.dart';

Widget accountCard(
  BuildContext context,
  String accountType,
  ImageProvider image,
  String nickname,
  String info,
) {
  return Container(
    padding: EdgeInsets.only(left: 15, right: 15),
    child: Stack(
      children: [
        Container(
          child: Container(
            padding: EdgeInsets.only(top: 3),
            child: Card(
              child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                return Container(
                  width: constraints.maxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 8),
                      Container(
                        padding: EdgeInsets.only(left: 80),
                        child: Text(
                          nickname,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(height: 6),
                      Container(
                        padding: EdgeInsets.only(left: 80),
                        child: Text(
                          info,
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
          child: Avatar(image: image),
        ),
        Container(
          margin: EdgeInsets.only(right: 7, top: 7),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              accountType,
              style: TextStyle(
                fontSize: 10,
                color: Colors.black.withAlpha(30),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget unlessLoginAccountCard(BuildContext context, String type, String title) {
  return accountCard(
    context,
    type,
    AssetImage('lib/assets/default_avatar.png'),
    title,
    '这个家伙很懒, 什么也没留下',
  );
}

Widget noLoginAccountCard(BuildContext context, String type) {
  return unlessLoginAccountCard(context, type, '未登录');
}

Widget errorLoginAccountCard(BuildContext context, String type) {
  return unlessLoginAccountCard(context, type, '获取个人信息出错');
}

Widget loadingLoginAccountCard(BuildContext context, String type) {
  return unlessLoginAccountCard(context, type, '加载中');
}
