# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

This is a monorepo for **NOWLII**, a gamified productivity/wellness app with an AI companion.

- `nowli-backend/` — Django 6 + DRF REST API (Python 3.12+, managed with `uv`).
- `nowli-frontend-app/` — Flutter mobile app (Dart, GetX + go_router).
- `nowli-ai/` — FastAPI voice/emotion AI service (Python, `pip`/`requirements.txt`). This is the "AI server" the Flutter app talks to on port `:8001`.
- `docs/` — project docs: **`running-locally.md`** (verified first-run/setup procedure — read this before trying to run anything), `project-status.md`; screenshots live in `nowli-backend/docs/screenshots/`.

The three projects are developed and run independently; there is no root-level build. `cd` into the relevant subproject first.

## Backend (`nowli-backend/`)

### Commands
- Install deps: `uv sync`
- Run dev server: `uv run python manage.py runserver` (or `docker-compose -f docker-compose.dev.yml up --build`)
- Migrations: `uv run python manage.py makemigrations` / `uv run python manage.py migrate`
- Create admin: `uv run python manage.py createsuperuser`
- Run all tests: `uv run python manage.py test`
- Run one app's tests: `uv run python manage.py test Apps.quests`
- Run a single test: `uv run python manage.py test Apps.quests.tests.QuestTestCase.test_name`
- API docs (Swagger): `http://localhost:8000/api/docs/`; root `/` redirects there.

### Architecture
- **Django project** lives in `core/`: `settings.py` (all config), `urls.py` (routes + Swagger), `exceptions.py` (custom DRF exception handler wired via `REST_FRAMEWORK['EXCEPTION_HANDLER']`), `middleware.py`. Served over ASGI (`core.asgi`) via Daphne/Uvicorn; Gunicorn+UvicornWorker in prod.
- **Feature apps** live under `Apps/` (note the capital `A`, and they are imported as `Apps.<name>`):
  - `users` — auth (email + OTP, JWT, Google/Apple OAuth via allauth), `Profile`, and `NowliiPredefinedOption` (companion/avatar options). Routes under `/api/auth/…`, `/api/profiles/`, `/api/nowlii-options/`.
  - `quests` — `Quests` + `SubTasks` models (zone-based difficulty, call/alarm/repeat flags), streaks. `QuestsViewset` under `/api/quests/`.
  - `subtask_generator` — AI-generated subtasks. `POST /api/subtasks/generate/`.
  - `insights` — AI weekly reflections + quest suggestions. `GET /api/insights/`.
- **AI provider abstraction**: `Apps/insights/ai_client.py` (and the parallel logic in `subtask_generator`) auto-selects a provider by which API key is set, in priority order **Anthropic → OpenAI → Google** (`get_active_provider()`). Prompts instruct the model to return raw JSON; `_parse()` strips ``` fences before `json.loads`. When touching AI code, keep all three provider callers (`_call_claude`, `_call_chatgpt`, `_call_gemini`) in sync.
- **Auth**: SimpleJWT with `Bearer` scheme; access & refresh tokens both live 31 days; refresh rotation + blacklist enabled. Default DRF permission is `AllowAny` — permissions are enforced per-view, so don't assume endpoints are protected by default.
- **Config**: driven by `.env` (loaded in `settings.py`). `DEBUG` defaults off. DB is SQLite unless `DB_ENGINE` points at Postgres (prod uses AWS RDS via `DB_HOST`). Media uses S3 when `AWS_ACCESS_KEY_ID` is set, else local `media/`. Static files via WhiteNoise. `CORS_ALLOW_ALL_ORIGINS = True`.
- **Docker**: `entrypoint.sh` waits for the DB (only if `DB_HOST` set), runs `migrate`, `collectstatic`, and optionally creates a superuser from `DJANGO_SUPERUSER_*` env vars.

## AI service (`nowli-ai/`)

FastAPI app **"Emotion AI — Human Friend System"** (v4.2). This is the `:8001` server the Flutter app connects to for the AI companion / voice-call feature.

### Commands
- Install deps: `pip install -r requirements.txt` (dependency-only; no lockfile/`pyproject.toml`).
- Run: `python test17.py` — binds `HOST`/`PORT` from env, defaulting to `0.0.0.0:8001` (the port the Flutter app expects; Django owns `:8000`). Override via `nowli-ai/.env` (`HOST`, `PORT`).
- Alternative: `uvicorn test17:app --reload --port 8001` (the `__main__` host/port block is skipped in this mode).
- No test suite is present.

### Architecture
- **Entry point is `test17.py`** — a ~1300-line monolith that defines the `app` object and every served route. It imports helpers from `config.py`, `models.py`, and `services/`.
- **`routers/` (`chat.py`, `emotion.py`) is a parallel modular refactor that is NOT wired into `test17.py`** — those `/emotion/combined` and WebSocket `/chat/stream` endpoints are not mounted. Treat `routers/` as aspirational/dead code; the live endpoints are the `@app.*` routes in `test17.py`.
- **Endpoints** (all under `/api/v1/`): session mgmt (`session/new`, `session/{id}` GET/DELETE), `detect-emotion` (voice + text), `chat-stream` (**SSE**, emotion-aware streaming), `chat/summary` (mood summary), `conversation/emotion-breakdown/{id}`, `conversation/low-mood-detect/{id}`, `quest-suggestions` (`?zone=&mode=auto|static|ai`), `quest-source`, `languages`; plus `/` and `/health`.
- **Emotion pipeline**: OpenAI **Whisper** transcribes audio → **Hume AI** prosody gives voice emotions → **GPT** classifies text emotions → `services/emotion_merger.merge_emotions` weights/merges them → the combined state is injected into the chat system prompt (`services/` holds `hume_emotion`, `text_emotion`, `llm_chat`, `emotion_merger`).
- **Models**: OpenAI `gpt-4o` / `gpt-4o-mini` (chat, summaries, text emotion, quest suggestions) and `whisper-1`; `LLM_MODEL` overridable via env. Hume for voice; if no Hume key, voice emotion is skipped.
- **Quest suggestions** call back into the Django API via `QUEST_API_URL` (defaults to `http://127.0.0.1:8000/api/quests/`); `mode` selects static vs GPT-generated.
- **State**: sessions live in an in-memory dict (`_sessions`) — nothing is persisted; restarting drops all sessions.
- **Config**: `config.py` loads `.env` (also strips inline `#` comments from values). CORS is `allow_origins=["*"]`.

