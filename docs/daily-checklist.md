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

### Then
- [ ] Merge `feat/realtime-voice-call` → `main` (it is 10 commits ahead; a deploy from `main`
      today would be a regression).

## ⚠️ Blockers / decisions needed

- **No real money yet.** `activate` is a mock and `verify-receipt` is a 501 stub — anyone can
  "subscribe" for free. Phase 2 (Apple IAP / Google Play Billing) is the next subscriptions task.
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
