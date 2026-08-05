import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/models/subscription_model.dart';
import 'package:nowlii/services/number_words.dart';
import 'package:nowlii/services/subscription_service.dart';
import 'package:intl/intl.dart';
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

  /// Someone who is actually paying — not merely someone the backend has a row for.
  ///
  /// `subscribed` is true for anyone with a `Subscription` record, which includes every
  /// user still inside the free trial. Reading it as "is a customer" disabled the CTA for
  /// exactly the people the screen exists to convert: the rest of the screen quoted them a
  /// price while the button underneath it was dead. `month_index` is 0 until the paid
  /// schedule starts, which is the same signal the timeline and the headline already use.
  bool get _isSubscribed => _currentMonth != null && _status?.hasAccess == true;

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

  /// The daily call allowance named in the subscriber copy. The backend owns the real
  /// number (`VOICE_CALL_DAILY_LIMIT`); this screen has no reason to fetch a quota, so it
  /// states the shipped default and stays a word, not a promise about a specific count.
  static const int _dailySparks = 2;

  /// The subscriber's 1-based billing month, or null while they are still deciding.
  ///
  /// `month_index` is 0 for anyone who has not started paying, which is exactly the "no
  /// current stage" case — the timeline then quotes a schedule instead of locating them in
  /// one.
  int? get _currentMonth {
    final index = _status?.monthIndex ?? 0;
    return index > 0 ? index : null;
  }

  List<PriceStep> get _schedule => buildPriceSchedule(
        plan: _plan,
        anchor: _anchor,
        currentMonth: _currentMonth,
      );

  /// The name of the stage the subscriber is in, from the schedule the backend owns.
  ///
  /// Falls back to the phase string rather than to a hardcoded "Spark": the stage names
  /// live in `/plan/`, and the app holding a second list of them is how they drift.
  String get _currentStageName {
    for (final step in _schedule) {
      if (step.current) return step.stage;
    }
    final phase = _status?.phase.trim() ?? '';
    return phase.isEmpty ? 'Your plan' : phase;
  }

  /// "Month 1 · \$19.99/mo. Rhythm starts 4 Nov at \$14.99."
  ///
  /// States where they are and what changes next — the two things a subscriber opens this
  /// screen to find out. Everything in it comes from the schedule, so a plan change on the
  /// backend moves the sentence with it.
  String get _membershipSummary {
    if (_isFreeForever) {
      return "You've reached the end of the ladder. Nowlii is free for you from here — "
          'same $_dailySparks sparks a day, same receipts.';
    }

    final month = _currentMonth;
    final where = month == null
        ? 'Your plan is active'
        : 'Month $month · \$${_monthlyPrice.toStringAsFixed(2)}/mo';

    // The first step after the current one, which is what "how far along" really asks.
    PriceStep? next;
    var seenCurrent = false;
    for (final step in _schedule) {
      if (seenCurrent) {
        next = step;
        break;
      }
      if (step.current) seenCurrent = true;
    }

    if (next == null) return '$where.';

    final when = next.isFinalFree
        ? DateFormat('MMMM y').format(next.startsOn)
        : DateFormat('d MMM').format(next.startsOn);
    final price = next.price <= 0
        ? 'free'
        : '\$${next.price.toStringAsFixed(2)}';
    return '$where. ${next.stage} starts $when at $price.';
  }

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
          // A subscriber is not being quoted a price — they already pay it. The headline
          // answers their question ("which plan am I on, and how far along?") instead of
          // selling. It used to read "READY TO CONTINUE? / Pick back up where you left
          // off", which is what you say to somebody who has stopped — under a timeline
          // that said CURRENT PLAN and above a button offering to sell them the thing
          // they were already paying for.
          if (_currentMonth != null) ...[
            Text(
              _isFreeForever ? 'FREE FOREVER' : _currentStageName.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.archivoBlack(color: _orange, fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              _membershipSummary,
              textAlign: TextAlign.center,
              style: GoogleFonts.workSans(
                color: _ink,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ] else ...[
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
        ],
      ),
    );
  }

  Widget _buildScheduleCard(List<PriceStep> schedule) {
    // Fading orange for a prospect: the stage on offer is solid, the rest recede. Five
    // entries because the opening stage is now a row of its own.
    const quotedDots = [
      Color(0xFFFF8F26),
      Color(0xFFFFA551),
      Color(0xFFFFC17A),
      Color(0xFFFFCB9B),
      Color(0xFFC3DBFF),
    ];

    /// A subscriber's rail is read as a journey: green behind them, orange where they
    /// stand, faded ahead.
    Color dotFor(PriceStep step, int index) {
      switch (step.status) {
        case PriceStepStatus.completed:
          return const Color(0xFF10B981);
        case PriceStepStatus.current:
          return const Color(0xFFFF8F26);
        case PriceStepStatus.next:
          return const Color(0xFFFFA551);
        case PriceStepStatus.starting:
        case PriceStepStatus.confirmed:
        case PriceStepStatus.provisional:
          return _currentMonth == null
              ? quotedDots[index.clamp(0, quotedDots.length - 1)]
              : const Color(0xFFC3DBFF);
      }
    }

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
            _currentMonth == null
                ? 'WE DON’T WANT YOUR TIME AND MONEY IF WE ARE NOT MAKING '
                    'YOUR LIFE BETTER !'
                : 'YOUR JOURNEY TIMELINE',
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
              dotColour: dotFor(schedule[i], i),
              incomingColour: i == 0 ? null : dotFor(schedule[i - 1], i - 1),
              isLast: i == schedule.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildCta() {
    // Already paying: there is nothing to swipe for. The label used to read "Continue for
    // $19.99" — a price on a primary button, which is what a purchase looks like, over an
    // onTap of null. It was inert and nothing said so; a subscriber could only find out by
    // pressing it. It now states the fact instead of offering the sale.
    if (_isSubscribed) {
      return PaywallTapButton(
        // Short on purpose: the button is one line and clips, and the price is already
        // stated twice above it — in the summary and in the timeline row.
        label: _isFreeForever ? 'Free forever' : "You're subscribed",
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

  /// Colour of the segment arriving from the row above; null on the first row, which has
  /// nothing above it to join to.
  final Color? incomingColour;
  final bool isLast;

  /// How far down the row the dot sits, so it lines up with the stage name.
  static const double _dotTopOffset = 24;

  const _ScheduleRow({
    required this.step,
    required this.dotColour,
    required this.incomingColour,
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
          // The rail. It has to read as one continuous line down the card, so each row
          // draws the segment *arriving* at its dot as well as the one leaving it —
          // otherwise the space above every dot is blank and the line looks broken.
          //
          // The arriving segment takes the colour of the row above, so a stage change is a
          // colour change at the dot rather than mid-gap.
          SizedBox(
            width: 16,
            child: Column(
              children: [
                SizedBox(
                  height: _dotTopOffset,
                  child: incomingColour == null
                      ? null
                      : Container(width: 2, color: incomingColour),
                ),
                Container(
                  width: 12,
                  height: 12,
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
            child: Container(
              padding: step.current
                  ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
                  : EdgeInsets.zero,
              decoration: step.current
                  ? BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF7941D)),
                    )
                  : null,
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
                    _StatusBadge(step: step),
                  ],
                ),
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The badge on the right of a timeline row.
///
/// Four states rather than two, because a subscriber's question is different from a
/// prospect's: behind them, on them, next, and further out.
class _StatusBadge extends StatelessWidget {
  final PriceStep step;

  const _StatusBadge({required this.step});

  static const _green = Color(0xFF059669);
  static const _greenBg = Color(0xFFE6FAF0);
  static const _orange = Color(0xFFF7941D);

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color ink;
    Border? border;

    switch (step.status) {
      case PriceStepStatus.completed:
        background = _greenBg;
        ink = _green;
        break;
      case PriceStepStatus.current:
        background = _orange;
        ink = Colors.white;
        break;
      case PriceStepStatus.next:
        background = Colors.transparent;
        ink = _NowliProSubscriptionState._cardInk;
        border = Border.all(color: const Color(0xFFD1D5DB));
        break;
      case PriceStepStatus.confirmed:
        background = _greenBg;
        ink = _green;
        break;
      case PriceStepStatus.provisional:
        background = const Color(0xFFF3F4F6);
        ink = _NowliProSubscriptionState._cardMuted;
        break;
      case PriceStepStatus.starting:
        // The stage on offer. Green like the settled ones, because its price is settled —
        // it is the one thing on this screen the user is being asked to agree to.
        background = _greenBg;
        ink = _green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        border: border,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        step.badgeLabel,
        style: GoogleFonts.martianMono(
          color: ink,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
