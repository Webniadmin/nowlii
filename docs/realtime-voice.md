# NOWLII — Realtime Voice Call (OpenAI Realtime API over WebRTC)

_Added 2026-07-22. The AI voice call was re-architected from the old speech-to-text → GPT → text-to-speech
pipeline to **OpenAI Realtime API speech-to-speech over WebRTC** for a smooth, ChatGPT-voice-like experience
with native server-VAD turn-taking and barge-in._

## Why

The old pipeline (`speech_to_text` → SSE `/chat-stream` → `flutter_tts`) turned a transcript into a
conversation with client-side turn-taking heuristics. It felt laggy and "push-pull", and without echo
cancellation the AI kept interrupting itself. The OpenAI Realtime API does speech-to-speech with **server-side
VAD, native interruption, and low latency** — the same tech ChatGPT voice mode uses.

## Architecture

```
Flutter (WebRTC)  ──① POST /api/v1/realtime/token ─────▶  nowli-ai  ──▶ OpenAI /v1/realtime/client_secrets
       │                                                      (persona + voice + server_vad + transcription)
       │◀───────────── ephemeral token (ek_…) + sdp_url ──────┘
       │
       ├──② mic (getUserMedia, WebRTC AEC) ──▶ OpenAI Realtime ──▶ model audio ──▶ speaker
       │    data channel "oai-events": transcripts, speech start/stop, response.done
       │
       └──③ at call end: POST /api/v1/session/turns (collected transcript)  ──▶ nowli-ai session.turns
            then the existing /chat/summary + /conversation/* insights work unchanged.
```

- **The real OpenAI key never reaches the client.** The backend mints a short-lived ephemeral token; the app
  only ever sees `ek_…`.
- **Summary/emotions preserved:** the Realtime conversation happens client↔OpenAI directly, so nowli-ai never
  sees it. The app collects the transcript (data-channel events) and POSTs it to `/api/v1/session/turns` at
  call end, which populates `session.turns` — so `/chat/summary`, `/conversation/emotion-breakdown`,
  `/conversation/low-mood-detect`, `/conversation/call-insights` all keep working exactly as before.

## Backend — `nowli-ai/test17.py`

- **`POST /api/v1/realtime/token`** `{session_id}` → mints the ephemeral session via OpenAI
  `/v1/realtime/client_secrets` with: model `REALTIME_MODEL` (`gpt-realtime-mini`), voice `REALTIME_VOICE`
  (`marin`), input transcription (`gpt-4o-mini-transcribe`), `turn_detection: server_vad`
  (`interrupt_response: true`), and the persona from `_realtime_instructions(session)`. Returns
  `{client_secret, expires_at, model, voice, sdp_url, user_name, system_name}`.
- **`POST /api/v1/session/turns`** `{session_id, turns:[{user_message, ai_reply}]}` → replaces `session.turns`
  so the summary/insight endpoints have the conversation.
