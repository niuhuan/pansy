import 'package:pansy/src/rust/api/api.dart';
import 'package:signals_flutter/signals_flutter.dart';

const waterfallColumnsKey = 'waterfall_columns';
const waterfallColumnsDefault = 2;

final waterfallColumnsSignal = signal<int>(waterfallColumnsDefault);

Future<void> initWaterfallColumns() async {
  final raw = (await loadProperty(k: waterfallColumnsKey)).trim();
  if (raw.isEmpty) return;
  final value = int.tryParse(raw);
  if (value != null && value >= 1 && value <= 6) {
    waterfallColumnsSignal.value = value;
  }
}

Future<void> setWaterfallColumns(int value) async {
  await saveProperty(k: waterfallColumnsKey, v: value.toString());
  waterfallColumnsSignal.value = value;
}
