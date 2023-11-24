import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dart:ui' as ui show Codec;

import 'package:pansy/ffi.dart';

class PixivUrlImageProvider extends ImageProvider<PixivUrlImageProvider> {
  final String url;
  final double scale;

  PixivUrlImageProvider(this.url, {this.scale = 1.0});

  @override
  ImageStreamCompleter load(PixivUrlImageProvider key, DecoderCallback decode) {
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
    return PaintingBinding.instance!.instantiateImageCodec(
        await File(await api.loadPixivImage(url: url)).readAsBytes());
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final PixivUrlImageProvider typedOther = other;
    return url == typedOther.url && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(url, scale);

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
