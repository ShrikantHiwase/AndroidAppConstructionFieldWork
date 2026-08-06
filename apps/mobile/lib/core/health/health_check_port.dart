import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';

/// Injectable callable for tests (avoids live Cloud Functions).
typedef HealthCaller = Future<Map<String, dynamic>> Function();

class HealthCheckResult {
  const HealthCheckResult({
    required this.ok,
    required this.service,
    required this.version,
    required this.source,
    this.latencyMs,
    this.error,
  });

  final bool ok;
  final String service;
  final String version;

  /// `demo` or `firebase`.
  final String source;
  final int? latencyMs;
  final String? error;

  String get summary {
    if (error != null) {
      return 'Health failed ($source): $error';
    }
    final latency = latencyMs == null ? '' : ' · ${latencyMs}ms';
    return 'Health OK · $service v$version · $source$latency';
  }
}

/// Probes backend readiness (Cloud Functions `health` or local demo).
abstract class HealthCheckPort {
  Future<HealthCheckResult> ping();
}

class NoOpHealthCheckPort implements HealthCheckPort {
  const NoOpHealthCheckPort();

  @override
  Future<HealthCheckResult> ping() async {
    final sw = Stopwatch()..start();
    await Future<void>.delayed(Duration.zero);
    sw.stop();
    return HealthCheckResult(
      ok: true,
      service: 'demo-local',
      version: '0',
      source: 'demo',
      latencyMs: sw.elapsedMilliseconds,
    );
  }
}

class FirebaseHealthCheckPort implements HealthCheckPort {
  FirebaseHealthCheckPort({
    FirebaseFunctions? functions,
    HealthCaller? caller,
  })  : _functionsOverride = functions,
        _callerOverride = caller;

  final FirebaseFunctions? _functionsOverride;
  final HealthCaller? _callerOverride;

  Future<Map<String, dynamic>> _callHealth() async {
    if (_callerOverride != null) {
      return _callerOverride();
    }
    final functions = _functionsOverride ?? FirebaseFunctions.instance;
    final result = await functions.httpsCallable('health').call();
    final raw = result.data;
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  @override
  Future<HealthCheckResult> ping() async {
    final sw = Stopwatch()..start();
    try {
      final data = await _callHealth();
      sw.stop();
      final ok = data['ok'] == true;
      return HealthCheckResult(
        ok: ok,
        service: '${data['service'] ?? 'construction-field-functions'}',
        version: '${data['version'] ?? '?'}',
        source: 'firebase',
        latencyMs: sw.elapsedMilliseconds,
        error: ok ? null : 'ok != true',
      );
    } catch (e) {
      sw.stop();
      return HealthCheckResult(
        ok: false,
        service: 'construction-field-functions',
        version: '?',
        source: 'firebase',
        latencyMs: sw.elapsedMilliseconds,
        error: '$e',
      );
    }
  }
}

final healthCheckPortProvider = Provider<HealthCheckPort>((ref) {
  if (ref.watch(firebaseEnabledProvider)) {
    return FirebaseHealthCheckPort();
  }
  return const NoOpHealthCheckPort();
});

/// Last in-app probe result (null until the user taps Probe).
final lastHealthCheckProvider =
    StateProvider<HealthCheckResult?>((ref) => null);
