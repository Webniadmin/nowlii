import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The orange pill both paywall screens end on: a round knob on the left, a heavy label
/// beside it. The trial screen taps it; the subscribe screen makes you swipe it, because
/// the difference between "start a free week" and "start paying" deserves more than the
/// same tap in the same place on the screen.

const Color _kPillOrange = Color(0xFFFF8F26);
const Color _kKnobBlue = Color(0xFF4542EB);
const Color _kLabelInk = Color(0xFF011F54);
const double _kPillHeight = 72;
const double _kKnobSize = 56;

TextStyle _labelStyle() => GoogleFonts.workSans(
      color: _kLabelInk,
      fontSize: 20,
      fontWeight: FontWeight.w900,
      height: 1.0,
    );

ShapeDecoration _pillDecoration() => ShapeDecoration(
      color: _kPillOrange,
      shape: const StadiumBorder(),
      shadows: const [
        BoxShadow(
          color: Color(0x40FF8F26),
          blurRadius: 8,
          offset: Offset(0, 6),
        ),
      ],
    );

Widget _knob({required Widget icon}) => Container(
      width: _kKnobSize,
      height: _kKnobSize,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: _kKnobBlue,
        shape: BoxShape.circle,
      ),
      child: icon,
    );

/// Tap variant — used for "Start my free week".
class PaywallTapButton extends StatelessWidget {
  final String label;
  final Widget knobIcon;
  final VoidCallback? onTap;

  const PaywallTapButton({
    super.key,
    required this.label,
    required this.knobIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: _kPillHeight,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 8, 24, 8),
          decoration: _pillDecoration(),
          child: Row(
            children: [
              _knob(icon: knobIcon),
              const SizedBox(width: 12),
              Expanded(
                // Shrink rather than ellipsise: the longest label is
                // "Continue — 7 days left", and next to the knob that did not fit a
                // 320dp screen — the primary action read "Continue — 1 day…". The
                // ellipsis stays as the backstop for a label longer than scaling can
                // rescue. Same pattern as `custom_button.dart`.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: _labelStyle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// Swipe variant — used for "Swipe to Subscribe".
///
/// [onConfirm] fires once, when the knob is released past [threshold] of the track. A
/// shorter drag springs back, so a stray touch while scrolling the paywall cannot start a
/// subscription.
class PaywallSwipeButton extends StatefulWidget {
  final String label;
  final Widget knobIcon;
  final VoidCallback onConfirm;

  /// Disables the drag — e.g. while the purchase is already in flight.
  final bool enabled;

  final double threshold;

  const PaywallSwipeButton({
    super.key,
    required this.label,
    required this.knobIcon,
    required this.onConfirm,
    this.enabled = true,
    this.threshold = 0.7,
  });

  @override
  State<PaywallSwipeButton> createState() => _PaywallSwipeButtonState();
}

class _PaywallSwipeButtonState extends State<PaywallSwipeButton> {
  double _drag = 0;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 8px of padding either side of the knob's travel.
        final maxDrag = constraints.maxWidth - _kKnobSize - 16;

        return Opacity(
          opacity: widget.enabled ? 1 : 0.6,
          child: Container(
            height: _kPillHeight,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: _pillDecoration(),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // The label sits clear of the knob's resting position, and fades out as
                // the knob travels over it.
                Padding(
                  padding: const EdgeInsets.only(left: _kKnobSize + 12, right: 16),
                  child: Opacity(
                    opacity:
                        maxDrag <= 0 ? 1 : (1 - (_drag / maxDrag)).clamp(0.0, 1.0),
                    child: Text(
                      widget.label,
                      style: _labelStyle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Positioned(
                  left: _drag,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      if (!widget.enabled || _confirmed || maxDrag <= 0) return;
                      setState(() {
                        _drag = (_drag + details.delta.dx).clamp(0.0, maxDrag);
                      });
                    },
                    onHorizontalDragEnd: (_) {
                      if (!widget.enabled || _confirmed || maxDrag <= 0) return;
                      if (_drag > maxDrag * widget.threshold) {
                        setState(() {
                          _drag = maxDrag;
                          _confirmed = true;
                        });
                        widget.onConfirm();
                      } else {
                        setState(() => _drag = 0);
                      }
                    },
                    child: _knob(icon: widget.knobIcon),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
