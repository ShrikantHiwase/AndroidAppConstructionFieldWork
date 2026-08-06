import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import 'local_notification_inbox.dart';
import 'notification_message_mapper.dart';

/// Top-level FCM background/terminated entry (separate isolate).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('FCM background Firebase init skipped: $e');
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final inbox = LocalNotificationInbox(prefs);
  await recordRemoteMessage(inbox, message, source: 'fcm_bg');
}

Future<void> recordRemoteMessage(
  LocalNotificationInbox inbox,
  RemoteMessage message, {
  required String source,
}) async {
  final parsed = parsePushPayload(
    notificationTitle: message.notification?.title,
    notificationBody: message.notification?.body,
    data: message.data,
  );
  await inbox.add(
    title: parsed.title,
    body: parsed.body,
    data: parsed.data,
    source: source,
  );
}

/// Foreground + notification-open / cold-start handlers → local inbox.
Future<void> attachMessageOpenHandlers(LocalNotificationInbox inbox) async {
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    recordRemoteMessage(inbox, message, source: 'fcm_open');
  });

  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    await recordRemoteMessage(inbox, initial, source: 'fcm_launch');
  }
}
