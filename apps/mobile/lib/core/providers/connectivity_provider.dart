import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../sync/local_sync_engine.dart';
import '../../sync/remote/syncable_store.dart';
import '../../sync/sync_models.dart';

final syncEngineProvider = Provider<LocalSyncEngine>((ref) {
  final stores = <SyncableStore>[
    ref.watch(dprRepositoryProvider) as LocalDprRepository,
    ref.watch(drawingPinsRepositoryProvider) as LocalDrawingPinsRepository,
    ref.watch(siteOpsRepositoryProvider) as LocalSiteOpsRepository,
    ref.watch(documentsRepositoryProvider) as LocalDocumentsRepository,
    ref.watch(voiceNotesRepositoryProvider) as LocalVoiceNotesRepository,
  ];
  return LocalSyncEngine(
    prefs: ref.watch(sharedPreferencesProvider),
    fieldRecords: ref.watch(fieldRecordsRepositoryProvider),
    moduleStores: stores,
  );
});

final syncLogsProvider = StreamProvider<List<SyncLogEntry>>((ref) {
  return ref.watch(syncEngineProvider).watchLogs();
});

final pendingSyncCountProvider = StreamProvider<int>((ref) {
  return ref.watch(syncEngineProvider).watchPendingTotal();
});

/// Demo connectivity flag; flipping to online triggers an outbox flush.
final isOfflineProvider =
    StateNotifierProvider<ConnectivityController, bool>((ref) {
  return ConnectivityController(ref);
});

class ConnectivityController extends StateNotifier<bool> {
  ConnectivityController(this._ref) : super(false);

  final Ref _ref;

  Future<void> setOffline(bool offline) async {
    state = offline;
    if (!offline) {
      final session = _ref.read(authSessionProvider);
      await _ref.read(syncEngineProvider).flushNow(
            isOnline: true,
            projectId: session?.activeProjectId,
          );
    }
  }

  Future<void> toggle() => setOffline(!state);
}
