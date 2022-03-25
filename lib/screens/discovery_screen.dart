import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pansy/screens/components/content_builder.dart';
import 'package:pansy/screens/components/first_url_illust_flow.dart';

import '../ffi.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<String> _future = api.illustRecommendedFirstUrl();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ContentBuilder(
      future: _future,
      onRefresh: () async {
        setState(() {
          _future = api.illustRecommendedFirstUrl();
        });
      },
      successBuilder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        return FirstUrlIllustFlow(firstUrl: snapshot.requireData);
      },
    );
  }
}
