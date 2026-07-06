# NOWLII — Cleanup Log (frontend)

_Running record of file moves/renames/deletions during PART A cleanup, so we can
trace any later build break back to a change. Newest session on top._

> **Golden rule adopted this session:** we **preserve + relocate + rename**, we do
> **not delete**. If something looks like junk, it moves to `lib/experimental/` (or a
> proper feature folder) and gets its imports fixed — nothing is thrown away.

> **Backup source of truth:** a full copy of the frontend lives at
> `Documents/Just Web (projekti)/nowlii-frontend/` (and backend at `nowlii-backend/`).
> Anything accidentally lost in `nowli-app/nowli-frontend-app/` can be restored from there.

---

## Session 2026-07-03 — A3 (frontend naming conventions)

Renamed misspelled/inconsistent folders and files under `lib/`, fixing every `package:` and
relative import that referenced them. Done in verified batches (folders first, then files);
`flutter analyze` → **0 errors** after each batch. Method: rename on disk, then
`sed` the path/filename segment across all `.dart` files, then confirm 0 leftover refs.

**Folders renamed** (segment → segment):
`utlis/`→`utils/` · `screen/Onboarding/`→`onboarding/` · `ProfileSetup/`→`profile_setup/` ·
`onbording_flow_file/`→`onboarding_flow_file/` · `home/swaipe_to_talk/`→`swipe_to_talk/` ·
`voice_cheack/`→`voice_check/` · `remiender_notification/`→`reminder_notification/` ·
`ai_call_remiender/`→`ai_call_reminder/` · `default-yellow/`→`default_yellow/` ·
`error_tueast/`→`error_toast/` · `success_tueast/`→`success_toast/` ·
`create_quets/`→`create_quests/` · `my_quets/`→`my_quests/` ·
`repeat_quest_repit_edit_card_/`→`repeat_quest_edit_card/` · `enabable_card/`→`enable_card/` ·
`enabable_card_edit/`→`enable_card_edit/` · `profile/Edit_profile/`→`edit_profile/` ·
`settings/subcription/`→`subscription/` · `notiofication_scren/`→`notification_screen/` ·
`contact_support/sopprt/`→`support/` · `restricted_topiccs_popup/`→`restricted_topics_popup/` ·
`welcome_activetion_flow/`→`welcome_activation_flow/` · `insights/AIInsightsScreen/`→`ai_insights_screen/`.

**Files renamed** (spelling fixes; only the file + its imports, classes left unchanged):
`loading_onboridng_nowli`→`loading_onboarding_nowli` · `onbording_fetures`→`onboarding_features` ·
`avatar_logo&name_selection`→`avatar_logo_name_selection` (had a literal `&`) ·
`pop_spking_loding`→`pop_speaking_loading` · `popup_spking_loding`→`popup_speaking_loading` ·
`swaipe_to_talk_loding`→`swipe_to_talk_loading` · `poup_error/preparing/prossing/spking/your_share_you`
→`popup_error/preparing/processing/speaking/your_share_you` · `efit_name`→`edit_name` ·
`blockng`→`blocking` · `reday_to_start_screen_p4`→`ready_to_start_screen_p4` (+ its `.backup`) ·
`error_tueast`→`error_toast` · `success_tueast`→`success_toast` · `chooise_your_mood`→`choose_your_mood` ·
`create_quets_default`→`create_quests_default` · `nowli_pro_subcription`→`nowli_pro_subscription` ·
`quests_my_quests_today_emty_state`→`…_empty_state` · `tomorow_card`→`tomorrow_card` ·
`enabable_card(_edit)`→`enable_card(_edit)`.

**Deliberately NOT renamed (ambiguous / higher-risk — need product knowledge, left for a later pass):**
- `screen/ai_call/pop_po_sahre.dart`, `profile/edit_profile/edit_from.dart` (form? from?),
  `themes/create_qutes.dart` + class `AppTextStylesQutes` (quotes? quests?),
  `contact_support/chat_boot/` (bot? boot?) — unclear intended spelling.
- camelCase build-step folders under `create_quests/` & `edit_quest/` (`_buildInputCard`,
  `buildHeader`, `buildTitle`, `buildAddSubtasksButton`) — not misspelled, just non-snake_case.
