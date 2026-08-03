import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/models/subscription_model.dart';
import 'package:nowlii/services/number_words.dart';
import 'package:nowlii/services/subscription_service.dart';
import 'package:nowlii/services/subscription_schedule.dart';
import 'package:nowlii/widget/paywall_cta.dart';

/// The paywall / subscribe screen.
///
/// Reached three ways: from the "Nowlii Pro" entry in the profile, from the trial screen,
/// and by the router when someone's trial has run out — in that last case they cannot go
/// anywhere else, so this screen has to carry the whole pitch.
///
/// The pitch is the schedule: the price steps down every three months and then stops. That
/// is unusual enough that showing it as dated rows is the argument — a single "$19.99/mo"
/// would say the opposite of what the plan actually does.
class NowliProSubscription extends StatefulWidget {
  const NowliProSubscription({super.key});

  @override
  State<NowliProSubscription> createState() => _NowliProSubscriptionState();
}

class _NowliProSubscriptionState extends State<NowliProSubscription> {
  final SubscriptionService _subService = SubscriptionService();
  SubscriptionStatus? _status;
  SubscriptionPlan? _plan;
  bool _activating = false;

  /// True when the router sent the user here because they'd lost access (trial over),
  /// as opposed to them opening the screen from the profile menu. Drives whether a
  /// successful purchase jumps back into the app.
  bool _openedAsPaywall = false;

