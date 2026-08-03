# Daily Checklist

_The single active document for the current working day. Update **only this file**
during the day. At end of day, write a report in `daily-reports/` and reset this list
for tomorrow. Deferred items go to `future-checklist.md`._

**Day:** 2026-08-03
**Branch:** `feat/design-implementation` (10 commits ahead of `main`)
**Last worked:** `daily-reports/2026-08-01.md` — home, receipts and the paywall got the design
(committed 08-03; it sat uncommitted for two days)

---

## ▶ START HERE

**One thing gates everything else: an APK on a phone.**

Six days of work are now stacked behind a device test that keeps slipping — the money flow,
scheduled-call reminders, the voice call, the onboarding redesign, and now home, receipts and
the paywall have never been seen on real hardware. The cutover, the release build and IAP are
all downstream of it.

Do these three in order. They are one continuous task; don't split them across days.

### 1. Deploy — backend + `nowli-ai`

The frontend work rides along in the APK. **The backend work does not**, and it is now three
migrations deep: `voice_calls.0006` (`words_circled`), `0007` (receipt `note`), `0008`
(`tiny_question`), plus the `nowli-ai` summary prompt. The app sends all of these regardless;
without the deploy the backend silently drops them. The ISO-8601 serializer fix ships here
too — without it receipt dates render as blank and **every scheduled-call reminder fires at
the wrong time**.

```bash
# from the repo root — see deploy-aws.md for the full runbook and its warnings
git -c core.autocrlf=false archive HEAD:nowli-backend \
  | ssh -i ~/.ssh/id_ed25519 ubuntu@16.170.191.239 "tar -x -C ~/backend"
git -c core.autocrlf=false archive HEAD:nowli-ai \
  | ssh -i ~/.ssh/id_ed25519 ubuntu@16.170.191.239 "tar -x -C ~/ai"
```
Then rebuild both and `up -d`. Tag rollback images first. Backend `entrypoint.sh` migrates
**production RDS** on boot — watch the log, and confirm with `showmigrations` rather than the
boot output, which truncates.

- [ ] Rollback tags created (`:backup-20260803`)
- [ ] Backend deployed, `voice_calls.0006`, `0007`, `0008` all show `[X]`
- [ ] `nowli-ai` deployed
- [ ] Smoke: `https://api.nowlii.com/api/quests/` → 401, `https://ai.nowlii.com/health` → 200

### 2. Build the APK

```bash
cd nowli-frontend-app
C:\src\flutter\bin\flutter.bat build apk --debug --dart-define-from-file=dart_defines.prod.json
```
`dart_defines.prod.json` now points at **`https://`** and carries the Apple defines. Verify the
URLs are actually baked in before installing — unzip the APK and grep `kernel_blob.bin` for
`https://api.nowlii.com` and for the absence of `16.170.191.239`.

- [ ] APK built and URL-verified
- [ ] Installed on the phone

### 3. On-device testing

⚠️ **Use a NEW account.** `pavle` is on both the paywall and voice-call allowlists, and staff
are exempt — that account will never see the trial, the block, or the daily limit.

**The redesigned onboarding (all new, never run on hardware):**
- [ ] Name step: Continue disabled until you type; digits and symbols rejected; accented letters accepted
- [ ] Gender step, then the loader
- [ ] Features → How to use (**scrolls**, has "A couple of honest truths")
- [ ] Companion picker → naming: **↻ cycles names, does NOT change the companion**
- [ ] Type 1 character → too-short error; type 13 → **too-long error actually appears**
- [ ] Steps 7/8 "Limited by design" and 8/8 receipt preview render correctly
- [ ] Progress reads **n/8** throughout, back and skip don't stack screens
- [ ] Voice check: mic permission prompt, **waveform reacts to your voice**, deny the permission → still proceeds
- [ ] Final screen greets you by **your** name, not "Julie"; loader names **your** companion
- [ ] **Kill the app mid-onboarding and reopen** → answers survived
- [ ] Force a profile failure (airplane mode on the last step) → returns to the flow, not stranded at home

**The voice call + receipt:**
- [ ] A real call, then the summary shows **"Words you circled around"** with your own words
- [ ] Summary saves → appears in the **receipt library**, with a **real date** (a blank date
      means the ISO-8601 fix did not deploy)
- [ ] Male/female voice matches the avatar; screen stays awake through a call

**New on 08-01, never run on hardware:**
- [ ] Home screen renders; no broken-image placeholders anywhere in the app
- [ ] Call header counts **"Spark 1 of 2"**, then **2 of 2**; after both, home shows the
      out-of-sparks card and the swipe button stops inviting a call
- [ ] Receipt detail: write a note → reopen → it is still there; **reopen the summary screen
      for that call and confirm the note was not wiped** (that is the bug the endpoint exists for)
- [ ] "Keep this receipt" → share sheet opens with a readable PDF
- [ ] "See what keeps coming back" scrolls Insights to the right section
- [ ] Paywall shows **dated** price steps, and they are anchored sensibly (not 1970, not today
      for an existing subscriber)
