# Future Checklist

_All work we have consciously deferred, organized by priority. When we start an item,
move it into `daily-checklist.md` for the day. When it's done, remove it here and record
it in that day's report. Detailed context for most items lives in `next-phase.md` and the
per-feature docs._

Priority tiers: **P1** = security / must-do soon · **P2** = correctness & quality ·
**P3** = features · **P4** = long-term tech debt.

---

## P0 — Blocks the store listing

- [ ] **Terms of Service does not exist.** The document was never written, so both places it
      was referenced now hide the link rather than show dead text: the sign-up screen
      (`lib/screen/auth/sign_up.dart`) and Settings → Privacy (`privacy_data_screen.dart`).
      Both are marked `TODO(legal)`. **To restore:** publish the document, set
      `ApiConstants.termsOfServiceUrl`, and uncomment the two blocks.
      Privacy Policy is done — https://www.nowlii.com/privacy-policy, live and reachable
      from both screens.
- [ ] **HTTPS for the API.** Domain is `nowlii.com` (www is a Figma-hosted site behind
      Cloudflare; the apex parks at a registrar IP). **Blocked on one DNS record:** an
      `A` record for `api.nowlii.com` → `16.170.191.239`, DNS-only (grey cloud) so
      Let's Encrypt can answer the HTTP-01 challenge on the box. Once it resolves:
      nginx + certbot in front of :8000 and :8001, switch `dart_defines.prod.json` to
      `https://`, then flip the HTTPS block in `~/backend/.env` (see `.env.example`).
      Until then a **release** build cannot reach the backend at all — see `deploy-aws.md`.
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

- [ ] **Google Client ID cleanup.** `docs/google-login.md` lists two conflicting Web client
      IDs (`274971792537-m5oca…` active/verified vs. a stale `1042808398004-…`). Remove the
      stale reference so there's one source of truth; verify all five wiring points agree
      (`nowli-backend/.env`, three `dart_defines*.json`, `web/index.html`).
- [ ] **AI model cleanup.** All providers hardcode older model IDs — backend `claude-opus-4-5`,
      and `nowli-ai` `gpt-4o` / `gpt-4o-mini`; Gemini `gemini-2.0-flash`. Update to current
      models and keep all three provider callers in sync (`_call_claude` / `_call_chatgpt` /
      `_call_gemini`). Current top Claude Opus is `claude-opus-4-8`.
- [ ] **Tests.** There is no test suite anywhere (backend `Apps` have no `tests.py`; `nowli-ai`
      has none). Add at least smoke/API tests for auth, quests CRUD, subtasks routing, and the
      Google login token-exchange view.
- [ ] **Client-side JWT refresh — the app looks broken after 31 days.** Nothing anywhere in
      `lib/` handles a 401, and the stored refresh token is never used. The router guard only
      checks that an `access_token` *exists*, not that it is valid, so once the 31-day access
      token expires the user is let straight into the home screen where **every request
      silently fails** — empty quests, empty Insights, refused calls — with nothing telling
      them to sign in again. Fix: on 401, try the refresh token; if that fails too, clear
      storage and route to sign-in.

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
- [ ] **Reconcile unused `CustomUserModel`.** The app runs on the default `auth.User`; the
      custom `users.CustomUserModel` is defined but unused — reconcile or remove.
- [ ] **`editFrom` avatar screen** should send `predefined_option` on update (like the main
      avatar picker) so the selection persists.
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
