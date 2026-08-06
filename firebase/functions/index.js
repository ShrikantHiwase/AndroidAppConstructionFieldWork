/**
 * Cloud Functions for Field Evidence.
 *
 * - health: connectivity check
 * - inviteMember: admin creates Auth user + memberships + invite audit doc
 * - onDprWrite: FCM notify creator on DPR submit
 * - onIssueWrite: FCM on assign / status change
 *
 * Emulators: firebase emulators:start
 * Deploy: firebase deploy --only functions (after flutterfire + Blaze if needed)
 * Dry-run FCM: FCM_SEND_ENABLED=false
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { sendToUser } = require("./fcm");

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
  return { ok: true, service: "construction-field-functions", version: "2" };
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
    invitedByName,
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
  const nowIso = new Date().toISOString();
  batch.set(inviteRef, {
    id: inviteRef.id,
    email: normalized,
    role,
    orgId,
    projectIds,
    status: "accepted",
    invitedByUserId: request.auth.uid,
    invitedByName: invitedByName || "",
    acceptedUserId: userRecord.uid,
    createdAt: nowIso,
    acceptedAt: nowIso,
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
 * DPR submit → notify the creator (ack / digest hook).
 */
exports.onDprWrite = onDocumentWritten("dprs/{dprId}", async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!after) return null;
  if (after.submitted !== true) return null;
  // Only fan out when transitioning into submitted (avoid re-send on edits).
  if (before?.submitted === true) return null;

  const result = await sendToUser(after.createdBy, {
    title: "DPR submitted",
    body: `DPR for ${after.date || "today"} is on record`,
    data: {
      type: "dpr_submitted",
      dprId: event.params.dprId,
      projectId: after.projectId || "",
    },
  });

  console.log(
    JSON.stringify({
      type: "dpr_submitted",
      dprId: event.params.dprId,
      projectId: after.projectId || null,
      createdBy: after.createdBy || null,
      fcm: result,
    })
  );
  return null;
});

/**
 * Issue assign / status → notify assignee and creator.
 */
exports.onIssueWrite = onDocumentWritten("issues/{issueId}", async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!after) return null;

  const results = [];
  const issueId = event.params.issueId;
  const title = after.title || "Issue";

  const assigneeChanged =
    Boolean(after.assigneeId) && after.assigneeId !== before?.assigneeId;
  if (assigneeChanged) {
    results.push({
      kind: "issue_assigned",
      ...(await sendToUser(after.assigneeId, {
        title: "Issue assigned",
        body: title,
        data: {
          type: "issue_assigned",
          issueId,
          projectId: after.projectId || "",
        },
      })),
    });
  }

  const statusChanged =
    Boolean(before) &&
    Boolean(after.status) &&
    before.status !== after.status;
  if (statusChanged) {
    const targets = new Set();
    if (after.assigneeId) targets.add(after.assigneeId);
    if (after.createdBy) targets.add(after.createdBy);
    for (const uid of targets) {
      results.push({
        kind: "issue_status",
        uid,
        ...(await sendToUser(uid, {
          title: "Issue status updated",
          body: `${title} → ${after.status}`,
          data: {
            type: "issue_status",
            issueId,
            status: after.status,
            projectId: after.projectId || "",
          },
        })),
      });
    }
  }

  if (results.length) {
    console.log(
      JSON.stringify({
        type: "issue_fcm",
        issueId,
        results,
      })
    );
  }
  return null;
});