- [ ] "Seven days. On us." appears **once** at the end of sign-up and never again
- [ ] Close the voice check with **✕** → lands on the loader, **not a black screen**

**Carried over, still never verified on a device:**
- [ ] The money flow: fresh signup → trial → subscription screen → **new dark trial popup** →
      subscribe → force the paywall by backdating `trial_started_at` 8 days
- [ ] Scheduled-call reminders: 5 min before, from a locked screen, from a cold start, after a reboot
- [ ] Delete My Account really deletes; the same email can sign up again
- [ ] Insights: productive **hour** is real; "Yes, it's my rest day" un-reds the calendar

---

## 🔲 Only after the APK is confirmed working — the cutover

Do **not** start these before the phone test passes. Each one breaks any pre-HTTPS build the
moment it lands, and the installed APK is the fallback if something is wrong.

- [ ] Flip the HTTPS block in `~/backend/.env`: `SECURE_SSL_REDIRECT`, `SESSION_COOKIE_SECURE`,
      `CSRF_COOKIE_SECURE`, `SECURE_HSTS_SECONDS` (ramp 3600 → 31536000, **not** straight to a
      year — HSTS is effectively irreversible for the duration it advertises).
      `BEHIND_TLS_PROXY` is already on.
- [ ] Add the nginx HTTP→HTTPS redirect (the cert was issued `--no-redirect` on purpose)
- [ ] Close 8000/8001 in the AWS security group
- [ ] Then a **release** build becomes possible for the first time — needs the upload keystore,
      and the **release SHA-1 registered in Google Cloud `274971792537`** or Google login dies
      with `DEVELOPER_ERROR` on the signed build

---

## ⛔ Waiting on you (not code)

- [ ] **Companion name suggestions.** `↻` works but the names are placeholder. The design asks
      for "5–7 predefined names per archetype" without listing them, and the backend has no
      field for them. Send the real list → it's a one-file change
      (`companion_name_suggestions.dart`), nothing else moves.
- [ ] **Apple domain verification file**, if the portal asks for it. nginx is already wired:
      drop it in `/var/www/apple/` and it serves at
      `https://api.nowlii.com/.well-known/apple-developer-domain-association.txt`.
- [ ] **Figma seat hit its tool-call limit** mid-session. Consequence: **"Tonight's receipt"
      (step 8/8) was built from its text content, not a screenshot** — worth eyeballing against
      the mock. Six frames in the Welcome Activation Flow were never seen at all.

---

## 🔲 After that, in order

- [ ] **Terms of Service** — still does not exist. Both links are commented out with
      `TODO(legal)` (`sign_up.dart`, `privacy_data_screen.dart`). **P0 — the listing needs it.**
- [ ] **Real payments (IAP)** — the biggest remaining product gap. `activate` is a mock and
      `verify-receipt` a 501 stub, so anyone can "subscribe" for free.
- [ ] **Email from a real sender** — currently a personal Gmail app password. Now that
      `nowlii.com` exists: `noreply@nowlii.com` via Amazon SES, which needs SPF/DKIM at GoDaddy.
- [ ] Merge `feat/design-implementation` → `main` once the phone test passes
- [ ] **Optional:** voice check currently sends the transcript, not raw audio, so Hume prosody
      is skipped. Adding it means a recorder package — decide whether it's worth the dependency.
- [ ] Clean up the orphaned onboarding branch (`procrastination → mood updates → energy
      check-in`): fully written, zero entry points. Per the standing rule, relocate rather than
      delete.

---

## ⚠️ Standing notes

- **HTTPS is live**: `https://api.nowlii.com` (Django) and `https://ai.nowlii.com` (nowli-ai).
  Cert expires **2026-10-29**, `certbot.timer` auto-renews. Config backed up in `deploy/nginx/`.
- **Security-group changes are Console-only.** The `Nowlii` IAM keys in `nowli-backend/.env`
  are S3-only — a permissions boundary denies every `ec2:` action, reads included. Don't waste
  time on the AWS CLI.
- After ever rotating `SECRET_KEY`: tell everyone to sign out and back in.
- Rollback images on the box: `:backup-20260731`. **Images roll back; migrations do not.**
- Local `.env` OpenAI key is invalid (401) since the 07-23 rotation — one insights test logs
  that error and still passes via the fallback path. Prod is fine.
- Paywall escape hatches: `SUBSCRIPTION_ENFORCED=False`, or `SUBSCRIPTION_UNLIMITED_USERS`.
- `flutter` is not on PATH in tool shells — use `C:\src\flutter\bin\flutter.bat`.
- Backend tests: app-level labels (`Apps.users`) fail on this machine's Python 3.13 with a
  namespace-loader error. Use module labels — `manage.py test Apps.users.tests`.
- Longer-term backlog in `future-checklist.md`.
