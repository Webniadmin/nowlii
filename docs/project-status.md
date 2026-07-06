# NOWLII — Project Status & Analysis

_Last reviewed: 2026-07-01_

## What the app does

**NOWLII** is a gamified productivity/wellness mobile app with an AI companion. Users
set daily "quests" (tasks with a difficulty "zone", time/date, subtasks, and optional
call/alarm/repeat flags), track completion streaks, view progress analytics, and
interact with a personalized companion (Milo, Bloop, Gumo, etc.) via text and **voice
calls** — including AI-generated subtask suggestions, weekly reflections, and quest
recommendations.

## Completed this session (2026-07-03)

- **PART A cleanup done (A1–A4).** Adopted a **preserve-not-delete** rule: scratch/junk
  (`lib/aaa/`, `screen/test_file/`, `screen/debug/`) was relocated to `lib/experimental/`
  and the `je_je_…` placeholder's 4 mockups moved into real feature folders — nothing thrown
  away, all imports fixed. **A3 naming pass:** ~25 misspelled folders + ~25 files renamed
  (e.g. `utlis→utils`, `remiender_notification→reminder_notification`, `swaipe→swipe`),
  every import updated, `flutter analyze` = **0 errors**.
- **A4 — subtasks CRUD is now routed.** `GET/POST /api/subtasks/` + `…/<id>/`
  (`IsAuthenticated`, per-user). Kept `/api/subtasks/generate/` working by reordering the
  URL includes; added a writable-`task` serializer + ownership checks so create actually works.
- **B1 — Google login implemented** (backend `/api/auth/google/` verifies a Google `id_token`
  and returns the normal JWT shape; frontend `google_sign_in` service + wired sign-in button).
  A real **Web** OAuth client id is wired into `.env` / `dart_defines.json` / `web/index.html`;
  `flutter build web` passes. Live end-to-end still needs Google Cloud consent/origin config.
- **Change trail:** `docs/cleanup-log.md` (A1–A4 file moves/renames) and `docs/google-login.md`
  (B1 + the exact Google Cloud setup) added.

### Later the same day (2026-07-03) — live Android testing

- **Google login verified end-to-end on Android** (emulator). Set up the full Android toolchain
  path: Developer Mode, debug keystore + SHA-1, fixed corrupted (Linux-copied) SDK build-tools,
  cleartext-for-debug manifest, and per-target dart-define files (`dart_defines.android.json` =
  emulator `10.0.2.2`, `dart_defines.phone.json` = LAN IP). Google Cloud project swapped to
  `274971792537` (new Web + Android client ids). The "Continue with Google" button is now wired on
  **all** auth screens via `lib/api/google_sign_in_flow.dart`. See `docs/running-on-android.md`.
- **Email/SMTP made env-driven** (`EMAIL_HOST/PORT/USE_TLS/USE_SSL/DEFAULT_FROM_EMAIL/SUPPORT_EMAIL`)
  and the sender switched to **`nowliiapp@gmail.com`** (Gmail app password). A live test email
  delivered to the inbox. OTP / verification / password-reset emails now come from this account.
- **Companion avatars fixed.** Root cause: the DB had no `NowliiPredefinedOption` rows → the API
  returned `[]` and the picker spun forever; and the avatar is set via `predefined_option` (the
  `avatar_logo`/`nowlii_name` fields are read-only), which the frontend never sent. Fix: **seeded 6
  companions** (images on S3, public HTTPS URLs that work on emulator + phone), the frontend now
  **sends `predefined_option`** on update (persists + displays), empty-list falls back to built-in
  assets, and the broken `?`-in-filename avatar fallback was replaced.
- **Support / contact chat built** (`Apps/support`): DB-backed `SupportMessage` +
  `/api/support/messages/` (per-user), admin "Reply" box, email both ways (send → support inbox,
  admin reply → user). Frontend Support form + Support Chat wired. A superuser
  (`justweb.rs@gmail.com`) was created for the admin. Verified end-to-end from the app. See
  `docs/support-feature.md`.

## Completed this session (2026-07-01)

- **Security — hardcoded JWTs removed** from all three frontend services
  (`subtask_service.dart`, `quest_service.dart`, `profile_service.dart`). They now read
  the logged-in user's `access_token` from storage instead of falling back to a baked-in
  test token (also removed a stale hardcoded `X-CSRFTOKEN`). Zero hardcoded JWTs remain
  in `lib/`.
- **Full local toolchain installed** on the Windows dev machine (previously had none):
  `uv` (user-scope), **Python 3.12.13** (via `uv python install`), and
  **Flutter 3.44.4** stable (git clone → `C:\src\flutter`, web enabled). Both committed
  `.venv` folders were Linux-built and were rebuilt from scratch.
- **Trailing-space import bug fixed** — 23 files imported `package:nowlii/core%20/…`
  (a trailing space in the folder name that only existed on the original Linux box). This
  broke the Windows web compile; all 23 imports rewritten to portable `core/`.
