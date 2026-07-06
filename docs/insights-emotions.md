# Insights — "Top Emotions" + "When feeling low, you often say…" (plan)

_Status: **planned / not implemented** (report written 2026-07-06, to build 2026-07-07)._
_Companion to `architecture.md` (services/ports) and `technical-debt.md`._

## Goal

Add **two new sections** to the Insights screen
(`nowli-frontend-app/lib/screen/progress/insights/insights.dart`), positioned **between
the "Weekly reflection" section and "Preferred quest types"**:

1. **Top Emotions** — emotions the AI extracted from the user's voice-call conversations,
   sorted into: **happy, motivated, angry, tired, sad**.
2. **When feeling low, you often say things like:** — recurring sentences/phrases the AI
   detected across the conversations.

Both are fed by the AI from the actual call transcripts.

## What already exists (investigation, 2026-07-06)

The AI building blocks **already exist in `nowli-ai`** (`test17.py`) but are **not wired,
not persisted, and not surfaced** anywhere:

- **Emotion breakdown** — `GET /api/v1/conversation/emotion-breakdown/{session_id}`
  (`conversation_emotion_breakdown`, test17.py:1139). Returns per-emotion percentages.
  It buckets raw emotions via `_BUCKET_MAP` / `_map_to_bucket` into
  `_EMOTION_BUCKETS = ["happy", "sad", "angry", "anxious", "confused", "neutral"]`
  (test17.py:963). Uses per-turn Hume/GPT scores when available, else a GPT-4o-mini prompt
  (`_BREAKDOWN_GPT_USER`, test17.py:1038).
- **Low-mood / recurring phrases** — `GET /api/v1/conversation/low-mood-detect/{session_id}`
  (`conversation_low_mood_detect`, test17.py:1199). Returns `detected_phrases`
  (`DetectedPhrase{phrase, pattern, turn, context}`) from a rule-based scan
  (`_LOW_MOOD_PATTERNS`, test17.py:1067 — helplessness / overwhelm / avoidance /
  self-criticism / exhaustion / stress / hopelessness) **plus** a GPT-4o analysis
  (`is_low_mood`, `stress_level`, `language_patterns`, `gpt_summary`, `recommendations`).

**Gaps that make this real work (not a toggle):**

1. **Frontend never calls them.** `lib/services/ai_call_service.dart` implements only
   `createSession` + `chatStream`. No emotion-breakdown / low-mood call exists; there is no
   Dart model or service for either response.
2. **No UI.** Nothing named "Top Emotions" / "feeling low" / "often say" exists in `lib/`
   (not even commented-out). `InsightsResponse` (`lib/models/insights_models.dart`) has **no
   emotion fields**.
3. **Data is ephemeral and per-call.** `nowli-ai` sessions live in an in-memory dict
   (`_sessions`) — lost on restart, keyed by a single call's `session_id`. There is **no
   persistence and no cross-call aggregation**. The Insights screen, however, shows an
   aggregate over time and is fed by **Django** `GET /api/insights/`
   (`Apps/insights`) — which knows nothing about calls or emotions.
4. **Category mismatch.** The requested Top-Emotions categories are
   **happy, motivated, angry, tired, sad**. `nowli-ai` buckets are
   **happy, sad, angry, anxious, confused, neutral** — no `motivated` or `tired`
   (though "exhaustion" ≈ tired exists as a low-mood *pattern* label). This needs
   reconciling (extend `_BUCKET_MAP` with `motivated`/`tired` buckets, or a dedicated
   GPT prompt that returns exactly these five).

**Conclusion:** the AI *capability* is there, but surfacing it as these two Insights
sections requires wiring + persistence + aggregation + UI. Nothing can simply be
"switched on".

## Recommended implementation (for 2026-07-07)

Reuse the call-end path we already have instead of inventing a new one.

### 1. Capture at call end (frontend)
When a voice call ends we already: (a) have `_currentSession.sessionId` in `ai_voice.dart`,
(b) report the end to Django via `voice_call_service.endCall(...)`, and (c) call `nowli-ai`
`/chat/summary` from the summary screen. Add two more `nowli-ai` calls **while the session is
still in memory** (right at call end, before it's dropped):
`GET /conversation/emotion-breakdown/{sessionId}` and
`GET /conversation/low-mood-detect/{sessionId}`.

### 2. Persist to Django (backend)
Extend the existing `Apps/voice_calls` end endpoint (`POST /api/voice-calls/<id>/end/`) — or
add a small `CallAnalytics` model — to accept & store: the emotion breakdown (5 buckets) and
the detected low-mood phrases for that call, per user. (This survives `nowli-ai` restarts and
gives us history.)

### 3. Aggregate in Insights (backend)
In `Apps/insights/services.py` add, to the `weekly` (and/or `monthly`) block:
- `top_emotions`: summed/averaged emotion percentages across the period's calls, in the
  five requested categories.
- `low_mood_phrases`: the most frequently recurring detected sentences across calls
  (dedup + count, keep top N).
Add these to `Apps/insights/serializers.py` + the test fixture.

### 4. Frontend model + UI
- Extend `InsightsResponse`/`WeeklyInsights` (`lib/models/insights_models.dart`) with
  `topEmotions` + `lowMoodPhrases`.
- In `insights.dart`, add `_buildTopEmotions()` and `_buildWhenFeelingLow()` and place them
  **between** `_buildWeeklyReflection()` and where "Preferred quest types" renders (note:
  `_buildPreferredQuestTypes()` is currently called inside `_buildAIInsights()`), matching
  the existing card design (reuse the `Your mood` bar / card styles already in the file).
- Empty-state copy when there are no calls yet.

### Category reconciliation (do first)
Decide the five Top-Emotions buckets = **happy, motivated, angry, tired, sad**:
- Map `optimism/enthusiasm/determination/pride/excitement → motivated`.
- Map `exhaustion/tiredness/fatigue/sleepy → tired`.
- Keep `happy/angry/sad`; fold `anxious/confused/neutral` into the nearest of the five (or
  drop from the "top" list). Simplest: a dedicated GPT prompt that returns exactly these five
  percentages, replacing `_BREAKDOWN_GPT_USER` for this use.

## Touch list (tomorrow)
- `nowli-ai/test17.py` — (opt.) 5-category prompt/bucket reconciliation.
- `nowli-frontend-app/lib/services/ai_call_service.dart` — add the two GET calls + models.
- `nowli-frontend-app/lib/screen/ai_call/ai_voice.dart` (or the summary flow) — fetch at
  call end and hand off to Django persist.
- `nowli-backend/Apps/voice_calls/` — persist per-call analytics.
- `nowli-backend/Apps/insights/{services,serializers,tests}.py` — aggregate + expose.
- `nowli-frontend-app/lib/models/insights_models.dart` + `screen/progress/insights/insights.dart`
  — model + the two new UI sections.
