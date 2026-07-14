# Voice-check popup & scheduled calls — status + open decisions

_Created 2026-07-10. Captures the designer's "Voice Check" spec, what actually exists in the
codebase, and the decisions taken so far, so nothing is lost while these are deferred._

## TL;DR (current state)
- **Scheduled calls do NOT exist** anywhere in the app (no backend model, no reminder times,
  no scheduling job; frontend has **no** local-notification/scheduling packages). The
  `reminder_notification/ai_call_reminder/*` screens are static mockups; `my_quests/scheduled/`
  is scheduled **quests** (by date), not calls.
- The **voice-check popup was a mock** (recorded/sent nothing; a 2s delay + a fake "Your voice
  note is saved" toast). On 2026-07-10 it was removed from the swipe→call path and the screens
  were preserved in `lib/experimental/emotion_share_flow/` (see `cleanup-log.md`). Swipe now
  goes straight to the real 5-min AI call.

## Decisions (2026-07-10)
- **Scheduled calls → PENDING CLIENT.** Do not build yet; ask the client whether the product
  wants scheduled calls at all. Marked open.
- **Voice-note / voice-check → DEFERRED.** The 5-min AI call already does real STT + emotion
  detection + journaling, so a separate async voice-note is not needed for now. Revisit only if
  the client wants a lightweight async reflection. Experimental screens remain as a starting point.

## Designer's spec (verbatim, for reference)
> Voice Check popup before the call. A lightweight voice-based reflection popup, appearing
> before scheduled calls or when users skip multiple sessions. Goal: let the user express their
> mood via short voice input, captured and stored for AI analysis (emotion detection, tone
> tracking, journaling).
>
> **Appears:** 10 min before a scheduled call (as a "quick note" option). Dismiss via top-left ❌
> (does not affect streaks).
> **Hold to record:** mic activates; hint "Nowlii will listen once you say something."; pulse
> animation around Fuzzy while mic active; mic stays active until release; audio stored locally
> as a temp file.
> **Screen 4 — Error state:** no voice after 2s silence → Fuzzy neutral; copy "You didn't say
> anything? Hold and speak again."; button reverts to "Hold to speak 🎙"; no backend call.
> **Screen 5 — Processing state:** on stop → loading dots (~2s) → upload
> `POST /api/v1/voice-note` payload `{ user_id, timestamp, audio_file, mood_context }` → on
> success, fade out and return Home.
> **Edge cases:** no mic permission → permission modal ("Nowlii needs microphone access to
> record your voice notes."); if denied → toast "That's okay — we can always talk later 💜."

## What building each for real would require

### A) Scheduled calls (prerequisite for the spec's main trigger)
- **Backend:** a scheduled-call/reminder model (per-user time(s), timezone, enabled), CRUD API.
- **Frontend:** add `flutter_local_notifications` + `timezone`; schedule local notifications;
  a settings UI to pick call times; deep-link the notification into the call / voice-check.
- Consider DST / timezone correctness and Android 13+ notification permission.

### B) Voice-note endpoint + wiring (the popup itself)
- **nowli-ai:** new `POST /api/v1/voice-note` — accept the audio file + `{user_id, timestamp,
  mood_context}`, store it, run emotion detection, return success. (Sessions are in-memory today;
  decide on real storage for the audio/analysis.)
- **Frontend:** wire the preserved `experimental/emotion_share_flow/` screens to **real**
  recording (hold-to-record, 2s-silence error state, upload with the processing state) instead
  of the current simulated delay; handle mic-permission edge cases (Android + iOS).
- **Overlap check:** make the value vs. the 5-min call explicit (async note vs. live call) so the
  two features don't confuse users.
