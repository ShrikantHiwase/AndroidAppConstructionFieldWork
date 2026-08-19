import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/dpr/data/local_dpr_repository.dart';
import 'package:construction_field_app/features/dpr/domain/dpr_models.dart';
import 'package:construction_field_app/features/issues/data/local_field_records_repository.dart';
import 'package:construction_field_app/features/issues/domain/issue_models.dart';
import 'package:construction_field_app/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));

  test('engineer can draft and submit today DPR with share text', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    final repo = LocalDprRepository(prefs);

    final draft = await repo.createOrUpdateToday(
      session: session,
      input: const CreateDprInput(
        weather: 'Clear',
        manpowerSummary: '40 total',
        activities: [
          DprActivity(id: 'a1', description: 'Slab pour Bay 2', hasPhoto: true),
        ],
        blockers: 'Waiting on rebar delivery',
      ),
    );
    expect(draft.submitted, isFalse);

    final submitted = await repo.submit(session: session, dprId: draft.id);
    expect(submitted.submitted, isTrue);
    final share = submitted.toShareText(
      projectName: session.activeProject.name,
      l10n: en,
    );
    expect(share, contains('DAILY PROGRESS REPORT'));
    expect(share, contains('Slab pour Bay 2'));
    expect(share, contains('Waiting on rebar'));
  });

  test('ensureSeedDprs adds yesterday submitted report without outbox', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    final repo = LocalDprRepository(prefs);

    await repo.ensureSeedDprs(session);
    final list = await repo.watchDprs(session.activeProjectId).first;
    expect(list, hasLength(1));
    expect(list.single.submitted, isTrue);
    expect(list.single.synced, isTrue);
    expect(list.single.blockers, contains('beam depth'));
    final today = await repo.todayDpr(session.activeProjectId, DateTime.now());
    expect(today, isNull);
    expect(await repo.watchPendingSyncCount().first, 0);

    await repo.ensureSeedDprs(session);
    expect(await repo.watchDprs(session.activeProjectId).first, hasLength(1));
  });

  test('client cannot edit DPR', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(prefs);
    final client = await auth.signInWithEmail(
      email: 'client@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    final repo = LocalDprRepository(prefs);
    expect(
      () => repo.createOrUpdateToday(
        session: client,
        input: const CreateDprInput(
          weather: 'x',
          manpowerSummary: 'y',
          activities: [],
          blockers: '',
        ),
      ),
      throwsA(isA<DprException>()),
    );
  });

  test('drawing pin links issue at normalized coords', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    final issues = LocalFieldRecordsRepository(prefs);
    final issue = await issues.createIssue(
      session: session,
      input: const CreateIssueInput(title: 'Crack at grid B', description: ''),
    );
    final drawings = LocalDrawingPinsRepository(prefs);
    await drawings.ensureSeedDrawings(session);
    final sheet =
        (await drawings.watchDrawings(session.activeProjectId).first).single;

    final pin = await drawings.addPin(
      session: session,
      input: CreatePinInput(
        drawingId: sheet.id,
        page: 1,
        x: 0.42,
        y: 0.55,
        issueId: issue.id,
        issueTitle: issue.title,
      ),
    );
    expect(pin.issueTitle, 'Crack at grid B');
    final pins = await drawings.watchPins(sheet.id).first;
    expect(pins.where((p) => p.issueTitle == 'Crack at grid B'), hasLength(1));
    expect(
      pins.where((p) => p.id == 'pin_seed_rebar'),
      hasLength(1),
    );
  });

  test('ensureSeedDrawings seeds rebar pin once for Pune', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    final drawings = LocalDrawingPinsRepository(prefs);
    await drawings.ensureSeedDrawings(session);
    final sheet =
        (await drawings.watchDrawings(session.activeProjectId).first).single;
    var pins = await drawings.watchPins(sheet.id).first;
    expect(pins, hasLength(1));
    expect(pins.single.id, 'pin_seed_rebar');
    expect(pins.single.issueTitle, contains('Rebar spacing'));
    expect(pins.single.synced, isTrue);
    expect(await drawings.watchPendingSyncCount().first, 0);

    await drawings.ensureSeedDrawings(session);
    pins = await drawings.watchPins(sheet.id).first;
    expect(pins, hasLength(1));
  });
}
