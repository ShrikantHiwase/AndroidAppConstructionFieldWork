/**
 * Pure helpers for demo Firestore seed (no firebase-admin required).
 * Used by seed_demo.js and seed_demo.test.js.
 */
const path = require("path");
const fs = require("fs");

const SEED_PATH = path.join(__dirname, "demo_seed.json");

/** Collections written after Auth + memberships. */
const FIELD_COLLECTIONS = [
  "issues",
  "rfis",
  "comments",
  "dprs",
  "folders",
  "documents",
  "drawing_pins",
  "safety_records",
  "inspections",
  "attendance_logs",
  "material_logs",
  "voice_notes",
];

const REQUIRED_ISSUE_KEYS = [
  "orgId",
  "projectId",
  "title",
  "description",
  "status",
  "createdByEmail",
  "createdAt",
  "updatedAt",
];

const REQUIRED_AUTH_KEYS = [
  "email",
  "password",
  "displayName",
  "role",
  "projectIds",
];

function loadSeed(seedPath = SEED_PATH) {
  return JSON.parse(fs.readFileSync(seedPath, "utf8"));
}

function assertString(value, label) {
  if (typeof value !== "string" || !value.trim()) {
    throw new Error(`${label} must be a non-empty string`);
  }
}

function assertIsoDate(value, label) {
  assertString(value, label);
  if (Number.isNaN(Date.parse(value))) {
    throw new Error(`${label} must be an ISO date string`);
  }
}

/**
 * Validates seed JSON shape against client fromJson expectations.
 * Does not talk to Firebase.
 */
