/**
 * Cloud Functions for Field Evidence.
 *
 * - health: connectivity check
 * - inviteMember: admin creates Auth user + memberships + invite audit doc
 * - onDprWrite: placeholder for 5 PM nudge / digest fan-out (FCM)
 *
 * Emulators: firebase emulators:start
 * Deploy: firebase deploy --only functions (after flutterfire + Blaze if needed)
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();
const auth = getAuth();

const STAFF_ROLES = new Set([
  "admin",
  "project_manager",
  "site_engineer",
  "qa_qc",
  "client",
]);

async function callerIsAdmin(uid, orgId, projectId) {
  const snap = await db.doc(`memberships/${uid}_${projectId}`).get();
  if (!snap.exists) return false;
  const data = snap.data();
  return data.orgId === orgId && data.active === true && data.role === "admin";
}

exports.health = onCall(async () => {
  return { ok: true, service: "construction-field-functions", version: "1" };
});

/**
 * Callable: invite a member to one or more projects.
 * Request: { email, displayName?, role, orgId, projectIds: string[], temporaryPassword? }
 * Creates/updates Auth user, membership docs, and invites/{id} audit row.
 */
exports.inviteMember = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }

  const {
    email,
    displayName,
    role,
    orgId,
    projectIds,
    temporaryPassword = "demo1234",
  } = request.data || {};

  if (!email || !role || !orgId || !Array.isArray(projectIds) || !projectIds.length) {
    throw new HttpsError(
      "invalid-argument",
      "email, role, orgId, and projectIds[] are required"
    );
  }
  if (!STAFF_ROLES.has(role)) {
    throw new HttpsError("invalid-argument", `Unsupported role: ${role}`);
  }

  const adminOk = await callerIsAdmin(
    request.auth.uid,
    orgId,
    projectIds[0]
  );
  if (!adminOk) {
    throw new HttpsError("permission-denied", "Admin membership required");
  }

  const normalized = String(email).trim().toLowerCase();
  let userRecord;
  try {
    userRecord = await auth.getUserByEmail(normalized);
  } catch (e) {
    if (e.code !== "auth/user-not-found") throw e;
    userRecord = await auth.createUser({
      email: normalized,
      password: temporaryPassword,
      displayName: displayName || normalized.split("@")[0],
      emailVerified: false,
    });
  }

  const batch = db.batch();
  for (const projectId of projectIds) {
    const membershipId = `${userRecord.uid}_${projectId}`;
    batch.set(
      db.doc(`memberships/${membershipId}`),
      {
        userId: userRecord.uid,
        orgId,
        projectId,
        role,
        active: true,
        email: normalized,
        displayName: userRecord.displayName || displayName || normalized,
        invitedBy: request.auth.uid,
        updatedAt: new Date().toISOString(),
      },
      { merge: true }
    );
  }

  const inviteRef = db.collection("invites").doc();
  batch.set(inviteRef, {
    email: normalized,
    role,
    orgId,
    projectIds,
    status: "accepted",
    invitedByUserId: request.auth.uid,
    acceptedUserId: userRecord.uid,
    createdAt: new Date().toISOString(),
    acceptedAt: new Date().toISOString(),
    channel: "callable",
  });

  await batch.commit();

  // Email delivery is intentionally not wired (SendGrid/etc.). Log for ops.
  console.log(
    JSON.stringify({
      type: "invite_created",
      email: normalized,
      uid: userRecord.uid,
      projectIds,
      note: "Wire transactional email provider here",
    })
  );

  return {
    uid: userRecord.uid,
    email: normalized,
    inviteId: inviteRef.id,
    temporaryPasswordSet: true,
  };
});

/**
 * Placeholder for DPR submit → digest / nudge fan-out.
 * Looks up fcm_tokens for the creator when present; actual Admin.messaging()
 * send stays off until Cloud Messaging is enabled on the project.
 */
exports.onDprWrite = onDocumentWritten("dprs/{dprId}", async (event) => {
  const after = event.data?.after?.data();
  if (!after) return null;
  if (after.submitted !== true) return null;

  let tokenHint = null;
  if (after.createdBy) {
    const tok = await db.doc(`fcm_tokens/${after.createdBy}`).get();
    if (tok.exists) tokenHint = tok.data()?.token ? "present" : null;
  }

  console.log(
    JSON.stringify({
      type: "dpr_submitted",
      dprId: event.params.dprId,
      projectId: after.projectId,
      createdBy: after.createdBy || null,
      fcmToken: tokenHint,
      note: "Call admin.messaging().send when Cloud Messaging is live",
    })
  );
  return null;
});
