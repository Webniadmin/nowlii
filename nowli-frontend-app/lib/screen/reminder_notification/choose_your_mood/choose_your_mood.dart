import 'package:flutter/material.dart';
import 'package:nowlii/screen/reminder_notification/choose_your_mood/loader.dart';

class AppColors {
  static const Color navy = Color(0xFF0B2246);
  static const Color headingBlue = Color(0xFF061438);
  static const Color softBlue = Color(0xFFE9F1FF);
  static const Color cardBg = Color(0xFFF2F6FF);
  static const Color primary = Color(0xFF3A6BFF);
  static const Color lightPrimary = Color(0xFFE7EEFF);
  static const Color accent = Color(0xFF6C5CE7);
  static const Color green = Color(0xFF8CE07B);
  static const Color orange = Color(0xFFFFA54F);
  static const Color red = Color(0xFFFF6B6B);
  static const Color purple = Color(0xFF9B8CFF);
}

class Mood {
  final String label;
  final String emoji;
  final Color bg;
  const Mood({required this.label, required this.emoji, required this.bg});
}

const List<Mood> moods = [
  Mood(label: 'Sad', emoji: '😞', bg: Color(0xFFDDE9FF)),
  Mood(label: 'Happy', emoji: '🙂', bg: Color(0xFFDFF4DB)),
  Mood(label: 'Awesome', emoji: '😄', bg: Color(0xFFFFF0D9)),
  Mood(label: 'Peacefull', emoji: '😊', bg: Color(0xFFE8FFE5)),
  Mood(label: 'Angry', emoji: '😡', bg: Color(0xFFFFE6E6)),
  Mood(label: 'Anxious', emoji: '😣', bg: Color(0xFFF0EAFF)),
  Mood(label: 'Tired', emoji: '😪', bg: Color(0xFFEFF6FF)),
  Mood(label: 'Empty', emoji: '😶', bg: Color(0xFFECEFF6)),
  Mood(label: 'Joyfull', emoji: '😁', bg: Color(0xFFFFF2E6)),
];

class ChooiseYourMood extends StatefulWidget {
  const ChooiseYourMood({super.key});

  @override
  State<ChooiseYourMood> createState() => _ChooiseYourMoodState();
}

class _ChooiseYourMoodState extends State<ChooiseYourMood> {
  int? selectedIndex;

  // === Change this path to your uploaded file path (option A) OR
  // move the file into assets/images and use Image.asset() with that path (option B).
  final String uploadedFilePath =
      '/mnt/data/Screenshot from 2025-11-20 00-06-30.png';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // baseScale used to scale text & paddings on different screens
    final baseScale = (width / 390).clamp(0.85, 1.25);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = 20.0 * baseScale;
            final moodButtonSize =
                (constraints.maxWidth - horizontalPadding * 2 - 32) / 3;
            final moodEmojiSize = moodButtonSize * 0.36;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Top decorative area - we overlay an image (the one you uploaded).
                  Stack(
                    children: [
                      Container(
                        height: 120 * baseScale,
                        width: double.infinity,
                        color: Colors.transparent,
                      ),
                      // Blue curves background (simple approximation)
                      Positioned(
                        left: -30 * baseScale,
                        top: -40 * baseScale,
                        child: Container(
                          width: 190 * baseScale,
                          height: 160 * baseScale,
                          decoration: BoxDecoration(
                            color: const Color(0xFF9DC3FF),
                            borderRadius: BorderRadius.circular(
                              100 * baseScale,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -40 * baseScale,
                        top: -20 * baseScale,
                        child: Container(
                          width: 150 * baseScale,
                          height: 140 * baseScale,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8DB8FF),
                            borderRadius: BorderRadius.circular(
                              100 * baseScale,
                            ),
                          ),
                        ),
                      ),
                      // Smaller circle with "x" — matches top-left control in design
                      Positioned(
                        left: 24 * baseScale,
                        top: 20 * baseScale,
                        child: Container(
                          width: 34 * baseScale,
                          height: 34 * baseScale,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.close,
                              size: 18 * baseScale,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      // Option A: show the uploaded screenshot as a small preview (dev only)
                    ],
                  ),

                  // Main content area
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 8 * baseScale),

                        // Title (big chunky font): two lines with bold weight
                        Text(
                          "HEY JULIE! HOW'S\nYOUR ENERGY TODAY?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.headingBlue,
                            fontSize: 22 * baseScale,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),

                        SizedBox(height: 12 * baseScale),

                        // Subtitle
                        Text(
                          "What kind of day are we having?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14 * baseScale,
                          ),
                        ),

                        SizedBox(height: 20 * baseScale),

                        // Mood grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: moods.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 16 * baseScale,
                                mainAxisSpacing: 16 * baseScale,
                                childAspectRatio: 1,
                              ),
                          itemBuilder: (context, index) {
                            final mood = moods[index];
                            return MoodButton(
                              mood: mood,
                              size: moodButtonSize,
                              emojiSize: moodEmojiSize,
                              isSelected: selectedIndex == index,
                              onTap: () => setState(() {
                                selectedIndex = (selectedIndex == index)
                                    ? null
                                    : index;
                              }),
                              labelFontSize: 12 * baseScale,
                            );
                          },
                        ),

                        SizedBox(height: 22 * baseScale),

                        // "I'm not sure" button (outlined, full width)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  30 * baseScale,
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 16 * baseScale,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                selectedIndex = null;
                              });
                            },
                            child: Text(
                              "I'm not sure",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16 * baseScale,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 32 * baseScale),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                              30 * baseScale,
                            ), // ✅ Correct way
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    30 * baseScale,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: 16 * baseScale,
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Loader(),
                                  ),
                                );
                              },
                              child: Text(
                                "Share",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16 * baseScale,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class MoodButton extends StatelessWidget {
  final Mood mood;
  final double size;
  final double emojiSize;
  final double labelFontSize;
  final bool isSelected;
  final VoidCallback onTap;

  const MoodButton({
    super.key,
    required this.mood,
    required this.size,
    required this.emojiSize,
    required this.onTap,
    this.isSelected = false,
    this.labelFontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(14);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : mood.bg,
          borderRadius: borderRadius,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                  ),
                ]
              : [],
          border: isSelected
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.95),
                  width: 1.8,
                )
              : null,
        ),
        width: size,
        height: size,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji circle
            Container(
              width: emojiSize,
              height: emojiSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                mood.emoji,
                style: TextStyle(fontSize: emojiSize * 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mood.label,
              style: TextStyle(
                fontSize: labelFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
