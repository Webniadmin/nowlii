# NOWLII — Project Status & Analysis

_Last reviewed: 2026-08-04 (evening)_

## Completed this session (2026-08-04)

_Full detail in `daily-reports/2026-08-04.md`. **Nothing is committed** — the whole day is on
one machine, and production is running backend code shipped from the working tree._

- **Yesterday's backend reached production** (`users.0016/0017/0018` + the nowli-ai
  personalization changes), verified inside the running container rather than from the deploy
  log. Restricted Topics then survived a cold restart on the emulator.
- **The paywall could not take money from anyone on a trial.** `/subscriptions/me/` reports
  `subscribed: true` for anyone with a Subscription row — including every trial user — and the
  Pro screen read that as "already paying", rendering a permanently disabled CTA. The screen
  quoted a price with a dead button underneath it.
- **A lapsed plan no longer closes the app** (client decision, mid-session). Reads survive,
  writes answer 402, and a once-per-launch dialog says so. Insights still serves the user's
  own numbers but skips the AI generation — the statistics are theirs, the paragraphs are the
  paid part. Three defects surfaced only on the device: splash still hard-redirected to the
  paywall, the quota 402 was mistaken for "quota unknown" (leaving the home card on
  "Checking your sparks…" forever), and the copy promised a tomorrow that brings nothing back.
- **Four screens reported success they had not achieved.** Changing the companion sent a
  read-only URL instead of `predefined_option` and announced "Avatar updated successfully!";
  the same defect at signup meant **every new account got the default companion and its
  voice**; the naming screen picked the character by matching its *name*, so renaming it —
  which that screen invites — showed a different character; and the Power-moves ring drew full
  for any single completion.
- **"Your moves" was dynamic but unreadable** — it showed only completions, so "0" was
  indistinguishable from having no quests. Each ring now carries its denominator.
- **Design:** Spark is now the opening row of the paywall timeline (badged NEXT); the profile
  card names the actual plan and stage instead of a flat "Nowlii Pro"; home is restored to the
  original design with the hero card, "Todays progress" and the orange quest list, with the
  green closing card taking the hero slot once the day's sparks are spent.
- Verified: 169 backend tests, 180 Flutter tests, `flutter analyze` 0 errors. Twelve existing
  tests asserted the old behaviour and were rewritten — three of them had been proving the
  entitlement bypass with a **GET** that is now open to everyone, so they would have passed
  against a broken gate.

> ⚠️ **Both QA allowlists are empty on production** at the user's request, so the test account
> now hits the real trial, the real paywall and the real 2-calls-a-day limit — and real calls
> cost real money.

_Previously reviewed: 2026-08-03 (evening)_

## Completed this session (2026-08-03)

_Full detail in `daily-reports/2026-08-03.md`. 18 commits on `feat/design-implementation`;
the 08-01 batch is deployed, **today's backend work is not**._

- **The money flow was finally exercised**, against production with a real account rather
  than mocks. Expired trial → 402 on every feature endpoint while subscriptions and profile
  stay open; the paywall holds (✕ inert, back exits the app, relaunch returns to it);
  subscribing restores access; every price stage turns green in turn and past the year
  **Graduated is the current plan at $0.00**.
- **Neither store can sell this plan.** A Google Play offer allows **two** pricing phases and
  an Apple introductory offer **one**, so the four-step ladder needs four products per store
  plus a plan change **only a device can perform** — no store has a server-side plan change.
  The backend now notices when a subscriber falls behind and the admin can find them, but the
  hazard is inherent to that path.
- **Stripe is the alternative and is less work**, not more: subscription schedules express the
  phased price natively. Linking out from the app is now permitted in the US, EU, South Korea
  and Japan — and nowhere else. Recorded in `subscriptions-iap.md`; the decision is gated on
  which markets launch first.
- **AI Personalization was three-quarters theatre.** Restricted Topics saved nowhere, the
  privacy switch wrote to a preference nothing read, and "Clear All AI Memory" reported
  success while deleting nothing. All three are real now, stored on the account, and the
  topics are folded into the call persona — the first per-user change to what the AI says.
- **Female is the default voice**, existing accounts included. Español and "Rate Nowlii" are
  blurred and inert rather than hidden. Four screens were pointing at an asset whose filename
  contains a `?` and had been rendering broken on every platform.
- **The Pro screen shows a subscriber where they are** rather than what they would pay — the
  opening stage had been missing from its own timeline. Also fixed: Settings → "Nowlii Pro"
  opened the free-trial pitch, so a paying subscriber was offered a trial.

> ⚠️ **Still no real money**, still no upload keystore, still no Terms of Service. The
> payments decision (Stripe vs store IAP) now gates the rest of that work.

_Previously reviewed: 2026-08-03 (morning)_

## Completed this session (2026-08-01, committed 2026-08-03)

_Full detail in `daily-reports/2026-08-01.md`. Five commits on `feat/design-implementation`;
**nothing deployed, nothing seen on a device**._

- **The updated design reached the three screens after onboarding**: the **home screen**, the
  **receipt** a call leaves behind, and the **paywall**.
