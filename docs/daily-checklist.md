# Daily Checklist

_The single active document for the current working day. Update **only this file**
during the day. At end of day, write a report in `daily-reports/` and reset this list
for tomorrow. Deferred items go to `future-checklist.md`._

**Day:** 2026-07-06

---

## ✅ Done today

### Project setup + docs workflow
- [x] Git init, root `.gitignore`, initial commit (`c207a32`); docs workflow (`51980d2`)

### AI Voice Call — daily limit + duration + warnings (`fdf5260`)
- [x] Backend `Apps/voice_calls` (model, `quota`/`start`/`end`, limit, race lock, admin);
      frontend gate + notices + one-time +2.5 min extension + auto-end; verified; DB untracked

### Docs reclassification (`de11a6d`)
- [x] `technical-debt.md` → inherited-only; new `system-constraints.md`; architecture design notes

### Cleanup / stabilization (`2c1595d`)
- [x] TD-005 real user name to AI session · TD-009 commented dead methods · TD-010 `listenFor` 5 min
- [x] TD-008 moved dead AI-call screens to `lib/experimental/ai_call/`
- [x] Ran locally (backend + Android emulator); fixed broken companion avatar URLs
      (TD-013 — Drive `/view` → S3) in local `db.sqlite3`; `running-*` docs updated (`1a0ec23`)

### Progress + Insights screen changes (NOT yet committed)
- [x] **1A** Progress: commented out the "Share" button (`my_progress.dart`)
- [x] **1B** Progress: "Your moves" pill → **This week / This month dropdown**
      (same pill design). **Real backend data for both** — extended the insights API so
      `monthly` returns a real `zone_progress` (services + serializer + test fixture +
      frontend model); removed the earlier % approximation (TD-014 Fixed).
- [x] **1C** Progress: commented out the Activity Trend "This week" label only (rest untouched)
- [x] **2A** Insights: commented out the "This week" label (hidden)
- [x] **2B** Insights: commented out the Monthly Overview "This month" label
- [x] **2C** Insights: **personal notes** — new `personal_notes_service.dart` (per-user,
      SharedPreferences), "Add note" action, saved list, per-note delete (X)
- [x] **2D** Insights: commented out the "Share my success" button
- [x] `flutter analyze` → 0 errors after each step; redeployed to emulator; `technical-debt.md`
      updated (TD-014 monthly-zone gap, TD-015 note-input was dead)

## 🔲 Open — pick up here next

### Next up (2026-07-07): Insights emotion sections
- [ ] **"Top Emotions" + "When feeling low, you often say…"** — two AI-fed Insights sections.
      Investigated today: AI logic exists in `nowli-ai` but is unwired/unpersisted/unsurfaced;
      categories differ. **Do not "just enable" — it needs real work.** Full report + plan +
      touch list in **`docs/insights-emotions.md`**; tracked in `future-checklist.md` (P3).


- [ ] **Commit the Progress/Insights work** (uncommitted): `my_progress.dart`,
      `insights.dart`, `personal_notes_service.dart`, `technical-debt.md`, `daily-checklist.md`
      → suggested: `feat(progress-insights): dropdown, personal notes, hide share/labels`
- [ ] Commit the earlier reclassification docs if still pending
- [ ] On-device smoke test: verify Progress "Your moves" dropdown reloads data, and the
      Insights notes (add → shows below, X deletes, persists across app restart per user)
- [ ] On-device smoke test of the voice-call flow (from the voice-call task)

## 📝 Notes / bigger items (see `technical-debt.md` / `future-checklist.md`)

- **TD-014 (P3)** monthly insights has no per-zone breakdown → "This month" Your Moves is a
  documented approximation; proper fix is a backend monthly `zone_progress`.
- **TD-001 (P1)** `nowli-ai` (:8001) unauthenticated; **TD-007 (P2)** no tests;
  **TD-012/TD-013 (P2)** committed DB data in history + broken seed URLs in the migration.
- Longer-term backlog in `future-checklist.md`.
