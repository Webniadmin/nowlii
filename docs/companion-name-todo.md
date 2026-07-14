# Companion name ("Fuzzy") — dynamic-vs-static TODO

_Created 2026-07-10. The companion/avatar name is per-user (`nowlii_name` /
`custom_nowlii_name` from `GET /api/profiles/`). Historically the UI hardcoded **"Fuzzy"**
everywhere. On 2026-07-10 we made it dynamic **only on the swipe→call path**; the rest is
left hardcoded **pending a client decision** on whether every surface should use the real
companion name._

**Source of the real name (already available):**
`ProfileData.companionName` (`lib/services/profile_service.dart`) = `custom_nowlii_name`
if set, else `nowlii_name`. Also on `ProfileModel` (`lib/api/profile_model.dart`) and via
`StorageService.getProfileData()`.

## ✅ Already made dynamic (2026-07-10)
- `lib/screen/home/swipe_to_talk/swipe_button_widget.dart` — "Swipe to talk to $companionName".
- `lib/screen/home/home_screen.dart` — passes `_profileData?.companionName` to the swipe button.
- `lib/screen/ai_call/ai_voice.dart` — AI session `system_name` = `_resolveCompanionName()`.
- `lib/screen/ai_call/call_summary_screen.dart:201` — already uses `_summary?.systemName ?? 'Fuzzy'`
  (semi-dynamic: the summary's `system_name`, which now flows from the resolved name above).

## ⛔ Still hardcoded "Fuzzy" — decide per-surface (line #s approx, may drift)

### Plain text strings (easy swap — inject the companion name)
| File | Line | Text |
|---|---|---|
| `lib/screen/home/home_screen.dart` | 219 | `'Fuzzy\'s proud of you'` (success notification) |
| `lib/screen/home/home_screen.dart` | 1045 | `'Fuzzy\'s proud of you'` (success notification) |
| `lib/screen/streak/streak_popup.dart` | 510 | `'Every day counts — Fuzzy\'s proud of you!'` |
| `lib/screen/reminder_notification/missed_talks_popup.dart` | 97 | `'Fuzzy misses you 💜 ...'` |
| `lib/screen/reminder_notification/choose_your_mood/loader.dart` | 64 | `"Fuzzy's here to make today..."` |
| `lib/screen/reminder_notification/ai_call_reminder/success_toast/success_toast.dart` | 64 | `'Fuzzy\'s proud of you'` |
| `lib/screen/reminder_notification/ai_call_reminder/ai_call_remiender.dart` | 486 | `'Swipe to talk to Fuzzy'` (also commented copies at 410/416) |
| `lib/screen/welcome_activation_flow/notice_loader_screen.dart` | 142 | `"Fuzzy's here to make today..."` |
| `lib/screen/welcome_activation_flow/popup_choose_mood_updates.dart` | 76 | `"Fuzzy can gently check in each day..."` |
| `lib/screen/onboarding/popup_choose_mood_updates.dart` | 80 | `"Fuzzy can gently check in each day..."` |
| `lib/screen/settings/subscription/subscription_popup.dart` | 372 | `'Daily talks with Fuzzy'` (card title) |

### Baked-in-text PNG assets (CANNOT swap with a string — need new assets or replace with a Text widget)
| File | Line | Asset |
|---|---|---|
| `lib/screen/home/swipe_to_talk/swipe_button_widget.dart` | 102 | `Swipe to talk to Fuzzy.png` — used as the round **knob avatar** (not text), likely fine to leave |
| `lib/screen/reminder_notification/ai_call_reminder/ai_call_remiender.dart` | 480 | `Swipe to talk to Fuzzy.png` |
| `lib/screen/settings/subscription/subscription_popup.dart` | 371 | `Daily talks with Fuzzy.png` |
| `lib/screen/quests/all_quests_done_popup.dart` | 33 | `Daily talks with Fuzzy.png` |
| assets: `assets/svg_icons/Swipe to talk to Fuzzy.png`, `assets/svg_icons/Daily talks with Fuzzy.png` | — | referenced via `assets.gen.dart` (`swipeToTalkToFuzzy`, `dailyTalksWithFuzzy`) |

### Related data-consistency issue (separate from "Fuzzy")
- `lib/screen/onboarding/onboarding_features/avatar_logo_name_selection.dart:73` —
  `avatarNames = ['KNOTTY','BLOOBY','FUZZY','SNOOZY','GRUMPY','SLEEPY']`. These frontend
  picker names **do not match** the backend seed (`milo, bloop, gumo, knotty, Fizzy, zee`
  per `profile_model.dart` `validNowliiNames`). Worth reconciling so the chosen name persists.

## Notes for whoever does the full pass
- Most surfaces don't hold a live `Profile`; you'll need to fetch it (`ProfileService`) or
  read `StorageService.getProfileData()` and thread the name in. Notifications built far from
  a profile fetch are the fiddly ones.
- Experimental copies under `lib/experimental/**` also say "Fuzzy" — ignore (not in the app).
