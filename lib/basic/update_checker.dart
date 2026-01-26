import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pansy/cross.dart';
import 'package:pansy/src/rust/api/api.dart';
import 'package:signals_flutter/signals_flutter.dart';

const _lastUpdateCheckKey = 'last_update_check_ms';
const _nextUpdatePromptMsKey = 'next_update_prompt_ms';
const _ignoredLatestVersionKey = 'ignored_latest_version';

final updateStatusSignal = signal<UpdateStatus>(const UpdateStatus.unknown());

const String updateOwner = String.fromEnvironment('UPDATE_OWNER', defaultValue: '');
const String updateRepo = String.fromEnvironment('UPDATE_REPO', defaultValue: 'pansy');

bool get updateCheckEnabled => updateOwner.trim().isNotEmpty && updateRepo.trim().isNotEmpty;

Future<String> getCurrentAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
}

Future<void> maybeAutoCheckUpdate(BuildContext context) async {
  if (!updateCheckEnabled) return;
  try {
    final lastRaw = (await loadProperty(k: _lastUpdateCheckKey)).trim();
    final lastMs = int.tryParse(lastRaw) ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const intervalMs = 12 * 60 * 60 * 1000;
    if (nowMs - lastMs < intervalMs) return;
    await saveProperty(k: _lastUpdateCheckKey, v: nowMs.toString());

    // Respect user's postpone choice.
    final nextPromptRaw = (await loadProperty(k: _nextUpdatePromptMsKey)).trim();
    final nextPromptMs = int.tryParse(nextPromptRaw) ?? 0;
    if (nowMs < nextPromptMs) return;

    // Silent check (no loading dialog). Only show popup if update is available.
    final status = await _check(context, showLoading: false, showErrors: false);
    if (status == null) return;
    if (!status.hasUpdate) return;

    // Ignore user-suppressed version.
    final ignored = (await loadProperty(k: _ignoredLatestVersionKey)).trim();
    if (ignored.isNotEmpty && ignored == status.latestVersion) return;

    if (!context.mounted) return;
    await _showUpdateAvailableDialog(context, status, manual: false);
  } catch (_) {
    // Ignore auto-check failures.
  }
}

Future<void> manualCheckUpdate(BuildContext context) async {
  if (!context.mounted) return;
  final status = await _check(context, showLoading: true, showErrors: true);
  if (status == null) return;

  final l10n = AppLocalizations.of(context)!;
  if (!status.hasUpdate) {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.alreadyLatest),
          content: Text(
            '${l10n.currentVersion}: ${status.currentVersion}\n'
            '${l10n.latestVersion}: ${status.latestVersion}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
    return;
  }

  await _showUpdateAvailableDialog(context, status, manual: true);
}

Future<UpdateStatus?> _check(
  BuildContext context, {
  required bool showLoading,
  required bool showErrors,
}) async {
  final l10n = AppLocalizations.of(context)!;

  if (showLoading) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.checkingUpdate)),
            ],
          ),
        );
      },
    );
  }

  UpdateCheckResult? result;
  Object? error;
  try {
    result = await checkForUpdate();
  } catch (e) {
    error = e;
  }

  if (showLoading && context.mounted) Navigator.of(context).pop();
  if (!context.mounted) return null;

  if (error != null || result == null) {
    if (!showErrors) return null;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.updateCheckFailed),
          content: Text(error?.toString() ?? '-'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
    return null;
  }

  final status = UpdateStatus.fromResult(result);
  updateStatusSignal.value = status;
  return status;
}

Future<void> _showUpdateAvailableDialog(
  BuildContext context,
  UpdateStatus status, {
  required bool manual,
}) async {
  final l10n = AppLocalizations.of(context)!;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.updateAvailable),
        content: SingleChildScrollView(
          child: Text(
            '${l10n.currentVersion}: ${status.currentVersion}\n'
            '${l10n.latestVersion}: ${status.latestVersion}\n\n'
            '${status.releaseNotes ?? ''}',
          ),
        ),
        actions: [
          if (!manual) ...[
            TextButton(
              onPressed: () async {
                final now = DateTime.now().millisecondsSinceEpoch;
                const oneDayMs = 24 * 60 * 60 * 1000;
                await saveProperty(
                  k: _nextUpdatePromptMsKey,
                  v: (now + oneDayMs).toString(),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.remindInOneDay),
            ),
            TextButton(
              onPressed: () async {
                final now = DateTime.now().millisecondsSinceEpoch;
                const oneWeekMs = 7 * 24 * 60 * 60 * 1000;
                await saveProperty(
                  k: _nextUpdatePromptMsKey,
                  v: (now + oneWeekMs).toString(),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.remindInOneWeek),
            ),
            TextButton(
              onPressed: () async {
                await saveProperty(k: _ignoredLatestVersionKey, v: status.latestVersion);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.ignoreThisVersion),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final url = status.releaseUrl;
              if (url != null && url.isNotEmpty) {
                await openUrl(url);
              }
            },
            child: Text(l10n.openReleasePage),
          ),
        ],
      );
    },
  );
}

