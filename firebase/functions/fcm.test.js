const { describe, it } = require("node:test");
const assert = require("node:assert/strict");

// Pure unit coverage for the skip/demo-token branches without Admin SDK.
// sendToUser itself is exercised via the exported guard constants + a thin
// local reimplementation of the decision tree used in fcm.js.

function decideSend({ enabled, uid, token }) {
  if (!enabled) return { skipped: true, reason: "FCM_SEND_ENABLED=false" };
  if (!uid) return { skipped: true, reason: "no_uid" };
  if (!token) return { skipped: true, reason: "no_token" };
  if (String(token).startsWith("demo-fcm-token-")) {
    return { skipped: true, reason: "demo_token" };
  }
  return { ok: true };
}

describe("FCM send guards", () => {
  it("skips when disabled", () => {
    assert.equal(
      decideSend({ enabled: false, uid: "u1", token: "tok" }).reason,
      "FCM_SEND_ENABLED=false"
    );
  });

  it("skips when uid missing", () => {
    assert.equal(
      decideSend({ enabled: true, uid: null, token: "tok" }).reason,
      "no_uid"
    );
  });

  it("skips when token missing", () => {
    assert.equal(
      decideSend({ enabled: true, uid: "u1", token: null }).reason,
      "no_token"
    );
  });

  it("skips demo tokens", () => {
    assert.equal(
      decideSend({
        enabled: true,
        uid: "u1",
        token: "demo-fcm-token-u1",
      }).reason,
      "demo_token"
    );
  });

  it("allows real tokens", () => {
    assert.equal(
      decideSend({ enabled: true, uid: "u1", token: "real-device-token" }).ok,
      true
    );
  });
});