- **Class / route-constant** misspellings (e.g. `PopSpkingLoding`, `ReminederNotifications`) —
  files were renamed but the class identifiers were left to keep this pass low-risk.
- Backend **`Apps/`** (capital A) — left intentionally (migration `app_label` risk), per `next-phase.md`.

**Verification:** `flutter analyze` → **0 errors** (396 issues total, all pre-existing
`info`/`warning` lint). No live route/import broke.

---

## Session 2026-07-03 — A4 (backend: route the subtasks CRUD endpoint)

`SubTasksViewset` existed but was never routed. Registered it **and** fixed two latent
problems so the endpoint actually works. Files touched (all in `nowli-backend/`):

- **`Apps/quests/urls.py`** — `router.register(r'subtasks', SubTasksViewset)`.
- **`core/urls.py`** — **reordered** the includes so `path("api/subtasks/", …generator…)`
  sits **above** `path('api/', …quests…)`. Reason: the new `subtasks` router adds a
  `subtasks/<pk>/` detail route whose `[^/.]+` pk would otherwise swallow
  `subtasks/generate/` (pk="generate") and shadow the AI generate endpoint. A comment in
  the file records this ordering requirement.
- **`Apps/quests/serializers.py`** — added `SubTasksCrudSerializers` (`fields = '__all__'`,
  so the `task` FK is **writable**). The old `SubTasksSerializers` (`exclude = ['task']`)
  is unchanged and still used nested inside `QuestsSerializers`.
- **`Apps/quests/views.py`** — `SubTasksViewset` now uses `SubTasksCrudSerializers`;
  removed `parser_classes = [MultiPartParser, FormParser]` (subtasks have no file field —
  the restriction blocked JSON, which the Flutter client sends); added `perform_create` /
  `perform_update` that reject attaching a subtask to another user's quest
  (`PermissionDenied`). Dropped the now-unused parser import.

**Why the serializer/parser changes were needed:** as-is, standalone `POST` would fail —
`SubTasks.task` is a required FK but was excluded from the serializer and no `perform_create`
set it, so a create had no way to specify the parent quest (and multipart-only blocked JSON).

**Verification:** `manage.py check` → *0 issues*. URL resolution proven via `resolve()`:
`/api/subtasks/generate/` → `GenerateSubTasksView` (not shadowed); `/api/subtasks/` →
`SubTasksViewset` list/create; `/api/subtasks/1/` → retrieve/update/partial_update/destroy;
quests routes unchanged. (No test suite exists in the repo — `Apps` has no `tests.py`, so
`manage.py test` only ever hits a discovery quirk; not run.)

