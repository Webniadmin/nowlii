# Technical Debt Register

_**Scope — inherited problems only.** This file records **exclusively** debt we inherited
from the previous team / the existing system: hardcoded values, missing authentication
where it was expected, unfinished or placeholder implementations, poor legacy architectural
decisions, security holes that are not part of our own design, and legacy code that isn't
production-ready._

_This file does **not** track: stack/runtime constraints (Django, SQLite, timezone
behavior) → see `system-constraints.md`; or limitations of our own current design/
implementation → see the design notes in `architecture.md`._

_Each item: location, problem, why it matters, recommended fix, priority, status
(Open / Fixed). Priority: **P1** critical/security · **P2** important · **P3** nice-to-have._

---

## P1

### TD-001 — `nowli-ai` (:8001) is unauthenticated; the daily call limit can be bypassed
- **Location:** `nowli-ai/test17.py` (all `@app` routes, e.g. `/api/v1/session/new`,
  `/api/v1/chat-stream`); CORS `allow_origins=["*"]`.
- **Problem:** The `nowli-ai` service has **no authentication** and does not know the Django
  user (inherited: the whole service was built session-only). Our per-user daily call limit
  is enforced on Django (`POST /api/voice-calls/start/`), but the AI conversation itself
  runs on `nowli-ai`, so a user could call `:8001` directly and chat without consuming a
  Django call.
- **Why it matters:** Missing auth where it is expected — the limit is app-honest, not
  attack-proof, and the AI endpoints are open.
- **Recommended fix:** Have the app pass a short-lived signed token (or the JWT) to
  `nowli-ai`, and have `nowli-ai` validate it / call back to Django to confirm an active,
  authorized `call_id` before streaming. Lock down CORS.
- **Priority:** P1 · **Status:** Open

## P2

### TD-007 — Almost no automated tests, and the test runner is broken
- **Location:** whole repo. Correction (found 2026-07-06): `Apps/insights/tests.py` **does**
  have real tests; the other backend apps (`users`, `quests`, `subtask_generator`,
  `support`, `voice_calls`) have none, `nowli-ai` has none, frontend only the default
  `widget_test.dart`.
- **Problem:** Near-zero regression safety net. Worse, **`manage.py test` fails to even
  discover tests** — `TypeError: _path_normpath: path should be string … not NoneType`
  (a namespace-package/`Apps` discovery quirk), so the existing insights tests can't be run
  via the standard command. Changes are verified ad-hoc via `manage.py shell`.
- **Recommended fix:** Fix test discovery (e.g. ensure `Apps/__init__.py`, set a test
  runner / `pytest-django`), then add API tests (auth, quests, subtasks, voice-call
  quota/start/end). Also tracked in `future-checklist.md`.
- **Priority:** P2 · **Status:** Open

### TD-012 — A SQLite database file was committed, and the `DB_NAME=nowlii` config trap
- **Location:** `nowli-backend/nowlii` (a SQLite DB, no file extension);
  `nowli-backend/.env` (`DB_ENGINE=postgresql`, `DB_NAME=nowlii`); `docs/running-locally.md`.
- **Problem:** The inherited `.env` sets `DB_NAME=nowlii`. Running locally with
  `DB_ENGINE=sqlite3` (per the docs) but that same `DB_NAME` makes Django create a SQLite
  file literally named `nowlii`. Because it has no `.sqlite3` extension the ignore rules
  missed it and it landed in the initial baseline. It carries local data (users, possibly
  the superuser hash).
- **Why it matters:** A data-bearing binary in version control — noise and a potential
  data/secret exposure (a legacy config/hygiene problem).
- **Recommended fix (remediated in tracking):** Untracked (`git rm --cached`) and added to
  `.gitignore`. Still open: the data remains in git **history** (initial commit) — scrub if
  sensitive; and fix the config so no extension-less DB file is created locally (e.g. set a
  local `DB_NAME=db.sqlite3`).
- **Priority:** P2 · **Status:** Open (tracking removed; history + config trap remain)

