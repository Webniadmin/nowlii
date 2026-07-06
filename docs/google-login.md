# Google Sign-In (B1) — implementation & setup

## ✅ CURRENT STATE (verified end-to-end on Android, 2026-07-03)

Google login **works on Android** (emulator confirmed; same flow on a physical device).
On **web** the imperative `signIn()` is unreliable (google_sign_in v6 limitation) — Android is
the real target.

**Active Google Cloud project:** `274971792537`
- **Web** client id (audience / `serverClientId`): `274971792537-m5ocadbliir3cn16b8urmro9fgnp742r.apps.googleusercontent.com`
- **Android** client id (NOT in code — Google matches by package + SHA-1): `274971792537-5gej0oi2cuhon8rrkmsdf0n4ohgod1r4.apps.googleusercontent.com`
  - Registered with **package `com.nowlii.app`** + **debug SHA-1 `D9:ED:AA:51:EE:F3:E0:C5:7D:6E:92:32:C6:1F:25:51:09:E2:CA:FE`**.

The Web id is wired in: `nowli-backend/.env` (`SOCIAL_AUTH_GOOGLE_CLIENT_ID`),
`nowli-frontend-app/dart_defines.json` / `dart_defines.android.json` / `dart_defines.phone.json`
(`GOOGLE_WEB_CLIENT_ID`), and `web/index.html` meta tag. **Whenever the Web id changes, update all
five and rebuild the app** (it's baked in at build time). The Android id must live in the SAME
Google Cloud project as the Web id (the id_token `aud`=web, `azp`=android).

**The "Continue with Google" button is wired on every auth screen** via a shared helper
`lib/api/google_sign_in_flow.dart` → `handleGoogleSignIn(context)`: sign-in, welcome, ready-to-start,
sign-up. On success it stores JWTs (like email login) and routes to home/onboarding.

**Verified log:** id_token `aud` = the Web id, `azp` = the Android id, backend `POST /api/auth/google/`
→ 200 with access+refresh+user, tokens saved. No `DEVELOPER_ERROR` (SHA-1/package correct).

**To rebuild + test on Android:** see `docs/running-on-android.md`.

---

# Google Sign-In (B1) — implementation & setup

_Added 2026-07-03. Code is complete and compiles clean (backend `manage.py check` = 0 issues
+ functional test; frontend `flutter analyze` = 0 errors). **Going live still needs the
Google Cloud config below** — until then the button will fail with a config error._

## How it works (contract)

1. Frontend runs the Google Sign-In SDK → gets a Google **`id_token`** (a JWT).
2. Frontend `POST /api/auth/google/` with `{ "id_token": "<token>" }`.
3. Backend verifies the token against Google (signature, expiry, and `aud` == our client id),
   reads the verified email, **gets-or-creates** the user (activated, no local password),
   and returns the **same shape as `/api/auth/login/`** plus `is_new_user`:
   ```json
   { "refresh": "...", "access": "...",
     "user": {"user_id": 1, "email": "...", "is_superuser": false},
     "is_new_user": true }
   ```
4. Frontend stores tokens via `StorageService` (identical to email login), then routes:
   profile exists → `/homeScreen`, else → `/onboardingFlow`.

## Files changed

**Backend (`nowli-backend/`)**
- `core/settings.py` — `GOOGLE_OAUTH_CLIENT_ID` (from `SOCIAL_AUTH_GOOGLE_CLIENT_ID`);
  made `SOCIAL_AUTH_GOOGLE_OAUTH2_CALLBACK_URL` env-driven.
- `Apps/users/serializers.py` — `GoogleLoginSerializer` (`id_token`).
- `Apps/users/views.py` — `GoogleLoginAPI` (verifies token via `google-auth`, issues SimpleJWT).
- `Apps/users/urls.py` — `POST /api/auth/google/` (`name='auth-google-login'`).
- Dependency `google-auth` was already installed (no new package needed).

**Frontend (`nowli-frontend-app/`)**
- `pubspec.yaml` — added `google_sign_in: ^6.2.1`.
- `lib/api/api_constant.dart` — `googleLogin` endpoint + `googleWebClientId`
  (`--dart-define=GOOGLE_WEB_CLIENT_ID=...`).
- `lib/api/auth_service.dart` — `signInWithGoogle()` (SDK → backend → store tokens).
- `lib/api/auth_controller.dart` — `signInWithGoogle()` (GetX, mirrors `login`).
- `lib/screen/auth/sign_in_screen.dart` — the "Continue with Google" button now calls it
  (was a placeholder that pushed onboarding); `socialButton` gained an `onPressed`.

## What YOU must configure for it to actually work

### 1. Google Cloud Console — OAuth client IDs (https://console.cloud.google.com/apis/credentials)
Create an OAuth consent screen, then Client IDs per platform you target:
- **Web application** client → this is the **primary** one. Its id is the `aud` the backend
  checks and the `serverClientId` the app sends. Add authorized JS origins for web dev
  (e.g. `http://localhost:5000`).
- **Android** client → needs the app **package name** + **SHA-1** fingerprint
  (`keytool -list -v -keystore <debug/release keystore>`).
- **iOS** client → needs the **bundle id**; gives you a reversed-client-id URL scheme.

### 2. Backend `.env` (`nowli-backend/.env`)
```
SOCIAL_AUTH_GOOGLE_CLIENT_ID=<WEB_CLIENT_ID>.apps.googleusercontent.com
SOCIAL_AUTH_GOOGLE_SECRET=<web client secret>          # only needed for the allauth redirect flow
```
Without `SOCIAL_AUTH_GOOGLE_CLIENT_ID` the endpoint returns **503 "not configured"**.

### 3. Frontend build define + per-platform bits
- Pass the **web** client id at run/build time (used as `serverClientId` on native):
  ```
  flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=<WEB_CLIENT_ID>.apps.googleusercontent.com ...
  ```
  (add it to `dart_defines.json` alongside `BASE_URL`/`AI_BASE_URL`).
- **Web:** add to `web/index.html` `<head>`:
  `<meta name="google-signin-client_id" content="<WEB_CLIENT_ID>.apps.googleusercontent.com">`
  (on web `serverClientId` is intentionally NOT set — the code guards this with `kIsWeb`).
- **Android:** register the SHA-1 (above); enable **Windows Developer Mode**
  (`start ms-settings:developers`) so `flutter pub get`/build can create plugin symlinks
  — `google_sign_in` is a native plugin (this was the pub-get warning during setup).
- **iOS:** add the reversed-client-id URL scheme to `ios/Runner/Info.plist` (needs macOS).

## How to test end-to-end (once configured)
1. Backend: `SOCIAL_AUTH_GOOGLE_CLIENT_ID` set, `runserver`.
2. Frontend: `flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=... --dart-define=BASE_URL=...`
3. Tap **Continue with Google** → pick an account → should land on home/onboarding and have
   tokens in storage. Backend logs a `get_or_create` on the user's email.

## Verified now (without real Google creds)
- Backend `GoogleLoginAPI`, with Google verification mocked: valid → 200 + tokens +
  `is_new_user` true then false on repeat; unverified email → 401; bad token → 401;
  missing field → 400. URL resolves; `/api/subtasks/generate/`-style collisions N/A.
- Frontend compiles: `flutter analyze` → 0 errors.

## Wired on 2026-07-03 (Web client id in place)
- Web-type Client ID `1042808398004-…apps.googleusercontent.com` set in:
  `nowli-backend/.env` (`SOCIAL_AUTH_GOOGLE_CLIENT_ID`), `nowli-frontend-app/dart_defines.json`
  (`GOOGLE_WEB_CLIENT_ID`, alongside `BASE_URL`/`AI_BASE_URL`), and `web/index.html` meta tag.
- Backend confirmed reading it (`settings.GOOGLE_OAUTH_CLIENT_ID` set). `flutter build web` passes.
- **Still required in Google Cloud:** Authorized JavaScript origin `http://localhost:5000`, and —
  if the OAuth consent screen is in "Testing" — the tester's Google account added as a Test user.
- **Run web on a fixed port** so the origin matches: `--web-port=5000`.
- **Web caveat:** `google_sign_in` v6's imperative `signIn()` is finicky on web (Google pushes the
  rendered-button flow). If the web popup misbehaves, the reliable target is a real Android device
  (B3) or we switch the web path to the rendered Google button.

## Notes / follow-ups
- Uses a custom token-exchange view (verifies the `id_token` with `google-auth`) rather than
  `dj-rest-auth`'s `SocialLoginView` — matches this repo's custom-auth style and avoids adding
  `dj_rest_auth` to `INSTALLED_APPS`. (Those imports already sit unused at the top of `views.py`.)
- `google_sign_in` v6 API is used. v7 changed the API significantly; if upgrading, revisit
  `auth_service.signInWithGoogle()`.
- B2 (Apple) will follow the same shape: a `/api/auth/apple/` token-exchange view.