function validateSeed(seed) {
  const errors = [];

  if (!seed.organizations || !seed.organizations.org_demo) {
    errors.push("organizations.org_demo required");
  }
  if (!seed.projects?.proj_pune_tower || !seed.projects?.proj_mumbai_metro) {
    errors.push("projects.proj_pune_tower and proj_mumbai_metro required");
  }
  if (!Array.isArray(seed.authUsers) || seed.authUsers.length < 5) {
    errors.push("authUsers must list all five demo roles");
  }

  const emails = new Set();
  for (const user of seed.authUsers || []) {
    for (const key of REQUIRED_AUTH_KEYS) {
      if (user[key] == null) errors.push(`authUsers ${user.email || "?"}: missing ${key}`);
    }
    if (user.password !== "demo1234") {
      errors.push(`${user.email}: password must remain demo1234`);
    }
    emails.add(user.email);
    for (const projectId of user.projectIds || []) {
      if (!seed.projects?.[projectId]) {
        errors.push(`${user.email}: unknown project ${projectId}`);
      }
    }
  }

  const resolveEmail = (email, label) => {
    if (!email) return;
    if (!emails.has(email)) errors.push(`${label}: unknown email ${email}`);
  };

  for (const [id, doc] of Object.entries(seed.issues || {})) {
    for (const key of REQUIRED_ISSUE_KEYS) {
      if (doc[key] == null) errors.push(`issues.${id}: missing ${key}`);
    }
    if (!seed.projects?.[doc.projectId]) {
      errors.push(`issues.${id}: unknown projectId`);
    }
    resolveEmail(doc.createdByEmail, `issues.${id}.createdByEmail`);
    resolveEmail(doc.assigneeEmail, `issues.${id}.assigneeEmail`);
    try {
      assertIsoDate(doc.createdAt, `issues.${id}.createdAt`);
      assertIsoDate(doc.updatedAt, `issues.${id}.updatedAt`);
    } catch (e) {
      errors.push(e.message);
    }
    for (const h of doc.statusHistory || []) {
      if (!h.from || !h.to || !h.changedBy || !h.changedAt) {
        errors.push(`issues.${id}: statusHistory needs from/to/changedBy/changedAt`);
      }
    }
  }

  for (const [id, doc] of Object.entries(seed.rfis || {})) {
    for (const key of [
      "orgId",
      "projectId",
      "subject",
      "question",
      "status",
      "createdByEmail",
      "createdAt",
      "updatedAt",
    ]) {
      if (doc[key] == null) errors.push(`rfis.${id}: missing ${key}`);
    }
    resolveEmail(doc.createdByEmail, `rfis.${id}.createdByEmail`);
  }

  for (const [id, doc] of Object.entries(seed.comments || {})) {
    if (!seed.issues?.[doc.parentId] && !seed.rfis?.[doc.parentId]) {
      errors.push(`comments.${id}: parentId must reference issue or rfi`);
    }
    resolveEmail(doc.authorEmail, `comments.${id}.authorEmail`);
  }

  for (const [id, doc] of Object.entries(seed.dprs || {})) {
    if (doc.submitted !== true) {
      errors.push(`dprs.${id}: seed DPR should be submitted=true for digests/nudge demos`);
    }
    resolveEmail(doc.createdByEmail, `dprs.${id}.createdByEmail`);
    if (!Array.isArray(doc.activities) || doc.activities.length < 1) {
      errors.push(`dprs.${id}: need ≥1 activity`);
    }
  }

  for (const [id, doc] of Object.entries(seed.folders || {})) {
    if (!["discipline", "documentType"].includes(doc.kind)) {
      errors.push(`folders.${id}: kind must be discipline|documentType`);
    }
    if (doc.parentId && !seed.folders?.[doc.parentId]) {
      errors.push(`folders.${id}: unknown parentId`);
    }
  }

  for (const [id, doc] of Object.entries(seed.documents || {})) {
    if (!seed.folders?.[doc.folderId]) {
      errors.push(`documents.${id}: unknown folderId`);
    }
    if (!["pdf", "txt", "csv", "other"].includes(doc.kind)) {
      errors.push(`documents.${id}: invalid kind`);
    }
    resolveEmail(doc.createdByEmail, `documents.${id}.createdByEmail`);
  }

  for (const [id, doc] of Object.entries(seed.drawing_pins || {})) {
    if (!seed.issues?.[doc.issueId]) {
      errors.push(`drawing_pins.${id}: unknown issueId`);
    }
    if (typeof doc.x !== "number" || typeof doc.y !== "number") {
      errors.push(`drawing_pins.${id}: x/y must be numbers`);
    }
    resolveEmail(doc.createdByEmail, `drawing_pins.${id}.createdByEmail`);
  }

  for (const [id, doc] of Object.entries(seed.safety_records || {})) {
    if (!["toolboxTalk", "observation", "incident"].includes(doc.kind)) {
      errors.push(`safety_records.${id}: invalid kind`);
    }
    resolveEmail(doc.createdByEmail, `safety_records.${id}.createdByEmail`);
  }

  for (const [id, doc] of Object.entries(seed.inspections || {})) {
    if (!Array.isArray(doc.items) || doc.items.length < 1) {
      errors.push(`inspections.${id}: need items`);
    }
    resolveEmail(doc.createdByEmail, `inspections.${id}.createdByEmail`);
  }

  for (const [id, doc] of Object.entries(seed.attendance_logs || {})) {
    resolveEmail(doc.createdByEmail, `attendance_logs.${id}.createdByEmail`);
    if (typeof doc.headcount !== "number") {
      errors.push(`attendance_logs.${id}: headcount required`);
    }
  }

  for (const [id, doc] of Object.entries(seed.material_logs || {})) {
    if (!["inward", "consumption"].includes(doc.kind)) {
      errors.push(`material_logs.${id}: invalid kind`);
    }
    resolveEmail(doc.createdByEmail, `material_logs.${id}.createdByEmail`);
  }

  for (const [id, doc] of Object.entries(seed.voice_notes || {})) {
    if (!seed.dprs?.[doc.parentId] && !seed.issues?.[doc.parentId]) {
      errors.push(`voice_notes.${id}: parentId must reference dpr or issue`);
    }
    resolveEmail(doc.createdByEmail, `voice_notes.${id}.createdByEmail`);
  }

  // Ensure at least one of each field collection for Pune pull-sync demos.
  for (const name of FIELD_COLLECTIONS) {
    const block = seed[name];
    if (!block || Object.keys(block).length < 1) {
      errors.push(`${name}: at least one seeded doc required`);
    }
  }

  const ga = seed.documents?.doc_seed_ga_plan;
  if (!ga || ga.name !== "GA Plan Level 02.pdf") {
    errors.push('documents.doc_seed_ga_plan must be named "GA Plan Level 02.pdf"');
  }

  return errors;
}

