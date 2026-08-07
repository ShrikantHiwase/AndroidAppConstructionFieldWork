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
  String syncPendingCount(int count) {
    return '$count sync';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHinglish => 'Hinglish';

  @override
  String get languagePickerLabel => 'भाषा / Language';

  @override
  String get newIssue => 'नया Issue';

  @override
  String get todaysDpr => 'आज का DPR';

  @override
  String get pinOnDrawing => 'Drawing पर Pin';

  @override
  String get siteOps => 'Site ops';

  @override
  String get reminders => 'Reminders';

  @override
  String get openQueue => 'Open queue';

  @override
  String get dprs => 'DPRs';

  @override
  String get digests => 'Digests';

  @override
  String get weeklyPack => 'Weekly pack';

  @override
  String get weeklyProgress => 'Weekly progress';

  @override
  String get pilot => 'Pilot';

  @override
  String get inspections => 'Inspections';

  @override
  String get qualityIssues => 'Quality issues';

  @override
  String get issues => 'Issues';

  @override
  String get documents => 'Documents';

  @override
  String get inviteUser => 'Invite user';

  @override
  String get roleEngineerTitle => 'Site capture';

  @override
  String get roleEngineerSubtitle =>
      'Photo + GPS से issue बनाओ। DPR ready रखो।';

  @override
  String get rolePmTitle => 'PM queue';

  @override
  String get rolePmSubtitle =>
      'Open issues/RFIs देखो, assign करो, status approve करो।';

  @override
  String get roleQaTitle => 'QA / QC';

  @override
  String get roleQaSubtitle =>
      'Inspections और quality issues — photo evidence के साथ।';

  @override
  String get roleClientTitle => 'Client view';

  @override
  String get roleClientSubtitle => 'Read-only progress और project documents.';

  @override
  String get roleAdminTitle => 'Admin';

  @override
  String get roleAdminSubtitle =>
      'Users invite करो, roles/projects assign करो।';

  @override
  String get primaryActions => 'Primary actions';

  @override
  String get signIn => 'Sign in';
}
