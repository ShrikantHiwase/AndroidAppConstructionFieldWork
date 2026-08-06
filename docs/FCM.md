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
| `dailyDprNudge` | Cron ~17:00 `Asia/Kolkata` → FCM `dpr_nudge` to active `site_engineer` memberships missing a submitted DPR for that local day |

## Local DPR nudge (not FCM)

Digests prefs schedule a **device-local** daily tray reminder via
`flutter_local_notifications` (`DprNudgeScheduler`). Reminder hour is
configurable (12:00–21:00). Cloud schedule is the multi-device companion
(`dailyDprNudge`); keep the local tray for demo / offline.

**Deep links:** tapping the tray notification, an FCM open/launch message, or a
Sync status inbox row routes to Today's DPR / issue / RFI via
`NotificationDeepLink` (`payload` / `data.type`).

`sendToUser` soft-skips when: `FCM_SEND_ENABLED=false`, no uid, no token doc, or demo token prefix. Send errors are logged, never thrown.

`dailyDprNudge` soft-skips entirely when `DPR_NUDGE_SCHEDULE_ENABLED=false`.
Override cron/TZ with `DPR_NUDGE_CRON` / `DPR_NUDGE_TZ` at deploy time. Pure
fan-out logic lives in `dpr_nudge.js` (unit-tested).

## Paths

- Client: `lib/core/notifications/` (`fcm_background.dart`, mapper, services)
- Rules: `firebase/firestore.rules` → `fcm_tokens/{uid}` (owner R/W)
- Functions: `firebase/functions/fcm.js`, `dpr_nudge.js`, `index.js`
- Android channel: `field_alerts` (MainActivity + manifest meta-data)

## Operator checklist

1. Enable Cloud Messaging in Firebase console
2. `flutterfire configure` + `FirebaseOptionsGate.isConfigured = true`
3. Upgrade to **Blaze** (required for scheduled Functions)
4. Deploy: `firebase deploy --only functions,firestore:rules`
5. Sign in on a device → grant notification permission → confirm token on **Sync status**
6. Submit a DPR, assign an issue/RFI, or change status → recipient should get a push (and inbox row)
7. (Optional) Wait for 17:00 Asia/Kolkata or run `dailyDprNudge` from the console → engineers without today's submitted DPR get `dpr_nudge`

Dry-run without Messaging: set `FCM_SEND_ENABLED=false` on the Functions runtime.
Disable the schedule fan-out: `DPR_NUDGE_SCHEDULE_ENABLED=false`.

## Out of scope

- Topics / marketing campaigns
- iOS APNs key upload (required for iOS push)
- Per-user cloud nudge hour prefs (client Digests hour stays local; Cloud uses TZ cron)
- `flutter_local_notifications` as a full FCM replacement
