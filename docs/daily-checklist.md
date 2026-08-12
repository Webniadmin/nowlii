# Daily Checklist

_The single active document for the current working day. Update **only this file**
during the day. At end of day, write a report in `daily-reports/` and reset this list
for tomorrow. Deferred items go to `future-checklist.md`._

**Day:** 2026-08-13
**Branch:** `feat/design-implementation` — pushed; still not merged to `main`
**Yesterday:** `daily-reports/2026-08-12.md` — the pose art landed, and the mapping under
every avatar turned out to have been wrong for five of the six companions

---

## ▶ START HERE — the phone test, seven days overdue

Everything else on this list is smaller than this one. A **prod** APK pointing at the live
HTTPS backend has been waiting since 08-06, and three things can only be judged on hardware
because the emulator cannot route host audio.

- [ ] **Build a fresh APK** — yesterday's frontend work is not in the one on disk.
      `flutter build apk --dart-define-from-file=dart_defines.prod.json`
- [ ] Install it and sign in as a real user
- [ ] **Confirm the timezone fix on the device** — make a quest for a time an hour out and
      check the card says that time, not that time plus your UTC offset
- [ ] Microphone, voice check, one AI call. **The allowlists are empty again, so this costs
      ~$0.25 and the daily limit is 2.**
- [ ] **Second phone still to retry** — `kekile49@gmail.com` failed all of 08-06 afternoon
      and has not tried since the fix went out at ~18:26
- [ ] Merge → `main` once it passes

While the call is open, three things fixed yesterday are worth a glance on real hardware,
since the emulator's silence made every summary a degenerate one:
the **mood face** (should follow what the summary actually says), the **"Save reflection"**
wording, and the **call screen pulse**.

---

## 🔲 Then, in rough order of value

- [ ] **See the other five companions on a screen.** The avatar→art mapping was rewritten
      yesterday and only **Zee** has been looked at — the other five are covered by
      `test/companion_pose_test.dart` against the real production ids and URLs, not by eye.
      Switch the QA account's companion and check the home card. Use the **main avatar
      picker**, not the pencil on Edit Profile: that goes to the rename screen, which has the
      known "doesn't send `predefined_option`" bug.
- [ ] **Reminders drop to inexact alarms after every restart.** `_canScheduleExact` is set
      only in `requestPermissions()`, called only from the create-quest screen, so after a
      restart `sync()` arms `inexactAllowWhileIdle` even though the permission is granted.
      Measured on 08-05: a 12:10 reminder landed at 12:12:45, window 24 minutes. Fix is
      small — have `sync()` re-read the permission.
- [ ] **Finish the 320dp sweep.** Home, Quests, Progress, Insights, Profile, Edit Profile and
      the paywall were checked yesterday. **Not yet:** the onboarding steps, Settings, and the
      call / voice-check screens. Recipe in the standing notes below.
- [ ] **Re-verify the lapsed state on a device.** Covered by backend tests and exercised on
      2026-08-04, but the QA account is mid-trial, so repeating it means editing prod
      subscription data.
- [ ] **The stranded-call prompt has never been seen** — reaching it costs a real call.

---

## ⛔ Waiting on you (not code)

- [ ] **Trial-ending reminders do not exist.** The trial screen promises a reminder on day 5
      and day 6; nothing anywhere sends either. Pick one:
      **local notifications** (recommended — the mechanism exists and is proven, no backend,
      works offline; lost if the app is deleted) or a **backend job** (survives reinstall;
      needs cron on the box and there is no scheduler today). **P0 — blocks the listing.**
- [ ] **Terms of Service** still does not exist. **P0 — the listing needs it.**
- [ ] **Upload keystore does not exist** — blocks a Play-acceptable build. It is the app's
      permanent signing identity; decide who creates it.
- [ ] **Which markets at launch** — Stripe vs store IAP. Everything in payments waits on it.
      Researched in `subscriptions-iap.md`; do not re-research.
- [ ] **Decide: the app-icon tile on two popups.** `all_quests_done_popup` and
      `missed_talks_popup` used to show the companion on an indigo rounded square. Now that
      the served art is transparent and unclipped, only the character shows. Restore the tile
      (one line per site) or keep it as is?
- [ ] **`waving` is shipped but unused.** The fourth pose has no slot. Candidates: the
      swipe-to-talk reminder, the paywall companion, the two popups above.
- [ ] **Two zone colours unconfirmed** — Stretch zone `#3D87F5`, Power move `#D53D40`. Send a
      Figma link with the zone chips *selected* (a page root returns "nothing selected").
      It is one constant now: `utils/color_palette/zone_colors.dart`.
