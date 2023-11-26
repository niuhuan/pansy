import 'package:flutter/material.dart';
import 'package:pansy/ffi.dart';
import 'package:pansy/screens/components/appbar.dart';
import 'package:pansy/screens/components/first_url_illust_flow.dart';

class UserIllustsScreen extends StatefulWidget {
  final UserSample user;
  const UserIllustsScreen(this.user, {Key? key}) : super(key: key);

  @override
  State<UserIllustsScreen> createState() => _UserIllustsScreenState();
}

class _UserIllustsScreenState extends State<UserIllustsScreen> {
  late final Future<String> _firstUrlFuture =
      api.userIllustsFirstUrl(userId: widget.user.id);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _firstUrlFuture,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: buildUserSampleAppBar(
              context,
              widget.user,
              [],
            ),
            body: Center(
              child: Text(snapshot.error.toString()),
            ),
          );
        }
        if (snapshot.hasData) {
          return Scaffold(
            appBar: buildUserSampleAppBar(
              context,
              widget.user,
              [],
            ),
            body: FirstUrlIllustFlow(
              firstUrl: snapshot.data!,
            ),
          );
        }
        return Scaffold(
          appBar: buildUserSampleAppBar(
            context,
            widget.user,
            [],
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
