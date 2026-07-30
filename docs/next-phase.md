# NOWLII — Next Phase (planned work)

_Created 2026-07-01 for the next session. **Do cleanup before any new features.**_
_Companion to `architecture.md` (how things fit) and `project-status.md` (current state)._

Each task lists **What to do**, **Files likely touched**, and **Gotchas/blockers**.
References verified against the codebase on 2026-07-01.

---

## ▶ START HERE (2026-07-31)

**Two things block everything, and both are outside the code:** the `api`/`ai` A records at
**GoDaddy** (checked against the authoritative nameservers — `NXDOMAIN`, so the record was
never saved to that zone; adding it in Figma or Cloudflare has no effect), and **ports 80/443
in the AWS security group** (confirmed closed, so certbot cannot issue). Exact steps in
`daily-checklist.md`.

Once those land: nginx + certbot → HTTPS on both subdomains → new APK → close 8000/8001.
That is what removes the release blocker — a release build cannot use cleartext HTTP, so
today it cannot reach the backend at all.

Nothing was tested on a device on 2026-07-30. Scheduled-call reminders especially can only be
proven there. Full day detail: `daily-reports/2026-07-30.md`.

---

## ▶ RESUME HERE (2026-07-30) — production hardening + the real road to release

**The headline: "production ready" has one blocker in front of everything else, and it is a
domain.** A release APK cannot talk to the backend at all — Android has blocked cleartext HTTP
since API 28, `usesCleartextTraffic` lives only in the *debug* manifest, and prod is
`http://16.170.191.239:8000`. So a signed release build launches and then fails every request.
Play separately rejects cleartext credential traffic, so widening the manifest just swaps one
blocker for another. Ordered path: **domain + TLS → signed build that works → real IAP** (IAP can
only be tested through a signed build on an internal testing track). Detail in `deploy-aws.md`
→ "A release build cannot talk to production today".

**Shipped today** (full list in `daily-checklist.md`):
- `SECRET_KEY` is now enforced in production — the app refuses to boot on a weak key (Django's own
  `W009` thresholds). Both the local and the box `.env` currently fail it.
- HTTPS settings added as env switches, **all defaulting off** on purpose — turning on secure-only
  cookies without TLS in front would lock everyone out of the admin. Flip them with the domain.
  `SECURE_PROXY_SSL_HEADER` no longer trusts `X-Forwarded-Proto` unconditionally.
- **Real vulnerability fixed:** `NowliiPredefinedOptionViewSet` was `AllowAny` on a full
  `ModelViewSet` — any anonymous caller could rename or DELETE every companion avatar. Now
  read-public / write-admin, with 8 tests (confirmed they fail against the old code).
- DRF default permission `AllowAny` → `IsAuthenticated` (fail closed). Audited first: every existing
  view already sets its own, so behaviour is unchanged.
- **`nowli-ai` `/api/v1/` now requires the caller's Django token**, verified locally with the same
  HS256 secret. It mints OpenAI Realtime keys, so it was previously a direct route to the OpenAI
  bill for anyone who knew the IP — which matters given the 07-23 key leak. Auth stays **off** when
  `NOWLII_JWT_SECRET` is unset, so the deploy can be staged.
- Full JWTs are no longer printed to logcat (3 files); Android release signing wired via
  `key.properties`; `.env.example` written for both services.

⚠️ **Before the next deploy:** `SECRET_KEY` on `~/backend/.env` (else the container crash-loops) and
`NOWLII_JWT_SECRET` on `~/ai/.env`. See the STOP box at the top of `deploy-aws.md` — it includes the
safe staging order so an old app build doesn't start getting 401s.

---

## ✅ TOMORROW (2026-07-30) — do in this order

**Everything through the paywall is committed AND deployed to EC2. Tomorrow is device testing.**
The day-by-day list lives in **`daily-checklist.md`** — this is the summary.

1. **On-phone verification with the 2026-07-29 debug APK** (built against live AWS).
   ⚠️ **Use a NEW account** — `pavle` is on the paywall allowlist and staff are exempt, so neither
   will ever see the trial or the block.
   - **The money flow (never tested on a device):** fresh signup → full access + the "7 days free"
     screen once → subscription screen shows days left and the real price boxes → Pro screen shows
     one plan + the billing explainer → subscribe works. Then **force the paywall**: in Django admin
     set that user's `trial_started_at` back 8 days, restart the app → it must land on the Pro screen
     and refuse to go anywhere else; subscribing must let them back in.
   - **Carried over from the morning deploy:** male vs female voice matches the avatar; persona isn't
     "moody"; screen stays awake on a long call; summary → **Call History**; Insights productive
     **hour** is real; "Yes, it's my rest day" drops the day from "skipped" and un-reds the calendar.

2. **Merge `feat/realtime-voice-call` → `main`.** It is 10 commits ahead; deploying from `main`
   today would be a regression.

3. **Decide the two open voice questions** (see `realtime-voice-gender-persona` memory):
   - Existing users default to **Male** until they re-pick an avatar or use the selector — OK, or backfill?
   - Confirm the female-voice avatar assignments (`bloop/fizzy/zee/cloudy/glowy`) match the intended art.

