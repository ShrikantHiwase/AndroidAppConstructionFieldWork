import 'dart:async';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
import 'l10n/app_localizations.dart';
import 'sync/background/background_sync_scheduler.dart';

Future<void> main() async {
  await runZonedGuarded(_bootstrap, _reportUncaughtError);
}

void _reportUncaughtError(Object error, StackTrace stack) {
  // Crashlytics is deferred until FlutterFire configure (see docs/Telemetry.md);
  // until then keep uncaught errors visible in logs instead of dying silently.
  debugPrint('Uncaught error: $error\n$stack');
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _reportUncaughtError(details.exception, details.stack ?? StackTrace.empty);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _reportUncaughtError(error, stack);
    return true;
  };

  // Field forms are portrait workflows on phones; landscape support is a
  // deliberate tablet follow-up rather than an accidental rotation.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
  final localeCode = prefs.getString('app.locale_code');
  final l10n = lookupAppLocalizations(
    localeCode == null || localeCode.isEmpty
        ? const Locale('en')
        : Locale(localeCode),
  );
  await syncDprNudgeSchedule(
    scheduler: nudgeScheduler,
    enabled: digestPrefs.dprNudgeEnabled,
    hourLocal: digestPrefs.nudgeHourLocal,
    title: l10n.dprReminderTitle,
    body: l10n.dprReminderBody,
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
