import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_deep_link.dart';

/// Schedules / shows the daily DPR reminder (demo-safe local notifications).
abstract class DprNudgeScheduler {
  Future<bool> initialize();

  /// Schedules a daily reminder at [hourLocal]:00 (device local wall clock).
  Future<void> scheduleDaily({
    required int hourLocal,
    required String title,
    required String body,
  });

  Future<void> cancel();

  /// Immediate tray notification (Simulate / overdue check).
  Future<void> showNow({
    required String title,
    required String body,
  });
}

/// Test double — records calls, never touches plugins.
class FakeDprNudgeScheduler implements DprNudgeScheduler {
  var initialized = false;
  int? scheduledHour;
  String? scheduledTitle;
  String? scheduledBody;
  final shown = <({String title, String body})>[];
  var cancelled = false;

  @override
  Future<bool> initialize() async {
    initialized = true;
    return true;
  }

  @override
  Future<void> scheduleDaily({
    required int hourLocal,
    required String title,
    required String body,
  }) async {
    scheduledHour = hourLocal;
    scheduledTitle = title;
    scheduledBody = body;
    cancelled = false;
  }

  @override
  Future<void> cancel() async {
    cancelled = true;
    scheduledHour = null;
  }

  @override
  Future<void> showNow({
    required String title,
    required String body,
  }) async {
    shown.add((title: title, body: body));
  }
}

/// Production: `flutter_local_notifications` + timezone daily schedule.
class LocalNotificationsDprNudgeScheduler implements DprNudgeScheduler {
  LocalNotificationsDprNudgeScheduler({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static const _notificationId = 1700;
  static const _channelId = 'field_alerts';
  var _ready = false;

  void _onTap(NotificationResponse response) {
    openNotificationDeepLink(payload: response.payload);
  }

  @override
  Future<bool> initialize() async {
    try {
      tzdata.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      );
      final ok = await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onTap,
      );
      _ready = ok ?? true;

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              'Field alerts',
              description: 'DPR reminders and field push alerts',
              importance: Importance.defaultImportance,
            ),
          );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        PendingNotificationDeepLink.store(
          payload: launch!.notificationResponse?.payload,
        );
      }

      return _ready;
    } catch (e, st) {
      debugPrint('DPR nudge scheduler init skipped: $e\n$st');
      _ready = false;
      return false;
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Field alerts',
          channelDescription: 'DPR reminders and field push alerts',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );

  tz.TZDateTime _nextInstance(int hourLocal) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hourLocal);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(next, tz.local);
  }

  @override
  Future<void> scheduleDaily({
    required int hourLocal,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _notificationId);
      await _plugin.zonedSchedule(
        id: _notificationId,
        title: title,
        body: body,
        scheduledDate: _nextInstance(hourLocal),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'dpr_nudge',
      );
    } catch (e, st) {
      debugPrint('scheduleDaily failed: $e\n$st');
    }
  }

  @override
  Future<void> cancel() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _notificationId);
    } catch (e) {
      debugPrint('cancel nudge failed: $e');
    }
  }

  @override
  Future<void> showNow({
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: _notificationId,
        title: title,
        body: body,
        notificationDetails: _details,
        payload: 'dpr_nudge',
      );
    } catch (e, st) {
      debugPrint('showNow nudge failed: $e\n$st');
    }
  }
}

final dprNudgeSchedulerProvider = Provider<DprNudgeScheduler>((ref) {
  return LocalNotificationsDprNudgeScheduler();
});

/// Applies [DigestPrefs]-style enable/hour to the scheduler.
Future<void> syncDprNudgeSchedule({
  required DprNudgeScheduler scheduler,
  required bool enabled,
  required int hourLocal,
}) async {
  if (!enabled) {
    await scheduler.cancel();
    return;
  }
  await scheduler.scheduleDaily(
    hourLocal: hourLocal,
    title: 'DPR reminder',
    body: "Submit today's Daily Progress Report if you haven't yet.",
  );
}
