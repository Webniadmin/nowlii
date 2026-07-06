import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  final SubscriptionType type;

  const SubscriptionScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4C3EDD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),

              // Content Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _buildContent(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.emoji_emotions, color: Color(0xFF4C3EDD)),
        ),
        const SizedBox(width: 12),
        const Text(
          'NOWLLI PRO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (type) {
      case SubscriptionType.monthlyActive:
        return _MonthlyActiveContent();
      case SubscriptionType.expiringSoon:
        return _ExpiringContent();
      case SubscriptionType.expired:
        return _ExpiredContent();
      case SubscriptionType.startTrial:
        return _StartTrialContent();
      case SubscriptionType.cancellation:
        return _CancellationContent();
    }
  }
}

enum SubscriptionType {
  monthlyActive,
  expiringSoon,
  expired,
  startTrial,
  cancellation,
}

// Monthly Active Subscription
class _MonthlyActiveContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'NOWLLI PRO\nMEMBER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Subscription Info
        _buildInfoRow(
          Icons.refresh,
          'Monthly plan \$8.99',
          'Next billing on September 21, 2025',
          const Color(0xFF4C3EDD),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          Icons.access_time,
          'Subscribed via App Store',
          null,
          Colors.grey,
        ),
        const Spacer(),

        // Buttons
        _buildButton(
          'Pause Subscription',
          const Color(0xFF4C3EDD),
          Colors.white,
          () {},
        ),
        const SizedBox(height: 12),
        _buildButton(
          'Cancel Subscription',
          Colors.white,
          const Color(0xFF4C3EDD),
          () {},
          outlined: true,
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String? subtitle,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onTap, {
    bool outlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: textColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: bgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}

// Expiring Soon
class _ExpiringContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Color(0xFFFF9800),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'NOWLLI PRO\nEXPIRED',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _MonthlyActiveContent()._buildInfoRow(
          Icons.refresh,
          'Monthly plan \$8.99',
          'Next billing on September 21, 2025',
          const Color(0xFF4C3EDD),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.error, color: Color(0xFFE53935), size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Your subscription is expiring soon.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        _MonthlyActiveContent()._buildButton(
          'Pause Subscription',
          const Color(0xFF4C3EDD),
          Colors.white,
          () {},
        ),
        const SizedBox(height: 12),
        _MonthlyActiveContent()._buildButton(
          'Cancel Subscription',
          Colors.white,
          const Color(0xFF4C3EDD),
          () {},
          outlined: true,
        ),
      ],
    );
  }
}

// Expired Subscription
class _ExpiredContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF4C3EDD),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.repeat, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 24),

        const Text(
          'YOUR SUBSCRIPTION\nHAS ENDED',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E3A8A),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Renew your Nowlli Pro plan to keep\ngrowing from here 🚀',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
        ),
        const SizedBox(height: 24),

        // Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStat('11 day streak', Icons.local_fire_department),
            const SizedBox(width: 24),
            _buildStat('32 quests completed', Icons.check_circle),
          ],
        ),
        const SizedBox(height: 32),

        // Pricing Cards
        _buildPricingCard('Monthly', '\$4.66', null, const Color(0xFF4CAF50)),
        const SizedBox(height: 12),
        _buildPricingCard(
          'Yearly',
          '\$2.66/mo',
          'save 26%',
          const Color(0xFFFF9800),
          originalPrice: '\$25.99',
        ),
        const Spacer(),

        _MonthlyActiveContent()._buildButton(
          'Renew for \$25.99',
          const Color(0xFF4C3EDD),
          Colors.white,
          () {},
        ),
      ],
    );
  }

  Widget _buildStat(String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8E9F3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF4C3EDD), size: 20),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A8A),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard(
    String title,
    String price,
    String? badge,
    Color badgeColor, {
    String? originalPrice,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4C3EDD), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              if (originalPrice != null)
                Text(
                  originalPrice,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
          Row(
            children: [
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Start Free Trial
class _StartTrialContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF4C3EDD),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.repeat, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 24),
        const Text(
          'SUBSCRIBE TO\nNOWLLI',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E3A8A),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Unlock unlimited calls, deeper\nconversations, and personalized\ninsights.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
        ),
        const SizedBox(height: 32),
        _ExpiredContent()._buildPricingCard(
          'Monthly',
          '\$4.66',
          null,
          const Color(0xFF4CAF50),
        ),
        const SizedBox(height: 12),
        _ExpiredContent()._buildPricingCard(
          'Yearly',
          '\$2.66/mo',
          'save 26%',
          const Color(0xFFFF9800),
          originalPrice: '\$25.99',
        ),
        const Spacer(),
        _MonthlyActiveContent()._buildButton(
          'Start Free Trial',
          const Color(0xFF4C3EDD),
          Colors.white,
          () {},
        ),
      ],
    );
  }
}

// Cancellation Reasons
class _CancellationContent extends StatefulWidget {
  @override
  State<_CancellationContent> createState() => _CancellationContentState();
}

class _CancellationContentState extends State<_CancellationContent> {
  String? _selectedReason;

  final List<String> _reasons = [
    "It's too expensive",
    "I'm not using Nowlli enough",
    "I only needed it short-term",
    "Other reason",
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.sentiment_dissatisfied,
              color: Color(0xFF6B7280),
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "We'll Miss You",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          "Before you go, could you tell us why you'd like to cancel your plan?\nYour feedback helps Nowlli grow and support others better.",
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
        ),
        const SizedBox(height: 24),
        ..._reasons.map((reason) => _buildReasonCheckbox(reason)),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: _MonthlyActiveContent()._buildButton(
                'Cancel',
                Colors.white,
                const Color(0xFF4C3EDD),
                () => Navigator.pop(context),
                outlined: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MonthlyActiveContent()._buildButton(
                'Keep plan',
                const Color(0xFF4C3EDD),
                Colors.white,
                () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReasonCheckbox(String reason) {
    final isSelected = _selectedReason == reason;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedReason = reason;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF4C3EDD) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4C3EDD) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4C3EDD)
                        : const Color(0xFFD1D5DB),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
