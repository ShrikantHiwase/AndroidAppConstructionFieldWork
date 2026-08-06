import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../device/local_media_cache.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/documents/data/local_documents_repository.dart';
import '../../features/documents/presentation/documents_providers.dart';
import '../../features/dpr/data/local_dpr_repository.dart';
import '../../features/dpr/presentation/dpr_providers.dart';
import '../../features/issues/presentation/field_records_providers.dart';
import '../../features/site_ops/data/local_site_ops_repository.dart';
import '../../features/site_ops/presentation/site_ops_providers.dart';
import '../../features/voice_notes/data/local_voice_notes_repository.dart';
import '../../features/voice_notes/presentation/voice_notes_providers.dart';
import '../../sync/background/background_outbox_flush.dart';
import '../../sync/background/background_sync_scheduler.dart';
import '../../sync/local_sync_engine.dart';
import '../../sync/remote/syncable_store.dart';
import '../../sync/sync_models.dart';

final syncEngineProvider = Provider<LocalSyncEngine>((ref) {
  final fieldRecords = ref.watch(fieldRecordsRepositoryProvider);
  final siteOps = ref.watch(siteOpsRepositoryProvider) as LocalSiteOpsRepository;
  final stores = <SyncableStore>[
    ref.watch(dprRepositoryProvider) as LocalDprRepository,
    ref.watch(drawingPinsRepositoryProvider) as LocalDrawingPinsRepository,
    siteOps,
    ref.watch(documentsRepositoryProvider) as LocalDocumentsRepository,
    ref.watch(voiceNotesRepositoryProvider) as LocalVoiceNotesRepository,
  ];
  return LocalSyncEngine(
    prefs: ref.watch(sharedPreferencesProvider),
    fieldRecords: fieldRecords,
    moduleStores: stores,
    mediaCaches: [
      if (fieldRecords is LocalMediaCache) fieldRecords as LocalMediaCache,
      siteOps,
    ],
  );
});

/// Soft local-cache estimate for Sync status (stubs; not on-disk usage).
final localCacheSnapshotProvider = Provider<LocalCacheSnapshot>((ref) {
  return ref.watch(syncEngineProvider).estimateLocalCache();
});

final syncLogsProvider = StreamProvider<List<SyncLogEntry>>((ref) {
  return ref.watch(syncEngineProvider).watchLogs();
});

final pendingSyncCountProvider = StreamProvider<int>((ref) {
  return ref.watch(syncEngineProvider).watchPendingTotal();
});

final backgroundSyncSchedulerProvider = Provider<BackgroundSyncScheduler>((ref) {
  return const BackgroundSyncScheduler();
});

/// Last Workmanager / headless flush metadata from SharedPreferences.
final backgroundSyncMetaProvider = Provider<BackgroundSyncMeta>((ref) {
  return BackgroundSyncMeta.fromPrefs(ref.watch(sharedPreferencesProvider));
});

/// True when the OS reports no usable network (independent of demo override).
final deviceOfflineProvider = StateProvider<bool>((ref) => false);

/// Demo connectivity override; flipping to online triggers an outbox flush.
/// Also listens to [Connectivity] so real reconnects flush when demo is online.
final isOfflineProvider =
    StateNotifierProvider<ConnectivityController, bool>((ref) {
  // StateNotifierProvider already calls [ConnectivityController.dispose].
  return ConnectivityController(ref);
});

class ConnectivityController extends StateNotifier<bool> {
  ConnectivityController(this._ref) : super(false) {
    unawaited(_startDeviceWatch());
  }

  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  var _disposed = false;

  Future<void> _startDeviceWatch() async {
    try {
      final connectivity = Connectivity();
      final initial = await connectivity.checkConnectivity();
      _applyDeviceResults(initial);
      _sub = connectivity.onConnectivityChanged.listen(_applyDeviceResults);
    } catch (_) {
      // Plugin unavailable in some test environments.
    }
  }

  void _applyDeviceResults(List<ConnectivityResult> results) {
    if (_disposed) return;
    final online = results.any((r) => r != ConnectivityResult.none);
    _ref.read(deviceOfflineProvider.notifier).state = !online;
    if (online && !state) {
      unawaited(_flushAndEnqueue());
    }
  }

  Future<void> _flushAndEnqueue() async {
    final session = _ref.read(authSessionProvider);
    await _ref.read(syncEngineProvider).flushNow(
          isOnline: true,
          projectId: session?.activeProjectId,
        );
    await _ref.read(backgroundSyncSchedulerProvider).enqueueOneOffFlush();
  }

  Future<void> setOffline(bool offline) async {
    state = offline;
    if (!offline) {
      await _flushAndEnqueue();
    }
  }

  Future<void> toggle() => setOffline(!state);

  @override
  void dispose() {
    _disposed = true;
    unawaited(_sub?.cancel());
    super.dispose();
  }
}
