# Daily Checklist

_The single active document for the current working day. Update **only this file**
during the day. At end of day, write a report in `daily-reports/` and reset this list
for tomorrow. Deferred items go to `future-checklist.md`._

**Day:** 2026-07-31

---

## ⛔ BLOCKED ON YOU — two things, everything else waits on them

Both are outside the codebase. Neither takes more than a few minutes.

### 1. DNS records at **GoDaddy** (not Cloudflare, not Figma)

Checked with the authoritative nameservers (`ns41/ns42.domaincontrol.com`): `api.nowlii.com`
returns **NXDOMAIN** — the name does not exist in the zone, under any spelling. Also checked
`ai`, `www.api`, `api.www`, `www.ai`, `backend`, `api-nowlii`: nothing. This is **not** slow
propagation; propagation would show the record at the authoritative server first.

The zone today holds only `www → sites.figma.net` and `nowlii.com → 204.69.207.1` (parking).
**If the record was added in Figma or Cloudflare it has no effect** — only GoDaddy is
authoritative for this domain.

GoDaddy → My Products → `nowlii.com` → **DNS** → Add New Record, twice:

| Type | Name | Value | TTL |
|---|---|---|---|
| A | `api` | `16.170.191.239` | 600 |
| A | `ai` | `16.170.191.239` | 600 |

`Name` is just `api` / `ai` — GoDaddy appends the domain itself.
Two subdomains, not one, so the app's paths stay unchanged: Django is on `:8000`, `nowli-ai`
on `:8001`. Verify at https://dnschecker.org/#A/api.nowlii.com

### 2. AWS security group — open 80 and 443

Confirmed from outside: **80 and 443 are closed**, only 8000/8001 are reachable. Certbot
proves domain ownership over port 80, so it cannot issue a certificate until this is open.

EC2 → instance `i-0c053bc7fea33f0df` → Security → the security group → Edit inbound rules:
HTTP/80 and HTTPS/443, source `0.0.0.0/0`.

⚠️ **Leave 8000 and 8001 open for now.** The current APK points at
`http://16.170.191.239:8000`; closing them before the HTTPS switch would cut the phone off.

---

## 🔲 Then — HTTPS, and the release blocker it removes

Once the two above are done, this is mine and runs end to end:

- [ ] Verify the records resolve to the box
- [ ] nginx + certbot; certificates for both subdomains
- [ ] Proxy `api.nowlii.com → :8000`, `ai.nowlii.com → :8001`
- [ ] Flip the HTTPS block in `~/backend/.env` (`BEHIND_TLS_PROXY`, `SECURE_SSL_REDIRECT`,
      `SESSION/CSRF_COOKIE_SECURE`, HSTS — see `nowli-backend/.env.example`) and extend
      `ALLOWED_HOSTS` + `CSRF_TRUSTED_ORIGINS`
- [ ] `dart_defines.prod.json` → `https://`, new APK
- [ ] Only after the new APK is confirmed working: close 8000/8001

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
- [ ] Merge `feat/realtime-voice-call` → `main` (16 commits ahead)

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