4. **Then the real backlog** (biggest first):
   - **Subscriptions Phase 2 — real IAP.** This is now the top gap: the paywall is enforced but
     `activate` is a mock and `verify-receipt` is a 501 stub, so **anyone can "subscribe" for free**.
     Needs the `in_app_purchase` plugin, per-phase products in App Store Connect / Play Console, and
     backend receipt verification feeding the existing lifecycle engine.
   - **Prod hardening** — fresh Django `SECRET_KEY` (still the dev `django-insecure-…`), HTTPS/domain
     + signing before any Play/release build.
   - **Apple Sign-In** — needs a permanent HTTPS URL (temp trycloudflare tunnel) before any device build.
   - **Scheduled AI calls** — **blocked on the client**, do not start. Confirmed 2026-07-29 that
     nothing exists: no notification/scheduling package, no backend reminder model, and `set_alarm`
     is stored but drives nothing (hardcoded `true` on create). "Enable call" only shows an on-demand
     button. Design notes in `voice-check-and-scheduling.md` §A.
   - ~~**Insights 500 → graceful fallback**~~ ✅ **done** (`cc29803`).
   - ~~**Wire the "Let's begin 7 days free" button / reconcile Pro pricing / enforce gating**~~
     ✅ **done** (`6e420d6`).

### Nice-to-haves noticed while working (not blockers)
- Streak-card old asset `120Days.png` is now unused (kept, not deleted).
- The `Quests` model has **no completion timestamp** — "most productive hour" uses `select_a_time`
  (scheduled time) as a proxy. If real completion-time analytics are wanted later, add a `completed_at`.
- Rest-day exclusion is by **weekday** (recurring), not a one-off date — fine for the current UX.
- The legacy `CustomUserModel.paid_user` / `current_plan` fields are now definitively dead — the live
  model is `Apps/subscriptions`. Worth removing in a cleanup pass.
- Local `.env` OpenAI key is invalid (401) since the 07-23 rotation; prod is fine.

---

## ▶ RESUME HERE (2026-07-29, latest) — 7-day free trial + real paywall

The "7 days free → then buy Pro" flow now exists end to end. It previously existed only as
artwork: the button was `onPressed: () { // Start trial logic }`, the backend had no trial concept
at all (`grep -i trial` = 0 hits), and `user_has_pro()` was never called — so **every user had the
whole app free, forever**. Commit `6e420d6`.

**How it works now**
- Trial is granted **automatically on the user's first authenticated request** — install + login
  starts the 7 days, nothing to tap. Granted once; never extended or re-granted.
- `Subscription.started_at` is now **nullable**: the paid year starts the day someone actually
  subscribes, not when their trial began (so nobody loses a week of month-1 pricing).
- Enforcement is `subscriptions/permissions.HasProAccess` → **402 `subscription_required`** on
  quests / subtasks / insights / voice-calls. **402, not 403**, so the app routes to the paywall
  instead of bouncing to login. Auth / profile / subscriptions / support stay open — a blocked user
  must still be able to log in, pay and reach support.
- Escape hatches: `SUBSCRIPTION_ENFORCED=False` (kill switch) and `SUBSCRIPTION_UNLIMITED_USERS`
  (default `pavle`); staff/superusers always exempt.
- Frontend: entitlement cached in prefs for the router guard (**defaults to allow** — a slow status
  call must never lock a paying user out; the backend 402 is the real gate). Splash refreshes it,
  shows the "7 days free" screen once, and sends expired users to the paywall.

**Pricing UI conflict resolved:** the Pro screen's hardcoded **Yearly $25.99 / $2.66-mo** cards are
gone. No yearly product exists in the backend, and `_subscribe()` ignored the selection entirely —
tapping "Yearly" silently started the monthly plan. One plan now, prices from `/subscriptions/plan/`,
and the "How billing works" explainer (19.99 → 14.99 → 9.99 → 4.99 → free after month 12) is a
shared widget on **both** the trial screen and the Pro screen.

**Verified:** 25 `Apps.subscriptions` tests (was 8), 44 total; a live end-to-end run on the real URLs
(trial → app open → expiry → 402 everywhere → purchase → access back → price steps down to free at
month 13); `flutter analyze` 0 errors.

> ⚠️ **Still no real money.** `activate` is a mock and `verify-receipt` is a 501 stub — anyone can
> "subscribe" for free. Phase 2 (Apple IAP / Google Play Billing) is the next subscriptions task.
> **Not deployed to EC2 yet** — needs `subscriptions.0002` migration.

---

## ▶ RESUME HERE (2026-07-29, later) — Insights no longer 500s when the AI is down

`GET /api/insights/` returned 500/502/503 on any AI failure, so the OpenAI quota error blanked the
**whole** Insights + Progress screen — even though only `ai_reflections` / `quest_suggestions` need
the AI (streak, rings, calendar, emotions, mood chart are all real DB analytics). The Flutter
`InsightsService.getInsights()` returns `null` on any non-200, so one failed AI call = empty screen.

Now each AI block degrades independently and the response is still **200**:
- `services.build_fallback_reflections()` — 3 sentences from the user's real weekly numbers
  (completion + %, strongest zone, skipped days). Handles empty / perfect weeks.
- `services.build_fallback_quest_suggestions()` — 5 static suggestions matched to the time of day,
  biased toward Soft steps after a rough week. **Night is deliberately all-gentle** (no Power move
  at 23:00), unlike the AI prompt's zone-variety rule.
- New top-level **`ai_degraded`** boolean so a fallback is never mistaken for real AI output. The
  Flutter model ignores unknown keys, so **no frontend change was needed**.
- Fallbacks are **never cached** (stored as `[]`) → the next load retries the AI. A partial failure
  keeps the half that worked. _Real bug found by the new tests: a successful emotion-meaning pass set
  `cache_dirty` and cached the fallback reflections._
- Each generator is now called only when actually missing (the old code regenerated both whenever
  either was absent — a wasted GPT call on every partial cache hit).
- **20 s provider timeout + 1 retry** (`AI_REQUEST_TIMEOUT`, env-tunable). The OpenAI/Anthropic SDKs
  default to **600 s**, so a hanging provider would have left the app spinning instead of falling back.
