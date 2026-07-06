import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/themes/text_styles.dart';

class PopSpkingLoding extends StatefulWidget {
  const PopSpkingLoding({super.key});

  @override
  State<PopSpkingLoding> createState() => _PopSpkingLodingState();
}

class _PopSpkingLodingState extends State<PopSpkingLoding> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFFEF8), // light blue background
      body: Center(child: LoadingContent()),
    );
  }
}

class LoadingContent extends StatefulWidget {
  const LoadingContent({super.key});

  @override
  State<LoadingContent> createState() => _LoadingContentState();
}

class _LoadingContentState extends State<LoadingContent> {
  int _currentDot = 0;

  @override
  void initState() {
    super.initState();
    _startDotAnimation();
  }

  void _startDotAnimation() async {
    // Run animation for 3 seconds, then navigate
    int elapsedTime = 0;
    while (mounted && elapsedTime < 3000) {
      await Future.delayed(const Duration(milliseconds: 250));
      elapsedTime += 250;
      if (mounted) {
        setState(() {
          _currentDot = (_currentDot + 1) % 4;
        });
      }
    }
    if (mounted) {
      context.go(AppRoutespath.popupChooseMoodUpdates);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                    : Colors.blueAccent.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            "Nowlii is preparing your safe space...",
            textAlign: TextAlign.center,
            style: AppsTextStyles.extraBold32Centered,
          ),
        ),
      ],
    );
  }
}
/*
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/themes/text_styles.dart';

class PopSpkingLoding extends StatefulWidget {
  const PopSpkingLoding({super.key});

  @override
  State<PopSpkingLoding> createState() => _PopSpkingLodingState();
}

class _PopSpkingLodingState extends State<PopSpkingLoding> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFFEF8),
      body: Center(child: LoadingContent()),
    );
  }
}

class LoadingContent extends StatefulWidget {
  const LoadingContent({super.key});

  @override
  State<LoadingContent> createState() => _LoadingContentState();
}

class _LoadingContentState extends State<LoadingContent>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _bounceAnimations;

  static const List<double> _bounceHeights = [-20, -28, -16, -24];
  static const List<int> _durations = [1000, 1200, 900, 1100];
  static const List<int> _delays = [0, 300, 150, 450];
  static const int _dotCount = 4;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startNavigationTimer();
  }

  void _initAnimations() {
    _controllers = List.generate(
      _dotCount,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _durations[i]),
      ),
    );

    _bounceAnimations = List.generate(_dotCount, (i) {
      return Tween<double>(begin: 0, end: _bounceHeights[i]).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOut),
      );
    });

    for (int i = 0; i < _dotCount; i++) {
      Future.delayed(Duration(milliseconds: _delays[i]), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _startNavigationTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go(AppRoutespath.popupChooseMoodUpdates);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 64,
          width: 64,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // থালা — fixed
              Positioned(
                bottom: 0,
                child: Container(
                  width: 64,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA4CAFE),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.elliptical(32, 5),
                      topRight: Radius.elliptical(32, 5),
                      bottomLeft: Radius.elliptical(32, 4),
                      bottomRight: Radius.elliptical(32, 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA4CAFE).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Dots
              Positioned(
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_dotCount, (index) {
                    return AnimatedBuilder(
                      animation: _controllers[index],
                      builder: (context, child) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Transform.translate(
                            offset: Offset(0, _bounceAnimations[index].value),
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFFA4CAFE), // নতুন color
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            "Nowlii is preparing your safe space...",
            textAlign: TextAlign.center,
            style: AppsTextStyles.extraBold32Centered,
          ),
        ),
      ],
    );
  }
}
*/
/*
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/themes/text_styles.dart';

class PopSpkingLoding extends StatefulWidget {
  const PopSpkingLoding({super.key});

  @override
  State<PopSpkingLoding> createState() => _PopSpkingLodingState();
}

class _PopSpkingLodingState extends State<PopSpkingLoding> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFFEF8),
      body: Center(child: LoadingContent()),
    );
  }
}

class LoadingContent extends StatefulWidget {
  const LoadingContent({super.key});

  @override
  State<LoadingContent> createState() => _LoadingContentState();
}

class _LoadingContentState extends State<LoadingContent>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _bounceAnimations;
  late List<Animation<Color?>> _colorAnimations;

  static const List<double> _bounceHeights = [-25, -28, -16, -24];
  static const List<int> _durations = [1000, 1200, 900, 1100];
  static const List<int> _delays = [0, 300, 150, 450];
  static const int _dotCount = 4;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startNavigationTimer();
  }

  void _initAnimations() {
    _controllers = List.generate(
      _dotCount,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _durations[i]),
      ),
    );

    _bounceAnimations = List.generate(_dotCount, (i) {
      return Tween<double>(begin: 0, end: _bounceHeights[i]).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOut),
      );
    });

    // নিচে = A4CAFE, উপরে = 4542EB
    _colorAnimations = List.generate(_dotCount, (i) {
      return ColorTween(
        begin: const Color(0xFFA4CAFE),
        end: const Color(0xFF4542EB),
      ).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOut),
      );
    });

    for (int i = 0; i < _dotCount; i++) {
      Future.delayed(Duration(milliseconds: _delays[i]), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _startNavigationTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go(AppRoutespath.popupChooseMoodUpdates);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 64,
          width: 64,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // থালা — fixed
              Positioned(
                bottom: 0,
                child: Container(
                  width: 64,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA4CAFE),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.elliptical(32, 5),
                      topRight: Radius.elliptical(32, 5),
                      bottomLeft: Radius.elliptical(32, 4),
                      bottomRight: Radius.elliptical(32, 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA4CAFE).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Dots — bounce + color change
              Positioned(
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_dotCount, (index) {
                    return AnimatedBuilder(
                      animation: _controllers[index],
                      builder: (context, child) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Transform.translate(
                            offset: Offset(0, _bounceAnimations[index].value),
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                // উপরে গেলে গাঢ়, নিচে হালকা
                                color: _colorAnimations[index].value,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            "Nowlii is preparing your safe space...",
            textAlign: TextAlign.center,
            style: AppsTextStyles.extraBold32Centered,
          ),
        ),
      ],
    );
  }
}
*/