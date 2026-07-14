# NOWLII — Project Status & Analysis

_Last reviewed: 2026-07-14_

## What the app does

**NOWLII** is a gamified productivity/wellness mobile app with an AI companion. Users
set daily "quests" (tasks with a difficulty "zone", time/date, subtasks, and optional
call/alarm/repeat flags), track completion streaks, view progress analytics, and
interact with a personalized companion (Milo, Bloop, Gumo, etc.) via text and **voice
calls** — including AI-generated subtask suggestions, weekly reflections, and quest
recommendations.

## Completed this session (2026-07-14)

_Full detail in `daily-reports/2026-07-14.md`; design notes in the `quest-toggles-wiring` memory._

- **Add-Quest toggles wired to real behavior.** "Enable call" and "Repeat quest" were persisted but
  did nothing. Now (client-chosen behavior; **no scheduler exists**, so both are done without one):
  - **Enable call** → the Today quest card shows a **"📞 Call Nowlii (5 min)"** button only when
    `enable_call=true`; it launches the existing 5-min AI call and passes the quest title as a spoken
    opener context (`today.dart`, `ai_voice.dart` `questTitle` param, `app_pages.dart` route).
  - **Repeat quest** → recurrence is **materialized up-front** in `_createQuest`: copies for the next 6
    days (7 total incl. selected date). Copies aren't re-materialized (no recursion).
  - Both toggles now **default to `false`** (frontend matched to the backend `default=False`); before
    they were forced `true`.
- **Call-duration copy fixed 10-min → 5-min** in 5 places (`enable_card.dart`, `enable_card_edit.dart`,
  `suggested_task_overview.dart` ×2, `experimental/clean_the_house_screen.dart`). Real call = 5 min +
  one 2.5-min extension. (Left "10 mins" task-duration chips and "call 10 minutes before" timing copy.)
- **No past scheduling (new).** The date picker already limited dates to today..+6, but a **past time on
  "Today"** was allowed and the **backend had no validation**. Added a frontend guard in `_createQuest`
  (blocks a selected date+time before now, 1-min grace) **and** `QuestsSerializers.validate_select_a_date`
  (rejects a past date **on create only**, date-level vs `timezone.localdate()` — tz-safe; edits and the
  seed command are unaffected).
- Verified: `flutter analyze` (touched files) = 0 errors; `manage.py check` = no issues.
- **Insights "What this means" is now AI-generated** (was a static placeholder). New
  `generate_emotion_meaning()` fills `emotions_summary` / `low_mood_summary` /
  `low_mood_recommendation`, cached weekly in `InsightCache`, with **fallback to the placeholder copy**
  on any AI failure. Called only when the user has voice-call data. Verified live (provider = chatgpt).
- **Insights "Your mood" weekly chart is now dynamic** (was demo data). `services._build_mood_week`
  gives per-weekday dominant emotion + intensity from `CallEmotionSnapshot`; new `mood_week` serializer
  field + `MoodDay` model; the chart renders real bars (emotion→color/emoji) and **hides when the week
  has no call data**. No migration needed.
