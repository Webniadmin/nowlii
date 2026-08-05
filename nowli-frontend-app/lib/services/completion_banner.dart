/// The green banner that drops in when a quest is ticked off.
///
/// It used to read "Boom, your first task completed!" and "+1 streak" on **every**
/// completion, forever. The first is false from the second tick onward; the second is
/// false more often than that, because a streak day is only earned when *every* quest
/// for the date is done (`/api/quests/streak/` counts dates where `total == done`).
/// Ticking the first of three quests advanced nothing.
///
/// The copy lives here so both claims can be tested — see `test/completion_banner_test.dart`.
library;

import 'package:shared_preferences/shared_preferences.dart';

import 'number_words.dart';

/// The headline for one completion.
///
/// [lifetimeCompletions] counts this one, so the very first tick is 1. [completedToday]
/// likewise includes it.
String completionBannerTitle({
  required int lifetimeCompletions,
  required int completedToday,
}) {
  // The moment the copy was written for, and the only one it was ever true in.
  if (lifetimeCompletions <= 1) return 'Boom, your first task completed!';
  if (lifetimeCompletions == 2) return 'Two done. That\'s a pattern starting.';

  // Later in a day, the honest thing to say is how many — it is the one number the user
  // cannot see from the banner itself.
  if (completedToday >= 2) return 'That\'s ${numberWord(completedToday)} done today.';

  return 'One more done.';
}

/// The pill on the right of the banner.
///
/// A streak day lands only when the whole day is finished, so the badge says so only then.
/// Short of that it counts down what is left, which is both true and more useful than a
/// congratulation the user has not earned yet.
String completionBannerBadge({
  required int completedToday,
  required int totalToday,
}) {
  final remaining = totalToday - completedToday;
  if (remaining <= 0) return '+1 streak';
  return '$remaining to go';
}

/// How many quests this account has ever ticked off, kept on the device.
///
/// Only the copy depends on it, and only to tell a first completion from the rest, so a
/// count that resets on reinstall is good enough — and it costs no request on the path
/// between the tap and the banner.
class CompletionCounter {
  static const _key = 'lifetime_quest_completions';

  /// Records one completion and returns the new lifetime total (1 on the first ever).
  ///
  /// A storage failure returns 1, which shows the first-completion copy — the wrong
  /// message on a rare failure is better than a crash on the happy path.
  static Future<int> record() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final next = (prefs.getInt(_key) ?? 0) + 1;
      await prefs.setInt(_key, next);
      return next;
    } catch (_) {
      return 1;
    }
  }

  /// Test seam: forget everything this device has counted.
  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // Nothing to do — the counter only drives wording.
    }
  }
}