- Test hygiene: view tests were making **live Anthropic calls** (`generate_emotion_meaning` unmocked)
  — now stubbed; suite runs in ~4 s offline.

Verified: 19 `Apps.insights` tests (was 15) pass, 27 across insights+subscriptions+quests,
`manage.py check` clean, fallback copy eyeballed against the local DB. Commit `cc29803`.
**Not deployed** — ships with the branch deploy (step 1 above).

---

## ▶ RESUME HERE (2026-07-29) — Progress/Insights made production-dynamic

Made the Progress + Insights screens fully dynamic (no more faked/hardcoded data):
- **Most productive HOUR** — now computed in `insights/services.py` (`get_monthly_analytics`) from
  `Quests.select_a_time` (weighted by completion, like the day), serialized as
  `most_productive_hour`, shown in the Insights "Hour" tile (was hardcoded `10:00`). Frontend model
  `MonthlyInsights.mostProductiveHour`; empty → `—`.
- **Rest-day button works + persists** — new `Profile.rest_days` JSONField (migration
  `users.0015_profile_rest_days`) + `POST/GET /api/insights/rest-days/` (`RestDaysView`, add/remove/set,
  weekday-validated). Weekly `skipped_days` AND the calendar now exclude rest days (a marked day off
  is `none`, not `skipped`). Frontend: `InsightsService.markRestDays()`, the "Yes, it's my rest day"
  button now taps → posts the skipped days → reloads; hidden when there are none.
- **Skipped-days text dynamic** — reads `weekly.skipped_days` (was hardcoded "Sundays"); positive
  fallback when none.
- **"Your moves" rings** — fill = real `completed/assigned` (was fixed 0.75/1.0).
- **"% to 30 days"** — now real `streak/30` (was this-week's `completedDays/7`, mislabeled).
- **Streak card** — replaced fixed `120Days.png` background with **milestone-tier gradient logic**
  (`_streakGradient` + `_streakMilestones`); subtitle shows days-to-next-badge; added a real progress
  bar toward the next milestone. `my_progress.dart`.

Verified: insights end-to-end test (hour=14:00, rest-day drops the skip + flips calendar to none),
all 8 `Apps.insights` tests pass, `flutter analyze` clean. **Migrations `0015` (rest_days) not yet on
EC2.**

---

## ▶ RESUME HERE (2026-07-28)

**Done today: persist each voice call's conversational summary in the DB, per user** (was the
top 2026-07-24 TODO below). Key finding that changed the plan: the summary **GPT-4o pass already
happens at call end** — the `CallSummaryScreen` fetches `/api/v1/chat/summary` to display it, then
threw it away. So we persist that already-fetched summary with **zero extra GPT cost** (no double
pay), from the summary screen where it's created + displayed.

**What shipped:**
- **Backend** (`Apps/voice_calls/`): new **`CallSummary`** model (OneToOne→`VoiceCall`, denormalized
  `user` FK like `CallEmotionSnapshot`; fields `mood_detected`/`focus_topic`/`energy_shift`/
  `next_step`, `dominant_emotion`, `top_emotions` JSON, `language`, `total_turns`). Migration
  `0004_callsummary` applied. Endpoints: **`POST /api/voice-calls/<id>/summary/`** (idempotent
  upsert) + **`GET /api/voice-calls/summaries/`** (the user's saved summaries, newest first — for
  reviewing progress over time). Registered in admin. Serializer `CallSummarySerializer`.
- **Frontend**: `callId` threaded into `CallSummaryScreen` via the route (`ai_voice.dart`
  `_callSummaryRoute()`); after `getSummary()` the screen calls `VoiceCallService.saveSummary()` to
  persist it (best-effort, fire-and-forget). New `voiceCallSummary(id)` / `voiceCallSummaries` in
  `api_constant.dart`.
- **Verified**: backend end-to-end test (201 create → 200 upsert single row → GET list → 400 on empty
  → 404 cross-user); `flutter analyze` clean (only pre-existing info lints).

**Not yet deployed to EC2** — changes are local on `feat/realtime-voice-call`. Redeploy the backend
(migration runs via `entrypoint.sh`) when pushing this branch.

**Also shipped 2026-07-28 (5-item batch):**
1. **Call history screen** — `GET /summaries/` is now consumed. New `CallHistoryScreen`
   (`lib/screen/ai_call/call_history_screen.dart`, route `callHistory`) + `CallSummaryHistoryItem`
   model + `VoiceCallService.getSummaries()`; entered via a "Call history" card at the top of the
   Insights tab (`insights.dart` `_buildCallHistoryEntry`).
