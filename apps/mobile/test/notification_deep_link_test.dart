import 'package:flutter_test/flutter_test.dart';

import 'package:construction_field_app/core/notifications/notification_deep_link.dart';
import 'package:construction_field_app/features/dpr/presentation/dpr_pages.dart';
import 'package:construction_field_app/features/issues/presentation/issue_detail_page.dart';
import 'package:construction_field_app/features/issues/presentation/issues_list_page.dart';
import 'package:construction_field_app/features/rfis/presentation/rfis_pages.dart';

void main() {
  test('tryParse maps dpr_nudge payload to TodaysDprPage', () {
    final link = NotificationDeepLink.tryParse(const {}, payload: 'dpr_nudge');
    expect(link?.type, 'dpr_nudge');
    expect(link?.buildPage(), isA<TodaysDprPage>());
  });

  test('tryParse maps issue types to detail or list', () {
    final withId = NotificationDeepLink.tryParse({
      'type': 'issue_assigned',
      'issueId': 'iss_1',
    });
    expect(withId?.buildPage(), isA<IssueDetailPage>());

    final withoutId =
        NotificationDeepLink.tryParse({'type': 'issue_status'});
    expect(withoutId?.buildPage(), isA<IssuesListPage>());
  });

  test('tryParse maps rfi types to detail or list', () {
    final withId = NotificationDeepLink.tryParse({
      'type': 'rfi_status',
      'rfiId': 'rfi_1',
    });
    expect(withId?.buildPage(), isA<RfiDetailPage>());

    final withoutId =
        NotificationDeepLink.tryParse({'type': 'rfi_assigned'});
    expect(withoutId?.buildPage(), isA<RfisListPage>());
  });

  test('tryParse returns null for unknown / empty', () {
    expect(NotificationDeepLink.tryParse(const {}), isNull);
    expect(
      NotificationDeepLink.tryParse({'type': 'unknown_type'})?.buildPage(),
      isNull,
    );
  });

  test('PendingNotificationDeepLink store and clear', () {
    PendingNotificationDeepLink.clear();
    PendingNotificationDeepLink.store(
      payload: 'dpr_nudge',
      data: {'type': 'dpr_nudge'},
    );
    expect(PendingNotificationDeepLink.payload, 'dpr_nudge');
    PendingNotificationDeepLink.clear();
    expect(PendingNotificationDeepLink.payload, isNull);
    expect(PendingNotificationDeepLink.data, isNull);
  });
}
