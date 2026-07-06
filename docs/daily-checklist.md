# Daily Checklist

_The single active document for the current working day. Update **only this file**
during the day. At end of day, write a report in `daily-reports/` and reset this list
for tomorrow. Deferred items go to `future-checklist.md`._

**Day:** 2026-07-06

---

## ✅ Done today

### Project setup
- [x] Git initialized, comprehensive root `.gitignore`, initial commit (`c207a32`)
- [x] Docs workflow: `daily-checklist.md`, `future-checklist.md`, `daily-reports/`
      (commit `51980d2`)

### AI Voice Call — daily limit + duration + warnings (committed `fdf5260`)
- [x] Analysis of the existing implementation (frontend + AI service + backend)
- [x] Backend `Apps/voice_calls`: `VoiceCall` model + migration
- [x] Backend endpoints `/api/voice-calls/` — `quota`, `start` (limit → 429, per-user race
      lock), `end`; `VOICE_CALL_DAILY_LIMIT` setting; admin
- [x] Frontend `voice_call_service.dart` + endpoint constants (fails closed on error)
- [x] Frontend `ai_voice.dart`: backend gate, start notice, 1-min + one-time "Add 2.5 min",
      30-sec warning, last-10s countdown, auto-end, warnings adapt after extension, end report
- [x] Removed the old unlimited "Add 5 minutes" flow
- [x] Verified: backend logic (quota 2→0, 3rd call 429, end idempotent, cross-user 404,
      date-based reset), `manage.py check` 0 issues, `flutter analyze` 0 errors
- [x] Untracked the stray committed `nowli-backend/nowlii` SQLite DB + gitignored it

### Documentation
- [x] `technical-debt.md` created, then **reclassified** to inherited-only (legacy) items
- [x] `system-constraints.md` created (SC-001 UTC window, SC-002 SQLite locking)
- [x] `architecture.md` design notes (per-user limit; enforced on screen open)
- [x] `project-status.md`, `daily-reports/2026-07-06.md` updated

## 🔲 Open — pick up here next

- [ ] **Commit the reclassification docs** (uncommitted): `technical-debt.md`,
      `system-constraints.md`, `architecture.md`, `project-status.md`,
      `daily-reports/2026-07-06.md`, `daily-checklist.md`
      → suggested: `docs: reclassify technical debt; add system-constraints`
- [ ] **On-device smoke test** of the voice-call flow (Android): start a call, watch notices
      at 4:00 / 4:30 / last 10s, use "Add 2.5 minutes" once, confirm auto-end and that the
      3rd call the same day is blocked. (Restart the 3 servers first — `running-on-android.md`.)

## 🧹 Optional cleanups (small, if we want them next — all still Open)

_Inherited legacy, not fixed (logged in `technical-debt.md`). None are part of the voice-call
requirement; the "real Django user" link is already satisfied via JWT on `/start/`._
- [ ] TD-005 — pass the real username to the AI session instead of hardcoded `'User'`
- [ ] TD-009 — remove unused methods in `ai_voice.dart`
- [ ] TD-010 — fix the `listenFor: 10 min` leftover constant
- [ ] TD-008 — relocate dead AI-call screen variants to `lib/experimental/`

## 📝 Notes / bigger items (see `future-checklist.md`)

- **TD-001 (P1)** `nowli-ai` (:8001) has no auth → the daily limit is app-honest but not
  attack-proof at that service. Biggest follow-up for this feature.
- **TD-007 (P2)** no test suite; **TD-012 (P2)** committed DB data still in git history.
- Longer-term backlog (secret rotation, Apple Sign-In, AI model cleanup, security, tests)
  lives in `future-checklist.md`.
