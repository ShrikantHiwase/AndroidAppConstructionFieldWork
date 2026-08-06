import 'package:flutter/material.dart';

import '../../features/dpr/presentation/dpr_pages.dart';
import '../../features/issues/presentation/issue_detail_page.dart';
import '../../features/issues/presentation/issues_list_page.dart';
import '../../features/rfis/presentation/rfis_pages.dart';

/// Root navigator for notification taps (local tray + FCM open).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Parsed deep link from FCM data / local notification payload.
class NotificationDeepLink {
  const NotificationDeepLink({
    required this.type,
    this.issueId,
    this.rfiId,
    this.dprId,
  });

  final String type;
  final String? issueId;
  final String? rfiId;
  final String? dprId;

  /// Builds a link from inbox / FCM maps. [payload] is used when [data] has no type
  /// (local tray uses payload string `dpr_nudge`).
  static NotificationDeepLink? tryParse(
    Map<String, String> data, {
    String? payload,
  }) {
    final type = (data['type'] ?? payload ?? '').trim();
    if (type.isEmpty) return null;
    return NotificationDeepLink(
      type: type,
      issueId: _nonEmpty(data['issueId']),
      rfiId: _nonEmpty(data['rfiId']),
      dprId: _nonEmpty(data['dprId']),
    );
  }

  static String? _nonEmpty(String? v) {
    final t = v?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  /// Widget to push, or null if type unknown.
  Widget? buildPage() {
    switch (type) {
      case 'dpr_nudge':
        return const TodaysDprPage();
      case 'dpr_submitted':
        return const DprHomePage();
      case 'issue_assigned':
      case 'issue_status':
        final id = issueId;
        if (id != null) return IssueDetailPage(issueId: id);
        return const IssuesListPage();
      case 'rfi_assigned':
      case 'rfi_status':
        final id = rfiId;
        if (id != null) return RfiDetailPage(rfiId: id);
        return const RfisListPage();
      default:
        return null;
    }
  }
}

/// Holds a cold-start payload until the user is signed in and the navigator is ready.
class PendingNotificationDeepLink {
  static String? payload;
  static Map<String, String>? data;

  static void store({String? payload, Map<String, String>? data}) {
    PendingNotificationDeepLink.payload = payload;
    PendingNotificationDeepLink.data = data;
  }

  static void clear() {
    payload = null;
    data = null;
  }
}

/// Pushes the matching page if the navigator is ready.
bool openNotificationDeepLink({
  Map<String, String> data = const {},
  String? payload,
}) {
  final link = NotificationDeepLink.tryParse(data, payload: payload);
  if (link == null) return false;
  final page = link.buildPage();
  if (page == null) return false;
  final nav = rootNavigatorKey.currentState;
  if (nav == null) {
    PendingNotificationDeepLink.store(payload: payload, data: data);
    return false;
  }
  nav.push(MaterialPageRoute<void>(builder: (_) => page));
  return true;
}

/// Flushes [PendingNotificationDeepLink] after sign-in / first frame.
bool consumePendingNotificationDeepLink() {
  final data = PendingNotificationDeepLink.data ?? const <String, String>{};
  final payload = PendingNotificationDeepLink.payload;
  if (payload == null && data.isEmpty) return false;
  PendingNotificationDeepLink.clear();
  return openNotificationDeepLink(data: data, payload: payload);
}
