# Daily Checklist

_The single active document for the current working day. Update **only this file**
during the day. At end of day, write a report in `daily-reports/` and reset this list
for tomorrow. Deferred items go to `future-checklist.md`._

**Day:** 2026-07-31

---

## ✅ HTTPS IS LIVE — `https://api.nowlii.com` + `https://ai.nowlii.com` (2026-07-31)

**The release blocker is gone.** Both services are behind a domain with a valid Let's Encrypt
certificate, and a new APK built against them is ready to install.

### What landed

- **DNS at GoDaddy** — `api` and `ai` both → `16.170.191.239`, propagated everywhere.
  > First attempt pointed both at `204.69.207.1`, the GoDaddy **parking** IP copied from the
  > `@` record. The names existed but led nowhere. If a subdomain "exists but doesn't work",
  > check the *value*, not just that the record is there.
- **Security group** — 80 and 443 opened. 8000/8001 deliberately still open (see cutover below).
  > **Not scriptable from the dev machine.** The `Nowlii` IAM keys in `nowli-backend/.env` are
  > **S3-only** — a permissions boundary denies every `ec2:` action, reads included (verified
  > 2026-07-31; `deploy-aws.md` used to claim EC2 FullAccess and was wrong). Console only.
- **nginx 1.24 + certbot 2.9** installed; `certbot.timer` enabled for auto-renewal.
  `ufw` confirmed **inactive** — the security group is genuinely the only firewall.
- **Vhosts** `/etc/nginx/sites-available/{api,ai}.nowlii.com` → `:8000` / `:8001`.
  `ai` gets `proxy_buffering off` + 3600 s timeouts so **SSE `chat-stream` isn't held back**;
  both get `client_max_body_size 25m` for media / recorded audio.
- **Certificate** — one cert, both SANs (`api.nowlii.com`, `ai.nowlii.com`), expires
  **2026-10-29**. Issued `--no-redirect` on purpose: a forced HTTP→HTTPS redirect while the
  old APK still talks plain HTTP to `:8000` would have broken it.
- **`~/backend/.env`** — `ALLOWED_HOSTS` + `CSRF_TRUSTED_ORIGINS` extended with both subdomains
  (backup `.env.bak-20260731-predomain`); container **force-recreated**, because `env_file` is
  baked in at container *create* time and a plain `restart` would not have picked it up.
- **`dart_defines.prod.json`** → `https://api.nowlii.com` / `https://ai.nowlii.com`.
  The old IP config is kept as **`dart_defines.prod-ip.json`** for a fast rollback build.

### Verified, not assumed

| Check | Result |
|---|---|
| TLS cert from outside | valid, `CN=api.nowlii.com`, SANs cover both, Let's Encrypt |
| `api` `/api/docs/`, `/admin/login/` | 200 |
| `api` protected routes, no token | 401 |
| `ai` `/health` | 200 |
| `ai` `/api/v1/*`, no token | 401 (gate enforcing) |
| **Authenticated** over HTTPS — quests, profiles, rest-days, quota, subscriptions, scheduled | **all 200** |
| `ai` `/api/v1/*` with a **Django** token | 200 — cross-service JWT still matches |
| same token, one char changed | 401 |
| `session/new` → `realtime/token` | 200, `gpt-realtime-mini`, `voice: marin` (cost cap + gender intact) |
| APK contents | `https://api.nowlii.com` + `https://ai.nowlii.com` present, old IP **absent** |

**New build:** `nowlii-https.v0.2.apk` (debug, HTTPS) in
`nowli-frontend-app/build/app/outputs/flutter-apk/`.

### Social login on the new domain (2026-07-31)

- **Google — nothing to change, and nothing was.** The native Android flow never involves the
  backend URL: Google matches by package `com.nowlii.app` + SHA-1, and the app posts the
  `id_token` to whatever `BASE_URL` it was built with. Verified on the new domain: a bad token
  gives **401**, not 503, so the audience check is live.
  > ⚠️ **Coming with the release keystore:** register the **release SHA-1** in Google Cloud
  > `274971792537` alongside the debug one, or Google login dies with `DEVELOPER_ERROR` on the
  > signed build. Unrelated to the domain, easy to forget.
- **Apple — moved onto the permanent URL.** Portal + backend + build config all verified; the
  Android `intent://` bounce bug is the only thing left. Detail in `apple-login.md`.
  > **Found while doing it:** prod had **no `APPLE_CLIENT_IDS` at all** (503 on every attempt).
  > It lived only in the local `.env` and was never copied to the box — the same "prod `.env`
  > lags local" trap `deploy-aws.md` warns about. Now set, backup `.env.bak-20260731-preapple`.

### 🔲 Cutover — only after the new APK is confirmed on a phone

Deliberately **not** done yet, in this order:

