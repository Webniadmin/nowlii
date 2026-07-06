# NOWLII — Architecture

_Last updated: 2026-07-01. Companion to `running-locally.md` (how to run) and
`project-status.md` (what's done / what's missing)._

NOWLII is three independently-deployed services in one repo:

| Service | Tech | Port | Role |
|---|---|---|---|
| `nowli-frontend-app/` | Flutter (Dart), GetX, go_router | web dev `:5000` (Chrome for native) | UI / client |
| `nowli-backend/` | Django 6 + DRF | `:8000` | Core REST API, auth, data, DB |
| `nowli-ai/` | FastAPI (`test17.py`) | `:8001` | Voice/emotion AI companion |

---

## 1. How the three services connect

```
                         ┌─────────────────────────────┐
                         │   Flutter app (frontend)     │
                         │   lib/api/api_constant.dart  │
                         └──────────┬───────────┬───────┘
              JWT Bearer, BASE_URL  │           │  session-based, AI_BASE_URL
              (auth/profile/quests/ │           │  (voice + emotion + chat)
               insights/subtasks)   │           │
                         ┌──────────▼──┐   ┌────▼─────────────┐
                         │ Django API  │   │  nowli-ai        │
                         │   :8000     │◄──┤   :8001          │
                         └──────┬──────┘   └────┬─────────────┘
        QUEST_API_URL callback ─┘               │  (quest-suggestions reads
                         │                       │   Django quests via HTTP)
                  ┌──────▼──────┐          ┌─────▼───────┐  ┌──────────┐
                  │ SQLite/RDS  │          │  OpenAI     │  │  Hume AI │
                  │  Postgres   │          │ Whisper+GPT │  │ prosody  │
                  └─────────────┘          └─────────────┘  └──────────┘
```

- **Frontend → Backend (`:8000`)**: all authenticated app data (auth, profile, quests,
  subtasks, insights). JWT `Bearer` token in the `Authorization` header.
- **Frontend → nowli-ai (`:8001`)**: the AI companion / voice-call feature. **No JWT** —
  it is session-based: the app first creates a session and then streams chat against that
  `session_id`.
- **nowli-ai → Backend (`:8000`)**: the `quest-suggestions` feature can pull the user's
  quests from Django via `QUEST_API_URL` (default `http://127.0.0.1:8000/api/quests/`).
- **nowli-ai → OpenAI + Hume**: outbound only, per request (Whisper transcription,
  GPT chat/emotion, Hume voice prosody).
- **Backend → DB / S3 / SMTP / Google OAuth**: Postgres or SQLite, S3 for media, Gmail
  SMTP for OTP email, Google/Apple for social auth.

The three services share **no code and no database**; they communicate only over HTTP.

---

## 2. Data flow

### 2a. Normal app request (e.g. load today's quests)
1. User acts in a Flutter screen → a service in `lib/services/` (e.g. `quest_service.dart`).
2. Service calls `_getToken()` → reads `access_token` from `SharedPreferences`.
3. `GET http://<BASE_URL>/api/quests/?due_date=YYYY-MM-DD` with
   `Authorization: Bearer <token>`.
4. Django `QuestsViewset` filters `Quests.objects.filter(user=request.user)` and returns JSON.
5. Service maps JSON → `Quest`/`Subtask` models → UI renders.

### 2b. AI voice-call / companion chat
1. Frontend `ai_call_service.createSession()` →
   `POST http://<AI_BASE_URL>/api/v1/session/new` `{user_name, system_name, language}`
   → returns `session_id` (stored in an in-memory dict on the server).
2. Frontend records audio / captures text and streams a turn →
   `POST http://<AI_BASE_URL>/api/v1/chat-stream` (**SSE** response).
3. nowli-ai pipeline: **Whisper** transcribes audio → **Hume** analyzes voice prosody →
   **GPT** classifies text emotion → `services/emotion_merger` merges them into a combined
   emotional state → that state is injected into the GPT chat system prompt → tokens are
   streamed back over SSE.
