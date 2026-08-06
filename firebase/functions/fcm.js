/**
 * Shared Admin Messaging helpers.
 * Soft-fails when tokens are missing or Messaging is not enabled on the project.
 * Set FCM_SEND_ENABLED=false to force log-only (emulators / dry runs).
 */
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore } = require("firebase-admin/firestore");

const FCM_SEND_ENABLED = process.env.FCM_SEND_ENABLED !== "false";

/**
 * @param {string|null|undefined} uid
 * @param {{ title: string, body: string, data?: Record<string, string|number|boolean|null|undefined> }} payload
 * @returns {Promise<{ ok?: boolean, skipped?: boolean, reason?: string, messageId?: string, error?: string }>}
 */
async function sendToUser(uid, { title, body, data = {} }) {
  if (!FCM_SEND_ENABLED) {
    return { skipped: true, reason: "FCM_SEND_ENABLED=false" };
  }
  if (!uid) {
    return { skipped: true, reason: "no_uid" };
  }

  const tok = await getFirestore().doc(`fcm_tokens/${uid}`).get();
  if (!tok.exists || !tok.data()?.token) {
    return { skipped: true, reason: "no_token" };
  }

  const token = String(tok.data().token);
  if (token.startsWith("demo-fcm-token-")) {
    return { skipped: true, reason: "demo_token" };
  }

  const stringData = {};
  for (const [k, v] of Object.entries(data || {})) {
    stringData[k] = v == null ? "" : String(v);
  }

  try {
    const messageId = await getMessaging().send({
      token,
      notification: { title, body },
      data: stringData,
    });
    return { ok: true, messageId };
  } catch (e) {
    console.error(
      JSON.stringify({
        type: "fcm_send_failed",
        uid,
        error: e.message || String(e),
      })
    );
    return { ok: false, error: e.message || String(e) };
  }
}

module.exports = { sendToUser, FCM_SEND_ENABLED };