### TD-013 — Companion seed data uses broken Google Drive `/view` URLs
- **Location:** the `Apps/users` data migration that seeds `NowliiPredefinedOption` rows
  (the 6 companions milo/bloop/gumo/knotty/fizzy/zee); `avatar_logo` values are
  `https://drive.google.com/file/d/<id>/view?usp=drive_link`.
- **Problem:** A Google Drive `/view` link returns an **HTML page** (`content-type:
  text/html`), not the image, so `Image.network` cannot render it. Any freshly-migrated DB
  gets these broken URLs. The previously-working `nowlii` DB only rendered because it had
  been **manually re-seeded** with proper S3 paths (`nowlii_logos/*.png` →
  `https://nowlii.s3.eu-north-1.amazonaws.com/...`, `content-type: image/png`).
- **Why it matters:** On a fresh DB the companion avatar is blank on the home screen and
  the avatar picker; changing the avatar looks like it "reverts to default" even though the
  selection **is** persisted (`Profile.save()` copies `predefined_option.avatar_logo`, so the
  broken URL is copied and the UI falls back to the default asset). Purely a data/URL bug,
  not a persistence bug.
- **Recommended fix:** Add a corrective data migration (or a seed management command — the
  long-pending "seed as management command" TODO) that sets the 6 `avatar_logo` values to the
  working `nowlii_logos/*.png` S3 paths, so any fresh/reset DB renders correctly. (The current
  local `db.sqlite3` was patched by hand on 2026-07-06 to unblock testing; the migration/seed
  is still unfixed.)
- **Priority:** P2 · **Status:** Open (local `db.sqlite3` data patched; seed/migration
  still produces broken URLs on a fresh DB)

## P3

### TD-014 — Monthly insights had no per-zone breakdown (Your Moves "This Month")
- **Location:** `Apps/insights/services.py` `get_monthly_analytics`,
  `Apps/insights/serializers.py` `MonthlyInsightSerializer`; frontend `MonthlyInsights` in
  `lib/models/insights_models.dart`, consumed by `_buildMovesSection()` in
  `screen/progress/my_progress/my_progress.dart`.
- **Problem:** `WeeklyInsights` had `zone_progress` (per-zone completed **counts**), but
  `MonthlyInsights` did not — only `preferred_quest_types` (percentages, computed from
  **assigned** quests) + a total `quests_completed`. The first cut of "This Month" therefore
  showed a client-side **approximation** (`pct × total`), which was not real per-zone counts.
- **Recommended fix / status:** **Fixed (2026-07-06)** — extended the existing endpoint
  (no new endpoint): `get_monthly_analytics` now computes a real monthly `zone_progress`
  (same shape/logic as weekly), added `zone_progress` to `MonthlyInsightSerializer` (and the
  test fixture), added `zoneProgress` to the frontend `MonthlyInsights`, and the widget now
  reads real counts for both This Week and This Month — the approximation was removed.
- **Priority:** P3 · **Status:** Fixed (2026-07-06)

### TD-015 — "Add personal note" was a dead input (no save/persistence/display)
- **Location:** `nowli-frontend-app/lib/screen/progress/insights/insights.dart`
  (`_personalNoteController` + the note `TextField`).
- **Problem:** The previous team shipped the note input with **no** save action, no
  persistence, and no display of saved notes — the typed text went nowhere.
