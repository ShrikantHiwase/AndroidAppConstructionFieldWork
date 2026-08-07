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

  testWidgets('Hinglish Site ops chrome', (tester) async {
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

    await tester.ensureVisible(find.text('Site ops'));
    await tester.tap(find.text('Site ops'));
    await tester.pumpAndSettle();
    expect(find.text('Safety log करो'), findsOneWidget);
    expect(find.text('Safety'), findsWidgets);
  });

  testWidgets('Hinglish Documents and Drawings chrome', (tester) async {
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

    // Client/engineer home may not show Documents; open via Pin on Drawing.
    await tester.ensureVisible(find.text('Drawing पर Pin'));
    await tester.tap(find.text('Drawing पर Pin'));
    await tester.pumpAndSettle();
    expect(find.text('Drawings'), findsOneWidget);
    expect(find.text('अभी कोई drawing seed नहीं।'), findsNothing); // seeded
  });

  testWidgets('Hinglish Documents browser folder kind chrome', (tester) async {
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

    await tester.tap(find.widgetWithText(ActionChip, 'client'));
    await tester.pump();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Documents'));
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    expect(find.text('Discipline'), findsWidgets);

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Document type'), findsWidgets);
  });

  testWidgets('Hinglish Pilot hub chrome from PM home', (tester) async {
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

    await tester.tap(find.widgetWithText(ActionChip, 'pm'));
    await tester.pump();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Pilot'));
    await tester.tap(find.text('Pilot'));
    await tester.pumpAndSettle();
    expect(find.text('Pilot / UAT'), findsOneWidget);
    expect(find.text('Hypercare snapshot'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pilot PDF share करो'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Pilot PDF share करो'), findsOneWidget);
  });

  testWidgets('Hinglish Invite users chrome from Admin home', (tester) async {
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

    await tester.tap(find.widgetWithText(ActionChip, 'admin'));
    await tester.pump();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Invite user'));
    await tester.tap(find.text('Invite user'));
    await tester.pumpAndSettle();
    expect(find.text('Invite users'), findsOneWidget);
    expect(find.text('Invite बनाओ'), findsOneWidget);
    expect(find.text('Invite भेजो'), findsOneWidget);
  });

  testWidgets('Hinglish Voice notes chrome from PM open queue', (tester) async {
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

    // Seed an issue as engineer (demo has no local issue seed).
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('नया Issue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Voice chrome issue');
    await tester.ensureVisible(find.text('Issue save करो'));
    await tester.tap(find.text('Issue save करो'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ActionChip, 'pm'));
    await tester.pump();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Open queue'));
    await tester.tap(find.text('Open queue'));
    await tester.pumpAndSettle();
    expect(find.text('Issues'), findsOneWidget);

    await tester.tap(find.text('Voice chrome issue'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Demo voice note जोड़ो'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Voice notes'), findsOneWidget);
    expect(find.text('Demo voice note जोड़ो'), findsOneWidget);
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
    expect(hi.logSafety, 'Safety log करो');
    expect(hi.save, 'Save करो');
    expect(hi.uploadDocument, 'Document upload करो');
    expect(hi.linkIssue, 'Issue link करो');
    expect(hi.drawingsTitle, 'Drawings');
    expect(hi.sharePilotPdf, 'Pilot PDF share करो');
    expect(hi.shareWeeklyPdf, 'Weekly PDF share करो');
    expect(hi.sendInvite, 'Invite भेजो');
    expect(hi.createInvite, 'Invite बनाओ');
    expect(hi.addDemoVoiceNote, 'Demo voice note जोड़ो');
    expect(hi.noVoiceNotesYet, 'अभी कोई voice note नहीं।');
    expect(hi.musterLoggedOk('+'), 'Muster log हो गया (geofence OK)+');
    expect(hi.onDevicePart, ' · device पर');
    expect(hi.noPdfPreview, 'PDF preview उपलब्ध नहीं।');
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.newIssue, 'New Issue');
    expect(en.syncPendingCount(3), '3 sync');
    expect(en.flushNow, 'Flush now');
    expect(en.digestsAndReminders, 'Digests & reminders');
    expect(en.saveIssue, 'Save issue');
    expect(en.submitDpr, 'Submit DPR');
    expect(en.logSafety, 'Log safety');
    expect(en.siteOps, 'Site ops');
    expect(en.uploadDocument, 'Upload document');
    expect(en.linkIssue, 'Link issue');
    expect(en.pilotUatTitle, 'Pilot / UAT');
    expect(en.inviteUsersTitle, 'Invite users');
    expect(en.sharePilotPdf, 'Share pilot PDF');
    expect(en.sendInvite, 'Send invite');
    expect(en.addDemoVoiceNote, 'Add demo voice note');
    expect(en.voiceNotesTitle, 'Voice notes');
    expect(en.disciplineFolderKind, 'Discipline');
    expect(en.blockersLine('None'), 'Blockers: None');
    expect(en.hasFailsLabel, 'HAS FAILS');
  });
}
