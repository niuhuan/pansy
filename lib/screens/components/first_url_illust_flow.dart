
import 'package:flutter/material.dart';
import '../../src/rust/api/api.dart';
import '../../src/rust/pixirust/entities.dart';
import 'illust_flow.dart';

class FirstUrlIllustFlow extends StatefulWidget {

  final String firstUrl;
  const FirstUrlIllustFlow({Key? key, required this.firstUrl}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FirstUrlIllustFlowState();

}

class _FirstUrlIllustFlowState extends State<FirstUrlIllustFlow> {

  String _nextUrl = "";

  Future<List<Illust>> _next() async {
    if (_nextUrl == "") {
      _nextUrl = widget.firstUrl;
    }
    var response = await illustFromUrl(url: _nextUrl);
    _nextUrl = response.nextUrl;
    return response.illusts;
  }

  @override
  Widget build(BuildContext context) {
    return IllustFlow(nextPage: _next);
  }

}
