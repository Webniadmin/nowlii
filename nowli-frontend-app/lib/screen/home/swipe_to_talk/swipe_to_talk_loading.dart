import 'package:flutter/material.dart';
import 'package:nowlii/screen/home/swipe_to_talk/screen_flow_controller.dart';

class SwipeToTalkLoading extends StatefulWidget {
  const SwipeToTalkLoading({super.key});

  @override
  State<SwipeToTalkLoading> createState() => _SwipeToTalkLoadingState();
}

class _SwipeToTalkLoadingState extends State<SwipeToTalkLoading>
    with SingleTickerProviderStateMixin, ScreenFlowMixin {
  late AnimationController _controller;
  int _currentDot = 0;

  @override
  FlowScreen get flowScreen => FlowScreen.swipeToTalkLoading;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(() {
            if (_controller.status == AnimationStatus.completed) {
              _controller.reverse();
            } else if (_controller.status == AnimationStatus.dismissed) {
              _controller.forward();
            }
          })
          ..repeat();
    _startDotAnimation();

    // Initialize automatic navigation flow (3 seconds delay)
    initializeFlow(context);
  }

  void _startDotAnimation() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        setState(() {
          _currentDot = (_currentDot + 1) % 4;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF8), // light blue background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: index == _currentDot
                        ? Colors.blueAccent
                        // ignore: deprecated_member_use
                        : Colors.blueAccent.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
