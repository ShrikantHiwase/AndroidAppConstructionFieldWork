import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sync/conflict/conflict_policy.dart';
import 'sync_providers.dart';

class SyncStatusPage extends ConsumerWidget {
  const SyncStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOfflineProvider);
    final pending = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final logsAsync = ref.watch(syncLogsProvider);
    final engine = ref.watch(syncEngineProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sync status')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(offline ? 'Offline' : 'Online', style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            pending == 0
                ? 'Outbox empty'
                : '$pending item(s) waiting to sync',
            style: textTheme.bodyLarge,
          ),
          if (engine.lastSuccessAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last success: ${engine.lastSuccessAt!.toLocal()}',
              style: textTheme.bodySmall,
            ),
          ],
          if (engine.lastFailure != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last failure: ${engine.lastFailure}',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: offline
                    ? null
                    : () async {
                        final n = await ref
                            .read(syncEngineProvider)
                            .flushNow(isOnline: true);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Flushed $n item(s)')),
                          );
                        }
                      },
                icon: const Icon(Icons.sync),
                label: const Text('Flush now'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(isOfflineProvider.notifier).toggle(),
                icon: Icon(offline ? Icons.cloud_done_outlined : Icons.cloud_off),
                label: Text(offline ? 'Go online' : 'Go offline'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await ref
                      .read(syncEngineProvider)
                      .runStorageCleanup();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Removed ${result.removedLogEntries} log(s)',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.cleaning_services_outlined),
                label: const Text('Cleanup'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Conflict policy', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          ...ConflictStrategy.values.map(
            (s) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.rule_folder_outlined),
              title: Text(ConflictPolicy.describe(s)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Sync log', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          logsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (logs) {
              if (logs.isEmpty) {
                return const Text('No sync events yet.');
              }
              final visible = logs.take(40).toList();
              return Column(
                children: [
                  for (final e in visible)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(_iconFor(e.level)),
                      title: Text(e.message),
                      subtitle: Text(e.at.toLocal().toString()),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Workmanager / Drift background sync wires after Firebase configure. '
            'Soft local cache budget: '
            '${SyncCleanupPolicy.softLocalBytesCap ~/ (1024 * 1024)}MB.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  IconData _iconFor(SyncLogLevel level) => switch (level) {
        SyncLogLevel.info => Icons.info_outline,
        SyncLogLevel.warn => Icons.warning_amber_outlined,
        SyncLogLevel.error => Icons.error_outline,
      };
}