- **Why it matters:** A visible feature that silently did nothing.
- **Recommended fix / status:** **Fixed (2026-07-06)** by us as part of task 2C — added
  `PersonalNotesService` (per-user, SharedPreferences), an explicit "Add note" action
  (the input is multiline so keyboard-submit isn't reliable), a saved-notes list, and
  per-note delete. Logged here for the inherited-state record.
- **Priority:** P3 · **Status:** Fixed (2026-07-06)

### TD-016 — Asset filename with `?` fails to load ("Ready to make today count?.png")
- **Location:** `nowli-frontend-app/assets/svg_icons/Ready to make today count?.png`
  (referenced via `Assets.svgIcons.readyToMakeTodayCount`; used as the home-screen companion
  **fallback** image and in `contextual_onboarding/popup_screen.dart`).
- **Problem:** Runtime error `Unable to load asset: "assets/svg_icons/Ready to make today
  count?.png"`. The filename contains `?` (and spaces) — `?` is invalid in Windows filenames,
  so the asset isn't bundled/loadable. Same class of bug as the earlier `&`/space filenames.
- **Why it matters:** When a user has no avatar the home companion fallback throws instead
  of showing the placeholder. Found while redeploying for the Progress/Insights task (unrelated
  to it).
- **Recommended fix:** Rename the asset to an ASCII, no-`?`/space name (e.g.
  `ready_to_make_today_count.png`), update `pubspec.yaml` + the `Assets` reference.
- **Priority:** P3 · **Status:** Open

### TD-005 — AI session still greets a hardcoded "User"
- **Location:** `nowli-frontend-app/lib/screen/ai_call/ai_voice.dart` `_createAiSession()`
  (`userName: 'User'`).
- **Problem:** Inherited hardcoded value — the `nowli-ai` session passes a generic display
  name instead of the logged-in user.
- **Why it matters:** The companion addresses everyone as "User" — cosmetic, but sloppy.
- **Recommended fix:** Read the stored username/profile name and pass it as `user_name`.
- **Priority:** P3 · **Status:** Fixed (2026-07-06) — `ai_voice.dart` `_resolveUserName()`
  now uses the profile name → stored username; the last-resort fallback is a neutral
  greeting, never a hardcoded identity. Added `StorageService.getUsername()`.

### TD-008 — Dead / unrouted AI-call screen variants
- **Location:** `nowli-frontend-app/lib/screen/ai_call/` — `ai_calling.dart`,
  `ai_calling_two.dart`, `AiCalling_two.dart`, `ai_voice_calling_screen.dart` are not in
  the router (only `ai_voice.dart`, `call_summary_screen.dart`, `pop_po_sahre.dart` are).
- **Problem:** Inherited near-duplicate versions of the call screen; unclear which is
  canonical without checking the router.
- **Why it matters:** Confusing; risk of editing the wrong file.
- **Recommended fix:** Relocate to `lib/experimental/` or remove, per the cleanup rule.
- **Priority:** P3 · **Status:** Fixed (2026-07-06) — moved (`git mv`, history preserved) to
  `lib/experimental/ai_call/`. `screen/ai_call/` now holds only the routed screens
  (`ai_voice`, `call_summary_screen`, `pop_po_sahre`). See `cleanup-log.md`.

### TD-009 — Unused methods in `ai_voice.dart`
- **Location:** `nowli-frontend-app/lib/screen/ai_call/ai_voice.dart` — `_toggleMute`,
  `_handleWebVoiceInput`, `_getEmotionIcon`, `_getEmotionColor` (analyzer: `unused_element`).
- **Problem:** Inherited dead code (pre-existing; not introduced by the limit feature).
- **Why it matters:** Noise; `_getEmotion*` hint at an emotion UI that was never wired.
- **Recommended fix:** Remove, or wire the emotion display if intended.
- **Priority:** P3 · **Status:** Fixed (2026-07-06) — commented out (not deleted) in
  `ai_voice.dart` with a `TD-009` note, so the code is preserved but no longer dead-warns.

### TD-010 — Speech `listenFor` does not match the call duration
- **Location:** `nowli-frontend-app/lib/screen/ai_call/ai_voice.dart` `_startListening()`
  (`listenFor: Duration(minutes: 10)`).
- **Problem:** Inherited leftover constant — speech is told to listen for 10 minutes.
- **Why it matters:** Harmless today, but a misleading magic number.
- **Recommended fix:** Tie it to the call's remaining time or a sensible per-utterance value.
- **Priority:** P3 · **Status:** Fixed (2026-07-06) — `listenFor` set to 5 minutes to match
  the base call duration.

### TD-011 — `print()` used for logging; deprecated `withOpacity`
- **Location:** across the frontend (e.g. `ai_voice.dart`, all services).
- **Problem:** The inherited codebase logs with `print()` (`avoid_print`) and uses the
  deprecated `withOpacity` (`deprecated_member_use`) throughout. New code follows the
  existing style for consistency until a cleanup pass.
- **Why it matters:** Not production-grade logging; deprecated API usage.
- **Recommended fix:** Introduce a logging util and migrate `withOpacity` → `withValues`
  in a dedicated lint-cleanup pass.
- **Priority:** P3 · **Status:** Open

### TD-017 — Call screen mic icon flickered (tracked the raw speech lifecycle)
- **Location:** `nowli-frontend-app/lib/screen/ai_call/ai_voice.dart` — the mic button
  decoration read `_isListening` directly.
- **Problem:** Inherited behavior — `_isListening` mirrors the raw `speech_to_text`
  lifecycle, which flips true/false on every pause between phrases (plus periodic
  restarts), so the mic icon constantly toggled red ↔ normal (looked like a bug).
- **Recommended fix / status:** **Fixed (2026-07-06)** — added a debounced visual flag
  `_micActive` driven by the existing callbacks: it goes active immediately on a speaking
  event (`onResult` with text) and returns to normal only after ~1s of silence via a single
  self-resetting `Timer` (`_micOffTimer`); a resumed speech event cancels the pending
  turn-off. Recognition/restart logic and the icon's design are unchanged.
- **Priority:** P3 · **Status:** Fixed (2026-07-06)

### TD-018 — Call timer shifted the whole layout (proportional Wosker digits)
- **Location:** `ai_voice.dart` — the timer `Text`s (`Wosker`, size 52) sat in a
  shrink-to-fit `Flexible`/`FittedBox`.
- **Problem:** Inherited — `Wosker` has proportional digits (a "1" is narrower than an
  "8"), so as the time changed the timer's width changed and the whole centered row (and
  design) visibly "danced".
