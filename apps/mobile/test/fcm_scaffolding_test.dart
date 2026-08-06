import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/core/notifications/local_notification_inbox.dart';
import 'package:construction_field_app/core/notifications/notification_message_mapper.dart';
import 'package:construction_field_app/core/notifications/push_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('NoOp push registers demo token and logs local notify', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final inbox = LocalNotificationInbox(prefs);
    final push = NoOpPushNotificationService(
      onLocalNotify: (title, body, data) => inbox.add(
        title: title,
        body: body,
        data: data,
        source: 'demo',
      ),
    );

    final token = await push.register(userId: 'u_engineer');
    expect(token, 'demo-fcm-token-u_engineer');
    expect(await push.currentToken(), token);

    await push.notifyLocal(
      title: 'Issue assigned',
      body: 'Crack → Asha',
      data: {'type': 'issue_assigned'},
    );
    expect(inbox.entries, hasLength(1));
    expect(inbox.entries.first.title, 'Issue assigned');
    expect(inbox.entries.first.source, 'demo');
  });

  test('inbox persists across instances', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final inbox = LocalNotificationInbox(prefs);
    await inbox.add(title: 'A', body: 'B', source: 'local');
    await inbox.saveToken('tok_1');

    final again = LocalNotificationInbox(prefs);
    expect(again.entries, hasLength(1));
    expect(again.readToken(), 'tok_1');
  });

  test('parsePushPayload prefers notification then data type', () {
    final fromNotification = parsePushPayload(
      notificationTitle: 'Hello',
      notificationBody: 'World',
      data: {'type': 'issue_assigned'},
    );
    expect(fromNotification.title, 'Hello');
    expect(fromNotification.body, 'World');

    final fromType = parsePushPayload(
      data: {'type': 'issue_status', 'status': 'resolved'},
    );
    expect(fromType.title, 'Issue status updated');
    expect(fromType.body, 'resolved');
    expect(fromType.data['type'], 'issue_status');

    final dpr = parsePushPayload(data: {'type': 'dpr_submitted'});
    expect(dpr.title, 'DPR submitted');
  });
}
