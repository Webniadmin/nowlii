# NOWLII — AWS Deploy (backend + nowli-ai)

_Rewritten 2026-07-21 after the **first full deploy from this repo**. Supersedes the earlier
"SSH → git pull → up --build" draft, which described a mechanism that does not exist on the box._

## TL;DR — how to deploy now

From the repo root on the dev machine (SSH access is set up — see below):

```bash
# ---- Backend (Django :8000) ----
git -c core.autocrlf=false archive HEAD:nowli-backend \
  | ssh -i ~/.ssh/id_ed25519 ubuntu@16.170.191.239 "tar -x -C ~/backend"
ssh -i ~/.ssh/id_ed25519 ubuntu@16.170.191.239 \
  "cd ~/backend && docker compose -f docker-compose.prod.yml build && docker compose -f docker-compose.prod.yml up -d"

# ---- nowli-ai (:8001) ----
git -c core.autocrlf=false archive HEAD:nowli-ai \
  | ssh -i ~/.ssh/id_ed25519 ubuntu@16.170.191.239 "tar -x -C ~/ai"
ssh -i ~/.ssh/id_ed25519 ubuntu@16.170.191.239 \
  "cd ~/ai && docker compose -f docker-compose.prod.yml build && docker compose -f docker-compose.prod.yml up -d"
```

- **`-c core.autocrlf=false` is REQUIRED on Windows** — otherwise `git archive` re-injects CRLF and
  `entrypoint.sh` crash-loops with `exec /app/entrypoint.sh: no such file or directory`.
- `git archive` ships **only tracked files** (no `.venv`, no local `.env`, no `db.sqlite3`), so the box's
  **production `.env` files are preserved** (they are git-ignored and never in the archive).
- The backend `entrypoint.sh` runs **`migrate` against the production RDS** + `collectstatic` to S3 on every
  boot — so a backend deploy is a deliberate prod DB migration. Watch the logs after.

## The box

- **Host:** `16.170.191.239` — `ubuntu@`, instance `i-0c053bc7fea33f0df`, region `eu-north-1`,
  AWS account `227755136391`, Ubuntu 24.04. Public DNS `ec2-16-170-191-239.eu-north-1.compute.amazonaws.com`.
- **DB:** AWS RDS Postgres `nowlii.cts2swoie0hb.eu-north-1.rds.amazonaws.com:5432` (prod — the box `.env`
  `DB_*` points here). **Media:** S3 bucket `nowlii` (`eu-north-1`), public HTTPS URLs.
