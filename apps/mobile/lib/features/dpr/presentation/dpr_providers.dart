import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/local_dpr_repository.dart';
import '../domain/dpr_models.dart';
import '../domain/dpr_repository.dart';

final dprRepositoryProvider = Provider<DprRepository>((ref) {
  return LocalDprRepository(ref.watch(sharedPreferencesProvider));
});

final drawingPinsRepositoryProvider = Provider<DrawingPinsRepository>((ref) {
  return LocalDrawingPinsRepository(ref.watch(sharedPreferencesProvider));
});

final dprsProvider = StreamProvider<List<DailyProgressReport>>((ref) {
  final session = ref.watch(authSessionProvider);
  if (session == null) return Stream.value(const []);
  return ref.watch(dprRepositoryProvider).watchDprs(session.activeProjectId);
});

final drawingsSeedProvider = FutureProvider<void>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null) return;
  await ref.read(drawingPinsRepositoryProvider).ensureSeedDrawings(session);
});

final drawingsProvider = StreamProvider<List<DrawingSheet>>((ref) async* {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    yield const [];
    return;
  }
  await ref.watch(drawingsSeedProvider.future);
  yield* ref
      .watch(drawingPinsRepositoryProvider)
      .watchDrawings(session.activeProjectId);
});

final pinsProvider =
    StreamProvider.family<List<DrawingPin>, String>((ref, drawingId) {
  return ref.watch(drawingPinsRepositoryProvider).watchPins(drawingId);
});