- [ ] **"Your moves" covers 2 of 4 zones** — a week of Stretch or Elevated shows 0 and 0.
      Redesign the card, or map the missing zones onto the two rings?
- [ ] **Companion name suggestions** are placeholder (`companion_name_suggestions.dart`).
- [ ] **Your dev machine is nearly full** — 8 GB of 559 GB on 08-06, and several APK builds
      have landed since.

---

## ⚠️ Standing notes

### Running on a small screen
- One AVD (`Medium_Phone_API_36.1`, 411dp). Drive it to other widths rather than making new
  ones: `adb shell wm size 840x1867` + `wm density 420` = **exactly 320.0dp** (840 ÷ 2.625);
  `945x2100` = 360dp; `984x2187` = 375dp; `adb shell wm size reset` + `wm density reset`
  restores it. 320 is a **logical** width — the physical panel is 840px.
- **Check the emulator's clock before suspecting auth.** Twice now, clock skew on this
  machine has masqueraded as a credentials failure. `adb shell settings put global auto_time 1`.
- **Do not swipe vertically over the home screen to scroll** — it catches the swipe-to-talk
  control and starts a real, billable call.
- **A `flutter run` can clear app storage and sign you out.** It did once on 08-12 and not on
  the four rebuilds either side. Recovery is three taps: the QA Google account is on the
  emulator, so **Have an account? → Continue with Google → p.pavle16**.
- **Driving the call screen by `adb`:** "Mark as done" only registers on the circle itself
  (≈`686 1537` at 320dp), and it opens a "Wrap up already?" dialog whose "Yes, I'm done" sits
  at ≈`409 1207`. Snackbars live ~1s before the screen navigates — capture them with a burst
  of `screencap`, not one delayed shot.
- Install without a full rebuild: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`.

### Deploy / backend
- **Compose service on the box is `backend`, not `web`.** `exec web …` answers "service is
  not running" and reads like an outage.
- **`-f docker-compose.prod.yml` is required** on the box — a bare `docker compose build` in
  `~/backend` fails with "no configuration file provided".
- Env changes take effect on container **create**, not restart — always `up -d`.
- **Production logs 500s now.** `docker logs nowlii-backend` holds tracebacks.
- **HTTPS is live**: `https://api.nowlii.com`, `https://ai.nowlii.com`. Cert to 2026-10-29.
- As of 2026-08-12 the deployed backend is **byte-identical to committed `HEAD`** — there is
  nothing waiting to deploy.

### Accounts, money, data
- **Both QA allowlists are EMPTY on production** (`SUBSCRIPTION_UNLIMITED_USERS`,
  `VOICE_CALL_UNLIMITED_USERS`). Real calls cost ~$0.25 and the daily limit is 2.
  **To grant unlimited again, set both to `p.pavle16` and `up -d` — do NOT "restore" them by
  deleting the lines.** `settings.py` defaults both to `"pavle"`, a username dead since the
  account was recreated on 08-06, so deleting the lines yields an allowlist matching nobody.
  They match on **username**. Backups: `.env.bak-20260812-before-allowlist-restore` (empty
  state), `.env.bak-20260812-before-allowlist-remove` (granted state).
- **The QA account** is `p.pavle16@gmail.com` = prod user **id 51**, username `p.pavle16`.
  Its trial had **1 day left on 08-12**, so it meets the paywall around 08-13.
- **Existing scheduled calls keep their old (wrong) instants** until their quest is saved
  again or their phone reports a timezone.

### Code
- `flutter` is not on PATH in tool shells — use `C:\src\flutter\bin\flutter.bat`.
- **`flutter analyze lib` has a standing baseline of 10 warnings.** Diff against it rather
  than reading the count. 0 errors. **262 tests** pass.
- **Never key companion art off `predefined_option`.** Production ids are `2, 3, 4, 6, 10,
  12`; the id says nothing about which character a row is. Resolution order is the
  `avatar_logo` filename → preset `nowlii_name` → id. Never the displayed name, which the
  user can change. **Do not rename the S3 files** until the backend has a stable `slug`.
- Backend tests: use module labels (`Apps.users.tests`). A bare `manage.py test` **errors**.
- **`AUTH_USER_MODEL` is never set** — production runs Django's stock `auth.User`.
- The emulator cannot route host audio, so the mic, the voice check and the AI call cannot be
  judged there. Those need a phone.
- **Figma MCP hits a per-seat call limit.** ~45 calls on 08-12 without hitting it. A page root
  (`node-id=0-1`) returns "nothing selected" and its metadata can exceed the token limit —
  drill into a named frame instead.
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
