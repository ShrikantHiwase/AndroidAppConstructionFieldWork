# Construction Management Field App

Flutter + Firebase field evidence OS for mid-market construction contractors (India / emerging markets first), based on the RAYNS requirements and an extended product plan.

## Documents

- [Requirements (PDF)](Construction%20Management%20Field%20App.pdf)
- [Requirements (PPTX)](Construction%20Management%20Field%20App.pptx)
- [Holistic build plan (canonical)](docs/Construction_Field_App_Build_Plan.md)

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
| FlutterFire configure + pilot launch | Next (needs your Firebase project) |
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