- **Sparks.** The daily AI-call allowance now uses the product's word for it, counted in one
  place so the home card, swipe button and call header cannot drift. Unlimited QA accounts
  (`limit: -1`) and an unknown quota are handled explicitly — the first would otherwise read
  "Spark 1 of -1", and the second would make a failed fetch look like an empty allowance.
- **A receipt library.** Numbered receipts, a note the user writes and edits (its own endpoint,
  so re-posting the generated summary cannot overwrite it), a `tiny_question` from the existing
  GPT pass at no extra cost, and PDF export via the share sheet. Migrations `voice_calls.0007`,
  `0008`.
- **The paywall shows dated price steps** instead of month ranges, anchored to `started_at` for
  a subscriber and to today for someone deciding, with month arithmetic that clamps rather than
  rolling the 31st into the month after next.
- **Two silent bugs fixed.** DRF's project-wide `DATETIME_FORMAT` has no offset, so receipt
  dates arrived as `null` and **every scheduled-call reminder was out by the device's offset**.
  And the voice check's ✕ called a bare `Navigator.pop` on a screen reached with `go`, leaving
  the user on a black screen — one tap off the redesigned onboarding path.
- Verified: `flutter analyze` 0 errors, 160 Flutter tests (11 new files), 107 backend tests.

> ⚠️ **The device test is now six days overdue** and is the only thing between this work and a
> release build. The backend is three migrations behind production.

_Previously reviewed: 2026-07-30 (evening)_

## Completed this session (2026-07-30)

_Full detail in `daily-reports/2026-07-30.md`; tomorrow's list in `daily-checklist.md`.
11 commits, all deployed to EC2._

- **Production hardening.** `nowli-ai` required no credentials at all while minting OpenAI
  Realtime keys — an open door to the bill for anyone who knew the IP. The companion
  catalogue was anonymously writable (any caller could DELETE every avatar). `SECRET_KEY` is
  now enforced, DRF fails closed, JWTs no longer reach logcat, release signing is wired.
- **Scheduled AI calls**, via a quest's existing "Enable call" toggle, with a local reminder
  5 minutes before. The daily limit of 2 is fully wired in **without reserving anything** —
  a scheduled call is a plan, not a booking — so the app warns before a swipe spends the
  last call and offers "Move to tomorrow" after.
- **Sessions now survive.** The app had stored a refresh token since day one with no route to
  spend it; four rounds closed the gaps (route, lifetimes, 401 recovery, and a route guard
  that accepted any non-empty string as a session).
- **Account deletion is real.** It was a dialog that showed "Account deletion initiated" and
  did nothing — a hard rejection under Play and Apple policy, and a false statement under the
  GDPR. Privacy Policy is now linked; Terms of Service does not exist yet and is P0.
- **A device report traced to one cause, not four bugs**: the day's `SECRET_KEY` rotation
  invalidated every token, and the installed build had no way back from a 401.

> ⛔ **Blocked on two external steps** before HTTPS: the `api`/`ai` DNS records at GoDaddy
> (verified absent from the zone) and ports 80/443 in the AWS security group (verified
> closed). HTTPS is what unblocks a real release build.

_Previously reviewed: 2026-07-29 (evening)_

## Completed this session (2026-07-29, evening)

_Full detail in `next-phase.md`; deploy record in `deploy-aws.md`; tomorrow's list in
`daily-checklist.md`. **All of this is deployed to EC2.**_

- **Deployed the whole `feat/realtime-voice-call` branch** — the box had been running the 07-21
  backend and 07-23 nowli-ai, so every 07-28/29 feature was local-only. 4 migrations applied to
  prod RDS. Verified with a credential-free trick: a protected route answers **401** when it
  exists and **404** when it doesn't, so 404→401 proves the deploy landed.
- **Insights no longer 500s when the AI provider fails.** Each AI block degrades independently to
  data-derived fallback copy and the request still returns 200, with an `ai_degraded` flag so a
  fallback is never mistaken for real AI output. Fallbacks are never cached, so the next load
  retries. Also added a 20 s provider timeout — the SDKs default to **600 s**, so a hanging
  provider would have left the app spinning instead of ever reaching the fallback.
- **7-day free trial + a real paywall (the big one).** Previously the whole "7 days free" flow was
  artwork: an empty `onPressed`, no trial concept in the backend at all, and `user_has_pro()` never
  called anywhere — so **every user had the entire app free, forever**. Now the trial is granted
  automatically on first login (once, never re-granted), and when it runs out every feature endpoint
  returns **402 `subscription_required`** (402 rather than 403 so the app routes to the paywall
  instead of the login screen). Auth, profile, subscriptions and support stay open so a blocked user
  can still pay or reach support. Kill switch + test allowlist included.
- **Pro screen pricing conflict resolved.** The hardcoded "Yearly $25.99 / $2.66-mo" cards were
  deleted — no yearly product exists in the backend and the subscribe button ignored the selection
  entirely (tapping "Yearly" silently started the monthly plan). One plan now, prices from the
  backend, with the decreasing-price explainer on both paywall screens.