Future<void> refreshUpdateStatusInBackground() async {
  if (!updateCheckEnabled) return;
  try {
    final result = await checkForUpdate();
    updateStatusSignal.value = UpdateStatus.fromResult(result);
  } catch (_) {
    // ignore
  }
}

Future<UpdateCheckResult> checkForUpdate({Duration timeout = const Duration(seconds: 8)}) async {
  final currentVersion = await getCurrentAppVersion();
  final response = await _fetchLatestRelease(timeout: timeout);
  final latestTag = (response['tag_name'] as String?)?.trim() ?? '';
  final latestVersion = _tagToVersion(latestTag);
  final releaseUrl = (response['html_url'] as String?)?.trim();
  final notes = (response['body'] as String?)?.trim();

  final hasUpdate = _compareSemver(_tagToVersion(currentVersion), latestVersion) < 0;
  return UpdateCheckResult(
    currentVersion: currentVersion,
    latestVersion: latestVersion.isEmpty ? latestTag : latestVersion,
    releaseUrl: releaseUrl,
    releaseNotes: notes,
    hasUpdate: hasUpdate,
  );
}

Future<Map<String, dynamic>> _fetchLatestRelease({required Duration timeout}) async {
  final owner = updateOwner.trim();
  final repo = updateRepo.trim();
  if (owner.isEmpty || repo.isEmpty) {
    throw StateError('UPDATE_OWNER/UPDATE_REPO not set');
  }

  final uri = Uri.https('api.github.com', '/repos/$owner/$repo/releases/latest');
  final client = HttpClient();
  client.connectionTimeout = timeout;
  try {
    final request = await client.getUrl(uri).timeout(timeout);
    request.headers.set(HttpHeaders.userAgentHeader, 'pansy');
    request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    final response = await request.close().timeout(timeout);
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw HttpException('GitHub API ${response.statusCode}: $body');
    }
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid response');
    }
    return json;
  } finally {
    client.close(force: true);
  }
}

String _tagToVersion(String v) {
  var s = v.trim();
  if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
  // drop build / prerelease
  s = s.split('+').first;
  s = s.split('-').first;
  return s.trim();
}

int _compareSemver(String a, String b) {
  final ap = _parseSemverParts(a);
  final bp = _parseSemverParts(b);
  final maxLen = ap.length > bp.length ? ap.length : bp.length;
  for (var i = 0; i < maxLen; i++) {
    final ai = i < ap.length ? ap[i] : 0;
    final bi = i < bp.length ? bp[i] : 0;
    if (ai != bi) return ai.compareTo(bi);
  }
  return 0;
}

List<int> _parseSemverParts(String v) {
  final s = _tagToVersion(v);
  if (s.isEmpty) return const [0, 0, 0];
  return s.split('.').map((part) {
    final m = RegExp(r'^\d+').firstMatch(part.trim());
    return int.tryParse(m?.group(0) ?? '') ?? 0;
  }).toList(growable: false);
}

class UpdateCheckResult {
  final String currentVersion;
  final String latestVersion;
  final String? releaseUrl;
  final String? releaseNotes;
  final bool hasUpdate;

  const UpdateCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.releaseNotes,
    required this.hasUpdate,
  });
}

class UpdateStatus {
  final String currentVersion;
  final String latestVersion;
  final String? releaseUrl;
  final String? releaseNotes;
  final bool hasUpdate;

  const UpdateStatus({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.releaseNotes,
    required this.hasUpdate,
  });

  const UpdateStatus.unknown()
      : currentVersion = '-',
        latestVersion = '-',
        releaseUrl = null,
        releaseNotes = null,
        hasUpdate = false;

  factory UpdateStatus.fromResult(UpdateCheckResult r) {
    return UpdateStatus(
      currentVersion: r.currentVersion,
      latestVersion: r.latestVersion,
      releaseUrl: r.releaseUrl,
      releaseNotes: r.releaseNotes,
      hasUpdate: r.hasUpdate,
    );
  }
}
