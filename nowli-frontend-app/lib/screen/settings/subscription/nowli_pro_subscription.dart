import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/utils/color_palette/color_palette.dart';

class NowliProSubscription extends StatefulWidget {
  const NowliProSubscription({super.key});

  @override
  State<NowliProSubscription> createState() => _NowliProSubscriptionState();
}

class _NowliProSubscriptionState extends State<NowliProSubscription> {
  /// 0 = Monthly, 1 = Yearly (default selected)
  int _selectedPlan = 1;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background with green blob ──
          Container(
            width: screenWidth,
            height: screenHeight,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/images/Popup_Multiple Missed Talks (1).png',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ── Main scrollable content ──
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // ── Close button ──
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Assets.svgIcons.proCrossIcon.svg(
                            width: 38,
                            height: 38,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Pro logo icon ──
                      Center(
                        child: Image.asset(
                          'assets/svg_images/popup_pro_icon.png',
                          width: 160,
                          height: 160,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Title: YOUR SUBSCRIPTION HAS ENDED ──
                      SizedBox(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'YOUR SUBSCRIPTION\n',
                                style: TextStyle(
                                  fontFamily: 'Wosker',
                                  color: Color(0xFF011F54),
                                  fontSize: 34,
                                  height: 1.1,
                                ),
                              ),
                              TextSpan(
                                text: 'HAS ENDED',
                                style: const TextStyle(
                                  fontFamily: 'Wosker',
                                  color: Color(0xFF011F54),
                                  fontSize: 34,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Subtitle ──
                      Center(
                        child: Text(
                          'Renew your Nowlii Pro plan to keep\ngrowing from here. 🌱',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.workSans(
                            color: const Color(0xFF4C586E),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── User stats card ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColorsApps.softCream,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE0E3E8),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: const AssetImage(
                                    'assets/images/AvatarLobe.png',
                                  ),
                                ),
                                Positioned(
                                  bottom: -4,
                                  left: -6,
                                  right: -6,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF3BB64B),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'JULIE',
                                        style: GoogleFonts.workSans(
                                          color: const Color(0xFF011F54),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),

                            // Stats
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(Assets.images.fireNave.path),
                                    const SizedBox(width: 4),
                                    Text(
                                      '11 day streak',
                                      style: GoogleFonts.workSans(
                                        color: const Color(0xFF011F54),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Image.asset(
                                      Assets.svgIcons.magicWand.path,

                                      height: 20,
                                      width: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '32 quests completed',
                                      style: GoogleFonts.workSans(
                                        color: const Color(0xFF011F54),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Monthly plan card ──
                      GestureDetector(
                        onTap: () => setState(() => _selectedPlan = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedPlan == 0
                                ? const Color(0xffB8FFAB)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: _selectedPlan == 0
                                ? Border.all(
                                    color: const Color(0xff4556F6),
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Monthly',
                                style: GoogleFonts.workSans(
                                  color: const Color(0xFF011F54),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                '\$19.99',
                                style: GoogleFonts.workSans(
                                  color: const Color(0xFF011F54),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Yearly plan card (selected by default) ──
                      GestureDetector(
                        onTap: () => setState(() => _selectedPlan = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedPlan == 1
                                ? const Color(0xffB8FFAB)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: _selectedPlan == 1
                                ? Border.all(
                                    color: const Color(0xff4556F6),
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Yearly',
                                    style: GoogleFonts.workSans(
                                      color: const Color(0xFF011F54),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$25.99',
                                    style: GoogleFonts.workSans(
                                      color: const Color(0xFF011F54),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '\$2.66/mo',
                                style: GoogleFonts.workSans(
                                  color: const Color(0xFF4542EB),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Renew button ──
                      SizedBox(
                        width: double.infinity,
                        height: 72,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3F3CD6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _selectedPlan == 1
                                ? 'Renew for \$25.99'
                                : 'Renew for \$19.99',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.workSans(
                              color: const Color(0xFFFFFDF7),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Bottom safe text ──
                      Center(
                        child: SizedBox(
                          width: 336,
                          child: Text(
                            'Your data and progress are safely saved. 💾',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.workSans(
                              color: const Color(
                                0xFF011F54,
                              ), // Text-text-default
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.60,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
