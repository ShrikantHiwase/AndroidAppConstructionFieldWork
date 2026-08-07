import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// Application title shown in the OS and app chrome
  ///
  /// In en, this message translates to:
  /// **'Field Evidence'**
  String get appTitle;

  /// Shown when the device has no network
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineBadge;

  /// Pending outbox count in the home app bar
  ///
  /// In en, this message translates to:
  /// **'{count} sync'**
  String syncPendingCount(int count);

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHinglish.
  ///
  /// In en, this message translates to:
  /// **'Hinglish'**
  String get languageHinglish;

  /// No description provided for @languagePickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languagePickerLabel;

  /// No description provided for @newIssue.
  ///
  /// In en, this message translates to:
  /// **'New Issue'**
  String get newIssue;

  /// No description provided for @todaysDpr.
  ///
  /// In en, this message translates to:
  /// **'Today\'s DPR'**
  String get todaysDpr;

  /// No description provided for @pinOnDrawing.
  ///
  /// In en, this message translates to:
  /// **'Pin on Drawing'**
  String get pinOnDrawing;

  /// No description provided for @siteOps.
  ///
  /// In en, this message translates to:
  /// **'Site ops'**
  String get siteOps;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @openQueue.
  ///
  /// In en, this message translates to:
  /// **'Open queue'**
  String get openQueue;

  /// No description provided for @dprs.
  ///
  /// In en, this message translates to:
  /// **'DPRs'**
  String get dprs;

  /// No description provided for @digests.
  ///
  /// In en, this message translates to:
  /// **'Digests'**
  String get digests;

  /// No description provided for @weeklyPack.
  ///
  /// In en, this message translates to:
  /// **'Weekly pack'**
  String get weeklyPack;

  /// No description provided for @weeklyProgress.
  ///
  /// In en, this message translates to:
  /// **'Weekly progress'**
  String get weeklyProgress;

  /// No description provided for @pilot.
  ///
  /// In en, this message translates to:
  /// **'Pilot'**
  String get pilot;

  /// No description provided for @inspections.
  ///
  /// In en, this message translates to:
  /// **'Inspections'**
  String get inspections;

  /// No description provided for @qualityIssues.
  ///
  /// In en, this message translates to:
  /// **'Quality issues'**
  String get qualityIssues;

  /// No description provided for @issues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get issues;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @inviteUser.
  ///
  /// In en, this message translates to:
  /// **'Invite user'**
  String get inviteUser;

  /// No description provided for @roleEngineerTitle.
  ///
  /// In en, this message translates to:
  /// **'Site capture'**
  String get roleEngineerTitle;

  /// No description provided for @roleEngineerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log issues with photos and location. Keep DPR ready.'**
  String get roleEngineerSubtitle;

  /// No description provided for @rolePmTitle.
  ///
  /// In en, this message translates to:
  /// **'PM queue'**
  String get rolePmTitle;

  /// No description provided for @rolePmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review open issues/RFIs, assign work, approve status.'**
  String get rolePmSubtitle;

  /// No description provided for @roleQaTitle.
  ///
  /// In en, this message translates to:
  /// **'QA / QC'**
  String get roleQaTitle;

  /// No description provided for @roleQaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inspections and quality issues with photo evidence.'**
  String get roleQaSubtitle;

  /// No description provided for @roleClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Client view'**
  String get roleClientTitle;

  /// No description provided for @roleClientSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read-only progress and project documents.'**
  String get roleClientSubtitle;

  /// No description provided for @roleAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdminTitle;

  /// No description provided for @roleAdminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite users, assign roles and projects, org settings.'**
  String get roleAdminSubtitle;

  /// No description provided for @primaryActions.
  ///
  /// In en, this message translates to:
  /// **'Primary actions'**
  String get primaryActions;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
