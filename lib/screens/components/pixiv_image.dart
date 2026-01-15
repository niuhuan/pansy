import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dart:ui' as ui;

import 'package:pansy/basic/config/picture_source.dart';
import 'package:pansy/src/rust/api/api.dart';

class PixivUrlImageProvider extends ImageProvider<PixivUrlImageProvider> {
  final String url;
  final double scale;

  PixivUrlImageProvider(this.url, {this.scale = 1.0});

  @override
  ImageStreamCompleter loadImage(PixivUrlImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
    );
  }

  @override
  Future<PixivUrlImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<PixivUrlImageProvider>(this);
  }

  Future<ui.Codec> _loadAsync(PixivUrlImageProvider key) async {
    assert(key == this);
    final effectiveUrl = rewritePixivImageUrl(url);
    return ui.instantiateImageCodec(
        await File(await loadPixivImage(url: effectiveUrl)).readAsBytes());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PixivUrlImageProvider && url == other.url && scale == other.scale;

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() => '$runtimeType('
      ' url: ${describeIdentity(url)},'
      ' scale: $scale'
      ')';
}

class PixivImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const PixivImage(this.url, {Key? key, this.width, this.height, this.fit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image(
        image: PixivUrlImageProvider(url),
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: Center(
              child: Icon(
                Icons.broken_image,
                size: 48,
                color: Colors.grey[600],
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ScalePixivImage extends StatelessWidget {
  final String url;
  final Size? originSize;

  const ScalePixivImage({Key? key, required this.url, this.originSize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double? width, height;
        if (originSize != null) {
          width = constraints.maxWidth;
          height =
              constraints.maxWidth * originSize!.height / originSize!.width;
        }
        return PixivImage(url, width: width, height: height);
      },
    );
  }
}
