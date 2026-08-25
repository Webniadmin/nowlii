# Daily Checklist

_The single active document for the current working day. Update **only this file**
during the day. At end of day, write a report in `daily-reports/` and reset this list
for tomorrow. Deferred items go to `future-checklist.md`._

**Day:** 2026-08-26 (Wednesday)
**Branch:** `fix/call-mic-permission-and-close-button` — six commits `3f77fbf` → `086f5e9`,
**not pushed to `origin`**.
**Yesterday's report:** `daily-reports/2026-08-25.md` — notifications proved on hardware, the
streak fix, the shared calendar, and four passes over the app.

---

## ▶ START HERE

1. **Empty both QA allowlists.** They are still active on production — the home screen says
   "Unlimited sparks", so nothing caps the OpenAI spend and the QA account meets neither the
   paywall nor the 2-calls-a-day limit. See **Accounts** below for how, and for the trap in
   "restoring" them by deleting the lines.
2. **Decide where `sync()` goes after login.** `sign_in_screen.dart:157` and `:193` go straight
   to the home screen. Nothing on that path asks for the notification permission or reports the
   device timezone, so a user who signs in and never creates a quest gets **no alarms at all**
   and never sees a dialog. `DeviceTimezone.report()` rides the same chain, so a phone in a new
   zone does not report it until the next cold start — that one only affects `ScheduledCall`,
   since quest alarms are local. Full write-up in yesterday's report §9.
3. **Decide what to do with the notification settings screen.** All five toggles are dead: they
   write to SharedPreferences and nothing reads them. Three of the five categories have no
   sender anywhere in the app. Wire the two that map to something real ("Task Reminders",
   "Streak Progress") and drop the rest, or take the promises off the screen.
4. **Decide about the in-app notification feed on the profile.** Permanently empty; the
   design's populated list was never built. Build it, or take the section out.
5. **Push, and decide whether this branch merges to `main`.** Six commits are sitting local.

---

## ✅ Done 2026-08-25 — see the report for the reasoning

- **Notifications and the timezone are proved on a device.** A 12:30 quest rang at
  12:30:00.026, as an exact `RTC_WAKEUP`, at the epoch that is 12:30 **in the device's zone**.
- **Quest alarms arrive 5 minutes early** (`questAlarmLeadMinutes`), with the copy reading the
  quest's clock rather than the reminder's, and a quest made inside its own lead window still
  warning instead of falling silent.
- **The streak can lapse again.** It never compared to today, so a run from January still read
  2 in August. Now anchored to today-or-yesterday, on the user's calendar, ignoring future
  dates. **First backend tests ever** — 11 cases.
- **Activity trend has a real axis.** `maxY` was hardcoded to 20, so every bar drew at a
  twentieth of its height and the chart looked empty.
- **One calendar, shared.** `widget/quest_calendar.dart` — Insights draws a month of it, My
  Progress a week. The old week strip had no "skipped" state, so a missed day and a future day
  looked identical. (That is the "all seven circles ticked" note that sat here unexplained.)
- **The quest card opens the quest; the checkbox completes it.** Edit pencil retired.
- **Suggested cards** read at last — most were navy on navy, because `moon4` is the fallback
  for every unmatched task. Plus 5 mins, no Shuffle, smaller moon.
- **Empty states centre properly** on Scheduled, Completed and Blocking — fixed in `today.dart`
  on 08-14 and nowhere else.
- **Profile** matches the design; the Edit icon was `Image.asset(color:)` flattening a plate to
  a white disc. **"Talk to Fuzzy"** was the tenth place using a name the user never chose.
- **Receipts** have a back button and swipe-to-delete, on a new
  `DELETE /api/voice-calls/<id>/summary/`.
- **Backend deployed** and verified inside the running container. `nowli-ai` untouched on
  purpose.

## 🔎 Open from yesterday, not acted on

- **The time picker overflows by 4.3 px** on the AM/PM column at 375dp — visible as the striped
  overflow banner on create-quest.
