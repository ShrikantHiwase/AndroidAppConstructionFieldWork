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
  String get onlineBadge => 'ऑनलाइन';

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

  @override
  String get signOut => 'Sign out';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get emailRequired => 'Email ज़रूरी है';

  @override
  String get passwordRequired => 'Password ज़रूरी है';

  @override
  String get demoRoles => 'Demo roles';

  @override
  String get demoModeHint => 'Demo mode — सब accounts का password: demo1234';

  @override
  String get firebaseSignInHint => 'Org email से Sign in करो (Firebase Auth).';

  @override
  String get backendFirebase => 'Backend: Firebase';

  @override
  String get backendLocalDemo => 'Backend: local demo';

  @override
  String get permissions => 'Permissions';

  @override
  String get permCreateIssues => 'Issues बना सकते हो';

  @override
  String get permAssignWork => 'Work assign';

  @override
  String get permChangeStatus => 'Status बदलो';

  @override
  String get permApprove => 'Approve';

  @override
  String get permManageUsers => 'Users manage';

  @override
  String get permReadOnly => 'Read-only';

  @override
  String get clientReadOnlyNote =>
      'Client account field records create/edit नहीं कर सकता।';

  @override
  String get biometricUnlock => 'Biometric unlock';

  @override
  String get biometricUnlockSubtitle =>
      'App resume पर unlock चाहिए (USE_NATIVE_SENSORS=true पर local_auth)';

  @override
  String get simulateAppResumeLock => 'App resume lock simulate करो';

  @override
  String get activeProject => 'Active project';

  @override
  String get tooltipGoOnlineSync => 'Online जाओ और sync करो';

  @override
  String get tooltipSimulateOffline => 'Offline simulate करो';

  @override
  String get tooltipSyncStatus => 'Sync status';

  @override
  String get syncStatusTitle => 'Sync status';

  @override
  String get outboxEmpty => 'Outbox खाली है';

  @override
  String outboxPendingCount(int count) {
    return '$count item sync के इंतज़ार में';
  }

  @override
  String get remoteFirestore => 'Remote: Cloud Firestore (outbox push + pull)';

  @override
  String get remoteDemo => 'Remote: local demo sink (cloud write नहीं)';

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
    return 'Cleanup $bytes reclaim कर सकता है (uploaded local stubs)';
  }

  @override
  String get backgroundSync => 'Background sync';

  @override
  String get lastBackgroundFlushNever => 'Last background flush: कभी नहीं';

  @override
  String lastBackgroundFlushAt(String when, int count) {
    return 'Last background flush: $when ($count item(s))';
  }

  @override
  String get enqueueBackgroundFlush => 'Background flush enqueue करो';

  @override
  String get oneOffFlushEnqueued => 'One-off background flush enqueue हो गया';

  @override
  String get oneOffFlushFailed => 'Enqueue नहीं हुआ (Workmanager यहाँ नहीं)';

  @override
  String get backendHealth => 'Backend health';

  @override
  String get healthNotProbedFirebase =>
      'अभी probe नहीं — Cloud Functions health call करो।';

  @override
  String get healthDemoNoop => 'Demo mode local NoOp health probe use करता है।';

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
      'Crashlytics/Analytics packages अभी deferred — FlutterFire go-live तक events local रहेंगे।';

  @override
  String get telemetryDemoNoop =>
      'Demo NoOp recorder — network नहीं। Events नीचे list हैं।';

  @override
  String get pushFcm => 'Push (FCM)';

  @override
  String get registeringToken => 'Device token register हो रहा है…';

  @override
  String tokenError(String error) {
    return 'Token error: $error';
  }

  @override
  String get noTokenSignIn => 'Token नहीं (sign in ज़रूरी)';

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
      'Inbox row tap करो — related DPR / issue / RFI खुलेगा। Functions DPR submit / issue & RFI assign & status पर send करते हैं।';

  @override
  String get pushHelpDemo =>
      'Demo mode assign/status intents local log करता है जब तक FlutterFire configure न हो। Inbox rows tap करके linked screens खोलो।';

  @override
  String get noLinkedScreen => 'इस alert के लिए linked screen नहीं';

  @override
  String get flushNow => 'अभी Flush करो';

  @override
  String flushedItems(int count) {
    return '$count item flush हो गए';
  }

  @override
  String get goOnline => 'Online जाओ';

  @override
  String get goOffline => 'Offline जाओ';

  @override
  String get cleanup => 'Cleanup';

  @override
  String cleanupRemovedLogs(int logs, String mediaNote, String freed) {
    return '$logs log हटाए$mediaNote (~$freed)';
  }

  @override
  String cleanupMediaNote(int count) {
    return ', $count media path reclaim';
  }

  @override
  String get conflictPolicy => 'Conflict policy';

  @override
  String get syncLog => 'Sync log';

  @override
  String get noSyncEventsYet => 'अभी कोई sync event नहीं।';

  @override
  String get syncFooterNote =>
      'Periodic Workmanager flush (~15 min, network चाहिए) + connectivity_plus auto-flush जब device reconnect हो। Cleanup sync logs और uploaded local:// media stubs clear करता है। Drift अभी deferred।';

  @override
  String get digestsTitle => 'Digests';

  @override
  String get digestsAndReminders => 'Digests और reminders';

  @override
  String get signInRequired => 'Sign in ज़रूरी है';

  @override
  String get dailyDprNudge => 'Daily DPR nudge';

  @override
  String dailyDprNudgeSubtitle(int hour) {
    return 'आज का DPR submit न हो तो लगभग $hour:00 पर local tray reminder। Cloud FCM cron अभी deferred।';
  }

  @override
  String get reminderHour => 'Reminder hour';

  @override
  String get noDprNudgeNow => 'अभी कोई DPR nudge नहीं।';

  @override
  String get openDpr => 'DPR खोलो';

  @override
  String get simulate5PmCheck => '5 PM check simulate करो';

  @override
  String get noNudgeAlreadySubmitted =>
      'Nudge नहीं (DPR already submitted या prefs off)।';

  @override
  String get dprReminderTitle => 'DPR याद दिलाना';

  @override
  String get dprReminderBody =>
      'आज का Daily Progress Report submit करो अगर अभी नहीं किया।';

  @override
  String get pmDigests => 'PM digests';

  @override
  String get pmDigestsSubtitle =>
      'Active project के open issues, RFIs, और DPR blockers aggregate करो।';

  @override
  String get pmDigest => 'PM digest';

  @override
  String get digestUnavailableRole => 'इस role के लिए digest उपलब्ध नहीं।';

  @override
  String get pmDigestsOff => 'PM digests बंद हैं।';

  @override
  String digestSummaryLine(int issues, int rfis, String dpr) {
    return 'Open issues: $issues · Open RFIs: $rfis · Today DPR: $dpr';
  }

  @override
  String get todayDprIncomplete => 'incomplete';

  @override
  String get todayDprOk => 'ok';

  @override
  String get queueIsClear => 'Queue clear है।';

  @override
  String get shareDigestPdf => 'Digest PDF share करो';

  @override
  String get shareAsText => 'Text के रूप में share';

  @override
  String get pmDigestsStaffOnly =>
      'PM digests project managers और admins के लिए हैं।';

  @override
  String get unlockTitle => 'Field Evidence unlock करो';

  @override
  String get unlockConfirm => 'जारी रखने के लिए confirm करो कि आप ही हो।';

  @override
  String unlockWelcomeBack(String name, String hint) {
    return 'Welcome back, $name. $hint';
  }

  @override
  String get unlockHintNative => 'Device biometrics या PIN use करो।';

  @override
  String get unlockHintDemo =>
      'Demo unlock (FakeBiometricService) — USE_NATIVE_SENSORS=true तक।';

  @override
  String get unlockAction => 'Unlock';

  @override
  String get unlockFailed => 'Unlock fail हो गया';

  @override
  String get unlockReason => 'Unlock Field Evidence';

  @override
  String get syncingEllipsis => 'Sync हो रहा है…';

  @override
  String pendingCount(int count) {
    return '$count pending';
  }

  @override
  String get noIssuesYet => 'अभी कोई issue नहीं। Field से capture करो।';

  @override
  String get notSyncedSuffix => ' · not synced';

  @override
  String get titleLabel => 'Title';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get requiredField => 'ज़रूरी है';

  @override
  String get evidence => 'Evidence';

  @override
  String get sensorsNativeHint =>
      'Device GPS / camera use हो रहा है (USE_NATIVE_SENSORS).';

  @override
  String get sensorsDemoHint =>
      'Demo sensors — --dart-define=USE_NATIVE_SENSORS=true से enable करो';

  @override
  String get addGps => 'GPS जोड़ो';

  @override
  String get refreshGps => 'GPS refresh करो';

  @override
  String get clearGps => 'GPS हटाओ';

  @override
  String get addPhoto => 'Photo जोड़ो';

  @override
  String get fromGallery => 'Gallery से';

  @override
  String get queuedForUpload => 'Upload queue में';

  @override
  String get uploadedStatus => 'Uploaded';

  @override
  String get onDeviceStatus => 'Device पर';

  @override
  String get syncedDemoStatus => 'Synced (demo)';

  @override
  String get saveIssue => 'Issue save करो';

  @override
  String get savesOfflineHint => 'Offline तुरंत save; online पर sync।';

  @override
  String get issueNoun => 'Issue';

  @override
  String get issueNotFound => 'Issue नहीं मिला';

  @override
  String get noDescription => 'Description नहीं';

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
  String get assignToAsha => 'Asha Patil को assign करो';

  @override
  String get statusHistory => 'Status history';

  @override
  String get comments => 'Comments';

  @override
  String get noCommentsYet => 'अभी कोई comment नहीं।';

  @override
  String get addComment => 'Comment जोड़ो';

  @override
  String get postComment => 'Comment post करो';

  @override
  String get pendingLabel => 'pending';

  @override
  String get syncedLabel => 'synced';

  @override
  String get rfisTitle => 'RFIs';

  @override
  String get newRfi => 'नया RFI';

  @override
  String get noRfisYet => 'अभी कोई RFI नहीं।';

  @override
  String get subjectLabel => 'Subject';

  @override
  String get questionLabel => 'Question';

  @override
  String get submitRfi => 'RFI submit करो';

  @override
  String get rfiNoun => 'RFI';

  @override
  String get rfiNotFound => 'RFI नहीं मिला';

  @override
  String get threadedResponses => 'Threaded responses';

  @override
  String get addResponse => 'Response जोड़ो';

  @override
  String get postResponse => 'Response post करो';

  @override
  String get dailyProgress => 'Daily Progress';

  @override
  String get noDprsYet =>
      'अभी कोई DPR नहीं। आज का progress ~3 min में capture करो।';

  @override
  String get submittedLabel => 'Submitted';

  @override
  String get draftLabel => 'Draft';

  @override
  String activitiesCount(int count) {
    return '$count activities';
  }

  @override
  String get alreadySubmittedViewOnly => 'पहले से submit — सिर्फ देख सकते हो।';

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
    return '$label · $size (अगली activity से attach)';
  }

  @override
  String get blockersLabel => 'Blockers';

  @override
  String get saveDraftForVoice =>
      'आज के DPR पर voice notes के लिए एक बार draft save करो।';

  @override
  String get saveDraft => 'Draft save करो';

  @override
  String get submitDpr => 'DPR submit करो';

  @override
  String get dprNoun => 'DPR';

  @override
  String get dprNotFound => 'DPR नहीं मिला';

  @override
  String get sharePdf => 'PDF share करो';

  @override
  String get sharePdfTooltip => 'PDF share करो';

  @override
  String get shareTextTooltip => 'Text summary share करो';

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
      'PDF और text system share sheet खोलते हैं (WhatsApp, email, आदि)।';

  @override
  String get noEvidencePhoto => 'Evidence photo नहीं';

  @override
  String get evidencePhotoQueued => 'Evidence photo · upload queue';

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
  String get logSafety => 'Safety log करो';

  @override
  String get wirChecklist => 'WIR checklist';

  @override
  String get muster => 'Muster';

  @override
  String get grnUse => 'GRN / use';

  @override
  String get noSafetyRecordsYet => 'अभी कोई safety record नहीं।';

  @override
  String get noInspectionsYet => 'अभी कोई inspection नहीं।';

  @override
  String get noLabourMusterYet => 'अभी labour muster नहीं (supervisor-led).';

  @override
  String get noMaterialLogsYet => 'अभी कोई material log नहीं।';

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
  String get save => 'Save करो';

  @override
  String get retry => 'फिर से try करो';

  @override
  String get signOutConfirmTitle => 'Sign out करें?';

  @override
  String get signOutConfirmBody =>
      'Unsynced items इसी device पर safe रहेंगे, sign in के बाद sync हो जाएंगे।';

  @override
  String get submitDprConfirmTitle => 'आज का DPR submit करें?';

  @override
  String get submitDprConfirmBody =>
      'Submit के बाद DPR lock हो जाएगा, फिर edit नहीं होगा।';

  @override
  String get emailInvalid => 'सही email address डालें';

  @override
  String get showPassword => 'Password दिखाओ';

  @override
  String get hidePassword => 'Password छिपाओ';

  @override
  String get photoRequiredObservation =>
      'Observation / incident के लिए photo evidence ज़रूरी।';

  @override
  String get photoOptionalToolbox => 'Toolbox talk के लिए photo optional।';

  @override
  String get queuedLabel => 'Queued';

  @override
  String queuedWithSize(String size) {
    return 'Queued · ~$size';
  }

  @override
  String get photoRequiredForFail => 'Fail checklist items के लिए photo ज़रूरी';

  @override
  String inspectionSavedWithFailPhoto(String size) {
    return 'Inspection fail photo के साथ save हो गई$size';
  }

  @override
  String get musterDialogHint =>
      'Civil · Shree Contractors · 18 geofence check के साथ log। Photo optional।';

  @override
  String get logMuster => 'Muster log करो';

  @override
  String get materialDialogHint =>
      'GRN inward या consumption lite। Photo optional।';

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
  String get noDocumentFoldersYet => 'अभी कोई document folder नहीं।';

  @override
  String get emptyFolderUploadHint =>
      'Folder खाली है। शुरू करने के लिए file upload करो।';

  @override
  String get uploadDocument => 'Document upload करो';

  @override
  String get fileNameLabel => 'File name';

  @override
  String get typeLabel => 'Type';

  @override
  String get pickFile => 'File pick करो';

  @override
  String get pickDemoFile => 'Demo file pick करो';

  @override
  String get previewNotesLabel => 'Preview / notes';

  @override
  String get contentPreviewLabel => 'Content preview';

  @override
  String get uploadAction => 'Upload';

  @override
  String get uploadHintNative =>
      'Device से file pick करो, या typed preview के साथ upload। Flush पर paths Firebase Storage पर जाते हैं (जब configure हो).';

  @override
  String get uploadHintDemo =>
      'Demo file pick से local:// stub + preview मिलता है। Flush पर demo:// Storage URLs। Native pick: --dart-define=USE_NATIVE_SENSORS=true.';

  @override
  String get documentNoun => 'Document';

  @override
  String get documentNotFound => 'Document नहीं मिला';

  @override
  String get downloadTooltip => 'Download';

  @override
  String get savedOnDevice => 'Device पर save हो गया';

  @override
  String get shareDocumentSummaryTooltip => 'Document summary share करो';

  @override
  String get searchLabel => 'Search';

  @override
  String get pdfrxViewerHint =>
      'PDF viewer (pdfrx) — pinch zoom, pages scroll.';

  @override
  String get drawingsTitle => 'Drawings';

  @override
  String get noDrawingsSeededYet => 'अभी कोई drawing seed नहीं।';

  @override
  String drawingPagesCount(String version, int count) {
    return '$version · $count pages';
  }

  @override
  String get drawingNoun => 'Drawing';

  @override
  String get drawingNotFound => 'Drawing नहीं मिला';

  @override
  String get linkIssue => 'Issue link करो';

  @override
  String get tapToDropPin =>
      'Issue link के बाद sheet पर tap करके punch pin डालो।';

  @override
  String get selectIssueFirst => 'पहले issue select करो';

  @override
  String get pinDropped => 'Pin drop हो गया';

  @override
  String get createIssueFirst => 'पहले issue बनाओ';

  @override
  String get selectIssueToPin => 'Pin के लिए issue select करो';

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
    return '$title\n$version\nPage $page\n\nPunch pin डालने के लिए tap करो$issueHint$photoHint.';
  }

  @override
  String get selectIssueFirstParen => ' (पहले issue select करो)';

  @override
  String get withEvidencePhoto => ' evidence photo के साथ';

  @override
  String pinnedIssueSnack(String title, String photoNote) {
    return '\"$title\" pin हो गया$photoNote';
  }

  @override
  String get plusEvidencePhoto => ' + evidence photo';

  @override
  String get pilotUatTitle => 'Pilot / UAT';

  @override
  String get pilotHubRestricted => 'Pilot hub PM और Admin के लिए है।';

  @override
  String get resetUatChecklistTitle => 'UAT checklist reset करें?';

  @override
  String get resetUatChecklistBody =>
      'इस device पर सारे local ticks clear हो जाएंगे।';

  @override
  String get resetAction => 'Reset';

  @override
  String get hypercareSnapshot => 'Hypercare snapshot';

  @override
  String get hypercareTargetsHint =>
      'Targets: DPR >=4 days this week · DPR submit median <3m · issue create median <90s · sync errors <2%. Full guide: docs/Hypercare_Metrics.md';

  @override
  String get noSnapshot => 'अभी कोई snapshot नहीं';

  @override
  String get sharePilotPdf => 'Pilot PDF share करो';

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
      'docs/UAT_Checklist.md mirror — device पर verify करते हुए tick करो।';

  @override
  String get weeklyProgressRoleGate =>
      'Weekly progress clients, PMs, और admins के लिए उपलब्ध है।';

  @override
  String get progressPackUnavailable => 'Progress pack उपलब्ध नहीं।';

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
      'इस ISO week में अभी कोई submitted DPR नहीं। Share फिर भी काम करता है ताकि client empty pack बिना PM compile खोल सके।';

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
  String get shareWeeklyPdf => 'Weekly PDF share करो';

  @override
  String get invitesTitle => 'Invites';

  @override
  String get inviteUsersTitle => 'Invite users';

  @override
  String get adminOnly => 'सिर्फ Admin';

  @override
  String get createInvite => 'Invite बनाओ';

  @override
  String get firebaseInviteHint =>
      'Firebase Auth user + memberships inviteMember callable से (temporary password demo1234 जब तक email delivery wire न हो).';

  @override
  String get demoInviteHint =>
      'Invitees email + password demo1234 से sign in (local demo). Firebase on होने पर वही form Cloud Functions call करता है।';

  @override
  String get roleSectionLabel => 'Role';

  @override
  String get projectsSectionLabel => 'Projects';

  @override
  String get sendInvite => 'Invite भेजो';

  @override
  String get invitesSection => 'Invites';

  @override
  String get noInvitesYet => 'अभी कोई invite नहीं।';

  @override
  String get copySignInHintTooltip => 'Sign-in hint copy करो';

  @override
  String get inviteHintCopied => 'Invite hint copy हो गया';

  @override
  String inviteCreatedFirebase(String email) {
    return '$email के लिए invite बन गया। Temp password: demo1234';
  }

  @override
  String inviteCreatedDemo(String email) {
    return '$email के लिए invite बन गया। Password: demo1234';
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
  String get noSession => 'Session नहीं है';

  @override
  String get voiceNotesTitle => 'Voice notes';

  @override
  String get voiceNotesHintNative =>
      'Live mic capture; flush audio Storage पर और transcript Firestore पर sync करता है।';

  @override
  String get voiceNotesHintDemo =>
      'Demo capture audio stub + transcript store करता है; flush Firestore/Storage पर sync करता है। Live mic: --dart-define=USE_NATIVE_SENSORS=true.';

  @override
  String get noVoiceNotesYet => 'अभी कोई voice note नहीं।';

  @override
  String get transcriptPendingPart => ' · transcript pending';

  @override
  String get audioReadyPart => ' · audio ready';

  @override
  String get recordingVoiceNoteTitle => 'Voice note record हो रहा है';

  @override
  String get recordingVoiceNoteBody => 'बोलो, फिर Stop दबाओ (max 60s).';

  @override
  String get stopAction => 'Stop';

  @override
  String get recordVoiceOffline => 'Voice record करो (offline)';

  @override
  String get addDemoVoiceOffline => 'Demo voice जोड़ो (offline)';

  @override
  String get recordVoiceNote => 'Voice note record करो';

  @override
  String get addDemoVoiceNote => 'Demo voice note जोड़ो';

  @override
  String get disciplineFolderKind => 'Discipline';

  @override
  String get documentTypeFolderKind => 'Document type';

  @override
  String get onDevicePart => ' · device पर';

  @override
  String get cloudPart => ' · cloud';

  @override
  String pageOfTotal(int current, int total) {
    return 'Page $current / $total';
  }

  @override
  String get noPdfPreview => 'PDF preview उपलब्ध नहीं।';

  @override
  String get textPdfPreviewHint =>
      'Text PDF preview — pdfrx के लिए seeded या on-device PDF खोलो।';

  @override
  String get noPreviewForFileType => 'इस file type के लिए preview उपलब्ध नहीं।';

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
    return 'Muster log हो गया (geofence OK)$photoNote';
  }

  @override
  String musterLoggedMiss(String photoNote) {
    return 'Muster log हो गया (geofence MISS)$photoNote';
  }

  @override
  String materialInwardLogged(String photoNote) {
    return 'Material inward log हो गया$photoNote';
  }

  @override
  String materialConsumptionLogged(String photoNote) {
    return 'Material consumption log हो गया$photoNote';
  }

  @override
  String get todaysDprIncomplete => 'आज का DPR अधूरा है';

  @override
  String get noDraftYet => 'अभी कोई draft नहीं';

  @override
  String get draftNotSubmitted => 'Draft submit नहीं हुआ';

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
    return 'Reminder: आज का DPR submit करो ($hour:00 के बाद nudge).';
  }

  @override
  String pmDigestShareHeader(String projectName) {
    return 'PM DIGEST — $projectName';
  }

  @override
  String pmDigestGenerated(String iso) {
    return 'बनाया: $iso';
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
  String get pmDigestTodayMissing => 'Today DPR: missing / submit नहीं हुआ';

  @override
  String get pmDigestTodayOk => 'Today DPR: ok';

  @override
  String shareSnackSystem(String kind) {
    return '$kind system share sheet में खुला';
  }

  @override
  String shareSnackClipboard(String kind) {
    return '$kind copy हो गया — WhatsApp या email में paste करो';
  }

  @override
  String get shareKindDigestPdf => 'Digest PDF';

  @override
  String get shareKindDigest => 'Digest';

  @override
  String get shareKindDocumentSummary => 'Document का summary';

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
  String get conflictLastWriteWins => 'Scalar fields पर last write wins';

  @override
  String get conflictAppendOnly => 'Comments और photos append-only';

  @override
  String get conflictAuditedStatus =>
      'Status changes audit होते हैं; illegal transitions reject';

  @override
  String get notifyIssueAssigned => 'Issue assign हो गया';

  @override
  String get notifyIssueStatusUpdated => 'Issue status update हुआ';

  @override
  String get notifyRfiAssigned => 'RFI assign हो गया';

  @override
  String get notifyRfiStatusUpdated => 'RFI status update हुआ';

  @override
  String get notifyDprSubmitted => 'DPR submit हो गया';

  @override
  String get notifyFieldUpdate => 'Field update';

  @override
  String get notifyOpenAppForDetails => 'Details के लिए app खोलो';

  @override
  String get issueStatusOpen => 'Open';

  @override
  String get issueStatusInProgress => 'In Progress (चल रहा)';

  @override
  String get issueStatusResolved => 'Resolved (हल)';

  @override
  String get issueStatusClosed => 'Closed';

  @override
  String get roleLabelSiteEngineer => 'Site Engineer (साइट)';

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
    return 'तारीख: $date';
  }

  @override
  String dprShareBy(String name) {
    return 'द्वारा: $name';
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
    return 'बनाया: $iso';
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
  String get weeklyShareEmptyWeek =>
      'इस ISO week में अभी कोई submitted DPR नहीं।';

  @override
  String weeklyShareDayLine(String date, String weather, String manpower) {
    return '$date · weather $weather · manpower $manpower';
  }

  @override
  String weeklyShareDayBlockers(String blockers) {
    return '  Blockers: $blockers';
  }

  @override
  String get weeklyShareBlockersThisWeek => 'इस week के blockers:';

  @override
  String get weeklyShareOpenIssues => 'Open issues:';

  @override
  String pilotShareHeader(String projectName) {
    return 'PILOT SNAPSHOT — $projectName';
  }

  @override
  String pilotShareGenerated(String iso) {
    return 'बनाया: $iso';
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
  String get documentShareOnDevice => 'Device / demo local path पर';

  @override
  String documentShareUrl(String url) {
    return 'URL: $url';
  }

  @override
  String get pdfDigestTitle => 'PM DIGEST';

  @override
  String get pdfWeeklyTitle => 'WEEKLY PROGRESS';

  @override
  String get pdfPilotTitle => 'PILOT / HYPERCARE';

  @override
  String pdfPageOf(int page, int pages) {
    return 'पेज $page / $pages';
  }

  @override
  String get pdfStatus => 'Status';

  @override
  String get pdfGenerated => 'Generated';

  @override
  String get pdfQueue => 'Queue';

  @override
  String get pdfNoneRecorded => 'कुछ record नहीं।';

  @override
  String get pdfDailyHighlights => 'Daily highlights';

  @override
  String get pdfTodayDpr => 'Today DPR';

  @override
  String get pdfOpenIssues => 'Open issues';

  @override
  String get pdfOpenRfis => 'Open RFIs';

  @override
  String get pdfSubmittedDprDays => 'Submitted DPR days';

  @override
  String get pdfDprDays => 'DPR days';

  @override
  String get pdfDprSubmit => 'DPR submit';

  @override
  String get pdfIssueCreate => 'Issue create';

  @override
  String get pdfPendingSync => 'Pending sync';

  @override
  String get pdfSyncErrors => 'Sync errors';

  @override
  String get pdfUatChecklist => 'UAT checklist';

  @override
  String get pdfNa => 'n/a';

  @override
  String get pdfDate => 'तारीख';

  @override
  String get pdfBy => 'द्वारा';

  @override
  String get pdfWeather => 'Weather';

  @override
  String get pdfManpower => 'Manpower';

  @override
  String get pdfActivities => 'Activities';

  @override
  String get pdfBlockers => 'Blockers';

  @override
  String get pdfWeek => 'Week';

  @override
  String pdfWeatherManpowerLine(String weather, String manpower) {
    return 'Weather: $weather · Manpower: $manpower';
  }

  @override
  String pdfBlockersLine(String blockers) {
    return 'Blockers: $blockers';
  }

  @override
  String pdfMetricLine(String value, String target, String status) {
    return '$value (target $target) $status';
  }

  @override
  String pdfSyncErrorsLine(int errors, int logs, String rate, String status) {
    return '$errors / $logs ($rate, target <2%) $status';
  }

  @override
  String pdfCountOfTotal(int done, int total) {
    return '$done / $total';
  }

  @override
  String pdfSubmittedDaysValue(int count) {
    return '$count / 7';
  }

  @override
  String pdfDprDaysValue(int days, String status) {
    return '$days (target >=4) $status';
  }

  @override
  String pdfMedianValue(String median, int n, String target, String status) {
    return '$median (n=$n, target $target) $status';
  }

  @override
  String get pdfTodayDprMissing => 'missing / submit नहीं हुआ';

  @override
  String get pdfTodayDprOk => 'ok';

  @override
  String get errClientReadOnly => 'Client accounts read-only हैं';

  @override
  String get errClientReadOnlySiteOps =>
      'Client accounts site ops के लिए read-only हैं';

  @override
  String get errClientCannotEditDpr => 'Client accounts DPR edit नहीं कर सकते';

  @override
  String get errClientCannotSubmitDpr =>
      'Client accounts DPR submit नहीं कर सकते';

  @override
  String get errClientCannotPin =>
      'Client accounts drawings पर pin नहीं कर सकते';

  @override
  String get errClientCannotVoice =>
      'Client accounts voice notes नहीं जोड़ सकते';

  @override
  String get errCannotAssign => 'आपके role को assign करने की अनुमति नहीं';

  @override
  String get errCannotChangeStatus =>
      'आपके role को status change की अनुमति नहीं';

  @override
  String get errCannotUploadDocs =>
      'आपके role को documents upload की अनुमति नहीं';

  @override
  String get errCannotManageFolders =>
      'आपके role को folders manage करने की अनुमति नहीं';

  @override
  String get errOnlyAdminsInvite => 'केवल admins users invite कर सकते हैं';

  @override
  String get errTitleRequired => 'Title ज़रूरी है';

  @override
  String get errSubjectRequired => 'Subject ज़रूरी है';

  @override
  String get errFileNameRequired => 'File name ज़रूरी है';

  @override
  String get errCommentEmpty => 'Comment खाली नहीं हो सकता';

  @override
  String get errIssueNotFound => 'Issue नहीं मिला';

  @override
  String get errIssueWrongProject => 'Issue active project में नहीं है';

  @override
  String get errRfiNotFound => 'RFI नहीं मिला';

  @override
  String get errDprNotFound => 'DPR नहीं मिला';

  @override
  String get errDprWrongProject => 'DPR active project में नहीं है';

  @override
  String get errDprAlreadySubmitted => 'आज का DPR पहले ही submit हो चुका है';

  @override
  String get errDprNeedActivity => 'Submit से पहले कम से कम एक activity जोड़ो';

  @override
  String get errDocumentNotFound => 'Document नहीं मिला';

  @override
  String get errFolderNotFound => 'Active project में folder नहीं मिला';

  @override
  String get errParentFolderNotFound => 'Parent folder नहीं मिला';

  @override
  String get errDrawingNotFound => 'Drawing नहीं मिला';

  @override
  String get errPageOutOfRange => 'Page range से बाहर है';

  @override
  String get errPinOutOfBounds => 'Pin drawing page के अंदर होना चाहिए';

  @override
  String get errParentRequired => 'Parent record ज़रूरी है';

  @override
  String get errAudioPathRequired => 'Audio path ज़रूरी है';

  @override
  String get errChecklistItemsRequired => 'Checklist items जोड़ो';

  @override
  String get errHeadcountInvalid => 'Headcount > 0 होना चाहिए';

  @override
  String get errMaterialRequired => 'Material ज़रूरी है';

  @override
  String get errQuantityInvalid => 'Quantity > 0 होना चाहिए';

  @override
  String errPhotoEvidenceRequired(String kind) {
    return '$kind के लिए photo evidence ज़रूरी है';
  }

  @override
  String errPhotoRequiredOnFail(String label) {
    return 'Fail पर photo ज़रूरी: $label';
  }

  @override
  String get errEmailRequired => 'Valid email ज़रूरी है';

  @override
  String get errSelectProject => 'कम से कम एक project चुनो';

  @override
  String errUnknownProject(String id) {
    return 'Unknown project: $id';
  }

  @override
  String errPendingInviteExists(String email) {
    return '$email के लिए pending invite पहले से है';
  }

  @override
  String get errInviteMissingId => 'Invite बना पर inviteId नहीं मिला';

  @override
  String errCannotMoveStatus(String from, String to) {
    return '$from से $to में move नहीं हो सकता';
  }

  @override
  String get errRemoteFailure => 'Remote request fail हो गया';
}
