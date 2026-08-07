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

  /// No description provided for @onlineBadge.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineBadge;

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

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email required'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password required'**
  String get passwordRequired;

  /// No description provided for @demoRoles.
  ///
  /// In en, this message translates to:
  /// **'Demo roles'**
  String get demoRoles;

  /// No description provided for @demoModeHint.
  ///
  /// In en, this message translates to:
  /// **'Demo mode — password for all accounts: demo1234'**
  String get demoModeHint;

  /// No description provided for @firebaseSignInHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your org email (Firebase Auth).'**
  String get firebaseSignInHint;

  /// No description provided for @backendFirebase.
  ///
  /// In en, this message translates to:
  /// **'Backend: Firebase'**
  String get backendFirebase;

  /// No description provided for @backendLocalDemo.
  ///
  /// In en, this message translates to:
  /// **'Backend: local demo'**
  String get backendLocalDemo;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @permCreateIssues.
  ///
  /// In en, this message translates to:
  /// **'Create issues'**
  String get permCreateIssues;

  /// No description provided for @permAssignWork.
  ///
  /// In en, this message translates to:
  /// **'Assign work'**
  String get permAssignWork;

  /// No description provided for @permChangeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get permChangeStatus;

  /// No description provided for @permApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get permApprove;

  /// No description provided for @permManageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage users'**
  String get permManageUsers;

  /// No description provided for @permReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get permReadOnly;

  /// No description provided for @clientReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Client accounts cannot create or edit field records.'**
  String get clientReadOnlyNote;

  /// No description provided for @biometricUnlock.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get biometricUnlock;

  /// No description provided for @biometricUnlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require unlock after app resume (local_auth when USE_NATIVE_SENSORS=true)'**
  String get biometricUnlockSubtitle;

  /// No description provided for @simulateAppResumeLock.
  ///
  /// In en, this message translates to:
  /// **'Simulate app resume lock'**
  String get simulateAppResumeLock;

  /// No description provided for @activeProject.
  ///
  /// In en, this message translates to:
  /// **'Active project'**
  String get activeProject;

  /// No description provided for @tooltipGoOnlineSync.
  ///
  /// In en, this message translates to:
  /// **'Go online & sync'**
  String get tooltipGoOnlineSync;

  /// No description provided for @tooltipSimulateOffline.
  ///
  /// In en, this message translates to:
  /// **'Simulate offline'**
  String get tooltipSimulateOffline;

  /// No description provided for @tooltipSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get tooltipSyncStatus;

  /// No description provided for @syncStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get syncStatusTitle;

  /// No description provided for @outboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'Outbox empty'**
  String get outboxEmpty;

  /// No description provided for @outboxPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s) waiting to sync'**
  String outboxPendingCount(int count);

  /// No description provided for @remoteFirestore.
  ///
  /// In en, this message translates to:
  /// **'Remote: Cloud Firestore (outbox push + pull)'**
  String get remoteFirestore;

  /// No description provided for @remoteDemo.
  ///
  /// In en, this message translates to:
  /// **'Remote: local demo sink (no cloud write)'**
  String get remoteDemo;

  /// No description provided for @demoCloudToggleLine.
  ///
  /// In en, this message translates to:
  /// **'Demo cloud toggle: {demoState} · Device network: {deviceState}'**
  String demoCloudToggleLine(String demoState, String deviceState);

  /// No description provided for @stateOffline.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get stateOffline;

  /// No description provided for @stateOnline.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get stateOnline;

  /// No description provided for @lastSuccessPrefix.
  ///
  /// In en, this message translates to:
  /// **'Last success:'**
  String get lastSuccessPrefix;

  /// No description provided for @lastFailurePrefix.
  ///
  /// In en, this message translates to:
  /// **'Last failure:'**
  String get lastFailurePrefix;

  /// No description provided for @localCache.
  ///
  /// In en, this message translates to:
  /// **'Local cache'**
  String get localCache;

  /// No description provided for @softBudgetLine.
  ///
  /// In en, this message translates to:
  /// **'{used} / {cap} soft budget{over}'**
  String softBudgetLine(String used, String cap, String over);

  /// No description provided for @softBudgetOverSuffix.
  ///
  /// In en, this message translates to:
  /// **' (over)'**
  String get softBudgetOverSuffix;

  /// No description provided for @cleanupCanReclaim.
  ///
  /// In en, this message translates to:
  /// **'Cleanup can reclaim {bytes} (uploaded local stubs)'**
  String cleanupCanReclaim(String bytes);

  /// No description provided for @backgroundSync.
  ///
  /// In en, this message translates to:
  /// **'Background sync'**
  String get backgroundSync;

  /// No description provided for @lastBackgroundFlushNever.
  ///
  /// In en, this message translates to:
  /// **'Last background flush: never'**
  String get lastBackgroundFlushNever;

  /// No description provided for @lastBackgroundFlushAt.
  ///
  /// In en, this message translates to:
  /// **'Last background flush: {when} ({count} item(s))'**
  String lastBackgroundFlushAt(String when, int count);

  /// No description provided for @enqueueBackgroundFlush.
  ///
  /// In en, this message translates to:
  /// **'Enqueue background flush'**
  String get enqueueBackgroundFlush;

  /// No description provided for @oneOffFlushEnqueued.
  ///
  /// In en, this message translates to:
  /// **'One-off background flush enqueued'**
  String get oneOffFlushEnqueued;

  /// No description provided for @oneOffFlushFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not enqueue (Workmanager unavailable here)'**
  String get oneOffFlushFailed;

  /// No description provided for @backendHealth.
  ///
  /// In en, this message translates to:
  /// **'Backend health'**
  String get backendHealth;

  /// No description provided for @healthNotProbedFirebase.
  ///
  /// In en, this message translates to:
  /// **'Not probed yet — call Cloud Functions health.'**
  String get healthNotProbedFirebase;

  /// No description provided for @healthDemoNoop.
  ///
  /// In en, this message translates to:
  /// **'Demo mode uses a local NoOp health probe.'**
  String get healthDemoNoop;

  /// No description provided for @probeHealth.
  ///
  /// In en, this message translates to:
  /// **'Probe health'**
  String get probeHealth;

  /// No description provided for @telemetry.
  ///
  /// In en, this message translates to:
  /// **'Telemetry'**
  String get telemetry;

  /// No description provided for @telemetryBackendLine.
  ///
  /// In en, this message translates to:
  /// **'Backend: {label}{userPart}'**
  String telemetryBackendLine(String label, String userPart);

  /// No description provided for @telemetryUserPart.
  ///
  /// In en, this message translates to:
  /// **' · user {userId}'**
  String telemetryUserPart(String userId);

  /// No description provided for @secureStoreLine.
  ///
  /// In en, this message translates to:
  /// **'Secure store: {label} (session email, biometrics flag, FCM token)'**
  String secureStoreLine(String label);

  /// No description provided for @telemetryFirebaseDeferred.
  ///
  /// In en, this message translates to:
  /// **'Crashlytics/Analytics packages still deferred — events stay local until FlutterFire go-live.'**
  String get telemetryFirebaseDeferred;

  /// No description provided for @telemetryDemoNoop.
  ///
  /// In en, this message translates to:
  /// **'Demo NoOp recorder — no network. Events listed below.'**
  String get telemetryDemoNoop;

  /// No description provided for @pushFcm.
  ///
  /// In en, this message translates to:
  /// **'Push (FCM)'**
  String get pushFcm;

  /// No description provided for @registeringToken.
  ///
  /// In en, this message translates to:
  /// **'Registering device token…'**
  String get registeringToken;

  /// No description provided for @tokenError.
  ///
  /// In en, this message translates to:
  /// **'Token error: {error}'**
  String tokenError(String error);

  /// No description provided for @noTokenSignIn.
  ///
  /// In en, this message translates to:
  /// **'No token (sign in required)'**
  String get noTokenSignIn;

  /// No description provided for @demoTokenLine.
  ///
  /// In en, this message translates to:
  /// **'Demo token: {token}'**
  String demoTokenLine(String token);

  /// No description provided for @tokenLine.
  ///
  /// In en, this message translates to:
  /// **'Token: {token}'**
  String tokenLine(String token);

  /// No description provided for @pushHelpFirebase.
  ///
  /// In en, this message translates to:
  /// **'Tap an inbox row to open the related DPR / issue / RFI. Functions send on DPR submit / issue & RFI assign & status.'**
  String get pushHelpFirebase;

  /// No description provided for @pushHelpDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo mode logs assign/status intents locally until FlutterFire is configured. Tap inbox rows to open linked screens.'**
  String get pushHelpDemo;

  /// No description provided for @noLinkedScreen.
  ///
  /// In en, this message translates to:
  /// **'No linked screen for this alert'**
  String get noLinkedScreen;

  /// No description provided for @flushNow.
  ///
  /// In en, this message translates to:
  /// **'Flush now'**
  String get flushNow;

  /// No description provided for @flushedItems.
  ///
  /// In en, this message translates to:
  /// **'Flushed {count} item(s)'**
  String flushedItems(int count);

  /// No description provided for @goOnline.
  ///
  /// In en, this message translates to:
  /// **'Go online'**
  String get goOnline;

  /// No description provided for @goOffline.
  ///
  /// In en, this message translates to:
  /// **'Go offline'**
  String get goOffline;

  /// No description provided for @cleanup.
  ///
  /// In en, this message translates to:
  /// **'Cleanup'**
  String get cleanup;

  /// No description provided for @cleanupRemovedLogs.
  ///
  /// In en, this message translates to:
  /// **'Removed {logs} log(s){mediaNote} (~{freed})'**
  String cleanupRemovedLogs(int logs, String mediaNote, String freed);

  /// No description provided for @cleanupMediaNote.
  ///
  /// In en, this message translates to:
  /// **', reclaimed {count} media path(s)'**
  String cleanupMediaNote(int count);

  /// No description provided for @conflictPolicy.
  ///
  /// In en, this message translates to:
  /// **'Conflict policy'**
  String get conflictPolicy;

  /// No description provided for @syncLog.
  ///
  /// In en, this message translates to:
  /// **'Sync log'**
  String get syncLog;

  /// No description provided for @noSyncEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No sync events yet.'**
  String get noSyncEventsYet;

  /// No description provided for @syncFooterNote.
  ///
  /// In en, this message translates to:
  /// **'Periodic Workmanager flush (~15 min, network required) + connectivity_plus auto-flush when the device reconnects. Cleanup clears sync logs and uploaded local:// media stubs. Drift still deferred.'**
  String get syncFooterNote;

  /// No description provided for @digestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Digests'**
  String get digestsTitle;

  /// No description provided for @digestsAndReminders.
  ///
  /// In en, this message translates to:
  /// **'Digests & reminders'**
  String get digestsAndReminders;

  /// No description provided for @signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get signInRequired;

  /// No description provided for @dailyDprNudge.
  ///
  /// In en, this message translates to:
  /// **'Daily DPR nudge'**
  String get dailyDprNudge;

  /// No description provided for @dailyDprNudgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local tray reminder around {hour}:00 if today\'s DPR is not submitted. Cloud FCM cron still deferred.'**
  String dailyDprNudgeSubtitle(int hour);

  /// No description provided for @reminderHour.
  ///
  /// In en, this message translates to:
  /// **'Reminder hour'**
  String get reminderHour;

  /// No description provided for @noDprNudgeNow.
  ///
  /// In en, this message translates to:
  /// **'No DPR nudge right now.'**
  String get noDprNudgeNow;

  /// No description provided for @openDpr.
  ///
  /// In en, this message translates to:
  /// **'Open DPR'**
  String get openDpr;

  /// No description provided for @simulate5PmCheck.
  ///
  /// In en, this message translates to:
  /// **'Simulate 5 PM check'**
  String get simulate5PmCheck;

  /// No description provided for @noNudgeAlreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'No nudge (DPR already submitted or prefs off).'**
  String get noNudgeAlreadySubmitted;

  /// No description provided for @dprReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'DPR reminder'**
  String get dprReminderTitle;

  /// No description provided for @pmDigests.
  ///
  /// In en, this message translates to:
  /// **'PM digests'**
  String get pmDigests;

  /// No description provided for @pmDigestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Aggregate open issues, RFIs, and DPR blockers for the active project.'**
  String get pmDigestsSubtitle;

  /// No description provided for @pmDigest.
  ///
  /// In en, this message translates to:
  /// **'PM digest'**
  String get pmDigest;

  /// No description provided for @digestUnavailableRole.
  ///
  /// In en, this message translates to:
  /// **'Digest unavailable for this role.'**
  String get digestUnavailableRole;

  /// No description provided for @pmDigestsOff.
  ///
  /// In en, this message translates to:
  /// **'PM digests are turned off.'**
  String get pmDigestsOff;

  /// No description provided for @digestSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'Open issues: {issues} · Open RFIs: {rfis} · Today DPR: {dpr}'**
  String digestSummaryLine(int issues, int rfis, String dpr);

  /// No description provided for @todayDprIncomplete.
  ///
  /// In en, this message translates to:
  /// **'incomplete'**
  String get todayDprIncomplete;

  /// No description provided for @todayDprOk.
  ///
  /// In en, this message translates to:
  /// **'ok'**
  String get todayDprOk;

  /// No description provided for @queueIsClear.
  ///
  /// In en, this message translates to:
  /// **'Queue is clear.'**
  String get queueIsClear;

  /// No description provided for @shareDigestPdf.
  ///
  /// In en, this message translates to:
  /// **'Share digest PDF'**
  String get shareDigestPdf;

  /// No description provided for @shareAsText.
  ///
  /// In en, this message translates to:
  /// **'Share as text'**
  String get shareAsText;

  /// No description provided for @pmDigestsStaffOnly.
  ///
  /// In en, this message translates to:
  /// **'PM digests are available to project managers and admins.'**
  String get pmDigestsStaffOnly;

  /// No description provided for @unlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Field Evidence'**
  String get unlockTitle;

  /// No description provided for @unlockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm it is you to continue.'**
  String get unlockConfirm;

  /// No description provided for @unlockWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}. {hint}'**
  String unlockWelcomeBack(String name, String hint);

  /// No description provided for @unlockHintNative.
  ///
  /// In en, this message translates to:
  /// **'Use device biometrics or PIN.'**
  String get unlockHintNative;

  /// No description provided for @unlockHintDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo unlock (FakeBiometricService) until USE_NATIVE_SENSORS=true.'**
  String get unlockHintDemo;

  /// No description provided for @unlockAction.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockAction;

  /// No description provided for @unlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Unlock failed'**
  String get unlockFailed;

  /// No description provided for @unlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Field Evidence'**
  String get unlockReason;
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
