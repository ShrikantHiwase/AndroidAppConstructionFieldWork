import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'sync/background/background_sync_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final firebase = await bootstrapFirebase();

  final scheduler = const BackgroundSyncScheduler();
  final wmReady = await scheduler.initialize();
  if (wmReady) {
    await scheduler.registerPeriodicFlush();
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseEnabledProvider.overrideWithValue(firebase.enabled),
      ],
      child: const FieldApp(),
    ),
  );
}