- **All three services verified running end-to-end** on 2026-07-01:
  Backend (Django) `:8000` → HTTP 200, `nowli-ai` (FastAPI) `:8001` → `/health` OK
  (`openai:true, hume:true`), Frontend (Flutter web) served on `:5000` → HTTP 200 with
  the correct API URLs baked in via `--dart-define`.
- **`docs/running-locally.md` created** — the verified, reproducible first-run/setup
  procedure with exact commands per service and every gotcha hit.
- Earlier in the session (already reflected below): host/CORS/CSRF and all frontend base
  URLs moved to env vars; `nowli-ai` host/port made env-driven and aligned to `:8001`.

## Tech stack

### Backend (`nowli-backend/`)
- **Django 6 + Django REST Framework**, Python 3.12+, managed with `uv`.
- **Auth**: SimpleJWT (31-day access & refresh tokens, rotation + blacklist),
  email + OTP registration, Google/Apple OAuth via `django-allauth`.
- **Runtime**: ASGI (Daphne/Uvicorn), Gunicorn + UvicornWorker in production.
- **Data**: SQLite (dev) / PostgreSQL on AWS RDS (prod). Media on S3 or local disk.
  Static files via WhiteNoise. Swagger docs at `/api/docs/`.
- **Pluggable AI layer**: auto-selects a provider by which API key is set,
  in priority order **Anthropic → OpenAI → Google** (`get_active_provider()`).
  This logic is duplicated in `Apps/subtask_generator` and `Apps/insights`.

### Frontend (`nowli-frontend-app/`)
- **Flutter / Dart**, GetX state management, `go_router` navigation.
- `flutter_screenutil` (responsive, design size 375×812), `fl_chart` (analytics),
  `speech_to_text` + `flutter_tts` (voice).

### AI service (`nowli-ai/`)
- **FastAPI** app "Emotion AI — Human Friend System" (v4.2), Python, deps via
  `requirements.txt` (`pip`). This is the `:8001` "AI server" the Flutter app talks to
  (`aiBaseUrl` in `lib/api/api_constant.dart`, used by `lib/services/ai_call_service.dart`).
- **Emotion pipeline**: OpenAI **Whisper** (transcription) + **Hume AI** (voice prosody
  emotion) + **GPT** (text emotion), merged into a combined emotional state that is
  injected into the chat system prompt.
- **Models**: OpenAI `gpt-4o` / `gpt-4o-mini` + `whisper-1`; Hume for voice.
- **Endpoints** (all `/api/v1/`): session management, `detect-emotion`, `chat-stream`
  (SSE, emotion-aware streaming), `chat/summary` (mood summary), conversation analytics
  (`emotion-breakdown`, `low-mood-detect`), `quest-suggestions`, `quest-source`,
  `languages`, plus `/` and `/health`.
- **Quest suggestions** call back into the Django API via `QUEST_API_URL`
  (default `http://127.0.0.1:8000/api/quests/`).

## What's complete and working

- **Auth flow** (backend + frontend): register → OTP → login, forgot/reset password,
  JWT storage, and a `go_router` auth-redirect guard based on token + `isFirstTime`.
  The users app is substantial (`Apps/users/views.py` ≈ 771 lines).
- **Quests CRUD**: full `ModelViewSet` with per-user filtering, `?due_date=` filter,
  a `bulk-delete` action, and a real **streak** calculation (`GET /api/quests/streak/`).
- **Subtasks CRUD** (as of 2026-07-03): `GET/POST /api/subtasks/` + `…/<id>/`,
  per-user, alongside the nested-in-quest representation.
- **Google login** (as of 2026-07-03): `POST /api/auth/google/` exchanges a Google
  `id_token` for NOWLII JWTs; frontend "Continue with Google" button wired. Live test
  pending Google Cloud config (see `google-login.md`).
- **AI voice-call daily limit** (as of 2026-07-06): `Apps/voice_calls` +
  `/api/voice-calls/` (`quota/`, `start/`, `<id>/end/`). Per-user, backend-authoritative:
  max 2 calls/day (`VOICE_CALL_DAILY_LIMIT`), counted from calls started today (resets at
  00:00, no cron), with per-user race locking. Frontend (`ai_voice.dart`) enforces the
  5-minute call with a single +2.5-minute extension (7.5-min cap), start notice, 1-min /
  30-sec warnings, last-10s countdown, and auto-end. Known gaps: the `nowli-ai` bypass
  (inherited — `technical-debt.md` TD-001) and the UTC day boundary (`system-constraints.md`
  SC-001).
  - **Call-screen UI polish** (2026-07-06): fixed four inherited in-call visual issues in
    `ai_voice.dart` — a flickering mic icon (now a debounced "speaking" indicator),
    the timer shifting the layout (fixed-width), the last minute tinting the whole
    background orange (removed; background stays blue), and the final-10s fullscreen
    overlay (now counts 10 → 1 on the shared notice card). See `technical-debt.md`
    TD-017…TD-020. No UI/UX changes beyond these fixes; `flutter analyze` clean (no new issues).
