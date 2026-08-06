/**
 * Pure helpers + fan-out for the scheduled Cloud 5 PM DPR nudge.
 * Local tray nudge remains the demo path; this Function needs Blaze + FCM.
 */

const DEFAULT_TZ = "Asia/Kolkata";
const DEFAULT_ROLES = new Set(["site_engineer"]);

/**
 * Local calendar day YYYY-MM-DD in [timeZone].
 * @param {Date} [now]
 * @param {string} [timeZone]
 */
function localDayKey(now = new Date(), timeZone = DEFAULT_TZ) {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
}

/**
 * @param {{ role?: string, active?: boolean }} membership
 * @param {Set<string>} [roles]
 */
function membershipNeedsDprNudge(membership, roles = DEFAULT_ROLES) {
  if (!membership || membership.active === false) return false;
  return roles.has(String(membership.role || ""));
}

/**
 * True when a DPR covers today's submission for this user+project.
 * @param {{ projectId?: string, createdBy?: string, submitted?: boolean, reportDate?: string }} dpr
 * @param {{ uid: string, projectId: string, dayKey: string }} target
 */
function dprCoversUserDay(dpr, { uid, projectId, dayKey }) {
  if (!dpr || dpr.projectId !== projectId) return false;
  if (dpr.createdBy !== uid) return false;
  if (!dpr.submitted) return false;
  const rd = String(dpr.reportDate || "");
  return rd.startsWith(dayKey);
}

/**
 * @param {Array<{ userId?: string, projectId?: string, role?: string, active?: boolean }>} memberships
 * @param {Array<object>} dprs
 * @param {{ dayKey: string, roles?: Set<string> }} opts
 * @returns {Array<{ uid: string, projectId: string, orgId?: string }>}
 */
function collectNudgeTargets(memberships, dprs, { dayKey, roles = DEFAULT_ROLES }) {
  const targets = [];
  const seen = new Set();
  for (const m of memberships || []) {
    if (!membershipNeedsDprNudge(m, roles)) continue;
    const uid = m.userId;
    const projectId = m.projectId;
    if (!uid || !projectId) continue;
    const key = `${uid}_${projectId}`;
    if (seen.has(key)) continue;
    seen.add(key);
    const covered = (dprs || []).some((d) =>
      dprCoversUserDay(d, { uid, projectId, dayKey })
    );
    if (covered) continue;
    targets.push({
      uid,
      projectId,
      orgId: m.orgId || undefined,
    });
  }
  return targets;
}

/**
 * Fan-out nudges via [send] (usually sendToUser). Soft-skips are preserved.
 *
 * @param {object} args
 * @param {Array<object>} args.memberships
 * @param {Array<object>} args.dprs
 * @param {(uid: string, payload: object) => Promise<object>} args.send
 * @param {Date} [args.now]
 * @param {string} [args.timeZone]
 * @param {Set<string>} [args.roles]
 * @param {boolean} [args.enabled] when false, skip all sends
 */
async function runDailyDprNudge({
  memberships,
  dprs,
  send,
  now = new Date(),
  timeZone = DEFAULT_TZ,
  roles = DEFAULT_ROLES,
  enabled = true,
}) {
  if (!enabled) {
    return {
      skipped: true,
      reason: "DPR_NUDGE_SCHEDULE_ENABLED=false",
      dayKey: localDayKey(now, timeZone),
      sent: 0,
      results: [],
    };
  }

  const dayKey = localDayKey(now, timeZone);
  const targets = collectNudgeTargets(memberships, dprs, { dayKey, roles });
  const results = [];

  for (const t of targets) {
    const outcome = await send(t.uid, {
      title: "DPR reminder",
      body: `Submit today's DPR for project ${t.projectId}.`,
      data: {
        type: "dpr_nudge",
        projectId: t.projectId,
        orgId: t.orgId || "",
        dayKey,
      },
    });
    results.push({ ...t, ...outcome });
  }

  return {
    skipped: false,
    dayKey,
    timeZone,
    targetCount: targets.length,
    sent: results.filter((r) => r.ok).length,
    results,
  };
}

module.exports = {
  DEFAULT_TZ,
  DEFAULT_ROLES,
  localDayKey,
  membershipNeedsDprNudge,
  dprCoversUserDay,
  collectNudgeTargets,
  runDailyDprNudge,
};
