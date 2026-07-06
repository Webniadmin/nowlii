# Future Checklist

_All work we have consciously deferred, organized by priority. When we start an item,
move it into `daily-checklist.md` for the day. When it's done, remove it here and record
it in that day's report. Detailed context for most items lives in `next-phase.md` and the
per-feature docs._

Priority tiers: **P1** = security / must-do soon · **P2** = correctness & quality ·
**P3** = features · **P4** = long-term tech debt.

---

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
- [ ] **Client-side JWT refresh.** No automatic refresh-token rotation on the client — services
      just send the stored access token. Add refresh handling on 401.

## P3 — Features

- [ ] **Apple Sign-In (B2).** Fully built; disabled (returns 503) until `APPLE_CLIENT_IDS` and
      related keys are filled. Requires a paid Apple Developer account + `.p8` key + Service ID.
      See `docs/apple-login.md`.
- [ ] **Subscriptions / payments.** Currently UI-only: `CustomUserModel` has `paid_user` /
      `current_plan` / period fields and the frontend has pro screens, but there is **no
      payment integration** (no Stripe/IAP, no purchase/webhook endpoint). Nothing can change
      a user's plan.
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
