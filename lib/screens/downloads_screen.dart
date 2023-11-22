import 'package:flutter/material.dart';
import 'package:pansy/ffi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'components/pixiv_image.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<Downloading> _list = [];

  Future _fetch() async {
    _list = await api.downloadingList();
    setState(() {});
  }

  @override
  void initState() {
    _fetch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.1,
        title: Text(
          AppLocalizations.of(context)!.downloads,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await api.resetFailedDownloads();
              _fetch();
            },
          ),
        ],
      ),
      body: ListView(children: [
        ..._buildItems(),
      ]),
    );
  }

  List<Widget> _buildItems() {
    List<Widget> items = [];
    for (var item in _list) {
      items.add(_buildItem(item));
    }
    return items;
  }

  Widget _buildItem(Downloading item) {
    return Container(
      padding: EdgeInsets.all(5),
      child: Row(children: [
        PixivImage(
          item.squareMedium,
          width: 70,
          height: 70,
        ),
        Expanded(
          child: SizedBox(
            height: 70,
            child: Column(
              children: [
                Expanded(child: Container()),
                Text(item.illustTitle),
                Expanded(child: Container()),
                Text(item.downloadStatus == 2 ? "下载失败" : "下载中"),
                Expanded(child: Container()),
                ...(item.downloadStatus == 2
                    ? [
                        Text(
                          item.errorMsg,
                          maxLines: 1,
                        ),
                        Expanded(child: Container()),
                      ]
                    : []),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
