# Running NOWLII locally (Windows)

_Verified end-to-end on 2026-07-01 (Windows 11): backend on `:8000`, `nowli-ai` on `:8001`,
Flutter web frontend served on `:5000`, all three talking to each other._

This is the exact procedure that got a clean first run on a fresh Windows machine.
Follow it top-to-bottom the first time; the **one-time setup** only needs doing once.

> **Port contract:** Django backend = `:8000`, `nowli-ai` = `:8001`, frontend expects
> both at those ports. Don't swap them.

---

## 0. One-time setup (toolchain)

The repo's committed `.venv` folders were built on a Linux machine and **do not work on
Windows** — they are deleted and rebuilt below. You need Python **3.12+** (Django 6
requires it; system Python 3.10 is too old), `uv`, and the Flutter SDK.

```powershell
# 1. Install uv (user-scope, no admin). Installs to %USERPROFILE%\.local\bin
powershell -ExecutionPolicy Bypass -c "irm https://astral.sh/uv/install.ps1 | iex"
$env:Path = "C:\Users\$env:USERNAME\.local\bin;$env:Path"   # for the current shell

# 2. Install Python 3.12 (uv manages it; no system install needed)
uv python install 3.12

# 3. Install Flutter SDK (stable) via git clone to C:\src\flutter
git clone --depth 1 -b stable https://github.com/flutter/flutter.git C:\src\flutter
$env:Path = "C:\src\flutter\bin;$env:Path"
flutter --version            # first run downloads the Dart SDK (a few minutes)
flutter config --enable-web  # we run the frontend as a web app (no Android/VS needed)
```

Add `C:\src\flutter\bin` and `C:\Users\<you>\.local\bin` to your **PATH** permanently
(System → Environment Variables) so new shells pick them up automatically.

**Chrome** must be installed (it is used as the web run target). The Windows desktop /
Android targets are **not** set up here and need extra tooling (Visual Studio 2022 with
the C++ desktop workload, or the Android SDK) — stick to web for local dev.

---

## 1. Backend — Django API (`nowli-backend/`) → http://localhost:8000

```powershell
$env:Path = "C:\Users\$env:USERNAME\.local\bin;$env:Path"
cd "C:\Users\Pavle\Documents\Just Web (projekti)\nowli-app\nowli-backend"

# First time only: remove the Linux-built venv, then build a fresh one
if (Test-Path .venv) { Remove-Item -Recurse -Force .venv }
uv sync                                   # creates .venv + installs from uv.lock

# Local runs use SQLite. The committed .env points DB at a PRODUCTION AWS RDS Postgres,
# so override the engine for local dev (do NOT edit .env):
$env:DB_ENGINE = "django.db.backends.sqlite3"
$env:DEBUG = "True"

uv run python manage.py migrate           # applies migrations to local db.sqlite3
# uv run python manage.py createsuperuser # optional (or set DJANGO_SUPERUSER_* in .env)

uv run python manage.py runserver 127.0.0.1:8000
```

Verify: `http://localhost:8000/api/docs/` (Swagger UI) or
`http://localhost:8000/api/nowlii-options/` → `200 []`.

---

## 2. AI service — `nowli-ai/` (FastAPI) → http://localhost:8001

```powershell
$env:Path = "C:\Users\$env:USERNAME\.local\bin;$env:Path"
cd "C:\Users\Pavle\Documents\Just Web (projekti)\nowli-app\nowli-ai"

# First time only: rebuild the venv (Linux-built one won't run on Windows)
if (Test-Path .venv) { Remove-Item -Recurse -Force .venv }
uv venv --python 3.12
uv pip install -r requirements.txt

# HOST/PORT are env-driven; defaults are 0.0.0.0:8001. Bind localhost for local dev:
$env:HOST = "127.0.0.1"; $env:PORT = "8001"
uv run python test17.py
```

Requires `OPENAI_API_KEY` (and optionally `HUME_API_KEY`/`HUME_SECRET_KEY`) in
`nowli-ai/.env`. Verify: `http://localhost:8001/health` →
`{"status":"ok","openai":true,"hume":true,...}`.

