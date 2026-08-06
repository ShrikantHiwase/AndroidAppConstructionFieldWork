# Field Evidence — Pilot Training Guide

Short training for 1–2 live pilot sites. Demo logins work without Firebase; production uses org email after `flutterfire configure` (see [Firebase_Setup.md](Firebase_Setup.md)).

## Who does what

| Role | Daily job in the app |
|------|----------------------|
| **Site Engineer** | New Issue (photo + GPS), Today's DPR (~3 min), Pin on Drawing, Site ops as needed, Reminders |
| **Project Manager** | Open queue (assign / status), DPRs, Digests (PM digest + copy), Site ops |
| **QA/QC** | Inspections (photo on fail), quality issues |
| **Client** | Read-only Issues + Documents |
| **Admin** | Documents, Digests, **Pilot** hub, **Invite user** (role + projects) |

## Demo accounts (local)

Password for all: `demo1234`

`engineer@` / `pm@` / `qa@` / `client@` / `admin@` + `demo.rayns`

## Engineer — day-one script (15 minutes)

1. Sign in → confirm active project (switcher at top).
2. **New Issue** → title, Add demo GPS, Add demo photo → Save. Toggle cloud icon offline, create another issue, go online (auto-sync).
3. **Today's DPR** → weather, manpower, ≥1 activity, blockers if any → Save draft → add demo voice note → Submit → **Share** summary to WhatsApp.
4. **Pin on Drawing** → pick issue → tap sheet to drop pin.
5. **Reminders** → leave 5 PM DPR nudge on (schedules a local tray reminder); use **Simulate 5 PM** to fire tray + inbox.

## PM — day-one script (10 minutes)

1. **Open queue** → assign an issue, move status.
2. **Digests** → review open issues/RFIs/blockers → **Share digest**.
3. Confirm client can open Documents without help.

## Offline rules to teach

- Never block create when offline (badge + cloud icon).
- Sync from Sync status (app bar) or by going online.
- Voice notes offline keep audio stub; transcript marked pending until online.

## Success targets (pilot)

See [Hypercare_Metrics.md](Hypercare_Metrics.md). Track in-app under Admin → **Pilot**.
