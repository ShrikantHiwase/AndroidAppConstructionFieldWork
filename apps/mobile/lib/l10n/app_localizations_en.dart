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
  String get onlineBadge => 'Online';

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

  @override
  String get signOut => 'Sign out';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get emailRequired => 'Email required';

  @override
  String get passwordRequired => 'Password required';

  @override
  String get demoRoles => 'Demo roles';

  @override
  String get demoModeHint => 'Demo mode — password for all accounts: demo1234';

  @override
  String get firebaseSignInHint =>
      'Sign in with your org email (Firebase Auth).';

  @override
  String get backendFirebase => 'Backend: Firebase';

  @override
  String get backendLocalDemo => 'Backend: local demo';

  @override
  String get permissions => 'Permissions';

  @override
  String get permCreateIssues => 'Create issues';

  @override
  String get permAssignWork => 'Assign work';

  @override
  String get permChangeStatus => 'Change status';

  @override
  String get permApprove => 'Approve';

  @override
  String get permManageUsers => 'Manage users';

  @override
  String get permReadOnly => 'Read-only';

  @override
  String get clientReadOnlyNote =>
      'Client accounts cannot create or edit field records.';

  @override
  String get biometricUnlock => 'Biometric unlock';

  @override
  String get biometricUnlockSubtitle =>
      'Require unlock after app resume (local_auth when USE_NATIVE_SENSORS=true)';

  @override
  String get simulateAppResumeLock => 'Simulate app resume lock';

  @override
  String get activeProject => 'Active project';

  @override
  String get tooltipGoOnlineSync => 'Go online & sync';

  @override
  String get tooltipSimulateOffline => 'Simulate offline';

  @override
  String get tooltipSyncStatus => 'Sync status';

  @override
  String get syncStatusTitle => 'Sync status';

  @override
  String get outboxEmpty => 'Outbox empty';

  @override
  String outboxPendingCount(int count) {
    return '$count item(s) waiting to sync';
  }

  @override
  String get remoteFirestore => 'Remote: Cloud Firestore (outbox push + pull)';

  @override
  String get remoteDemo => 'Remote: local demo sink (no cloud write)';

  @override
  String demoCloudToggleLine(String demoState, String deviceState) {
    return 'Demo cloud toggle: $demoState · Device network: $deviceState';
  }

  @override
  String get stateOffline => 'offline';

  @override
  String get stateOnline => 'online';

  @override
  String get lastSuccessPrefix => 'Last success:';

  @override
  String get lastFailurePrefix => 'Last failure:';

  @override
  String get localCache => 'Local cache';

  @override
  String softBudgetLine(String used, String cap, String over) {
    return '$used / $cap soft budget$over';
  }

  @override
  String get softBudgetOverSuffix => ' (over)';

  @override
  String cleanupCanReclaim(String bytes) {
    return 'Cleanup can reclaim $bytes (uploaded local stubs)';
  }

  @override
  String get backgroundSync => 'Background sync';

  @override
  String get lastBackgroundFlushNever => 'Last background flush: never';

  @override
  String lastBackgroundFlushAt(String when, int count) {
    return 'Last background flush: $when ($count item(s))';
  }

  @override
  String get enqueueBackgroundFlush => 'Enqueue background flush';

  @override
  String get oneOffFlushEnqueued => 'One-off background flush enqueued';

  @override
  String get oneOffFlushFailed =>
      'Could not enqueue (Workmanager unavailable here)';

  @override
  String get backendHealth => 'Backend health';

  @override
  String get healthNotProbedFirebase =>
      'Not probed yet — call Cloud Functions health.';

  @override
  String get healthDemoNoop => 'Demo mode uses a local NoOp health probe.';

  @override
  String get probeHealth => 'Probe health';

  @override
  String get telemetry => 'Telemetry';

  @override
  String telemetryBackendLine(String label, String userPart) {
    return 'Backend: $label$userPart';
  }

  @override
  String telemetryUserPart(String userId) {
    return ' · user $userId';
  }

  @override
  String secureStoreLine(String label) {
    return 'Secure store: $label (session email, biometrics flag, FCM token)';
  }

  @override
  String get telemetryFirebaseDeferred =>
      'Crashlytics/Analytics packages still deferred — events stay local until FlutterFire go-live.';

  @override
  String get telemetryDemoNoop =>
      'Demo NoOp recorder — no network. Events listed below.';

  @override
  String get pushFcm => 'Push (FCM)';

  @override
  String get registeringToken => 'Registering device token…';

  @override
  String tokenError(String error) {
    return 'Token error: $error';
  }

  @override
  String get noTokenSignIn => 'No token (sign in required)';

  @override
  String demoTokenLine(String token) {
    return 'Demo token: $token';
  }

  @override
  String tokenLine(String token) {
    return 'Token: $token';
  }

  @override
  String get pushHelpFirebase =>
      'Tap an inbox row to open the related DPR / issue / RFI. Functions send on DPR submit / issue & RFI assign & status.';

  @override
  String get pushHelpDemo =>
      'Demo mode logs assign/status intents locally until FlutterFire is configured. Tap inbox rows to open linked screens.';

  @override
  String get noLinkedScreen => 'No linked screen for this alert';

  @override
  String get flushNow => 'Flush now';

  @override
  String flushedItems(int count) {
    return 'Flushed $count item(s)';
  }

  @override
  String get goOnline => 'Go online';

  @override
  String get goOffline => 'Go offline';

  @override
  String get cleanup => 'Cleanup';

  @override
  String cleanupRemovedLogs(int logs, String mediaNote, String freed) {
    return 'Removed $logs log(s)$mediaNote (~$freed)';
  }

  @override
  String cleanupMediaNote(int count) {
    return ', reclaimed $count media path(s)';
  }

  @override
  String get conflictPolicy => 'Conflict policy';

  @override
  String get syncLog => 'Sync log';

  @override
  String get noSyncEventsYet => 'No sync events yet.';

  @override
  String get syncFooterNote =>
      'Periodic Workmanager flush (~15 min, network required) + connectivity_plus auto-flush when the device reconnects. Cleanup clears sync logs and uploaded local:// media stubs. Drift still deferred.';

  @override
  String get digestsTitle => 'Digests';

  @override
  String get digestsAndReminders => 'Digests & reminders';

  @override
  String get signInRequired => 'Sign in required';

  @override
  String get dailyDprNudge => 'Daily DPR nudge';

  @override
  String dailyDprNudgeSubtitle(int hour) {
    return 'Local tray reminder around $hour:00 if today\'s DPR is not submitted. Cloud FCM cron still deferred.';
  }

  @override
  String get reminderHour => 'Reminder hour';

  @override
  String get noDprNudgeNow => 'No DPR nudge right now.';

  @override
  String get openDpr => 'Open DPR';

  @override
  String get simulate5PmCheck => 'Simulate 5 PM check';

  @override
  String get noNudgeAlreadySubmitted =>
      'No nudge (DPR already submitted or prefs off).';

  @override
  String get dprReminderTitle => 'DPR reminder';

  @override
  String get dprReminderBody =>
      'Submit today\'s Daily Progress Report if you haven\'t yet.';

  @override
  String get pmDigests => 'PM digests';

  @override
  String get pmDigestsSubtitle =>
      'Aggregate open issues, RFIs, and DPR blockers for the active project.';

  @override
  String get pmDigest => 'PM digest';

  @override
  String get digestUnavailableRole => 'Digest unavailable for this role.';

  @override
  String get pmDigestsOff => 'PM digests are turned off.';

  @override
  String digestSummaryLine(int issues, int rfis, String dpr) {
    return 'Open issues: $issues · Open RFIs: $rfis · Today DPR: $dpr';
  }

  @override
  String get todayDprIncomplete => 'incomplete';

  @override
  String get todayDprOk => 'ok';

  @override
  String get queueIsClear => 'Queue is clear.';

  @override
  String get shareDigestPdf => 'Share digest PDF';

  @override
  String get shareAsText => 'Share as text';

  @override
  String get pmDigestsStaffOnly =>
      'PM digests are available to project managers and admins.';

  @override
  String get unlockTitle => 'Unlock Field Evidence';

  @override
  String get unlockConfirm => 'Confirm it is you to continue.';

  @override
  String unlockWelcomeBack(String name, String hint) {
    return 'Welcome back, $name. $hint';
  }

  @override
  String get unlockHintNative => 'Use device biometrics or PIN.';

  @override
  String get unlockHintDemo =>
      'Demo unlock (FakeBiometricService) until USE_NATIVE_SENSORS=true.';

  @override
  String get unlockAction => 'Unlock';

  @override
  String get unlockFailed => 'Unlock failed';

  @override
  String get unlockReason => 'Unlock Field Evidence';

  @override
  String get syncingEllipsis => 'Syncing…';

  @override
  String pendingCount(int count) {
    return '$count pending';
  }

  @override
  String get noIssuesYet => 'No issues yet. Capture one from the field.';

  @override
  String get notSyncedSuffix => ' · not synced';

  @override
  String get titleLabel => 'Title';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get requiredField => 'Required';

  @override
  String get evidence => 'Evidence';

  @override
  String get sensorsNativeHint =>
      'Using device GPS / camera (USE_NATIVE_SENSORS).';

  @override
  String get sensorsDemoHint =>
      'Demo sensors — enable with --dart-define=USE_NATIVE_SENSORS=true';

  @override
  String get addGps => 'Add GPS';

  @override
  String get refreshGps => 'Refresh GPS';

  @override
  String get clearGps => 'Clear GPS';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get fromGallery => 'From gallery';

  @override
  String get queuedForUpload => 'Queued for upload';

  @override
  String get uploadedStatus => 'Uploaded';

  @override
  String get onDeviceStatus => 'On device';

  @override
  String get syncedDemoStatus => 'Synced (demo)';

  @override
  String get saveIssue => 'Save issue';

  @override
  String get savesOfflineHint =>
      'Saves offline immediately; syncs when online.';

  @override
  String get issueNoun => 'Issue';

  @override
  String get issueNotFound => 'Issue not found';

  @override
  String get noDescription => 'No description';

  @override
  String byAuthorLine(String author, String assigneePart, String syncPart) {
    return 'By $author$assigneePart$syncPart';
  }

  @override
  String assignedToPart(String name) {
    return ' · Assigned to $name';
  }

  @override
  String get syncedPart => ' · synced';

  @override
  String get pendingSyncPart => ' · pending sync';

  @override
  String get statusSection => 'Status';

  @override
  String get assignToAsha => 'Assign to Asha Patil';

  @override
  String get statusHistory => 'Status history';

  @override
  String get comments => 'Comments';

  @override
  String get noCommentsYet => 'No comments yet.';

  @override
  String get addComment => 'Add comment';

  @override
  String get postComment => 'Post comment';

  @override
  String get pendingLabel => 'pending';

  @override
  String get syncedLabel => 'synced';

  @override
  String get rfisTitle => 'RFIs';

  @override
  String get newRfi => 'New RFI';

  @override
  String get noRfisYet => 'No RFIs yet.';

  @override
  String get subjectLabel => 'Subject';

  @override
  String get questionLabel => 'Question';

  @override
  String get submitRfi => 'Submit RFI';

  @override
  String get rfiNoun => 'RFI';

  @override
  String get rfiNotFound => 'RFI not found';

  @override
  String get threadedResponses => 'Threaded responses';

  @override
  String get addResponse => 'Add response';

  @override
  String get postResponse => 'Post response';

  @override
  String get dailyProgress => 'Daily Progress';

  @override
  String get noDprsYet =>
      'No DPRs yet. Capture today\'s progress in ~3 minutes.';

  @override
  String get submittedLabel => 'Submitted';

  @override
  String get draftLabel => 'Draft';

  @override
  String activitiesCount(int count) {
    return '$count activities';
  }

  @override
  String get alreadySubmittedViewOnly => 'Already submitted — view only.';

  @override
  String get weatherLabel => 'Weather';

  @override
  String get manpowerSummaryLabel => 'Manpower summary';

  @override
  String get activities => 'Activities';

  @override
  String get activityLocationLabel => 'Activity + optional location';

  @override
  String get activityPhoto => 'Activity photo';

  @override
  String get gallery => 'Gallery';

  @override
  String photoAttachesNext(String label, String size) {
    return '$label · $size (attaches to next activity)';
  }

  @override
  String get blockersLabel => 'Blockers';

  @override
  String get saveDraftForVoice =>
      'Save a draft once to attach voice notes to today\'s DPR.';

  @override
  String get saveDraft => 'Save draft';

  @override
  String get submitDpr => 'Submit DPR';

  @override
  String get dprNoun => 'DPR';

  @override
  String get dprNotFound => 'DPR not found';

  @override
  String get sharePdf => 'Share PDF';

  @override
  String get sharePdfTooltip => 'Share PDF';

  @override
  String get shareTextTooltip => 'Share text summary';

  @override
  String weatherValue(String value) {
    return 'Weather: $value';
  }

  @override
  String manpowerValue(String value) {
    return 'Manpower: $value';
  }

  @override
  String get textPreview => 'Text preview';

  @override
  String get shareSheetHint =>
      'PDF and text open the system share sheet (WhatsApp, email, etc.).';

  @override
  String get noEvidencePhoto => 'No evidence photo';

  @override
  String get evidencePhotoQueued => 'Evidence photo · queued upload';

  @override
  String get evidencePhotoSynced => 'Evidence photo · synced';

  @override
  String get evidencePhotoAttached => 'Evidence photo attached';

  @override
  String get tabSafety => 'Safety';

  @override
  String get tabQaQc => 'QA/QC';

  @override
  String get tabLabour => 'Labour';

  @override
  String get tabMaterials => 'Materials';

  @override
  String get logSafety => 'Log safety';

  @override
  String get wirChecklist => 'WIR checklist';

  @override
  String get muster => 'Muster';

  @override
  String get grnUse => 'GRN / use';

  @override
  String get noSafetyRecordsYet => 'No safety records yet.';

  @override
  String get noInspectionsYet => 'No inspections yet.';

  @override
  String get noLabourMusterYet => 'No labour muster yet (supervisor-led).';

  @override
  String get noMaterialLogsYet => 'No material logs yet.';

  @override
  String get safetyRecord => 'Safety record';

  @override
  String get labourMuster => 'Labour muster';

  @override
  String get materialLog => 'Material log';

  @override
  String get kindLabel => 'Kind';

  @override
  String get notesLabel => 'Notes';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get photoRequiredObservation =>
      'Photo evidence required for observations / incidents.';

  @override
  String get photoOptionalToolbox => 'Photo optional for toolbox talks.';

  @override
  String get queuedLabel => 'Queued';

  @override
  String queuedWithSize(String size) {
    return 'Queued · ~$size';
  }

  @override
  String get photoRequiredForFail =>
      'Photo required for failed checklist items';

  @override
  String inspectionSavedWithFailPhoto(String size) {
    return 'Inspection saved with fail photo$size';
  }

  @override
  String get musterDialogHint =>
      'Logs Civil · Shree Contractors · 18 with geofence check. Photo is optional.';

  @override
  String get logMuster => 'Log muster';

  @override
  String get materialDialogHint =>
      'GRN inward or consumption lite. Photo is optional.';

  @override
  String get inward => 'Inward';

  @override
  String get useLabel => 'Use';

  @override
  String get materialLabel => 'Material';

  @override
  String get qtyLabel => 'Qty';

  @override
  String get unitLabel => 'Unit';

  @override
  String get activityRefOptional => 'Activity ref (optional)';

  @override
  String get uploadTooltip => 'Upload';

  @override
  String get noDocumentFoldersYet => 'No document folders yet.';

  @override
  String get emptyFolderUploadHint =>
      'Empty folder. Upload a file to get started.';

  @override
  String get uploadDocument => 'Upload document';

  @override
  String get fileNameLabel => 'File name';

  @override
  String get typeLabel => 'Type';

  @override
  String get pickFile => 'Pick file';

  @override
  String get pickDemoFile => 'Pick demo file';

  @override
  String get previewNotesLabel => 'Preview / notes';

  @override
  String get contentPreviewLabel => 'Content preview';

  @override
  String get uploadAction => 'Upload';

  @override
  String get uploadHintNative =>
      'Pick a file from the device, or upload with typed preview. On flush, paths upload to Firebase Storage when configured.';

  @override
  String get uploadHintDemo =>
      'Pick demo file fills a local:// stub + preview. On flush, demo paths use demo:// Storage URLs. Enable native pick with --dart-define=USE_NATIVE_SENSORS=true.';

  @override
  String get documentNoun => 'Document';

  @override
  String get documentNotFound => 'Document not found';

  @override
  String get downloadTooltip => 'Download';

  @override
  String get savedOnDevice => 'Saved on device';

  @override
  String get shareDocumentSummaryTooltip => 'Share document summary';

  @override
  String get searchLabel => 'Search';

  @override
  String get pdfrxViewerHint =>
      'PDF viewer (pdfrx) — pinch to zoom, scroll pages.';

  @override
  String get drawingsTitle => 'Drawings';

  @override
  String get noDrawingsSeededYet => 'No drawings seeded yet.';

  @override
  String drawingPagesCount(String version, int count) {
    return '$version · $count pages';
  }

  @override
  String get drawingNoun => 'Drawing';

  @override
  String get drawingNotFound => 'Drawing not found';

  @override
  String get linkIssue => 'Link issue';

  @override
  String get tapToDropPin =>
      'Tap the sheet to drop a punch pin (after linking an issue).';

  @override
  String get selectIssueFirst => 'Select an issue first';

  @override
  String get pinDropped => 'Pin dropped';

  @override
  String get createIssueFirst => 'Create an issue first';

  @override
  String get selectIssueToPin => 'Select issue to pin';

  @override
  String get photoOptional => 'Photo optional';

  @override
  String tapSheetHint(
    String title,
    String version,
    int page,
    String issueHint,
    String photoHint,
  ) {
    return '$title\n$version\nPage $page\n\nTap to drop a punch pin$issueHint$photoHint.';
  }

  @override
  String get selectIssueFirstParen => ' (select an issue first)';

  @override
  String get withEvidencePhoto => ' with evidence photo';

  @override
  String pinnedIssueSnack(String title, String photoNote) {
    return 'Pinned \"$title\"$photoNote';
  }

  @override
  String get plusEvidencePhoto => ' + evidence photo';

  @override
  String get pilotUatTitle => 'Pilot / UAT';

  @override
  String get pilotHubRestricted => 'Pilot hub is for PM and Admin.';

  @override
  String get resetUatChecklistTitle => 'Reset UAT checklist?';

  @override
  String get resetUatChecklistBody => 'Clears all local ticks on this device.';

  @override
  String get resetAction => 'Reset';

  @override
  String get hypercareSnapshot => 'Hypercare snapshot';

  @override
  String get hypercareTargetsHint =>
      'Targets: DPR >=4 days this week · DPR submit median <3m · issue create median <90s · sync errors <2%. Full guide: docs/Hypercare_Metrics.md';

  @override
  String get noSnapshot => 'No snapshot';

  @override
  String get sharePilotPdf => 'Share pilot PDF';

  @override
  String get metricDprDaysSubmitted => 'DPR days submitted (ISO week)';

  @override
  String get metricDprSubmitMedian => 'DPR submit median';

  @override
  String get metricIssueCreateMedian => 'Issue create median';

  @override
  String get metricOpenIssues => 'Open issues';

  @override
  String get metricPendingSync => 'Pending sync';

  @override
  String get metricSyncFailureRate => 'Sync failure rate';

  @override
  String get hintTargetGte4 => 'target >=4';

  @override
  String get hintActiveProject => 'active project';

  @override
  String get hintOutbox => 'outbox';

  @override
  String uatChecklistProgress(int completed, int total) {
    return 'UAT checklist ($completed/$total)';
  }

  @override
  String get uatChecklistHint =>
      'Mirrors docs/UAT_Checklist.md — tick as you verify on device.';

  @override
  String get weeklyProgressRoleGate =>
      'Weekly progress is available to clients, PMs, and admins.';

  @override
  String get progressPackUnavailable => 'Progress pack unavailable.';

  @override
  String isoWeekLabel(String range) {
    return 'ISO week $range';
  }

  @override
  String submittedDprDaysLine(int days, int openCount) {
    return 'Submitted DPR days: $days / 7 · Open issues: $openCount';
  }

  @override
  String get emptyWeekShareHint =>
      'No submitted DPRs in this ISO week yet. Share still works so clients can open an empty pack without a PM compile.';

  @override
  String weatherManpowerLine(String weather, String manpower) {
    return 'Weather: $weather · Manpower: $manpower';
  }

  @override
  String blockersLine(String text) {
    return 'Blockers: $text';
  }

  @override
  String get openIssuesSection => 'Open issues';

  @override
  String get shareWeeklyPdf => 'Share weekly PDF';

  @override
  String get invitesTitle => 'Invites';

  @override
  String get inviteUsersTitle => 'Invite users';

  @override
  String get adminOnly => 'Admin only';

  @override
  String get createInvite => 'Create invite';

  @override
  String get firebaseInviteHint =>
      'Creates a Firebase Auth user + memberships via the inviteMember callable (temporary password demo1234 until email delivery is wired).';

  @override
  String get demoInviteHint =>
      'Invitees sign in with the email + password demo1234 (local demo). When Firebase is on, the same form calls Cloud Functions.';

  @override
  String get roleSectionLabel => 'Role';

  @override
  String get projectsSectionLabel => 'Projects';

  @override
  String get sendInvite => 'Send invite';

  @override
  String get invitesSection => 'Invites';

  @override
  String get noInvitesYet => 'No invites yet.';

  @override
  String get copySignInHintTooltip => 'Copy sign-in hint';

  @override
  String get inviteHintCopied => 'Invite hint copied';

  @override
  String inviteCreatedFirebase(String email) {
    return 'Invite created for $email. Temp password: demo1234';
  }

  @override
  String inviteCreatedDemo(String email) {
    return 'Invite created for $email. Password: demo1234';
  }

  @override
  String inviteListSubtitle(String role, String status, int count) {
    return '$role · $status · $count project(s)';
  }

  @override
  String clipboardInviteHint(String email) {
    return 'Field Evidence invite\nEmail: $email\nPassword: demo1234';
  }

  @override
  String get noSession => 'No session';

  @override
  String get voiceNotesTitle => 'Voice notes';

  @override
  String get voiceNotesHintNative =>
      'Live mic capture; flush syncs audio to Storage and transcript to Firestore.';

  @override
  String get voiceNotesHintDemo =>
      'Demo capture stores audio stub + transcript; flush syncs to Firestore/Storage. Enable live mic with --dart-define=USE_NATIVE_SENSORS=true.';

  @override
  String get noVoiceNotesYet => 'No voice notes yet.';

  @override
  String get transcriptPendingPart => ' · transcript pending';

  @override
  String get audioReadyPart => ' · audio ready';

  @override
  String get recordingVoiceNoteTitle => 'Recording voice note';

  @override
  String get recordingVoiceNoteBody => 'Speak, then tap Stop (max 60s).';

  @override
  String get stopAction => 'Stop';

  @override
  String get recordVoiceOffline => 'Record voice (offline)';

  @override
  String get addDemoVoiceOffline => 'Add demo voice (offline)';

  @override
  String get recordVoiceNote => 'Record voice note';

  @override
  String get addDemoVoiceNote => 'Add demo voice note';

  @override
  String get disciplineFolderKind => 'Discipline';

  @override
  String get documentTypeFolderKind => 'Document type';

  @override
  String get onDevicePart => ' · on device';

  @override
  String get cloudPart => ' · cloud';

  @override
  String pageOfTotal(int current, int total) {
    return 'Page $current / $total';
  }

  @override
  String get noPdfPreview => 'No PDF preview available.';

  @override
  String get textPdfPreviewHint =>
      'Text PDF preview — open a seeded or on-device PDF for pdfrx.';

  @override
  String get noPreviewForFileType => 'No preview available for this file type.';

  @override
  String get noneLabel => 'None';

  @override
  String photoEvidenceCount(int count) {
    return '$count photo evidence';
  }

  @override
  String gpsCoords(String lat, String lng, String labelPart) {
    return 'GPS: $lat, $lng$labelPart';
  }

  @override
  String get demoStubLabel => 'Demo stub';

  @override
  String get fileNoun => 'File';

  @override
  String pickedFileMeta(String kind, String bytes) {
    return '$kind · $bytes';
  }

  @override
  String inspectionChecksCount(int count, String status) {
    return '$count checks · $status';
  }

  @override
  String get hasFailsLabel => 'HAS FAILS';

  @override
  String get passLabel => 'PASS';

  @override
  String get photoQueuedPart => ' · photo queued';

  @override
  String get photoUploadedPart => ' · photo uploaded';

  @override
  String get photoAttachedPart => ' · photo';

  @override
  String geofenceStatusLine(String subcontractor, String status) {
    return '$subcontractor · geofence $status';
  }

  @override
  String get geofenceOk => 'OK';

  @override
  String get geofenceMiss => 'MISS';

  @override
  String musterLoggedOk(String photoNote) {
    return 'Muster logged (geofence OK)$photoNote';
  }

  @override
  String musterLoggedMiss(String photoNote) {
    return 'Muster logged (geofence MISS)$photoNote';
  }

  @override
  String materialInwardLogged(String photoNote) {
    return 'Material inward logged$photoNote';
  }

  @override
  String materialConsumptionLogged(String photoNote) {
    return 'Material consumption logged$photoNote';
  }

  @override
  String get todaysDprIncomplete => 'Today\'s DPR incomplete';

  @override
  String get noDraftYet => 'No draft yet';

  @override
  String get draftNotSubmitted => 'Draft not submitted';

  @override
  String issueStatusSubtitle(String status) {
    return 'Issue · $status';
  }

  @override
  String rfiStatusSubtitle(String status) {
    return 'RFI · $status';
  }

  @override
  String blockerTitle(String date) {
    return 'Blocker · $date';
  }

  @override
  String dprNudgeReminder(int hour) {
    return 'Reminder: submit today\'s DPR (nudge after $hour:00).';
  }

  @override
  String pmDigestShareHeader(String projectName) {
    return 'PM DIGEST — $projectName';
  }

  @override
  String pmDigestGenerated(String iso) {
    return 'Generated: $iso';
  }

  @override
  String pmDigestOpenIssues(int count) {
    return 'Open issues: $count';
  }

  @override
  String pmDigestOpenRfis(int count) {
    return 'Open RFIs: $count';
  }

  @override
  String get pmDigestTodayMissing => 'Today DPR: missing / not submitted';

  @override
  String get pmDigestTodayOk => 'Today DPR: ok';

  @override
  String shareSnackSystem(String kind) {
    return '$kind opened in the system share sheet';
  }

  @override
  String shareSnackClipboard(String kind) {
    return '$kind copied — paste into WhatsApp or email';
  }

  @override
  String get shareKindDigestPdf => 'Digest PDF';

  @override
  String get shareKindDigest => 'Digest';

  @override
  String get shareKindDocumentSummary => 'Document summary';

  @override
  String get shareKindDprPdf => 'DPR PDF';

  @override
  String get shareKindDprSummary => 'DPR summary';

  @override
  String get shareKindPilotPdf => 'Pilot PDF';

  @override
  String get shareKindPilotSnapshot => 'Pilot snapshot';

  @override
  String get shareKindWeeklyPdf => 'Weekly PDF';

  @override
  String get shareKindWeeklyProgress => 'Weekly progress';

  @override
  String get conflictLastWriteWins => 'Last write wins on scalar fields';

  @override
  String get conflictAppendOnly => 'Append-only for comments and photos';

  @override
  String get conflictAuditedStatus =>
      'Status changes are audited; illegal transitions rejected';

  @override
  String get notifyIssueAssigned => 'Issue assigned';

  @override
  String get notifyIssueStatusUpdated => 'Issue status updated';

  @override
  String get notifyRfiAssigned => 'RFI assigned';

  @override
  String get notifyRfiStatusUpdated => 'RFI status updated';

  @override
  String get notifyDprSubmitted => 'DPR submitted';

  @override
  String get notifyFieldUpdate => 'Field update';

  @override
  String get notifyOpenAppForDetails => 'Open the app for details';

  @override
  String get issueStatusOpen => 'Open';

  @override
  String get issueStatusInProgress => 'In Progress';

  @override
  String get issueStatusResolved => 'Resolved';

  @override
  String get issueStatusClosed => 'Closed';

  @override
  String get roleLabelSiteEngineer => 'Site Engineer';

  @override
  String get roleLabelProjectManager => 'Project Manager';

  @override
  String get roleLabelQaQc => 'QA/QC';

  @override
  String get roleLabelClient => 'Client';

  @override
  String get roleLabelAdmin => 'Admin';

  @override
  String shareSubjectPmDigest(String projectName) {
    return 'PM digest — $projectName';
  }

  @override
  String shareSubjectDpr(String date, String projectName) {
    return 'DPR $date — $projectName';
  }

  @override
  String shareSubjectWeekly(String projectName) {
    return 'Weekly progress — $projectName';
  }

  @override
  String shareSubjectPilot(String projectName) {
    return 'Pilot snapshot — $projectName';
  }

  @override
  String get dprShareHeader => 'DAILY PROGRESS REPORT';

  @override
  String dprShareProject(String projectName) {
    return 'Project: $projectName';
  }

  @override
  String dprShareDate(String date) {
    return 'Date: $date';
  }

  @override
  String dprShareBy(String name) {
    return 'By: $name';
  }

  @override
  String dprShareWeather(String value) {
    return 'Weather: $value';
  }

  @override
  String dprShareManpower(String value) {
    return 'Manpower: $value';
  }

  @override
  String get dprShareActivities => 'Activities:';

  @override
  String dprShareLocationPart(String location) {
    return ' @ $location';
  }

  @override
  String dprSharePhotoPart(int count) {
    return ' ($count photo)';
  }

  @override
  String dprShareBlockers(String value) {
    return 'Blockers: $value';
  }

  @override
  String weeklyShareHeader(String projectName) {
    return 'WEEKLY PROGRESS — $projectName';
  }

  @override
  String weeklyShareWeek(String range) {
    return 'Week: $range';
  }

  @override
  String weeklyShareGenerated(String iso) {
    return 'Generated: $iso';
  }

  @override
  String weeklyShareSubmittedDays(int count) {
    return 'Submitted DPR days: $count / 7';
  }

  @override
  String weeklyShareOpenIssuesCount(int count) {
    return 'Open issues: $count';
  }

  @override
  String get weeklyShareEmptyWeek => 'No submitted DPRs in this ISO week yet.';

  @override
  String weeklyShareDayLine(String date, String weather, String manpower) {
    return '$date · weather $weather · manpower $manpower';
  }

  @override
  String weeklyShareDayBlockers(String blockers) {
    return '  Blockers: $blockers';
  }

  @override
  String get weeklyShareBlockersThisWeek => 'Blockers this week:';

  @override
  String get weeklyShareOpenIssues => 'Open issues:';

  @override
  String pilotShareHeader(String projectName) {
    return 'PILOT SNAPSHOT — $projectName';
  }

  @override
  String pilotShareGenerated(String iso) {
    return 'Generated: $iso';
  }

  @override
  String pilotShareDprDays(int days, String status) {
    return 'DPR days submitted (ISO week): $days (target >=4) $status';
  }

  @override
  String pilotShareDprSubmitMedian(String median, int n, String status) {
    return 'DPR submit median: $median (n=$n, target <3m) $status';
  }

  @override
  String pilotShareIssueCreateMedian(String median, int n, String status) {
    return 'Issue create median: $median (n=$n, target <90s) $status';
  }

  @override
  String pilotShareOpenIssues(int count) {
    return 'Open issues: $count';
  }

  @override
  String pilotSharePendingSync(int count) {
    return 'Pending sync: $count';
  }

  @override
  String pilotShareSyncErrors(
    int errors,
    int logs,
    String ratePart,
    String status,
  ) {
    return 'Sync errors: $errors / $logs$ratePart (target <2%) $status';
  }

  @override
  String pilotShareSyncRatePart(String percent) {
    return ' ($percent%)';
  }

  @override
  String pilotShareUat(int done, int total) {
    return 'UAT checklist: $done / $total';
  }

  @override
  String get pilotStatusOk => 'OK';

  @override
  String get pilotStatusBelow => 'BELOW';

  @override
  String get pilotStatusWatch => 'WATCH';

  @override
  String pilotStatusNeedSamples(int count) {
    return 'NEED $count+';
  }

  @override
  String documentShareType(String contentType) {
    return 'Type: $contentType';
  }

  @override
  String get documentShareOnDevice => 'On device / demo local path';

  @override
  String documentShareUrl(String url) {
    return 'URL: $url';
  }
}