/**
 * @param {Record<string, {uid: string, displayName: string, email: string}>} usersByEmail
 */
function resolveActor(usersByEmail, email) {
  const user = usersByEmail[email];
  if (!user) {
    throw new Error(`Cannot resolve seed email ${email}`);
  }
  return user;
}

/**
 * Strip email hints and inject Auth uid / displayName for Firestore payloads.
 * @returns {Array<{collection: string, id: string, data: object}>}
 */
function buildFieldDocuments(seed, usersByEmail) {
  const docs = [];

  const withCreator = (raw, emailKey = "createdByEmail") => {
    const data = { ...raw };
    const email = data[emailKey];
    delete data.createdByEmail;
    delete data.assigneeEmail;
    delete data.authorEmail;
    if (email) {
      const user = resolveActor(usersByEmail, email);
      data.createdBy = user.uid;
      data.createdByName = user.displayName;
    }
    if (raw.assigneeEmail) {
      const assignee = resolveActor(usersByEmail, raw.assigneeEmail);
      data.assigneeId = assignee.uid;
      data.assigneeName = assignee.displayName;
    }
    if (raw.authorEmail) {
      const author = resolveActor(usersByEmail, raw.authorEmail);
      data.authorId = author.uid;
      data.authorName = author.displayName;
    }
    return data;
  };

  for (const [id, raw] of Object.entries(seed.issues || {})) {
    docs.push({
      collection: "issues",
      id,
      data: { id, ...withCreator(raw) },
    });
  }
  for (const [id, raw] of Object.entries(seed.rfis || {})) {
    docs.push({
      collection: "rfis",
      id,
      data: { id, ...withCreator(raw) },
    });
  }
  for (const [id, raw] of Object.entries(seed.comments || {})) {
    const data = { ...raw };
    const author = resolveActor(usersByEmail, data.authorEmail);
    delete data.authorEmail;
    docs.push({
      collection: "comments",
      id,
      data: {
        id,
        ...data,
        authorId: author.uid,
        authorName: author.displayName,
      },
    });
  }
  for (const [id, raw] of Object.entries(seed.dprs || {})) {
    docs.push({
      collection: "dprs",
      id,
      data: { id, ...withCreator(raw) },
    });
  }
  for (const [id, raw] of Object.entries(seed.folders || {})) {
    docs.push({
      collection: "folders",
      id,
      data: { id, ...raw },
    });
  }
  for (const [id, raw] of Object.entries(seed.documents || {})) {
    docs.push({
      collection: "documents",
      id,
      data: { id, ...withCreator(raw) },
    });
  }
  for (const [id, raw] of Object.entries(seed.drawing_pins || {})) {
    docs.push({
      collection: "drawing_pins",
      id,
      data: { id, ...withCreator(raw) },
    });
  }
  for (const [id, raw] of Object.entries(seed.safety_records || {})) {
    docs.push({
      collection: "safety_records",
      id,
      data: { id, ...withCreator(raw) },
    });
  }
  for (const [id, raw] of Object.entries(seed.inspections || {})) {
    docs.push({
      collection: "inspections",
      id,
      data: { id, ...withCreator(raw) },
    });
  }
  for (const [id, raw] of Object.entries(seed.attendance_logs || {})) {
    docs.push({
      collection: "attendance_logs",
      id,
      data: { id, ...withCreator(raw) },
    });
  }
  for (const [id, raw] of Object.entries(seed.material_logs || {})) {
    docs.push({
      collection: "material_logs",
      id,
      data: { id, ...withCreator(raw) },
    });
  }
  for (const [id, raw] of Object.entries(seed.voice_notes || {})) {
    docs.push({
      collection: "voice_notes",
      id,
      data: { id, ...withCreator(raw) },
    });
  }

  return docs;
}

module.exports = {
  SEED_PATH,
  FIELD_COLLECTIONS,
  loadSeed,
  validateSeed,
  buildFieldDocuments,
};