- **Recommended fix / status:** **Fixed (2026-07-06)** — wrapped the timer in a
  fixed-width `SizedBox` (left-aligned, `scaleDown` kept) so its width is constant; font,
  size and colors are unchanged. (If any residual per-digit shimmer is observed on-device,
  the fallback is per-character fixed slots.)
- **Priority:** P3 · **Status:** Fixed (2026-07-06)

### TD-019 — Last minute turned the whole background orange
- **Location:** `ai_voice.dart` `_backgroundColor` returned an orange
  (`0xFFFF8F26`) whenever `_isTimeWarningActive`.
- **Problem:** Inherited — during the final-minute warnings the entire screen background
  went orange, which was not wanted.
- **Recommended fix / status:** **Fixed (2026-07-06)** — removed the orange branch from
  `_backgroundColor` only; the background stays blue. The warning cards and `_timerColor`
  were left intentionally unchanged (per product request: remove *only* the background tint).
- **Priority:** P3 · **Status:** Fixed (2026-07-06)

### TD-020 — Final 10 seconds used a fullscreen overlay
- **Location:** `ai_voice.dart` `_buildCountdownOverlay()` — a `Positioned.fill` scrim with
  a huge centered number.
- **Problem:** Inherited — the last-10s countdown covered the whole screen instead of using
  the app's existing in-call notice style.
- **Recommended fix / status:** **Fixed (2026-07-06)** — replaced with
  `_buildCountdownNotice()` that reuses the shared `_noticeCard` (same style as the
  30-seconds warning) and counts 10 → 1 on that card; the old overlay was commented out
  (preserve-not-delete), no fullscreen overlay remains.
- **Priority:** P3 · **Status:** Fixed (2026-07-06)

---

## Reclassified out of this file (2026-07-06)

During a review of what counts as inherited debt, four earlier entries were moved out
because they are **not** inherited problems:

- **TD-002** (daily window is UTC, not user-local) → **system constraint** →
  `system-constraints.md` (SC-001).
- **TD-003** (`select_for_update` is a no-op on SQLite) → **system constraint** →
  `system-constraints.md` (SC-002).
- **TD-004** (multi-account limit bypass) → **our current design's known limitation** →
  design notes in `architecture.md`.
- **TD-006** (no quota pre-check at the call entry points) → **our current design's known
  limitation** → design notes in `architecture.md`.

IDs are not reused; the gaps above are intentional so existing references stay valid.