- **Persona:** `_REALTIME_PERSONA_EN` — a calm, professional psychological-companion (speaks slowly/softly,
  validates feelings first, doesn't rush to fix, one gentle question at a time, gentle crisis-safety line).
  Only the Realtime path uses it (via `_realtime_instructions`); the original `_FRIEND_PROMPTS` /
  `_build_system_prompt` persona (text/SSE path) is **untouched**.
- **Env knobs:** `REALTIME_MODEL`, `REALTIME_VOICE`, `REALTIME_TRANSCRIBE_MODEL`.

## Frontend — `nowli-frontend-app`

- **`lib/services/realtime_call_service.dart`** — the WebRTC engine: token fetch → `RTCPeerConnection` →
  mic (`getUserMedia`, WebRTC AEC) → data channel `oai-events` → SDP exchange → transcript/greeting/turn
  events. Callbacks (`onAiSpeakingChange`, `onUserSpeakingChange`, `onAssistantText`, `onUserText`) drive the
  UI. `flushTranscript()` posts turns at call end; `sendUserText()` seeds quest context / typed input;
  `greet()` opens the conversation; `setMuted()` mutes the mic track.
- **`lib/screen/ai_call/ai_voice.dart`** — the SAME call screen (design/timer/extension/quest-complete/
  daily-limit/summary all unchanged) with the audio engine swapped behind `bool _useRealtime = true`
  (flip to `false` to fall back to the old STT/TTS pipeline, which is kept). Adds: a **Connecting…** overlay
  (`_buildConnectingOverlay`) until Nowlii's first words; the **timer starts on her first speech**
  (`_onRealtimeStarted`, 8s fallback) so timed duration = real conversation; mic button = mute toggle;
  keyboard button routes typed text to `_realtime.sendUserText`.
- **Android config** (`android/app/…`): `minSdk 23`; permissions `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`,
  **`ACCESS_NETWORK_STATE`**, `CHANGE_NETWORK_STATE`.

## Two crash/bug fixes that were required (don't remove them)

1. **`ACCESS_NETWORK_STATE` permission** — flutter_webrtc/libjingle queries network state at startup and
   **crashes natively** without it (`SecurityException` in `jvm.cc` → SIGABRT → "app closed"). This was the
   crash on the physical phone. It affects **every** device.
2. **SDP POST must not include `?model=`** — the SDP exchange goes to `https://api.openai.com/v1/realtime/calls`
   with the ephemeral token; the model is already bound to the token, so adding `?model=` returns **HTTP 409
   Conflict**. Post to the bare `sdp_url`.

Also required: request mic permission before `getUserMedia` (WebRTC doesn't prompt), a short settle delay
after the grant, and capture the mic before creating the peer connection.

## Build & test the APK

```powershell
cd nowli-frontend-app
flutter build apk --debug --dart-define-from-file=<aws-defines.json>   # BASE_URL/AI_BASE_URL = 16.170.191.239
# APK: build/app/outputs/flutter-apk/app-debug.apk
```
Debug build (cleartext HTTP is allowed only in debug; release is HTTPS-only). On the phone: install → start a
call → **Allow** the mic → Nowlii greets you.

**Fast WebRTC repro without login:** a temp `lib/main_rt_test.dart` that calls `RealtimeCallService.connect()`
directly + `flutter run -t lib/main_rt_test.dart -d <emulator>` + `adb logcat` isolates the native crash (the
`/realtime/token` endpoint needs no auth). This is how the `ACCESS_NETWORK_STATE` crash was found.

## Rollback

- **Voice:** set `REALTIME_VOICE` (env) — e.g. `shimmer` (softest), `coral` (warmer), `alloy` (original).
  All of shimmer/coral/sage/marin/cedar/alloy work on `gpt-realtime-mini`.
- **Persona:** point `realtime_token`'s `instructions` back to
  `_build_system_prompt("neutral", session.user_name, session.system_name, session.language)`.
- **Whole feature:** set `_useRealtime = false` in `ai_voice.dart` → the old STT/TTS pipeline returns.

## Deploy note (important)

The Django and nowli-ai changes were **host-patched directly on EC2** (files edited on the box, then
`docker compose build && up -d`), so the server is **divergent from git**. The local repo has the same changes
(committed on `feat/realtime-voice-call`). A future `git archive`-based redeploy (`deploy-aws.md`) will only
carry these once the branch is merged and re-deployed. Server backups: `~/ai/test17.py.bak-*`,
`~/backend/*.bak-*`, `~/backend/.env.bak-email`.

## Cost controls (added 2026-07-23 — deployed to EC2)

A few test calls billed ~$16–20 **each**. The server was **already on `gpt-realtime-mini`** (the cheapest
realtime model — the `.env` had no `REALTIME_MODEL`, so it used the code default), so the blow-up was NOT the
model. It was the uncapped, noise-amplified session: no reply cap + a low VAD threshold that let background
noise fire spurious responses, each re-billing the growing (audio) conversation. Fixes in `realtime_token`'s
session payload (`test17.py`), all env-tunable:

- `max_output_tokens=1024` (`REALTIME_MAX_OUTPUT_TOKENS`) — caps each spoken reply.
- `audio.input.noise_reduction={"type":"near_field"}` — filters room noise before VAD.
- `turn_detection.threshold` `0.5 → 0.7` (`REALTIME_VAD_THRESHOLD`) — only real speech triggers/interrupts;
  `interrupt_response` stays on so genuine barge-in still works.
- `turn_detection.silence_duration_ms` `500 → 400` (`REALTIME_SILENCE_MS`) — snappier turn-taking, no cost
  impact (still long enough not to chop mid-sentence pauses into extra turns).
- `~/ai/.env` on EC2 now pins `REALTIME_MODEL=gpt-realtime-mini` explicitly (backup `~/ai/.env.bak-realtime-cost-*`).

Estimated after-cost on mini with these caps: **~$0.03 per minute of talk** + **~$0.03 one-time summary** →
a full 5+2.5 min call ≈ **$0.25** (was ~$16–20). Verify actual spend in the OpenAI usage dashboard.
Deployed via the `deploy-aws.md` `git archive HEAD:nowli-ai` flow (commit on `feat/realtime-voice-call`).

## Known follow-ups (see `next-phase.md` → 2026-07-22 TO-DO)

1. Keep the screen awake on the call screen (screen lock drops the WebRTC connection).
2. ~~Small noise makes the AI restart talking — raise `turn_detection.threshold` / add input noise reduction.~~
   **Done 2026-07-23** (see Cost controls above).
3. Dynamic emotion emoji in the call summary (currently a static smiley).
4. Optional further saving: `LLM_MODEL=gpt-4o` drives the end-of-call summary/insights; switching to
   `gpt-4o-mini` would cut that (already-small) cost ~10× — decide vs. summary quality.
