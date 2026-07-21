# NOWLII — Next Phase (planned work)

_Created 2026-07-01 for the next session. **Do cleanup before any new features.**_
_Companion to `architecture.md` (how things fit) and `project-status.md` (current state)._

Each task lists **What to do**, **Files likely touched**, and **Gotchas/blockers**.
References verified against the codebase on 2026-07-01.

---

## ▶ RESUME HERE (2026-07-21 end of day)

**Where we are:** the app is now **deployed to AWS and being tested on a physical phone against the live
backend** (not just the emulator). Full detail in `daily-reports/2026-07-21.md`; the authoritative deploy
runbook is now **`deploy-aws.md`** (rewritten — the old git-pull assumption was wrong; deploy = `git
archive | ssh tar -x` → `docker compose build && up -d`). **SSH to EC2 is fixed** (`ssh -i ~/.ssh/id_ed25519
ubuntu@16.170.191.239`). Google login works on-device. Core API (auth/quests/subtasks/profiles/avatars/
subscriptions/support) verified live.

**Top blocker — AI is down everywhere:** the shared **OpenAI key is out of quota** (`insufficient_quota`),
which kills AI voice, Insights (500), and AI subtask-gen on both AWS *and* local. **Next action: add OpenAI
billing credits** (or rotate to a funded key / set a backend `ANTHROPIC_API_KEY`), then verify the AI trio.

**Next up (2026-07-21):**
1. Add OpenAI credits → re-verify AI voice / insights / subtask-gen end-to-end on the phone.
2. Fix **Insights 500 → graceful fallback** (`insights/views.py`) + redeploy backend.
3. Sign up a fresh account on the phone (prod RDS ≠ local DB) → test quests + AI voice on-device.
4. Then continue the pre-2026-07-14 threads below (subscribe button 1A, secrets rotation A5, Apple login,
   and HTTPS/domain before any release/Play build).

---

## ▶ RESUME HERE (2026-07-14 end of day — superseded by 2026-07-21 above)

**Where we are:** core loop + AI voice call + Insights all working on the emulator. Big 2026-07-14
session — full detail + a **DETAILED TO-DO for tomorrow in `daily-reports/2026-07-14.md`** (read its
"Recommended next start"). Today shipped: Add-Quest **Enable call / Repeat quest** toggles wired to real
behavior + **5-min** call copy + **no-past-scheduling** guard (`quest-toggles-wiring` memory); Insights
**"What this means" AI summary** + **dynamic "Your mood" chart**; **Subscriptions Phase 1** — backend
lifecycle engine (`Apps/subscriptions`, decreasing-price-then-free, mock activation, tested) + frontend
data layer (`subscription-model` memory); **Nowli Pro screen** spelling fixes + "How it works" matched to
Figma + new **"How billing works"** section with the phase boxes. For earlier sessions read
`daily-reports/2026-07-10.md` (fluid voice, moderation, barge-in, Apple web-redirect) and `2026-07-07.md`
(Insights Top-Emotions / When-feeling-low). Base (cleanup, Google login, email, avatars, support) is in
the STATUS table below + the feature docs.

> ⚠️ **Nothing is committed to git yet** — the whole session is on disk only. Commit early tomorrow.

**Restart everything tomorrow** (each in its own terminal; background servers don't survive a
reboot). Details in `running-locally.md` / `running-on-android.md`:
```powershell
# 1) Django backend (bind 0.0.0.0 for the emulator/phone; allow their hosts)
cd nowli-backend
$env:DB_ENGINE="django.db.backends.sqlite3"; $env:DEBUG="True"
$env:ALLOWED_HOSTS="10.0.2.2,192.168.0.39,localhost,127.0.0.1"
uv run python manage.py runserver 0.0.0.0:8000

# 2) nowli-ai (optional, for the AI companion)
cd nowli-ai; $env:HOST="0.0.0.0"; $env:PORT="8001"; .venv\Scripts\python.exe test17.py

# 3) App on the Android emulator
flutter emulators --launch Medium_Phone_API_36.1
flutter run -d emulator-5554 --dart-define-from-file=dart_defines.android.json
```

