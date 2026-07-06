# Technical Debt Register

_A running record of problems we inherited from the previous team and issues found along
the way. We log here instead of fixing on sight, unless the fix is part of the current
task. Newest entries on top. Each item: location, problem, why it matters, recommended
fix, priority, status (Open / Fixed)._

Priority: **P1** critical/security · **P2** important · **P3** nice-to-have.

---

## Found during: AI Voice Call daily limit (2026-07-06)

### TD-001 — `nowli-ai` (:8001) is unauthenticated; the daily call limit can be bypassed
- **Location:** `nowli-ai/test17.py` (all `@app` routes, e.g. `/api/v1/session/new`,
  `/api/v1/chat-stream`); CORS `allow_origins=["*"]`.
- **Problem:** The per-user daily call limit is enforced on the Django backend
  (`POST /api/voice-calls/start/`). The actual AI conversation runs on the separate
  `nowli-ai` service, which has **no authentication** and does not know the Django user.
  A technically savvy user could call `:8001` directly and chat without ever consuming a
  Django call.
- **Why it matters:** The limit is enforced for the *app flow* but not at the AI service
  itself — the limit is app-honest, not attack-proof.
- **Recommended fix:** Have the app pass a short-lived signed token (or the JWT) to
  `nowli-ai`, and have `nowli-ai` validate it / call back to Django to confirm an active,
  authorized `call_id` before streaming. Lock down CORS.
- **Priority:** P1 · **Status:** Open

### TD-002 — Daily window is UTC, not the user's local midnight
- **Location:** `nowli-backend/core/settings.py` (`TIME_ZONE = 'UTC'`);
  `Apps/voice_calls/views.py` `_calls_used_today()` (`timezone.localdate()`).
- **Problem:** The "resets at 00:00" boundary is computed in the server timezone (UTC).
  For a user in another timezone the reset happens at their local equivalent of UTC
  midnight, not their own midnight.
- **Why it matters:** A user could perceive the reset as happening at an odd hour, or get
  two "days" of calls around their local midnight.
- **Recommended fix:** Decide the intended semantics (server day vs user-local day). If
  user-local, send the device timezone/offset and compute the day boundary per user.
- **Priority:** P2 · **Status:** Open

### TD-003 — Race protection is a no-op on SQLite
- **Location:** `nowli-backend/Apps/voice_calls/views.py` `VoiceCallStartView.post()`
  (`select_for_update` on the user row).
- **Problem:** `select_for_update()` provides real row locking only on PostgreSQL (prod).
  On SQLite (local dev) it is a no-op, so two near-simultaneous start requests could both
  pass the limit check locally.
- **Why it matters:** Only affects local dev correctness; prod (Postgres) is protected.
- **Recommended fix:** Rely on Postgres in any environment where concurrency matters; add
  a DB unique/constraint-based guard if stronger protection is ever needed on SQLite.
- **Priority:** P3 · **Status:** Open

### TD-004 — Multi-account limit bypass is not addressed
- **Location:** feature-level (by design).
- **Problem:** The limit is per authenticated Django user. Multiple *devices* on the same
  account share the count (correct), but one person creating multiple *accounts* gets a
  fresh limit each.
- **Why it matters:** Determined abuse can exceed the intended per-person cap.
- **Recommended fix:** Out of scope for now. If needed, add device/attestation signals or
  phone/email verification friction — a product decision.
- **Priority:** P3 · **Status:** Open

### TD-005 — AI session still greets a hardcoded "User"
- **Location:** `nowli-frontend-app/lib/screen/ai_call/ai_voice.dart` `_createAiSession()`
  (`userName: 'User'`).
- **Problem:** The call is now correctly tied to the real Django user server-side (via the
  JWT on `/start/`), but the `nowli-ai` session still passes a generic display name.
- **Why it matters:** The companion addresses everyone as "User" — cosmetic, but sloppy.
- **Recommended fix:** Read the stored username/profile name and pass it as `user_name`.
- **Priority:** P3 · **Status:** Open

### TD-006 — No pre-check of quota at the call entry points
- **Location:** `nowli-frontend-app/lib/screen/home/home_screen.dart` (:240, :1038),
  `screen/home/swipe_to_talk/screen_flow_controller.dart`.
- **Problem:** The limit is (correctly) enforced when the call screen opens, but the
  entry points navigate to the call screen unconditionally; when the limit is reached the
  screen opens, shows a "checking…" then a "limit reached" message, and bounces back.
- **Why it matters:** Minor UX flash. The backend is still authoritative (this is only
  about not opening a screen we immediately leave).
