import 'package:flutter/foundation.dart';
import 'package:nowlii/services/spark_state.dart';
import 'package:nowlii/services/subscription_service.dart';
import 'package:nowlii/services/voice_call_service.dart';

/// One shared copy of "how many sparks are left today", so the home card, the swipe
/// button and the call screen can never show different numbers.
///
/// The alternative — each widget calling `getQuota()` itself — reliably goes stale: the
/// home screen is built once, a call is taken, and it keeps offering a swipe button for an
/// allowance that is already gone until the user happens to pull-to-refresh.
///
/// Refresh points, mirroring what `CallReminderService.sync()` already does:
///   * home screen load / pull-to-refresh,
///   * the moment a call is authorized (the `start/` response carries fresh numbers, so
///     that costs no extra request),
///   * after a call ends.
class SparkStateStore {
  SparkStateStore._();

  static final SparkStateStore instance = SparkStateStore._();

  final ValueNotifier<SparkState> state =
      ValueNotifier<SparkState>(const SparkState.unknown());

  final VoiceCallService _service = VoiceCallService();

  /// Re-read the allowance from the backend. A failed read leaves the previous value in
  /// place rather than blanking it — a dropped request is not evidence of anything.
  ///
  /// One failure is evidence, though: a lapsed plan. The quota endpoint answers 402 and
  /// will keep doing so, so treating that like a dropped request leaves the home card
  /// saying "Checking your sparks…" forever and still offering a call.
  Future<void> refresh() async {
    final quota = await _service.getQuota();
    if (quota == null) {
      if (!await SubscriptionService.cachedHasAccess()) {
        state.value = const SparkState.paused();
      }
      return;
    }
    state.value = SparkState(limit: quota.limit, remaining: quota.remaining);
  }

  /// Record the numbers returned when a call was registered, avoiding a second request.
  void adopt({required int limit, required int remaining}) {
    state.value = SparkState(limit: limit, remaining: remaining);
  }
}
