import 'package:flutter_test/flutter_test.dart';

import 'package:construction_field_app/core/notifications/dpr_nudge_scheduler.dart';
import 'package:construction_field_app/features/digests/domain/digest_models.dart';
import 'package:construction_field_app/features/digests/presentation/digests_providers.dart';
import 'package:construction_field_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

void main() {
  test('FakeDprNudgeScheduler records schedule cancel and show', () async {
    final fake = FakeDprNudgeScheduler();
    expect(await fake.initialize(), isTrue);

    await syncDprNudgeSchedule(
      scheduler: fake,
      enabled: true,
      hourLocal: 17,
    );
    expect(fake.scheduledHour, 17);
    expect(fake.scheduledTitle, 'DPR reminder');

    await syncDprNudgeSchedule(
      scheduler: fake,
      enabled: false,
      hourLocal: 17,
    );
    expect(fake.cancelled, isTrue);
    expect(fake.scheduledHour, isNull);

    await fake.showNow(title: 'T', body: 'B');
    expect(fake.shown, hasLength(1));
    expect(fake.shown.single.body, 'B');
  });

  test('evaluateDprNudge gates on prefs hour and submission', () {
    const prefs = DigestPrefs(dprNudgeEnabled: true, nudgeHourLocal: 17);
    final en = lookupAppLocalizations(const Locale('en'));
    expect(
      evaluateDprNudge(
        prefs: prefs,
        todaySubmitted: false,
        l10n: en,
        now: DateTime(2026, 8, 6, 16, 59),
      ),
      isNull,
    );
    expect(
      evaluateDprNudge(
        prefs: prefs,
        todaySubmitted: false,
        l10n: en,
        now: DateTime(2026, 8, 6, 17, 1),
      )?.message,
      contains('submit today'),
    );
    expect(
      evaluateDprNudge(
        prefs: prefs,
        todaySubmitted: true,
        l10n: en,
        now: DateTime(2026, 8, 6, 18),
      ),
      isNull,
    );
    expect(
      evaluateDprNudge(
        prefs: const DigestPrefs(dprNudgeEnabled: false),
        todaySubmitted: false,
        l10n: en,
        now: DateTime(2026, 8, 6, 18),
      ),
      isNull,
    );
  });
}
