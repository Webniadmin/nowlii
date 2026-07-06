# System Constraints

_Runtime / stack constraints we operate within — behavior that follows from the
infrastructure and frameworks (Django, the database engine, timezone handling), **not**
from bugs or debt. These are documented so we understand the boundaries and make informed
choices; they are not "technical debt" (see `technical-debt.md`, which is inherited legacy
problems only) and not defects in our own design (see the design notes in `architecture.md`)._

_Each item: area, constraint, effect on us, how we handle it._

---

### SC-001 — The daily-limit day boundary is the server timezone (UTC)
- **Area:** Django `TIME_ZONE = 'UTC'`, `USE_TZ = True`;
  `Apps/voice_calls/views.py` `_calls_used_today()` uses `timezone.localdate()`.
- **Constraint:** With `USE_TZ` on, "today" is computed in the configured server timezone,
  which is UTC. So the AI-call daily counter resets at 00:00 **UTC**, not at each user's
  local midnight.
- **Effect on us:** For a user in another timezone the reset happens at their local
  equivalent of UTC midnight. This is a property of how Django resolves dates, not a bug.
- **How we handle it:** Accepted for now (single server-day semantics). If the product ever
  requires a user-local reset, we would send the device timezone/offset and compute the day
  boundary per user — a deliberate change, tracked as a product decision, not debt.

### SC-002 — Row-level locking (`select_for_update`) is a no-op on SQLite
- **Area:** Django ORM on the database engine;
  `Apps/voice_calls/views.py` `VoiceCallStartView.post()` locks the user row inside a
  transaction to serialize concurrent "start" requests.
- **Constraint:** `select_for_update()` provides real row locking only on engines that
  support it (PostgreSQL — used in production). On SQLite (local dev) it is a documented
  no-op.
- **Effect on us:** The race protection for the daily limit is fully effective on the
  production database (Postgres) but not on a local SQLite dev database, where two
  near-simultaneous start requests could theoretically both pass the check.
- **How we handle it:** Rely on Postgres wherever concurrency matters (prod). The code is
  written correctly for the engine that enforces it; no change needed for the stack we ship
  on. If stronger local guarantees are ever required, a DB-level unique/constraint guard
  could be added.
