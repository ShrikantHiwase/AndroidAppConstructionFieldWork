import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/issues/presentation/field_records_providers.dart';
import '../../sync/local_sync_engine.dart';
import '../../sync/sync_models.dart';

final syncEngineProvider = Provider<LocalSyncEngine>((ref) {
  return LocalSyncEngine(
    prefs: ref.watch(sharedPreferencesProvider),
    fieldRecords: ref.watch(fieldRecordsRepositoryProvider),
  );
});

final syncLogsProvider = StreamProvider<List<SyncLogEntry>>((ref) {
  return ref.watch(syncEngineProvider).watchLogs();
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
