import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/app/app.dart';
import 'package:construction_field_app/core/theme/app_theme.dart';
import 'package:construction_field_app/features/auth/presentation/auth_controller.dart';

Future<void> _pumpSignedIn(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const FieldApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign out asks for confirmation and cancel keeps session',
      (tester) async {
    await _pumpSignedIn(tester);
    expect(find.text('Site capture'), findsOneWidget);

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Site capture'), findsOneWidget);

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('engineer home links to RFIs list', (tester) async {
    await _pumpSignedIn(tester);

    await tester.tap(find.text('RFIs'));
    await tester.pumpAndSettle();

    expect(find.text('New RFI'), findsOneWidget);
  });

  testWidgets('DPR submit asks for confirmation before locking',
      (tester) async {
    await _pumpSignedIn(tester);

    await tester.tap(find.text("Today's DPR"));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Submit DPR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit DPR'));
    await tester.pumpAndSettle();
    expect(find.text("Submit today's DPR?"), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Save draft'), findsOneWidget);
  });

  testWidgets('login validates email format and can reveal password',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const FieldApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  test('theme exposes matching light and dark schemes', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));
  });
}
