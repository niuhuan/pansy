import 'package:flutter/material.dart';
import 'package:pansy/basic/download/download_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pansy/src/rust/udto.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:intl/intl.dart';

class DownloadListScreen extends StatefulWidget {
  const DownloadListScreen({super.key});

  @override
  State<DownloadListScreen> createState() => _DownloadListScreenState();
}

class _DownloadListScreenState extends State<DownloadListScreen> {
  @override
  void initState() {
    super.initState();
    downloadManager.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.downloads),
        actions: [
          Watch((context) {
            final stats = downloadManager.getStatistics();
            final hasCompleted = (stats['completed'] ?? 0) > 0;
            return IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: AppLocalizations.of(context)!.clearCompleted,
              onPressed:
                  hasCompleted
                      ? () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              AppLocalizations.of(context)!.clearCompleted,
                            ),
                            content: Text(
                              AppLocalizations.of(context)!
                                  .clearCompletedConfirm,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  AppLocalizations.of(context)!.cancel,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  AppLocalizations.of(context)!.confirm,
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await downloadManager.clearCompleted();
                        }
                      }
                      : null,
            );
          }),
          Watch((context) {
            final isProcessing = downloadManager.isProcessingSignal.value;
            return IconButton(
              icon: Icon(isProcessing ? Icons.pause : Icons.play_arrow),
              tooltip:
                  isProcessing
                      ? AppLocalizations.of(context)!.pause
                      : AppLocalizations.of(context)!.resume,
              onPressed: () {
                if (!isProcessing) {
                  downloadManager.processQueue();
                }
              },
            );
          }),
        ],
      ),
      body: Column(
        children: [
          _buildStatisticsCard(),
          const Divider(height: 1),
          Expanded(
            child: Watch((context) {
              final tasks = downloadManager.tasksSignal.value;
              if (tasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noDownloads,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return _buildTaskItem(task);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Watch((context) {
      final stats = downloadManager.getStatistics();
      return Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                AppLocalizations.of(context)!.total,
                stats['total'] ?? 0,
                Colors.blue,
              ),
              _buildStatItem(
                context,
                AppLocalizations.of(context)!.pending,
                stats['pending'] ?? 0,
                Colors.orange,
              ),
              _buildStatItem(
                context,
                AppLocalizations.of(context)!.downloading,
                stats['downloading'] ?? 0,
                Colors.green,
              ),
              _buildStatItem(
                context,
                AppLocalizations.of(context)!.completed,
                stats['completed'] ?? 0,
                Colors.grey,
              ),
              _buildStatItem(
                context,
                AppLocalizations.of(context)!.failed,
                stats['failed'] ?? 0,
                Colors.red,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTaskItem(DownloadTaskDto task) {
    final status = DownloadTaskStatus.fromString(task.status);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final createdTime =
        DateTime.fromMillisecondsSinceEpoch(task.createdTime);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildStatusIcon(status),
        title: Text(
          task.illustTitle.isEmpty
              ? 'Illust ${task.illustId}'
              : task.illustTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${task.illustId} - Page ${task.pageIndex + 1}/${task.pageCount}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (status == DownloadTaskStatus.downloading)
              LinearProgressIndicator(value: task.progress / 100)
            else if (status == DownloadTaskStatus.failed)
              Text(
                task.errorMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                ),
              )
            else
              Text(
                dateFormat.format(createdTime),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: _buildTaskActions(task, status),
      ),
    );
  }

  Widget _buildStatusIcon(DownloadTaskStatus status) {
    return switch (status) {
      DownloadTaskStatus.pending => const CircleAvatar(
        backgroundColor: Colors.orange,
        child: Icon(Icons.schedule, color: Colors.white, size: 20),
      ),
      DownloadTaskStatus.downloading => const CircleAvatar(
        backgroundColor: Colors.green,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
      DownloadTaskStatus.completed => const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.check, color: Colors.white, size: 20),
      ),
      DownloadTaskStatus.failed => const CircleAvatar(
        backgroundColor: Colors.red,
        child: Icon(Icons.error, color: Colors.white, size: 20),
      ),
    };
  }

  Widget _buildTaskActions(DownloadTaskDto task, DownloadTaskStatus status) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == DownloadTaskStatus.failed)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppLocalizations.of(context)!.retry,
            onPressed: () async {
              try {
                await downloadManager.retryTask(task.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.retrying),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to retry: $e')),
                );
              }
            },
          ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: AppLocalizations.of(context)!.delete,
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.deleteTask),
                content: Text(
                  AppLocalizations.of(context)!.deleteTaskConfirm,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(AppLocalizations.of(context)!.delete),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              try {
                await downloadManager.deleteTask(task.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.deleted),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete: $e')),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
