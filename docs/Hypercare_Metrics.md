# Hypercare Metrics — Pilot

Targets from the build plan. Measure during the first 2 weeks on each pilot site.

| Metric | Target | How to measure (demo / local) | Production later |
|--------|--------|-------------------------------|------------------|
| Engineer DPR adherence | ≥70% of engineers submit DPR ≥4 days/week | Pilot hub: submitted DPR days this ISO week / expected | Firestore query + FCM nudge analytics |
| DPR submit speed | Median &lt;3 min | Pilot hub: median from Today's DPR open → Submit (≥3 samples) | Instrumentation events (`dpr_submit`) |
| Issue create speed | Median &lt;90s | Pilot hub: median from New Issue open → save (need ≥3 samples) | Instrumentation events (`issue_create`) |
| Sync failure rate | &lt;2% of flush attempts | Pilot hub: error logs / total sync logs | Crashlytics + sync_events |
| Client self-serve | Client opens weekly share/PDF without PM compile | Client → Weekly progress → Share weekly PDF | Storage download metrics |

## In-app Pilot hub

Admin (and PM) → **Pilot**:

- **UAT checklist** — persisted local ticks matching [UAT_Checklist.md](UAT_Checklist.md) (35 items)
- **Live snapshot** — DPR days submitted this week, **DPR submit median**, **issue create median**, open issues, pending outbox, sync error rate from local logs
- **Share pilot PDF** — 1-tap PDF / text share of the hypercare snapshot (same `SharePort` as DPR/digest)
- **Pass/fail strip** — green when snapshot meets targets (DPR days ≥4; DPR submit median &lt;3m with ≥3 samples; issue create median &lt;90s with ≥3 samples; sync error rate &lt;2% when enough samples)

## Hypercare cadence

1. **Day 0:** Training ([Pilot_Training.md](Pilot_Training.md)); install; smoke UAT.
2. **Daily (site lead):** Confirm today's DPR; glance Digests / Pilot snapshot.
3. **End of week 1:** Review metrics vs targets; log blockers in issues.
4. **End of week 2:** Go / no-go for broader rollout; open Phase 3 only with traction.

## Store release notes (stub)

- Internal testing / TestFlight / Play internal track after Firebase project is live.
- Crashlytics + Analytics packages still deferred until FlutterFire is on; in-app
  [Telemetry.md](Telemetry.md) NoOp/deferred port records sync/health events locally for Sync status.
