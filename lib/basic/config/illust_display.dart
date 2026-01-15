import 'package:pansy/src/rust/api/api.dart';
import 'package:signals_flutter/signals_flutter.dart';

const illustOnlyShowImagesKey = 'illust_only_show_images';

/// Only show image area in illust cards (hide title/author/stats).
final illustOnlyShowImagesSignal = signal<bool>(false);

Future<void> initIllustOnlyShowImages() async {
  final raw = (await loadProperty(k: illustOnlyShowImagesKey)).trim();
  if (raw.isEmpty) return;
  illustOnlyShowImagesSignal.value = raw == '1' || raw.toLowerCase() == 'true';
}

Future<void> setIllustOnlyShowImages(bool value) async {
  await saveProperty(k: illustOnlyShowImagesKey, v: value ? '1' : '0');
  illustOnlyShowImagesSignal.value = value;
}

