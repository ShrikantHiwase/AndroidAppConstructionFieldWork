import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'background_outbox_flush.dart';

/// Top-level Workmanager entry point (must stay a library top-level function).
@pragma('vm:entry-point')
void backgroundSyncCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('Background sync task: $taskName');
    final result = await runBackgroundOutboxFlush();
    if (result.error != null) {
      debugPrint('Background flush error: ${result.error}');
      return false;
    }
    debugPrint(
      'Background flush ok: flushed=${result.flushed} firebase=${result.firebaseEnabled}',
    );
    return true;
  });
}

/// Schedules periodic + opportunistic one-off outbox flushes.
class BackgroundSyncScheduler {
  const BackgroundSyncScheduler();

  static const _uniquePeriodic = 'field-outbox-periodic';
  static const _uniqueOneOff = 'field-outbox-oneoff';

  /// Initializes Workmanager. Safe to call multiple times; failures are logged
  /// (e.g. unit tests / unsupported platforms).
  Future<bool> initialize() async {
    try {
      await Workmanager().initialize(backgroundSyncCallbackDispatcher);
      return true;
    } catch (e, st) {
      debugPrint('Workmanager initialize skipped: $e\n$st');
      return false;
    }
  }

  /// Registers a periodic flush (Android min ~15 minutes) requiring network.
  Future<void> registerPeriodicFlush() async {
    try {
      await Workmanager().registerPeriodicTask(
        _uniquePeriodic,
        BackgroundSyncTasks.periodicFlush,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (e) {
      debugPrint('registerPeriodicFlush failed: $e');
    }
  }

  /// Queues a one-off flush soon (e.g. after going online).
  Future<void> enqueueOneOffFlush({Duration delay = Duration.zero}) async {
    try {
      await Workmanager().registerOneOffTask(
        _uniqueOneOff,
        BackgroundSyncTasks.oneOffFlush,
        initialDelay: delay,
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (e) {
      debugPrint('enqueueOneOffFlush failed: $e');
    }
  }
}
