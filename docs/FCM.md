# Push notifications (FCM)

Demo-safe scaffolding for Cloud Messaging. Real device delivery needs
`flutterfire configure` + Cloud Messaging enabled on the Firebase project.

## App behaviour

| Mode | Behaviour |
|------|-----------|
| **Demo** (`firebaseEnabled == false`) | `NoOpPushNotificationService` returns `demo-fcm-token-{userId}`. Assign / status changes append to a local inbox on Sync status. |
| **Firebase on** | `FirebasePushNotificationService` requests permission, stores token in prefs + `fcm_tokens/{uid}`, listens for **foreground** messages into the same inbox. |

## Paths

- Client: `lib/core/notifications/`
- Rules: `firebase/firestore.rules` → `fcm_tokens/{uid}` (owner R/W)
- Functions: `onDprWrite` logs whether a creator token doc exists (does **not** send yet)

## Operator checklist

1. Enable Cloud Messaging in Firebase console
2. `flutterfire configure` + `FirebaseOptionsGate.isConfigured = true`
3. Deploy rules: `firebase deploy --only firestore:rules`
4. Sign in on a device → grant notification permission → confirm token on **Sync status**
5. (Later) Replace `onDprWrite` console log with `admin.messaging().send(...)`

## Out of scope (this scaffolding)

- Background / terminated message handlers (`@pragma('vm:entry-point')`)
- Topics / multicast campaigns
- iOS APNs key upload (required for iOS push)
- Workmanager background sync
