import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pansy/basic/config/download_dir.dart';
import 'package:pansy/basic/config/download_save_target.dart';
import 'package:pansy/basic/config/illust_display.dart';
import 'package:pansy/basic/config/picture_source.dart';
import 'package:signals_flutter/signals_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _customHostController =
      TextEditingController(text: pictureSourceSignal.value);

  @override
  void dispose() {
    _customHostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: ListView(
        children: [
          _sectionTitle(context, AppLocalizations.of(context)!.network),
          _imageHostCard(context, _customHostController),
          _sectionTitle(context, AppLocalizations.of(context)!.display),
          _onlyShowImagesCard(context),
          _sectionTitle(context, AppLocalizations.of(context)!.download),
          if (platformSupportsAlbum) _downloadTargetCard(context),
          _downloadDirCard(context),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _imageHostCard(
    BuildContext context,
    TextEditingController customHostController,
  ) {
    return Watch((context) {
      final selected = pictureSourceSignal.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
          child: Column(
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.imageHost),
                subtitle: Text(AppLocalizations.of(context)!.imageHostDesc),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh_outlined),
                  onPressed: () async {
                    customHostController.text = imageHost;
                    await setPictureSource(imageHost);
                  },
                ),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.imageHostDefault),
                subtitle: const Text(imageHost),
                selected: selected == imageHost,
                selectedTileColor: Theme.of(
                  context,
                ).colorScheme.secondary.withAlpha(40),
                onTap: () async {
                  customHostController.text = imageHost;
                  await setPictureSource(imageHost);
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.imageHostProxy),
                subtitle: const Text(imageProxyHost),
                selected: selected == imageProxyHost,
                selectedTileColor: Theme.of(
                  context,
                ).colorScheme.secondary.withAlpha(40),
                onTap: () async {
                  customHostController.text = imageProxyHost;
                  await setPictureSource(imageProxyHost);
                },
              ),
              ListTile(
                selected: selected != imageHost && selected != imageProxyHost,
                selectedTileColor: Theme.of(
                  context,
                ).colorScheme.secondary.withAlpha(40),
                title: TextField(
                  controller: customHostController,
                  maxLines: 1,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.customHost,
                    hintText: AppLocalizations.of(context)!.customHostHint,
                    suffixIcon: IconButton(
                      onPressed: () async {
                        final v = customHostController.text.trim();
                        if (v.isEmpty) return;
                        if (v.contains(' ')) return;
                        await setPictureSource(v);
                        if (!context.mounted) return;
                        FocusScope.of(context).unfocus();
                      },
                      icon: const Icon(Icons.check),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _downloadDirCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Watch((context) {
      final configured = downloadDirSignal.value.trim();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
          child: Column(
            children: [
              ListTile(
                title: Text(l10n.downloadDir),
                subtitle:
                    Platform.isAndroid
                        ? Text(
                          l10n.downloadDirAndroidDesc(
                            l10n.downloadsFolder,
                            configured.isEmpty ? 'Pansy' : configured,
                          ),
                        )
                        : Text(
                          configured.isEmpty
                              ? l10n.downloadDirNotSet
                              : configured,
                        ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.chooseDownloadDir,
                      icon: const Icon(Icons.folder_open),
                      onPressed: () async {
                        if (Platform.isAndroid) {
                          final current =
                              configured.isEmpty ? 'Pansy' : configured;
                          final controller = TextEditingController(
                            text: current,
                          );
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(l10n.downloadSubDir),
                                content: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    hintText: l10n.downloadSubDirHint,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: Text(l10n.cancel),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    child: Text(l10n.ok),
                                  ),
                                ],
                              );
                            },
                          );
                          if (ok != true) return;
                          await setDownloadDir(controller.text.trim());
                          return;
                        }

                        final dir = await FilePicker.platform.getDirectoryPath(
                          dialogTitle: l10n.chooseDownloadDir,
                        );
                        if (dir == null || dir.trim().isEmpty) return;
                        await setDownloadDir(dir);
                      },
                    ),
                    IconButton(
                      tooltip: l10n.reset,
                      icon: const Icon(Icons.refresh_outlined),
                      onPressed: () async => resetDownloadDir(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _onlyShowImagesCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Watch((context) {
      final enabled = illustOnlyShowImagesSignal.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
          child: SwitchListTile(
            value: enabled,
            onChanged: (v) async => setIllustOnlyShowImages(v),
            title: Text(l10n.onlyShowImages),
            subtitle: Text(l10n.onlyShowImagesDesc),
          ),
        ),
      );
    });
  }

  Widget _downloadTargetCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Watch((context) {
      final target = downloadSaveTargetSignal.value;
      final subtitle = switch (target) {
        DownloadSaveTarget.file => l10n.saveToFile,
        DownloadSaveTarget.album => l10n.saveToAlbum,
        DownloadSaveTarget.fileAndAlbum => l10n.saveToFileAndAlbum,
      };
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
          child: ListTile(
            title: Text(l10n.defaultSaveTarget),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final selected = downloadSaveTargetSignal.value;
              final action = await showModalBottomSheet<int>(
                context: context,
                showDragHandle: true,
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(l10n.saveToFile),
                          selected: selected == DownloadSaveTarget.file,
                          trailing:
                              selected == DownloadSaveTarget.file
                                  ? const Icon(Icons.check)
                                  : null,
                          onTap: () => Navigator.of(context).pop(1),
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_outlined),
                          title: Text(l10n.saveToAlbum),
                          selected: selected == DownloadSaveTarget.album,
                          trailing:
                              selected == DownloadSaveTarget.album
                                  ? const Icon(Icons.check)
                                  : null,
                          onTap: () => Navigator.of(context).pop(2),
                        ),
                        ListTile(
                          leading: const Icon(Icons.save_outlined),
                          title: Text(l10n.saveToFileAndAlbum),
                          selected: selected == DownloadSaveTarget.fileAndAlbum,
                          trailing:
                              selected == DownloadSaveTarget.fileAndAlbum
                                  ? const Icon(Icons.check)
                                  : null,
                          onTap: () => Navigator.of(context).pop(3),
                        ),
                      ],
                    ),
                  );
                },
              );
              final t = switch (action) {
                1 => DownloadSaveTarget.file,
                2 => DownloadSaveTarget.album,
                3 => DownloadSaveTarget.fileAndAlbum,
                _ => null,
              };
              if (t != null) await setDownloadSaveTarget(t);
            },
          ),
        ),
      );
    });
  }
}
