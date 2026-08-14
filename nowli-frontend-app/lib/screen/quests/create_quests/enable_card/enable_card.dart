import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/themes/create_qutes.dart';

class EnableCallCard extends StatefulWidget {
  final double scale;
  final Function(bool)? onCallEnabledChanged;
  final bool? initialValue;

  /// Why a call cannot be planned for the chosen day, or null when it can.
  ///
  /// Set, the card blurs and the switch stops responding: the day has no spark left for
  /// this call, so offering the toggle would only lead to a reminder the backend refuses.
  /// See `services/call_slot.dart`.
  final String? blockedReason;

  const EnableCallCard({
    super.key,
    this.scale = 1.0,
    this.onCallEnabledChanged,
    this.initialValue,
    this.blockedReason,
  });

  @override
  State<EnableCallCard> createState() => _EnableCallCardState();
}

class _EnableCallCardState extends State<EnableCallCard> {
  bool isCallEnabled = false;

  bool get _blocked => widget.blockedReason != null;

  @override
  void initState() {
    super.initState();
    isCallEnabled = widget.initialValue ?? false;
  }

  @override
  void didUpdateWidget(EnableCallCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The day can change under the card — pick tomorrow, then pick today again. A toggle
    // left on behind the blur would still be sent with the quest.
    if (_blocked && isCallEnabled) {
      isCallEnabled = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCallEnabledChanged?.call(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double s = widget.scale;

    final card = Container(
      width: double.infinity,
      padding: EdgeInsets.all(12 * s),
      decoration: BoxDecoration(
        color: Color(0xFFDFEFFF),
        borderRadius: BorderRadius.circular(12 * s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Switch(
                value: isCallEnabled,
                onChanged: _blocked
                    ? null
                    : (bool newValue) {
                        setState(() {
                          isCallEnabled = newValue;
                        });
                        widget.onCallEnabledChanged?.call(newValue);
                      },
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF4542EB),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFB0B0B0),
              ),
              Text('ENABLE CALL', style: AppTextStylesQutes.workSansBlack24),
            ],
          ),
          SizedBox(height: 10 * s),
          // Description + switch
          Row(
            children: [
              Expanded(
                child: Text(
                  'A real-time 5-min support call will help you stay on track.',
                  style: AppTextStylesQutes.workSansRegular16,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!_blocked) return card;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12 * s),
          child: Stack(
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                child: card,
              ),
              // Absorbs a tap on the blurred card so it never feels half-alive.
              Positioned.fill(
                child: Container(color: const Color(0x66FFFEF8)),
              ),
            ],
          ),
        ),
        SizedBox(height: 6 * s),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4 * s),
          child: Text(
            widget.blockedReason!,
            style: GoogleFonts.workSans(
              color: const Color(0xFF011F54),
              fontSize: 12 * s,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
