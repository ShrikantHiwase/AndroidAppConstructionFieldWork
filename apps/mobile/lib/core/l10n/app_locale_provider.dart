import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/auth_controller.dart';

const _localePrefsKey = 'app.locale_code';

/// Demo language override: `en` or `hi` (Hinglish ARB). Null = device locale.
final appLocaleProvider =
    StateNotifierProvider<AppLocaleController, Locale?>((ref) {
  return AppLocaleController(ref.watch(sharedPreferencesProvider));
});

class AppLocaleController extends StateNotifier<Locale?> {
  AppLocaleController(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static Locale? _read(SharedPreferences prefs) {
    final code = prefs.getString(_localePrefsKey);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  Future<void> setLocaleCode(String? code) async {
    if (code == null || code.isEmpty) {
      await _prefs.remove(_localePrefsKey);
      state = null;
      return;
    }
    await _prefs.setString(_localePrefsKey, code);
    state = Locale(code);
  }

  /// Cycles English → Hinglish (hi) → device default.
  Future<void> cycle() async {
    final current = state?.languageCode;
    if (current == null) {
      await setLocaleCode('en');
    } else if (current == 'en') {
      await setLocaleCode('hi');
    } else {
      await setLocaleCode(null);
    }
  }
}
