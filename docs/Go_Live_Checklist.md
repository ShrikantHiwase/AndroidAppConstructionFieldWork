# Go-live checklist

Operator steps after the Flutter feature set is merged. Demo mode works without
these; production Auth/Firestore needs a real Firebase project.

## 1. Firebase project

- [ ] Create project in [Firebase console](https://console.firebase.google.com/)
- [ ] Enable **Authentication** → Email/Password
- [ ] Create **Firestore** (production mode) + **Storage**
- [ ] Enable **Cloud Messaging**
- [ ] (Optional) Upgrade to Blaze if using scheduled Functions later

## 2. FlutterFire

```bash
cd firebase && firebase login && firebase use --add
cd ../apps/mobile
dart pub global activate flutterfire_cli
flutterfire configure
```

- [ ] Set `FirebaseOptionsGate.isConfigured = true` in `lib/firebase_options.dart`
- [ ] Keep `google-services.json` / `GoogleService-Info.plist` gitignored
- [ ] App banner shows **FIREBASE** after restart

## 3. Rules, indexes, functions

```bash
cd firebase/functions && npm install && cd ..
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

- [ ] Deploy succeeds
- [ ] `health` callable returns `{ ok: true }` (also: Sync status → **Probe health** after FlutterFire)

## 4. Seed demo org (staging / emulator)

**Emulators**

```bash
cd firebase
firebase emulators:start
# other terminal:
chmod +x seed/run_seed_emulators.sh && ./seed/run_seed_emulators.sh
```

**Staging project** (use a service account; never commit it)

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/staging-sa.json
cd firebase/functions && npm install
cd .. && node seed/seed_demo.js
```

- [ ] Demo emails sign in (`demo1234`) with memberships for Pune / Mumbai projects

## 5. Device build

```bash
cd apps/mobile
flutter run --dart-define=USE_NATIVE_SENSORS=true
```

- [ ] GPS / camera / biometrics prompts appear
- [ ] Optional: `flutter run --dart-define=USE_SECURE_STORAGE=true` so session email / FCM token use platform secure storage (see [Secure_Store.md](Secure_Store.md))
- [ ] Offline create → online sync still works (issues + DPR/site-ops/docs outboxes)
- [ ] Issue / site-ops / drawing-pin / labour-muster / material-log / DPR-activity with photo: flush uploads to Storage when Firebase is on; Fake `local://` paths stay demo URLs

- [ ] Enable **Cloud Messaging** and confirm Sync status shows an FCM token after sign-in
- [ ] Deploy Functions; submit DPR / assign issue or RFI → recipient push (or check Functions logs if token missing)
- [ ] Kill app → send test message → reopen and confirm inbox source `fcm_bg` / `fcm_launch`
- [ ] Background: create offline → leave app → confirm `sync.background_last_at` updates (or reconnect flushes)

## 6. Pilot

- [ ] Run [UAT_Checklist.md](UAT_Checklist.md) on pilot devices
- [ ] Track metrics in Admin/PM → **Pilot** and [Hypercare_Metrics.md](Hypercare_Metrics.md)
- [ ] Train crews with [Pilot_Training.md](Pilot_Training.md)

## 7. Store tracks

- [ ] Play internal testing / TestFlight build
- [ ] Crashlytics + Analytics packages (scaffolding ships as NoOp — add packages when Firebase is live; see [Telemetry.md](Telemetry.md))
- [ ] Privacy policy / data safety forms for location + camera

## Notes

- In-app admin invites: **demo** uses FakeAuth + local prefs; **Firebase on**
  calls callable `inviteMember` (`FirebaseAdminInvitesRepository`). Temp password
  remains `demo1234` until transactional email is wired.
- When Firebase is enabled, the local outbox **pushes** issues/RFIs/comments **and**
  DPR / site-ops / document metadata / drawing pins to Firestore on flush, and
  **pulls** those collections into the on-device cache.
- Issue **photo attachments**, **document uploads**, and **voice note audio** go
  through `StorageUploader` on flush; Fake `local://` paths resolve to `demo://`
  URLs without network I/O. Voice notes also push Firestore metadata (`voice_notes`).
  Firestore still stores document metadata without inline demo bodies.
