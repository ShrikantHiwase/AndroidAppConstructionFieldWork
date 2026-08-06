/// Abstraction over Crashlytics / Analytics so demo mode never touches Firebase.
///
/// Real `firebase_crashlytics` / `firebase_analytics` packages stay deferred until
/// FlutterFire is configured; see [DeferredFirebaseTelemetry].
abstract class TelemetryPort {
  /// `demo-noop` or `firebase-deferred` (packages not wired yet).
  String get backendLabel;

  String? get userId;

  /// Newest-first ring of recent events (for Sync status diagnostics).
  List<TelemetryEvent> get recentEvents;

  Future<void> logEvent(
    String name, {
    Map<String, Object?> params = const {},
  });

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  });

  Future<void> setUserId(String? userId);
}

class TelemetryEvent {
  const TelemetryEvent({
    required this.at,
    required this.kind,
    required this.name,
    this.params = const {},
  });

  final DateTime at;

  /// `event`, `error`, or `user`.
  final String kind;
  final String name;
  final Map<String, Object?> params;

  String get summary {
    if (params.isEmpty) return name;
    final bits = params.entries
        .take(3)
        .map((e) => '${e.key}=${e.value}')
        .join(' ');
    return '$name · $bits';
  }
}

/// In-memory recorder shared by demo and deferred-Firebase backends.
class InMemoryTelemetry implements TelemetryPort {
  InMemoryTelemetry({
    required this.backendLabel,
    this.maxEvents = 40,
  });

  @override
  final String backendLabel;

  final int maxEvents;
  final _events = <TelemetryEvent>[];
  String? _userId;

  @override
  String? get userId => _userId;

  @override
  List<TelemetryEvent> get recentEvents => List.unmodifiable(_events);

  void _push(TelemetryEvent event) {
    _events.insert(0, event);
    if (_events.length > maxEvents) {
      _events.removeRange(maxEvents, _events.length);
    }
  }

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?> params = const {},
  }) async {
    _push(
      TelemetryEvent(
        at: DateTime.now().toUtc(),
        kind: 'event',
        name: name,
        params: Map.unmodifiable(params),
      ),
    );
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    _push(
      TelemetryEvent(
        at: DateTime.now().toUtc(),
        kind: 'error',
        name: fatal ? 'fatal_error' : 'non_fatal_error',
        params: {
          'error': error.toString(),
          if (stack != null) 'stack': stack.toString().split('\n').first,
        },
      ),
    );
  }

  @override
  Future<void> setUserId(String? userId) async {
    _userId = userId;
    _push(
      TelemetryEvent(
        at: DateTime.now().toUtc(),
        kind: 'user',
        name: 'set_user_id',
        params: {'userId': userId ?? '(cleared)'},
      ),
    );
  }
}

/// Demo / Firebase-off — local ring buffer only.
class NoOpTelemetry extends InMemoryTelemetry {
  NoOpTelemetry({super.maxEvents}) : super(backendLabel: 'demo-noop');
}

/// Firebase enabled but Crashlytics/Analytics packages not added yet.
class DeferredFirebaseTelemetry extends InMemoryTelemetry {
  DeferredFirebaseTelemetry({super.maxEvents})
      : super(backendLabel: 'firebase-deferred');
}
