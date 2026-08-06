import 'digest_models.dart';

abstract class DigestsRepository {
  DigestPrefs getPrefs();
  Future<void> setPrefs(DigestPrefs prefs);
}
