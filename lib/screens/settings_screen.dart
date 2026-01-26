import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pansy/basic/config/download_dir.dart';
import 'package:pansy/basic/config/download_save_target.dart';
import 'package:pansy/basic/config/use_download_queue.dart';
import 'package:pansy/basic/config/illust_display.dart';
import 'package:pansy/basic/config/picture_source.dart';
import 'package:pansy/basic/config/sni_bypass.dart';
import 'package:pansy/basic/update_checker.dart';
import 'package:pansy/cross.dart';
import 'package:pansy/screens/download_list_screen.dart';
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
  void initState() {
    super.initState();
    refreshUpdateStatusInBackground();
  }

  @override
  void dispose() {
    _customHostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              title: Text(AppLocalizations.of(context)!.settings),
            ),
          ];
        },
        body: ListView(
          children: [
            _sectionTitle(context, AppLocalizations.of(context)!.display),
            _onlyShowImagesCard(context),
          _sectionTitle(context, AppLocalizations.of(context)!.download),
          _downloadListEntryCard(context),
          _useDownloadQueueCard(context),
          if (platformSupportsAlbum) _rememberSaveTargetCard(context),
          if (platformSupportsAlbum) _downloadTargetCard(context),
          if (!Platform.isIOS) _downloadDirCard(context),
          _sectionTitle(context, AppLocalizations.of(context)!.network),
          _imageHostCard(context, _customHostController),
          _sniBypassCard(context),
          _sectionTitle(context, AppLocalizations.of(context)!.cache),
          _clearImageCacheCard(context),
          _sectionTitle(context, AppLocalizations.of(context)!.app),
          _updateCard(context),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmClearCache(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.confirm),
          content: Text(l10n.confirmClearCache),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
    return ok == true;
  }

  Widget _clearImageCacheCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.image_outlined),
          title: Text(l10n.clearImageCache),
          subtitle: Text(l10n.clearImageCacheDesc),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            if (!await _confirmClearCache(context)) return;
            try {
              PaintingBinding.instance.imageCache.clear();
              PaintingBinding.instance.imageCache.clearLiveImages();

              final root = await cross.root();
              final dir = Directory('$root${Platform.pathSeparator}network_image');
              if (await dir.exists()) {
                await for (final entity in dir.list(followLinks: false)) {
                  try {
                    await entity.delete(recursive: true);
                  } catch (_) {}
                }
              }

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.cacheCleared)),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.cacheClearFailed('$e'))),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _updateCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Watch((context) {
      final status = updateStatusSignal.value;
      final subtitle = !updateCheckEnabled
          ? l10n.updateDisabled
          : (status.hasUpdate ? l10n.newVersionFound(status.latestVersion) : l10n.checkUpdateDesc);

      Widget icon = const Icon(Icons.system_update_alt_outlined);
      if (status.hasUpdate) {
        icon = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'NEW',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                  fontWeight: FontWeight.w700,
                ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
          child: Column(
            children: [
              ListTile(
                title: Text(l10n.checkUpdate),
                subtitle: Text(subtitle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status.hasUpdate) icon,
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () async {
                  if (!updateCheckEnabled) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.updateDisabled)),
                    );
                    return;
                  }
                  await manualCheckUpdate(context);
                },
              ),
              FutureBuilder<String>(
                future: getCurrentAppVersion(),
                builder: (context, snapshot) {
                  final v = snapshot.data ?? '-';
                  return ListTile(
                    title: Text(l10n.currentVersion),
                    subtitle: Text(v),
                    dense: true,
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
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

  Widget _sniBypassCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Watch((context) {
      final enabled = sniBypassSignal.value;
      final hosts = sniBypassHostsSignal.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
          child: Column(
            children: [
              SwitchListTile(
                title: Text(l10n.sniBypass),
                subtitle: Text(l10n.sniBypassDesc),
                value: enabled,
                onChanged: (value) async {
                  if (value) {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(l10n.confirm),
                          content: Text(l10n.sniBypassWarning),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(l10n.ok),
                            ),
                          ],
                        );
                      },
                    );
                    if (ok != true) return;
                  }
                  await setSniBypass(value);
                },
              ),
              ListTile(
                title: Text(l10n.sniBypassHosts),
                subtitle: Text(l10n.sniBypassHostsDesc),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.reset,
                      icon: const Icon(Icons.refresh_outlined),
                      onPressed: () async => resetSniBypassHosts(),
                    ),
                    IconButton(
                      tooltip: l10n.add,
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        final result = await _showEditSniBypassHostDialog(
                          context: context,
                          title: l10n.add,
                        );
                        if (result == null) return;
                        final next = Map<String, String>.from(hosts);
                        next[result.$1] = result.$2;
                        await setSniBypassHosts(next);
                      },
                    ),
                  ],
                ),
              ),
              if (hosts.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(l10n.empty, style: Theme.of(context).textTheme.bodySmall),
                )
              else
                ...hosts.entries.map((e) {
                  return ListTile(
                    dense: true,
                    title: Text(e.key),
                    subtitle: Text(e.value),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.edit,
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () async {
                            final result = await _showEditSniBypassHostDialog(
                              context: context,
                              title: l10n.edit,
                              initialDomain: e.key,
                              initialIp: e.value,
                            );
                            if (result == null) return;
                            final next = Map<String, String>.from(hosts);
                            if (result.$1 != e.key) {
                              next.remove(e.key);
                            }
                            next[result.$1] = result.$2;
                            await setSniBypassHosts(next);
                          },
                        ),
                        IconButton(
                          tooltip: l10n.delete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text(l10n.confirm),
                                  content: Text(l10n.deleteConfirm),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text(l10n.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: Text(l10n.ok),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (ok != true) return;
                            final next = Map<String, String>.from(hosts);
                            next.remove(e.key);
                            await setSniBypassHosts(next);
                          },
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      );
    });
  }

  Future<(String, String)?> _showEditSniBypassHostDialog({
    required BuildContext context,
    required String title,
    String? initialDomain,
    String? initialIp,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final domainController = TextEditingController(text: initialDomain ?? '');
    final ipController = TextEditingController(text: initialIp ?? '');
    final result = await showDialog<(String, String)?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: domainController,
                decoration: InputDecoration(labelText: l10n.domain),
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ipController,
                decoration: InputDecoration(labelText: l10n.ip),
                maxLines: 1,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                final domain = domainController.text.trim();
                final ip = ipController.text.trim();
                if (domain.isEmpty || ip.isEmpty) return;
                if (domain.contains(' ') || ip.contains(' ')) return;
                Navigator.of(context).pop((domain, ip));
              },
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
    domainController.dispose();
    ipController.dispose();
    return result;
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

  Widget _rememberSaveTargetCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Watch((context) {
      final enabled = downloadSaveTargetRememberSignal.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
          child: SwitchListTile(
            value: enabled,
            onChanged: (v) => setDownloadSaveTargetRemember(v),
            title: Text(l10n.rememberMyChoice),
            subtitle: Text(l10n.rememberMyChoiceDesc),
          ),
        ),
      );
    });
  }

  Widget _downloadListEntryCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.download_outlined),
          title: Text(l10n.downloads),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DownloadListScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _useDownloadQueueCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Watch((context) {
      final enabled = useDownloadQueueSignal.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
          child: SwitchListTile(
            value: enabled,
            onChanged: (v) async => setUseDownloadQueue(v),
            title: Text(l10n.useDownloadQueue),
            subtitle: Text(l10n.useDownloadQueueDesc),
          ),
        ),
      );
    });
  }
}
