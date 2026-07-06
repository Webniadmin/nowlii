import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

class SwipeButtonWidget extends StatefulWidget {
  final VoidCallback onSwipe;

  const SwipeButtonWidget({super.key, required this.onSwipe});

  @override
  State<SwipeButtonWidget> createState() => _SwipeButtonWidgetState();
}

class _SwipeButtonWidgetState extends State<SwipeButtonWidget> {
  double _dragValue = 0.0;
  bool _isSwiped = false;
  final double _knobSize = 60.0;
  final double _padding = 8.0;

  @override
  Widget build(BuildContext context) {
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
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Text Label
              Center(
                child: Padding(
                  padding: EdgeInsets.only(left: _knobSize),
                  child: Text(
                    'Swipe to talk to Fuzzy',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF011F54),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              // Draggable Knob
              Positioned(
                left: _dragValue,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isSwiped) return;
                    setState(() {
                      _dragValue = (_dragValue + details.delta.dx).clamp(
                        0.0,
                        maxDrag,
                      );
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isSwiped) return;
                    if (_dragValue > maxDrag * 0.7) {
                      setState(() {
                        _dragValue = maxDrag;
                        _isSwiped = true;
                      });
                      widget.onSwipe();
                    } else {
                      setState(() {
                        _dragValue = 0.0;
                      });
                    }
                  },
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
        );
      },
    );
  }
}
