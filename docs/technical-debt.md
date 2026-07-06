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

### TD-007 — No automated test suite anywhere
- **Location:** whole repo (`nowli-backend` apps have no real `tests.py`; `nowli-ai` none;
  frontend only the default `widget_test.dart`).
- **Problem:** The inherited project ships with no regression safety net.
- **Why it matters:** Every change is manually verified; easy to regress silently.
- **Recommended fix:** Add API tests (auth, quests, subtasks, and voice-call
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

## P3

### TD-005 — AI session still greets a hardcoded "User"
- **Location:** `nowli-frontend-app/lib/screen/ai_call/ai_voice.dart` `_createAiSession()`
  (`userName: 'User'`).
- **Problem:** Inherited hardcoded value — the `nowli-ai` session passes a generic display
  name instead of the logged-in user.
- **Why it matters:** The companion addresses everyone as "User" — cosmetic, but sloppy.
- **Recommended fix:** Read the stored username/profile name and pass it as `user_name`.
- **Priority:** P3 · **Status:** Open

### TD-008 — Dead / unrouted AI-call screen variants
- **Location:** `nowli-frontend-app/lib/screen/ai_call/` — `ai_calling.dart`,
  `ai_calling_two.dart`, `AiCalling_two.dart`, `ai_voice_calling_screen.dart` are not in
  the router (only `ai_voice.dart`, `call_summary_screen.dart`, `pop_po_sahre.dart` are).
- **Problem:** Inherited near-duplicate versions of the call screen; unclear which is
  canonical without checking the router.
- **Why it matters:** Confusing; risk of editing the wrong file.
- **Recommended fix:** Relocate to `lib/experimental/` or remove, per the cleanup rule.
- **Priority:** P3 · **Status:** Open

### TD-009 — Unused methods in `ai_voice.dart`
- **Location:** `nowli-frontend-app/lib/screen/ai_call/ai_voice.dart` — `_toggleMute`,
  `_handleWebVoiceInput`, `_getEmotionIcon`, `_getEmotionColor` (analyzer: `unused_element`).
- **Problem:** Inherited dead code (pre-existing; not introduced by the limit feature).
- **Why it matters:** Noise; `_getEmotion*` hint at an emotion UI that was never wired.
- **Recommended fix:** Remove, or wire the emotion display if intended.
- **Priority:** P3 · **Status:** Open

### TD-010 — Speech `listenFor` does not match the call duration
- **Location:** `nowli-frontend-app/lib/screen/ai_call/ai_voice.dart` `_startListening()`
  (`listenFor: Duration(minutes: 10)`).
- **Problem:** Inherited leftover constant — speech is told to listen for 10 minutes.
- **Why it matters:** Harmless today, but a misleading magic number.
- **Recommended fix:** Tie it to the call's remaining time or a sensible per-utterance value.
- **Priority:** P3 · **Status:** Open

### TD-011 — `print()` used for logging; deprecated `withOpacity`
- **Location:** across the frontend (e.g. `ai_voice.dart`, all services).
- **Problem:** The inherited codebase logs with `print()` (`avoid_print`) and uses the
  deprecated `withOpacity` (`deprecated_member_use`) throughout. New code follows the
  existing style for consistency until a cleanup pass.
- **Why it matters:** Not production-grade logging; deprecated API usage.
- **Recommended fix:** Introduce a logging util and migrate `withOpacity` → `withValues`
  in a dedicated lint-cleanup pass.
- **Priority:** P3 · **Status:** Open

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
