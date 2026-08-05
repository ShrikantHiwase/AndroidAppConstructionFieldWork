import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:construction_field_app/app/app.dart';

void main() {
  testWidgets('Phase 0 shell shows brand and primary actions', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FieldApp()));

    expect(find.text('Field Evidence'), findsWidgets);
    expect(find.text('New Issue'), findsOneWidget);
    expect(find.text("Today's DPR"), findsOneWidget);
    expect(find.text('Pin on Drawing'), findsOneWidget);
  });
}
