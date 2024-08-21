import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:waterfall_flow/waterfall_flow.dart';
import '../../src/rust/pixirust/entities.dart';
import '../../types.dart';
import '../illust_info_screen.dart';
import 'image_size_abel.dart';
import 'pixiv_image.dart';

class IllustFlow extends StatefulWidget {
  final FutureOr<List<Illust>> Function() nextPage;

  const IllustFlow({required this.nextPage, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _IllustFlowState();
}

class _IllustFlowState extends State<IllustFlow> {
  late ScrollController _controller;
  late Future _joinFuture;
  late var _joining = false;
  final List<Illust> _data = [];

  Future _join() async {
    try {
      setState(() {
        _joining = true;
      });
      _data.addAll(await widget.nextPage());
    } finally {
      setState(() {
        _joining = false;
      });
    }
  }

  @override
  void initState() {
    _controller = ScrollController();
    _controller.addListener(_onScroll);
    _joinFuture = _join();
    super.initState();
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_joining) {
      return;
    }
    if (_controller.position.pixels < _controller.position.maxScrollExtent) {
      return;
    }
    setState(() {
      _joinFuture = _join();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildFlow(),
    );
  }

  Widget _buildFlow() {
    return WaterfallFlow.builder(
      controller: _controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      itemCount: _data.length + 1,
      gridDelegate: const SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
      itemBuilder: (BuildContext context, int index) {
        if (index >= _data.length) {
          return _buildLoadingCard();
        }
        return _buildImageCard(_data[index]);
      },
    );
  }

  Widget _buildLoadingCard() {
    return FutureBuilder(
      future: _joinFuture,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Card(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: const CupertinoActivityIndicator(
                    radius: 14,
                  ),
                ),
                const Text('加载中'),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          print("${snapshot.error}\n${snapshot.stackTrace}");
          return Card(
            child: InkWell(
              onTap: () {
                setState(() {
                  _joinFuture = _join();
                });
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: const Icon(Icons.sync_problem_rounded),
                  ),
                  const Text('出错, 点击重试'),
                ],
              ),
            ),
          );
        }
        return Container();
      },
    );
  }

  Widget _buildImageCard(Illust item) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) {
            return IllustInfoScreen(item);
          },
        ));
      },
      child: Card(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Stack(
              children: [
                Container(
                  width: constraints.maxWidth,
                  child: ScalePixivImage(
                    url: item.imageUrls.medium,
                    originSize:
                        Size(item.width.toDouble(), item.height.toDouble()),
                  ),
                ),
                Container(
                  width: constraints.maxWidth,
                  child: imageSizeLabel(item.metaPages.length),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
