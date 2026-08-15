# Future Checklist

_All work we have consciously deferred, organized by priority. When we start an item,
move it into `daily-checklist.md` for the day. When it's done, remove it here and record
it in that day's report. Detailed context for most items lives in `next-phase.md` and the
per-feature docs._

Priority tiers: **P1** = security / must-do soon · **P2** = correctness & quality ·
**P3** = features · **P4** = long-term tech debt.

---

## P0 — Blocks the store listing

- [ ] **The trial-ending reminders do not exist.** The "SEVEN DAYS. ON US." screen
      (`subscription_popup.dart`, Figma `1:1558`) promises, in its own timeline, "Day 5 —
      Trial Status Update" and "Day 6 — Your Call to Continue". Nothing sends either: the only
      code that schedules a notification is `call_reminder_service.dart` and it handles
      `ScheduledCall` alone; `Apps/subscriptions/` has no job, cron or email. A user's trial
      ends in silence and they meet the paywall cold. **Decision needed:** local notifications
      laid down when the trial starts (recommended — the mechanism exists and is proven, no
      backend, works offline; lost on reinstall) or a backend job (survives reinstall; needs a
      scheduler on the box, which does not exist yet).

- [ ] **Terms of Service does not exist.** The document was never written, so both places it
      was referenced now hide the link rather than show dead text: the sign-up screen
      (`lib/screen/auth/sign_up.dart`) and Settings → Privacy (`privacy_data_screen.dart`).
      Both are marked `TODO(legal)`. **To restore:** publish the document, set
      `ApiConstants.termsOfServiceUrl`, and uncomment the two blocks.
      Privacy Policy is done — https://www.nowlii.com/privacy-policy, live and reachable
      from both screens.