**Config state (all set up, git-ignored `.env` / dart_defines):**
- Google Cloud project `274971792537` (Web + Android client ids wired). Google login verified on Android.
- Email sender `nowliiapp@gmail.com` (Gmail app password) — OTP/support emails work.
- Admin superuser `justweb.rs@gmail.com` / `lozinka_123` → `http://localhost:8000/admin/`.
- Avatars: DB seeded with 6 companions (images on S3). **If the SQLite DB is reset, re-seed** (see
  `running-on-android.md`; a repeatable management command is still a TODO).
- Apple: everything built; **empty** `APPLE_CLIENT_IDS` etc. — fill in to enable (`apple-login.md`).

**Next up (in order) — the authoritative day-by-day list is in `daily-reports/2026-07-14.md`
"Recommended next start". Summary:**

0. **Commit the session's work first** (nothing is committed yet).

1. **SUBSCRIPTIONS (primary thread — continue this):**
   - **A. Wire the subscribe flow:** `subscription_popup.dart` "Let's begin 7 days free" button is still
     empty (`onPressed: () {}`) → call `SubscriptionService.activateMock()` + SnackBar + status refresh;
     show current status (month/price/next/"Free forever") when already subscribed; add a cancel action.
   - **B. Client/design decisions:** (i) reconcile the two pricing models on the Pro screen — it now
     shows BOTH the Figma trial cards (Yearly $25.99 / "7 days free") AND the new decreasing-phase
     billing explanation; decide which is the real purchase path. (ii) Decide exactly which features
     "Pro" gates, then enforce (`subscriptions.services.user_has_pro` backend + frontend gating).
   - **C. Phase 2 — real IAP:** `in_app_purchase` plugin + per-phase products in App Store Connect /
     Play Console (verify current offer templates) + backend receipt verification (fill the
     `verify-receipt/` stub → drive the engine, set `platform`/store token). Mobile-only; no Stripe
     in-app. See `subscription-model` memory.

2. **Add-Quest toggle client decisions:** (a) "Call Nowlii" button on Scheduled/Blocking too (Today
   only now)? (b) does "Repeat quest" need real recurrence (linked series) vs the 7-day materialization?
   Real recurrence/scheduled calls → deferred `flutter_local_notifications` + backend reminder model
   (`voice-check-and-scheduling.md`).

3. **Carryovers:** barge-in headphones test + mic earcon; **Apple login** `intent://` fix + permanent
   https URL before any device build (`apple-login.md`); **A5 rotate secrets**; build the phone `.apk`
   (`flutter build apk --debug --dart-define-from-file=dart_defines.phone.json`).

4. **Small follow-ups:** `editFrom` avatar → send `predefined_option`; seed-as-management-command;
   reconcile unused `users.CustomUserModel` vs default `auth.User`.
   _(Done 2026-07-14: Insights "What this means" AI summary + dynamic "Your mood" chart.)_

---

## STATUS (updated 2026-07-03)

