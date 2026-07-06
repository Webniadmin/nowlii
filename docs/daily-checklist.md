# Daily Checklist

_The single active document for the current working day. Update **only this file**
during the day. At end of day, write a report in `daily-reports/` and reset this list
for tomorrow. Deferred items go to `future-checklist.md`._

**Day:** 2026-07-06

**Feature in focus:** AI Voice Call — daily limit + max duration + in-call warnings

Business rules (confirmed):
- Max **2 AI calls per user per day**, per-user (never global), **backend authoritative**.
- Each call **5 minutes** initially; **one** optional **+2.5 min** extension → **7.5 min** max.
- Daily counter resets at **00:00** (date-based query, no cron).
- In-call notices: on connect "max 5 min"; at 4:00 "1 minute left" + "Add 2.5 minutes"
  (once); at 4:30 "30 seconds left" (if not extended); last 10s countdown; auto-end at
  expiry. When extended, warnings adapt to the 7.5-min maximum.
- Reuse the existing in-call notification style; no new visual patterns.

---

## ✅ Done

- [x] Analyze the existing AI Voice Call implementation (frontend + AI service + backend)
- [x] Define solution architecture (backend authoritative for the daily count; frontend
      owns the real-time timer/warnings; date-based reset; UTC day boundary noted)
- [x] Backend: new `Apps/voice_calls` — `VoiceCall` model + migration
- [x] Backend: `GET quota`, `POST start` (429 on limit, per-user race lock),
      `POST <id>/end`, wired at `/api/voice-calls/`, admin, `VOICE_CALL_DAILY_LIMIT` setting
- [x] Frontend: `voice_call_service.dart` + endpoint constants
- [x] Frontend: gate the call on the backend, start notice, 1-min + Add-2.5-min (once),
      30s warning, last-10s countdown, auto-end, extension adapts warnings, end reported
- [x] Removed the old unlimited "Add 5 minutes" extension (conflicted with the hard cap)
- [x] Verified: backend logic (quota 2→0, 3rd call 429, end idempotent, cross-user 404,
      date-based reset), `manage.py check` clean, `flutter analyze` 0 errors
- [x] Logged findings in `docs/technical-debt.md`

## ⏭️ Next

- [ ] End-of-day report in `docs/daily-reports/2026-07-06.md`
- [ ] Single git commit for the feature
- [ ] (Next session) On-device smoke test of the full call flow on Android

## 📝 Notes

- Timezone of the daily window is UTC (server) — see `technical-debt.md` TD-002 if
  user-local reset is required.
- The AI chat service (`nowli-ai` :8001) is still unauthenticated — the limit is enforced
  in the app flow but not attack-proof at that service (TD-001).
