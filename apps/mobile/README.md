# Construction Field App (mobile)

Phase 0 scaffold for the RAYNS construction field app.

## Structure

```
lib/
  app/                 MaterialApp + Riverpod shell
  core/                theme, constants, shared widgets
  features/            auth, projects, issues, rfis, documents, dpr, sync, admin
  sync/outbox/         offline outbox contracts
  l10n/                ARB (en + hi stub)
```

## Commands

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter run
```

Firebase packages are in `pubspec.yaml`. Until you run `flutterfire configure` and
set `FirebaseOptionsGate.isConfigured = true`, the app uses demo auth. Full steps:
[docs/Firebase_Setup.md](../../docs/Firebase_Setup.md).

## Auth (Phase 1)

`FakeAuthRepository` when Firebase is not configured; `FirebaseAuthRepository`
when it is. See root README for demo emails. Biometric unlock is a preference +
unlock screen stub; wire `local_auth` after FlutterFire.

## Issues / RFIs (Phase 1)

Offline-first `LocalFieldRecordsRepository` with sync outbox. Demo GPS/photo buttons stand in for geolocator/image_picker until Firebase + device plugins are wired. Toggle offline from the cloud icon on home/issues.

## Documents (Phase 1)

Browse Project → Discipline → Document Type → Files. Seeded demo PDF/TXT/CSV. Upload uses
`DocumentFilePicker` (Fake `local://` stub by default; native `file_picker` with
`USE_NATIVE_SENSORS=true`). Viewer supports search; PDF uses demo pages with zoom/page
nav (pdfrx later).

## Sync (Phase 1)

`LocalSyncEngine` logs flushes, applies conflict-policy labels, and supports cleanup. Open **Sync** from the home app bar. Going online auto-flushes the outbox. When Firebase is enabled, flush writes issues/RFIs/comments to Firestore and pulls remote issues/RFIs (demo mode uses a no-op sink). Sync status shows a soft **8MB local cache** meter (issue + site-ops + pin + DPR + voice + docs media stubs); **Cleanup** trims sync logs and clears uploaded `local://` paths once a remote/demo URL exists. **Telemetry** records sync/health events locally (`TelemetryPort` NoOp) until Crashlytics/Analytics packages are added — see [docs/Telemetry.md](../../docs/Telemetry.md). **Secure store** holds session email, biometrics flag, and FCM token (Fake by default; platform via `--dart-define=USE_SECURE_STORAGE=true`) — see [docs/Secure_Store.md](../../docs/Secure_Store.md).

## Phase 2a — DPR & drawing pins

- **Today's DPR:** weather, manpower, activities (+ demo photos), blockers; submit; copy WhatsApp/PDF summary.
- **Pin on Drawing:** seeded GA Plan sheet; select an issue, optionally attach evidence photo (camera/gallery), tap to drop a punch pin. Photos enqueue Storage upload then create (demo → `demo://`).

## Phase 2b — Site ops

Hub with Safety / QA/QC / Labour / Materials tabs. Photo required on safety observations/incidents and failed QA checks. Labour is supervisor-led muster (demo geofence OK) with **optional** evidence photo. Materials support inward + consumption logs.

## Voice notes & digests

- **Voice notes:** demo capture on DPR (after first draft save) and issue detail. Stores stub audio path + transcript; offline marks transcript pending.
- **Digests:** engineer **Reminders** / PM **Digests** — 5 PM DPR nudge prefs, simulate evening check, PM digest of open issues/RFIs/blockers with copy-to-clipboard share.

## Pilot / UAT

PM and Admin → **Pilot**: local UAT checklist + hypercare snapshot (DPR days this week, open issues, sync error rate). Docs: `docs/Pilot_Training.md`, `docs/UAT_Checklist.md`, `docs/Hypercare_Metrics.md`.

## Admin invites

Admin → **Invite user**: create pending invites (email, role, projects). Invitees sign in with that email + `demo1234` and get invite-scoped memberships. Demo accounts stay unchanged. Email delivery via Cloud Functions comes with production Firebase.

## Device sensors

`geolocator` / `image_picker` / `local_auth` are wired behind Fake defaults.
Enable on device: `flutter run --dart-define=USE_NATIVE_SENSORS=true`.
See [docs/Device_Sensors.md](../../docs/Device_Sensors.md).