- [x] ~~**HTTPS for the API.**~~ **Done** — live on `https://api.nowlii.com` and
      `https://ai.nowlii.com` (nginx + Let's Encrypt, cert to 2026-10-29, auto-renewing), and
      `dart_defines.prod.json` points at both. What remains is the **cutover**, and it is
      deliberately held until an APK is proven on a phone, because each step breaks any
      pre-HTTPS build the instant it lands: flip the HTTPS block in `~/backend/.env`
      (`SECURE_SSL_REDIRECT`, `SESSION`/`CSRF_COOKIE_SECURE`, `SECURE_HSTS_SECONDS` — ramp
      3600 → 31536000, not straight to a year), add the nginx HTTP→HTTPS redirect (the cert
      was issued `--no-redirect` on purpose), then close 8000/8001 in the security group.
      Tracked in `daily-checklist.md`.
- [ ] **Release signing keystore** — not created yet; release builds fall back to the debug
      keystore, which Play rejects. Wiring is done (`android/key.properties.example`).
- [ ] **Real payments** — `activate` is a mock, `verify-receipt` a 501 stub. See P3 below.

## P1 — Security (do soon)

- [ ] **Secret rotation (A5).** All `.env` secrets were exposed and must be rotated at the
      providers (OpenAI, AWS IAM, Hume, Google), then pasted back into both `.env` files.
      The OpenAI key is duplicated in `nowli-backend/.env` **and** `nowli-ai/.env` — rotate
      once, update both. Generate a fresh Django `SECRET_KEY` (still the `django-insecure-…`
      dev key). Requires the user to rotate provider-side first. See `next-phase.md` §A5.
- [ ] **Security improvements.**
  - `nowli-ai` FastAPI service uses `CORS allow_origins=["*"]` and has **no auth**
    (session-id only) — harden before any public exposure.
  - DRF default permission is `AllowAny` (enforced per-view) — audit that every sensitive
    view sets `IsAuthenticated`.
  - Confirm `.env` files were never committed anywhere; if they were, treat the old keys as
    permanently burned.

## P2 — Correctness & quality

- [ ] **The AI voice call parrots the user back in every single reply.** Reported from real
      use, 2026-08-15: "ne osećam se dobro, boli me glava" → "Okay, I feel you, your head is
      hurting." Every turn, without exception. Once in a while it lands as being heard; every
      time it is wearing, and it makes her sound like a script rather than someone listening.
      **This is not model drift — the persona instructs it.** `nowli-ai/test17.py`,
      `_REALTIME_PERSONA_EN`:

      > "Reflect back what you actually hear before responding, so {user_name} feels
      > understood."

      Unconditional, and "before responding" makes it a step in every turn. The line came in
      with the calm-companion rewrite and the intent was right — it is the fix for a companion
      that talks past you — but as written it has no "sometimes" and no "only when it adds
      something".
      **When picking this up:** rewrite the line so reflecting is occasional and earned
      (something like: reflect only when it genuinely helps, and when you do, use your own
      words rather than repeating theirs; usually just respond to what they said). Then
      **listen to a real call** — this cannot be judged from the prompt text, and the emulator
      routes no microphone, so it needs a phone and a billable call.
      Two things to keep in mind while editing that block: the **non-English path does not use
      this persona at all** (it falls back to `_build_system_prompt`), so check whether the
      same complaint applies there; and per CLAUDE.md the three provider callers stay in sync,
      though this particular string is realtime-only. Rollback is documented above the persona.

- [ ] **Google Client ID cleanup.** `docs/google-login.md` lists two conflicting Web client
      IDs (`274971792537-m5oca…` active/verified vs. a stale `1042808398004-…`). Remove the
      stale reference so there's one source of truth; verify all five wiring points agree
      (`nowli-backend/.env`, three `dart_defines*.json`, `web/index.html`).
- [ ] **AI model IDs — recurring maintenance check, not an upgrade.** _Decision 2026-07-30:
      stay on the current models; they are good enough and cheaper. This item exists so the
      choice is revisited deliberately rather than discovered by an outage._
      Hardcoded today: backend `claude-opus-4-5` (`Apps/insights/ai_client.py`,
      `Apps/subtask_generator`), `nowli-ai` `gpt-4o` / `gpt-4o-mini`, Gemini
      `gemini-2.0-flash`, Realtime `gpt-realtime-mini`.
      **The risk is retirement, not obsolescence:** when a provider withdraws a model ID the
      call starts erroring and the feature stops with no warning. Insights degrades
      gracefully (fallback copy), but AI subtask generation and the voice call do not.
      **Check every ~3 months**, or immediately if a provider announces a deprecation:
      confirm each ID is still served, then either leave it or bump. Keep the three backend
      provider callers in sync (`_call_claude` / `_call_chatgpt` / `_call_gemini`).
      For reference, the current Claude generation is `claude-opus-5` / `claude-sonnet-5`.
- [ ] **Tests.** There is no test suite anywhere (backend `Apps` have no `tests.py`; `nowli-ai`
      has none). Add at least smoke/API tests for auth, quests CRUD, subtasks routing, and the
      Google login token-exchange view.
- [x] ~~**Client-side JWT refresh**~~ ✅ **done 2026-07-30.** There was no refresh route on
      the backend at all, so the app stored a refresh token it could never spend. Added
      `POST /api/auth/token/refresh/` and `lib/api/session.dart`, which reads the token's own
      `exp` locally and refreshes *before* sending rather than reacting to a 401. Refreshes
      are single-flight — rotation blacklists the old token, so two in parallel would sign
      the user out. **One follow-up:** the access-token lifetime is still the historical 31
      days so older app builds keep working. Once the new build is confirmed on devices, set
      `JWT_ACCESS_MINUTES=60` and `JWT_REFRESH_DAYS=60` in the prod `.env` — a stateless
      31-day access token cannot be revoked if it leaks.

## P3 — Features

- [x] **Insights: "Top Emotions" + "When feeling low, you often say…" (AI).** ✅ **Done 2026-07-07**
      — both sections implemented end-to-end and runtime-verified on the emulator. Fed by one
      GPT-free nowli-ai call (`/conversation/call-insights/{id}`) → `CallEmotionSnapshot` /
      `CallLowMoodSnapshot` persist → weekly aggregate → Flutter cards (Figma 1:1). See
      `daily-reports/2026-07-07.md` and `insights-emotions.md`. **Two follow-ups remain:**
  - [ ] **Replace the temporary "What this means" copy** (BOTH sections) with a real AI-generated
        summary (currently placeholder tables; `TODO(insights-emotions)` in
        `Apps/insights/services.py`). Keep it off the Insights-load hot path or cache it.
  - [ ] **Final organic voice-call test** — confirm an actual emulator call (not a seeded snapshot)
        makes the app write both `CallEmotionSnapshot` and `CallLowMoodSnapshot`, and both cards
        update.
- [ ] **Voice Call companion — persona & UX (found in the 2026-07-07 real E2E).**
  - **AI persona** — `nowli-ai/test17.py` `_FRIEND_PROMPTS` is a casual "close friend", not a Nowli
    wellbeing/reflective companion (the `neutral` default even says "don't sound like a helper").
    Reframe to supportive/reflective/empathetic + question-asking; pass the user's real companion
    name instead of hardcoded "Aria" (`ai_voice.dart _createAiSession`). Prompt edit, high impact. **(P1-impact)**
  - **Voice Call timeout UI to Figma** — implement frames Adding 2.5 min (`364-15969`), Added 2.5 min
    (`364-15790`), Less than 1 minute (`364-15945`) in `ai_voice.dart` notice widgets. Was blocked by
    the Figma MCP rate limit on 2026-07-07 — retry.
  - **Barge-in / interrupt** — let the user interrupt the AI mid-TTS (STT listens during TTS → real
    speech stops TTS → normal send). Guard echo/self-trigger; device test. `ai_voice.dart`.
  - **"Your mood" weekly bars** (`insights.dart:980–1035`) — hardcoded demo data; needs a new per-day
    backend mood source to become dynamic (new API field). Separate from Top Emotions.
  - (Optional) Persist Call Summary (currently live-only from nowli-ai, lost on restart).
- [ ] **Apple Sign-In (B2).** Fully built; disabled (returns 503) until `APPLE_CLIENT_IDS` and
      related keys are filled. Requires a paid Apple Developer account + `.p8` key + Service ID.
      See `docs/apple-login.md`.
- [ ] **Subscriptions Phase 2 — REAL payments.** _Now the biggest product gap (2026-07-29)._
      The 7-day trial, the 402 paywall and the decreasing-price lifecycle are all built, deployed
      and enforced — but `POST /subscriptions/activate/` is a **mock** and `verify-receipt/` is a
      **501 stub**, so anyone can "subscribe" for free. Needs: the `in_app_purchase` plugin,
      per-phase products in App Store Connect / Play Console (re-verify the offer templates —
      policies change), and backend receipt verification feeding the existing engine. Mobile-only;
      Stripe is not allowed for in-app digital subscriptions. See the `subscription-model` memory.
- [ ] **Remove the dead `CustomUserModel` subscription fields** (`paid_user`, `current_plan`,
      period + `is_subscribed()`/`get_subscription_period()`) — superseded by `Apps/subscriptions`.
- [ ] **Scheduled AI calls — BLOCKED ON CLIENT, do not start.** Confirmed 2026-07-29 that nothing
      exists: no notification/scheduling package in `pubspec.yaml`, no backend reminder model, and
      `set_alarm` is persisted but drives nothing (it is even hardcoded `true` on quest create).
      "Enable call" only reveals an on-demand button; "Repeat quest" materializes 7 days up-front.
      Full design notes in `voice-check-and-scheduling.md` §A.
- [ ] **Wire relocated mockups.** The `experimental/` screens and the moved `je_je_…` mockups
      (streak popup, missed-talks popup, all-quests-done popup) are unrouted — wire them into
      real routes/data when their features are built. See `cleanup-log.md`.
- [ ] **Support chat UX.** Auto-refresh / websocket instead of pull-to-refresh; mark-as-read;
      optional inbound-email → chat. See `support-feature.md`.

## P4 — Long-term tech debt

- [ ] **Seed companions as a management command.** The 6 `NowliiPredefinedOption` rows are
      seeded manually; if the SQLite DB resets, avatars break. Make a repeatable
      `manage.py` command. See `running-on-android.md`.
      **Give the model a stable `slug` while doing it.** There is no field today that
      identifies *which character* a row is, so the app has to infer it from the
      `avatar_logo` filename. Production ids are already `2, 3, 4, 6, 10, 12` from earlier
      reseeding — the id says nothing — and keying art off it shipped the wrong character
      for five of six companions (found 2026-08-12, fixed client-side in
      `companion_avatar.dart`). A `slug` the seeder sets would let the client stop parsing
      URLs; until then, **do not rename the S3 files**.
- [ ] **Reconcile unused `CustomUserModel`.** `AUTH_USER_MODEL` is never set, so the app runs
      on the default `auth.User`; `users.CustomUserModel` is migrated and referenced but unused
      — reconcile or remove. **This cost a production outage on 2026-08-06:** code written as
      if accounts were email-only created Google users with an empty `username`, which
      `auth_user` requires to be unique, so every new Google signup after the first 500ed.
      Anything reading `paid_user` / `current_plan` / `current_period_end` off the user is
      reading a table nobody writes. One row with `username=''` survives in prod from before
      the fix — harmless (lookups go by email), but it is why the collisions started.
- [x] ~~**`editFrom` avatar screen** should send `predefined_option` on update.~~ **Already
      done** — the screen sends `predefinedOption: selectedOption.id` and carries a comment
      describing the old `avatar_logo`/`nowlii_name` bug. Verified on the emulator 2026-08-14
      by switching through all six companions and watching the home card follow.
      **Note this is the only way to change a companion after signup:** `/avatarLogo`, the
      main picker, is routed from onboarding alone, so the pencil on Edit Profile → rename
      screen → its own pencil is the whole path.
- [x] ~~**Companion poses.**~~ ✅ **Done 2026-08-12** — the art landed and is wired.
      24 files (`assets/companions/<option id>_<pose>.png`, 6 characters × sleeping /
      reading / speaking / waving, transparent, 512px, 4.5 MB) imported from Figma
      `y4Wzcc018iQEfEjm8T0Yjd` node `36:8041`. `NowliiAvatar` takes a `pose:`; 12 of the 17
      call sites now name one, chosen from the asset each had replaced (`companionSleeping`,
      `homeQuestBlob` — the one with the book, `Popup_Speaking`, `callStarted`). The other
      five stay `.neutral`, which is the profile URL and was already correct.
      Poses are deliberately **bundled-only** — the backend serves one neutral picture per
      companion, so a pose can never come from S3. Guarded by `test/companion_pose_test.dart`
      (loads all 24 through `rootBundle`, so a missing file *or* a `pubspec.yaml` slip fails).
      **Two import traps, if more art arrives:** character 3 authors sleeping and speaking in
      the opposite columns to the other five, and character 5's sleeping frame also contains
      an awake copy — column position is not the pose, so look at the pictures.
      **`waving` is shipped but unclaimed** — no slot asks for it yet.
      Two things learned doing the widget, still true:
  - **The served art is transparent; only the bundled fallback tiles are not.** So
        `NowliiAvatar` draws the served art whole (`BoxFit.contain`, no clip) and applies the
        circle/rounded clip *only* on the fallback path. Clipping everything with
        `BoxFit.cover` sliced the character's feet off on the call screen.
  - **Converting a slot means replacing the picture, not the footprint.** Sizing the
        out-of-sparks companion as a 95 square rather than the original 78.885 pushed it 16pt
        into a text column capped at 200, and it ran over the words. Match the dimensions of
        the art being replaced.
      **One open decision:** `all_quests_done_popup` and `missed_talks_popup` were app-icon
      tiles — the character on an indigo rounded square. With transparent art and no clip the
      tile no longer shows. Restore it (one line per site) or leave the bare character?
      Not converted, deliberately: `Assets.svgIcons.avatar` in `popup_screen.dart` (a stock
      photo of a person, not a companion) and `upscalemedia-transformed.png` in
      `ai_call_remiender.dart` (a page background). `lib/experimental/` was left alone —
      unrouted.
- [ ] **`nowli-ai` structure.** Sessions are in-memory only (lost on restart) → add
      persistence. The `routers/` module is a parallel refactor that is **not mounted** —
      either wire it in or delete it. No dependency lockfile — add one.
- [ ] **A3 naming follow-ups.** Class/route-constant misspellings not yet aligned to their
      renamed files (e.g. `PopSpkingLoding`, `ReminederNotifications`); ambiguous names left on
      purpose (`pop_po_sahre`, `edit_from`, `create_qutes` + `AppTextStylesQutes`, `chat_boot`);
      non-snake_case build-step folders. Backend `Apps/` (capital A) left due to migration
      `app_label` risk. See `cleanup-log.md`.
- [ ] **`google_sign_in` web reliability.** v6 imperative `signIn()` is finicky on web (Android
      is the real target); consider the rendered Google button, or revisit `signInWithGoogle()`
      if upgrading to v7 (breaking API change). See `google-login.md`.