Endpoints now live: `GET/POST /api/subtasks/`, `GET/PUT/PATCH/DELETE /api/subtasks/<id>/`
(all `IsAuthenticated`, scoped to the user's own quests). Not yet consumed by the frontend.

---

## Session 2026-07-03 — A1 + A2 (frontend `lib/` tidy-up)

**Verification after all changes:** `flutter analyze` → **0 errors** (397 issues total, all
pre-existing `warning`/`info` lint: `avoid_print`, `deprecated_member_use`, `unused_import`).
So none of the moves below broke a compile. Live app build is unaffected — every moved file
is **unreferenced** (not wired into routes).

### 1. `je_je_page_gula_connect_kori_nai.dart/` → real feature folders (A2)

The placeholder dir ("pages I haven't connected yet") held 4 finished-looking UI mockups
(hardcoded data, not wired). Moved + renamed; folder deleted. **Nothing imported them.**

| From (in `lib/je_je_.../`) | To | Class rename |
|---|---|---|
| `steak_popup.dart` | `lib/screen/streak/streak_popup.dart` | `StreakScreen` → `StreakPopup` |
| `popup_multi_misscal_talk.dart` | `lib/screen/remiender_notification/missed_talks_popup.dart` | `PopupMultiMisscalTalk` → `MissedTalksPopup` |
| `ai_calling.dart` | `lib/screen/ai_call/ai_calling.dart` | _(unchanged: `AiCalling`)_ |
| `quest_for_done_screen.dart` | `lib/screen/quests/all_quests_done_popup.dart` | `QuestForDoneScreen` → `AllQuestsDonePopup` |

Note: `steak_popup`'s design and `missed_talks_popup` have **no equivalent elsewhere** in the
code; the other two overlap live screens (`ai_call/ai_calling_two.dart`,
`home_screen.dart` `CompletionDialog`). All four remain **unrouted** — wire them up later.

### 2. `lib/aaa/`, `screen/test_file/`, `screen/debug/` → `lib/experimental/` (A1)

These were scratch/experiment/debug code. **First mistakenly deleted, then restored from the
`nowlii-frontend` backup**, then consolidated into one honest folder `lib/experimental/`
(instead of deleting). All **unreferenced** by the live app.

| From | To |
|---|---|
| `lib/aaa/` (whole folder) | `lib/experimental/` |
| `lib/aaa/remineder_notifications.dart` | `lib/experimental/reminder_notifications.dart` _(renamed)_ |
| `lib/aaa/clean_the_housescreen.dart` | `lib/experimental/clean_the_house_screen.dart` _(renamed)_ |
| `lib/aaa/great_job.dart` | `lib/experimental/call_summary.dart` _(renamed; class is `CallSummary`)_ |
| `lib/aaa/reminder/*` | `lib/experimental/reminder/*` |
| `lib/aaa/ai_voice_call/*` | `lib/experimental/ai_voice_call/*` |
| `lib/screen/test_file/*` | `lib/experimental/test_file/*` |
| `lib/screen/debug/profile_test_screen.dart` | `lib/experimental/debug/profile_test_screen.dart` |

Also restored (was deleted, now back in place): `lib/screen/reday_to_start_screen_p4.dart.backup`.

### 3. Import fixes made during the move

- `experimental/reminder_notifications.dart`:
  - 3 imports `package:nowlii/aaa/reminder/…` → `package:nowlii/experimental/reminder/…`
  - **`package:nowlii/core%20/app_routes/app_routes.dart` → `core/…`** (leftover trailing-space
    `core%20` bug that had survived in `aaa/`; would break analyze once reachable).
- `experimental/test_file/test_file.dart`:
  - **`package:nowlii/core%20/app_routes/app_routes.dart` → `core/…`** (same bug).

After these, a repo-wide search for `core%20`, `nowlii/aaa/`, `nowlii/screen/test_file`,
`nowlii/screen/debug`, `je_je_page_gula` → **0 matches**.

### 4. Route table change (the one place live code was edited)

`profile_test_screen.dart` (a debug screen) **was** wired into the router. To move it out of
the shipped route table, these were removed:

- `lib/core/app_routes/app_pages.dart`: the `import '…/screen/debug/profile_test_screen.dart'`
  line, and the `// Debug routes` `GoRoute` block for `profileTestScreen`.
- `lib/core/app_routes/app_routes.dart`: the `// Debug` `profileTestScreen` path constant.

**If you ever need that debug screen back in the app:** re-add a route pointing at the new
path `lib/experimental/debug/profile_test_screen.dart` (class `ProfileTestScreen`) and a
matching path constant. It compiles fine where it is; it's just not routed.

### If a build breaks after this session — where to look

1. Most moved files are **unreferenced**, so they can't break the live build. If analyze/build
   complains about one of them, it's an internal issue in that file (pre-existing lint), not wiring.
2. The only live-code edit was the **route removal** above. If a screen can't navigate to
   `profileTestScreen`, that's why (intended).
3. Watch for any **reintroduced `core%20/` imports** if code is re-copied from the old Linux box
   or the `nowlii-frontend` backup — rewrite to `core/`.
4. Full pre-cleanup copies of every moved/deleted file exist in `nowlii-frontend/lib/…`.

### Deliberately deferred (not done this session)

- **Class↔file name alignment** (e.g. `call_summary.dart` already matches `CallSummary`, but
  `reminder_notifications.dart` still declares `ReminederNotifications`) — belongs to the
  broader **A3 naming pass**; left alone to keep this change low-risk.
- Wiring any `experimental/` or relocated mockup screen into real routes/data.