- **The "10 mins" pill was invented** and is now gone from the user's quest cards. If quests
  should carry a duration, it needs a real field; nothing ever asked the user for one.
- **`completed/task_card/task_card.dart` is dead mock code** — a hardcoded "Clean house" list,
  referenced from nowhere. Left in place.
- **`SleepRoutineCard` is a byte-identical unused duplicate** of `RoutineCard` in
  `soft_steps.dart`.
- **Create-quest asks for the nearby-devices (Bluetooth) permission** — almost certainly a
  plugin pulling in `BLUETOOTH_CONNECT` for headsets. Play wants a justification, and the
  wording is alarming on a screen where someone writes down a task.
- **The receipts screen has not been seen on a device.** The QA account has no saved summary,
  and making one costs a billable call.

---

## ▶ The phone test — still open

Yesterday's work was all emulator. The emulator routes no audio, so the microphone, the voice
check and the AI call still cannot be judged here. **The archived APK predates everything** —
build a fresh one:
`flutter build apk --debug --dart-define-from-file=dart_defines.prod.json`.

- [ ] Install and sign in as a real user — and watch whether the notification dialog appears
      before the first quest is created (it should not today; that is item 2 above)
- [ ] **The male voice** — still the one open question from 08-21, still needs two log lines:
      `Companion voice from profile:` and `Realtime voice for this call:` (`cedar` male,
      `marin` female)
- [ ] Microphone, voice check, one AI call. ⚠️ **Calls are free and unlimited on the QA
      account right now** — empty the allowlists first or accept the spend
- [ ] A quest with a time should ring **5 minutes before** it, with the quest's own time in the
      body. ⚠️ An account that has already denied twice will never see the dialog again;
      grant it in system settings or use a fresh install
- [ ] **Second phone still to retry** — `kekile49@gmail.com`, untested since the 08-06 fix
- [ ] The last of the 320dp sweep: the call and voice-check screens

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
- [ ] ⚠️ **The dev machine ran out of disk on 08-14** and stopped the test suite dead:
      `flutter test` failed with `errno = 112, there is not enough space on the disk`, at
      **87 MB free**. Recovered to 8.8 GB by deleting `nowli-frontend-app/build/` (5.1 GB,
      regenerable — `flutter clean` does the same job) and three stale
      `%TEMP%\flutter_tools.*` folders. The hand-named APKs that lived inside `build/` were
      **moved, not deleted**, to `Just Web (projekti)/nowlii-apk-archive/`:
      `nowlii-prod-v0.1.apk`, `nowlii-https.v0.2.apk`, `nowlii-prod.v0.1.apk`.
      **This is a reprieve, not a fix** — the disk is still about 98% full and each debug
      APK is ~180 MB, so expect it again within a few builds. Needs real space freed.

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
- **As of 2026-08-21 both services on the box run commit `7377ae8`** (backend and `nowli-ai`,
  rebuilt and restarted that afternoon). Nothing server-side is waiting to deploy. The
  **Flutter** tree is a different story — see the top of this file.
- `git archive` ships **committed** files only. A deploy of uncommitted work silently ships
  the old code and looks like it worked.

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

- ⚠️ **`LayoutBuilder` under `IntrinsicHeight`/`IntrinsicWidth` paints nothing, silently.**
  A LayoutBuilder cannot answer an intrinsic-size query, so the parent measures the subtree
  as zero and the whole thing disappears — **with no exception in the log**. This bit twice
  on 2026-08-14: the fourth tutorial bubble (an `AutoShrinkText`, which is a LayoutBuilder,
  inside an `IntrinsicWidth`) drew nothing and read as the app hanging; and the **entire AI
  call screen** went blank, because its column lives inside an `IntrinsicHeight` and the
  pulse fix had put a LayoutBuilder in it. Both are fixed. Before reaching for a
  LayoutBuilder, check what is above it — on the call screen, `MediaQuery` size was all it
  needed. `AutoShrinkText`'s doc comment carries the same warning.
