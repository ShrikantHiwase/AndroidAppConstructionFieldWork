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
  String syncPendingCount(int count) {
    return '$count sync';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHinglish => 'Hinglish';

  @override
  String get languagePickerLabel => 'Language';

  @override
  String get newIssue => 'New Issue';

  @override
  String get todaysDpr => 'Today\'s DPR';

  @override
  String get pinOnDrawing => 'Pin on Drawing';

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
      'Log issues with photos and location. Keep DPR ready.';

  @override
  String get rolePmTitle => 'PM queue';

  @override
  String get rolePmSubtitle =>
      'Review open issues/RFIs, assign work, approve status.';

  @override
  String get roleQaTitle => 'QA / QC';

  @override
  String get roleQaSubtitle =>
      'Inspections and quality issues with photo evidence.';

  @override
  String get roleClientTitle => 'Client view';

  @override
  String get roleClientSubtitle => 'Read-only progress and project documents.';

  @override
  String get roleAdminTitle => 'Admin';

  @override
  String get roleAdminSubtitle =>
      'Invite users, assign roles and projects, org settings.';

  @override
  String get primaryActions => 'Primary actions';

  @override
  String get signIn => 'Sign in';
}