- **Confirmed scheduled AI calls do not exist** (client question): no notification/scheduling
  package, no backend reminder model, and `set_alarm` is persisted but drives nothing. "Enable call"
  only reveals an on-demand button. Blocked pending client input.

> ⚠️ **Payments are still not real.** The paywall is enforced, but `activate` is a mock and
> `verify-receipt` is a 501 stub — anyone can "subscribe" for free. Apple IAP / Play Billing is now
> the single biggest gap in the product.

_Last reviewed: 2026-07-29_

## What the app does

**NOWLII** is a gamified productivity/wellness mobile app with an AI companion. Users
set daily "quests" (tasks with a difficulty "zone", time/date, subtasks, and optional
call/alarm/repeat flags), track completion streaks, view progress analytics, and
interact with a personalized companion (Milo, Bloop, Gumo, etc.) via text and **voice
calls** — including AI-generated subtask suggestions, weekly reflections, and quest
recommendations.

## Completed this session (2026-07-28 → 07-29)

_Full detail in `next-phase.md` (RESUME HERE blocks for 07-28 and 07-29). All on branch
`feat/realtime-voice-call`; **not yet deployed to EC2**._

- **Voice-call summaries persisted per user.** New `voice_calls.CallSummary` model + `POST
  /voice-calls/<id>/summary/` (idempotent) + `GET /voice-calls/summaries/`; saved from the summary
  screen (zero extra GPT — the summary was already fetched to display it). New **Call History screen**
  consumes the list. Migration `voice_calls.0004`.
