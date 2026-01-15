import 'dart:convert';

import 'package:pansy/src/rust/api/api.dart';
import 'package:signals_flutter/signals_flutter.dart';

const _tagHistoryKey = 'tag_history_v1';
const _maxHistory = 30;

class TagHistoryItem {
  final String tag;
  final bool pinned;
  final int lastUsedMs;

  const TagHistoryItem({
    required this.tag,
    required this.pinned,
    required this.lastUsedMs,
  });

  TagHistoryItem copyWith({bool? pinned, int? lastUsedMs}) => TagHistoryItem(
        tag: tag,
        pinned: pinned ?? this.pinned,
        lastUsedMs: lastUsedMs ?? this.lastUsedMs,
      );

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'pinned': pinned,
        'lastUsedMs': lastUsedMs,
      };

  static TagHistoryItem? fromJson(dynamic v) {
    if (v is! Map) return null;
    final tag = v['tag'];
    final pinned = v['pinned'];
    final lastUsedMs = v['lastUsedMs'];
    if (tag is! String || tag.trim().isEmpty) return null;
    return TagHistoryItem(
      tag: tag.trim(),
      pinned: pinned is bool ? pinned : false,
      lastUsedMs: lastUsedMs is int ? lastUsedMs : 0,
    );
  }
}

final tagHistorySignal = signal<List<TagHistoryItem>>([]);

List<TagHistoryItem> get pinnedTags => tagHistorySignal.value
    .where((e) => e.pinned)
    .toList()
  ..sort((a, b) => b.lastUsedMs.compareTo(a.lastUsedMs));

List<TagHistoryItem> get recentTags => tagHistorySignal.value
    .where((e) => !e.pinned)
    .toList()
  ..sort((a, b) => b.lastUsedMs.compareTo(a.lastUsedMs));

Future<void> initTagHistory() async {
  final raw = await loadProperty(k: _tagHistoryKey);
  if (raw.trim().isEmpty) {
    tagHistorySignal.value = [];
    return;
  }
  try {
    final parsed = jsonDecode(raw);
    if (parsed is! List) {
      tagHistorySignal.value = [];
      return;
    }
    final items = parsed
        .map(TagHistoryItem.fromJson)
        .whereType<TagHistoryItem>()
        .toList();
    tagHistorySignal.value = _normalize(items);
  } catch (_) {
    tagHistorySignal.value = [];
  }
}

Future<void> clearTagHistory() async {
  tagHistorySignal.value = [];
  await saveProperty(k: _tagHistoryKey, v: jsonEncode([]));
}

Future<void> togglePinTag(String tag) async {
  final t = tag.trim();
  if (t.isEmpty) return;
  final now = DateTime.now().millisecondsSinceEpoch;
  final current = tagHistorySignal.value;
  final idx = current.indexWhere((e) => e.tag == t);
  if (idx < 0) {
    await recordTag(t, pinned: true);
    return;
  }
  final updated = [...current];
  updated[idx] = updated[idx].copyWith(pinned: !updated[idx].pinned, lastUsedMs: now);
  await _saveList(updated);
}

Future<void> recordTag(String tag, {bool? pinned}) async {
  final t = tag.trim();
  if (t.isEmpty) return;
  final now = DateTime.now().millisecondsSinceEpoch;
  final current = tagHistorySignal.value;
  final idx = current.indexWhere((e) => e.tag == t);
  final updated = [...current];
  if (idx >= 0) {
    updated[idx] = updated[idx].copyWith(
      pinned: pinned ?? updated[idx].pinned,
      lastUsedMs: now,
    );
  } else {
    updated.add(TagHistoryItem(tag: t, pinned: pinned ?? false, lastUsedMs: now));
  }
  await _saveList(updated);
}

Future<void> _saveList(List<TagHistoryItem> items) async {
  final normalized = _normalize(items);
  tagHistorySignal.value = normalized;
  await saveProperty(
    k: _tagHistoryKey,
    v: jsonEncode(normalized.map((e) => e.toJson()).toList()),
  );
}

List<TagHistoryItem> _normalize(List<TagHistoryItem> items) {
  final byTag = <String, TagHistoryItem>{};
  for (final item in items) {
    final t = item.tag.trim();
    if (t.isEmpty) continue;
    final prev = byTag[t];
    if (prev == null) {
      byTag[t] = item.copyWith();
    } else {
      byTag[t] = TagHistoryItem(
        tag: t,
        pinned: prev.pinned || item.pinned,
        lastUsedMs: prev.lastUsedMs > item.lastUsedMs ? prev.lastUsedMs : item.lastUsedMs,
      );
    }
  }
  final list = byTag.values.toList();
  list.sort((a, b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    return b.lastUsedMs.compareTo(a.lastUsedMs);
  });
  if (list.length > _maxHistory) {
    return list.sublist(0, _maxHistory);
  }
  return list;
}