4. `call_summary_service` can later `POST /api/v1/chat/summary` for a mood summary; other
   analytics endpoints (`emotion-breakdown`, `low-mood-detect`) read the session's turns.

### 2c. AI features that live in the Django backend (separate from nowli-ai)
- `POST /api/subtasks/generate/` and `GET /api/insights/` run their **own** pluggable AI
  layer inside Django (`Apps/subtask_generator`, `Apps/insights`) — auto-selecting
  Anthropic → OpenAI → Google by which key is set. These are unrelated to the `nowli-ai`
  service and are authenticated with the normal JWT.

---

## 3. API base URLs & ports

All frontend URLs come from compile-time `--dart-define` values in
`lib/api/api_constant.dart` (defaults shown):

| Constant | dart-define | Default | Points at |
|---|---|---|---|
| `ApiConstants.baseUrl` | `BASE_URL` | `http://localhost:8000` | Django backend |
| `ApiConstants.aiBaseUrl` | `AI_BASE_URL` | `http://localhost:8001` | nowli-ai |

Path prefixes (frontend side): `apiPrefix=/api/auth`, `profilePrefix=/api/profiles`,
`questsPrefix=/api/quests`, `insightsPrefix=/api`, `aiCallPrefix=/api/v1`. Note several
services (`quest_service`, `profile_service`, `subtask_service`) build their own base as
`${ApiConstants.baseUrl}/api` and append paths — same effective host, different string.

**Backend endpoints** (`nowli-backend/core/urls.py`): `/admin/`, `/api/auth/…`
(incl. `/api/auth/google/` — Google id_token → JWT; `/api/auth/apple/` — Apple identity_token
→ JWT, prepared/keys-pending), `/api/profiles/`,
`/api/nowlii-options/`, `/api/quests/` (+`/streak/`, `/bulk-delete/`),
`/api/subtasks/` (CRUD) and `/api/subtasks/generate/`, `/api/insights/`,
`/api/support/messages/` (per-user support chat),
`/api/voice-calls/` (`quota/`, `start/`, `<id>/end/` — per-user AI-call daily limit),
`/accounts/…` (allauth), `/api/docs/` (Swagger).
> ⚠ Include order matters: `api/subtasks/` (generator) is included **before** the quests
> router so `subtasks/generate/` isn't shadowed by the subtasks `<pk>` detail route.

**nowli-ai endpoints** (all `/api/v1/`): `session/new`, `session/{id}` (GET/DELETE),
`detect-emotion`, `chat-stream` (SSE), `chat/summary`, `conversation/emotion-breakdown/{id}`,
`conversation/low-mood-detect/{id}`, `quest-suggestions`, `quest-source`, `languages`;
plus `/` and `/health`.

**Port contract:** backend **8000**, nowli-ai **8001** (both env-driven on the server side;
`nowli-ai` reads `HOST`/`PORT`, defaults `0.0.0.0:8001`). Frontend web dev server: **5000**.

---

## 4. Auth flow (JWT)

**Scheme:** SimpleJWT, `Bearer` header. Access & refresh tokens both live 31 days;
`ROTATE_REFRESH_TOKENS` + `BLACKLIST_AFTER_ROTATION` are on. DRF default permission is
`AllowAny`, so protection is enforced **per-view** (`permission_classes = [IsAuthenticated]`).

**Login/registration:** email + 6-digit OTP (register → verify-otp → login), plus
forgot/reset-password (OTP-verified). **Google** social login is wired end-to-end via a
custom token-exchange view: the client posts a Google `id_token` to `POST /api/auth/google/`,
the server verifies it (`google-auth`) and returns the same SimpleJWT shape as `/auth/login/`
(see `google-login.md`). Apple is still allauth-configured but not yet wired (B2).

