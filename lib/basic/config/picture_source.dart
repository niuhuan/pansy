import 'package:pansy/src/rust/api/api.dart';
import 'package:signals_flutter/signals_flutter.dart';

const pictureSourceKey = 'picture_source';

const imageHost = 'i.pximg.net';
const imageProxyHost = 'i.pixiv.re';
const imageStaticHost = 's.pximg.net';

final pictureSourceSignal = signal<String>(imageHost);

Future<void> initPictureSource() async {
  final v = await loadProperty(k: pictureSourceKey);
  if (v.trim().isNotEmpty) {
    pictureSourceSignal.value = v.trim();
  }
}

Future<void> setPictureSource(String value) async {
  final v = value.trim();
  await saveProperty(k: pictureSourceKey, v: v);
  pictureSourceSignal.value = v.isEmpty ? imageHost : v;
}

String rewritePixivImageUrl(String url) {
  final src = Uri.tryParse(url);
  if (src == null) return url;
  if (src.host != imageHost && src.host != imageStaticHost) return url;

  final configured = pictureSourceSignal.value.trim();
  if (configured.isEmpty || configured == imageHost) return url;

  final base = Uri.tryParse(configured.contains('://') ? configured : 'https://$configured');
  if (base == null || base.host.isEmpty) return url;

  final basePath = base.path;
  final prefix = basePath.endsWith('/') ? basePath.substring(0, basePath.length - 1) : basePath;
  final newPath = prefix.isEmpty
      ? src.path
      : (src.path.startsWith('/') ? '$prefix${src.path}' : '$prefix/${src.path}');

  return src
      .replace(
        scheme: base.scheme.isEmpty ? src.scheme : base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
        path: newPath,
      )
      .toString();
}

