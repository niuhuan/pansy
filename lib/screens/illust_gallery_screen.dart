import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pansy/screens/components/empty_app_bar.dart';

import '../types.dart';
import 'components/pixiv_image.dart';
import 'components/shadow_icon_button.dart';

class IllustGalleryScreen extends StatefulWidget {
  final List<MetaPage> metaPages;
  final int startIndex;

  const IllustGalleryScreen(this.metaPages, this.startIndex);

  @override
  State<StatefulWidget> createState() => _IllustGalleryScreenState();
}

class _IllustGalleryScreenState extends State<IllustGalleryScreen> {
  late final _pageController = PageController(initialPage: widget.startIndex);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildControllers() {
    return SafeArea(child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShadowIconButton(
                  icon: Icons.arrow_back,
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
              Expanded(child: Container()),
            ],
          ),
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EmptyAppBar(),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: widget.metaPages.length,
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions.customChild(
                child: PixivImage(
                  widget.metaPages[index].imageUrls.large,
                ),
              );
            },
          ),
          _buildControllers(),
        ],
      ),
    );
  }
}
