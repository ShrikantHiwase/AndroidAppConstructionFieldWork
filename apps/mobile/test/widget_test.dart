import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:construction_field_app/app/app.dart';
import 'package:construction_field_app/features/auth/presentation/auth_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login shows demo hints and signs engineer into capture home',
      (tester) async {
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

    expect(find.text('Field Evidence'), findsWidgets);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Site capture'), findsOneWidget);
    expect(find.text('New Issue'), findsOneWidget);
    expect(find.text('Create issues'), findsOneWidget);
  });

  testWidgets('client demo chip lands on read-only home', (tester) async {
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

    await tester.tap(find.widgetWithText(ActionChip, 'client'));
    await tester.pump();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Client view'), findsOneWidget);
    expect(find.text('Read-only'), findsOneWidget);
  });
}
