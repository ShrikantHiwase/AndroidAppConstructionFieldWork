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
- [ ] `health` callable returns `{ ok: true }`

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
- [ ] Offline create → online sync still works (local outbox until Firestore field repos land)

## 6. Pilot

- [ ] Run [UAT_Checklist.md](UAT_Checklist.md) on pilot devices
- [ ] Track metrics in Admin/PM → **Pilot** and [Hypercare_Metrics.md](Hypercare_Metrics.md)
- [ ] Train crews with [Pilot_Training.md](Pilot_Training.md)

## 7. Store tracks

- [ ] Play internal testing / TestFlight build
- [ ] Crashlytics + Analytics packages (still deferred — add when Firebase is live)
- [ ] Privacy policy / data safety forms for location + camera

## Notes

- In-app admin invites still work in **demo** FakeAuth; production invites should call
  callable `inviteMember` (see `firebase/functions/index.js`).
- Field collections (issues/DPRs/…) remain local SharedPreferences until a follow-up
  wires Firestore repositories behind `firebaseEnabledProvider`.
