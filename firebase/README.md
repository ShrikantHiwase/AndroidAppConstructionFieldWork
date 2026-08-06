# Firebase

Backend for Auth, Firestore, Storage, Functions, and FCM.

## Quick start

1. Create a Firebase project and enable Auth (email/password), Firestore, Storage, FCM.
2. Link this folder: `firebase use --add`
3. Configure the Flutter app: see [docs/Firebase_Setup.md](../docs/Firebase_Setup.md)
4. Go-live order: [docs/Go_Live_Checklist.md](../docs/Go_Live_Checklist.md)
5. Emulators: `firebase emulators:start`
6. Seed demo users: `./seed/run_seed_emulators.sh` (with emulators running)

Rules are deny-by-default with membership helpers. Expand with emulator tests
before production traffic.

## Layout

```
firebase.json
firestore.rules
firestore.indexes.json
storage.rules
functions/          # health, inviteMember, onDprWrite, onIssueWrite (+ fcm.js)
seed/               # demo_seed.json + seed_demo.js
```