| Task | Status | Notes |
|---|---|---|
| **A1** remove junk/scratch | ✅ done | NOT deleted — **preserved + relocated** to `lib/experimental/`, imports fixed. See `cleanup-log.md`. |
| **A2** `je_je_…` placeholder | ✅ done | 4 mockups relocated to real feature folders (`screen/streak/`, etc.), renamed. |
| **A3** naming conventions | ✅ done | ~25 folders + ~25 files renamed, all imports fixed, `flutter analyze` = 0 errors. A few ambiguous names + `Apps/` left (see `cleanup-log.md`). |
| **A4** route `SubTasksViewset` | ✅ done | Live at `/api/subtasks/` CRUD; `/subtasks/generate/` kept via include reorder; serializer/parser fixed so create works. Verified. |
| **A5** rotate API keys | ⏳ pending | Needs YOU to rotate at the providers (OpenAI/AWS/Hume/Google); then paste values → I update both `.env`s + fresh `SECRET_KEY`. |
| **B1** Google login | ✅ **verified on Android** | `/api/auth/google/` (id_token → JWT) + button on all auth screens. Working end-to-end on the emulator with Google Cloud project `274971792537`. Web `signIn()` remains finicky (Android is the target). See `google-login.md`. |
| **B2** Apple Sign-In | 🔶 prepared (keys pending) | Full flow built like Google: `/api/auth/apple/` (verifies identity token, 503 until configured) + `sign_in_with_apple` + button on all 4 auth screens. Fill in `APPLE_CLIENT_IDS` etc. to enable. See `docs/apple-login.md`. |
| **B3** mobile build (device) | ✅ **on real device vs AWS** | Debug `.apk` built with `dart_defines.prod.json` (→ AWS), installed on a physical phone via file transfer, runs against the **live AWS backend**; Google login verified on-device (2026-07-21). Release/Play build still needs HTTPS + signing. iOS still needs macOS. See `deploy-aws.md`. |
| **AWS deploy** | ✅ **live (2026-07-21)** | Both services rebuilt on EC2 from `main`; runbook in `deploy-aws.md`; rollback images `:backup-20260721`. Prod `.env` gaps fixed (hosts/CSRF/Google id). Blocker: OpenAI quota for AI features. |
| **Email/SMTP** | ✅ done | env-driven; sender = `nowliiapp@gmail.com`; test email delivered. |
| **Companion avatars** | ✅ fixed | DB seeded (6 companions on S3); update sends `predefined_option`; empty-list fallback + broken-asset fix. |
| **Support / contact chat** | ✅ done | `Apps/support` + `/api/support/messages/` (per-user); admin "Reply" box; email both ways. Superuser `justweb.rs@gmail.com`. See `docs/support-feature.md`. |

_Detailed change records: `cleanup-log.md` (A1–A4), `google-login.md` (B1)._

---

## PART A — CLEANUP FIRST (before any new features)

### A1. Remove junk / scratch folders
**What:** Delete experimental/scratch code that isn't wired into the app:
- `lib/aaa/` (contains `ai_voice_call/`, `reminder/` experiments)
- `lib/screen/test_file/`
- `lib/screen/debug/` (`profile_test_screen.dart`)
- `.backup` files: `lib/screen/reday_to_start_screen_p4.dart.backup`

**Files likely touched:** the folders above, plus **`lib/core/app_routes/app_pages.dart`**
and **`lib/core/app_routes/app_routes.dart`** (route cleanup — see gotcha).

**Gotchas/blockers:**
- `lib/aaa/` and `lib/screen/test_file/` are **not imported anywhere** → safe to delete.
- **`lib/screen/debug/profile_test_screen.dart` IS referenced**: imported at
  `app_pages.dart:52` and wired to the `profileTestScreen` route. To remove `debug/` you
  must also delete that import, its `GoRoute`, and the `profileTestScreen` constant in
  `app_routes.dart`. Deleting the folder alone will break the build.
- After deleting, run `flutter analyze` and a `flutter build web` to confirm nothing else
  referenced them transitively.

### A2. Delete the `je_je_page_gula_connect_kori_nai.dart` placeholder
**What:** Remove the placeholder ("pages I haven't connected yet").

**Files likely touched:** `lib/je_je_page_gula_connect_kori_nai.dart/` **← it's a
DIRECTORY, not a single file.** It contains `ai_calling.dart`,
`popup_multi_misscal_talk.dart`, `quest_for_done_screen.dart`, `steak_popup.dart`.

**Gotchas/blockers:**
- Confirmed **not imported anywhere** → safe to delete the whole directory.
- Before deleting, skim the 4 files — some (e.g. `steak_popup.dart`, `ai_calling.dart`)
  may contain logic worth salvaging into the real screens rather than losing outright.

### A3. Fix bad naming conventions
**What:** Normalize the many misspelled/inconsistent names so the tree is navigable.
Examples found: `lib/utlis/` (→ `utils`), `screen/Onboarding/` (capitalized vs others),
`swaipe_to_talk/` (swipe), `reday_to_start_*` (ready), `remiender_notification/` (reminder),
`onbording_*` / `efit_name.dart` / `blockng.dart` / `poup_*` (popup), `steak_popup` (streak),
`Apps/` (capital A — imported as `Apps.…`).

**Files likely touched:** many folders/files under `lib/`, and **every import that
references them** — especially `lib/core/app_routes/app_pages.dart` (imports ~40 screens).
Backend `Apps/` rename would touch `INSTALLED_APPS`, every `apps.py` `name=`, `urls.py`
includes, and migration `app_label`s — **high blast radius**.

