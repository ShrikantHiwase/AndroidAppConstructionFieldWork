# Firebase setup

The Flutter app ships in **demo mode** until Firebase options are configured.
With `FirebaseOptionsGate.isConfigured == false`, auth uses `FakeAuthRepository`
and field data stays on device via SharedPreferences.

## One-time project setup

1. Create a Firebase project in the [console](https://console.firebase.google.com/).
   Enable **Authentication** (Email/Password), **Firestore**, **Storage**, and **Cloud Messaging**.
2. From the repo:

```bash
# Link CLI project
cd firebase
firebase login
firebase use --add

# Generate Flutter options (from apps/mobile)
cd ../apps/mobile
dart pub global activate flutterfire_cli
flutterfire configure
```

3. Open `lib/firebase_options.dart` and set:

```dart
static const bool isConfigured = true;
```

4. Keep platform credential files **out of git** (already gitignored):
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

5. Deploy rules / indexes when ready:

```bash
cd firebase
firebase deploy --only firestore:rules,firestore:indexes,storage
```

6. Restart the app. The corner banner should read **FIREBASE** and login uses
   real Auth + membership docs.

## Seed data (minimum)

After creating Auth users in the console (or Admin SDK), write matching docs:

| Collection | Doc shape |
|------------|-----------|
| `organizations/{orgId}` | `{ name }` |
| `projects/{projectId}` | `{ orgId, name, siteName? }` |
| `memberships/{uid}_{projectId}` | `{ userId, orgId, projectId, role, active }` |

`role` values: `site_engineer`, `project_manager`, `qa_qc`, `client`, `admin`.

`FirebaseAuthRepository` loads memberships by `userId == Auth.uid` and
`active == true`, then hydrates projects/orgs.

## Emulators (optional)

```bash
cd firebase
firebase emulators:start
```

Point the app at emulators only after options are configured (see FlutterFire
emulator docs). Demo mode does not need emulators.

## CI

CI stays on demo mode (`isConfigured = false`). Do not commit real API keys or
service account JSON into this repository.
