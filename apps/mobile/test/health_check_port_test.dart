import 'package:flutter_test/flutter_test.dart';

import 'package:construction_field_app/core/health/health_check_port.dart';
import 'package:construction_field_app/sync/background/background_outbox_flush.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('NoOpHealthCheckPort returns demo OK', () async {
    const port = NoOpHealthCheckPort();
    final result = await port.ping();
    expect(result.ok, isTrue);
    expect(result.source, 'demo');
    expect(result.service, 'demo-local');
    expect(result.version, '0');
    expect(result.summary, contains('Health OK'));
  });

  test('FirebaseHealthCheckPort maps callable payload', () async {
    final port = FirebaseHealthCheckPort(
      caller: () async => {
        'ok': true,
        'service': 'construction-field-functions',
        'version': '2',
      },
    );
    final result = await port.ping();
    expect(result.ok, isTrue);
    expect(result.source, 'firebase');
    expect(result.service, 'construction-field-functions');
    expect(result.version, '2');
    expect(result.latencyMs, isNotNull);
  });

  test('FirebaseHealthCheckPort surfaces callable failures', () async {
    final port = FirebaseHealthCheckPort(
      caller: () async => throw Exception('functions down'),
    );
    final result = await port.ping();
    expect(result.ok, isFalse);
    expect(result.source, 'firebase');
    expect(result.error, contains('functions down'));
    expect(result.summary, contains('Health failed'));
  });

  test('BackgroundSyncMeta.fromPrefs reads empty and written state', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final empty = BackgroundSyncMeta.fromPrefs(prefs);
    expect(empty.lastAt, isNull);
    expect(empty.lastFlushed, 0);

    await prefs.setString(
      'sync.background_last_at',
      DateTime.utc(2026, 8, 6, 9).toIso8601String(),
    );
    await prefs.setInt('sync.background_last_flushed', 3);
    final meta = BackgroundSyncMeta.fromPrefs(prefs);
    expect(meta.lastAt, isNotNull);
    expect(meta.lastFlushed, 3);
  });
}
