# Firebase setup

The Flutter app ships in **demo mode** until Firebase options are configured.
With `FirebaseOptionsGate.isConfigured == false`, auth uses `FakeAuthRepository`
and field data stays on device via SharedPreferences.

**Full go-live order:** [Go_Live_Checklist.md](Go_Live_Checklist.md)

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

5. Deploy rules / indexes / functions when ready:

```bash
cd firebase/functions && npm install && cd ..
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

6. Restart the app. The corner banner should read **FIREBASE** and login uses
   real Auth + membership docs.

## Seed data

Use the demo seed (same emails/password as the FakeAuth catalog):

```bash
cd firebase
firebase emulators:start
# other terminal:
./seed/run_seed_emulators.sh
```

Or against staging with a service account:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json
cd firebase/functions && npm install
cd .. && node seed/seed_demo.js
```

Seed writes `organizations`, `projects`, Auth users, and `memberships/{uid}_{projectId}`.

`role` values: `site_engineer`, `project_manager`, `qa_qc`, `client`, `admin`.

`FirebaseAuthRepository` loads memberships by `userId == Auth.uid` and
`active == true`, then hydrates projects/orgs.

## Cloud Functions

| Callable / trigger | Purpose |
|--------------------|---------|
| `health` | Connectivity check — Sync status **Probe health** (NoOp in demo; Functions when Firebase on) |
| `inviteMember` | Admin creates Auth user + memberships + `invites` audit doc (app calls via `cloud_functions` when Firebase is on) |
| `onDprWrite` | FCM notify creator on DPR submit |
| `onIssueWrite` | FCM on issue assign / status change |
| `onRfiWrite` | FCM on RFI assign / status change |
| `dailyDprNudge` | Scheduled ~17:00 `Asia/Kolkata` FCM reminder for site engineers missing today's DPR (Blaze; disable with `DPR_NUDGE_SCHEDULE_ENABLED=false`) |

When `firebaseEnabledProvider` is true, **Invite users** calls `inviteMember`
(`FirebaseAdminInvitesRepository`). Demo mode keeps local FakeAuth invites.
Local tray DPR nudge still covers demos without Blaze — see [FCM.md](FCM.md).

## Emulators

```bash
cd firebase
firebase emulators:start
```

UI: http://127.0.0.1:4000 — Auth `9099`, Firestore `8080`, Functions `5001`, Storage `9199`.

Point the app at emulators only after options are configured (see FlutterFire
emulator docs). Demo mode does not need emulators.

## CI

CI stays on demo mode (`isConfigured = false`). Do not commit real API keys or
service account JSON into this repository.
