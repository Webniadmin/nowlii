# Daily Checklist

_The single active document for the current working day. Update **only this file**
during the day. At end of day, write a report in `daily-reports/` and reset this list
for tomorrow. Deferred items go to `future-checklist.md`._

**Day:** 2026-07-30

---

## ✅ Done 2026-07-29 (full detail in `next-phase.md` RESUME HERE blocks)

- **Deployed the whole `feat/realtime-voice-call` branch to EC2** — the box had been running
  07-21 backend + 07-23 nowli-ai, so everything from 07-28/29 was local only. 4 migrations applied
  to prod RDS; voice gender + neutral persona live.
- **Insights no longer 500s when the AI is down** — degrades per-block to data-derived fallback
  copy and returns 200 with an `ai_degraded` flag. Added a 20 s provider timeout (the SDKs default
  to 600 s, so a hang would have left the app spinning instead of falling back).
- **7-day free trial + real paywall, end to end** — previously the button was an empty
  `onPressed`, the backend had no trial concept, and `user_has_pro()` was never called, so
  everyone had the whole app free forever. Now: trial auto-granted on first login, 402
  `subscription_required` on all feature endpoints when it runs out, purchase restores access.
- **Pro screen pricing conflict resolved** — removed the hardcoded Yearly $25.99 cards (no such
  product exists in the backend; the selection was ignored anyway). One plan, real prices, with
  the "How billing works" explainer now on both paywall screens.
- **Second deploy** — the trial/paywall shipped to EC2 (`subscriptions.0002`), verified on prod
  inside a rolled-back transaction. New debug APK built against AWS.

---

## ✅ Done 2026-07-30 — production hardening pass

Goal for the day was "make it production ready". It is not, and the reason is now precisely
known — see the blocker at the bottom. What did land:

- **Django `SECRET_KEY` can no longer be weak in production.** `settings.py` refuses to boot when
  `DEBUG=False` and the key is the shipped default, `django-insecure-`-prefixed, under 50 chars or
  under 5 distinct characters (Django's own `W009` thresholds). The local `.env` key fails all of
  this today, and so does the box's.
- **HTTPS switches added, all defaulting OFF** (`BEHIND_TLS_PROXY`, `SECURE_SSL_REDIRECT`,
  `SESSION/CSRF_COOKIE_SECURE`, HSTS). Deliberately off: prod is plain HTTP, and enabling
  secure-only cookies without TLS silently locks everyone out of the Django admin.
  `SECURE_PROXY_SSL_HEADER` was being trusted unconditionally — now only behind a real proxy.
  Always-on now: `X_FRAME_OPTIONS=DENY`, nosniff, referrer policy, HttpOnly session cookie.
- **Fixed an open door: the companion catalogue was anonymously writable.**
  `NowliiPredefinedOptionViewSet` was `AllowAny` on a full `ModelViewSet` — anyone on the internet
  could POST/PATCH/**DELETE** every avatar. Now public to read (onboarding needs it pre-login),
  admin-only to write. 8 regression tests; verified they fail 4/8 against the old code.
- **DRF now fails closed** — default permission `AllowAny` → `IsAuthenticated`. Audited first: every
  existing view already declares its own, so nothing changed behaviourally. It only catches views
  added later that forget.
- **`nowli-ai` is no longer an open door to the OpenAI bill.** `/api/v1/` now requires the caller's
  Django access token, verified locally against the same HS256 secret (no extra network hop, no
  second credential to embed in the APK). `/` and `/health` stay public; `/health` reports
  `auth_required` so a deploy can be checked without a token. 10 checks in the repo's first-ever
  `nowli-ai` test (`test_auth_middleware.py`). Flutter sends the header on all 4 AI endpoints.
- **Stopped leaking JWTs into logcat** — `storage.dart`, `api_service.dart` and `profile_service.dart`
  printed full access/refresh tokens. `print` reaches logcat in release builds too.
- **Android release signing wired** — `key.properties` (git-ignored) + `.example`; falls back to the
  debug keystore when absent so local `--release` still works. `*.jks`/`*.keystore` now git-ignored.
- **`.env.example` for both services** — neither had one; the new required vars are documented there.

**Verified:** `manage.py check --deploy` clean apart from the 4 expected HTTPS warnings (and clean
with the HTTPS block on); 54 backend tests pass (44 existing + 10 new); 10/10 nowli-ai auth checks;
`flutter analyze` 0 errors; first-ever release APK builds (111 MB, R8 minification works).

- **Prod secrets rotated and staged on EC2.** `SECRET_KEY` (backend) and `NOWLII_JWT_SECRET`
  (nowli-ai) generated **on the box** and written, byte-identical, with backups
  (`*.env.bak-20260730-prehardening`). The old prod key was 66 chars but `django-insecure-`
  prefixed — it would have crash-looped the container under the new guard. **Containers were
  deliberately not restarted**, so production is untouched and still healthy (verified: backend
  401 on a protected route, nowli-ai `/health` ok). The same was done for the local `.env` pair
  with a *different* value, and the wiring was proved end to end: a JWT minted by Django with the
  local key is accepted by nowli-ai (401 without it, 200 with it).

**Code not deployed.** ⚠️ Read the box at the top of `deploy-aws.md` before deploying — the
secrets are already in place, but two ordering consequences now apply: the first backend
`up -d` logs every user out, and deploying `nowli-ai` without shipping a fresh APK at the same
time breaks voice calls on the old build (no `Authorization` header → 401).

## ✅ Done 2026-07-30 (afternoon) — three client requests

1. **Nowlii warns before the call runs out** — the "Add 2.5 minutes" card used to appear
   silently at 60 s left. Nowlii now says it out loud 10 s *before* that card appears, and
   is kept genuinely time-aware (a silent system item once a minute) so it can answer "how
   long do we have?" truthfully. Wording adapts once the extension is spent; extending
   re-arms the warning for the real end. `CallTimeAnnouncer`, 10 tests.
2. **Screen no longer sleeps mid-call** — the wakelock existed but was set once in
   `initState` and never checked. `FLAG_KEEP_SCREEN_ON` belongs to the window, so it was
   lost every time the app left the foreground. Now re-asserted on resume and verified
   after enabling, with one retry.
3. **Scheduled AI calls** (the big one) — turning on a quest's **Enable call** now schedules
   the call at the quest's time, with a local notification 5 minutes before that opens the
   call when tapped. Backend `ScheduledCall` + a `post_save` signal on `Quests` (so "Repeat
   quest" gets 7 reminders for free) + `GET/PATCH /api/voice-calls/scheduled/`.

   **The daily limit is fully wired in, without reserving anything.** Schedule three calls
   and the third gets the usual 429. Spend the day's last call by swiping on home and a
   later scheduled call goes `locked` — so the app **warns before that swipe** ("you have a
   call at 17:00; this is your last one today") and offers **Move to tomorrow** afterwards,
   on the quest card and in the notification itself. Reminders are re-laid after every call,
   which is what keeps that wording honest: a call can only be spent with the app open.

   Two things worth knowing: `flutter_local_notifications` needs **core library desugaring**
   (added to `build.gradle.kts`; the build fails outright without it), and we deliberately do
   **not** declare `USE_EXACT_ALARM` — Play restricts it to alarm/calendar apps, so we
   request `SCHEDULE_EXACT_ALARM` and degrade to inexact scheduling if refused.

   Also replaced `test/widget_test.dart`: it was the untouched Flutter counter template from
   the initial commit, asserting a UI this app never had, so `flutter test` had been red
   since day one.

**Verified:** 81 backend tests (27 new in `voice_calls`, which had none) + 31 Flutter tests,
all pass; `flutter analyze` 0 errors; debug APK builds. **Not tested on a device** — the
notification path (lock screen, cold start, reboot, exact-alarm denied) can only be proven
there.

## 🔲 Today — on-phone verification (the whole point of the new APK)

Install `build/app/outputs/flutter-apk/app-debug.apk`. **Use a NEW account** — `pavle` is on the
paywall allowlist and staff are exempt, so neither will ever see the trial or the block.

### The new money flow (highest priority — never tested on a device)
- [ ] Fresh signup → land in the app with full access; the **"7 days free" screen shows once**.
- [ ] Settings → subscription screen shows **7 days left** and the real price boxes
      (19.99 → 14.99 → 9.99 → 4.99 → free after month 12).
- [ ] Profile menu → **Nowlii Pro** shows one plan (not Monthly/Yearly) + the billing explainer.
- [ ] "Subscribe" → SnackBar confirms month 1 / $19.99, and the app stays usable.
      _(Mock payment — no money moves. See the blocker below.)_
- [ ] **Force the paywall:** in Django admin set that user's `trial_started_at` back 8 days
      (Subscriptions → their row), restart the app → it must land on the Pro screen and refuse
      to navigate anywhere except Pro / subscription / settings / support.
- [ ] From the paywall, "Subscribe" → app opens again.

### Carried over from the 07-29 deploy (still unverified on a device)
- [ ] **Voice**: male vs female matches the chosen avatar; persona doesn't interrogate the mood.
- [ ] Screen stays awake through a long call; summary saves → appears in **Call History**.
- [ ] **Insights**: productive **hour** shows a real value; "Yes, it's my rest day" drops that day
      out of "skipped" and un-reds its calendar cell.

### Scheduled calls — device checks (new, 2026-07-30)
- [ ] Create a quest ~6 min out with **Enable call** → reminder arrives 5 min before.
- [ ] Tap it from a **locked phone**, and again from a **cold start** → lands on the call.
- [ ] Burn both calls, then let a scheduled one come due → the notification says "no calls
      left" and offers tomorrow; the Today card shows **locked** + **Move to tomorrow**.
- [ ] With 1 call left and one scheduled later, swipe on home → the warning appears first.
- [ ] Deny exact-alarm access → the reminder still arrives (a little late), no crash.
- [ ] Reboot the phone with a reminder pending → it survives.

### Then
- [ ] Merge `feat/realtime-voice-call` → `main` (it is 10 commits ahead; a deploy from `main`
      today would be a regression).

## ⚠️ Blockers / decisions needed

- **🚧 NO DOMAIN = NO RELEASE. The ordered path to production is now known.**
  A release APK **cannot reach the backend at all** — Android blocks cleartext HTTP since API 28
  and `usesCleartextTraffic` is debug-only, so every request in a release build fails. Play also
  rejects cleartext credential traffic, so widening the manifest is not an escape. Everything
  else is downstream of this:
  1. **Buy a domain** → Nginx + Let's Encrypt on EC2 in front of :8000 and :8001 → switch
     `dart_defines.prod.json` to `https://` → flip the HTTPS block in `~/backend/.env`.
  2. **Then** the release keystore + a signed build that actually works.
  3. **Then** real IAP — it can only be tested through a signed build on an internal testing track.
  Device testing meanwhile is unaffected: the **debug** APK still allows cleartext.
- **No real money yet.** `activate` is a mock and `verify-receipt` is a 501 stub — anyone can
  "subscribe" for free. Phase 2 (Apple IAP / Google Play Billing) is the next subscriptions task.
  Store accounts exist (both), so the missing pieces are the per-phase products in App Store
  Connect / Play Console and a Play Developer API service account.
- **Scheduled AI calls — waiting on the client.** Confirmed today that nothing exists: no
  notification/scheduling package, no backend reminder model, and `set_alarm` is stored but drives
  nothing (it's even hardcoded `true` on create). "Enable call" only shows an on-demand button.
- **Two voice questions still open** — do existing users get backfilled to their avatar's voice?
  Do `bloop/fizzy/zee/cloudy/glowy` match the intended female art?
- **Local `.env` OpenAI key is invalid** (401 "Incorrect API key") — stale since the 07-23
  rotation. Prod is fine. Only affects local AI testing.
- **Set a hard OpenAI budget cap** (still open from the 07-23 key leak).

## 📝 Notes

- **Paywall escape hatches** if it misbehaves on the device: set `SUBSCRIPTION_ENFORCED=False` in
  `~/backend/.env` on EC2 and restart, or add the account to `SUBSCRIPTION_UNLIMITED_USERS`.
- Rollback images on the box: `:backup-20260729b` (pre-paywall), `:backup-20260729` (pre-branch).
  **Images roll back; migrations do not.**
- `flutter` is not on PATH in tool shells — use `C:\src\flutter\bin\flutter.bat`.
- Longer-term backlog in `future-checklist.md`.
