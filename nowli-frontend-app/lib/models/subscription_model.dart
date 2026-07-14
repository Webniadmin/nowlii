/// Subscription data models mirroring Apps/subscriptions on the backend.
///
/// NOWLII's plan steps the monthly price down over the first year, then becomes free
/// forever. The backend is the source of truth; these models just carry its output.

class SubscriptionPhase {
  final int fromMonth;
  final int toMonth;
  final double price;

  SubscriptionPhase({
    required this.fromMonth,
    required this.toMonth,
    required this.price,
  });

  factory SubscriptionPhase.fromJson(Map<String, dynamic> json) {
    return SubscriptionPhase(
      fromMonth: json['from_month'] ?? 0,
      toMonth: json['to_month'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}

class SubscriptionPlan {
  final String currency;
  final int freeAfterMonth;
  final List<SubscriptionPhase> phases;

  SubscriptionPlan({
    required this.currency,
    required this.freeAfterMonth,
    required this.phases,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      currency: json['currency'] ?? 'USD',
      freeAfterMonth: json['free_after_month'] ?? 12,
      phases: (json['phases'] as List?)
              ?.map((e) => SubscriptionPhase.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SubscriptionStatus {
  final bool subscribed;
  final String status; // none | active | lifetime_free | cancelled | expired
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
  });

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
    );
  }
}