**Gotchas/blockers:**
- Rename in small batches; after each, fix imports and run `flutter analyze` /
  `manage.py check`. Do NOT bulk-rename everything at once.
- **Windows trailing-space trap** (already hit once): never reintroduce folder names with
  trailing spaces (the old `core%20/` bug). Keep names ASCII, lowercase, no spaces.
- Renaming Django `Apps/` is risky (migrations reference `app_label`) — consider leaving
  it or doing it as an isolated, well-tested change. Lowest-risk win is the `lib/` renames.
- Some files use `part`/`part of` or GetX bindings by path — grep for the old name across
  the repo before/after each rename.

### A4. Route `SubTasksViewset` properly
**What:** `SubTasksViewset` is fully implemented in `Apps/quests/views.py` but never
registered, so subtasks have no standalone CRUD endpoints (only nested via the quest
serializer).

**Files likely touched:** `nowli-backend/Apps/quests/urls.py` (register the viewset),
possibly `core/urls.py` (include ordering).

**Gotchas/blockers:**
- **URL collision risk.** `core/urls.py` includes `Apps.quests.urls` at `api/` *before*
  `path("api/subtasks/", include("Apps.subtask_generator.urls"))`. If you
  `router.register(r'subtasks', SubTasksViewset)`, DRF's default detail route
  `subtasks/<pk>/` uses `[^/.]+` and will **shadow `/api/subtasks/generate/`** (it'd treat
  `generate` as a pk). Avoid this: register under a distinct basename (e.g. `sub-tasks`),
  or nest under quests (`quests/{id}/subtasks/`), or reorder includes so the explicit
  `generate/` path resolves first.
- `SubTasksViewset` already sets `permission_classes=[IsAuthenticated]` and filters by
  `task__user=request.user` — keep that; verify the `MultiPartParser` there is intended.

### A5. Rotate exposed API keys
**What:** All secrets are committed in plaintext `.env` files and must be rotated (they
were visible/used this session).