- [ ] Install `nowlii-https.v0.2.apk`, confirm login + quests + a voice call all work
- [ ] Flip the HTTPS block in `~/backend/.env` (`BEHIND_TLS_PROXY`, `SECURE_SSL_REDIRECT`,
      `SESSION/CSRF_COOKIE_SECURE`, HSTS — see `nowli-backend/.env.example`) and add the
      nginx HTTP→HTTPS redirect
      > ⚠️ `SECURE_SSL_REDIRECT=True` redirects **every** insecure request, including direct
      > `:8000` ones — it would break the old APK the moment it is set. Hence: new APK first.
- [ ] Close 8000/8001 in the security group
- [ ] Then a **release** build becomes possible for the first time (cleartext no longer needed;
      still needs the upload keystore — see `deploy-aws.md`)

**This is what unblocks a real release build.** A release APK cannot use cleartext HTTP, so
today it cannot reach the backend at all — see `deploy-aws.md`.

---

## 🔲 On-device testing (nothing was tested on a phone today)

Install `nowlii-prod.v0.1.apk` (`nowli-frontend-app/build/app/outputs/flutter-apk/`).

### Scheduled calls — brand new, never run on hardware
- [ ] Quest ~6 min out with **Enable call** → reminder arrives 5 min before, naming the
      quest and its time ("…at 16:30 starts in 5 minutes")
- [ ] Tap it from a **locked screen**, and again from a **cold start** → lands on the call
- [ ] Burn both calls, then let a scheduled one come due → notification offers tomorrow, and
      the Today card shows **locked** + **Move to tomorrow**
- [ ] 1 call left + one scheduled later → swiping on Home warns first
- [ ] Deny exact-alarm permission → reminder still arrives (a little late), no crash
- [ ] Reboot with a reminder pending → it survives

### Today's other fixes
- [ ] **Delete My Account** really deletes — then confirm the same email can sign up again
- [ ] Privacy Policy link opens nowlii.com from sign-up **and** Settings → Privacy
- [ ] Nowlii says the call is nearly up ~10 s before the extension card appears
- [ ] Screen stays awake through a call, including after switching apps and back

### Carried over, still never verified on a device
- [ ] The money flow: fresh signup → trial → subscription screen → Pro screen → subscribe →
      force the paywall by backdating `trial_started_at` 8 days
- [ ] Voice: male/female matches the avatar; summary saves → **Call History**
- [ ] Insights: productive **hour** is real; "Yes, it's my rest day" un-reds the calendar

---

## 🔲 After that, in order

- [ ] **Terms of Service** — does not exist. Both links are commented out with `TODO(legal)`
      (`sign_up.dart`, `privacy_data_screen.dart`). Publish it, set
      `ApiConstants.termsOfServiceUrl`, uncomment. **P0 — the listing needs it.**
- [ ] **Tighten the token lifetimes** once the new APK is confirmed on devices:
      `JWT_ACCESS_MINUTES=60`, `JWT_REFRESH_DAYS=90` are already the defaults in code, so
      this is only a check that prod is not overriding them.
- [ ] **Email from a real sender.** Currently a personal Gmail app password. Now that
      `nowlii.com` exists: `noreply@nowlii.com` via Amazon SES (already on AWS), which needs
      SPF/DKIM records — worth doing in the same GoDaddy session as the A records above.
- [ ] **Release keystore** → then a signed build that actually works (needs HTTPS first)
- [ ] **Real payments (IAP)** — the biggest remaining product gap; `activate` is a mock and
      `verify-receipt` a 501 stub, so anyone can "subscribe" for free
- [x] **Merge `feat/realtime-voice-call` → `main`** — done 2026-07-31. A clean fast-forward (26
      commits; `main` had nothing the branch lacked), so `main` now matches what production
      actually runs. Design work continues on **`feat/design-implementation`**, branched from
      the merged `main`.

---

## ⚠️ Standing notes

- **After ever rotating `SECRET_KEY` again: tell everyone to sign out and back in.** Today's
  rotation invalidated every token and the installed build had no 401 recovery, so it sat
  there failing silently. That recovery now exists, but the advice still saves confusion.
- Rollback images on the box: `:backup-20260730`. **Images roll back; migrations do not.**
- Paywall escape hatches: `SUBSCRIPTION_ENFORCED=False`, or `SUBSCRIPTION_UNLIMITED_USERS`.
- `flutter` is not on PATH in tool shells — use `C:\src\flutter\bin\flutter.bat`.
- Disk filled to 0 bytes mid-session today. `nowli-frontend-app/build` alone was 4.2 GB and
  `~/.gradle` 12 GB; both are regenerable if space runs short again.
- Longer-term backlog in `future-checklist.md`; today's detail in
  `daily-reports/2026-07-30.md`.
