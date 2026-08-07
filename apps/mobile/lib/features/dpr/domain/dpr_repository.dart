import '../../auth/domain/auth_models.dart';
import 'dpr_models.dart';

abstract class DprRepository {
  Stream<List<DailyProgressReport>> watchDprs(String projectId);
  Future<DailyProgressReport> createOrUpdateToday({
    required AuthSession session,
    required CreateDprInput input,
  });
  Future<DailyProgressReport> submit({
    required AuthSession session,
    required String dprId,
  });
  Future<DailyProgressReport?> todayDpr(String projectId, DateTime day);

  /// Demo-only yesterday submitted DPR (synced, no outbox). Leaves today empty for nudge demos.
  Future<void> ensureSeedDprs(AuthSession session);
}

abstract class DrawingPinsRepository {
  Future<void> ensureSeedDrawings(AuthSession session);
  Stream<List<DrawingSheet>> watchDrawings(String projectId);
  Stream<List<DrawingPin>> watchPins(String drawingId);
  Future<DrawingPin> addPin({
    required AuthSession session,
    required CreatePinInput input,
  });
}
