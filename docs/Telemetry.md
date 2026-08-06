# Telemetry (Crashlytics / Analytics scaffolding)

Demo-safe port so Sync diagnostics can record analytics-style events before
`firebase_crashlytics` / `firebase_analytics` are added.

## What ships

| Piece | Behaviour |
|-------|-----------|
| **`TelemetryPort`** | `logEvent`, `recordError`, `setUserId` + recent-event ring |
| **`NoOpTelemetry`** | Demo / Firebase-off — in-memory only (`demo-noop`) |
| **`DeferredFirebaseTelemetry`** | Firebase gate on, packages still deferred (`firebase-deferred`) |
| **Sync status** | Shows backend label, user id, last events |
| **Hooks** | Session → `setUserId`; flush / cleanup / health probe → `logEvent` |

## Entry points

- `lib/core/telemetry/telemetry_port.dart`
- `lib/core/telemetry/telemetry_providers.dart`
- Sync status **Telemetry** section
- Home watches `telemetryBootstrapProvider` (same pattern as FCM token warm-up)

## Not in this PR

- `firebase_crashlytics` / `firebase_analytics` pubspec deps
- Native Crashlytics Gradle / dSYM upload
- Production event taxonomy beyond sync/health/auth identity

Add packages after `flutterfire configure` (see [Go_Live_Checklist.md](Go_Live_Checklist.md)).

## Verify

1. Sign in → Sync status Telemetry shows `demo-noop` + user id
2. Flush now / Cleanup / Probe health → events appear in the list
3. Unit: `flutter test test/telemetry_scaffolding_test.dart`
