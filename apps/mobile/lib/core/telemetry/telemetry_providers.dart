import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import 'telemetry_port.dart';

final telemetryPortProvider = Provider<TelemetryPort>((ref) {
  if (ref.watch(firebaseEnabledProvider)) {
    return DeferredFirebaseTelemetry();
  }
  return NoOpTelemetry();
});

/// Bumped after telemetry writes so Sync status rebuilds the event list.
final telemetryRevisionProvider = StateProvider<int>((ref) => 0);

/// Keeps Crashlytics-style user id aligned with the signed-in session.
final telemetryBootstrapProvider = FutureProvider<void>((ref) async {
  final session = ref.watch(authSessionProvider);
  final telemetry = ref.read(telemetryPortProvider);
  await telemetry.setUserId(session?.user.id);
  ref.read(telemetryRevisionProvider.notifier).state++;
});

/// Logs an analytics-style event and refreshes Sync diagnostics.
Future<void> logTelemetryEvent(
  WidgetRef ref, {
  required String name,
  Map<String, Object?> params = const {},
}) async {
  await ref.read(telemetryPortProvider).logEvent(name, params: params);
  ref.read(telemetryRevisionProvider.notifier).state++;
}

/// Same as [logTelemetryEvent] for non-widget [Ref] call sites (connectivity).
Future<void> logTelemetryEventFromRef(
  Ref ref, {
  required String name,
  Map<String, Object?> params = const {},
}) async {
  await ref.read(telemetryPortProvider).logEvent(name, params: params);
  ref.read(telemetryRevisionProvider.notifier).state++;
}
