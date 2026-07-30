/// Decides when Nowlii should mention the clock during a voice call.
///
/// Pulled out of the call screen so the rules are testable without a device, a mic or a
/// WebRTC connection — they are fiddly enough to be worth pinning down:
///  * the spoken warning must fire exactly **once** per end-approach, not once per tick;
///  * extending the call must **re-arm** it, so the user is warned before the real end too;
///  * after the extension is spent there is no card left to tap, so the wording differs;
///  * silent time updates must not pile up on top of the spoken warning.
///
/// Pure Dart, no Flutter imports. See `test/call_time_announcer_test.dart`.
library;

/// What the call screen should do on this tick. `null` means "nothing".
enum CallTimeCue {
  /// Say out loud that time is nearly up and the call can still be extended.
  speakEndingSoonCanExtend,

  /// Say out loud that time is nearly up and the call is wrapping up for good.
  speakEndingSoonFinal,

  /// Quietly tell the model how much time is left (it must not read this out).
  sendSilentTimeContext,
}

class CallTimeAnnouncer {
  CallTimeAnnouncer({
    required this.promptSeconds,
    required this.leadSeconds,
    required this.contextIntervalSeconds,
  })  : assert(promptSeconds > 0),
        assert(leadSeconds >= 0),
        assert(contextIntervalSeconds > 0);

  /// Seconds remaining when the "Add 2.5 minutes" card appears.
  final int promptSeconds;

  /// How far ahead of that card the spoken warning goes out.
  final int leadSeconds;

  /// How often the silent time context is refreshed.
  final int contextIntervalSeconds;

  bool _spokenWarningSent = false;
  bool _extensionUsed = false;
  int _lastContextBucket = -1;

  /// The moment the spoken warning goes out — [leadSeconds] before the card appears.
  int get warnAtSeconds => promptSeconds + leadSeconds;

  bool get spokenWarningSent => _spokenWarningSent;

  /// Call once per second with the seconds left in the call.
  CallTimeCue? onTick(int remainingSeconds) {
    // The call is over; the end-of-call flow takes it from here.
    if (remainingSeconds <= 0) return null;

    if (remainingSeconds <= warnAtSeconds) {
      if (_spokenWarningSent) return null; // already warned, and too late for chit-chat
      _spokenWarningSent = true;
      return _extensionUsed
          ? CallTimeCue.speakEndingSoonFinal
          : CallTimeCue.speakEndingSoonCanExtend;
    }

    // Comfortably mid-call: keep the model's sense of time fresh, once per interval.
    final bucket = remainingSeconds ~/ contextIntervalSeconds;
    if (bucket == _lastContextBucket) return null;
    _lastContextBucket = bucket;
    return CallTimeCue.sendSilentTimeContext;
  }

  /// The user tapped "Add 2.5 minutes".
  ///
  /// Re-arms the spoken warning so they are told again before the (now later) real end —
  /// that second warning is the `final` variant, since the one extension is spent.
  void onExtended() {
    _extensionUsed = true;
    _spokenWarningSent = false;
    _lastContextBucket = -1;
  }

  /// Whether the extension has been spent — drives the wording of the warning.
  bool get extensionUsed => _extensionUsed;
}