- ⚠️ **A popped dialog's `BuildContext` is dead, and `context.mounted` hides it.** Anything
  of the shape "pop the dialog, `await` some work, then navigate or show a snackbar with that
  same `context`" silently does nothing: the pop unmounts the element when the exit animation
  ends (~150ms), well inside any network call, so the `context.mounted` guard is false by the
  time it is read and the method returns through its correct-looking early exit. **No
  exception, nothing in the log.** It cost Log out its navigation and Delete My Account its
  spinner (2026-08-15). Capture `GoRouter.of(context)`, `Navigator.of(context)` and
  `ScaffoldMessenger.of(context)` **before** the pop — all three live above the dialog and
  outlive it. The `use_build_context_synchronously` lint does flag this, but it is `info`
  severity and drowns in the ~400 the project already carries.
  **Testing it needs care:** ordering inverts in a widget test — a mocked store resolves in
  one microtask, so the dialog is still mounted and the broken code passes. Hold the work open
  with a `Completer` until the dialog has pumped out. And `pumpAndSettle` never returns while a
  `CircularProgressIndicator` is on screen; use explicit `pump(Duration)`.
- ⚠️ **Do not `await` `CallReminderService` on a path the user is leaving through.** Its
  `init()` awaits two platform channels (`FlutterTimezone`, then the notifications plugin);
  either one hanging strands the user. In `delete_account_dialog` the cancel is fired and not
  awaited for exactly this reason.
- `flutter` is not on PATH in tool shells — use `C:\src\flutter\bin\flutter.bat`.
- ⚠️ **`Image.asset(..., color:)` flattens every pixel to one value.** It is a tint, not a
  fill, so art that is already a coloured *plate* becomes a solid block of that colour. The
  profile's Edit row passed `Colors.white` over `Edit profilIcon.png` — a blue plate with a
  navy pencil — and rendered a plain white disc with no pencil in it, for weeks. If a row
  needs its own colour, pass a widget rather than a path plus a tint.
- ⚠️ **Key a `Dismissible` by the item's id, never its list position.** The key survives
  rebuilds, so an index key makes the *next* row inherit the dismissed one's state and vanish
  with it.
- ⚠️ **Dart has no nested block comments.** Retiring a method by wrapping it in `/* */`
  breaks silently if the region already contains one — the first inner `*/` ends the outer
  comment and everything after it lands back in the parse. It happened once on 08-25 and
  produced a cascade of `undefined_identifier` errors pointing nowhere near the cause.
- **Splitting a mixed working tree:** `git add -p` is not available here, so a file carrying
  two days' changes cannot be split. Assign the whole file to one commit and say so in the
  message. File mtime is a reliable way to tell which day's work a file belongs to.
- **`flutter analyze lib` has a standing baseline of 10 warnings.** Diff against it rather
  than reading the count. 0 errors. **297 tests** pass (2026-08-25).
- **The backend has tests now, but only one app's.** `Apps/quests/tests.py` covers the streak
  rule (11 cases, added 2026-08-25) and is the only suite that exists. Everything else is
  still covered by reading and `manage.py check` alone — say so rather than implying a
  green run across the backend.
- **Never key companion art off `predefined_option`.** Production ids are `2, 3, 4, 6, 10,
  12`; the id says nothing about which character a row is. Resolution order is the
  `avatar_logo` filename → preset `nowlii_name` → id. Never the displayed name, which the
  user can change. **Do not rename the S3 files** until the backend has a stable `slug`.
- Backend tests: use **module** labels (`Apps.quests.tests`). A bare `manage.py test` errors,
  and so does an app label — `manage.py test Apps.quests` dies in unittest discovery with
  `TypeError: _path_normpath`, because `Apps/` has no `__init__.py`. CLAUDE.md still quotes
  the broken form.
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
