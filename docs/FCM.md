# Push notifications (FCM)

Demo-safe client + Cloud Functions delivery. Real device pushes need
`flutterfire configure`, Cloud Messaging enabled, and Functions deployed.

## App behaviour

| Mode | Behaviour |
|------|-----------|
| **Demo** (`firebaseEnabled == false`) | `NoOpPushNotificationService` returns `demo-fcm-token-{userId}`. Assign / status changes append to a local inbox on Sync status. Background handler is **not** registered. |
| **Firebase on** | Permission + token → prefs + `fcm_tokens/{uid}`. Foreground, notification-open, cold-start, and **background** messages → local inbox. |

## Server behaviour (Functions)

| Trigger | Action |
|---------|--------|
| `onDprWrite` | When `submitted` flips to true → `admin.messaging().send` to creator token |
| `onIssueWrite` | Assignee change → assignee; status change → assignee + creator |
| `onRfiWrite` | Same assign/status fan-out for RFIs (`rfi_assigned` / `rfi_status`) |

## Local DPR nudge (not FCM)

Digests prefs schedule a **device-local** daily tray reminder via
`flutter_local_notifications` (`DprNudgeScheduler`). Cloud cron / FCM fan-out
for 5 PM remains deferred (needs Blaze + live Messaging).

`sendToUser` soft-skips when: `FCM_SEND_ENABLED=false`, no uid, no token doc, or demo token prefix. Send errors are logged, never thrown.

## Paths

- Client: `lib/core/notifications/` (`fcm_background.dart`, mapper, services)
- Rules: `firebase/firestore.rules` → `fcm_tokens/{uid}` (owner R/W)
- Functions: `firebase/functions/fcm.js`, `index.js`
- Android channel: `field_alerts` (MainActivity + manifest meta-data)

## Operator checklist

1. Enable Cloud Messaging in Firebase console
2. `flutterfire configure` + `FirebaseOptionsGate.isConfigured = true`
3. Deploy: `firebase deploy --only functions,firestore:rules`
4. Sign in on a device → grant notification permission → confirm token on **Sync status**
5. Submit a DPR, assign an issue/RFI, or change status → recipient should get a push (and inbox row)

Dry-run without Messaging: set `FCM_SEND_ENABLED=false` on the Functions runtime.

## Out of scope

- Topics / marketing campaigns
- iOS APNs key upload (required for iOS push)
- Scheduled **Cloud** 5 PM DPR nudge Function (local tray nudge ships; Blaze cron later)
- `flutter_local_notifications` as a full FCM replacement