- **Recommended fix:** Optionally call `getQuota()` at the entry point and show the
  limit message inline before navigating.
- **Priority:** P3 · **Status:** Open

---

### TD-012 — A SQLite database file was committed to the repo (and the `DB_NAME=nowlii` trap)
- **Location:** `nowli-backend/nowlii` (a SQLite DB, no file extension);
  `nowli-backend/.env` (`DB_ENGINE=postgresql`, `DB_NAME=nowlii`); `docs/running-locally.md`
  (local run overrides only `DB_ENGINE`, not `DB_NAME`).
- **Problem:** Locally, the documented run overrides `DB_ENGINE=sqlite3` but leaves
  `DB_NAME=nowlii`, so Django creates a SQLite file literally named `nowlii`. Because it has
  no `.sqlite3` extension, `.gitignore` did not catch it and it was committed in the initial
  baseline (`c207a32`). It carries local data (users, possibly the superuser hash) and gets
  rewritten on every local migration.
- **Why it matters:** A data-bearing binary in version control is noise and a potential
  data/secret exposure; every dev's local run shows it as "modified".
- **Recommended fix (done partially here):** Untracked it (`git rm --cached`) and added it
  to `.gitignore`. Still open: the data remains in git **history** (initial commit) — scrub
  history if the data is sensitive, and either set `DB_NAME=db.sqlite3` for local dev or
  document overriding `DB_NAME` too so no extension-less DB file is created.
- **Priority:** P2 · **Status:** Open (tracking removed; history + config trap remain)

---

## Pre-existing (inherited) — noticed while working in these files

### TD-007 — No automated test suite anywhere
- **Location:** whole repo (`nowli-backend` apps have no real `tests.py`; `nowli-ai` none;
  frontend only the default `widget_test.dart`).
- **Problem:** No regression safety net. Backend logic for this feature was verified with
  an ad-hoc `manage.py shell` script, not a committed test.
- **Why it matters:** Every change is manually verified; easy to regress silently.
- **Recommended fix:** Add API tests (auth, quests, subtasks, and now voice-call
  quota/start/end). Also tracked in `future-checklist.md`.
- **Priority:** P2 · **Status:** Open

### TD-008 — Dead / unrouted AI-call screen variants
- **Location:** `nowli-frontend-app/lib/screen/ai_call/` — `ai_calling.dart`,
  `ai_calling_two.dart`, `AiCalling_two.dart`, `ai_voice_calling_screen.dart` are not in
  the router (only `ai_voice.dart`, `call_summary_screen.dart`, `pop_po_sahre.dart` are).
- **Problem:** Multiple near-duplicate versions of the call screen; unclear which is
  canonical without checking the router.
- **Why it matters:** Confusing; risk of editing the wrong file.
- **Recommended fix:** Relocate to `lib/experimental/` or remove, per the cleanup rule.
- **Priority:** P3 · **Status:** Open

### TD-009 — Unused methods in `ai_voice.dart`
- **Location:** `nowli-frontend-app/lib/screen/ai_call/ai_voice.dart` — `_toggleMute`,
  `_handleWebVoiceInput`, `_getEmotionIcon`, `_getEmotionColor` (analyzer: `unused_element`).
- **Problem:** Dead code (pre-existing; not introduced by the limit feature).
- **Why it matters:** Noise; `_getEmotion*` hint at an emotion UI that was never wired.
- **Recommended fix:** Remove, or wire the emotion display if intended.
- **Priority:** P3 · **Status:** Open

### TD-010 — Speech `listenFor` does not match the call duration
- **Location:** `nowli-frontend-app/lib/screen/ai_call/ai_voice.dart` `_startListening()`
  (`listenFor: Duration(minutes: 10)`).
- **Problem:** Speech recognition is told to listen for 10 minutes while a call is at most
  7.5 minutes — a leftover constant.
- **Why it matters:** Harmless today, but a misleading magic number.
- **Recommended fix:** Tie it to the call's remaining time or a sensible per-utterance value.
- **Priority:** P3 · **Status:** Open

### TD-011 — `print()` used for logging; deprecated `withOpacity`
- **Location:** across the frontend (e.g. `ai_voice.dart`, `voice_call_service.dart`,
  all services).
- **Problem:** `avoid_print` and `deprecated_member_use` (`withOpacity`) lints throughout
  (the codebase's established style). New code follows the existing style for consistency.
- **Why it matters:** Not production-grade logging; deprecated API usage.
- **Recommended fix:** Introduce a logging util and migrate `withOpacity` → `withValues`
  in a dedicated lint-cleanup pass.
- **Priority:** P3 · **Status:** Open
