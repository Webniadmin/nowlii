# Daily Checklist

_The single active document for the current working day. Update **only this file**
during the day. At end of day, write a report in `daily-reports/` and reset this list
for tomorrow. Deferred items go to `future-checklist.md`._

**Day:** 2026-08-14
**Branch:** `feat/design-implementation` — merged to `main` today at the user's decision,
ahead of the phone test (see the note under the phone test below)
**Last working day:** `daily-reports/2026-08-12.md` — the pose art landed, and the mapping
under every avatar turned out to have been wrong for five of the six companions.
**2026-08-13 produced no commits and no report.**

## ✅ Done today (2026-08-14)

- **The 320dp sweep is finished except the call screens.** Settings and every screen under
  it driven at 320.0dp, and onboarding covered by a new `test/small_screen_layout_test.dart`
  instead — it runs once, on a brand-new account, so a device cannot get back to it.
  Three defects fixed: the **Clear All AI Memory** sheet drew its buttons half-cut (no
  `isScrollControlled`, so the sheet was capped at 9/16 of the screen and clipped in
  silence), and the **Update** button on both the rename screen and the companion picker
  ran edge to edge from a hardcoded `width: 335`.
- **All six companions checked by eye**, switching the account through each and watching
  the home card. Every one showed the right character on the hero card *and* in the reading
  pose on the quest card — including id 3, whose Figma columns are swapped, and the 4/10 and
  6/12 pairs that used to collapse. Account restored to Zee afterwards.
- **Reminders no longer degrade to inexact alarms after a restart** — `sync()` re-reads the
  permission instead of trusting a flag only the create-quest screen ever set.
- **"Nowlli" → "Nowlii"** in 24 user-facing strings across eight screens. The product's own
  name was misspelled in Notifications, both AI-personalization sheets, the delete-account
  warning and the cancel-plan flow.
- Verified: `flutter analyze lib` → 0 errors, **10 warnings, the standing baseline**;
  **268 tests pass**, up from 262.

## ⚠️ Corrections to what this file used to say

- **The emulator is signed in as `pavlegdn`, not `p.pavle16`.** That is why the entitlement
  allowlist appeared not to work: the home card read "Unlimited sparks" (the voice allowlist
  matched) while **Add quest went straight to the paywall**. Unblocked by subscribing through
  the paywall — `activate` is still a mock, so it cost nothing — at the user's choice.
  **`p.pavle16` has not been checked today**, so whether the allowlists reach it is unknown.
- **The `editFrom` "doesn't send `predefined_option`" bug is fixed** and has been for a
  while; the warning in this file was stale. It sends the id, and switching companions
  persists — verified six times over today.
- **`/avatarLogo`, the "main avatar picker", is routed from onboarding only.** So the pencil
  on Edit Profile → rename screen → its own pencil is not the path to avoid, it is the only
  path there is after signup.

## 🔎 Found today, not yet acted on

- **Create-quest asks for the nearby-devices (Bluetooth) permission** — "find, connect to,
  and determine the relative position of nearby devices", on the screen where someone writes
  down a task. Almost certainly a plugin pulling in `BLUETOOTH_CONNECT` for headsets. Play
  wants a justification for it, and the wording is alarming in that context.
- **The profile picture slot draws a washed-out, oversized logo** rather than a photo or a
  clean placeholder, on both Profile and Edit Profile.
- **Progress shows all seven weekday circles ticked** under "0-Day Streak" and "0 / 3 days".
  Unverified — it may be the unfilled state, but ticked-and-orange reads as done.

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
- [ ] Microphone, voice check, one AI call. **Calls are free and unlimited on the QA account
      right now** — the allowlists were restored at the end of 08-12 so the expiring trial
      would not block this. That also means nothing caps the OpenAI spend, so **empty them
      again as soon as the test is done** (see Accounts below).
- [ ] **Second phone still to retry** — `kekile49@gmail.com` failed all of 08-06 afternoon
      and has not tried since the fix went out at ~18:26
- [x] ~~Merge → `main` once it passes.~~ **Merged 08-14, before the phone test**, at the
      user's explicit decision after the ordering was pointed out. So `main` now carries work
      that no hardware has seen — the phone test still has to happen, and anything it finds
      lands on `main` rather than on a branch.

While the call is open, three things fixed yesterday are worth a glance on real hardware,
since the emulator's silence made every summary a degenerate one:
the **mood face** (should follow what the summary actually says), the **"Save reflection"**
wording, and the **call screen pulse**.

---

## 🔲 Then, in rough order of value

- [x] ~~See the other five companions on a screen.~~ Done 08-14, all six.
- [x] ~~Reminders drop to inexact alarms after every restart.~~ Fixed 08-14.
- [ ] **The last of the 320dp sweep: the call and voice-check screens.** Everything else is
      done. These two cannot be judged here — swiping to talk starts a real, billable call,
      and the emulator routes no audio anyway — so they belong to the phone test. Candidates
      from a static read: `popup_speaking` / `popup_your_share_you` (`width: 335`),
      `popup_error` / `popup_processing` (`324.39`).
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
- ⚠️ **Both QA allowlists are ACTIVE on production** — both set to `p.pavle16`, restored at
  the end of 08-12 so the phone test is not blocked when the trial expires. That account
  therefore has **unlimited entitlement and unlimited voice calls**, so it will neither meet
  the paywall nor stop at 2 calls a day, and **every call still bills OpenAI** — the limit
  that used to cap the spend is gone. **Empty them again the moment the phone test is done.**
- **To empty:** set both to blank in `~/backend/.env` and `up -d`. **Do NOT "restore" them by
  deleting the lines** — `settings.py` defaults both to `"pavle"`, a username dead since the
  account was recreated on 08-06, so deleting them yields an allowlist matching nobody. They
  match on **username**. Backups on the box: `.env.bak-20260812-before-allowlist-restore`
  and `.env.bak-20260812-eod-before-restore` are both the *empty* state.
- Off the allowlist, real calls cost ~$0.25 each and the daily limit is 2.
- **The QA account** is `p.pavle16@gmail.com` = prod user **id 51**, username `p.pavle16`.
  Its trial had **1 day left on 08-12**, so it meets the paywall around 08-13.
- ⚠️ **The emulator is not signed in as that account.** On 08-14 it was `pavlegdn`, whose
  entitlement had lapsed — the paywall on every write — while its sparks were unlimited, so
  only one of the two allowlists was reaching it. It was put on a plan through the paywall
  (free; `activate` is still a mock), so **that account now carries a real Subscription row
  on production** — worth remembering the next time someone wants to test the lapsed state.
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
