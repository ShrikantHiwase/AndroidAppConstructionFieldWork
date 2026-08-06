import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/notifications/dpr_nudge_scheduler.dart';
import 'core/notifications/fcm_background.dart';
import 'core/secure/secure_store.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/digests/data/local_digests_repository.dart';
import 'sync/background/background_sync_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final secure = createSecureStore(prefs);
  await secure.migrateFromPrefs(prefs);
  final firebase = await bootstrapFirebase();

  if (firebase.enabled) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  final scheduler = const BackgroundSyncScheduler();
  final wmReady = await scheduler.initialize();
  if (wmReady) {
    await scheduler.registerPeriodicFlush();
  }

  final nudgeScheduler = LocalNotificationsDprNudgeScheduler();
  await nudgeScheduler.initialize();
  final digestPrefs = LocalDigestsRepository(prefs).getPrefs();
  await syncDprNudgeSchedule(
    scheduler: nudgeScheduler,
    enabled: digestPrefs.dprNudgeEnabled,
    hourLocal: digestPrefs.nudgeHourLocal,
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        secureStoreProvider.overrideWithValue(secure),
        firebaseEnabledProvider.overrideWithValue(firebase.enabled),
        dprNudgeSchedulerProvider.overrideWithValue(nudgeScheduler),
      ],
      child: const FieldApp(),
    ),
  );
}
