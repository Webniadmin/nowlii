# Sign in with Apple (B2) — prepared, keys pending

_Added 2026-07-03. The whole flow is built and compiles (backend `manage.py check` = 0;
frontend `flutter analyze` = 0). It is **disabled until you fill in the Apple keys** — the
endpoint returns **503 "not configured"** while `APPLE_CLIENT_IDS` is empty. Mirrors the
Google flow (`google-login.md`)._

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