### Gotchas
- **Port contract**: this service must run on `:8001` (the Flutter `AI_BASE_URL` default) because Django owns `:8000`. Both `test17.py`'s `__main__` block and `nowli-ai/.env` now default to `PORT=8001` / `HOST=0.0.0.0`; keep them in sync if you change either.
- There is a stray empty directory literally named `{services,routers}` (a shell brace-expansion mishap) — ignore/delete it; the real code is in `services/` and `routers/`.

## Frontend (`nowli-frontend-app/`)

### Commands
- Install deps: `flutter pub get`
- Run codegen (flutter_gen assets in `lib/core/gen/`): `dart run build_runner build -d`
- Run app: `flutter run`
- Analyze/lint: `flutter analyze` (rules in `analysis_options.yaml`, `flutter_lints`)
- Run tests: `flutter test`; single file: `flutter test test/widget_test.dart`

### Architecture
- **State management** is GetX (`get`); **navigation** is `go_router`. Route config is `AppPages.router` in `lib/core/app_routes/app_pages.dart`, referenced from `main.dart`. UI scales with `flutter_screenutil` (design size 375×812).
- **Networking**: all endpoints and the two base URLs are centralized in `lib/api/api_constant.dart`, both read from `--dart-define` (see below). There are **two backend servers**:
  - `baseUrl` (`:8000`) — the Django API in `nowli-backend/` (auth, profiles, quests, insights).
  - `aiBaseUrl` (`:8001`) — the FastAPI AI/voice service in **`nowli-ai/`** (`/api/v1/session/new`, `/api/v1/chat-stream`, `/api/v1/detect-emotion`, `/api/v1/chat/summary`). Used by `lib/services/ai_call_service.dart`.
- **Layers**: `lib/api/` (auth + profile controllers/services/models), `lib/services/` (feature services: quests, insights, streak, AI call, audio streaming, speech), `lib/models/` (data models), `lib/screen/` (feature UI modules), `lib/widget/` + `lib/custom_code/` (reusable UI), `lib/themes/` + `lib/utlis/color_palette/` (styling).
- **Voice/AI**: `speech_to_text` + `flutter_tts` for the talking companion; audio streaming to the `:8001` server.

### Gotchas (this codebase is under active, messy development)
- `lib/core/` **imports were historically written as `core%20/…`** (a trailing space in the folder name that existed on the original Linux dev box). This broke the build on Windows (which strips the trailing space), so all imports were rewritten to plain `core/`. If you pull code from the original machine, re-check for reintroduced `core%20/` imports.
- `lib/aaa/` (scratch AI-call + reminder experiments), `lib/screen/test_file/`, `lib/screen/debug/`, `*.backup` files, and `je_je_page_gula_connect_kori_nai.dart` are work-in-progress/experimental. Confirm what's actually wired into routes before assuming a file is live.
- Base URLs in `api_constant.dart` come from compile-time `String.fromEnvironment` (`BASE_URL`, `AI_BASE_URL`), defaulting to `localhost`. For non-local backends pass them at run time, e.g. `flutter run --dart-define-from-file=dart_defines.json` (template: `dart_defines.example.json`; real file is git-ignored).

## References
- **`docs/next-phase.md` — START HERE next session.** Prioritized plan of the upcoming work (cleanup tasks first, then Google/Apple OAuth and mobile-device builds), with files-to-touch and gotchas for each.
- `docs/running-locally.md` — verified first-run/setup procedure (toolchain install + per-service commands). Read before trying to run anything.
- `docs/architecture.md` — how the three services connect, data/auth flow, ports, per-service directories and env vars.
- `docs/project-status.md` — current state: what's complete, what's unfinished, and a dated session log.
- **`docs/deploy-aws.md` — AWS deploy runbook** (live on EC2 `16.170.191.239`). SSH + `git archive | ssh tar -x` → `docker compose build && up -d`; prod `.env` gotchas, rollback tags, and the known OpenAI-quota blocker on AI features.
