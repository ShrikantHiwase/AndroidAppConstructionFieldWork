import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/core/telemetry/telemetry_port.dart';
import 'package:construction_field_app/core/telemetry/telemetry_providers.dart';
import 'package:construction_field_app/features/auth/presentation/auth_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('NoOp telemetry records events, errors, and user id', () async {
    final telemetry = NoOpTelemetry();
    expect(telemetry.backendLabel, 'demo-noop');

    await telemetry.setUserId('u_engineer');
    expect(telemetry.userId, 'u_engineer');

    await telemetry.logEvent(
      'sync_flush',
      params: {'flushed': 2, 'source': 'manual'},
    );
    await telemetry.recordError(StateError('boom'), StackTrace.current);

    expect(telemetry.recentEvents.length, greaterThanOrEqualTo(3));
    expect(telemetry.recentEvents.first.kind, 'error');
    expect(
      telemetry.recentEvents.any((e) => e.name == 'sync_flush'),
      isTrue,
    );
    expect(
      telemetry.recentEvents.any((e) => e.name == 'set_user_id'),
      isTrue,
    );
  });

  test('DeferredFirebaseTelemetry keeps local ring until packages land',
      () async {
    final telemetry = DeferredFirebaseTelemetry();
    expect(telemetry.backendLabel, 'firebase-deferred');
    await telemetry.logEvent('health_probe', params: {'ok': true});
    expect(telemetry.recentEvents.single.name, 'health_probe');
  });

  test('telemetryPortProvider selects NoOp when Firebase is off', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseEnabledProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    final port = container.read(telemetryPortProvider);
    expect(port, isA<NoOpTelemetry>());
    expect(port.backendLabel, 'demo-noop');
  });

  test('telemetryPortProvider selects deferred backend when Firebase on',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseEnabledProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    final port = container.read(telemetryPortProvider);
    expect(port, isA<DeferredFirebaseTelemetry>());
    expect(port.backendLabel, 'firebase-deferred');
  });
}
