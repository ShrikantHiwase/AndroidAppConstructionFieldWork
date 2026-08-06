# Background sync (Workmanager + connectivity)

Demo-safe scaffolding so the outbox can flush without the UI open.

## What ships

| Piece | Behaviour |
|-------|-----------|
| **`runBackgroundOutboxFlush`** | Headless rebuild of local repos + `LocalSyncEngine.flushNow` (NoOp or Firestore sinks via `bootstrapFirebase`) |
| **Workmanager** | Periodic task ~15 min (`field_outbox_periodic_flush`) with `NetworkType.connected`; one-off enqueue after reconnect |
| **connectivity_plus** | When the OS reports network **and** the demo cloud toggle is online, auto-flush + enqueue one-off |

## Entry points

- `lib/sync/background/background_outbox_flush.dart`
- `lib/sync/background/background_sync_scheduler.dart` (`backgroundSyncCallbackDispatcher`)
- `lib/main.dart` — `initialize` + `registerPeriodicFlush`
- `lib/core/providers/connectivity_provider.dart` — device watch

## Android

Manifest permissions: `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK` (plus existing network/location).

## Limits

- Android periodic floor is ~15 minutes (OS-controlled).
- iOS background execution is budget-limited; treat periodic as best-effort.
- Workmanager `initialize` failures are swallowed in tests / unsupported hosts.
- Drift local DB still deferred — prefs outbox remains the source of truth.
- Pinned to `workmanager` **0.9.2** with overrides (`workmanager_android` 0.9.2, `workmanager_apple` 0.9.4, `workmanager_platform_interface` 0.9.3) so Flutter **3.32** CI compiles; newer lines need Flutter ≥3.38.

## Verify

1. Create an issue offline → leave app → wait for periodic (or force one-off via going online)
2. **Sync status** shows last background flush time / count (from `sync.background_last_at` / `sync.background_last_flushed`)
3. Tap **Enqueue background flush** (Workmanager one-off; may no-op on desktop tests)
4. Tap **Probe health** — demo returns local OK; Firebase calls Functions `health`
5. Unit: `flutter test test/background_sync_test.dart test/health_check_port_test.dart`
