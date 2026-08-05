// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Field Evidence';

  @override
  String get offlineBadge => 'ऑफ़लाइन';

  @override
  String get syncPending => 'सिंक हो रहा है…';

  @override
  String get newIssue => 'नया इश्यू';

  @override
  String get todaysDpr => 'आज का DPR';

  @override
  String get pinOnDrawing => 'ड्रॉइंग पर पिन';

  @override
  String get roleEngineerHome => 'साइट पर काम कैप्चर करें';

  @override
  String get rolePmHome => 'क्यू और अप्रूवल';

  @override
  String get roleQaHome => 'इंस्पेक्शन';

  @override
  String get roleClientHome => 'प्रगति और दस्तावेज़';
}
