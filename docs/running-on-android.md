# Running NOWLII on Android (emulator + physical phone)

_Verified 2026-07-03 on the Windows dev box: app runs on the `Medium Phone API 36.1` emulator,
Google login + companion avatars + email all work end-to-end._

_Re-verified 2026-07-06: backend on `0.0.0.0:8000` + emulator run (`emulator-5554`) build,
install, and launch cleanly (no logcat errors). Two tips learned this run:_
- _Run `flutter run` in **your own terminal** (interactive) so hot reload (`r`) and the
  in-tool screenshot (`s`) work. Launching it non-interactively detaches after startup._
- _`adb exec-out screencap` returns a **black** image for this Flutter app (Impeller renders
  to a GPU surface `screencap` can't grab) — use the emulator window or the `flutter run`
  `s` key to capture instead. Not an app fault._

The Flutter app talks to two local servers (Django `:8000`, nowli-ai `:8001`). The trick on
Android is **how the device reaches those servers**, which differs between emulator and phone.

## Backend URL per target (this is the #1 gotcha)

| Target | `BASE_URL` / `AI_BASE_URL` host | dart-define file |
|---|---|---|
| Android **emulator** | `http://10.0.2.2:8000` / `:8001` (10.0.2.2 = the host's loopback) | `dart_defines.android.json` |
| **Physical phone** | `http://<PC-LAN-IP>:8000` / `:8001` (e.g. `192.168.0.39`) | `dart_defines.phone.json` |
| Web / desktop | `http://localhost:8000` / `:8001` | `dart_defines.json` |

All three also carry `GOOGLE_WEB_CLIENT_ID` (see `google-login.md`).

## One-time setup (already done on this machine)

- **Developer Mode ON** (`start ms-settings:developers`) — required so `flutter pub get`/build can
  create native-plugin symlinks (`google_sign_in` is a native plugin). Without it the build fails
  with "requires symlink support".
- **Android build-tools were a Linux copy** (binaries had no `.exe`) → build failed with
  *"Installed Build Tools revision 35.0.0 is corrupted"*. Fix: delete
  `%LOCALAPPDATA%\Android\sdk\build-tools\35.0.0` and reinstall via
  `sdkmanager "build-tools;35.0.0"` (needs `JAVA_HOME` = Android Studio's `jbr`). Same applies to
  36.0.0/36.1.0 if a build ever selects them.
- **Debug keystore** created at `%USERPROFILE%\.android\debug.keystore` (standard params). Its
  SHA-1 `D9:ED:AA:51:EE:F3:E0:C5:7D:6E:92:32:C6:1F:25:51:09:E2:CA:FE` is registered in the Android
  OAuth client. Get it anytime with:
  `& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android`
- **Cleartext HTTP for debug** — `android/app/src/debug/AndroidManifest.xml` adds
  `android:usesCleartextTraffic="true"` so debug builds can hit the dev backend over `http://`.
  Release builds stay HTTPS-only.

## Run on the emulator

```powershell
# 1. Backend (bind 0.0.0.0 so the emulator reaches it via 10.0.2.2; allow that host)
cd nowli-backend
$env:DB_ENGINE="django.db.backends.sqlite3"; $env:DEBUG="True"
$env:ALLOWED_HOSTS="10.0.2.2,192.168.0.39,localhost,127.0.0.1"
uv run python manage.py runserver 0.0.0.0:8000
# (optional) nowli-ai: cd nowli-ai; $env:HOST="0.0.0.0"; $env:PORT="8001"; .venv\Scripts\python.exe test17.py

# 2. Launch the emulator + run the app
flutter emulators --launch Medium_Phone_API_36.1
flutter run -d emulator-5554 --dart-define-from-file=dart_defines.android.json
```
Google login needs a Google account added on the emulator (Settings → Passwords & accounts → Add
account) and the tester's account listed as a **Test user** on the OAuth consent screen.

## Build the .apk for a physical phone

```powershell
cd nowli-frontend-app
flutter build apk --debug --dart-define-from-file=dart_defines.phone.json
# → build\app\outputs\flutter-apk\app-debug.apk
```
Debug APK is signed with the debug keystore (SHA-1 above = registered Android client → Google login
works) and has cleartext enabled. **For the phone to reach the backend:**
- Phone + PC on the **same network**; backend running bound to `0.0.0.0:8000` with the PC's LAN IP in
  `ALLOWED_HOSTS`.
- Open **Windows Firewall** inbound for TCP `8000`/`8001` on the private network (Python is blocked by
  default), or the phone's requests will time out.

## Companion avatars — seeded data (see `avatars-and-companions` note in project-status)

Avatars come from `GET /api/nowlii-options/` (backend `NowliiPredefinedOption`). An **empty DB
returns `[]`** → the picker used to spin forever. The DB was seeded with 6 companions (milo, bloop,
gumo, knotty, fizzy, zee) whose images live on **S3** (public HTTPS URLs → load on emulator AND
phone). Picking one sends `predefined_option` (the only writable way — `avatar_logo`/`nowlii_name`
are read-only) and the backend copies the avatar into the profile. If the DB is reset, re-seed
(a repeatable management command is a pending task).
