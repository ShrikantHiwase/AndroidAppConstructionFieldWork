import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/device/evidence_image_policy.dart';
import '../../../core/health/health_check_port.dart';
import '../../../core/notifications/notification_deep_link.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/telemetry/telemetry_providers.dart';
import '../../../sync/conflict/conflict_policy.dart';
import '../../auth/presentation/auth_controller.dart';
import 'sync_providers.dart';

class SyncStatusPage extends ConsumerWidget {
  const SyncStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOfflineProvider);
    final deviceOffline = ref.watch(deviceOfflineProvider);
    final pending = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final logsAsync = ref.watch(syncLogsProvider);
    final engine = ref.watch(syncEngineProvider);
    final session = ref.watch(authSessionProvider);
    final firebase = ref.watch(firebaseEnabledProvider);
    final pushToken = ref.watch(pushRegistrationProvider);
    final inbox = ref.watch(notificationInboxProvider);
    final bgMeta = ref.watch(backgroundSyncMetaProvider);
    final lastHealth = ref.watch(lastHealthCheckProvider);
    final cache = ref.watch(localCacheSnapshotProvider);
    ref.watch(telemetryRevisionProvider);
    final telemetry = ref.watch(telemetryPortProvider);
    final secure = ref.watch(secureStoreProvider);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final overBudget = cache.estimatedBytes > cache.capBytes;

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
          Text(
            'Demo cloud toggle: ${offline ? 'offline' : 'online'} · '
            'Device network: ${deviceOffline ? 'offline' : 'online'}',
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
                color: scheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Local cache', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cache.usageRatio.clamp(0.0, 1.0),
              minHeight: 8,
              color: overBudget ? scheme.error : null,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${EvidenceImagePolicy.formatBytes(cache.estimatedBytes)} / '
            '${EvidenceImagePolicy.formatBytes(cache.capBytes)} soft budget'
            '${overBudget ? ' (over)' : ''}',
            style: textTheme.bodySmall?.copyWith(
              color: overBudget ? scheme.error : null,
            ),
          ),
          if (cache.breakdownLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(cache.breakdownLabel, style: textTheme.bodySmall),
          ],
          if (cache.reclaimableBytes > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Cleanup can reclaim '
              '${EvidenceImagePolicy.formatBytes(cache.reclaimableBytes)} '
              '(uploaded local stubs)',
              style: textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          Text('Background sync', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            bgMeta.lastAt == null
                ? 'Last background flush: never'
                : 'Last background flush: ${bgMeta.lastAt!.toLocal()} '
                    '(${bgMeta.lastFlushed} item(s))',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await ref
                  .read(backgroundSyncSchedulerProvider)
                  .enqueueOneOffFlush();
              ref.invalidate(backgroundSyncMetaProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'One-off background flush enqueued'
                          : 'Could not enqueue (Workmanager unavailable here)',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.schedule_send_outlined),
            label: const Text('Enqueue background flush'),
          ),
          const SizedBox(height: 16),
          Text('Backend health', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            lastHealth?.summary ??
                (firebase
                    ? 'Not probed yet — call Cloud Functions health.'
                    : 'Demo mode uses a local NoOp health probe.'),
            style: textTheme.bodySmall?.copyWith(
              color: lastHealth == null
                  ? null
                  : (lastHealth.ok ? null : scheme.error),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () async {
              final result = await ref.read(healthCheckPortProvider).ping();
              ref.read(lastHealthCheckProvider.notifier).state = result;
              await logTelemetryEvent(
                ref,
                name: 'health_probe',
                params: {
                  'ok': result.ok,
                  'source': result.source,
                },
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.summary)),
                );
              }
            },
            icon: const Icon(Icons.monitor_heart_outlined),
            label: const Text('Probe health'),
          ),
          const SizedBox(height: 16),
          Text('Telemetry', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Backend: ${telemetry.backendLabel}'
            '${telemetry.userId == null ? '' : ' · user ${telemetry.userId}'}',
            style: textTheme.bodySmall,
          ),
          Text(
            'Secure store: ${secure.backendLabel} '
            '(session email, biometrics flag, FCM token)',
            style: textTheme.bodySmall,
          ),
          Text(
            firebase
                ? 'Crashlytics/Analytics packages still deferred — '
                    'events stay local until FlutterFire go-live.'
                : 'Demo NoOp recorder — no network. Events listed below.',
            style: textTheme.bodySmall,
          ),
          if (telemetry.recentEvents.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...telemetry.recentEvents.take(6).map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      e.kind == 'error'
                          ? Icons.bug_report_outlined
                          : (e.kind == 'user'
                              ? Icons.person_outline
                              : Icons.analytics_outlined),
                    ),
                    title: Text(e.summary),
                    subtitle: Text('${e.at.toLocal()} · ${e.kind}'),
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
                ? 'Tap an inbox row to open the related DPR / issue / RFI. '
                    'Functions send on DPR submit / issue & RFI assign & status.'
                : 'Demo mode logs assign/status intents locally until FlutterFire is configured. '
                    'Tap inbox rows to open linked screens.',
            style: textTheme.bodySmall,
          ),
          if (inbox.entries.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...inbox.entries.take(8).map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      e.source.startsWith('fcm')
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_outlined,
                    ),
                    title: Text(e.title),
                    subtitle:
                        Text('${e.body}\n${e.at.toLocal()} · ${e.source}'),
                    isThreeLine: true,
                    onTap: () {
                      final opened = openNotificationDeepLink(data: e.data);
                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No linked screen for this alert'),
                          ),
                        );
                      }
                    },
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
                        ref.invalidate(backgroundSyncMetaProvider);
                        await logTelemetryEvent(
                          ref,
                          name: 'sync_flush',
                          params: {
                            'flushed': n,
                            'source': 'manual',
                          },
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
                  ref.invalidate(localCacheSnapshotProvider);
                  await logTelemetryEvent(
                    ref,
                    name: 'sync_cleanup',
                    params: {
                      'logs_removed': result.removedLogEntries,
                      'media_reclaimed': result.reclaimedMediaPaths,
                      'bytes_freed': result.bytesFreedEstimate,
                    },
                  );
                  if (context.mounted) {
                    final freed = EvidenceImagePolicy.formatBytes(
                      result.bytesFreedEstimate,
                    );
                    final mediaNote = result.reclaimedMediaPaths > 0
                        ? ', reclaimed ${result.reclaimedMediaPaths} media '
                            'path(s)'
                        : '';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Removed ${result.removedLogEntries} log(s)$mediaNote '
                          '(~$freed)',
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
            'Periodic Workmanager flush (~15 min, network required) + '
            'connectivity_plus auto-flush when the device reconnects. '
            'Cleanup clears sync logs and uploaded local:// media stubs. '
            'Drift still deferred.',
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
