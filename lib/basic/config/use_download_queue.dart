import 'package:pansy/src/rust/api/api.dart';
import 'package:signals_flutter/signals_flutter.dart';

const useDownloadQueueKey = 'use_download_queue';

final useDownloadQueueSignal = signal<bool>(true);

Future<void> initUseDownloadQueue() async {
  final raw = (await loadProperty(k: useDownloadQueueKey)).trim();
  if (raw == 'false') {
    useDownloadQueueSignal.value = false;
  } else {
    useDownloadQueueSignal.value = true;
  }
}

Future<void> setUseDownloadQueue(bool value) async {
  await saveProperty(k: useDownloadQueueKey, v: value.toString());
  useDownloadQueueSignal.value = value;
}
