import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import 'firebase_push_notification_service.dart';
import 'local_notification_inbox.dart';
import 'push_notification_service.dart';

final notificationInboxProvider = Provider<LocalNotificationInbox>((ref) {
  return LocalNotificationInbox(
    ref.watch(sharedPreferencesProvider),
    secure: ref.watch(secureStoreProvider),
  );
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final inbox = ref.watch(notificationInboxProvider);
  if (ref.watch(firebaseEnabledProvider)) {
    return FirebasePushNotificationService(inbox: inbox);
  }
  return NoOpPushNotificationService(
    onLocalNotify: (title, body, data) => inbox.add(
      title: title,
      body: body,
      data: data,
      source: 'demo',
    ),
  );
});

/// Registers (or refreshes) the FCM / demo token for the signed-in user.
final pushRegistrationProvider = FutureProvider<String?>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null) return null;
  final service = ref.watch(pushNotificationServiceProvider);
  return service.register(userId: session.user.id);
});