**Files likely touched (and what's in them):**
- `nowli-backend/.env`: `OPENAI_API_KEY`, AWS (`AWS_ACCESS_KEY_ID`,
  `AWS_SECRET_ACCESS_KEY`), `EMAIL_HOST_PASSWORD` (Gmail app pw), `DB_PASSWORD`,
  `SECRET_KEY` (still the `django-insecure-…` dev key), Google OAuth secret.
- `nowli-ai/.env`: `OPENAI_API_KEY`, `HUME_API_KEY`, `HUME_SECRET_KEY`, `HUME_CONFIG_ID`.

**Gotchas/blockers:**
- **The OpenAI key is duplicated** in both `.env` files — rotate once, update **both**.
- Rotate at the provider (OpenAI dashboard, Hume, AWS IAM, Google Cloud console), then
  paste new values locally; don't just edit the files.
- `.env` is git-ignored now, **but if it was ever committed**, the old keys live in git
  history — scrubbing history (or treating the keys as permanently burned) is required.
- Generate a fresh Django `SECRET_KEY` for any non-dev deployment.
- After rotating, re-run the smoke tests in `running-locally.md` (`/health` should still
  show `openai:true, hume:true`).

---

## PART B — NEW FEATURES (only after Part A is done)

### B1. Google OAuth login (backend + frontend)
**What:** Wire real Google sign-in returning app JWTs. Backend already lists the Google
provider in `django-allauth`; the missing piece is a REST endpoint that exchanges a Google
credential for NOWLII access/refresh tokens, plus the frontend button/flow.

**Files likely touched:**
- Backend: `nowli-backend/core/settings.py` (`SOCIALACCOUNT_PROVIDERS['google']` client
  id/secret via env), `Apps/users/urls.py` + `Apps/users/views.py` (a social-login view,
  e.g. `dj-rest-auth`'s `SocialLoginView` with `GoogleOAuth2Adapter`, returning SimpleJWT),
  `core/urls.py`.
- Frontend: add `google_sign_in` to `pubspec.yaml` (**not currently a dependency**), new
  `lib/api/` or `lib/services/` social-auth method that posts the Google token to the
  backend and stores the returned JWT via `StorageService.saveTokens()`, and the sign-in
  screen (`lib/screen/auth/sign_in_screen.dart`) button/handler.

**Gotchas/blockers:**
- No `google_sign_in` package is present yet — adding native OAuth pulls in Android/iOS
  platform config.
- **Config sprawl:** need a Google Cloud OAuth client per platform — Android needs the app
  SHA-1 fingerprint + package name; iOS needs the reversed client-id URL scheme; web needs
  an authorized JS origin. `settings.py` still hardcodes a
  `SOCIAL_AUTH_GOOGLE_OAUTH2_CALLBACK_URL` to `127.0.0.1:8000` — make it env-driven.
- Decide the token-exchange contract: frontend sends the Google `id_token`/`access_token`
  → backend verifies → returns SimpleJWT. Keep storage identical to `auth_service.login()`
  so the route guard keeps working.
- `ACCOUNT_EMAIL_VERIFICATION = "mandatory"` may interfere with social signups — verify
  allauth treats verified Google emails as already-verified.

### B2. Apple Sign-In (backend + frontend)
**What:** Same shape as B1 for Apple. Provider is already listed in allauth
(`allauth.socialaccount.providers.apple`).

**Files likely touched:**
- Backend: `settings.py` (`SOCIALACCOUNT_PROVIDERS['apple']` — team id, key id, client id,
  private key, all via env), a social-login view in `Apps/users/`, `core/urls.py`.
- Frontend: add `sign_in_with_apple` to `pubspec.yaml`, a service method + sign-in button.

**Gotchas/blockers:**
- **Apple requires a paid Apple Developer account** and a `.p8` private key + Service ID;
  more setup than Google.
- Apple only returns the user's name/email **once** (first authorization) — the backend
  must persist it on first login or it's lost.
- Apple Sign-In truly works only on iOS/macOS (and via web JS on Android with a redirect);
  test target matters.
- iOS requires the "Sign in with Apple" capability in Xcode + the entitlement.

### B3. Mobile build setup (run on a physical Android/iOS device)
**What:** Currently the app only runs as Flutter **web** (that's all that's set up). Enable
building/running on real devices. Document the exact prerequisites.

**Files likely touched:** mostly toolchain/config, not app code — `android/` Gradle config
(signing, `applicationId`, minSdk), `ios/` Xcode project (bundle id, signing team),
`pubspec.yaml` if plugins need platform setup; run with the same `--dart-define` URLs.

**What's needed / gotchas:**
- **Android (works from this Windows machine):**
  - Install Android Studio + Android SDK + platform-tools; accept licenses
    (`flutter doctor --android-licenses`).
  - Enable **Windows Developer Mode** (`start ms-settings:developers`) — required for
    Flutter plugin symlinks on native builds (web didn't need it; native does).
  - On the phone: enable Developer Options → **USB debugging**, connect via cable, accept
    the RSA prompt; `flutter devices` should list it; `flutter run -d <id>`.
  - **`localhost` won't reach the dev servers from a physical phone.** Use the PC's LAN IP
    for `--dart-define=BASE_URL=http://<PC-LAN-IP>:8000` (and `:8001`), run the servers
    bound to `0.0.0.0`, and open the firewall for those ports (or use `adb reverse
    tcp:8000 tcp:8000` / `tcp:8001` over USB).
  - Android blocks cleartext HTTP by default on newer SDKs — either serve HTTPS or add a
    network-security-config / `usesCleartextTraffic` for dev.
  - Need a signing config for release builds (debug builds run without one).
- **iOS (BLOCKER on this machine):**
  - **Requires macOS + Xcode** — cannot be built on Windows at all. Needs an Apple
    Developer account, provisioning profile, and bundle id signing.
  - Physical iOS device also needs the LAN-IP + cleartext (ATS) exception, same as Android.
- General: after any native run, re-verify the three-service wiring from `architecture.md`
  (the phone must reach both `:8000` and `:8001`).

---

## Suggested order

A5 (rotate keys — do immediately, security) → A1 → A2 → A4 → A3 (naming, most churn) →
then B1 → B2 → B3. Keep each cleanup step a separate, verifiable change
(`flutter analyze` + `flutter build web` + `manage.py check`) before moving on.