- **AI subtask generation** (`POST /api/subtasks/generate/`) — complete, with proper
  error handling (502/503 on AI failures).
- **AI insights** (`GET /api/insights/`) — weekly reflections + quest suggestions,
  backed by an `InsightCache` model to avoid re-calling the AI on every request. The
  `monthly` block now also returns a real `zone_progress` (per-zone completed counts),
  matching `weekly` (added 2026-07-06 for the Progress screen).
- **Progress + Insights screens** (as of 2026-07-06, committed `05605ae`): **done**.
  Progress "Your moves" has a This week / This month selector that shows **real backend
  per-zone data for both** (no approximation); Insights has a per-user **personal notes**
  system (add / list / delete, persisted locally via `PersonalNotesService`). Share buttons
  and the redundant This week / This month labels were commented out per product request.
- **Frontend** has a large, wired route table (~40 screens) covering onboarding, auth,
  quests, home, progress, profile, AI call, and settings.
- **AI voice/emotion service** (`nowli-ai/`) implements the full companion pipeline —
  sessions, Whisper+Hume+GPT emotion detection, SSE streaming chat, mood summaries,
  conversation analytics, and quest suggestions. This is the previously-"external"
  `:8001` server, now part of the repo.

## What looks unfinished / concerning

1. **Subscriptions are UI-only.** The `CustomUserModel` has `paid_user`,
   `current_plan`, and period fields plus `is_subscribed()`/`get_subscription_period()`
   helpers, and the frontend has subscription/pro screens — but there is **no payment
   integration, no purchase/webhook endpoint, no Stripe/IAP**. Nothing can actually
   change a user's plan.
2. ~~**Live chat with admin does not exist in the backend.**~~ **RESOLVED 2026-07-03** —
   `Apps/support` adds a `SupportMessage` model + `/api/support/messages/` (list/create,
   per-user), an admin "Reply" box, and email notifications both ways. The frontend Support
   form + Support Chat are wired to it. See `docs/support-feature.md`.
3. ~~**`SubTasksViewset` is defined but never routed.**~~ **RESOLVED 2026-07-03** —
   now registered at `/api/subtasks/` (CRUD) with a writable-`task` serializer and
   ownership checks; `/api/subtasks/generate/` preserved via URL-include reordering.
4. **Stale AI model IDs.** All three providers hardcode older models —
   `claude-opus-4-5`, `gpt-4o`, `gemini-2.0-flash`. Current top Claude Opus is
   `claude-opus-4-8`.
5. **Frontend is mid-development / messy.** _Largely addressed 2026-07-03:_ scratch dirs
   consolidated into `lib/experimental/`, the `je_je_…` placeholder's mockups moved into
   real feature folders, and the ~50 misspelled folder/file names fixed (see
   `cleanup-log.md`). Remaining: many `// Placeholder for X` route comments, a few
   ambiguous names left on purpose (`pop_po_sahre`, `edit_from`, `create_qutes`,
   `chat_boot`), and class/route-constant misspellings not yet aligned to their files.
6. **Security posture is dev-grade.** The Django `ALLOWED_HOSTS`, CORS, CSRF, and the
   Flutter base URLs (including `NowliiOptionsApi`) have since been moved to environment
   variables (secure defaults), and the `nowli-ai` host/port are now env-driven too. Two
   items remain: DRF's default permission is still `AllowAny` (enforced per-view), and
   the `nowli-ai` FastAPI service still uses `CORS allow_origins=["*"]`. Multiple `.env`
   files across all three services contain **live secrets in plaintext** (OpenAI, Hume,
   AWS, DB password) — these should be rotated and never committed.
7. **`nowli-ai` structure is confusing.** The live app is the ~1300-line monolith
   `test17.py`; the cleaner `routers/` module (`/emotion/combined`, WS `/chat/stream`)
   is **not wired in** (dead/aspirational code). Sessions are stored **in memory only**
   (lost on restart), and the service has **no tests and no dependency lockfile**. The
   port mismatch is resolved — `test17.py` and `nowli-ai/.env` now default to `:8001`
   (env-driven `HOST`/`PORT`), matching the Flutter client.

## Bottom line

The core loop — auth, quests, streaks, the three Django AI features, and the `nowli-ai`
voice/emotion companion — is functional end-to-end, and the previously-external AI
server is now part of the repo. Monetization (subscriptions) and support-chat remain
scaffolded in the UI and user model with **no working backend**. The `nowli-ai` service
works but is rough: a single-file monolith with an unwired parallel refactor and
in-memory sessions (its port/host are now env-driven and aligned with the Flutter client).