- **Subscriptions — backend lifecycle engine started (Phase 1).** New `Apps/subscriptions`: config-driven
  decreasing-price-then-free schedule (**1–3mo $19.99 → 4–6 $14.99 → 7–9 $9.99 → 10–12 $4.99 → 13+ free**),
  `Subscription` model, pure phase/entitlement engine, and `/api/subscriptions/` API (`plan`, `me`,
  **mock** `activate`, `cancel`, `verify-receipt` **stub**). 8 tests pass; verified live. Frontend data
  layer (`subscription_service.dart` + model) + minimal pro-screen wiring. **Sold mobile-only → Phase 2
  is real Apple IAP / Google Play Billing** (Stripe not allowed in-app); paywall UI still needs redesign
  to the phase model. See `subscription-model` memory + `daily-reports/2026-07-14.md`. Resolves the
  "subscriptions are UI-only" gap (#1 below) at the backend layer.

## Completed this session (2026-07-10)

_Full detail in `daily-reports/2026-07-10.md`; feature detail in `three-features-plan.md`._

- **Fluid voice conversation (architecture change).** Per-message emotion detection (a gpt-4o call
  before every reply, ~1.5–4s of lag) was **removed from the live path**; emotions are now extracted
  **once at call end over the whole transcript** (`_compute_top_emotions_from_transcript`, model via
  `EMOTION_MODEL` = gpt-4o-mini). First reply word dropped to **~0.9–1.4s**. Old per-message code is
  **commented, not deleted**. Feeds call-insights (Top Emotions / When-feeling-low) + the summary.
- **Profanity / content filter** in nowli-ai `chat-stream` (local word list + OpenAI Moderation),
  **excludes distress/self-harm**; warns via an SSE `warning` event → app notice + spoken TTS.
- **Barge-in** (interrupt the AI by talking) implemented; needs **headphones on the emulator / a real
  phone (AEC)** or the mic echoes the AI. **Tap-to-interrupt** fallback added. Mic start/stop earcon
  ("bip bip") still open (needs native mute).
- **AI persona** rewritten to a warm, emotionally-intelligent **wellness companion** (the only prompt
  that runs now that emotion is always "neutral").
- **After-call summary** confirmed dynamic; static fallbacks made honest; new **"Emotions in this
  chat"** section on the summary screen.
- **Swipe-to-talk** goes straight to the 5-min call (voice-note mock detour relocated to
  `lib/experimental/`); **dynamic companion name** on that path; call-screen control-row width fix.
- **Apple Sign-In (Android web flow)**: backend enabled + verified; redirect endpoint + manifest +
  cloudflared tested — Apple auth + backend 307 work, but the `intent://` bounce into the app didn't
  complete (deferred). **Must swap the temp trycloudflare URL for a permanent one before any
  preview/device build** (see `apple-login.md`).

## Completed this session (2026-07-07)

- **Insights "Top Emotions" section — implemented end-to-end and runtime-verified** (from
  Figma "Frame 2147228872"; full report in `daily-reports/2026-07-07.md`, plan/notes in
  `insights-emotions.md`).
  - **nowli-ai** — `/conversation/emotion-breakdown/{id}` now returns **5 native categories**
    (Happy, Motivated, Angry, Tired, Sad) via a dedicated `_TOP_EMOTION_MAP` /
    `_compute_top_emotions_from_turns`. The shared 6-bucket analytics map, the low-mood
    endpoint and the chat-prompt `_resolve_emotion_key` were left untouched.
  - **Persistence** — new `CallEmotionSnapshot` model in `Apps/voice_calls`; the app captures
    the breakdown at call end (nowli-ai session still in memory) and `POST /voice-calls/<id>/end/`
    stores it per call/user. Migration `0002_callemotionsnapshot`.
  - **Aggregation** — `Apps/insights` averages the week's snapshots and exposes
    `weekly.top_emotions` + `weekly.emotions_summary` (Weekly only, above "Weekly Reflection").
  - **Flutter** — `_buildTopEmotions()`/`_buildEmotionTile()` in `insights.dart`, **dynamic**
    layout (dominant full-width, rest sorted descending), Figma 1:1; clean hide-when-empty state.
  - **Runtime-verified on the emulator** — all three services up; the real flow (session →
    chat-stream → emotion-breakdown → voice-calls start/end → insights) exercised live, **not
    mock**; data-gate + seeded-data display both confirmed.
  - **Known TODOs:** the "What this means" copy is a **temporary placeholder** (10 texts, 2 per
    emotion; `TODO(insights-emotions)` in `services.py`) pending a real AI summary; and a final
    **organic** (non-seeded) voice-call test still to do.

- **Insights "When feeling low, you often say…" section — implemented end-to-end and
  runtime-verified** (Figma node `2888:11656`, below Top Emotions).
  - **One GPT-free call for both sections** — new nowli-ai `GET /conversation/call-insights/{id}`
    returns the 5-category emotion breakdown **and** the canonical low-mood phrases in one request
    (emotions from per-turn scores, phrases from regex — no LLM). The app calls it once at call end.
  - **Persistence** — new `CallLowMoodSnapshot` (`Apps/voice_calls`, migration `0003`);
    `end` stores the phrases. **Aggregation** — `Apps/insights` returns `low_mood_phrases`
    (top 5 by frequency, dedup, alphabetical ties) + placeholder `low_mood_summary`/`low_mood_recommendation`.
  - **Flutter** — `_buildWhenFeelingLow()`; **always-visible** section with a designed empty-state
    (unlike Top Emotions, which hides), mood phrases left-aligned per Figma.
  - Same TODOs as Top Emotions (AI "What this means"; organic voice-call test).

- **First real Voice Call E2E — passed; two fixes.** With the emulator mic enabled, the full pipeline
  ran on real speech (11 turns → AI replies → TTS → `CallEmotionSnapshot` + `CallLowMoodSnapshot` →
  summary). **P0** ("AI silent") root cause was the emulator not routing host audio (`error_speech_timeout`),
  not code — added a "check your microphone" hint (`ai_voice.dart`). **P3** ("Could not load summary")
  fixed — `call_summary_screen.dart` falls back to default cards instead of the error screen. An audit
  confirmed the Voice Call → Insights flow is dynamic + user-isolated (no mock data); test seeds removed.
  Open for next: AI persona (companion vs chatbot), timeout UI to Figma (Figma rate-limited), barge-in.

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
  - **Call-screen UI polish** (2026-07-06): fixed inherited in-call visual issues in
    `ai_voice.dart` — a flickering mic icon (now a voice-activity "speaking" indicator via
    `onSoundLevelChange`, off ~1s after speech stops), the timer shifting the layout (now
    per-digit fixed-width slots), the last minute recoloring the background **and** timer
    orange (removed both; they stay blue/indigo — only the notice card signals the warning),
    and the final-10s fullscreen overlay (now counts 10 → 1 on the shared notice card). Also
    replaced the placeholder "Answer emails" heading with a neutral companion heading, and
    made the call summary fall back to its default cards instead of a "No session ID
    provided" error when the AI session is missing (`call_summary_screen.dart`). See
    `technical-debt.md` TD-017…TD-021. No UI/UX changes beyond these fixes; `flutter analyze`
    clean (no new issues).
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
- **Insights "Top Emotions" + "When feeling low…"** (as of 2026-07-07): **done, runtime-verified**.
  Both fed by real voice-call data via one GPT-free nowli-ai call (`/conversation/call-insights/{id}`)
  → `CallEmotionSnapshot` / `CallLowMoodSnapshot` (Django) → weekly aggregation → the two Insights
  cards (Figma 1:1). Top Emotions hides when empty; "When feeling low" is always shown with a
  designed empty-state. Both "What this means" summaries are **temporary placeholders** pending a
  real AI summary. See `insights-emotions.md`.
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
8. **Conversation-analytics: now consumed via a combined GPT-free endpoint.**
   As of 2026-07-07, both Insights emotion sections are fed by a single new nowli-ai endpoint
   `/conversation/call-insights/{id}` (5-category emotion breakdown **+** canonical low-mood
   phrases, no LLM). The app fetches it at call end; Django persists both (`CallEmotionSnapshot`,
   `CallLowMoodSnapshot`) and Insights aggregates them into **Top Emotions** and **When feeling
   low…**. The original `/conversation/emotion-breakdown` and `/conversation/low-mood-detect`
   endpoints still exist but are no longer the app's path. See `docs/insights-emotions.md`.

## Bottom line

The core loop — auth, quests, streaks, the three Django AI features, and the `nowli-ai`
voice/emotion companion — is functional end-to-end, and the previously-external AI
server is now part of the repo. Monetization (subscriptions) and support-chat remain
scaffolded in the UI and user model with **no working backend**. The `nowli-ai` service
works but is rough: a single-file monolith with an unwired parallel refactor and
in-memory sessions (its port/host are now env-driven and aligned with the Flutter client).
