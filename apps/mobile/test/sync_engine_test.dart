import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/features/auth/data/fake_auth_repository.dart';
import 'package:construction_field_app/features/issues/data/local_field_records_repository.dart';
import 'package:construction_field_app/features/issues/domain/issue_models.dart';
import 'package:construction_field_app/sync/conflict/conflict_policy.dart';
import 'package:construction_field_app/sync/local_sync_engine.dart';
import 'package:construction_field_app/sync/sync_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('conflict policy maps collections and fields', () {
    expect(
      ConflictPolicy.forCollection('comments'),
      ConflictStrategy.appendOnly,
    );
    expect(
      ConflictPolicy.forField('issues', 'status'),
      ConflictStrategy.auditedStatus,
    );
    expect(
      ConflictPolicy.forField('issues', 'title'),
      ConflictStrategy.lastWriteWins,
    );
  });

  test('sync engine flushes outbox and writes logs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final field = LocalFieldRecordsRepository(prefs);
    final engine = LocalSyncEngine(prefs: prefs, fieldRecords: field);
    final auth = FakeAuthRepository(prefs);
    final session = await auth.signInWithEmail(
      email: 'engineer@demo.rayns',
      password: FakeAuthRepository.demoPassword,
    );

    await field.createIssue(
      session: session,
      input: const CreateIssueInput(title: 'Offline pour', description: ''),
    );

    final skipped = await engine.flushNow(isOnline: false);
    expect(skipped, 0);
    var logs = await engine.watchLogs().first;
    expect(logs.first.message, contains('offline'));

    final flushed = await engine.flushNow(isOnline: true);
    expect(flushed, greaterThan(0));
    logs = await engine.watchLogs().first;
    expect(logs.first.message, contains('Flushed'));
    expect(engine.lastSuccessAt, isNotNull);
    expect(await field.watchPendingSyncCount().first, 0);
  });

  test('cleanup trims old logs under retention policy', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final field = LocalFieldRecordsRepository(prefs);
    final engine = LocalSyncEngine(prefs: prefs, fieldRecords: field);

    for (var i = 0; i < 5; i++) {
      await engine.flushNow(isOnline: true);
    }
    final before = (await engine.watchLogs().first).length;
    expect(before, greaterThan(0));

    final result = await engine.runStorageCleanup();
    expect(result.removedLogEntries, greaterThanOrEqualTo(0));
    final after = (await engine.watchLogs().first).length;
    expect(after, lessThanOrEqualTo(SyncCleanupPolicy.maxLogEntries));
  });
}
