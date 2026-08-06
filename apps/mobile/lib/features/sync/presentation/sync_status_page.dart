import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_providers.dart';
import '../../../sync/conflict/conflict_policy.dart';
import '../../auth/presentation/auth_controller.dart';
import 'sync_providers.dart';

class SyncStatusPage extends ConsumerWidget {
  const SyncStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOfflineProvider);
    final pending = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final logsAsync = ref.watch(syncLogsProvider);
    final engine = ref.watch(syncEngineProvider);
    final session = ref.watch(authSessionProvider);
    final firebase = ref.watch(firebaseEnabledProvider);
    final pushToken = ref.watch(pushRegistrationProvider);
    final inbox = ref.watch(notificationInboxProvider);
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
          Text(
            firebase
                ? 'Remote: Cloud Firestore (outbox push + pull)'
                : 'Remote: local demo sink (no cloud write)',
            style: textTheme.bodySmall,
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
          Text('Push (FCM)', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          pushToken.when(
            loading: () => const Text('Registering device token…'),
            error: (e, _) => Text('Token error: $e'),
            data: (token) => Text(
              token == null
                  ? 'No token (sign in required)'
                  : (firebase
                      ? 'Token: ${token.length > 24 ? '${token.substring(0, 24)}…' : token}'
                      : 'Demo token: $token'),
              style: textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            firebase
                ? 'Foreground messages land in the inbox below; server sends via Functions.'
                : 'Demo mode logs assign/status intents locally until FlutterFire is configured.',
            style: textTheme.bodySmall,
          ),
          if (inbox.entries.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...inbox.entries.take(8).map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      e.source == 'fcm'
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_outlined,
                    ),
                    title: Text(e.title),
                    subtitle:
                        Text('${e.body}\n${e.at.toLocal()} · ${e.source}'),
                    isThreeLine: true,
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
                        final n = await ref.read(syncEngineProvider).flushNow(
                              isOnline: true,
                              projectId: session?.activeProjectId,
                            );
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