**Token storage & passing (frontend):**
- On successful `POST /api/auth/login/`, `auth_service.login()` saves tokens via
  `StorageService.saveTokens()` → `SharedPreferences` keys **`access_token`** and
  **`refresh_token`** (plus `user_id`, `email`, `username`).
- Every authenticated service reads `prefs.getString('access_token')` and sends
  `Authorization: 'Bearer $token'`. (As of this session, the hardcoded fallback JWTs were
  removed — an unauthenticated call now sends an empty token and gets 401, which is correct.)
- **Route guard:** `lib/core/app_routes/app_pages.dart` `go_router` `redirect` reads
  `access_token` + `isFirstTime` from `SharedPreferences`: no token + protected route →
  entry/sign-in; token present + on a public route → home.
- Logout = `StorageService.clearAll()`.
- There is currently **no automatic refresh-token rotation client-side** — services just
  send the stored access token.

**nowli-ai auth:** none. The `:8001` service is unauthenticated and identifies a
conversation only by its `session_id`. (If exposed publicly, this is worth hardening.)

---

## 5. Key directories per service

### `nowli-backend/` (Django)
- `core/` — project config: `settings.py` (all settings, env-driven), `urls.py` (routes +
  Swagger), `asgi.py`/`wsgi.py`, `exceptions.py` (custom DRF exception handler),
  `middleware.py`.
- `Apps/users/` — custom user model, `Profile`, `NowliiPredefinedOption`, all auth views
  (register/OTP/login/logout/forgot/reset). Routes: `/api/auth/…`, `/api/profiles/`,
  `/api/nowlii-options/`.
- `Apps/quests/` — `Quests` + `SubTasks` models, `QuestsViewset` (`/api/quests/`), streak.
  ⚠ `SubTasksViewset` exists but is **not routed** (see `next-phase.md`).
- `Apps/subtask_generator/` — `POST /api/subtasks/generate/` (in-Django AI).
- `Apps/insights/` — `GET /api/insights/` + `InsightCache` model (in-Django AI).
- `Apps/support/` — `SupportMessage` model + `/api/support/messages/` (per-user support chat);
  admin "Reply" box + email notifications. See `docs/support-feature.md`.
- `Apps/voice_calls/` — `VoiceCall` model + `/api/voice-calls/` (`quota/`, `start/`,
  `<id>/end/`). Enforces the **per-user daily AI-call limit** (`VOICE_CALL_DAILY_LIMIT`,
  default 2) server-side; the daily count is derived from calls started "today" (no cron).
  The frontend timer/warnings and the 5-min + one-time 2.5-min extension (7.5-min max) are
  in `ai_voice.dart`; `lib/services/voice_call_service.dart` calls this API.
- `manage.py`, `Dockerfile`, `docker-compose.*.yml`, `entrypoint.sh`, `uv.lock`, `.env`.

### `nowli-frontend-app/` (Flutter)
- `lib/main.dart` — entry; builds `MaterialApp.router` with `AppPages.router`.
- `lib/core/app_routes/` — `app_pages.dart` (go_router config + auth guard),
  `app_routes.dart` (path constants). `lib/core/gen/` — generated asset accessors.
- `lib/api/` — `api_constant.dart` (base URLs/endpoints), `auth_service`/`auth_controller`/
  `auth_model`, `profile_*`, `storage.dart` (SharedPreferences token/user store),
  `api_service.dart` (HTTP wrapper), `nowlii_options_api.dart`.
- `lib/services/` — feature services (quests, subtasks, insights, streak, profile,
  ai_call, audio_stream, call_summary, quest_suggestion, web_speech).
- `lib/models/` — data models. `lib/screen/` — ~40 screens by feature. `lib/widget/` +
  `lib/custom_code/` — reusable UI. `lib/themes/`, `lib/utlis/color_palette/` — styling.
