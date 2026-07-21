# NOWLII — AWS Deploy (backend + nowli-ai)

_Created 2026-07-14. Status: **partially reverse-engineered.** The EC2 host was set up by the
original dev (Md Fahad Mir); there is **no deploy script, no CI, and no documented SSH access**
in this repo. This file records what is confirmed vs. what still needs to be filled in._

## What's confirmed (live, verified 2026-07-14)

- **EC2 public IP: `16.170.191.239`** (region `eu-north-1`, same as RDS + S3).
- Both services respond over plain **HTTP** (no TLS/domain yet):
  - Django API — `http://16.170.191.239:8000/api/docs/` → 200
  - nowli-ai — `http://16.170.191.239:8001/health` → `{"status":"ok","openai":true,"hume":true,...}`
- **Database:** AWS RDS Postgres `nowlii.cts2swoie0hb.eu-north-1.rds.amazonaws.com:5432`
  (`.env` → `DB_*`). This is the **production DB** — local commands hit it unless you override
  `DB_ENGINE`/`DB_NAME` to SQLite.
- **Media:** S3 bucket `nowlii` (`eu-north-1`), public HTTPS asset URLs.
- **Django is containerized:** `docker-compose.prod.yml` builds from the local repo context
  (`Dockerfile` → Gunicorn + UvicornWorker, 4 workers, `0.0.0.0:8000`, `restart: always`).
  `entrypoint.sh` auto-runs `migrate` + `collectstatic` + optional superuser on every boot.
- GitHub remote for THIS working copy: `git@github.com:Webniadmin/nowlii.git` (branch `main`).
  The README still references the original `github.com/Md-Fahad-Mir/Nowlii` — **confirm which
  repo/branch the EC2 box actually pulls from.**

## The likely deploy flow (Django) — NOT yet run/verified by us

Once you have SSH into the EC2 box:

```bash
ssh <user>@16.170.191.239                 # key/user UNKNOWN — see "Needed" below
cd <path-to-repo-on-ec2>/nowli-backend     # path UNKNOWN
git pull origin main                       # pull commit 26968f9 (Apple callback etc.)
docker-compose -f docker-compose.prod.yml up --build -d   # rebuild + restart Django
docker-compose -f docker-compose.prod.yml logs -f backend # watch: DB wait, migrate, collectstatic
```

`entrypoint.sh` handles migrations and static automatically, so no manual `migrate` needed
if the container restarts cleanly. `.env` on the box already carries prod DB/S3/keys.

## nowli-ai (:8001) — deploy mechanism UNKNOWN

There is **no docker-compose / Dockerfile for `nowli-ai/`** in the repo, yet `:8001` is live on
EC2. It is being run some other way — likely one of:
- a manual `python test17.py` inside a screen/tmux/systemd unit, or
- a separately-built container not tracked here.

**To push the updated `test17.py` (fluid-convo + `/conversation/call-insights/`), we must know
how this process is managed on the box** (restart command, working dir, which `.env`).

## Needed from the account owner before we can deploy

1. **SSH access** to `16.170.191.239` — the login user + private key (or add our key to
   `~/.ssh/authorized_keys` on the box). Nothing in `~/.ssh` here reaches this host.
2. **Repo/branch the box tracks** (`Webniadmin/nowlii` vs `Md-Fahad-Mir/Nowlii`) and the
   **checkout path** on the box.
3. **How nowli-ai is started/restarted** on the box (systemd? screen? docker?).

## Frontend note (prod build)

The mobile app has no HTTPS backend yet, so the prod build (`dart_defines.prod.json` →
`http://16.170.191.239:8000` / `:8001`) works only as a **debug** APK (debug manifest allows
cleartext). A release APK or App Store/Play build will require **HTTPS** — i.e. a domain +
TLS (e.g. ALB/Nginx + Let's Encrypt) in front of both ports. See `next-phase.md`.
