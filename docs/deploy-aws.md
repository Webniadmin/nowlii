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

Backup image tags on the box: **`:backup-20260729`** (state before the 07-29 deploy) and
`:backup-20260721`.
```bash
ssh -i ~/.ssh/id_ed25519 ubuntu@16.170.191.239 \
  "docker tag fahad1000mir/nowlii-backend:backup-20260729 fahad1000mir/nowlii-backend:dev \
   && cd ~/backend && docker compose -f docker-compose.prod.yml up -d"   # same shape for ~/ai
```
⚠️ **Images roll back; migrations do not.** The 07-29 deploy applied 4 migrations to prod RDS. Rolling
the image back leaves the new columns/tables in place — harmless (the old code ignores them), but a
true rollback would need `migrate <app> <previous>` run deliberately.

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

## Deploy log — 2026-07-29 (branch `feat/realtime-voice-call`)

Shipped everything from the 07-28 / 07-29 sessions (the box had been running 07-21 backend + 07-23 ai).
Rollback tags created first: **`:backup-20260729`** (both images); prod `.env` copied to
`.env.bak-20260729` in `~/backend` and `~/ai`.

- **Backend** — 4 migrations applied against prod RDS: `users.0013_nowliipredefinedoption_voice`,
  `0014_seed_companion_voices`, `0015_profile_rest_days`, `voice_calls.0004_callsummary`.
  ⚠️ The boot log only showed `0015` (log window); **`showmigrations` is the authoritative check** —
  all four are `[X]`.
- **nowli-ai** — persona + per-gender voice + the Insights AI timeout.

**Verification used (repeatable — this is how you prove a deploy actually landed):**

| Check | Before deploy | After |
|---|---|---|
| `GET /api/voice-calls/summaries/` | **404** (route absent) | **401** (exists, auth required) |
| `GET /api/insights/rest-days/` | **404** | **401** |
| `session/new` `voice:"Male"` → `realtime/token` | `marin` (ignored) | **`cedar`** |
| `session/new` `voice:"Female"` → token | `marin` | `marin` |
| `realtime/token` model | `gpt-realtime-mini` | `gpt-realtime-mini` (cost cap intact) |

> **404 vs 401 is the tell.** Every protected endpoint returns **401** unauthenticated; a **404** means the
> route doesn't exist in the deployed code. Comparing the two is a credential-free way to check a deploy.

### Second deploy, same day — the 7-day trial + paywall

Backend only (`nowli-ai` was unchanged since the morning deploy — check with
`git diff --stat <last-deployed-sha>..HEAD -- nowli-ai` before rebuilding it for nothing).
Rollback tag: **`:backup-20260729b`**. Migration `subscriptions.0002` applied to prod RDS.

**Verified on prod without writing to it** — the probe ran inside a `transaction.atomic()` block
that raises at the end, so the throwaway user and its subscription rows never persisted:

```
users=8  subscriptions=0  staff(exempt)=1
fresh login  → in_trial=True days_left=7 has_access=True
quests       → 200          (usable during trial)
after expiry → 402 code=subscription_required
/subscriptions/me/ → 200    (can still pay)
after buying → quests 200
transaction rolled back — prod DB untouched
```

> **Nobody was locked out by this deploy.** All 8 existing users had no subscription row, so each
> gets a fresh 7-day trial on their next request rather than an instant block.

**If the paywall misbehaves in production**, two escape hatches, no redeploy needed:
`SUBSCRIPTION_ENFORCED=False` in `~/backend/.env` (+ restart) turns the gate off entirely, or add
the account to `SUBSCRIPTION_UNLIMITED_USERS` (defaults to `pavle`; staff/superusers always exempt).

## Known issues / not-yet-working (as of 2026-07-29)

- **Payments are not real.** The paywall is live and enforced, but `POST /subscriptions/activate/`
  is a **mock** and `verify-receipt/` returns 501 — anyone can "subscribe" for free. Phase 2
  (Apple IAP / Google Play Billing) is required before this is a real product.
- **Apple login → 503** — `APPLE_*` not configured (deferred per `next-phase.md`).
- **API path quirk:** nowli-ai `quest-suggestions` is at `/api/quest-suggestions/` (no `/v1/` prefix like
  the rest). Cosmetic; the app doesn't call it.
- ~~**Insights returns a raw 500 instead of graceful fallback**~~ ✅ **fixed 2026-07-29** (`cc29803`) —
  `/api/insights/` now degrades to data-derived fallback copy and returns 200, with an `ai_degraded`
  flag. Also added a 20 s provider timeout (`AI_REQUEST_TIMEOUT`); the SDKs defaulted to 600 s.
- ~~**AI features down — `insufficient_quota`**~~ resolved 2026-07-23 by the key rotation (the spend was a
  **leaked key**, not the app — see `daily-reports/2026-07-23.md`). `/health` reports `openai:true` and
  `realtime/token` returns 200. **Still open on the user side: set a hard OpenAI budget cap.**

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
