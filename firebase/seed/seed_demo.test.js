const { describe, it } = require("node:test");
const assert = require("node:assert/strict");

const {
  FIELD_COLLECTIONS,
  loadSeed,
  validateSeed,
  buildFieldDocuments,
} = require("./seed_lib");

describe("demo seed enrichment", () => {
  const seed = loadSeed();

  it("validates without errors", () => {
    const errors = validateSeed(seed);
    assert.deepEqual(errors, []);
  });

  it("keeps demo password and five roles", () => {
    const roles = seed.authUsers.map((u) => u.role).sort();
    assert.deepEqual(roles, [
      "admin",
      "client",
      "project_manager",
      "qa_qc",
      "site_engineer",
    ]);
    for (const user of seed.authUsers) {
      assert.equal(user.password, "demo1234");
    }
  });

  it("seeds every field collection used by pull sync", () => {
    for (const name of FIELD_COLLECTIONS) {
      assert.ok(
        seed[name] && Object.keys(seed[name]).length > 0,
        `expected ${name}`
      );
    }
  });

  it("mirrors GA Plan document for client UAT", () => {
    const ga = seed.documents.doc_seed_ga_plan;
    assert.equal(ga.name, "GA Plan Level 02.pdf");
    assert.equal(ga.folderId, "folder_seed_drawings");
    assert.equal(ga.kind, "pdf");
    assert.ok(Array.isArray(ga.pdfPages) && ga.pdfPages.length >= 1);
  });

  it("resolves emails to Auth uids in field payloads", () => {
    const usersByEmail = {
      "engineer@demo.rayns": {
        uid: "uid_engineer",
        displayName: "Asha Patil",
        email: "engineer@demo.rayns",
      },
      "pm@demo.rayns": {
        uid: "uid_pm",
        displayName: "Rohit Sharma",
        email: "pm@demo.rayns",
      },
      "qa@demo.rayns": {
        uid: "uid_qa",
        displayName: "Neha Kulkarni",
        email: "qa@demo.rayns",
      },
      "admin@demo.rayns": {
        uid: "uid_admin",
        displayName: "Site Admin",
        email: "admin@demo.rayns",
      },
      "client@demo.rayns": {
        uid: "uid_client",
        displayName: "Client Viewer",
        email: "client@demo.rayns",
      },
    };

    const docs = buildFieldDocuments(seed, usersByEmail);
    assert.ok(docs.length >= FIELD_COLLECTIONS.length);

    const issue = docs.find((d) => d.id === "issue_seed_rebar");
    assert.ok(issue);
    assert.equal(issue.collection, "issues");
    assert.equal(issue.data.createdBy, "uid_engineer");
    assert.equal(issue.data.createdByName, "Asha Patil");
    assert.equal(issue.data.assigneeId, "uid_pm");
    assert.equal(issue.data.status, "open");
    assert.equal(issue.data.synced, true);
    assert.equal(issue.data.createdByEmail, undefined);

    const comment = docs.find((d) => d.id === "comment_seed_rebar_1");
    assert.equal(comment.data.authorId, "uid_pm");
    assert.equal(comment.data.parentId, "issue_seed_rebar");

    const pin = docs.find((d) => d.id === "pin_seed_rebar");
    assert.equal(pin.data.drawingId, "drawing_proj_pune_tower_ga02");
    assert.equal(pin.data.issueId, "issue_seed_rebar");

    const dpr = docs.find((d) => d.id === "dpr_seed_pune_0801");
    assert.equal(dpr.data.submitted, true);
    assert.equal(dpr.data.createdBy, "uid_engineer");

    const voice = docs.find((d) => d.id === "voice_seed_dpr");
    assert.equal(voice.data.parentId, "dpr_seed_pune_0801");
    assert.equal(voice.data.parentType, "dpr");
  });

  it("rejects bad seed shapes", () => {
    const bad = structuredClone(seed);
    delete bad.issues;
    const errors = validateSeed(bad);
    assert.ok(errors.some((e) => e.includes("issues")));
  });
});
