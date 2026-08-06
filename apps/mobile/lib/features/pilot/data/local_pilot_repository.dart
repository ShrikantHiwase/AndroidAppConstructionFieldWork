import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/pilot_models.dart';
import '../domain/pilot_repository.dart';

class LocalPilotRepository implements PilotRepository {
  LocalPilotRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _checklistKey = 'pilot.uat_checklist';
  static const _issueTimingsKey = 'pilot.issue_create_timings';
  static const _dprTimingsKey = 'pilot.dpr_submit_timings';
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
  List<PilotDurationSample> getIssueCreateTimings() =>
      _readTimings(_issueTimingsKey);

  @override
  Future<void> recordIssueCreateTiming(PilotDurationSample sample) =>
      _appendTiming(_issueTimingsKey, sample);

  @override
  List<PilotDurationSample> getDprSubmitTimings() =>
      _readTimings(_dprTimingsKey);

  @override
  Future<void> recordDprSubmitTiming(PilotDurationSample sample) =>
      _appendTiming(_dprTimingsKey, sample);

  List<PilotDurationSample> _readTimings(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List? ?? const [];
    return list
        .map(
          (e) => PilotDurationSample.fromJson(
            Map<String, Object?>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<void> _appendTiming(String key, PilotDurationSample sample) async {
    final next = [..._readTimings(key), sample];
    while (next.length > _maxTimingSamples) {
      next.removeAt(0);
    }
    await _prefs.setString(
      key,
      jsonEncode(next.map((s) => s.toJson()).toList()),
    );
  }
}
