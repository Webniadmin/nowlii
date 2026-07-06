# Daily Checklist

_The single active document for the current working day. Update **only this file**
during the day. At end of day, write a report in `daily-reports/` and reset this list
for tomorrow. Deferred items go to `future-checklist.md`._

**Day:** 2026-07-06

---

## 🔨 In progress

- [x] Project organization: initialize Git, add root `.gitignore`, first commit
- [x] Set up documentation workflow (`daily-checklist.md`, `future-checklist.md`, `daily-reports/`)

## ⏭️ Next today (awaiting approval)

- [ ] Confirm daily workflow and pick the first real task, e.g.:
  - Build the debug `.apk` for a physical phone (everything is prepared —
    `flutter build apk --debug --dart-define-from-file=dart_defines.phone.json`), **or**
  - Start a `future-checklist.md` item (see that file for priorities).

## 📝 Notes

- Servers must be restarted after any reboot (see `running-locally.md` /
  `running-on-android.md`). Background servers do not survive a reboot.
- Working rules in effect: don't change existing business logic; update docs after each
  finished feature; commit after each larger logical unit.
- Full reference lives in `architecture.md`, `project-status.md`, `next-phase.md`, and the
  per-feature docs. This checklist only tracks **today's** active work.
