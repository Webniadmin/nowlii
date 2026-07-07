# Daily Checklist

_The single active document for the current working day. Update **only this file**
during the day. At end of day, write a report in `daily-reports/` and reset this list
for tomorrow. Deferred items go to `future-checklist.md`._

**Day:** 2026-07-08

---

## ✅ Done 2026-07-07 (carried summary — full detail in `daily-reports/2026-07-07.md`)

- **Insights "Top Emotions" + "When feeling low…"** — both sections built end-to-end (Figma 1:1),
  one GPT-free `call-insights` endpoint, `CallEmotionSnapshot`/`CallLowMoodSnapshot` persist, weekly
  aggregation, dynamic Flutter UI + empty states.
- **First real Voice Call E2E** (call 14) — full pipeline verified with real speech (STT → chat-stream
  → AI reply → TTS → snapshots → summary).
- **P0** (AI silent) — root cause = emulator mic (host audio), not code; added a "check your microphone"
  hint. **P3** (Could not load summary) — summary now falls back to default cards, no error screen.
- **Audit** — Voice Call → Insights flow verified dynamic + user-isolated; removed test seeds (user 3
  now shows only real call 14).

## 🔲 Open — pick up here next (prioritized)

### P1
- [ ] **AI persona** (`nowli-ai/test17.py` `_FRIEND_PROMPTS`) — reframe from casual "friend" to a Nowli
      **wellbeing / reflective / empathetic companion** (asks questions, helps explore feelings; not a
      generic chatbot). Fix the `neutral` "don't sound like a helper" line. Also pass the user's real
      companion name instead of hardcoded "Aria" (`ai_voice.dart _createAiSession` + backend).
      Cheap (prompt edit), high product impact. Analysis in `daily-reports/2026-07-07.md`.
- [ ] **P2 — Voice Call timeout UI to Figma** — implement the 3 frames (Adding 2.5 min `364-15969`,
      Added 2.5 min `364-15790`, Less than 1 minute `364-15945`). **Blocked** while the Figma MCP
      rate limit is active — retry the fetch first. Touch: `_buildOneMinuteWarning` /
      `_buildThirtySecWarning` / `_buildCountdownNotice` (+ maybe an "Added" state) in `ai_voice.dart`.

### P2
- [ ] **Barge-in / interrupt** — let the user interrupt the AI: STT listens during TTS, on real speech
      `flutterTts.stop()` + clear queue + reset flags → normal send. Guard against echo/self-trigger;
      test on device. `ai_voice.dart`.
- [ ] **Replace placeholder "What this means"** (both Insights sections) with a real AI summary
      (`Apps/insights/services.py` `TODO(insights-emotions)`); keep off the Insights-load hot path or cache.

### P3 / housekeeping
- [ ] **Commit** all the Voice Call + Insights work (implemented + E2E-verified, not committed).
- [ ] **"Your mood" weekly bars** (`insights.dart:980–1035`) — hardcoded demo; needs a new per-day
      backend source to become dynamic (separate task, new API field).
- [ ] (Optional) Persist Call Summary; clean throwaway test user `rt_live_test` (user 4) snapshots.

## 📝 Notes
- **Emulator mic is required for Voice Call** — Extended controls → Microphone → "Virtual microphone
  uses host audio input" (else `error_speech_timeout`, AI stays silent). Now in `running-on-android.md`.
- Daily call limit is per-user 2/day (UTC reset) — user 3 hit 2/2 on 2026-07-07.
- Longer-term backlog in `future-checklist.md`.
