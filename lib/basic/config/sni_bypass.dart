import 'package:pansy/src/rust/api/api.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'dart:convert';

const sniBypassKey = 'bypass_sni';
const sniBypassHostsKey = 'bypass_sni_hosts';

final sniBypassSignal = signal<bool>(false);
final sniBypassHostsSignal = signal<Map<String, String>>({});

const defaultSniBypassHosts = <String, String>{
  'app-api.pixiv.net': '210.140.139.155',
  'oauth.secure.pixiv.net': '210.140.139.155',
  'i.pximg.net': '210.140.139.133',
  's.pximg.net': '210.140.139.133',
};

Future<void> initSniBypass() async {
  final raw = (await loadProperty(k: sniBypassKey)).trim().toLowerCase();
  if (raw.isEmpty) return;
  sniBypassSignal.value = raw == 'true' || raw == '1' || raw == 'yes';
}

Future<void> setSniBypass(bool value) async {
  await saveProperty(k: sniBypassKey, v: value.toString());
  sniBypassSignal.value = value;
}

Future<void> initSniBypassHosts() async {
  final raw = (await loadProperty(k: sniBypassHostsKey)).trim();
  if (raw.isEmpty) {
    final jsonStr = jsonEncode(defaultSniBypassHosts);
    await saveProperty(k: sniBypassHostsKey, v: jsonStr);
    sniBypassHostsSignal.value = Map<String, String>.from(defaultSniBypassHosts);
    return;
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      sniBypassHostsSignal.value = decoded.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
      return;
    }
  } catch (_) {}
  sniBypassHostsSignal.value = Map<String, String>.from(defaultSniBypassHosts);
}

Future<void> setSniBypassHosts(Map<String, String> value) async {
  final normalized = Map<String, String>.fromEntries(
    value.entries
        .map((e) => MapEntry(e.key.trim(), e.value.trim()))
        .where((e) => e.key.isNotEmpty && e.value.isNotEmpty),
  );
  await saveProperty(k: sniBypassHostsKey, v: jsonEncode(normalized));
  sniBypassHostsSignal.value = Map<String, String>.from(normalized);
}

Future<void> resetSniBypassHosts() async {
  await setSniBypassHosts(defaultSniBypassHosts);
}
