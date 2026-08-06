# Secure store (encrypted local prefs)

Demo-safe port so sensitive session secrets leave plaintext SharedPreferences
before FlutterFire go-live.

## What ships

| Piece | Behaviour |
|-------|-----------|
| **`SecureStore`** | `read` / `write` / `delete` + one-time prefs migration |
| **`FakeSecureStore`** | Prefs under `secure.*` (`fake`) — default for CI / tests |
| **`PlatformSecureStore`** | `flutter_secure_storage` when `--dart-define=USE_SECURE_STORAGE=true` |
| **Keys** | `auth.session_email`, `auth.biometrics_enabled`, `fcm.token` |
| **Sync status** | Shows `Secure store: fake \| flutter_secure_storage` |

Bulk outbox / DPR / issues JSON stays in SharedPreferences (Drift still deferred).

## Enable on device

```bash
cd apps/mobile
flutter run --dart-define=USE_SECURE_STORAGE=true
```

Combine with sensors if needed:

```bash
flutter run --dart-define=USE_SECURE_STORAGE=true --dart-define=USE_NATIVE_SENSORS=true
```

## Entry points

- `lib/core/secure/secure_store.dart`
- `secureStoreProvider` in `lib/features/auth/presentation/auth_controller.dart`
- `lib/main.dart` — `createSecureStore` + migrate + provider override

## Verify

1. Sign in → Sync status shows `Secure store: fake` (CI/demo) or platform label
2. After migrate, plaintext `auth.session_email` / `fcm.token` keys are gone from prefs
3. Unit: `flutter test test/secure_store_test.dart test/auth_repository_test.dart test/fcm_scaffolding_test.dart`
