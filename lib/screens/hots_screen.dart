import 'package:flutter/material.dart';
import 'package:pansy/basic/ranks.dart';

import '../ffi.dart';
import 'components/content_builder.dart';
import 'components/first_url_illust_flow.dart';

class HotsScreen extends StatefulWidget {
  const HotsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HotsScreenState();
}

class _HotsScreenState extends State<HotsScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late final _tabController = TabController(
    initialIndex: 0,
    vsync: this,
    length: ranks.length,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: ranks.map((e) => Tab(text: e)).toList(),
          isScrollable: true,
          labelColor: Colors.black,
        ),
        Expanded(
          child: TabBarView(
            children: ranks.map((e) => _RankTab(mode: e)).toList(),
            controller: _tabController,
            // physics: NeverScrollableScrollPhysics(),
          ),
        ),
      ],
    );
  }
}

class _RankTab extends StatefulWidget {
  final String mode;

  const _RankTab({Key? key, required this.mode}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RankTabState();
}

class _RankTabState extends State<_RankTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late Future<String> _future = api.illustRankFirstUrl(
      query: UiIllustRankQuery(mode: widget.mode, date: ""));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ContentBuilder(
      future: _future,
      onRefresh: () async {
        setState(() {
          _future = api.illustRankFirstUrl(
              query: UiIllustRankQuery(mode: widget.mode, date: ""));
        });
      },
      successBuilder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        return FirstUrlIllustFlow(firstUrl: snapshot.requireData);
      },
    );
  }
}
