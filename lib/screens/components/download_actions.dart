import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pansy/basic/commons.dart';
import 'package:pansy/basic/config/download_dir.dart';
import 'package:pansy/basic/config/download_save_target.dart';
import 'package:pansy/basic/config/use_download_queue.dart';
import 'package:pansy/basic/download/download_service.dart';
import 'package:pansy/src/rust/pixirust/entities.dart';

class _SaveTargetChoice {
  final DownloadSaveTarget target;
  final bool remember;

  const _SaveTargetChoice({required this.target, required this.remember});
}

Future<DownloadSaveTarget?> chooseSaveTargetWithConfirmBottomSheet(
  BuildContext context,
) async {
  if (!(Platform.isAndroid || Platform.isIOS)) {
    return DownloadSaveTarget.file;
  }

  final l10n = AppLocalizations.of(context)!;
  DownloadSaveTarget selected = downloadSaveTargetSignal.value;
  bool remember = downloadSaveTargetRememberSignal.value;

  // If user disabled remembering in settings, keep it off here too.
  if (!downloadSaveTargetRememberSignal.value) {
    remember = false;
  }

  final result = await showModalBottomSheet<_SaveTargetChoice>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.defaultSaveTarget,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(
                              _SaveTargetChoice(
                                target: selected,
                                remember: remember,
                              ),
                            );
                          },
                          child: Text(l10n.ok),
                        ),
                      ],
                    ),
                  ),
                  RadioListTile<DownloadSaveTarget>(
                    value: DownloadSaveTarget.file,
                    groupValue: selected,
                    onChanged: (v) => setState(() => selected = v!),
                    title: Text(l10n.saveToFile),
                  ),
                  RadioListTile<DownloadSaveTarget>(
                    value: DownloadSaveTarget.album,
                    groupValue: selected,
                    onChanged: (v) => setState(() => selected = v!),
                    title: Text(l10n.saveToAlbum),
                  ),
                  RadioListTile<DownloadSaveTarget>(
                    value: DownloadSaveTarget.fileAndAlbum,
                    groupValue: selected,
                    onChanged: (v) => setState(() => selected = v!),
                    title: Text(l10n.saveToFileAndAlbum),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: Text(l10n.rememberMyChoice)),
                        Switch(
                          value: remember,
                          onChanged: (v) => setState(() => remember = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );

  if (result != null) {
    if (result.remember != downloadSaveTargetRememberSignal.value) {
      await setDownloadSaveTargetRemember(result.remember);
    }
    if (result.remember) {
      await setDownloadSaveTarget(result.target);
    }
  }
  return result?.target;
}

Future<DownloadSaveTarget?> resolveSaveTargetForDownload(
  BuildContext context,
) async {
  if (!(Platform.isAndroid || Platform.isIOS)) {
    return DownloadSaveTarget.file;
  }
  if (downloadSaveTargetRememberSignal.value) {
    return downloadSaveTargetSignal.value;
  }
  return chooseSaveTargetWithConfirmBottomSheet(context);
}

Future<bool> ensureFileDownloadDirSelectedIfNeeded(
  BuildContext context,
  DownloadSaveTarget target,
) async {
  if (Platform.isAndroid) return true;
  if (Platform.isIOS) return true;
  if (target == DownloadSaveTarget.album) return true;

  final configured = downloadDirSignal.value.trim();
  final mustRepickThisSession =
      Platform.isMacOS && !downloadDirSessionConfirmedSignal.value;

  if (!mustRepickThisSession && configured.isNotEmpty) {
    try {
      await Directory(configured).create(recursive: true);
      return true;
    } catch (_) {
      // Fall through to prompt user to re-select a folder.
    }
  }

  final dir = await FilePicker.platform.getDirectoryPath();
  if (dir == null || dir.trim().isEmpty) {
    return false;
  }
  await setDownloadDir(dir);
  if (Platform.isMacOS) {
    confirmDownloadDirForSession();
  }
  return true;
}

Future<void> downloadIllustWithPrompt(
  BuildContext context, {
  required Illust illust,
  required bool allPages,
}) async {
  try {
    final target = await resolveSaveTargetForDownload(context);
    if (target == null) return;
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (!await ensureFileDownloadDirSelectedIfNeeded(context, target)) return;

    final useQueue = useDownloadQueueSignal.value;
    if (useQueue) {
      await DownloadService.downloadIllustQueued(
        illust,
        allPages: allPages,
        target: target,
      );
      if (!context.mounted) return;
      defaultToast(context, l10n.addedToDownloadQueue);
      return;
    }

    final result = await DownloadService.downloadIllust(
      illust,
      allPages: allPages,
      target: target,
    );
    if (!context.mounted) return;

    final dir =
        result.files.isEmpty
            ? null
            : (Platform.isAndroid ? null : File(result.files.first).parent.path);
    if (result.files.isEmpty && result.savedToAlbumCount == 0) {
      defaultToast(context, l10n.failed);
      return;
    }

    if (target == DownloadSaveTarget.album) {
      defaultToast(context, l10n.downloadSavedToAlbum);
      return;
    }
    if (target == DownloadSaveTarget.fileAndAlbum) {
      final androidDir = l10n.downloadDirAndroidDesc(
        l10n.downloadsFolder,
        downloadDirSignal.value.trim().isEmpty
            ? 'Pansy'
            : downloadDirSignal.value.trim(),
      );
      defaultToast(
        context,
        Platform.isAndroid
            ? l10n.downloadSavedToFileAndAlbum(androidDir)
            : l10n.downloadSavedToFileAndAlbum(dir ?? ''),
      );
      return;
    }
    defaultToast(
      context,
      Platform.isAndroid
          ? l10n.downloadSavedTo(
            l10n.downloadDirAndroidDesc(
              l10n.downloadsFolder,
              downloadDirSignal.value.trim().isNotEmpty
                  ? downloadDirSignal.value.trim()
                  : 'Pansy',
            ),
          )
          : l10n.downloadSavedTo(dir ?? ''),
    );
  } catch (e) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (e.toString() == 'download_dir_not_set') {
      defaultToast(context, l10n.downloadDirRequired);
      return;
    }
    defaultToast(context, l10n.failed + "\n$e");
  }
}
