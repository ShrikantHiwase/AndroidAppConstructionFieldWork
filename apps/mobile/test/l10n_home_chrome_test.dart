import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/app/app.dart';
import 'package:construction_field_app/core/l10n/app_locale_provider.dart';
import 'package:construction_field_app/features/auth/presentation/auth_controller.dart';
import 'package:construction_field_app/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Hinglish locale shows Hinglish CTAs and Offline badge',
      (tester) async {
    SharedPreferences.setMockInitialValues({'app.locale_code': 'hi'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const FieldApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hinglish'), findsOneWidget);
    expect(find.text('नया Issue'), findsNothing); // not signed in yet

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('नया Issue'), findsOneWidget);
    expect(find.text('आज का DPR'), findsOneWidget);
    expect(find.text('Drawing पर Pin'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.cloud_outlined));
    await tester.pumpAndSettle();
    expect(find.text('ऑफ़लाइन'), findsOneWidget);
  });

  testWidgets('Hinglish Sync status and Digests chrome', (tester) async {
    SharedPreferences.setMockInitialValues({'app.locale_code': 'hi'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const FieldApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.sync));
    await tester.pumpAndSettle();
    expect(find.text('Sync status'), findsWidgets);
    expect(find.text('Outbox खाली है'), findsOneWidget);

    // ListView builds lazily — scroll to action buttons.
    await tester.scrollUntilVisible(
      find.text('अभी Flush करो'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('अभी Flush करो'), findsOneWidget);
    expect(find.text('Offline जाओ'), findsOneWidget);
  });

  testWidgets('Hinglish Digests chrome from Reminders', (tester) async {
    SharedPreferences.setMockInitialValues({'app.locale_code': 'hi'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const FieldApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Reminders'));
    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();
    expect(find.text('Digests और reminders'), findsOneWidget);
    expect(find.text('5 PM check simulate करो'), findsOneWidget);
  });


  testWidgets('Hinglish New Issue chrome', (tester) async {
    SharedPreferences.setMockInitialValues({'app.locale_code': 'hi'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const FieldApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('नया Issue'));
    await tester.pumpAndSettle();
    expect(find.text('Issue save करो'), findsOneWidget);
    expect(find.text('GPS जोड़ो'), findsOneWidget);
  });

  testWidgets('Hinglish Today DPR chrome', (tester) async {
    SharedPreferences.setMockInitialValues({'app.locale_code': 'hi'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const FieldApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('आज का DPR'));
    await tester.pumpAndSettle();
    expect(find.text('DPR submit करो'), findsOneWidget);
    expect(find.text('Draft save करो'), findsOneWidget);
  });

  testWidgets('English locale keeps New Issue CTA', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const FieldApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('New Issue'), findsOneWidget);
    expect(find.text("Today's DPR"), findsOneWidget);
  });

  test('AppLocaleController persists en/hi override', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = AppLocaleController(prefs);
    expect(controller.state, isNull);
    await controller.setLocaleCode('hi');
    expect(controller.state, const Locale('hi'));
    expect(prefs.getString('app.locale_code'), 'hi');
    await controller.cycle(); // hi → device default
    expect(controller.state, isNull);
  });

  test('generated localizations expose Hinglish Sync/Digests strings', () {
    final hi = lookupAppLocalizations(const Locale('hi'));
    expect(hi.newIssue, 'नया Issue');
    expect(hi.offlineBadge, 'ऑफ़लाइन');
    expect(hi.flushNow, 'अभी Flush करो');
    expect(hi.digestsAndReminders, 'Digests और reminders');
    expect(hi.simulate5PmCheck, '5 PM check simulate करो');
    expect(hi.saveIssue, 'Issue save करो');
    expect(hi.addGps, 'GPS जोड़ो');
    expect(hi.submitDpr, 'DPR submit करो');
    expect(hi.newRfi, 'नया RFI');
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.newIssue, 'New Issue');
    expect(en.syncPendingCount(3), '3 sync');
    expect(en.flushNow, 'Flush now');
    expect(en.digestsAndReminders, 'Digests & reminders');
    expect(en.saveIssue, 'Save issue');
    expect(en.submitDpr, 'Submit DPR');
  });
}
