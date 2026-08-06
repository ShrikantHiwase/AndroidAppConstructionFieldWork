import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/pilot_models.dart';
import '../domain/pilot_repository.dart';

class LocalPilotRepository implements PilotRepository {
  LocalPilotRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'pilot.uat_checklist';

  @override
  PilotChecklistState getChecklist() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const PilotChecklistState();
    return PilotChecklistState.fromJson(
      Map<String, Object?>.from(jsonDecode(raw) as Map),
    );
  }

  @override
  Future<void> saveChecklist(PilotChecklistState state) async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }
}
