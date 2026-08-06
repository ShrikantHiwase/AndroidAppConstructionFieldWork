import 'pilot_models.dart';

abstract class PilotRepository {
  PilotChecklistState getChecklist();
  Future<void> saveChecklist(PilotChecklistState state);

  List<PilotDurationSample> getIssueCreateTimings();
  Future<void> recordIssueCreateTiming(PilotDurationSample sample);

  List<PilotDurationSample> getDprSubmitTimings();
  Future<void> recordDprSubmitTiming(PilotDurationSample sample);
}