- **Runtime:** two Docker containers, images built **on the box** from our source:
  - `nowlii-backend` ← `fahad1000mir/nowlii-backend:dev` (Gunicorn + UvicornWorker, 4 workers, :8000).
  - `nowlii-ai-prod` ← `fahad1000mir/nowlii-ai:dev` (FastAPI `test17.py`, :8001, healthcheck).
  - The `fahad1000mir/*` names are historical (original dev's Docker Hub). We do **not** push there — we
    build locally on the box, which just overwrites those local tags. No Docker Hub login needed.
- **Layout:** `~/backend` and `~/ai` each hold the app source (shipped by `git archive`) + a git-ignored
  **`.env`** (prod secrets) + `docker-compose.prod.yml`. No git repo on the box.

## SSH access (set up 2026-07-21)

Pavle's key `~/.ssh/id_ed25519` (`justweb.rs@gmail.com`) is in `~ubuntu/.ssh/authorized_keys`.
Connect: `ssh -i ~/.ssh/id_ed25519 ubuntu@16.170.191.239`.

**To re-bootstrap access from scratch** (e.g. a new machine): AWS Console (IAM user `Nowlii`, has
EC2/RDS/S3 FullAccess) → open **CloudShell** → `aws ec2-instance-connect ssh --instance-id
i-0c053bc7fea33f0df --os-user ubuntu --region eu-north-1` → append the new public key to
`~/.ssh/authorized_keys`. The browser "EC2 Instance Connect" button also works.

> ⚠️ **Clock-skew trap:** if AWS Console/CloudShell/CLI throws `Signature expired` / `Request has expired`
> / credential 500s, the **dev machine clock is wrong**, not IAM. Fix the Windows clock first
> (`w32tm /resync` as admin). This blocked us for ~1h on 2026-07-21.

## Rollback

The pre-2026-07-21 images are tagged `:backup-20260721`:
```bash
ssh -i ~/.ssh/id_ed25519 ubuntu@16.170.191.239 \
  "docker tag fahad1000mir/nowlii-backend:backup-20260721 fahad1000mir/nowlii-backend:dev \
   && cd ~/backend && docker compose -f docker-compose.prod.yml up -d"   # same shape for ~/ai
```

## Production `.env` gotcha — it lags the code ("works local, fails on AWS")

The box `.env` files predate several env vars the current code reads, which caused feature-specific
failures. **When a flow works locally but fails on AWS, diff the two `.env` var sets first.**
Fixes already applied to `~/backend/.env` on 2026-07-21 (backup: `~/backend/.env.bak-20260721`):

| Var added | Fixes | Notes |
|---|---|---|
| `ALLOWED_HOSTS=16.170.191.239,ec2-16-170-191-239...,localhost,127.0.0.1` | 400 on every request | newer `settings.py` needs explicit hosts when `DEBUG=False` |
| `CSRF_TRUSTED_ORIGINS=http://16.170.191.239:8000,:8001` | admin/CSRF | |
| `SOCIAL_AUTH_GOOGLE_CLIENT_ID=274971792537-…apps.googleusercontent.com` | Google login `503→401` | the **Web** client id the app signs with |

Note the box `.env` still literally contains `DEBUG=True`, but `docker-compose.prod.yml` forces
`DEBUG=False` (compose env wins). Email/signup works via `settings.py` defaults
(`EMAIL_HOST=smtp.gmail.com`/587/TLS, `DEFAULT_FROM_EMAIL→EMAIL_HOST_USER`) since the box has
`EMAIL_HOST_USER`+`EMAIL_HOST_PASSWORD`.

## Known issues / not-yet-working (as of 2026-07-21)

- **AI features are down on the shared OpenAI key — `insufficient_quota` (429).** The **same** OpenAI key is
  in local + AWS backend + AWS ai `.env` (sha `7457e203…`), and its account is out of credits. This breaks:
  **AI voice** (chat-stream → silence), **Insights** (`/api/insights/` → 500), **AI subtask generation**.
  Fix = add OpenAI billing credits, **or** rotate to a funded key, **or** set a funded `ANTHROPIC_API_KEY`
  on the backend (Django AI uses Anthropic→OpenAI→Google; **nowli-ai voice uses OpenAI only, no fallback**).
- **Apple login → 503** — `APPLE_*` not configured (deferred per `next-phase.md`).
- **Insights returns a raw 500 instead of graceful fallback** when the AI call fails (`insights/views.py`
  `get` → `ai_client.generate_weekly_reflections` isn't wrapped). Robustness TODO.
- **API path quirk:** nowli-ai `quest-suggestions` is at `/api/quest-suggestions/` (no `/v1/` prefix like
  the rest). Cosmetic; the app doesn't call it.

## Full endpoint audit (verified live 2026-07-21)

**Working:** auth (email login, **Google login**, register+email), quests CRUD, streak, subtasks CRUD,
profiles, avatars/S3, nowlii-options, subscriptions (`plan`+`me`), voice-call quota, support; nowli-ai
health/session/languages/quest-source/quest-suggestions. **Down only via the OpenAI quota:** AI voice,
insights, AI subtask-gen. **Deferred:** Apple login (503).

## Frontend build for device testing

```bash
cd nowli-frontend-app
flutter build apk --debug --dart-define-from-file=dart_defines.prod.json   # → build/app/outputs/flutter-apk/app-debug.apk
```
- `dart_defines.prod.json` points at `http://16.170.191.239:8000` / `:8001`.
- **Debug** APK allows cleartext HTTP (the AWS endpoints are plain HTTP). Because AWS is a public IP, the
  phone works over any internet connection (WiFi or mobile data) — no LAN needed.
- Google login works on the debug APK (debug-keystore SHA-1 is registered in Google Cloud `274971792537`).
- A **release**/Play build will require **HTTPS** (domain + TLS, e.g. ALB/Nginx + Let's Encrypt) in front
  of both ports, plus a signing config.
```
