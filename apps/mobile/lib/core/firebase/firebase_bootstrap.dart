import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({
    required this.enabled,
    this.error,
  });

  final bool enabled;
  final String? error;
}

/// Initializes Firebase only when [FirebaseOptionsGate.isConfigured] is true.
Future<FirebaseBootstrapResult> bootstrapFirebase() async {
  if (!FirebaseOptionsGate.isConfigured) {
    debugPrint('Firebase: demo mode (options not configured yet).');
    return const FirebaseBootstrapResult(enabled: false);
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return const FirebaseBootstrapResult(enabled: true);
  } catch (e, st) {
    debugPrint('Firebase init failed: $e\n$st');
    return FirebaseBootstrapResult(enabled: false, error: e.toString());
  }
}
