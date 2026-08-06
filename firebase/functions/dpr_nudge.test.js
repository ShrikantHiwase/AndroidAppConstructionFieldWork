const { describe, it } = require("node:test");
const assert = require("node:assert/strict");

const {
  localDayKey,
  membershipNeedsDprNudge,
  dprCoversUserDay,
  collectNudgeTargets,
  runDailyDprNudge,
} = require("./dpr_nudge");

describe("dpr_nudge helpers", () => {
  it("localDayKey formats YYYY-MM-DD in timezone", () => {
    const key = localDayKey(
      new Date("2026-08-06T11:30:00.000Z"),
      "Asia/Kolkata"
    );
    assert.equal(key, "2026-08-06");
  });

  it("membershipNeedsDprNudge gates on active site_engineer", () => {
    assert.equal(
      membershipNeedsDprNudge({ role: "site_engineer", active: true }),
      true
    );
    assert.equal(
      membershipNeedsDprNudge({ role: "client", active: true }),
      false
    );
    assert.equal(
      membershipNeedsDprNudge({ role: "site_engineer", active: false }),
      false
    );
  });

  it("dprCoversUserDay requires submitted matching day", () => {
    const target = {
      uid: "u1",
      projectId: "proj_a",
      dayKey: "2026-08-06",
    };
    assert.equal(
      dprCoversUserDay(
        {
          projectId: "proj_a",
          createdBy: "u1",
          submitted: true,
          reportDate: "2026-08-06T00:00:00.000Z",
        },
        target
      ),
      true
    );
    assert.equal(
      dprCoversUserDay(
        {
          projectId: "proj_a",
          createdBy: "u1",
          submitted: false,
          reportDate: "2026-08-06T00:00:00.000Z",
        },
        target
      ),
      false
    );
    assert.equal(
      dprCoversUserDay(
        {
          projectId: "proj_a",
          createdBy: "u1",
          submitted: true,
          reportDate: "2026-08-05T00:00:00.000Z",
        },
        target
      ),
      false
    );
  });

  it("collectNudgeTargets skips users with submitted DPR", () => {
    const memberships = [
      {
        userId: "u1",
        projectId: "proj_a",
        role: "site_engineer",
        active: true,
      },
      {
        userId: "u2",
        projectId: "proj_a",
        role: "site_engineer",
        active: true,
      },
      {
        userId: "u3",
        projectId: "proj_a",
        role: "client",
        active: true,
      },
    ];
    const dprs = [
      {
        projectId: "proj_a",
        createdBy: "u1",
        submitted: true,
        reportDate: "2026-08-06T00:00:00.000Z",
      },
    ];
    const targets = collectNudgeTargets(memberships, dprs, {
      dayKey: "2026-08-06",
    });
    assert.deepEqual(targets.map((t) => t.uid), ["u2"]);
  });

  it("runDailyDprNudge soft-skips when disabled", async () => {
    const out = await runDailyDprNudge({
      memberships: [
        {
          userId: "u1",
          projectId: "p",
          role: "site_engineer",
          active: true,
        },
      ],
      dprs: [],
      send: async () => ({ ok: true }),
      enabled: false,
      now: new Date("2026-08-06T11:30:00.000Z"),
    });
    assert.equal(out.skipped, true);
    assert.equal(out.reason, "DPR_NUDGE_SCHEDULE_ENABLED=false");
    assert.equal(out.sent, 0);
  });

  it("runDailyDprNudge sends to uncovered engineers", async () => {
    const sent = [];
    const out = await runDailyDprNudge({
      memberships: [
        {
          userId: "u1",
          projectId: "proj_a",
          orgId: "org",
          role: "site_engineer",
          active: true,
        },
      ],
      dprs: [],
      send: async (uid, payload) => {
        sent.push({ uid, payload });
        return { ok: true, messageId: "m1" };
      },
      now: new Date("2026-08-06T11:30:00.000Z"),
      timeZone: "Asia/Kolkata",
      enabled: true,
    });
    assert.equal(out.skipped, false);
    assert.equal(out.targetCount, 1);
    assert.equal(out.sent, 1);
    assert.equal(sent[0].uid, "u1");
    assert.equal(sent[0].payload.data.type, "dpr_nudge");
    assert.equal(sent[0].payload.data.projectId, "proj_a");
    assert.equal(sent[0].payload.data.dayKey, "2026-08-06");
  });
});
