import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/pilot_models.dart';
import '../domain/pilot_repository.dart';

class LocalPilotRepository implements PilotRepository {
  LocalPilotRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _checklistKey = 'pilot.uat_checklist';
  static const _timingsKey = 'pilot.issue_create_timings';
  static const _maxTimingSamples = 50;

  @override
  PilotChecklistState getChecklist() {
    final raw = _prefs.getString(_checklistKey);
    if (raw == null) return const PilotChecklistState();
    return PilotChecklistState.fromJson(
      Map<String, Object?>.from(jsonDecode(raw) as Map),
    );
  }

  @override
  Future<void> saveChecklist(PilotChecklistState state) async {
    await _prefs.setString(_checklistKey, jsonEncode(state.toJson()));
  }

  @override
  List<IssueCreateTimingSample> getIssueCreateTimings() {
    final raw = _prefs.getString(_timingsKey);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List? ?? const [];
    return list
        .map(
          (e) => IssueCreateTimingSample.fromJson(
            Map<String, Object?>.from(e as Map),
          ),
        )
        .toList();
  }

  @override
  Future<void> recordIssueCreateTiming(IssueCreateTimingSample sample) async {
    final next = [...getIssueCreateTimings(), sample];
    while (next.length > _maxTimingSamples) {
      next.removeAt(0);
    }
    await _prefs.setString(
      _timingsKey,
      jsonEncode(next.map((s) => s.toJson()).toList()),
    );
  }
}
