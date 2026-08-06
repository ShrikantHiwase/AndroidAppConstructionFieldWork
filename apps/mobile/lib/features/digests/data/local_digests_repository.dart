import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/digest_models.dart';
import '../domain/digests_repository.dart';

class LocalDigestsRepository implements DigestsRepository {
  LocalDigestsRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'digests.prefs';

  @override
  DigestPrefs getPrefs() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const DigestPrefs();
    return DigestPrefs.fromJson(
      Map<String, Object?>.from(jsonDecode(raw) as Map),
    );
  }

  @override
  Future<void> setPrefs(DigestPrefs prefs) async {
    await _prefs.setString(_key, jsonEncode(prefs.toJson()));
  }
}