2. **Wakelock on the call screen** — `wakelock_plus` added; `WakelockPlus.enable()` in
   `ai_voice.dart` initState, `disable()` in dispose (screen no longer sleeps mid-call → WebRTC
   won't drop).
3. **Dynamic emotion emoji** — the call-summary avatar icon + colour now reflect `dominant_emotion`
   (`call_summary_screen.dart` `_emotionIcon`/`_emotionColor`).
4. **Male/female voice per companion** — the Realtime voice is chosen from `Profile.voice`
   (Male→`cedar`, Female→`marin`, both env-overridable `REALTIME_VOICE_MALE`/`_FEMALE`). Wired
   nowli-ai `session/new` (`voice`) → `Session.voice_gender` → `realtime_token`; frontend
   `createSession(voice:)` reads the profile; **the Voice & Personality selector now actually
   persists** the choice (local cache + backend) — it was a no-op SnackBar before.

   **Update — voice is now AVATAR-driven.** `NowliiPredefinedOption` got a `voice` field
   (Male/Female, default Male, admin-editable inline). `Profile.save()` adopts the chosen
   companion's voice **on companion change** (manual selector still overrides). Migrations
   `users.0013_nowliipredefinedoption_voice` + `0014_seed_companion_voices` (bloop/fizzy/zee/
   cloudy/glowy = Female, rest Male). ⚠️ Existing users only get the avatar's voice when they
   re-pick an avatar (or use the selector); default Male.

6. **Swipe-to-talk name reverted to fixed "Fuzzy"** — `home_screen.dart` `_buildSwipeButton`
   no longer passes the dynamic companion name; the label is always "Swipe to talk to Fuzzy".
5. **More neutral AI persona** — `_REALTIME_PERSONA_EN` rewritten to NOT assume/label the user's
   mood or ask leading questions ("are you sad or happy?"); stays neutral, lets the user lead.

**Coverage gap (unchanged):** summaries persist only when the user reaches the summary screen; a
force-quit mid-call saves emotions but no summary. Acceptable (no summary is generated then anyway).

**NEXT UP:** deploy the whole `feat/realtime-voice-call` branch to EC2 (backend migration + nowli-ai
`test17.py` persona/voice changes + rebuild). Then on-phone: confirm male vs female voice switches
with the profile setting, and that the persona feels less "moody".

---

## ▶ RESUME HERE (2026-07-23)

**Done today:** cut the Realtime voice-call cost (test calls were ~$16–20 each). The server was **already on
`gpt-realtime-mini`** (not a pricey model) — the blow-up was an uncapped, noise-amplified session. Deployed to
EC2 (`nowli-ai`, committed on `feat/realtime-voice-call`): reply cap `max_output_tokens=1024`, input
`noise_reduction=near_field`, VAD `threshold 0.5→0.7`, `silence_duration_ms 500→400`, all env-tunable; pinned
`REALTIME_MODEL=gpt-realtime-mini` in `~/ai/.env`. Est. after-cost ≈ **$0.25/call** (~$0.03/min + ~$0.03
summary). Talk/barge-in/summary all preserved. Full detail: `realtime-voice.md` → "Cost controls".
**Decision:** keep the summary on `gpt-4o` (do NOT downgrade to mini).

**TOP TO-DO (2026-07-24) — persist each call's summary in the DB, per user.**
- **What to do:** every voice call's conversational summary must be **saved to the database tied to the user**
  (survives nowli-ai restarts; enables per-user call history + richer Insights). Today only the 5-category
  **emotion** breakdown is persisted (`CallEmotionSnapshot`); the **text summary is generated at call end and
  then thrown away**. The summary content comes from nowli-ai `POST /api/v1/chat/summary` →
  `mood_detected`, `focus_topic`, `energy_shift`, `next_step` (+ `dominant_emotion`, `top_emotions`).
- **Files likely touched:**
  - `nowli-backend/Apps/voice_calls/models.py` — new `CallSummary` model (OneToOne→`VoiceCall`, denormalized
    `user` FK exactly like `CallEmotionSnapshot`) with `mood_detected` / `focus_topic` / `energy_shift` /
    `next_step` text fields (+ optional raw JSON). Then `makemigrations` / `migrate`.
  - `nowli-backend/Apps/voice_calls/views.py` (+ serializers) — extend the call-`end` endpoint to accept &
    store these summary fields (mirror how `emotion_breakdown`/`dominant_emotion` are handled now).
  - `nowli-frontend-app/lib/screen/ai_call/ai_voice.dart` → `_reportCallEnd` — after `flushTranscript`, also
    fetch the summary (`/chat/summary` or extend `getCallInsights`) and pass its fields into `endCall`.
  - `nowli-frontend-app/lib/services/voice_call_service.dart` → `endCall` — add the summary params to the body.
  - (Optional) surface saved summaries in an Insights/history screen.
- **Gotchas/blockers:**
  - **nowli-ai sessions are in-memory only** → the summary MUST be fetched at call end **while the session is
    still alive** (same window `CallEmotionSnapshot` already uses), and **after** the realtime `flushTranscript`
    populates `session.turns` — otherwise the summary is empty.
  - **Avoid paying GPT twice:** `getCallInsights` (call-insights) already runs a GPT pass for emotions; adding
    a separate `/chat/summary` GPT-4o call doubles the end-of-call GPT cost. Prefer one combined call, or
    reuse the emotions already fetched and only call summary once.
  - **Idempotency:** call-end can fire more than once — the `_callEndReported` guard + an idempotent backend
    `end` (upsert the summary) must not create duplicate rows.

---

## ▶ RESUME HERE (2026-07-22)

**Where we are:** the **AI voice call was rebuilt on the OpenAI Realtime API (speech-to-speech over
WebRTC, model `gpt-realtime-mini`)** — smooth, ChatGPT-voice-like, native turn-taking + barge-in. It is
**working on the physical phone** (calm **`marin`** female voice + a calm psychological-companion persona).
The old STT→GPT→TTS pipeline is kept as a fallback behind `_useRealtime` in `ai_voice.dart`. Summary/emotions
still work (the transcript is fed back into the nowli-ai session at call end). Full detail: **`realtime-voice.md`**
and `daily-reports/2026-07-22.md`.

Also shipped today: **login fix** (email trim + case-insensitive lookup — the real bug was the AWS Gmail app
password was revoked → signup/reset 500; switched prod to `nowliiapp@gmail.com`), and **`pavle` = unlimited
AI calls** (`VOICE_CALL_UNLIMITED_USERS`). AI-quota note: the **Realtime path is funded and works** (nowli-ai
OpenAI key has credit); the Django **Insights/subtask-gen** may still `insufficient_quota` (separate key) — see
the 2026-07-21 block below.

> ⚠️ **Servers were host-patched** (Django + nowli-ai on EC2, divergent from git). Local repo has the same
> changes and is now committed on branch **`feat/realtime-voice-call`**. A future `git archive` redeploy will
> only carry them once that branch is merged/pushed and re-deployed. See `realtime-voice.md` → "Deploy".

**Next up — TO-DO (2026-07-22, from on-phone testing):**
1. **Keep the screen awake on the call screen.** When the phone locks / screen sleeps during a call, the
   WebRTC connection drops (timeout, call lost). **Do:** add a wakelock while on the AI-call screen (enable on
   call start, release on dispose). **Files:** `pubspec.yaml` (+`wakelock_plus`), `lib/screen/ai_call/ai_voice.dart`
   (`WakelockPlus.enable()` in `_onRealtimeStarted`, `WakelockPlus.disable()` in `dispose`). **Gotcha:** also
   consider re-connecting gracefully if the OS backgrounds the app.
2. **Small noise makes the AI restart talking.** Server VAD is too sensitive — faint background noise is heard
   as the user starting to speak, so Nowlii interrupts itself and starts over. **Do:** raise the Realtime
   `turn_detection.threshold` (e.g. 0.5→0.7) and/or `silence_duration_ms`, and consider enabling input noise
   reduction. **Files:** `nowli-ai/test17.py` → `realtime_token` payload (`audio.input.turn_detection`, add
   `"noise_reduction": {"type": "near_field"}`). Redeploy nowli-ai. Make these env-tunable.
3. **Dynamic emotion emoji in the call summary.** The summary screen always shows the same smiley; make it
   reflect the detected dominant emotion (sad→sad face, happy→happy, tired, angry, motivated). **Files:**
   `lib/screen/ai_call/call_summary_screen.dart` (map `dominant_emotion`/`top_emotions` → icon/asset). The
   data is already returned by `/chat/summary` (`dominant_emotion`, `top_emotions`) and `getCallInsights`.

---

## ▶ RESUME HERE (2026-07-21 end of day)

**Where we are:** the app is now **deployed to AWS and being tested on a physical phone against the live
backend** (not just the emulator). Full detail in `daily-reports/2026-07-21.md`; the authoritative deploy
runbook is now **`deploy-aws.md`** (rewritten — the old git-pull assumption was wrong; deploy = `git
archive | ssh tar -x` → `docker compose build && up -d`). **SSH to EC2 is fixed** (`ssh -i ~/.ssh/id_ed25519
ubuntu@16.170.191.239`). Google login works on-device. Core API (auth/quests/subtasks/profiles/avatars/
subscriptions/support) verified live.

**Top blocker — AI is down everywhere:** the shared **OpenAI key is out of quota** (`insufficient_quota`),
which kills AI voice, Insights (500), and AI subtask-gen on both AWS *and* local. **Next action: add OpenAI
billing credits** (or rotate to a funded key / set a backend `ANTHROPIC_API_KEY`), then verify the AI trio.

**Next up (2026-07-21):**
1. Add OpenAI credits → re-verify AI voice / insights / subtask-gen end-to-end on the phone.
2. Fix **Insights 500 → graceful fallback** (`insights/views.py`) + redeploy backend.
3. Sign up a fresh account on the phone (prod RDS ≠ local DB) → test quests + AI voice on-device.
4. Then continue the pre-2026-07-14 threads below (subscribe button 1A, secrets rotation A5, Apple login,
   and HTTPS/domain before any release/Play build).

---

## ▶ RESUME HERE (2026-07-14 end of day — superseded by 2026-07-21 above)

**Where we are:** core loop + AI voice call + Insights all working on the emulator. Big 2026-07-14
session — full detail + a **DETAILED TO-DO for tomorrow in `daily-reports/2026-07-14.md`** (read its
"Recommended next start"). Today shipped: Add-Quest **Enable call / Repeat quest** toggles wired to real
behavior + **5-min** call copy + **no-past-scheduling** guard (`quest-toggles-wiring` memory); Insights
**"What this means" AI summary** + **dynamic "Your mood" chart**; **Subscriptions Phase 1** — backend
lifecycle engine (`Apps/subscriptions`, decreasing-price-then-free, mock activation, tested) + frontend
data layer (`subscription-model` memory); **Nowli Pro screen** spelling fixes + "How it works" matched to
Figma + new **"How billing works"** section with the phase boxes. For earlier sessions read
`daily-reports/2026-07-10.md` (fluid voice, moderation, barge-in, Apple web-redirect) and `2026-07-07.md`
(Insights Top-Emotions / When-feeling-low). Base (cleanup, Google login, email, avatars, support) is in
the STATUS table below + the feature docs.

> ⚠️ **Nothing is committed to git yet** — the whole session is on disk only. Commit early tomorrow.

**Restart everything tomorrow** (each in its own terminal; background servers don't survive a
reboot). Details in `running-locally.md` / `running-on-android.md`:
```powershell
# 1) Django backend (bind 0.0.0.0 for the emulator/phone; allow their hosts)
cd nowli-backend
$env:DB_ENGINE="django.db.backends.sqlite3"; $env:DEBUG="True"
$env:ALLOWED_HOSTS="10.0.2.2,192.168.0.39,localhost,127.0.0.1"
uv run python manage.py runserver 0.0.0.0:8000

# 2) nowli-ai (optional, for the AI companion)
cd nowli-ai; $env:HOST="0.0.0.0"; $env:PORT="8001"; .venv\Scripts\python.exe test17.py

# 3) App on the Android emulator
flutter emulators --launch Medium_Phone_API_36.1
flutter run -d emulator-5554 --dart-define-from-file=dart_defines.android.json
```

**Config state (all set up, git-ignored `.env` / dart_defines):**
- Google Cloud project `274971792537` (Web + Android client ids wired). Google login verified on Android.
- Email sender `nowliiapp@gmail.com` (Gmail app password) — OTP/support emails work.
- Admin superuser `justweb.rs@gmail.com` / `lozinka_123` → `http://localhost:8000/admin/`.
- Avatars: DB seeded with 6 companions (images on S3). **If the SQLite DB is reset, re-seed** (see
  `running-on-android.md`; a repeatable management command is still a TODO).
- Apple: everything built; **empty** `APPLE_CLIENT_IDS` etc. — fill in to enable (`apple-login.md`).

**Next up (in order) — the authoritative day-by-day list is in `daily-reports/2026-07-14.md`
"Recommended next start". Summary:**

0. **Commit the session's work first** (nothing is committed yet).

1. **SUBSCRIPTIONS (primary thread — continue this):**
   - **A. Wire the subscribe flow:** `subscription_popup.dart` "Let's begin 7 days free" button is still
     empty (`onPressed: () {}`) → call `SubscriptionService.activateMock()` + SnackBar + status refresh;
     show current status (month/price/next/"Free forever") when already subscribed; add a cancel action.
   - **B. Client/design decisions:** (i) reconcile the two pricing models on the Pro screen — it now
     shows BOTH the Figma trial cards (Yearly $25.99 / "7 days free") AND the new decreasing-phase
     billing explanation; decide which is the real purchase path. (ii) Decide exactly which features
     "Pro" gates, then enforce (`subscriptions.services.user_has_pro` backend + frontend gating).
   - **C. Phase 2 — real IAP:** `in_app_purchase` plugin + per-phase products in App Store Connect /
     Play Console (verify current offer templates) + backend receipt verification (fill the
     `verify-receipt/` stub → drive the engine, set `platform`/store token). Mobile-only; no Stripe
     in-app. See `subscription-model` memory.

2. **Add-Quest toggle client decisions:** (a) "Call Nowlii" button on Scheduled/Blocking too (Today
   only now)? (b) does "Repeat quest" need real recurrence (linked series) vs the 7-day materialization?
   Real recurrence/scheduled calls → deferred `flutter_local_notifications` + backend reminder model
   (`voice-check-and-scheduling.md`).

3. **Carryovers:** barge-in headphones test + mic earcon; **Apple login** `intent://` fix + permanent
   https URL before any device build (`apple-login.md`); **A5 rotate secrets**; build the phone `.apk`
   (`flutter build apk --debug --dart-define-from-file=dart_defines.phone.json`).

4. **Small follow-ups:** `editFrom` avatar → send `predefined_option`; seed-as-management-command;
   reconcile unused `users.CustomUserModel` vs default `auth.User`.
   _(Done 2026-07-14: Insights "What this means" AI summary + dynamic "Your mood" chart.)_

---

## STATUS (updated 2026-07-03)

| Task | Status | Notes |
|---|---|---|
| **A1** remove junk/scratch | ✅ done | NOT deleted — **preserved + relocated** to `lib/experimental/`, imports fixed. See `cleanup-log.md`. |
| **A2** `je_je_…` placeholder | ✅ done | 4 mockups relocated to real feature folders (`screen/streak/`, etc.), renamed. |
| **A3** naming conventions | ✅ done | ~25 folders + ~25 files renamed, all imports fixed, `flutter analyze` = 0 errors. A few ambiguous names + `Apps/` left (see `cleanup-log.md`). |
| **A4** route `SubTasksViewset` | ✅ done | Live at `/api/subtasks/` CRUD; `/subtasks/generate/` kept via include reorder; serializer/parser fixed so create works. Verified. |
| **A5** rotate API keys | ⏳ pending | Needs YOU to rotate at the providers (OpenAI/AWS/Hume/Google); then paste values → I update both `.env`s + fresh `SECRET_KEY`. |
| **B1** Google login | ✅ **verified on Android** | `/api/auth/google/` (id_token → JWT) + button on all auth screens. Working end-to-end on the emulator with Google Cloud project `274971792537`. Web `signIn()` remains finicky (Android is the target). See `google-login.md`. |
| **B2** Apple Sign-In | 🔶 prepared (keys pending) | Full flow built like Google: `/api/auth/apple/` (verifies identity token, 503 until configured) + `sign_in_with_apple` + button on all 4 auth screens. Fill in `APPLE_CLIENT_IDS` etc. to enable. See `docs/apple-login.md`. |
| **B3** mobile build (device) | ✅ **on real device vs AWS** | Debug `.apk` built with `dart_defines.prod.json` (→ AWS), installed on a physical phone via file transfer, runs against the **live AWS backend**; Google login verified on-device (2026-07-21). Release/Play build still needs HTTPS + signing. iOS still needs macOS. See `deploy-aws.md`. |
| **AWS deploy** | ✅ **live (2026-07-21)** | Both services rebuilt on EC2 from `main`; runbook in `deploy-aws.md`; rollback images `:backup-20260721`. Prod `.env` gaps fixed (hosts/CSRF/Google id). Blocker: OpenAI quota for AI features. |
| **Email/SMTP** | ✅ done | env-driven; sender = `nowliiapp@gmail.com`; test email delivered. |
| **Companion avatars** | ✅ fixed | DB seeded (6 companions on S3); update sends `predefined_option`; empty-list fallback + broken-asset fix. |
| **Support / contact chat** | ✅ done | `Apps/support` + `/api/support/messages/` (per-user); admin "Reply" box; email both ways. Superuser `justweb.rs@gmail.com`. See `docs/support-feature.md`. |

_Detailed change records: `cleanup-log.md` (A1–A4), `google-login.md` (B1)._

---

## PART A — CLEANUP FIRST (before any new features)

### A1. Remove junk / scratch folders
**What:** Delete experimental/scratch code that isn't wired into the app:
- `lib/aaa/` (contains `ai_voice_call/`, `reminder/` experiments)
- `lib/screen/test_file/`
- `lib/screen/debug/` (`profile_test_screen.dart`)
- `.backup` files: `lib/screen/reday_to_start_screen_p4.dart.backup`

**Files likely touched:** the folders above, plus **`lib/core/app_routes/app_pages.dart`**
and **`lib/core/app_routes/app_routes.dart`** (route cleanup — see gotcha).

**Gotchas/blockers:**
- `lib/aaa/` and `lib/screen/test_file/` are **not imported anywhere** → safe to delete.
- **`lib/screen/debug/profile_test_screen.dart` IS referenced**: imported at
  `app_pages.dart:52` and wired to the `profileTestScreen` route. To remove `debug/` you
  must also delete that import, its `GoRoute`, and the `profileTestScreen` constant in
  `app_routes.dart`. Deleting the folder alone will break the build.
- After deleting, run `flutter analyze` and a `flutter build web` to confirm nothing else
  referenced them transitively.

### A2. Delete the `je_je_page_gula_connect_kori_nai.dart` placeholder
**What:** Remove the placeholder ("pages I haven't connected yet").

**Files likely touched:** `lib/je_je_page_gula_connect_kori_nai.dart/` **← it's a
DIRECTORY, not a single file.** It contains `ai_calling.dart`,
`popup_multi_misscal_talk.dart`, `quest_for_done_screen.dart`, `steak_popup.dart`.

**Gotchas/blockers:**
- Confirmed **not imported anywhere** → safe to delete the whole directory.
- Before deleting, skim the 4 files — some (e.g. `steak_popup.dart`, `ai_calling.dart`)
  may contain logic worth salvaging into the real screens rather than losing outright.

### A3. Fix bad naming conventions
**What:** Normalize the many misspelled/inconsistent names so the tree is navigable.
Examples found: `lib/utlis/` (→ `utils`), `screen/Onboarding/` (capitalized vs others),
`swaipe_to_talk/` (swipe), `reday_to_start_*` (ready), `remiender_notification/` (reminder),
`onbording_*` / `efit_name.dart` / `blockng.dart` / `poup_*` (popup), `steak_popup` (streak),
`Apps/` (capital A — imported as `Apps.…`).

**Files likely touched:** many folders/files under `lib/`, and **every import that
references them** — especially `lib/core/app_routes/app_pages.dart` (imports ~40 screens).
Backend `Apps/` rename would touch `INSTALLED_APPS`, every `apps.py` `name=`, `urls.py`
includes, and migration `app_label`s — **high blast radius**.

**Gotchas/blockers:**
- Rename in small batches; after each, fix imports and run `flutter analyze` /
  `manage.py check`. Do NOT bulk-rename everything at once.
- **Windows trailing-space trap** (already hit once): never reintroduce folder names with
  trailing spaces (the old `core%20/` bug). Keep names ASCII, lowercase, no spaces.
- Renaming Django `Apps/` is risky (migrations reference `app_label`) — consider leaving
  it or doing it as an isolated, well-tested change. Lowest-risk win is the `lib/` renames.
- Some files use `part`/`part of` or GetX bindings by path — grep for the old name across
  the repo before/after each rename.

### A4. Route `SubTasksViewset` properly
**What:** `SubTasksViewset` is fully implemented in `Apps/quests/views.py` but never
registered, so subtasks have no standalone CRUD endpoints (only nested via the quest
serializer).

**Files likely touched:** `nowli-backend/Apps/quests/urls.py` (register the viewset),
possibly `core/urls.py` (include ordering).

**Gotchas/blockers:**
- **URL collision risk.** `core/urls.py` includes `Apps.quests.urls` at `api/` *before*
  `path("api/subtasks/", include("Apps.subtask_generator.urls"))`. If you
  `router.register(r'subtasks', SubTasksViewset)`, DRF's default detail route
  `subtasks/<pk>/` uses `[^/.]+` and will **shadow `/api/subtasks/generate/`** (it'd treat
  `generate` as a pk). Avoid this: register under a distinct basename (e.g. `sub-tasks`),
  or nest under quests (`quests/{id}/subtasks/`), or reorder includes so the explicit
  `generate/` path resolves first.
- `SubTasksViewset` already sets `permission_classes=[IsAuthenticated]` and filters by
  `task__user=request.user` — keep that; verify the `MultiPartParser` there is intended.

### A5. Rotate exposed API keys
**What:** All secrets are committed in plaintext `.env` files and must be rotated (they
were visible/used this session).

**Files likely touched (and what's in them):**
- `nowli-backend/.env`: `OPENAI_API_KEY`, AWS (`AWS_ACCESS_KEY_ID`,
  `AWS_SECRET_ACCESS_KEY`), `EMAIL_HOST_PASSWORD` (Gmail app pw), `DB_PASSWORD`,
  `SECRET_KEY` (still the `django-insecure-…` dev key), Google OAuth secret.
- `nowli-ai/.env`: `OPENAI_API_KEY`, `HUME_API_KEY`, `HUME_SECRET_KEY`, `HUME_CONFIG_ID`.

**Gotchas/blockers:**
- **The OpenAI key is duplicated** in both `.env` files — rotate once, update **both**.
- Rotate at the provider (OpenAI dashboard, Hume, AWS IAM, Google Cloud console), then
  paste new values locally; don't just edit the files.
- `.env` is git-ignored now, **but if it was ever committed**, the old keys live in git
  history — scrubbing history (or treating the keys as permanently burned) is required.
- Generate a fresh Django `SECRET_KEY` for any non-dev deployment.
- After rotating, re-run the smoke tests in `running-locally.md` (`/health` should still
  show `openai:true, hume:true`).

---

## PART B — NEW FEATURES (only after Part A is done)

### B1. Google OAuth login (backend + frontend)
**What:** Wire real Google sign-in returning app JWTs. Backend already lists the Google
provider in `django-allauth`; the missing piece is a REST endpoint that exchanges a Google
credential for NOWLII access/refresh tokens, plus the frontend button/flow.

**Files likely touched:**
- Backend: `nowli-backend/core/settings.py` (`SOCIALACCOUNT_PROVIDERS['google']` client
  id/secret via env), `Apps/users/urls.py` + `Apps/users/views.py` (a social-login view,
  e.g. `dj-rest-auth`'s `SocialLoginView` with `GoogleOAuth2Adapter`, returning SimpleJWT),
  `core/urls.py`.
- Frontend: add `google_sign_in` to `pubspec.yaml` (**not currently a dependency**), new
  `lib/api/` or `lib/services/` social-auth method that posts the Google token to the
  backend and stores the returned JWT via `StorageService.saveTokens()`, and the sign-in
  screen (`lib/screen/auth/sign_in_screen.dart`) button/handler.

**Gotchas/blockers:**
- No `google_sign_in` package is present yet — adding native OAuth pulls in Android/iOS
  platform config.
- **Config sprawl:** need a Google Cloud OAuth client per platform — Android needs the app
  SHA-1 fingerprint + package name; iOS needs the reversed client-id URL scheme; web needs
  an authorized JS origin. `settings.py` still hardcodes a
  `SOCIAL_AUTH_GOOGLE_OAUTH2_CALLBACK_URL` to `127.0.0.1:8000` — make it env-driven.
- Decide the token-exchange contract: frontend sends the Google `id_token`/`access_token`
  → backend verifies → returns SimpleJWT. Keep storage identical to `auth_service.login()`
  so the route guard keeps working.
- `ACCOUNT_EMAIL_VERIFICATION = "mandatory"` may interfere with social signups — verify
  allauth treats verified Google emails as already-verified.

### B2. Apple Sign-In (backend + frontend)
**What:** Same shape as B1 for Apple. Provider is already listed in allauth
(`allauth.socialaccount.providers.apple`).

**Files likely touched:**
- Backend: `settings.py` (`SOCIALACCOUNT_PROVIDERS['apple']` — team id, key id, client id,
  private key, all via env), a social-login view in `Apps/users/`, `core/urls.py`.
- Frontend: add `sign_in_with_apple` to `pubspec.yaml`, a service method + sign-in button.

**Gotchas/blockers:**
- **Apple requires a paid Apple Developer account** and a `.p8` private key + Service ID;
  more setup than Google.
- Apple only returns the user's name/email **once** (first authorization) — the backend
  must persist it on first login or it's lost.
- Apple Sign-In truly works only on iOS/macOS (and via web JS on Android with a redirect);
  test target matters.
- iOS requires the "Sign in with Apple" capability in Xcode + the entitlement.

### B3. Mobile build setup (run on a physical Android/iOS device)
**What:** Currently the app only runs as Flutter **web** (that's all that's set up). Enable
building/running on real devices. Document the exact prerequisites.

**Files likely touched:** mostly toolchain/config, not app code — `android/` Gradle config
(signing, `applicationId`, minSdk), `ios/` Xcode project (bundle id, signing team),
`pubspec.yaml` if plugins need platform setup; run with the same `--dart-define` URLs.

**What's needed / gotchas:**
- **Android (works from this Windows machine):**
  - Install Android Studio + Android SDK + platform-tools; accept licenses
    (`flutter doctor --android-licenses`).
  - Enable **Windows Developer Mode** (`start ms-settings:developers`) — required for
    Flutter plugin symlinks on native builds (web didn't need it; native does).
  - On the phone: enable Developer Options → **USB debugging**, connect via cable, accept
    the RSA prompt; `flutter devices` should list it; `flutter run -d <id>`.
  - **`localhost` won't reach the dev servers from a physical phone.** Use the PC's LAN IP
    for `--dart-define=BASE_URL=http://<PC-LAN-IP>:8000` (and `:8001`), run the servers
    bound to `0.0.0.0`, and open the firewall for those ports (or use `adb reverse
    tcp:8000 tcp:8000` / `tcp:8001` over USB).
  - Android blocks cleartext HTTP by default on newer SDKs — either serve HTTPS or add a
    network-security-config / `usesCleartextTraffic` for dev.
  - Need a signing config for release builds (debug builds run without one).
- **iOS (BLOCKER on this machine):**
  - **Requires macOS + Xcode** — cannot be built on Windows at all. Needs an Apple
    Developer account, provisioning profile, and bundle id signing.
  - Physical iOS device also needs the LAN-IP + cleartext (ATS) exception, same as Android.
- General: after any native run, re-verify the three-service wiring from `architecture.md`
  (the phone must reach both `:8000` and `:8001`).

---

## Suggested order

A5 (rotate keys — do immediately, security) → A1 → A2 → A4 → A3 (naming, most churn) →
then B1 → B2 → B3. Keep each cleanup step a separate, verifiable change
(`flutter analyze` + `flutter build web` + `manage.py check`) before moving on.
