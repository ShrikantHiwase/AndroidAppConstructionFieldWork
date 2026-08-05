/**
 * Phase 0 stub — replace with invite membership writes, FCM fan-out, and audit.
 * Deploy only after `firebase use <project>` and flutterfire configure.
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");

initializeApp();

exports.health = onCall(async () => {
  return { ok: true, phase: "0-scaffold" };
});

exports.inviteMember = onCall(async () => {
  throw new HttpsError(
    "unimplemented",
    "Invite flow lands in Phase 1 (Admin SDK membership write)."
  );
});
