import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

class SwipeButtonWidget extends StatefulWidget {
  final VoidCallback onSwipe;

  /// True once today's sparks are spent. The button becomes a closing statement rather
  /// than a disabled control: there is nothing to swipe toward until tomorrow, and a greyed
  /// -out slider invites people to keep trying it.
  final bool spent;

  /// Spent because the plan lapsed rather than because the day is done. Same shape, but
  /// "See you tomorrow" would be false — tomorrow brings nothing back on its own.
  final bool paused;

  const SwipeButtonWidget({
    super.key,
    required this.onSwipe,
    this.spent = false,
    this.paused = false,
  });

  @override
  State<SwipeButtonWidget> createState() => _SwipeButtonWidgetState();
}

class _SwipeButtonWidgetState extends State<SwipeButtonWidget> {
  double _dragValue = 0.0;

  /// Latched for [_relatchDelay] after a successful swipe so one gesture cannot open two
  /// calls. It used to be a one-way flag: the home screen keeps this widget alive while
  /// the call sits on top of it, so coming back from a call left the knob parked at the
  /// far end and every later swipe was ignored — the button worked exactly once per app
  /// launch.
  bool _isSwiped = false;

  /// True only while a finger is down. Drives the knob's animation duration, so dragging
  /// tracks the finger 1:1 while releasing eases home instead of teleporting.
  bool _dragging = false;

  static const Duration _relatchDelay = Duration(milliseconds: 600);
  static const Duration _settleDuration = Duration(milliseconds: 250);

  final double _knobSize = 60.0;
  final double _padding = 8.0;

  /// Out of sparks: no knob, no drag target, nothing to press.
  Widget _buildSpentButton() {
    return Container(
      height: 72,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 8),
      decoration: ShapeDecoration(
        color: const Color(0xFFC3DBFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFFFEF8),
              shape: BoxShape.circle,
            ),
            child: Assets.svgIcons.sparkSun.svg(width: 28, height: 28),
          ),
          const SizedBox(width: 12),
          Text(
            widget.paused ? 'Renew to talk again' : 'See you tomorrow',
            style: GoogleFonts.workSans(
              color: const Color(0xFF011F54),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.spent) return _buildSpentButton();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final maxDrag = totalWidth - _knobSize - (_padding * 2);

        return Container(
          height: 80,
          width: double.infinity,
          padding: EdgeInsets.all(_padding),
          decoration: ShapeDecoration(
            color: const Color(0xFFFF8F26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x19011F54),
                blurRadius: 18,
                offset: Offset(2, 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: GestureDetector(
            // On the whole track, not just the knob: the knob is 60px in an 80px-tall
            // pill, so grabbing "the button" a few pixels off the circle used to do
            // nothing at all and read as an unresponsive control.
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) {
              if (_isSwiped) return;
              setState(() => _dragging = true);
            },
            onHorizontalDragUpdate: (details) {
              if (_isSwiped) return;
              setState(() {
                _dragValue = (_dragValue + details.delta.dx).clamp(0.0, maxDrag);
              });
            },
            onHorizontalDragEnd: (_) {
              if (_isSwiped) return;
              if (_dragValue > maxDrag * 0.7) {
                setState(() {
                  _dragValue = maxDrag;
                  _isSwiped = true;
                  _dragging = false;
                });
                widget.onSwipe();
                // Re-arm rather than latching forever. The call screen is pushed over
                // this one, so the knob easing back is not visible; what matters is that
                // the control is usable again when the user returns.
                Future.delayed(_relatchDelay, () {
                  if (!mounted) return;
                  setState(() {
                    _dragValue = 0.0;
                    _isSwiped = false;
                  });
                });
              } else {
                setState(() {
                  _dragValue = 0.0;
                  _dragging = false;
                });
              }
            },
            onHorizontalDragCancel: () {
              if (_isSwiped) return;
              setState(() {
                _dragValue = 0.0;
                _dragging = false;
              });
            },
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Text Label
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(left: _knobSize),
                    child: Text(
                      // The product calls a call a "spark"; the label follows the same
                      // word as the counter on the call screen and the home bar.
                      'Swipe to start a spark',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF011F54),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                // The knob carries no gesture of its own — the track above owns the
                // drag, so the knob only has to render where the drag put it.
                AnimatedPositioned(
                  duration: _dragging ? Duration.zero : _settleDuration,
                  curve: Curves.easeOut,
                  left: _dragValue,
                  child: IgnorePointer(
                    child: CircleAvatar(
                      radius: _knobSize / 2,
                      backgroundImage: AssetImage(
                        Assets.svgIcons.swipeToTalkToFuzzy.path,
                      ),
                    ),
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