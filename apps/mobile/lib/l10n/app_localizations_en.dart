// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Field Evidence';

  @override
  String get offlineBadge => 'Offline';

  @override
  String get syncPending => 'Syncing…';

  @override
  String get newIssue => 'New Issue';

  @override
  String get todaysDpr => 'Today\'s DPR';

  @override
  String get pinOnDrawing => 'Pin on Drawing';

  @override
  String get roleEngineerHome => 'Capture work on site';

  @override
  String get rolePmHome => 'Queue and approvals';

  @override
  String get roleQaHome => 'Inspections';

  @override
  String get roleClientHome => 'Progress and documents';
}
