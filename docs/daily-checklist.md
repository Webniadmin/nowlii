# Daily Checklist

_The single active document for the current working day. Update **only this file**
during the day. At end of day, write a report in `daily-reports/` and reset this list
for tomorrow. Deferred items go to `future-checklist.md`._

**Day:** 2026-08-05
**Branch:** `feat/design-implementation` — **25 commits ahead of `origin`, not pushed**
**Yesterday:** `daily-reports/2026-08-04.md` — partial lock after a lapse; four screens that
reported success they had not achieved; home restored to the original design

---

## ▶ START HERE — push, before anything else

The 2026-08-04 work is committed (7 commits), and `Apps/subscriptions/permissions.py` inside
the running container was verified byte-identical to `HEAD` — so a
`git archive HEAD:nowli-backend` deploy is now safe and would be a no-op for the entitlement
gate. That risk is closed.

What is still true: **25 commits exist on this machine and nowhere else.**

- [ ] **`git push -u origin feat/design-implementation`**
- [ ] Merge → `main` once a phone test passes

---

## 🔲 Then, in order

- [ ] **The blue hero card has never been seen.** `_buildReadyCard()` only renders while
      sparks remain, and the test account had none left. Check it, including the
      "Todays progress" bar against a day with some quests done.
- [ ] **A test for the avatar plumbing.** `CreateProfileRequest.toJson()` must emit
      `predefined_option`; it went missing once and cost every new account its companion.
- [ ] **Merge `feat/design-implementation` → `main`** once a phone test passes.

---

## ⛔ Waiting on you (not code)

- [ ] **Which markets at launch** — Stripe vs store IAP. Everything in payments waits on it.
      Researched in `subscriptions-iap.md`; do not re-research.
- [ ] **"Your moves" covers 2 of 4 zones.** Soft steps and Power move are drawn; Stretch zone
      and Elevated are not, so a week of those shows 0 and 0 with real data behind it.
      Redesign the card, or map the missing zones onto the two rings?
- [ ] **"Today / Plan" date buttons** from Figma `1:1317` were not restored — home is
      deliberately today-only, other days live in the Quests tab. Back or not?
- [ ] **The last-said card** is out of the home layout (method kept in code). It is not in the
      restored design. Gone for good, or does it belong somewhere?
- [ ] **Upload keystore does not exist** — blocks the signed build, the Play upload, and any
      store testing. Decide who creates it; it is the app's permanent signing identity.
- [ ] **Terms of Service** still does not exist. **P0 — the listing needs it.**
- [ ] **Companion name suggestions** are placeholder (`companion_name_suggestions.dart`).

---

## ⚠️ Standing notes

- **Both QA allowlists are EMPTY on production** (`SUBSCRIPTION_UNLIMITED_USERS`,
  `VOICE_CALL_UNLIMITED_USERS` in `~/backend/.env`), at the user's request, so `pavle` hits
  the real trial, the real paywall and the real 2-calls-a-day limit. **Real calls now cost
  real money** (~$0.25 each). Restoring the exemptions = delete those two lines and
  `up -d`; absent means default `['pavle']`. Backup:
  `.env.bak-20260804-before-allowlist-removal`.
- **`-f docker-compose.prod.yml` is required** on the box — a bare `docker compose build` in
  `~/backend` fails with "no configuration file provided".
- Env changes take effect on container **create**, not restart — always `up -d`.
- `pavle` is prod user **id 7**, profile name "miki". Trial dates were moved several times
  yesterday; check `compute_status` before trusting the row.
- **HTTPS is live**: `https://api.nowlii.com`, `https://ai.nowlii.com`. Cert to 2026-10-29.
- `flutter` is not on PATH in tool shells — use `C:\src\flutter\bin\flutter.bat`.
- Backend tests: use module labels (`Apps.users.tests`). A bare `manage.py test` finds
  **nothing**. `Apps.support` has no test module.
- Local `.env` OpenAI key is invalid since the 07-23 rotation; one insights test logs the 401
  and still passes via the fallback. Prod is fine.
- The emulator cannot route host audio, so the mic, the voice check and the AI call cannot be
  judged there. Those need a phone.
- **Figma MCP hits a per-seat call limit** (a View seat on Professional). It ran out mid-task
  yesterday; budget the calls or expect to work from screenshots.
- Longer-term backlog in `future-checklist.md`.

---

## 🔲 The cutover — only after a real phone test

Not the emulator. Each of these breaks any pre-HTTPS build the moment it lands.

- [ ] Flip the HTTPS block in `~/backend/.env`: `SECURE_SSL_REDIRECT`,
      `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`, `SECURE_HSTS_SECONDS` (ramp
      3600 → 31536000, **not** straight to a year — HSTS is effectively irreversible for the
      duration it advertises)
- [ ] nginx HTTP→HTTPS redirect (the cert was issued `--no-redirect` on purpose)
- [ ] Close 8000/8001 in the AWS security group
- [ ] Then a **release** build becomes possible — needs the upload keystore and the **release
      SHA-1 registered in Google Cloud `274971792537`**, or Google login dies with
      `DEVELOPER_ERROR`
