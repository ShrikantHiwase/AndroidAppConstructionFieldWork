#!/usr/bin/env node
/**
 * Seeds Auth + Firestore with the RAYNS demo org/users.
 *
 * Emulators (default):
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
 *   FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
 *   node seed/seed_demo.js
 *
 * Production (dangerous — only with a staging project):
 *   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json node seed/seed_demo.js
 *
 * Requires: cd firebase/functions && npm install
 * (reuses firebase-admin from functions/)
 */
const path = require("path");
const fs = require("fs");

const seedPath = path.join(__dirname, "demo_seed.json");
const seed = JSON.parse(fs.readFileSync(seedPath, "utf8"));

// Prefer local functions node_modules for firebase-admin.
const adminPath = path.join(__dirname, "../functions/node_modules/firebase-admin");
let admin;
try {
  admin = require(adminPath);
} catch (_) {
  admin = require("firebase-admin");
}

const usingEmulators =
  !!process.env.FIRESTORE_EMULATOR_HOST ||
  !!process.env.FIREBASE_AUTH_EMULATOR_HOST;

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || "demo-rayns",
  });
}

const auth = admin.auth();
const db = admin.firestore();

async function upsertUser(user) {
  let record;
  try {
    record = await auth.getUserByEmail(user.email);
    await auth.updateUser(record.uid, {
      password: user.password,
      displayName: user.displayName,
    });
  } catch (e) {
    if (e.code !== "auth/user-not-found") throw e;
    record = await auth.createUser({
      email: user.email,
      password: user.password,
      displayName: user.displayName,
      emailVerified: true,
    });
  }
  return record.uid;
}

async function main() {
  console.log(
    usingEmulators
      ? "Seeding against Firebase emulators…"
      : "Seeding against LIVE Firebase (ensure this is a staging project)…"
  );

  for (const [orgId, data] of Object.entries(seed.organizations)) {
    await db.collection("organizations").doc(orgId).set(data, { merge: true });
    console.log(`organization ${orgId}`);
  }

  for (const [projectId, data] of Object.entries(seed.projects)) {
    await db.collection("projects").doc(projectId).set(data, { merge: true });
    console.log(`project ${projectId}`);
  }

  for (const user of seed.authUsers) {
    const uid = await upsertUser(user);
    console.log(`auth ${user.email} → ${uid}`);
    for (const projectId of user.projectIds) {
      const project = seed.projects[projectId];
      const membershipId = `${uid}_${projectId}`;
      await db
        .collection("memberships")
        .doc(membershipId)
        .set(
          {
            userId: uid,
            orgId: project.orgId,
            projectId,
            role: user.role,
            active: true,
            email: user.email,
            displayName: user.displayName,
          },
          { merge: true }
        );
      console.log(`  membership ${membershipId} (${user.role})`);
    }
  }

  console.log("Seed complete.");
  console.log(
    "App: flutterfire configure → set FirebaseOptionsGate.isConfigured=true → sign in with demo emails / demo1234"
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
