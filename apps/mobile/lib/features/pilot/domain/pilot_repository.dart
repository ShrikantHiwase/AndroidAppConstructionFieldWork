import 'pilot_models.dart';

abstract class PilotRepository {
  PilotChecklistState getChecklist();
  Future<void> saveChecklist(PilotChecklistState state);
}
