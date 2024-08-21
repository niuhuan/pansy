import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../src/rust/pixirust/entities.dart';
import '../user_info_screen.dart';
import 'pixiv_image.dart';

AppBar buildUserSampleAppBar(
  BuildContext context,
  UserSample user,
  List<Widget>? actions,
) {
  final theme = Theme.of(context);
  return AppBar(
    backgroundColor: theme.scaffoldBackgroundColor,
    foregroundColor: theme.textTheme.bodyLarge?.color ?? Colors.black,
    centerTitle: false,
    elevation: 0.1,
    title: Text.rich(
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
                  url: user.profileImageUrls.medium,
                ),
              ),
            ),
          ),
          WidgetSpan(child: Container(width: 10)),
          TextSpan(
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (BuildContext context) {
                  return UserInfoScreen(user);
                }));
              },
            text: user.name,
          ),
        ],
      ),
    ),
    actions: actions,
  );
}