- `lib/experimental/` — scratch/experiment/debug code consolidated here 2026-07-03
  (was `lib/aaa/`, `screen/test_file/`, `screen/debug/`); unreferenced by the live app.
  The old `je_je_…` mockups were moved into real feature folders. Many `lib/` folders/files
  were also renamed to fix misspellings (see `cleanup-log.md`) — re-check imports if pulling
  older code.

### `nowli-ai/` (FastAPI)
- `test17.py` — **the live app**: FastAPI instance + all `@app` routes + session store
  (in-memory `_sessions`), language list, quest-suggestion logic. Entry:
  `python test17.py` (env-driven `HOST`/`PORT`).
- `config.py` — loads `.env`, all constants + prompt templates.
- `models.py` — Pydantic request/response schemas + `EmotionState`.
- `services/` — `hume_emotion.py` (voice), `text_emotion.py` (GPT), `llm_chat.py`
  (streaming chat), `emotion_merger.py` (weighted merge). **Used by `test17.py`.**
- `routers/` (`chat.py`, `emotion.py`) — a cleaner modular refactor that is **NOT mounted**
  in `test17.py`. Dead/aspirational; ignore unless you wire it in.
- `requirements.txt` (no lockfile), `.env`.

---

## 6. Environment variables per service

### `nowli-backend/.env`
- **Core:** `SECRET_KEY`, `DEBUG` (default False), `ALLOWED_HOSTS` (comma list).
- **CORS/CSRF:** `CORS_ALLOW_ALL_ORIGINS`, `CORS_ALLOWED_ORIGINS`, `CSRF_TRUSTED_ORIGINS`.
- **Database:** `DB_ENGINE` (defaults SQLite; set to `django.db.backends.postgresql` for
  RDS), `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`.
  _Local dev: override `DB_ENGINE=django.db.backends.sqlite3`._
- **Email (OTP/verification/reset):** now env-driven — `EMAIL_HOST` (default `smtp.gmail.com`),
  `EMAIL_PORT` (587), `EMAIL_USE_TLS`/`EMAIL_USE_SSL`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD`
  (app password), `DEFAULT_FROM_EMAIL` (sender; defaults to the login), `SUPPORT_EMAIL`.
  Current sender: `nowliiapp@gmail.com`.
- **Social auth:** `SOCIAL_AUTH_GOOGLE_CLIENT_ID`, `SOCIAL_AUTH_GOOGLE_SECRET`.
- **Media (optional S3):** `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
  `AWS_STORAGE_BUCKET_NAME`, `AWS_S3_REGION_NAME`, … (S3 used only if key is set).
- **AI (in-Django features):** one of `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` /
  `GOOGLE_AI_API_KEY`.
- **Docker superuser (optional):** `DJANGO_SUPERUSER_EMAIL`, `DJANGO_SUPERUSER_PASSWORD`.

### `nowli-ai/.env`
- **Keys:** `OPENAI_API_KEY` (required — Whisper + GPT), `HUME_API_KEY`,
  `HUME_SECRET_KEY`, `HUME_CONFIG_ID` (voice emotion; skipped if absent).
- **LLM tuning:** `LLM_MODEL` (default `gpt-4o`), `LLM_MAX_TOKENS`, `LLM_TEMPERATURE`,
  `LOG_LEVEL`.
- **Integration:** `QUEST_API_URL` (Django quests endpoint for quest-suggestions).
- **Server:** `HOST` (default `0.0.0.0`), `PORT` (default `8001`).

### `nowli-frontend-app/` (compile-time `--dart-define`, not a `.env`)
- `BASE_URL` (Django, default `http://localhost:8000`),
  `AI_BASE_URL` (nowli-ai, default `http://localhost:8001`),
  `GOOGLE_WEB_CLIENT_ID` (Google Sign-In server/web client id; empty = Google button disabled).
- Convenience: `--dart-define-from-file=dart_defines.json` (template
  `dart_defines.example.json`; real file git-ignored).

> ⚠ All `.env` files currently hold **live secrets in plaintext** and are pending
> rotation — see `next-phase.md`.
