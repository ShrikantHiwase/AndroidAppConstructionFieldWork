import 'package:flutter_test/flutter_test.dart';

import 'package:construction_field_app/core/firebase/firebase_bootstrap.dart';
import 'package:construction_field_app/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('placeholder options keep Firebase disabled', () {
    expect(FirebaseOptionsGate.isConfigured, isFalse);
  });

  test('bootstrapFirebase returns demo mode without options', () async {
    final result = await bootstrapFirebase();
    expect(result.enabled, isFalse);
    expect(result.error, isNull);
  });
}
