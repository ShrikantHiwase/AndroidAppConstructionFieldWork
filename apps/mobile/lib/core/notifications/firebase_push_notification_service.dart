import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'local_notification_inbox.dart';
import 'push_notification_service.dart';

/// FCM registration + foreground message → local inbox.
///
/// Background/terminated handlers need a top-level `@pragma('vm:entry-point')`
/// after FlutterFire configure; this scaffolding covers foreground + token.
class FirebasePushNotificationService implements PushNotificationService {
  FirebasePushNotificationService({
    required LocalNotificationInbox inbox,
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _inbox = inbox,
        _messaging = messaging ?? FirebaseMessaging.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final LocalNotificationInbox _inbox;
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _db;
  String? _token;
  var _listening = false;

  @override
  Future<String?> register({required String userId}) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return null;
    }

    final token = await _messaging.getToken();
    _token = token;
    if (token != null) {
      await _inbox.saveToken(token);
      await _db.collection('fcm_tokens').doc(userId).set({
        'uid': userId,
        'token': token,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'platform': 'flutter',
      }, SetOptions(merge: true));
    }

    if (!_listening) {
      _listening = true;
      FirebaseMessaging.onMessage.listen((message) async {
        final title = message.notification?.title ??
            message.data['title'] ??
            'Field update';
        final body = message.notification?.body ??
            message.data['body'] ??
            message.data.toString();
        await _inbox.add(
          title: title,
          body: body,
          data: message.data.map((k, v) => MapEntry(k, v.toString())),
          source: 'fcm',
        );
      });
      _messaging.onTokenRefresh.listen((t) async {
        _token = t;
        await _inbox.saveToken(t);
        await _db.collection('fcm_tokens').doc(userId).set({
          'uid': userId,
          'token': t,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        }, SetOptions(merge: true));
      });
    }
    return token;
  }

  @override
  Future<String?> currentToken() async =>
      _token ?? _inbox.readToken() ?? await _messaging.getToken();

  @override
  Future<void> notifyLocal({
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    // Server-side FCM send is Functions' job; locally record the intent.
    await _inbox.add(title: title, body: body, data: data, source: 'local');
  }
}
