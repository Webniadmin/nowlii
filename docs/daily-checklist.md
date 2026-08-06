# Daily Checklist

_The single active document for the current working day. Update **only this file**
during the day. At end of day, write a report in `daily-reports/` and reset this list
for tomorrow. Deferred items go to `future-checklist.md`._

**Day:** 2026-08-06
**Branch:** `feat/design-implementation` — pushed and **deployed**; still not merged to `main`
**Yesterday:** `daily-reports/2026-08-05.md` — reminders follow the phone's clock, the
edit path stopped ignoring them, five screens stopped disagreeing with themselves, backend
deployed, first prod APK built

---

## ▶ START HERE — put the APK on a real phone

`nowli-frontend-app/build/app/outputs/flutter-apk/nowlii-prod-v0.1.apk` exists and points at
the live HTTPS backend. Four weeks of work have never run on hardware, and three things can
only be judged there: the microphone, the voice check, and an AI call. The emulator cannot
route host audio.

- [ ] Install it and sign in as a real user
- [ ] **Confirm the timezone fix on the device** — make a quest for a time an hour out and
      check the card says that time, not that time plus your UTC offset. This is the whole
      point of yesterday's deploy and it only takes effect for a phone running the new APK.
- [ ] Microphone, voice check, one AI call (~$0.25 — the QA allowlists are empty)
- [x] **Google login — works on the device, and a real bug came out of it.** Only the *first*
      Google signup ever could succeed: the account was built from the email alone, leaving
      `username` empty, and the model requires a unique one — so that first row took the empty
      username and every later new account 500ed forever, while anyone already registered
      signed in fine. Fixed, deployed and verified on a phone (`794d7ca`); a fresh account was
      created live at 19:13 (`p.pavle16`, id 51). The SHA-1 above never became a problem.
- [ ] **Second phone still to retry** — `kekile49@gmail.com` was the account that failed all
      afternoon and has not tried since the fix went out at ~18:26.
- [ ] Merge → `main` once it passes

---

## ⛔ Waiting on you (not code)

- [ ] **Trial-ending reminders do not exist.** The trial screen promises a reminder on day 5
      and day 6; nothing anywhere sends either. Pick one:
      **local notifications** (recommended — the mechanism exists and delivered twice
      yesterday, no backend, works offline; lost if the app is deleted) or a **backend job**
      (survives reinstall; needs cron on the box and there is no scheduler today).
- [ ] **Which markets at launch** — Stripe vs store IAP. Everything in payments waits on it.
      Researched in `subscriptions-iap.md`; do not re-research.
- [ ] **Two zone colours unconfirmed** — Stretch zone `#3D87F5`, Power move `#D53D40`. Send a
      Figma link with the zone chips *selected* (`node-id=0-1` is a page root and returns
      "nothing selected"). It is one constant now: `utils/color_palette/zone_colors.dart`.
- [ ] **Upload keystore does not exist** — blocks a Play-acceptable build. It is the app's
      permanent signing identity; decide who creates it.
- [ ] **Terms of Service** still does not exist. **P0 — the listing needs it.**
- [ ] **Your dev machine is nearly full** — 8 GB of 559 GB. It hit 0 yesterday and silently
      broke a build *and* a test run. Worth finding what took 551 GB.
- [ ] **"Your moves" covers 2 of 4 zones** — a week of Stretch or Elevated shows 0 and 0.
      Redesign the card, or map the missing zones onto the two rings?
- [ ] **Companion name suggestions** are placeholder (`companion_name_suggestions.dart`).

---

## 🔲 Then, if there is time

- [ ] **Reminders drop to inexact alarms after every restart.** `_canScheduleExact` is set
      only in `requestPermissions()`, called only from the create-quest screen, so after a
      restart `sync()` arms `inexactAllowWhileIdle` even though the permission is granted.
      Measured yesterday: a 12:10 reminder landed at 12:12:45, window 24 minutes. Fix is
      small — have `sync()` re-read the permission.
- [ ] **Re-verify the lapsed state on a device.** It is covered by backend tests and was
      exercised on 2026-08-04, but the QA account is now a paying subscriber, so repeating it
      means editing prod subscription data.
- [ ] **The stranded-call prompt has never been seen** — reaching it costs a real call.
- [x] ~~Clean up the two test quests left on the prod account (`Test poziv A`)~~ — moot, the
      account was deleted.

---

## ⚠️ Standing notes

- **Compose service on the box is `backend`, not `web`.** `exec web …` answers "service is
  not running" and reads like an outage.
- **`-f docker-compose.prod.yml` is required** on the box — a bare `docker compose build` in
  `~/backend` fails with "no configuration file provided".
- Env changes take effect on container **create**, not restart — always `up -d`.
- **Existing scheduled calls keep their old (wrong) instants** until their quest is saved
  again or their phone reports a timezone. A profile save re-derives every pending call.
- **Both QA allowlists are EMPTY on production** (`SUBSCRIPTION_UNLIMITED_USERS`,
  `VOICE_CALL_UNLIMITED_USERS`), at the user's request. **Real calls cost real money**
  (~$0.25 each). Restoring = delete those two lines and `up -d`. Backup:
  `.env.bak-20260804-before-allowlist-removal`.
- **The QA account was deleted and recreated on 2026-08-06** to test a first-time Google
  signup. It is now `p.pavle16@gmail.com` = prod user **id 51**, username `p.pavle16`, on a
  **fresh 7-day trial from today**. The old id 7 / username `pavle` are dead references —
  including in the two allowlists above, which match on username. 97 rows went with it
  (15 quests, 45 calls, 5 summaries, the subscription row), so any earlier finding that
  rested on that history is gone.
- **Production logs 500s now.** `LOGGING` sends `django.request` + `Apps.*` to stdout, so
  `docker logs nowlii-backend` holds tracebacks. Before today, `DEBUG=False` with no `ADMINS`
  mailed every traceback to nobody and nginx status codes were the only evidence.
- **`AUTH_USER_MODEL` is never set** — production runs Django's stock `auth.User`, so
  `Apps/users/models.py::CustomUserModel` is not the model in use despite being migrated and
  referenced everywhere. See `future-checklist.md`.
- **HTTPS is live**: `https://api.nowlii.com`, `https://ai.nowlii.com`. Cert to 2026-10-29.
- `flutter` is not on PATH in tool shells — use `C:\src\flutter\bin\flutter.bat`.
- Backend tests: use module labels (`Apps.users.tests`). A bare `manage.py test` **errors**
  rather than finding nothing. `Apps.support` has no test module.
- Local `.env` OpenAI key is invalid since the 07-23 rotation; one insights test logs the 401
  and still passes via the fallback. Prod is fine.
- The emulator cannot route host audio, so the mic, the voice check and the AI call cannot be
  judged there. Those need a phone.
- **Figma MCP hits a per-seat call limit** (a View seat on Professional). Budget the calls;
  `get_design_context` needs a node-specific URL, and a page root returns "nothing selected".
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