- **Voice-call polish:** wakelock on the call screen (screen no longer sleeps → WebRTC won't drop);
  summary avatar emoji/colour now reflect the dominant emotion; "Save reflection" note now persists
  (per-user, shows in Insights).
- **Male/female voice per chosen avatar.** `NowliiPredefinedOption.voice` (Male/Female, default Male,
  admin-editable) → `Profile.voice` on companion pick → nowli-ai Realtime voice (Male=`cedar`,
  Female=`marin`). Voice selector now actually persists. Migrations `users.0013`, `0014` (seed mix).
- **AI persona made more neutral** — no longer guesses/labels mood or asks leading "are you sad?"
  questions (`_REALTIME_PERSONA_EN` in test17.py).
- **Swipe-to-talk name reverted** to fixed "Fuzzy" (no longer the dynamic companion name).
- **Progress + Insights made fully dynamic (de-faked).** Most-productive **hour** now computed
  (`select_a_time`); **rest-day** feature (`Profile.rest_days` + `/insights/rest-days/`) — the button
  works and excludes those days from skipped/calendar; skipped-days text, "Your moves" rings
  (`completed/assigned`), and "% to 30 days" (`streak/30`) all real; **streak card** background is now
  milestone-tier gradient logic + progress-to-next-badge (was fixed `120Days.png`). Migration
  `users.0015`. All 8 `Apps.insights` tests pass.

## Completed this session (2026-07-23)

_Full detail in `daily-reports/2026-07-23.md`._

- **Traced a large OpenAI bill to a leaked API key, not the app.** A "1-minute call" appeared to cost ~$18;
  logs proved today had exactly one capped `gpt-realtime-mini` session (~67s), which can't bill that. The
  OpenAI dashboard showed spend on a model we never call (`gpt-5…-sol`) → the **old raw key leaked** and was
  used by a third party. Confirmed the leak is **not** from current code (no key in git history, frontend,
  `dart_defines`, or hardcoded — only in git-ignored `.env`).
- **Rotated the OpenAI key and redeployed both services from git** (`git archive → build → up -d`). New key
  verified live on nowli-ai (`realtime/token` → 200) and backend (`/api/` → 200); old key revoked everywhere.
- **Open (user side):** set a hard OpenAI budget cap, check for unrecognized API keys, dispute the fraudulent
  usage, and verify the `fahad1000mir/*` Docker Hub images aren't a leak source.

## Completed this session (2026-07-21)

_Full detail in `daily-reports/2026-07-21.md`; runbook in `deploy-aws.md`._

- **First full AWS deploy from this repo.** Both services rebuilt on EC2 `16.170.191.239` from `main` and
  verified live (previously the box ran ~3-month-old images from the original dev's Docker Hub). Deploy is
  `git -c core.autocrlf=false archive HEAD:<svc> | ssh tar -x` → `docker compose build && up -d`;
  old images tagged `:backup-20260721` for rollback. **SSH access blocker resolved** (our key added via
  AWS CloudShell `ec2-instance-connect`; the real hold-up was a 2h dev-machine **clock skew** faking
  `Signature expired` errors). Authored the missing **`nowli-ai/Dockerfile`** so its image is rebuildable.
- **On-device testing against live AWS started** (debug APK, `dart_defines.prod.json`, installed via file
  transfer). **Google login works on the phone.**
- **Prod `.env` gaps fixed** (the "works local, fails AWS" pattern): added `ALLOWED_HOSTS` (was 400 on every
  request), `CSRF_TRUSTED_ORIGINS`, and `SOCIAL_AUTH_GOOGLE_CLIENT_ID` (Google login was 503→now works).
- **Frontend error handling improved** — `api_service.dart` now surfaces the real server status/message and
  network exception instead of a blanket "Request failed" (debug build).
- **Full live endpoint + env audit** (`deploy-aws.md`): core app healthy (auth, quests, subtasks, profiles,
  avatars/S3, subscriptions, voice-quota, support). **All AI features are down via one root cause — the
  shared OpenAI key hit `insufficient_quota` (429)**: AI voice → silence, Insights → 500, AI subtask-gen.
  Resolves when OpenAI billing is topped up (or a funded key / backend `ANTHROPIC_API_KEY`). Apple login
  503 (deferred). Found a robustness bug: Insights returns a raw 500 instead of graceful fallback on AI
  failure.

## Completed this session (2026-07-14)

_Full detail in `daily-reports/2026-07-14.md`; design notes in the `quest-toggles-wiring` memory._

- **Add-Quest toggles wired to real behavior.** "Enable call" and "Repeat quest" were persisted but
  did nothing. Now (client-chosen behavior; **no scheduler exists**, so both are done without one):
  - **Enable call** → the Today quest card shows a **"📞 Call Nowlii (5 min)"** button only when
    `enable_call=true`; it launches the existing 5-min AI call and passes the quest title as a spoken
    opener context (`today.dart`, `ai_voice.dart` `questTitle` param, `app_pages.dart` route).
  - **Repeat quest** → recurrence is **materialized up-front** in `_createQuest`: copies for the next 6
    days (7 total incl. selected date). Copies aren't re-materialized (no recursion).
  - Both toggles now **default to `false`** (frontend matched to the backend `default=False`); before
    they were forced `true`.
- **Call-duration copy fixed 10-min → 5-min** in 5 places (`enable_card.dart`, `enable_card_edit.dart`,
  `suggested_task_overview.dart` ×2, `experimental/clean_the_house_screen.dart`). Real call = 5 min +
  one 2.5-min extension. (Left "10 mins" task-duration chips and "call 10 minutes before" timing copy.)
- **No past scheduling (new).** The date picker already limited dates to today..+6, but a **past time on
  "Today"** was allowed and the **backend had no validation**. Added a frontend guard in `_createQuest`
  (blocks a selected date+time before now, 1-min grace) **and** `QuestsSerializers.validate_select_a_date`
  (rejects a past date **on create only**, date-level vs `timezone.localdate()` — tz-safe; edits and the
  seed command are unaffected).
- Verified: `flutter analyze` (touched files) = 0 errors; `manage.py check` = no issues.
- **Insights "What this means" is now AI-generated** (was a static placeholder). New
  `generate_emotion_meaning()` fills `emotions_summary` / `low_mood_summary` /
  `low_mood_recommendation`, cached weekly in `InsightCache`, with **fallback to the placeholder copy**
  on any AI failure. Called only when the user has voice-call data. Verified live (provider = chatgpt).
- **Insights "Your mood" weekly chart is now dynamic** (was demo data). `services._build_mood_week`
  gives per-weekday dominant emotion + intensity from `CallEmotionSnapshot`; new `mood_week` serializer
  field + `MoodDay` model; the chart renders real bars (emotion→color/emoji) and **hides when the week
  has no call data**. No migration needed.
- **Subscriptions — backend lifecycle engine started (Phase 1).** New `Apps/subscriptions`: config-driven
  decreasing-price-then-free schedule (**1–3mo $19.99 → 4–6 $14.99 → 7–9 $9.99 → 10–12 $4.99 → 13+ free**),
  `Subscription` model, pure phase/entitlement engine, and `/api/subscriptions/` API (`plan`, `me`,
  **mock** `activate`, `cancel`, `verify-receipt` **stub**). 8 tests pass; verified live. Frontend data
  layer (`subscription_service.dart` + model) + minimal pro-screen wiring. **Sold mobile-only → Phase 2
  is real Apple IAP / Google Play Billing** (Stripe not allowed in-app); paywall UI still needs redesign
  to the phase model. See `subscription-model` memory + `daily-reports/2026-07-14.md`. Resolves the
  "subscriptions are UI-only" gap (#1 below) at the backend layer.

## Completed this session (2026-07-10)

_Full detail in `daily-reports/2026-07-10.md`; feature detail in `three-features-plan.md`._

- **Fluid voice conversation (architecture change).** Per-message emotion detection (a gpt-4o call
  before every reply, ~1.5–4s of lag) was **removed from the live path**; emotions are now extracted
  **once at call end over the whole transcript** (`_compute_top_emotions_from_transcript`, model via
  `EMOTION_MODEL` = gpt-4o-mini). First reply word dropped to **~0.9–1.4s**. Old per-message code is
  **commented, not deleted**. Feeds call-insights (Top Emotions / When-feeling-low) + the summary.
- **Profanity / content filter** in nowli-ai `chat-stream` (local word list + OpenAI Moderation),
  **excludes distress/self-harm**; warns via an SSE `warning` event → app notice + spoken TTS.
- **Barge-in** (interrupt the AI by talking) implemented; needs **headphones on the emulator / a real
  phone (AEC)** or the mic echoes the AI. **Tap-to-interrupt** fallback added. Mic start/stop earcon
  ("bip bip") still open (needs native mute).
- **AI persona** rewritten to a warm, emotionally-intelligent **wellness companion** (the only prompt
  that runs now that emotion is always "neutral").
- **After-call summary** confirmed dynamic; static fallbacks made honest; new **"Emotions in this
  chat"** section on the summary screen.
- **Swipe-to-talk** goes straight to the 5-min call (voice-note mock detour relocated to
  `lib/experimental/`); **dynamic companion name** on that path; call-screen control-row width fix.
- **Apple Sign-In (Android web flow)**: backend enabled + verified; redirect endpoint + manifest +
  cloudflared tested — Apple auth + backend 307 work, but the `intent://` bounce into the app didn't
  complete (deferred). **Must swap the temp trycloudflare URL for a permanent one before any
  preview/device build** (see `apple-login.md`).

## Completed this session (2026-07-07)

- **Insights "Top Emotions" section — implemented end-to-end and runtime-verified** (from
  Figma "Frame 2147228872"; full report in `daily-reports/2026-07-07.md`, plan/notes in
  `insights-emotions.md`).
  - **nowli-ai** — `/conversation/emotion-breakdown/{id}` now returns **5 native categories**
    (Happy, Motivated, Angry, Tired, Sad) via a dedicated `_TOP_EMOTION_MAP` /
    `_compute_top_emotions_from_turns`. The shared 6-bucket analytics map, the low-mood
    endpoint and the chat-prompt `_resolve_emotion_key` were left untouched.
  - **Persistence** — new `CallEmotionSnapshot` model in `Apps/voice_calls`; the app captures
    the breakdown at call end (nowli-ai session still in memory) and `POST /voice-calls/<id>/end/`
    stores it per call/user. Migration `0002_callemotionsnapshot`.
  - **Aggregation** — `Apps/insights` averages the week's snapshots and exposes
    `weekly.top_emotions` + `weekly.emotions_summary` (Weekly only, above "Weekly Reflection").
  - **Flutter** — `_buildTopEmotions()`/`_buildEmotionTile()` in `insights.dart`, **dynamic**
    layout (dominant full-width, rest sorted descending), Figma 1:1; clean hide-when-empty state.
  - **Runtime-verified on the emulator** — all three services up; the real flow (session →
    chat-stream → emotion-breakdown → voice-calls start/end → insights) exercised live, **not
    mock**; data-gate + seeded-data display both confirmed.
  - **Known TODOs:** the "What this means" copy is a **temporary placeholder** (10 texts, 2 per
    emotion; `TODO(insights-emotions)` in `services.py`) pending a real AI summary; and a final
    **organic** (non-seeded) voice-call test still to do.

- **Insights "When feeling low, you often say…" section — implemented end-to-end and
  runtime-verified** (Figma node `2888:11656`, below Top Emotions).
  - **One GPT-free call for both sections** — new nowli-ai `GET /conversation/call-insights/{id}`
    returns the 5-category emotion breakdown **and** the canonical low-mood phrases in one request
    (emotions from per-turn scores, phrases from regex — no LLM). The app calls it once at call end.
  - **Persistence** — new `CallLowMoodSnapshot` (`Apps/voice_calls`, migration `0003`);
    `end` stores the phrases. **Aggregation** — `Apps/insights` returns `low_mood_phrases`
    (top 5 by frequency, dedup, alphabetical ties) + placeholder `low_mood_summary`/`low_mood_recommendation`.
  - **Flutter** — `_buildWhenFeelingLow()`; **always-visible** section with a designed empty-state
    (unlike Top Emotions, which hides), mood phrases left-aligned per Figma.
  - Same TODOs as Top Emotions (AI "What this means"; organic voice-call test).

- **First real Voice Call E2E — passed; two fixes.** With the emulator mic enabled, the full pipeline
  ran on real speech (11 turns → AI replies → TTS → `CallEmotionSnapshot` + `CallLowMoodSnapshot` →
  summary). **P0** ("AI silent") root cause was the emulator not routing host audio (`error_speech_timeout`),
  not code — added a "check your microphone" hint (`ai_voice.dart`). **P3** ("Could not load summary")
  fixed — `call_summary_screen.dart` falls back to default cards instead of the error screen. An audit
  confirmed the Voice Call → Insights flow is dynamic + user-isolated (no mock data); test seeds removed.
  Open for next: AI persona (companion vs chatbot), timeout UI to Figma (Figma rate-limited), barge-in.

## Completed this session (2026-07-03)

- **PART A cleanup done (A1–A4).** Adopted a **preserve-not-delete** rule: scratch/junk
  (`lib/aaa/`, `screen/test_file/`, `screen/debug/`) was relocated to `lib/experimental/`
  and the `je_je_…` placeholder's 4 mockups moved into real feature folders — nothing thrown
  away, all imports fixed. **A3 naming pass:** ~25 misspelled folders + ~25 files renamed
  (e.g. `utlis→utils`, `remiender_notification→reminder_notification`, `swaipe→swipe`),
  every import updated, `flutter analyze` = **0 errors**.
- **A4 — subtasks CRUD is now routed.** `GET/POST /api/subtasks/` + `…/<id>/`
  (`IsAuthenticated`, per-user). Kept `/api/subtasks/generate/` working by reordering the
  URL includes; added a writable-`task` serializer + ownership checks so create actually works.
- **B1 — Google login implemented** (backend `/api/auth/google/` verifies a Google `id_token`
  and returns the normal JWT shape; frontend `google_sign_in` service + wired sign-in button).
  A real **Web** OAuth client id is wired into `.env` / `dart_defines.json` / `web/index.html`;
  `flutter build web` passes. Live end-to-end still needs Google Cloud consent/origin config.
- **Change trail:** `docs/cleanup-log.md` (A1–A4 file moves/renames) and `docs/google-login.md`
  (B1 + the exact Google Cloud setup) added.

### Later the same day (2026-07-03) — live Android testing

- **Google login verified end-to-end on Android** (emulator). Set up the full Android toolchain
  path: Developer Mode, debug keystore + SHA-1, fixed corrupted (Linux-copied) SDK build-tools,
  cleartext-for-debug manifest, and per-target dart-define files (`dart_defines.android.json` =
  emulator `10.0.2.2`, `dart_defines.phone.json` = LAN IP). Google Cloud project swapped to
  `274971792537` (new Web + Android client ids). The "Continue with Google" button is now wired on
  **all** auth screens via `lib/api/google_sign_in_flow.dart`. See `docs/running-on-android.md`.
- **Email/SMTP made env-driven** (`EMAIL_HOST/PORT/USE_TLS/USE_SSL/DEFAULT_FROM_EMAIL/SUPPORT_EMAIL`)
  and the sender switched to **`nowliiapp@gmail.com`** (Gmail app password). A live test email
  delivered to the inbox. OTP / verification / password-reset emails now come from this account.
- **Companion avatars fixed.** Root cause: the DB had no `NowliiPredefinedOption` rows → the API
  returned `[]` and the picker spun forever; and the avatar is set via `predefined_option` (the
  `avatar_logo`/`nowlii_name` fields are read-only), which the frontend never sent. Fix: **seeded 6
  companions** (images on S3, public HTTPS URLs that work on emulator + phone), the frontend now
  **sends `predefined_option`** on update (persists + displays), empty-list falls back to built-in
  assets, and the broken `?`-in-filename avatar fallback was replaced.
- **Support / contact chat built** (`Apps/support`): DB-backed `SupportMessage` +
  `/api/support/messages/` (per-user), admin "Reply" box, email both ways (send → support inbox,
  admin reply → user). Frontend Support form + Support Chat wired. A superuser
  (`justweb.rs@gmail.com`) was created for the admin. Verified end-to-end from the app. See
  `docs/support-feature.md`.

## Completed this session (2026-07-01)

- **Security — hardcoded JWTs removed** from all three frontend services
  (`subtask_service.dart`, `quest_service.dart`, `profile_service.dart`). They now read
  the logged-in user's `access_token` from storage instead of falling back to a baked-in
  test token (also removed a stale hardcoded `X-CSRFTOKEN`). Zero hardcoded JWTs remain
  in `lib/`.
- **Full local toolchain installed** on the Windows dev machine (previously had none):
  `uv` (user-scope), **Python 3.12.13** (via `uv python install`), and
  **Flutter 3.44.4** stable (git clone → `C:\src\flutter`, web enabled). Both committed
  `.venv` folders were Linux-built and were rebuilt from scratch.
- **Trailing-space import bug fixed** — 23 files imported `package:nowlii/core%20/…`
  (a trailing space in the folder name that only existed on the original Linux box). This
  broke the Windows web compile; all 23 imports rewritten to portable `core/`.
- **All three services verified running end-to-end** on 2026-07-01:
  Backend (Django) `:8000` → HTTP 200, `nowli-ai` (FastAPI) `:8001` → `/health` OK
  (`openai:true, hume:true`), Frontend (Flutter web) served on `:5000` → HTTP 200 with
  the correct API URLs baked in via `--dart-define`.
- **`docs/running-locally.md` created** — the verified, reproducible first-run/setup
  procedure with exact commands per service and every gotcha hit.
- Earlier in the session (already reflected below): host/CORS/CSRF and all frontend base
  URLs moved to env vars; `nowli-ai` host/port made env-driven and aligned to `:8001`.

## Tech stack

### Backend (`nowli-backend/`)
- **Django 6 + Django REST Framework**, Python 3.12+, managed with `uv`.
- **Auth**: SimpleJWT (31-day access & refresh tokens, rotation + blacklist),
  email + OTP registration, Google/Apple OAuth via `django-allauth`.
- **Runtime**: ASGI (Daphne/Uvicorn), Gunicorn + UvicornWorker in production.
- **Data**: SQLite (dev) / PostgreSQL on AWS RDS (prod). Media on S3 or local disk.
  Static files via WhiteNoise. Swagger docs at `/api/docs/`.
- **Pluggable AI layer**: auto-selects a provider by which API key is set,
  in priority order **Anthropic → OpenAI → Google** (`get_active_provider()`).
  This logic is duplicated in `Apps/subtask_generator` and `Apps/insights`.

### Frontend (`nowli-frontend-app/`)
- **Flutter / Dart**, GetX state management, `go_router` navigation.
- `flutter_screenutil` (responsive, design size 375×812), `fl_chart` (analytics),
  `speech_to_text` + `flutter_tts` (voice).

### AI service (`nowli-ai/`)
- **FastAPI** app "Emotion AI — Human Friend System" (v4.2), Python, deps via
  `requirements.txt` (`pip`). This is the `:8001` "AI server" the Flutter app talks to
  (`aiBaseUrl` in `lib/api/api_constant.dart`, used by `lib/services/ai_call_service.dart`).
- **Emotion pipeline**: OpenAI **Whisper** (transcription) + **Hume AI** (voice prosody
  emotion) + **GPT** (text emotion), merged into a combined emotional state that is
  injected into the chat system prompt.
- **Models**: OpenAI `gpt-4o` / `gpt-4o-mini` + `whisper-1`; Hume for voice.
- **Endpoints** (all `/api/v1/`): session management, `detect-emotion`, `chat-stream`
  (SSE, emotion-aware streaming), `chat/summary` (mood summary), conversation analytics
  (`emotion-breakdown`, `low-mood-detect`), `quest-suggestions`, `quest-source`,
  `languages`, plus `/` and `/health`.
- **Quest suggestions** call back into the Django API via `QUEST_API_URL`
  (default `http://127.0.0.1:8000/api/quests/`).

## What's complete and working

- **Auth flow** (backend + frontend): register → OTP → login, forgot/reset password,
  JWT storage, and a `go_router` auth-redirect guard based on token + `isFirstTime`.
  The users app is substantial (`Apps/users/views.py` ≈ 771 lines).
- **Quests CRUD**: full `ModelViewSet` with per-user filtering, `?due_date=` filter,
  a `bulk-delete` action, and a real **streak** calculation (`GET /api/quests/streak/`).
- **Subtasks CRUD** (as of 2026-07-03): `GET/POST /api/subtasks/` + `…/<id>/`,
  per-user, alongside the nested-in-quest representation.
- **Google login** (as of 2026-07-03): `POST /api/auth/google/` exchanges a Google
  `id_token` for NOWLII JWTs; frontend "Continue with Google" button wired. Live test
  pending Google Cloud config (see `google-login.md`).
- **AI voice-call daily limit** (as of 2026-07-06): `Apps/voice_calls` +
  `/api/voice-calls/` (`quota/`, `start/`, `<id>/end/`). Per-user, backend-authoritative:
  max 2 calls/day (`VOICE_CALL_DAILY_LIMIT`), counted from calls started today (resets at
  00:00, no cron), with per-user race locking. Frontend (`ai_voice.dart`) enforces the
  5-minute call with a single +2.5-minute extension (7.5-min cap), start notice, 1-min /
  30-sec warnings, last-10s countdown, and auto-end. Known gaps: the `nowli-ai` bypass
  (inherited — `technical-debt.md` TD-001) and the UTC day boundary (`system-constraints.md`
  SC-001).
  - **Call-screen UI polish** (2026-07-06): fixed inherited in-call visual issues in
    `ai_voice.dart` — a flickering mic icon (now a voice-activity "speaking" indicator via
    `onSoundLevelChange`, off ~1s after speech stops), the timer shifting the layout (now
    per-digit fixed-width slots), the last minute recoloring the background **and** timer
    orange (removed both; they stay blue/indigo — only the notice card signals the warning),
    and the final-10s fullscreen overlay (now counts 10 → 1 on the shared notice card). Also
    replaced the placeholder "Answer emails" heading with a neutral companion heading, and
    made the call summary fall back to its default cards instead of a "No session ID
    provided" error when the AI session is missing (`call_summary_screen.dart`). See
    `technical-debt.md` TD-017…TD-021. No UI/UX changes beyond these fixes; `flutter analyze`
    clean (no new issues).
- **AI subtask generation** (`POST /api/subtasks/generate/`) — complete, with proper
  error handling (502/503 on AI failures).
- **AI insights** (`GET /api/insights/`) — weekly reflections + quest suggestions,
  backed by an `InsightCache` model to avoid re-calling the AI on every request. The
  `monthly` block now also returns a real `zone_progress` (per-zone completed counts),
  matching `weekly` (added 2026-07-06 for the Progress screen).
- **Progress + Insights screens** (as of 2026-07-06, committed `05605ae`): **done**.
  Progress "Your moves" has a This week / This month selector that shows **real backend
  per-zone data for both** (no approximation); Insights has a per-user **personal notes**
  system (add / list / delete, persisted locally via `PersonalNotesService`). Share buttons
  and the redundant This week / This month labels were commented out per product request.
- **Insights "Top Emotions" + "When feeling low…"** (as of 2026-07-07): **done, runtime-verified**.
  Both fed by real voice-call data via one GPT-free nowli-ai call (`/conversation/call-insights/{id}`)
  → `CallEmotionSnapshot` / `CallLowMoodSnapshot` (Django) → weekly aggregation → the two Insights
  cards (Figma 1:1). Top Emotions hides when empty; "When feeling low" is always shown with a
  designed empty-state. Both "What this means" summaries are **temporary placeholders** pending a
  real AI summary. See `insights-emotions.md`.
- **Frontend** has a large, wired route table (~40 screens) covering onboarding, auth,
  quests, home, progress, profile, AI call, and settings.
- **AI voice/emotion service** (`nowli-ai/`) implements the full companion pipeline —
  sessions, Whisper+Hume+GPT emotion detection, SSE streaming chat, mood summaries,
  conversation analytics, and quest suggestions. This is the previously-"external"
  `:8001` server, now part of the repo.

## What looks unfinished / concerning

1. **Subscriptions: the lifecycle is real, the money is not.** _Updated 2026-07-29._ There is now a
   full trial → paywall → purchase flow enforced backend-side (`Apps/subscriptions`, 402 gate on
   every feature endpoint) with the decreasing-price-then-free engine behind it. What's still
   missing is **any real payment**: `POST /subscriptions/activate/` is a mock and
   `verify-receipt/` returns 501, so anyone can "subscribe" for free. Phase 2 = `in_app_purchase`
   + per-phase store products + receipt verification. The legacy `CustomUserModel.paid_user` /
   `current_plan` fields are dead and should be removed.
2. ~~**Live chat with admin does not exist in the backend.**~~ **RESOLVED 2026-07-03** —
   `Apps/support` adds a `SupportMessage` model + `/api/support/messages/` (list/create,
   per-user), an admin "Reply" box, and email notifications both ways. The frontend Support
   form + Support Chat are wired to it. See `docs/support-feature.md`.
3. ~~**`SubTasksViewset` is defined but never routed.**~~ **RESOLVED 2026-07-03** —
   now registered at `/api/subtasks/` (CRUD) with a writable-`task` serializer and
   ownership checks; `/api/subtasks/generate/` preserved via URL-include reordering.
4. **Stale AI model IDs.** All three providers hardcode older models —
   `claude-opus-4-5`, `gpt-4o`, `gemini-2.0-flash`. Current top Claude Opus is
   `claude-opus-4-8`.
5. **Frontend is mid-development / messy.** _Largely addressed 2026-07-03:_ scratch dirs
   consolidated into `lib/experimental/`, the `je_je_…` placeholder's mockups moved into
   real feature folders, and the ~50 misspelled folder/file names fixed (see
   `cleanup-log.md`). Remaining: many `// Placeholder for X` route comments, a few
   ambiguous names left on purpose (`pop_po_sahre`, `edit_from`, `create_qutes`,
   `chat_boot`), and class/route-constant misspellings not yet aligned to their files.
6. **Security posture is dev-grade.** The Django `ALLOWED_HOSTS`, CORS, CSRF, and the
   Flutter base URLs (including `NowliiOptionsApi`) have since been moved to environment
   variables (secure defaults), and the `nowli-ai` host/port are now env-driven too. Two
   items remain: DRF's default permission is still `AllowAny` (enforced per-view), and
   the `nowli-ai` FastAPI service still uses `CORS allow_origins=["*"]`. Multiple `.env`
   files across all three services contain **live secrets in plaintext** (OpenAI, Hume,
   AWS, DB password) — these should be rotated and never committed.
7. **`nowli-ai` structure is confusing.** The live app is the ~1300-line monolith
   `test17.py`; the cleaner `routers/` module (`/emotion/combined`, WS `/chat/stream`)
   is **not wired in** (dead/aspirational code). Sessions are stored **in memory only**
   (lost on restart), and the service has **no tests and no dependency lockfile**. The
   port mismatch is resolved — `test17.py` and `nowli-ai/.env` now default to `:8001`
   (env-driven `HOST`/`PORT`), matching the Flutter client.
8. **Conversation-analytics: now consumed via a combined GPT-free endpoint.**
   As of 2026-07-07, both Insights emotion sections are fed by a single new nowli-ai endpoint
   `/conversation/call-insights/{id}` (5-category emotion breakdown **+** canonical low-mood
   phrases, no LLM). The app fetches it at call end; Django persists both (`CallEmotionSnapshot`,
   `CallLowMoodSnapshot`) and Insights aggregates them into **Top Emotions** and **When feeling
   low…**. The original `/conversation/emotion-breakdown` and `/conversation/low-mood-detect`
   endpoints still exist but are no longer the app's path. See `docs/insights-emotions.md`.

## Bottom line

The core loop — auth, quests, streaks, the three Django AI features, and the `nowli-ai`
voice/emotion companion — is functional end-to-end, and the previously-external AI
server is now part of the repo. Monetization (subscriptions) and support-chat remain
scaffolded in the UI and user model with **no working backend**. The `nowli-ai` service
works but is rough: a single-file monolith with an unwired parallel refactor and
in-memory sessions (its port/host are now env-driven and aligned with the Flutter client).
