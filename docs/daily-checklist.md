# Daily Checklist

_The single active document for the current working day. Update **only this file**
during the day. At end of day, write a report in `daily-reports/` and reset this list
for tomorrow. Deferred items go to `future-checklist.md`._

**Day:** 2026-08-04
**Branch:** `feat/design-implementation` (18 commits ahead of `origin`, **not pushed**)
**Yesterday:** `daily-reports/2026-08-03.md` — the money flow verified on a device; AI
Personalization made real; the store cannot sell this plan

---

## ▶ START HERE — two things, in this order

### 1. Deploy yesterday's backend work

The app already sends restricted topics and calls the clear-memory route. Against production
today **both silently do nothing** — the fields and the route are not there yet.

```bash
git -c core.autocrlf=false archive HEAD:nowli-backend \
  | ssh -i ~/.ssh/id_ed25519 ubuntu@16.170.191.239 "tar -x -C ~/backend"
git -c core.autocrlf=false archive HEAD:nowli-ai \
  | ssh -i ~/.ssh/id_ed25519 ubuntu@16.170.191.239 "tar -x -C ~/ai"
```
Then rebuild and `up -d` both. Tag rollback images first (`:backup-20260804`).

- [ ] Rollback tags created
- [ ] Backend deployed — `users.0016`, `0017`, `0018` show `[X]`
- [ ] `nowli-ai` deployed (per-user persona)
- [ ] Smoke: `/api/profiles/clear-ai-memory/` → **401**, not 404
- [ ] On the emulator: pick restricted topics → reopen the screen → they survived
- [ ] Clear AI Memory → says cleared **and** the receipt library is empty afterwards

> ⚠️ `docker compose up -d` was refused twice by the permission classifier yesterday before
> going through. Nothing is half-applied at that point — the source is on the box and the
> image built, but the containers still run the old one.

### 2. Decide how payments are taken

**One business question gates a few days of work: which markets launch first?**

- **US first** → **Stripe on the web**. ~2–3 days, no IAP written at all, and the only way
  the four-step ladder works exactly as designed.
- **Global** → the Subscribe button may only link out in the US, EU, South Korea and Japan.
  Elsewhere it must not appear, so either those markets wait or they get IAP — and IAP brings
  back the device-dependent plan switch and the overpayment risk.

Both paths are researched and written up in **`docs/subscriptions-iap.md`**. Do not
re-research them.

**If Stripe wins:**
- [ ] Stripe account + 4 prices + the schedule (console work, ~1h — yours)
- [ ] Backend: Checkout session, subscription schedule, webhooks, mapping onto the existing
      `Subscription` model, tests
- [ ] Minimal web checkout page tied to the user's account
- [ ] App: paywall opens the web checkout, then refreshes entitlement
- [ ] Remove the `step_down` layer — it exists only for the store path
- [ ] Note: **from 2026-10-01** Google requires reporting and service fees for enrolled
      external-link developers

**If store IAP wins:** follow the console setup in `subscriptions-iap.md` §Google Play, and
expect the keystore below to be the first blocker.

---

## 🔲 After that, in order

- [ ] **Upload keystore does not exist** (`android/key.properties`). It blocks the signed
      build → the Play upload → any store testing. Stripe does not remove this.
      **Decide who creates it** — it is the app's permanent signing identity.
- [ ] **Terms of Service** still does not exist. Both links are commented out with
      `TODO(legal)`. **P0 — the listing needs it.**
- [ ] **Real payments.** `activate` is a mock and `verify-receipt` a 501 stub, so **anyone can
      "subscribe" for free** today.
- [ ] **The Pro screen's stats card** — avatar, streak, quests completed — is the one piece of
      Figma node `7-4114` not built. Needs the streak endpoint plus a completed-quest count.
- [ ] **Push the branch.** 18 commits exist only on this machine.
- [ ] Merge `feat/design-implementation` → `main` once a phone test passes
- [ ] **Email from a real sender** — currently a personal Gmail app password. Now that
      `nowlii.com` exists: `noreply@nowlii.com` via Amazon SES (SPF/DKIM at GoDaddy).

---

## 🔲 The cutover — only after a real phone test

Not the emulator. Each of these breaks any pre-HTTPS build the moment it lands.

- [ ] Flip the HTTPS block in `~/backend/.env`: `SECURE_SSL_REDIRECT`, `SESSION_COOKIE_SECURE`,
      `CSRF_COOKIE_SECURE`, `SECURE_HSTS_SECONDS` (ramp 3600 → 31536000, **not** straight to a
      year — HSTS is effectively irreversible for the duration it advertises)
- [ ] nginx HTTP→HTTPS redirect (the cert was issued `--no-redirect` on purpose)
- [ ] Close 8000/8001 in the AWS security group
- [ ] Then a **release** build becomes possible — needs the upload keystore and the **release
      SHA-1 registered in Google Cloud `274971792537`**, or Google login dies with
      `DEVELOPER_ERROR`

---

## ⛔ Waiting on you (not code)

- [ ] **Which markets at launch** — see §2 above. Everything in payments waits on this.
- [ ] **Companion name suggestions.** `↻` works but the names are placeholder. One-file change
      (`companion_name_suggestions.dart`) once the real list exists.
- [ ] **Should all companions default to the female voice?** Existing accounts were moved, but
      the per-companion seeding (bloop/fizzy/zee/cloudy/glowy female, the rest male) still
      stands and overrides on companion change.
- [ ] **"Spark" now means two things** — the daily call allowance *and* the first price stage.
      Cheap to rename either while nothing is published.
- [ ] **Apple domain verification file**, if the portal asks. nginx already serves
      `/var/www/apple/` at `https://api.nowlii.com/.well-known/…`.

---

## ⚠️ Standing notes

- **HTTPS is live**: `https://api.nowlii.com` and `https://ai.nowlii.com`. Cert expires
  **2026-10-29**, `certbot.timer` auto-renews. Config in `deploy/nginx/`.
- **Testing the paywall on a real account** means disabling the allowlist
  (`SUBSCRIPTION_UNLIMITED_USERS=` in `~/backend/.env` + `up -d`) — that applies to the **whole
  backend**, not one user. Put it back afterwards. `VOICE_CALL_UNLIMITED_USERS` is separate
  and still exempts `pavle` from the daily call limit.
- Backing up prod `.env` before edits: `~/backend/.env.bak-20260803-paywalltest` exists.
- Rollback images on the box: `:backup-20260803`. **Images roll back; migrations do not.**
- **Security-group changes are Console-only.** The `Nowlii` IAM keys are S3-only.
- `flutter` is not on PATH in tool shells — use `C:\src\flutter\bin\flutter.bat`.
- Backend tests: use module labels (`Apps.users.tests`), not app labels.
- Local `.env` OpenAI key is invalid (401) since the 07-23 rotation; one insights test logs
  that and still passes via the fallback. Prod is fine.
- The emulator cannot route host audio, so the mic, the voice check and the AI call cannot be
  judged there. Those need a phone.
- Longer-term backlog in `future-checklist.md`.
