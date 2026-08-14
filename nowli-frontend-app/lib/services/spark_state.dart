/// The daily AI-call allowance, as the product language calls it: **sparks**.
///
/// The backend is the only authority on how many calls a user has left
/// (`GET /voice-calls/quota/`, and the `start/` response). This file owns the small
/// amount of arithmetic and wording that sits on top of those numbers, so the call
/// screen, the home card and the swipe button cannot drift apart.
///
/// Two edges are the whole reason this is a type rather than a pair of ints:
///
///  * **Unlimited accounts.** QA/test users on `VOICE_CALL_UNLIMITED_USERS` get
///    `limit: -1, remaining: -1`. Rendered naively that reads "Spark 1 of -1", and every
///    "you're out of sparks" branch would be wrong for them.
///  * **An unknown quota.** A failed fetch must never look like "you're out". The backend
///    gates the call anyway, so the honest thing on the client is to say nothing —
///    hide the counter, keep the normal button — rather than guess.
///
/// Pure Dart, no Flutter — see `test/spark_state_test.dart`.
library;

class SparkState {
  /// Calls allowed per day. Negative means unlimited.
  final int limit;

  /// Calls left today. Negative means unlimited.
  final int remaining;

  /// False when the quota could not be read. Everything user-facing degrades to
  /// "don't claim anything" in that case.
  final bool known;

  /// The allowance is not unknown — it is withheld, because the plan has lapsed.
  ///
  /// Worth its own flag rather than reusing [unknown]: unknown is deliberately silent and
  /// keeps the normal button, which is right for a dropped request and wrong here. A lapsed
  /// user left on "Checking your sparks…" waits for an answer that is never coming, and is
  /// still invited to start a call the backend will refuse.
  final bool paused;

  const SparkState({required this.limit, required this.remaining})
      : known = true,
        paused = false;

  const SparkState.unknown()
      : limit = 0,
        remaining = 0,
        known = false,
        paused = false;

  const SparkState.paused()
      : limit = 0,
        remaining = 0,
        known = true,
        paused = true;

  /// The user bypasses the daily limit entirely.
  bool get unlimited => known && !paused && (limit < 0 || remaining < 0);

  /// True only when we *know* the allowance is gone. Unknown is never spent.
  ///
  /// A paused allowance counts: there is no call to be had, and the button must stop
  /// offering one. What differs is the wording — see [spentEyebrow].
  bool get isSpent => known && !unlimited && remaining <= 0;

  /// Sparks already started today.
  int get used => known && !unlimited ? (limit - remaining).clamp(0, limit) : 0;

  /// Which spark is running right now, 1-based, for a call that has just been
  /// registered — the `start/` response returns the quota *after* the call was counted,
  /// so the call in progress is `limit - remaining`.
  ///
  /// Null when there is nothing truthful to show (unlimited, or quota unknown).
  int? get currentSpark {
    if (!known || unlimited || limit <= 0) return null;
    return (limit - remaining).clamp(1, limit);
  }

  /// "Spark 1 of 2", or null when the counter should be hidden entirely.
  String? get counterLabel {
    final current = currentSpark;
    if (current == null) return null;
    return 'Spark $current of $limit';
  }

  /// Eyebrow copy for the out-of-sparks card. The design says "Both sparks used", which
  /// only reads correctly while the limit is 2 — it is a settings-driven value
  /// (`VOICE_CALL_DAILY_LIMIT`), so anything else falls back to a wording that survives.
  String get spentEyebrow {
    // Nothing was used — the plan ended. Saying "both sparks used" to someone who has not
    // had a call today would be a small lie about their own day.
    if (paused) return 'Plan ended';
    return limit == 2 ? 'Both sparks used' : 'All sparks used';
  }

  @override
  String toString() {
    if (paused) return 'SparkState.paused()';
    return known
        ? 'SparkState(limit: $limit, remaining: $remaining)'
        : 'SparkState.unknown()';
  }

  @override
  bool operator ==(Object other) =>
      other is SparkState &&
      other.known == known &&
      other.paused == paused &&
      other.limit == limit &&
      other.remaining == remaining;

  @override
  int get hashCode => Object.hash(known, paused, limit, remaining);
}
