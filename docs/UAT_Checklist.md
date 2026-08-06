# UAT Checklist — Pilot Sites

Run on mid/low-end Android first. Mark each item in Admin → **Pilot** (or tick here).

## Environment

- [ ] App installs / launches on pilot device (API 24+)
- [ ] Warm start feels &lt;2s on pilot hardware
- [ ] Offline badge visible on home
- [ ] Demo mode banner **DEMO** (or **FIREBASE** after FlutterFire)

## Auth & roles

- [ ] Engineer / PM / QA / Client / Admin can sign in (demo or Firebase)
- [ ] Project switcher changes active project
- [ ] Biometric unlock stub toggles and simulates resume lock
- [ ] Client cannot create issues, edit DPR, or mutate site ops

## Issues & RFIs

- [ ] Create issue with demo GPS + photo
- [ ] Create issue offline → appears pending sync → flushes online
- [ ] Status workflow Open → In Progress → Resolved → Closed with audit
- [ ] PM can assign; engineer cannot
- [ ] RFI + threaded comment
- [ ] Voice note on issue detail

## Documents

- [ ] Browse Project → Discipline → Type → Files
- [ ] Open seeded PDF/TXT/CSV viewer (zoom/search/page)
- [ ] Engineer upload stub; client blocked

## DPR & drawings

- [ ] Today's DPR draft + submit in &lt;3 minutes
- [ ] Share DPR PDF via system sheet; text share still works
- [ ] Voice note on DPR after first save
- [ ] Drawing pin linked to an issue

## Site ops

- [ ] Safety toolbox without photo; observation/incident requires photo
- [ ] QA fail rejected without photo; pass allowed
- [ ] Labour muster + material inward/consumption
- [ ] Client blocked from site ops mutations

## Digests & sync

- [ ] 5 PM nudge prefs + Simulate 5 PM check
- [ ] PM digest lists open issues/RFIs/blockers; Share digest PDF works
- [ ] Sync status shows logs; cleanup does not crash
- [ ] Conflict policy labels visible on flush (LWW / append / audited)

## Firebase (when configured)

- [ ] `FirebaseOptionsGate.isConfigured = true` and banner shows FIREBASE
- [ ] Real Auth user with membership docs signs in
- [ ] Rules deny cross-project reads (emulator or staging)

## Sign-off

| Site | Date | Lead | Result |
|------|------|------|--------|
| | | | Pass / Fail / Conditional |
