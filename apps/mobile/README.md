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

Firebase packages are commented in `pubspec.yaml` until `flutterfire configure` is run against a real project.

## Auth (Phase 1)

Demo repository (`FakeAuthRepository`) powers login until Firebase is configured.
See root README for demo emails. Biometric unlock is a preference + unlock screen stub; wire `local_auth` with Firebase.

## Issues / RFIs (Phase 1)

Offline-first `LocalFieldRecordsRepository` with sync outbox. Demo GPS/photo buttons stand in for geolocator/image_picker until Firebase + device plugins are wired. Toggle offline from the cloud icon on home/issues.

## Documents (Phase 1)

Browse Project → Discipline → Document Type → Files. Seeded demo PDF/TXT/CSV. Upload is a content stub until Firebase Storage + file picker. Viewer supports search; PDF uses demo pages with zoom/page nav (pdfrx later).

## Sync (Phase 1)

`LocalSyncEngine` logs flushes, applies conflict-policy labels, and supports log cleanup. Open **Sync** from the home app bar. Going online auto-flushes the outbox. Drift/Workmanager come after Firebase.
