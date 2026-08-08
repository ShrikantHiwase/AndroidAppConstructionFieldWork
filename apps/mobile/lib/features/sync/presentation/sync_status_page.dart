import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/device/evidence_image_policy.dart';
import '../../../core/health/health_check_port.dart';
import '../../../core/notifications/notification_deep_link.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/telemetry/telemetry_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../sync/conflict/conflict_policy.dart';
import '../../auth/presentation/auth_controller.dart';
import 'sync_providers.dart';

class SyncStatusPage extends ConsumerWidget {
  const SyncStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
      appBar: AppBar(title: Text(l10n.syncStatusTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            offline ? l10n.offlineBadge : l10n.onlineBadge,
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            pending == 0
                ? l10n.outboxEmpty
                : l10n.outboxPendingCount(pending),
            style: textTheme.bodyLarge,
          ),
          Text(
            firebase ? l10n.remoteFirestore : l10n.remoteDemo,
            style: textTheme.bodySmall,
          ),
          Text(
            l10n.demoCloudToggleLine(
              offline ? l10n.stateOffline : l10n.stateOnline,
              deviceOffline ? l10n.stateOffline : l10n.stateOnline,
            ),
            style: textTheme.bodySmall,
          ),
          if (engine.lastSuccessAt != null) ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.lastSuccessPrefix} ${engine.lastSuccessAt!.toLocal()}',
              style: textTheme.bodySmall,
            ),
          ],
          if (engine.lastFailure != null) ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.lastFailurePrefix} ${engine.lastFailure}',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.localCache, style: textTheme.titleMedium),
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
            l10n.softBudgetLine(
              EvidenceImagePolicy.formatBytes(cache.estimatedBytes),
              EvidenceImagePolicy.formatBytes(cache.capBytes),
              overBudget ? l10n.softBudgetOverSuffix : '',
            ),
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
              l10n.cleanupCanReclaim(
                EvidenceImagePolicy.formatBytes(cache.reclaimableBytes),
              ),
              style: textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.backgroundSync, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            bgMeta.lastAt == null
                ? l10n.lastBackgroundFlushNever
                : l10n.lastBackgroundFlushAt(
                    bgMeta.lastAt!.toLocal().toString(),
                    bgMeta.lastFlushed,
                  ),
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
                      ok ? l10n.oneOffFlushEnqueued : l10n.oneOffFlushFailed,
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.schedule_send_outlined),
            label: Text(l10n.enqueueBackgroundFlush),
          ),
          const SizedBox(height: 16),
          Text(l10n.backendHealth, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            lastHealth?.summary ??
                (firebase
                    ? l10n.healthNotProbedFirebase
                    : l10n.healthDemoNoop),
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
            label: Text(l10n.probeHealth),
          ),
          const SizedBox(height: 16),
          Text(l10n.telemetry, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.telemetryBackendLine(
              telemetry.backendLabel,
              telemetry.userId == null
                  ? ''
                  : l10n.telemetryUserPart(telemetry.userId!),
            ),
            style: textTheme.bodySmall,
          ),
          Text(
            l10n.secureStoreLine(secure.backendLabel),
            style: textTheme.bodySmall,
          ),
          Text(
            firebase
                ? l10n.telemetryFirebaseDeferred
                : l10n.telemetryDemoNoop,
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
          Text(l10n.pushFcm, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          pushToken.when(
            loading: () => Text(l10n.registeringToken),
            error: (e, _) => Text(l10n.tokenError('$e')),
            data: (token) => Text(
              token == null
                  ? l10n.noTokenSignIn
                  : (firebase
                      ? l10n.tokenLine(
                          token.length > 24
                              ? '${token.substring(0, 24)}…'
                              : token,
                        )
                      : l10n.demoTokenLine(token)),
              style: textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            firebase ? l10n.pushHelpFirebase : l10n.pushHelpDemo,
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
                          SnackBar(content: Text(l10n.noLinkedScreen)),
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
                            SnackBar(content: Text(l10n.flushedItems(n))),
                          );
                        }
                      },
                icon: const Icon(Icons.sync),
                label: Text(l10n.flushNow),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(isOfflineProvider.notifier).toggle(),
                icon: Icon(offline ? Icons.cloud_done_outlined : Icons.cloud_off),
                label: Text(offline ? l10n.goOnline : l10n.goOffline),
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
                        ? l10n.cleanupMediaNote(result.reclaimedMediaPaths)
                        : '';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.cleanupRemovedLogs(
                            result.removedLogEntries,
                            mediaNote,
                            freed,
                          ),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.cleaning_services_outlined),
                label: Text(l10n.cleanup),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.conflictPolicy, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          ...ConflictStrategy.values.map(
            (s) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.rule_folder_outlined),
              title: Text(ConflictPolicy.describe(s, l10n)),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.syncLog, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          logsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (logs) {
              if (logs.isEmpty) {
                return Text(l10n.noSyncEventsYet);
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
            l10n.syncFooterNote,
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