  static const Color _bg = Color(0xFF011F54);
  static const Color _ink = Color(0xFFFFFEF8);
  static const Color _lilac = Color(0xFFA9A8F6);
  static const Color _orange = Color(0xFFFF8F26);
  static const Color _cardInk = Color(0xFF011F54);
  static const Color _cardMuted = Color(0xFF4C586E);
  static const Color _caption = Color(0xFFC8CBD2);

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    final results = await Future.wait([
      _subService.getPlan(),
      _subService.getMyStatus(),
    ]);
    if (!mounted) return;
    final status = results[1] as SubscriptionStatus?;
    setState(() {
      _plan = results[0] as SubscriptionPlan?;
      _status = status;
      // No access on open ⇒ the router redirected them here as a paywall.
      _openedAsPaywall = status != null && !status.hasAccess;
    });
  }

  // Real full/first-phase monthly price from the backend; falls back to the design value.
  double get _monthlyPrice {
    if (_status?.subscribed == true && !(_status?.isFree ?? false)) {
      return _status!.currentPrice;
    }
    if (_plan != null && _plan!.phases.isNotEmpty) return _plan!.phases.first.price;
    return 19.99;
  }

  bool get _isFreeForever => _status?.lifetimeFree ?? false;
  bool get _isSubscribed => _status?.subscribed == true && _status?.hasAccess == true;

  /// The day the paid schedule counts from: when they actually subscribed, or today for
  /// someone still deciding — in which case the dates read as "if you subscribe now"
  /// rather than being anchored to nothing.
  DateTime get _anchor {
    final started = _status?.startedAt;
    if (started != null) {
      final parsed = DateTime.tryParse(started);
      if (parsed != null) return parsed.toLocal();
    }
    return DateTime.now();
  }

  List<PriceStep> get _schedule =>
      buildPriceSchedule(plan: _plan, anchor: _anchor);

  /// "for the next three months" — how long the price being quoted actually holds.
  String get _firstPhaseDuration {
    final phases = _plan?.phases;
    if (phases == null || phases.isEmpty) return 'for the next three months';
    final first = phases.first;
    final months = first.toMonth - first.fromMonth + 1;
    if (months <= 0) return 'billed monthly';
    if (months == 1) return 'for the first month';
    return 'for the next ${numberWord(months)} months';
  }

  // Phase-1 MOCK activation (real Apple IAP / Google Play Billing comes later).
  Future<void> _subscribe() async {
    setState(() => _activating = true);
    final status = await _subService.activateMock();
    if (!mounted) return;
    setState(() {
      _activating = false;
      if (status != null) _status = status;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status != null
            ? 'Subscription active — month ${status.monthIndex}, \$${status.currentPrice.toStringAsFixed(2)}/mo'
            : 'Could not activate subscription. Please try again.'),
        backgroundColor: status != null ? Colors.green : Colors.red,
      ),
    );

    // Someone who landed here because their trial ran out is stuck on this screen until
    // they pay — once access is back, let them straight into the app. A user who opened
    // the screen themselves (from the profile menu) stays put.
    if (status != null && status.hasAccess && _openedAsPaywall) {
      context.go(AppRoutespath.homeScreen);
    }
  }

  void _dismiss() {
    // A user whose trial expired has nowhere else to be — the router would only send them
    // straight back. Everyone else gets a working close button.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutespath.homeScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _schedule;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 20),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0x1FFFFEF8),
                      shape: BoxShape.circle,
                    ),
                    child: Assets.svgIcons.paywallClose.svg(width: 15, height: 15),
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildHeroPrice(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hidden rather than faked when the plan has not loaded: an
                          // empty schedule card would be a frame full of nothing, and
                          // invented dates on a pricing promise are worse.
                          if (schedule.isNotEmpty) ...[
                            _buildScheduleCard(schedule),
                            const SizedBox(height: 14),
                            Text(
                              'Tied to the date you joined — not to minutes, not to '
                              'anything you have to keep up.',
                              style: GoogleFonts.workSans(
                                color: _caption,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
              child: Column(
                children: [
                  _buildCta(),
                  const SizedBox(height: 13),
                  Text(
                    'Cancel anytime · no card games, no win-backs',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: const Color(0x8CFFFEF8),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroPrice() {
    final price = _monthlyPrice;
    final dollars = price.floor();
    final cents = ((price - dollars) * 100).round().toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: ShapeDecoration(
              color: const Color(0x12FFFFFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
                side: const BorderSide(color: Color(0x1FFFFFFF)),
              ),
            ),
            child: Text(
              'DESIGNED TO BE OUTGROWN',
              style: GoogleFonts.martianMono(
                color: _lilac,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('\$',
                    style: GoogleFonts.archivoBlack(
                        color: _lilac, fontSize: 40)),
                const SizedBox(width: 4),
                Text('$dollars',
                    style: GoogleFonts.archivoBlack(
                        color: _orange, fontSize: 104)),
                const SizedBox(width: 4),
                Text('.$cents',
                    style: GoogleFonts.archivoBlack(
                        color: _orange, fontSize: 40)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'per month · $_firstPhaseDuration',
            textAlign: TextAlign.center,
            style: GoogleFonts.workSans(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.22,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(List<PriceStep> schedule) {
    const dotColours = [
      Color(0xFFFF8F26),
      Color(0xFFFFA551),
      Color(0xFFFFCB9B),
      Color(0xFFC3DBFF),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
        color: _ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _orange, width: 1.5),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x21011F54),
            blurRadius: 12,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WE DON’T WANT YOUR TIME AND MONEY IF WE ARE NOT MAKING YOUR '
            'LIFE BETTER !',
            style: GoogleFonts.workSans(
              color: _cardInk,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < schedule.length; i++)
            _ScheduleRow(
              step: schedule[i],
              dotColour: dotColours[i.clamp(0, dotColours.length - 1)],
              isLast: i == schedule.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildCta() {
    // Already paying: there is nothing to swipe for. Showing the live state beats an
    // action that would either do nothing or take their money twice.
    if (_isSubscribed) {
      return PaywallTapButton(
        label: _isFreeForever
            ? 'Active — free forever'
            : 'Active — \$${_monthlyPrice.toStringAsFixed(2)}/mo',
        knobIcon: Assets.svgIcons.paywallSparkle.svg(width: 24, height: 24),
        onTap: null,
      );
    }

    return PaywallSwipeButton(
      label: _activating ? 'Just a moment…' : 'Swipe to Subscribe',
      knobIcon: Assets.svgIcons.paywallArrowRight.svg(width: 14, height: 14),
      enabled: !_activating,
      onConfirm: _subscribe,
    );
  }
}

/// One dated price change inside the white schedule card.
class _ScheduleRow extends StatelessWidget {
  final PriceStep step;
  final Color dotColour;
  final bool isLast;

  const _ScheduleRow({
    required this.step,
    required this.dotColour,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final confirmed = step.confirmed;
    final ink = confirmed
        ? _NowliProSubscriptionState._cardInk
        : _NowliProSubscriptionState._cardMuted;

    return SizedBox(
      height: 60,
      child: Row(
        children: [
          // Dot plus the connector down to the next row.
          SizedBox(
            width: 16,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 24),
                  decoration: BoxDecoration(color: dotColour, shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: dotColour),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      step.stage,
                      style: GoogleFonts.workSans(
                        color: ink,
                        fontSize: 15,
                        fontWeight:
                            confirmed ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.dateLabel,
                      style: GoogleFonts.workSans(
                        color: _NowliProSubscriptionState._cardMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      step.priceLabel,
                      style: GoogleFonts.workSans(
                        color: ink,
                        fontSize: 17,
                        fontWeight:
                            confirmed ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(confirmed: confirmed),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool confirmed;

  const _StatusBadge({required this.confirmed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: confirmed ? const Color(0xFFE6FAF0) : const Color(0xFFF3F4F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(
        confirmed ? 'CONFIRMED' : 'PROVISIONAL',
        style: GoogleFonts.martianMono(
          color: confirmed
              ? const Color(0xFF059669)
              : _NowliProSubscriptionState._cardMuted,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
