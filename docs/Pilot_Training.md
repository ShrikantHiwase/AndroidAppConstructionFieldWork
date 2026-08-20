# Field Evidence — Pilot Training Guide

Short training for 1–2 live pilot sites. Demo logins work without Firebase; production uses org email after `flutterfire configure` (see [Firebase_Setup.md](Firebase_Setup.md)).

## Who does what

| Role | Daily job in the app |
|------|----------------------|
| **Site Engineer** | New Issue (photo + GPS), Today's DPR (~3 min), Pin on Drawing, Site ops / **Safety log करो** (Hinglish), Reminders |
| **Project Manager** | Open queue (assign / status), DPRs, Digests (PM digest + copy), Weekly pack, Site ops |
| **QA/QC** | Inspections (photo on fail), quality issues |
| **Client** | Read-only **Weekly progress** (PDF/text share) + Issues + Documents |
| **Admin** | Documents, Digests, Weekly pack, **Pilot** hub, **Invite user** (role + projects) |

## Demo accounts (local)

Password for all: `demo1234`

`engineer@` / `pm@` / `qa@` / `client@` / `admin@` + `demo.rayns`

## Engineer — day-one script (15 minutes)

1. Sign in (optional **English / Hinglish** on the login screen, or translate icon on home) → confirm active project (switcher at top). Field chrome (home through Voice notes, Documents status / DPR blockers / Site ops snackbars, Digests item/nudge copy + scheduled tray reminder, share snacks/subjects/text bodies/share-sheet hint, document share summary, PDF share labels (Noto/Devanagari), domain error SnackBars, Sync conflict labels, issue/RFI notify titles, and status/role labels) follows the selected language.
2. **New Issue** / **नया Issue** → title, Add GPS / **GPS जोड़ो**, photo → **Save issue** / **Issue save करो** (duration feeds Pilot **issue create median**). Toggle cloud icon offline (**Offline** / **ऑफ़लाइन** badge), create another issue, go online (auto-sync).
3. **Today's DPR** / **आज का DPR** → weather, manpower, ≥1 activity (optional evidence photo), blockers if any → **Save draft** / **Draft save करो** → add voice note (demo stub, or live mic with `USE_NATIVE_SENSORS=true`) → **Submit DPR** / **DPR submit करो** (duration feeds Pilot **DPR submit median**) → **Share PDF** (or text) to WhatsApp. PM **DPRs** already shows yesterday's seeded report with a sample voice transcript (slab shuttering / beam depth).
4. **Pin on Drawing** → open seeded GA Plan → see seeded rebar punch (or pick issue → tap sheet to drop pin).
5. **Site ops** → Safety / QA / Labour / Materials already show seeded Pune samples (edge protection, slab pre-pour, bar muster, OPC inward); add a new Safety log with photo when practicing create.
6. **Reminders** → leave 5 PM DPR nudge on (schedules a local tray reminder); use **Simulate 5 PM** to fire tray + inbox. After FlutterFire + Blaze, Cloud `dailyDprNudge` also fans out FCM.

## PM — day-one script (10 minutes)

1. **Open queue** → seeded demo issues (Rebar / Water seepage) — open Rebar to see the seeded PM comment, assign an issue, move status.
2. **Digests** → review open issues/RFIs/blockers → **Share digest**.
3. Confirm client can open **Weekly progress** (seeded yesterday DPR) → Share weekly PDF, and Documents → seeded **GA Plan** (pdfrx) without help.

## Offline rules to teach

- Never block create when offline (badge + cloud icon).
- Sync from Sync status (app bar) or by going online.
- Voice notes offline keep audio stub; transcript marked pending until online.

## Success targets (pilot)

See [Hypercare_Metrics.md](Hypercare_Metrics.md). Track in-app under Admin → **Pilot**.
