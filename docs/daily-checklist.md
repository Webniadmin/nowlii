# Daily Checklist

_The single active document for the current working day. Update **only this file**
during the day. At end of day, write a report in `daily-reports/` and reset this list
for tomorrow. Deferred items go to `future-checklist.md`._

**Day:** 2026-09-23 (Wednesday).
**Branch:** `main`. `feat/stripe-payments` was merged in and pushed to `origin` on 2026-09-22.
**Last report:** `daily-reports/2026-09-22.md` (it also covers 09-16 and 09-21). The
checklist as it stood before this reset, with all its older history, is in
`daily-reports/checklist-archive-2026-09-22.md`.
**Production backend:** `7e39249` (rollback `:backup-20260922`). `nowli-ai` unchanged.

**Goal:** Google Play **closed testing**. The app is not live. Stripe stays in **TEST** mode
until testing passes; that is the user's decision.

---

## ▶ 1. Play Console + Google Cloud (the user does these, then tells Claude)

**The AAB:** `C:\Users\Pavle\Desktop\nowlii-1.0.0-2.aab`, version 1.0.0 / versionCode **2**
(code 1 was already used in Play). Every later upload needs a higher `+N` in `pubspec.yaml`.

- [ ] **Closed testing → Create release**: upload the AAB, then **save. Do NOT roll out.**
- [ ] **App content → Data safety → Data deletion**: "Delete account URL" =
      `https://api.nowlii.com/delete-account/`
- [ ] **App content → App access**: review login `appreview@nowlii.com` /
      (password: in the user's password manager / Claude memory `apple-reviewer-account` — never in the repo) (prod user 61, lifetime free, unlimited calls; email+password,
      not the Google/Apple button). Use the same login for App Store review.
- [ ] **App integrity → App signing**: copy the **App signing key SHA-1**. Then in Google
      Cloud project **274971792537** → Credentials, create **two Android OAuth clients** for
      `com.nowlii.app`: one with that Play SHA-1, one with the upload SHA-1
      `0F:8E:28:9D:07:96:7C:0A:65:95:86:62:04:7F:26:E7:8D:84:46:F6`. Leave the debug client
      alone. Without this, "Continue with Google" fails on Play installs (`ApiException: 10`).
      No rebuild needed.
- [ ] Install from Play as a tester and **test Google login**. Only after it works: add
      testers → **Start rollout**. (The user does not want testers on a build where Google
      login fails.)

## ▶ 2. Claude, meanwhile: close the OTP brute-force hole (P1)

- [ ] The password-reset and signup OTPs have **no attempt limit** and are generated with
      `random`, not `secrets`. Someone can guess a reset code and take over the account.
      Copy the `AccountDeletionRequest` pattern: `secrets`, HMAC-stored, single use, 5
      attempts, resend cooldown, same answer for unknown addresses. Add tests, then deploy
      (the user's message has to say "deploy to production").

## ▶ 3. Small ones, any order

- [ ] **Back up** `C:\Users\Pavle\nowlii-upload-keystore.jks` and
      `nowli-frontend-app/android/key.properties` **off this machine**. Losing them blocks
      every future app update.
- [ ] **RDS:** the deletion page says backups roll off "within 35 days". Check the AWS
      console for **manual** snapshots, or change that sentence in
      `Apps/users/templates/users/delete_account.html`.
- [ ] `READ_MEDIA_IMAGES` may trip Play's photo-permission policy. Consider the system
      photo picker instead.
- [ ] Release builds log URLs and response bodies (`🌐 URL`, `📥 Response Body`). Silence
      them before the public launch.

---

## ⛔ Before the public launch (not blocking closed testing)

- **Stripe live:** `sk_live_`, run `sync_stripe_prices --create` again (live ids differ),
  create a live webhook and its `whsec`, then `up -d`.
- **Terms of Service** and a refund policy. The P0 items are in `future-checklist.md`.
- **Trial-ending reminders** (day 5 / day 6) are still promised and never sent.
- Apple "Hide My Email" users can't receive the deletion code unless our sender is
  registered in Apple's Private Email Relay. The page sends them to in-app deletion or
  hello@nowlii.com.
- **The welcome screen still shows the blue mark**, baked into
  `assets/svg_images/enttry_two_screnn.png`. It needs a re-export from Figma.

---

## ⚠️ Standing notes

- **Local `nowli-backend/.env` points at prod RDS.** Always run locally with
  `DB_ENGINE=django.db.backends.sqlite3 DB_NAME=db.sqlite3`.
- **Both unlimited allowlists are ACTIVE on prod** (read back 2026-09-22):
  `SUBSCRIPTION_UNLIMITED_USERS=p.pavle16,appreview@nowlii.com`,
  `VOICE_CALL_UNLIMITED_USERS=p.pavle16,Dea,marija,marija912marija@gmail.com,appreview@nowlii.com`.
  Every call on those accounts still bills OpenAI. **Do not "empty" them by deleting the
  lines**: `settings.py` defaults them to `"pavle"`. Set them to blank instead.
- **Deploy:** `git archive | ssh tar -x` → `docker compose -f docker-compose.prod.yml build`
  → `up -d` (the service is `backend`, not `web`). Only **committed** files ship. Env
  changes need `up -d`, not a restart. The auto-mode classifier may refuse the prod
  `build`/`up -d` until the user explicitly says "deploy to production". The source is
  already on the box by then, so that is a safe place to pause. Full runbook:
  `docs/deploy-aws.md`.
- **Release build:** `C:\src\flutter\bin\flutter.bat build appbundle --release
  --dart-define-from-file=dart_defines.prod.json` (run from `nowli-frontend-app/`). Bump
  `version:` first. Verify the signature with Android Studio's
  `jbr/bin/keytool -printcert -jarfile <aab>`.
- **Backend tests:** module labels only (`manage.py test Apps.users.tests`). A bare
  `manage.py test` and app labels both error. **248 pass** (2026-09-22, all seven modules).
- **Frontend:** `flutter analyze lib` baseline is 0 errors / 10 warnings; **297 tests**
  (last run 2026-09-07).
- **Dev machine clock drifts** about 2 h behind, which breaks AWS-signed requests. Check the
  clock before blaming IAM. The emulator too: `adb shell settings put global auto_time 1`.
- **Do not swipe vertically over the home screen.** That starts a real, billable call.
- The older code gotchas (dead dialog contexts, `LayoutBuilder` under `Intrinsic*`,
  `Image.asset(color:)`, `Dismissible` keys, and so on) are in
  `daily-reports/checklist-archive-2026-09-22.md` §Standing notes.
