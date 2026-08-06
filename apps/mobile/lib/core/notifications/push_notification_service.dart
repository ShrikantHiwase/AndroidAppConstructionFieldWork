/// Abstraction over FCM so demo mode never touches the network.
abstract class PushNotificationService {
  /// Requests permission (no-op / granted in demo) and returns a device token.
  Future<String?> register({required String userId});

  /// Current token if already registered this session / prefs.
  Future<String?> currentToken();

  /// Records a local "would notify" event (demo) or prepares a data payload.
  Future<void> notifyLocal({
    required String title,
    required String body,
    Map<String, String> data = const {},
  });
}

/// Demo / Firebase-off — fake token + local inbox only.
class NoOpPushNotificationService implements PushNotificationService {
  NoOpPushNotificationService({this.onLocalNotify});

  final Future<void> Function(String title, String body, Map<String, String> data)?
      onLocalNotify;

  String? _token;

  @override
  Future<String?> register({required String userId}) async {
    _token = 'demo-fcm-token-$userId';
    return _token;
  }

  @override
  Future<String?> currentToken() async => _token;

  @override
  Future<void> notifyLocal({
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    await onLocalNotify?.call(title, body, data);
  }
}
