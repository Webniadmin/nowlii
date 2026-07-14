# Sign in with Apple (B2) — prepared, keys pending

> **STATUS 2026-07-10 — backend ENABLED & verified.** Client provided the identifiers, so
> `nowli-backend/.env` now has `APPLE_CLIENT_IDS=com.nowlii.app,com.nowlii.app.web` (iOS bundle
> id + web/Android Services ID "Nowlii Web Login") and `APPLE_TEAM_ID=7QWJ2DTYZ4`. The endpoint
> is live: `POST /api/auth/apple/` with an invalid token now returns **401** (verifying against
> Apple's keys) instead of 503. Frontend `dart_defines.android.json` has
> `APPLE_SERVICE_ID=com.nowlii.app.web` set; **`APPLE_REDIRECT_URI` is still empty** (needs a
> hosted https Return URL) so the **Android** web-redirect flow can't complete yet. **iOS** needs
> no redirect but requires a **Mac + Xcode** to build — not possible on this Windows box. No
> iOS emulator exists for Windows (iOS Simulator is macOS-only). Team/Key/.p8 remain unused
> (login doesn't need them). All secrets live in git-ignored `.env` / `dart_defines*.json`.



_Added 2026-07-03. The whole flow is built and compiles (backend `manage.py check` = 0;
frontend `flutter analyze` = 0). It is **disabled until you fill in the Apple keys** — the
endpoint returns **503 "not configured"** while `APPLE_CLIENT_IDS` is empty. Mirrors the
Google flow (`google-login.md`)._

## Android web-redirect setup (2026-07-10) — done in code, tunnel + Apple registration pending

To test on the **Android emulator** (no Mac needed) the `sign_in_with_apple` web flow needs a
public https **Return URL** that bounces Apple's `form_post` back into the app. Built & verified:
- **Backend redirect** `apple_web_redirect` → `POST /api/auth/apple/callback/` (`Apps/users/views.py`,
  `urls.py`). `@csrf_exempt`; returns **307** with
  `Location: intent://callback?<apple params>#Intent;package=com.nowlii.app;scheme=signinwithapple;end`.
  Verified with a form POST → correct 307 + intent.
- **Android manifest** — registered the plugin's `SignInWithAppleCallback` activity with the
  `signinwithapple://callback` intent-filter (`android/app/src/main/AndroidManifest.xml`).
  `MainActivity` already had `launchMode="singleTop"` (required).
- **ALLOWED_HOSTS** includes `.ngrok-free.app` / `.ngrok.io` / `.ngrok.app` for the tunnel.
- **Pending:** a public https tunnel to `localhost:8000`, registering its URL on the Services ID
  `com.nowlii.app.web`, and setting `APPLE_REDIRECT_URI` on the client, then a rebuild.

**Tunnel caveat:** ngrok-free shows a **browser interstitial** that can break Apple's `form_post`
redirect. If it does, use **cloudflared** instead (`cloudflared tunnel --url http://localhost:8000`
→ `https://<x>.trycloudflare.com`, no interstitial, no account) and add `.trycloudflare.com` to
ALLOWED_HOSTS. Either way the Return URL is `https://<tunnel-host>/api/auth/apple/callback/`.

## ⚠️ BEFORE a preview / physical-device build — MUST FIX (2026-07-10)

The current Apple Android setup uses a **temporary `trycloudflare.com` tunnel** as the Return URL,
which only lives while the local `cloudflared` process runs (URL changes on restart). This works
for **emulator testing in this session only**. Before building for **preview / a real phone**, do:

1. **Stand up a PERMANENT public https endpoint** for the backend (deploy it, or a stable
   tunnel/custom domain). The Apple Return URL must be reachable and stable.
2. **Re-register** on the Services ID `com.nowlii.app.web` (Apple portal → Configure): the new
   permanent **Domain** + **Return URL** `https://<permanent-host>/api/auth/apple/callback/`.
   (Remove the throwaway trycloudflare one.)
3. **`dart_defines.phone.json`** (physical device) currently has **NO** Apple keys — add
   `APPLE_SERVICE_ID=com.nowlii.app.web` and `APPLE_REDIRECT_URI=https://<permanent-host>/api/auth/apple/callback/`.
   (Only `dart_defines.android.json` (emulator) was set so far.)
4. Add the permanent host to backend **`ALLOWED_HOSTS`**.
5. Phone must reach both the backend AND the Apple Return URL over the public https host.

Until this is done, the "Continue with Apple" button will fail on a preview/phone build (the
tunnel URL from the emulator session is dead). iOS native (a Mac build) would not need the
Return URL at all — only the bundle id `com.nowlii.app`, which is already in `APPLE_CLIENT_IDS`.

## Test session 2026-07-10 — findings (Android emulator, cloudflared tunnel)

**Confidence for real devices:**
- **iOS (iPhone/iPad): ~85%.** The backend half is *verified* (accepts/rejects real Apple
  tokens; bundle id `com.nowlii.app` registered). iOS uses the **native** Apple sheet — no
  redirect/`intent://`/browser — so it avoids everything that made Android flaky below. Not 100%
  only because it's untested here (no Mac) and needs the Xcode **"Sign in with Apple" capability
  + entitlement** added, and the App ID must have that capability enabled.
- **Android (web flow): NOT confident yet** — see the open issue below.

**What worked:**
- Apple authenticated the user and `form_post`ed back to our Return URL through the cloudflared
  tunnel → Django `POST /api/auth/apple/callback/` returned **307** (`intent://…`) — seen several
  times in the log. So Apple config (Services ID `com.nowlii.app.web`, Return URL, domain) is
  accepted and the redirect works.

**Open issue (Android only):** after the 307, the app **never receives the credential** — no
`POST /api/auth/apple/` (token exchange) ever fired. The `intent://…;scheme=signinwithapple;end`
bounce back into the app isn't completing. Likely **Chrome blocking the server-driven `intent://`
redirect without a user gesture**, and/or the emulator killing the backgrounded FlutterActivity
while the Custom Tab is open (losing the plugin's pending result — `flutter run` also repeatedly
"Lost connection to device" when the tab opened). Also hit Apple's **"try again later"** =
rate-limit after ~3 rapid retries.

**Recommended fix for the Android bounce (next time):** change `apple_web_redirect`
(`Apps/users/views.py`) from a bare **307** to a tiny **HTML page** that navigates to the
`intent://` URL via JS *and* offers a tap-through link (a user-gesture navigation is far more
reliable in Chrome than a server redirect). Then retry **once** (not rapidly) after any Apple
cooldown.

**State left in place:** backend `.env` (`APPLE_CLIENT_IDS`, `APPLE_TEAM_ID`), the redirect
view + route, the Android manifest callback activity, and `dart_defines.android.json`
(`APPLE_SERVICE_ID` + the **temporary** trycloudflare `APPLE_REDIRECT_URI`) all remain. The
trycloudflare URL is **ephemeral** — see the "BEFORE a preview / physical-device build" section.
Cleanest real test is **iOS on a Mac** (needs no Return URL at all).

## How it works (contract, same shape as Google)

1. Frontend runs Sign in with Apple → gets an **`identity_token`** (a JWT) + (first time only)
   the name/email.
2. Frontend `POST /api/auth/apple/` with `{ "identity_token": "...", "full_name": "...", "email": "..." }`.
3. Backend verifies the token against **Apple's public keys** (`appleid.apple.com/auth/keys`):
   signature, expiry, issuer, and that `aud` is one of `APPLE_CLIENT_IDS`. Reads the email,
   **gets-or-creates** the user, returns the same JWT shape as `/auth/login/` + `is_new_user`.

## Files (already in place)

**Backend** — `core/settings.py` (`APPLE_CLIENT_IDS`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`,
`APPLE_PRIVATE_KEY`), `Apps/users/serializers.py` (`AppleLoginSerializer`),
`Apps/users/views.py` (`AppleLoginAPI`, verifies via PyJWT `PyJWKClient`),
`Apps/users/urls.py` (`POST /api/auth/apple/`). No new dependency (PyJWT ships with SimpleJWT).

**Frontend** — `pubspec.yaml` (`sign_in_with_apple`), `lib/api/api_constant.dart`
(`appleLogin`, `appleServiceId`, `appleRedirectUri`), `lib/api/auth_service.dart`
(`signInWithApple()`), `lib/api/auth_controller.dart` (`signInWithApple()`),
`lib/api/google_sign_in_flow.dart` (`handleAppleSignIn()` + shared routing). The
**"Continue with Apple" button is wired on all four auth screens** (sign-in, sign-up, welcome,
ready-to-start) — same places as Google.

## What YOU fill in later to enable it

### 1. Apple Developer (paid account) → https://developer.apple.com/account
- **App ID** for `com.nowlii.app` with the **"Sign in with Apple"** capability enabled.
- **Services ID** (e.g. `com.nowlii.app.service`) — needed for the **web / Android** web-redirect
  flow; configure its **Return URL** (a https page you host that redirects back to the app).
- **(Only for server-side token exchange / revoke — NOT needed for basic login):** a **Key (.p8)**
  → gives you Team ID + Key ID + the private key.

### 2. Backend `.env`
```
# iOS bundle id AND/OR the web/Android Services ID — comma separated:
APPLE_CLIENT_IDS=com.nowlii.app,com.nowlii.app.service
# optional (later, for revoke / refresh):
APPLE_TEAM_ID=
APPLE_KEY_ID=
APPLE_PRIVATE_KEY=
```

### 3. Frontend build defines (only for the web / Android web-redirect flow; iOS native needs neither)
```
--dart-define=APPLE_SERVICE_ID=com.nowlii.app.service
--dart-define=APPLE_REDIRECT_URI=https://your-host/apple/callback
```
(add them to `dart_defines*.json` next to the Google id.)

### 4. Per-platform
- **iOS (needs macOS):** add the **"Sign in with Apple"** capability + entitlement in Xcode. This
  is the simplest, most reliable target (native sheet; `aud` = the bundle id).
- **Android:** uses Apple's **web** flow — needs the Services ID + Return URL above, plus the
  `sign_in_with_apple` Android callback setup (intent-filter). More involved than iOS.

## Reality check
- Sign in with Apple **requires a paid Apple Developer account**.
- Apple returns the user's **name/email only on the FIRST authorization** — the backend already
  falls back to the token's email and to the `email`/`full_name` the client passes through.
- Cleanest to test on **iOS**; Android is possible but needs the hosted redirect.
