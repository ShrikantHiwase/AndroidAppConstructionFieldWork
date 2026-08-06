import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../../features/documents/data/local_documents_repository.dart';
import '../../features/dpr/data/local_dpr_repository.dart';
import '../../features/issues/data/local_field_records_repository.dart';
import '../../features/site_ops/data/local_site_ops_repository.dart';
import '../../features/voice_notes/data/local_voice_notes_repository.dart';
import '../local_sync_engine.dart';
import '../remote/firebase_storage_uploader.dart';
import '../remote/firestore_field_remote_pull.dart';
import '../remote/firestore_module_pull.dart';
import '../remote/firestore_outbox_remote_sink.dart';
import '../remote/module_remote_pull.dart';
import '../remote/outbox_remote_sink.dart';
import '../remote/storage_uploader.dart';
import '../remote/syncable_store.dart';

/// Result of a headless outbox flush (used by Workmanager + tests).
class BackgroundFlushResult {
  const BackgroundFlushResult({
    required this.flushed,
    required this.firebaseEnabled,
    this.error,
  });

  final int flushed;
  final bool firebaseEnabled;
  final String? error;
}

/// Builds local repos + [LocalSyncEngine] without Riverpod and flushes.
///
/// Safe to call from a Workmanager isolate after
/// `WidgetsFlutterBinding.ensureInitialized()`.
Future<BackgroundFlushResult> runBackgroundOutboxFlush({
  SharedPreferences? prefs,
  bool? forceOnline,
}) async {
  try {
    final shared = prefs ?? await SharedPreferences.getInstance();
    final firebase = await bootstrapFirebase();
    final OutboxRemoteSink sink = firebase.enabled
        ? FirestoreOutboxRemoteSink()
        : const NoOpOutboxRemoteSink();
    final ModuleRemotePull pull = firebase.enabled
        ? FirestoreModulePull()
        : const NoOpModuleRemotePull();

    final field = LocalFieldRecordsRepository(
      shared,
      remoteSink: sink,
      remotePull: firebase.enabled
          ? FirestoreFieldRemotePull()
          : null,
      storageUploader: firebase.enabled
          ? FirebaseStorageUploader()
          : const NoOpStorageUploader(),
    );
    final siteOps = LocalSiteOpsRepository(
      shared,
      remoteSink: sink,
      remotePull: pull,
      storageUploader: firebase.enabled
          ? FirebaseStorageUploader()
          : const NoOpStorageUploader(),
    );
    final pins = LocalDrawingPinsRepository(
      shared,
      remoteSink: sink,
      remotePull: pull,
      storageUploader: firebase.enabled
          ? FirebaseStorageUploader()
          : const NoOpStorageUploader(),
    );
    final stores = <SyncableStore>[
      LocalDprRepository(shared, remoteSink: sink, remotePull: pull),
      pins,
      siteOps,
      LocalDocumentsRepository(shared, remoteSink: sink, remotePull: pull),
      LocalVoiceNotesRepository(shared, remoteSink: sink, remotePull: pull),
    ];
    final engine = LocalSyncEngine(
      prefs: shared,
      fieldRecords: field,
      moduleStores: stores,
      mediaCaches: [field, siteOps, pins],
    );

    final projectId = shared.getString('auth.active_project');
    final flushed = await engine.flushNow(
      isOnline: forceOnline ?? true,
      projectId: projectId,
    );
    await shared.setString(
      'sync.background_last_at',
      DateTime.now().toUtc().toIso8601String(),
    );
    await shared.setInt('sync.background_last_flushed', flushed);
    return BackgroundFlushResult(
      flushed: flushed,
      firebaseEnabled: firebase.enabled,
    );
  } catch (e) {
    return BackgroundFlushResult(
      flushed: 0,
      firebaseEnabled: false,
      error: e.toString(),
    );
  }
}

/// Task names registered with Workmanager.
abstract final class BackgroundSyncTasks {
  static const periodicFlush = 'field_outbox_periodic_flush';
  static const oneOffFlush = 'field_outbox_oneoff_flush';
}

/// Reads last background flush metadata written by [runBackgroundOutboxFlush].
class BackgroundSyncMeta {
  const BackgroundSyncMeta({this.lastAt, this.lastFlushed = 0});

  final DateTime? lastAt;
  final int lastFlushed;

  factory BackgroundSyncMeta.fromPrefs(SharedPreferences prefs) {
    final raw = prefs.getString('sync.background_last_at');
    return BackgroundSyncMeta(
      lastAt: raw == null ? null : DateTime.tryParse(raw),
      lastFlushed: prefs.getInt('sync.background_last_flushed') ?? 0,
    );
  }
}
