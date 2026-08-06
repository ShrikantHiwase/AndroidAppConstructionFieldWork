import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/issues/data/local_field_records_repository.dart';
import 'package:construction_field_app/features/issues/domain/issue_models.dart';
import 'package:construction_field_app/sync/background/background_outbox_flush.dart';
import 'package:construction_field_app/sync/background/background_sync_scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('runBackgroundOutboxFlush clears pending issue outbox', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final field = LocalFieldRecordsRepository(prefs);
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );
    await prefs.setString('auth.active_project', session.activeProjectId);

    await field.createIssue(
      session: session,
      input: const CreateIssueInput(title: 'BG sync pour', description: ''),
    );
    expect(await field.watchPendingSyncCount().first, greaterThan(0));

    final result = await runBackgroundOutboxFlush(prefs: prefs);
    expect(result.error, isNull);
    expect(result.flushed, greaterThan(0));

    // Fresh load from prefs (background isolate uses its own in-memory maps).
    final reloaded = LocalFieldRecordsRepository(prefs);
    expect(await reloaded.watchPendingSyncCount().first, 0);

    final meta = BackgroundSyncMeta.fromPrefs(prefs);
    expect(meta.lastAt, isNotNull);
    expect(meta.lastFlushed, greaterThan(0));
  });

  test('BackgroundSyncScheduler initialize is safe in tests', () async {
    const scheduler = BackgroundSyncScheduler();
    // May return false without platform channels — must not throw.
    final ok = await scheduler.initialize();
    expect(ok, anyOf(isTrue, isFalse));
  });
}
