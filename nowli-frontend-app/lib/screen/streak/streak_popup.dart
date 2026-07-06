import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

// ── Confetti particle model ──────────────────────────────────────────────────
class _Particle {
  final double x; // 0..1  (screen width fraction)
  final double delay; // 0..1
  final double size;
  final double rotation; // radians
  final double speed; // multiplier

  _Particle({
    required this.x,
    required this.delay,
    required this.size,
    required this.rotation,
    required this.speed,
  });
}

// ── Confetti overlay (shown on top of everything) ────────────────────────────
class _ConfettiOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const _ConfettiOverlay({required this.onDone});

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _rng = Random();
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    // 18 টা particle তৈরি
    _particles = List.generate(
      18,
      (_) => _Particle(
        x: _rng.nextDouble(),
        delay: _rng.nextDouble() * 0.45,
        size: 32 + _rng.nextDouble() * 28,
        rotation: (_rng.nextDouble() - 0.5) * 0.6, // ±0.3 rad (~17°)
        speed: 0.35 + _rng.nextDouble() * 0.25,
      ),
    );

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Stack(
          children: _particles.map((p) {
            // delay সহ progress (0→1)
            final progress = ((_ctrl.value - p.delay) / (1 - p.delay)).clamp(
              0.0,
              1.0,
            );

            // উপর থেকে নিচে পড়া
            final top = -60.0 + (size.height + 80) * progress * p.speed;
            // বাম-ডানে হালকা দোলানো (sine wave)
            final left = size.width * p.x + sin(progress * pi * 3) * 18;
            // আস্তে আস্তে মিলিয়ে যাওয়া (শেষ 30% তে)
            final opacity = progress > 0.7
                ? 1.0 - ((progress - 0.7) / 0.3)
                : 1.0;

            return Positioned(
              left: left,
              top: top,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform(
                  transform: Matrix4.identity()
                    ..rotateZ(p.rotation + progress * 1.2),
                  alignment: Alignment.center,
                  child: Text(
                    '💚',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF011F54),
                      fontSize: p.size,
                      fontWeight: FontWeight.w800,
                      height: 1.20,
                      letterSpacing: -1.68,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Main Screen ──────────────────────────────────────────────────────────────
class StreakPopup extends StatefulWidget {
  const StreakPopup({super.key});

  @override
  State<StreakPopup> createState() => _StreakPopupState();
}

class _StreakPopupState extends State<StreakPopup> {
  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  late List<bool> completed;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    completed = [true, true, false, false, false, false, false];
  }

  void _onDayTapped(int index) {
    setState(() {
      completed[index] = !completed[index];
      if (completed[index]) _showConfetti = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background ─────────────────────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/Streak popup _poup.png',
              fit: BoxFit.cover,
            ),
          ),

          // ── Main content ───────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Close button
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Flame + number
                Container(
                  padding: const EdgeInsets.only(
                    top: 15.41,
                    left: 14.82,
                    right: 22.23,
                    bottom: 7.41,
                  ),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFDFEFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(183.39),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 44.46,
                        height: 44.46,
                        child: Image.asset(
                          Assets.images.fireBlue.path,
                          width: 20,
                          height: 20,
                        ),
                      ),
                      const SizedBox(width: 7.41),
                      Text(
                        '2',
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF4542EB),
                          fontSize: 37.05,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.93,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: const Text(
                    '2 DAYS STREAK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF011F54),
                      fontSize: 63.18,
                      fontFamily: 'Wosker',
                      fontWeight: FontWeight.w400,
                      height: 0.80,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'You\'re showing up — and that\'s what \n matters most.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF4C586E),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Max pill
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final fullWidth = constraints.maxWidth;
                      return Container(
                        width: fullWidth,
                        height: 43.92,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(1439.30),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 4.39,
                              child: Container(
                                width: fullWidth,
                                height: 35.14,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFC3DBFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      1439.30,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 4.39,
                              child: Container(
                                width: fullWidth,
                                height: 35.14,
                                decoration: ShapeDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFFDFEFFF),
                                      Color(0xFF4542EB),
                                    ],
                                  ),
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                      width: 2.88,
                                      strokeAlign:
                                          BorderSide.strokeAlignOutside,
                                      color: Color(0xFFFFFEF8),
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      1439.30,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Max',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.workSans(
                                      color: const Color(0xFFFFFDF7),
                                      fontSize: 25.93,
                                      fontWeight: FontWeight.w900,
                                      height: 0.8,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          child: Image.asset(
                                            Assets.images.star3.path,
                                            width: 17,
                                            height: 16,
                                          ),
                                        ),
                                        Positioned(
                                          left: 14,
                                          top: 14,
                                          child: Image.asset(
                                            Assets.images.star3.path,
                                            width: 11,
                                            height: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 42.53,
                                height: 43.92,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFF4542EB),
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                      width: 2.88,
                                      strokeAlign:
                                          BorderSide.strokeAlignOutside,
                                      color: Color(0xFFFFFEF8),
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      1439.30,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // Share with friends button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF4542EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Share with friends',
                          style: GoogleFonts.workSans(
                            color: const Color(0xFFFFFDF7),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Image.asset(
                          Assets.images.friends.path,
                          width: 20,
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // See progress button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 2,
                          color: Color(0xFF6A68EF),
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'See progress',
                          style: GoogleFonts.workSans(
                            color: const Color(0xFF4542EB),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Image.asset(
                          Assets.images.fireBlue.path,
                          width: 20,
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ── Day checkboxes ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(days.length, (i) {
                      return _DayCheckbox(
                        day: days[i],
                        checked: completed[i],
                        onTap: () => _onDayTapped(i),
                      );
                    }),
                  ),
                ),

                const Spacer(),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Every day counts — Fuzzy\'s proud of you!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF011F54),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 💚 Confetti Rain ───────────────────────────────────────────────
          if (_showConfetti)
            Positioned.fill(
              child: IgnorePointer(
                child: _ConfettiOverlay(
                  onDone: () => setState(() => _showConfetti = false),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Day Checkbox widget ──────────────────────────────────────────────────────
class _DayCheckbox extends StatelessWidget {
  final String day;
  final bool checked;
  final VoidCallback onTap;

  const _DayCheckbox({
    required this.day,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            day,
            style: GoogleFonts.workSans(
              color: const Color(0xFF4C586E),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: checked ? const Color(0xFF5B5BFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: checked
                    ? const Color(0xFF5B5BFF)
                    : const Color(0xFF4542EB),
                width: 2.5,
              ),
            ),
            child: checked
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        ],
      ),
    );
  }
}