> The live app is `test17.py` (the `routers/` folder is an unused parallel refactor —
> ignore it). Sessions are in-memory and reset on restart.

---

## 3. Frontend — Flutter app (`nowli-frontend-app/`) → http://localhost:5000

Start the backend (`:8000`) and AI service (`:8001`) **first**, then:

```powershell
$env:Path = "C:\src\flutter\bin;$env:Path"
cd "C:\Users\Pavle\Documents\Just Web (projekti)\nowli-app\nowli-frontend-app"
flutter pub get

# Fastest for iterative dev — hot reload, launches Chrome:
flutter run -d chrome `
  --dart-define=BASE_URL=http://localhost:8000 `
  --dart-define=AI_BASE_URL=http://localhost:8001

# Or build a static bundle and serve it (what we verified):
flutter build web `
  --dart-define=BASE_URL=http://localhost:8000 `
  --dart-define=AI_BASE_URL=http://localhost:8001
cd build\web
python -m http.server 5000 --bind 127.0.0.1   # open http://localhost:5000
```

The two `--dart-define` values are the API base URLs; without them the app defaults to
`localhost:8000`/`localhost:8001` anyway, but pass them explicitly to be safe. For a
non-local backend, use `--dart-define-from-file=dart_defines.json` (see
`dart_defines.example.json`).

**For Google Sign-In (B1):** a real `dart_defines.json` now also carries
`GOOGLE_WEB_CLIENT_ID`. Run on a **fixed** web port so it matches the Google Cloud authorized
origin, e.g. `flutter run -d chrome --web-port=5000 --dart-define-from-file=dart_defines.json`.
See `google-login.md` for the required Google Cloud config.

---

## Gotchas hit during first run (and their fixes)

- **`lib/core/` trailing-space import bug.** Imports were written as
  `package:nowlii/core%20/...` (`%20` = a trailing space in the folder name). The folder
  was genuinely `core ` on the original Linux dev box, but Windows strips the trailing
  space on copy, so the imports broke the web compile
  (`Error reading 'lib/core%20/app_routes/app_pages.dart'`). **Fixed** by rewriting all
  23 imports to `core/` (the portable form). If you re-import from the Linux machine,
  re-check this.
- **Committed `.venv` folders are Linux-built** (`/home/fahad-mindmatrix/...`) — always
  delete and rebuild with `uv` on Windows. Don't try to reuse them.
- **Python 3.10 is too old.** Django 6 needs 3.12+; use `uv python install 3.12`.
- **Production DB in `.env`.** `nowli-backend/.env` points at AWS RDS Postgres. Override
  `DB_ENGINE=django.db.backends.sqlite3` for local work rather than hitting/altering prod.
- **Also override `DB_NAME` locally.** `.env` sets `DB_NAME=nowlii`. If you only override
  the engine, Django creates a SQLite file literally named `nowlii` (no extension) that the
  ignore rules can miss. Override `DB_NAME=db.sqlite3` too, e.g.
  `$env:DB_NAME="db.sqlite3"`, so the local DB is the standard git-ignored `db.sqlite3`.
  (See `technical-debt.md` TD-012.)
- **Developer Mode.** Standalone `flutter pub get` warns
  *"Building with plugins requires symlink support — enable Developer Mode."* Web builds
  work without it, but **Windows/Android/iOS** native targets need Developer Mode on
  (`start ms-settings:developers`, requires admin).

## Quick reference

| Service       | Dir                    | Command (after setup)                                             | URL                     |
|---------------|------------------------|-------------------------------------------------------------------|-------------------------|
| Backend       | `nowli-backend/`       | `$env:DB_ENGINE="django.db.backends.sqlite3"; uv run python manage.py runserver 127.0.0.1:8000` | http://localhost:8000/api/docs/ |
| AI service    | `nowli-ai/`            | `$env:PORT="8001"; uv run python test17.py`                       | http://localhost:8001/health    |
| Frontend      | `nowli-frontend-app/`  | `flutter run -d chrome --dart-define=BASE_URL=http://localhost:8000 --dart-define=AI_BASE_URL=http://localhost:8001` | (Chrome) |
