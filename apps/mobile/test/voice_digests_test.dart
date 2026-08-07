import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/core/constants/app_constants.dart';
import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/auth/domain/auth_models.dart';
import 'package:construction_field_app/features/digests/data/local_digests_repository.dart';
import 'package:construction_field_app/features/digests/domain/digest_models.dart';
import 'package:construction_field_app/features/digests/presentation/digests_providers.dart';
import 'package:construction_field_app/features/dpr/data/local_dpr_repository.dart';
import 'package:construction_field_app/features/dpr/domain/dpr_models.dart';
import 'package:construction_field_app/features/issues/data/local_field_records_repository.dart';
import 'package:construction_field_app/features/issues/domain/issue_models.dart';
import 'package:construction_field_app/features/voice_notes/data/local_voice_notes_repository.dart';
import 'package:construction_field_app/features/voice_notes/domain/voice_note_models.dart';
import 'package:construction_field_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));

  late SharedPreferences prefs;
  late AuthSession engineer;
  late AuthSession pm;
  late AuthSession client;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(prefs);
    engineer = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    await auth.signOut();
    pm = await auth.signInWithEmail(
      email: 'pm@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    await auth.signOut();
    client = await auth.signInWithEmail(
      email: 'client@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
  });

  test('demo voice note attaches to issue; client blocked', () async {
    final voices = LocalVoiceNotesRepository(prefs);
    final note = await voices.addDemoVoiceNote(
      session: engineer,
      parentType: VoiceParentType.issue,
      parentId: 'issue_1',
    );
    expect(note.audioLocalPath, contains('local://demo/voice_'));
    expect(note.transcript, isNotEmpty);
    expect(note.transcriptPending, isFalse);

    final listed = await voices.listForParent(
      parentType: VoiceParentType.issue,
      parentId: 'issue_1',
    );
    expect(listed, hasLength(1));

    expect(
      () => voices.addDemoVoiceNote(
        session: client,
        parentType: VoiceParentType.issue,
        parentId: 'issue_1',
      ),
      throwsA(isA<VoiceNotesException>()),
    );
  });

  test('offline voice note marks transcript pending', () async {
    final voices = LocalVoiceNotesRepository(prefs);
    final note = await voices.addDemoVoiceNote(
      session: engineer,
      parentType: VoiceParentType.dpr,
      parentId: 'dpr_1',
      offline: true,
    );
    expect(note.transcriptPending, isTrue);
  });

  test('5 PM nudge fires when DPR missing after due hour', () {
    final nudge = evaluateDprNudge(
      prefs: const DigestPrefs(dprNudgeEnabled: true, nudgeHourLocal: 17),
      todaySubmitted: false,
      l10n: en,
      now: DateTime(2026, 8, 6, 17, 5),
    );
    expect(nudge, isNotNull);
    expect(nudge!.dueHourLocal, 17);

    final early = evaluateDprNudge(
      prefs: const DigestPrefs(),
      todaySubmitted: false,
      l10n: en,
      now: DateTime(2026, 8, 6, 10),
    );
    expect(early, isNull);

    final done = evaluateDprNudge(
      prefs: const DigestPrefs(),
      todaySubmitted: true,
      l10n: en,
      now: DateTime(2026, 8, 6, 18),
    );
    expect(done, isNull);
  });

  test('PM digest aggregates open issues, RFIs, and blockers', () async {
    final fields = LocalFieldRecordsRepository(prefs);
    final dprs = LocalDprRepository(prefs);

    await fields.createIssue(
      session: engineer,
      input: const CreateIssueInput(
        title: 'Leak at shaft',
        description: 'Water ingress',
      ),
    );
    await fields.createRfi(
      session: engineer,
      input: const CreateRfiInput(
        subject: 'Rebar diameter?',
        question: 'Confirm 12mm vs 16mm',
      ),
    );
    await dprs.createOrUpdateToday(
      session: engineer,
      input: CreateDprInput(
        weather: 'Rain',
        manpowerSummary: '20',
        activities: [
          const DprActivity(id: 'a1', description: 'Formwork'),
        ],
        blockers: 'Crane down',
      ),
    );

    final issues = await fields.watchIssues(engineer.activeProjectId).first;
    final rfis = await fields.watchRfis(engineer.activeProjectId).first;
    final reports = await dprs.watchDprs(engineer.activeProjectId).first;

    final digest = buildPmDigest(
      session: pm,
      issues: issues,
      rfis: rfis,
      dprs: reports,
      l10n: en,
      now: DateTime.now(),
    );

    expect(digest.openIssueCount, greaterThanOrEqualTo(1));
    expect(digest.openRfiCount, greaterThanOrEqualTo(1));
    expect(digest.missingTodayDpr, isTrue);
    expect(
      digest.items.any((i) => i.kind == DigestItemKind.dprBlocker),
      isTrue,
    );
    expect(digest.toShareText(projectName: 'Pune Tower A', l10n: en), contains('PM DIGEST'));
    expect(canViewPmDigest(AppRole.projectManager), isTrue);
    expect(canViewPmDigest(AppRole.siteEngineer), isFalse);
  });

  test('digest prefs persist', () async {
    final repo = LocalDigestsRepository(prefs);
    expect(repo.getPrefs().dprNudgeEnabled, isTrue);
    await repo.setPrefs(
      const DigestPrefs(dprNudgeEnabled: false, pmDigestEnabled: false),
    );
    expect(repo.getPrefs().dprNudgeEnabled, isFalse);
    expect(repo.getPrefs().pmDigestEnabled, isFalse);
  });
}
