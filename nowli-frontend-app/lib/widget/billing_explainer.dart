import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/models/subscription_model.dart';
import 'package:nowlii/utils/color_palette/color_palette.dart';

/// The "How billing works" explainer — NOWLII's decreasing-price-then-free schedule.
///
/// Shared by the 7-days-free intro screen and the Pro/paywall screen so there is exactly
/// one place describing the pricing. Prices come from the backend `/subscriptions/plan/`
/// endpoint (the single source of truth); the fallback below mirrors `subscriptions/config.py`
/// and is only used if that call fails.
class BillingExplainer extends StatelessWidget {
  /// The schedule fetched from the backend. Null → the fallback copy is shown.
  final SubscriptionPlan? plan;

  /// Hide the heading when the host screen already has one.
  final bool showTitle;

  const BillingExplainer({super.key, required this.plan, this.showTitle = true});

  static const _dotColors = [
    Color(0xFFFF8A00), // months 1–3
    Color(0xFFFFB74D), // 4–6
    Color(0xFF5C6BC0), // 7–9
    Color(0xFF4542EB), // 10–12
    Color(0xFF3BB64B), // free forever
  ];

  static const _fallback = [
    _Phase('Months 1–3', 19.99),
    _Phase('Months 4–6', 14.99),
    _Phase('Months 7–9', 9.99),
    _Phase('Months 10–12', 4.99),
    _Phase('Month 13+', 0, isFree: true),
  ];

  List<_Phase> get _phases {
    final p = plan;
    if (p == null || p.phases.isEmpty) return _fallback;
    return [
      ...p.phases.map((e) => _Phase('Months ${e.fromMonth}–${e.toMonth}', e.price)),
      _Phase('Month ${p.freeAfterMonth + 1}+', 0, isFree: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final phases = _phases;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            'How billing works?',
            style: GoogleFonts.workSans(
              color: const Color(0xFF011F54),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          "Nowlii isn't here to take your money — it's here to help you grow. 🌱\n\n"
          "The stronger and more consistent you become, the less you pay. Stick with it "
          "for a year and Nowlii becomes completely free — because once you've healed and "
          "built your habits, why keep paying for something you no longer need? Your "
          "progress is the whole point.",
          style: GoogleFonts.workSans(
            color: const Color(0xFF4C586E),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          phases.length,
          (i) => _PhaseBox(
            phase: phases[i],
            color: _dotColors[i % _dotColors.length],
          ),
        ),
      ],
    );
  }
}

class _Phase {
  final String label;
  final double price;
  final bool isFree;
  const _Phase(this.label, this.price, {this.isFree = false});
}

class _PhaseBox extends StatelessWidget {
  final _Phase phase;
  final Color color;

  const _PhaseBox({required this.phase, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColorsApps.softCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              phase.label,
              style: GoogleFonts.workSans(
                color: const Color(0xFF011F54),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Text(
            phase.isFree ? 'Free 🌱' : '\$${phase.price.toStringAsFixed(2)}/mo',
            style: GoogleFonts.workSans(
              color: phase.isFree
                  ? const Color(0xFF3BB64B)
                  : const Color(0xFF011F54),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
