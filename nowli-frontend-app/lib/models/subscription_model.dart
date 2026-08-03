/// Subscription data models mirroring Apps/subscriptions on the backend.
///
/// NOWLII's plan steps the monthly price down over the first year, then becomes free
/// forever. The backend is the source of truth; these models just carry its output.

class SubscriptionPhase {
  final int fromMonth;
  final int toMonth;
  final double price;

  /// The stage's name on the paywall — "Spark", "Rhythm", … Served by the backend, which
  /// owns the schedule, so the app cannot hold a second list that drifts from the prices
  /// it labels.
  final String stage;

  SubscriptionPhase({
    required this.fromMonth,
    required this.toMonth,
    required this.price,
    this.stage = '',
  });

  factory SubscriptionPhase.fromJson(Map<String, dynamic> json) {
    return SubscriptionPhase(
      fromMonth: json['from_month'] ?? 0,
      toMonth: json['to_month'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      stage: json['stage'] ?? '',
    );
  }
}

class SubscriptionPlan {
  final String currency;
  final int freeAfterMonth;
  final List<SubscriptionPhase> phases;

  /// What the free-forever stage is called. Not a phase — there is no price to bill.
  final String graduatedStage;

  SubscriptionPlan({
    required this.currency,
    required this.freeAfterMonth,
    required this.phases,
    this.graduatedStage = 'Graduated',
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      currency: json['currency'] ?? 'USD',
      freeAfterMonth: json['free_after_month'] ?? 12,
      graduatedStage: json['graduated_stage'] ?? 'Graduated',
      phases: (json['phases'] as List?)
              ?.map((e) => SubscriptionPhase.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SubscriptionStatus {
  final bool subscribed;
  final String status; // none | trial | active | lifetime_free | cancelled | expired
  final String currency;
  final String? platform;
  final String? startedAt;
  final int monthIndex;
  final String phase;
  final double currentPrice;
  final double nextPrice;
  final bool isFree;
  final bool lifetimeFree;
  final bool hasAccess;

  // ── Free trial ─────────────────────────────────────────────────────────────
  /// True only while access is coming FROM the trial — a user who subscribes on day 3
  /// is a paying customer, so this goes false even though the 7-day window is still open.
  final bool inTrial;
  final int trialDaysLeft;
  final String? trialEndsAt;
  final int trialDaysTotal;
  /// True once the user has ever had a trial — it is never granted twice.
  final bool trialUsed;

  SubscriptionStatus({
    required this.subscribed,
    required this.status,
    required this.currency,
    required this.platform,
    required this.startedAt,
    required this.monthIndex,
    required this.phase,
    required this.currentPrice,
    required this.nextPrice,
    required this.isFree,
    required this.lifetimeFree,
    required this.hasAccess,
    required this.inTrial,
    required this.trialDaysLeft,
    required this.trialEndsAt,
    required this.trialDaysTotal,
    required this.trialUsed,
  });

  /// The trial ran out and nothing was bought — this is the paywall state.
  bool get trialExpired => !hasAccess && trialUsed;

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      subscribed: json['subscribed'] ?? false,
      status: json['status'] ?? 'none',
      currency: json['currency'] ?? 'USD',
      platform: json['platform'],
      startedAt: json['started_at'],
      monthIndex: json['month_index'] ?? 0,
      phase: json['phase'] ?? '',
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      nextPrice: (json['next_price'] ?? 0).toDouble(),
      isFree: json['is_free'] ?? false,
      lifetimeFree: json['lifetime_free'] ?? false,
      hasAccess: json['has_access'] ?? false,
      inTrial: json['in_trial'] ?? false,
      trialDaysLeft: json['trial_days_left'] ?? 0,
      trialEndsAt: json['trial_ends_at'],
      trialDaysTotal: json['trial_days_total'] ?? 7,
      trialUsed: json['trial_used'] ?? false,
    );
  }
}
