# Construction Management Field App

Flutter + Firebase field evidence OS for mid-market construction contractors (India / emerging markets first), based on the RAYNS requirements and an extended product plan.

## Documents

- [Requirements (PDF)](Construction%20Management%20Field%20App.pdf)
- [Requirements (PPTX)](Construction%20Management%20Field%20App.pptx)
- [Holistic build plan (canonical)](docs/Construction_Field_App_Build_Plan.md)
- [Firebase setup](docs/Firebase_Setup.md)
- [Pilot training](docs/Pilot_Training.md)
- [UAT checklist](docs/UAT_Checklist.md)
- [Hypercare metrics](docs/Hypercare_Metrics.md)
- [Device sensors](docs/Device_Sensors.md)
- [Go-live checklist](docs/Go_Live_Checklist.md)
- [FCM / push scaffolding](docs/FCM.md)
- [Background sync](docs/Background_Sync.md)

## Repo layout

```
apps/mobile/       Flutter app (Android primary, iOS parity)
firebase/          Firestore/Storage rules, indexes, Functions stubs, emulators
docs/              Build plan and training
.github/workflows/ CI
```

## Planned stack

- **App:** Flutter + Riverpod
- **Backend:** Firebase Auth, Firestore, Storage, Cloud Functions, FCM
- **Local DB:** Drift (Phase 1) + sync outbox
- **Architecture:** Offline-first with local cache + sync outbox
- **CI / quality:** GitHub Actions, Crashlytics + Analytics (Phase 1)

## Status

| Phase | Status |
|-------|--------|
| Plan + decisions | Done |
| Phase 0 Foundations (scaffold, rules, CI, i18n stub) | Done |
| Phase 1 auth / RBAC (demo accounts) | Done |
| Phase 1 issues/RFIs + offline outbox | Done |
| Phase 1 documents + PDF viewer | Done |
| Offline sync hardening (logs/cleanup/status) | Done |
| Phase 2a DPR + drawing pins | Done |
| Phase 2b Safety / QA / labour / materials | Done |
| Firebase packages + auth switch (demo fallback) | Done |
| Voice notes + smart digests | Done |
| Pilot / UAT pack (training + hub) | Done |
| Admin invites (local / demo) | Done |
| Device sensors (GPS/camera/biometrics) | Done |
| Firebase go-live prep (seed + Functions) | Done |
| Firestore outbox push + issue/RFI pull | Done |
| Firestore module sync (DPR/ops/docs/pins) | Done |
| Storage upload for issue evidence | Done |
| Storage upload for documents | Done |
| Voice notes Firestore/Storage sync | Done |
| FCM push scaffolding | Done |
| Workmanager + connectivity background sync | Done |
| FCM Admin.messaging + background handlers | Done |
| Firebase inviteMember callable (admin UI) | Done |
| RFI FCM assign/status parity | Done |
| FlutterFire configure + store release | Next (needs your Firebase project) |
| Phase 3 Enterprise hooks | Deferred |

## Demo login (local demo mode)

App stays in demo mode until `flutterfire configure` sets
`FirebaseOptionsGate.isConfigured = true` (see [docs/Firebase_Setup.md](docs/Firebase_Setup.md)).

Password for all: `demo1234`

| Email | Role |
|-------|------|
| engineer@demo.rayns | Site Engineer |
| pm@demo.rayns | Project Manager |
| qa@demo.rayns | QA/QC |
| client@demo.rayns | Client (read-only) |
| admin@demo.rayns | Admin |

## Decisions locked

1. **Positioning:** Hybrid — mid-market field core first; enterprise hooks later
2. **Stack:** Flutter + Firebase (Approach A)
3. **Phase 2 split:** 2a = DPR + drawing pins; 2b = rest after pilot
4. **Admin (MVP):** in-app invites/roles; web console in Phase 3
5. **Auth (MVP):** email + org invite codes first; phone auth optional later (SMS cost)

## Getting started

```bash
cd apps/mobile
flutter pub get
flutter gen-l10n
flutter test
flutter run
```

Firebase project wiring: [docs/Firebase_Setup.md](docs/Firebase_Setup.md) · [firebase/README.md](firebase/README.md).
