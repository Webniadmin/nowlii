import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CleanTheHouseScreen extends StatefulWidget {
  const CleanTheHouseScreen({super.key});

  @override
  State<CleanTheHouseScreen> createState() => _CleanTheHouseScreenState();
}

class _CleanTheHouseScreenState extends State<CleanTheHouseScreen> {
  final List<Map<String, dynamic>> subtasks = [
    {'title': 'Clean kitchen', 'checked': false},
    {'title': 'Take out trash', 'checked': false},
    {'title': 'Wash dishes', 'checked': false},
  ];

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFFFCF1);
    const primaryNavy = Color(0xFF0D1B5E);
    const checkboxBorder = Color(0xFFE8A87C);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEE8D6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: primaryNavy,
                    size: 20,
                  ),
                ),
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Soft steps badge
                    Center(
                      child: Container(
                        height: 56,
                        width: 160,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(
                            0xFFA0E871,
                          ), // Background-bg-light-green
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Soft steps',
                            style: GoogleFonts.workSans(
                              color: const Color(
                                0xFF011F54,
                              ), // Text-text-default
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              letterSpacing: -0.9,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Title
                    SizedBox(
                      width: 302,
                      child: Text(
                        'CLEAN THE HOUSE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(
                            0xFF011F54,
                          ) /* Text-text-default */,
                          fontSize: 52,
                          fontFamily: 'Wosker',
                          fontWeight: FontWeight.w400,
                          height: 0.80,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Date and Time row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: primaryNavy,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Tomorrow',
                          style: GoogleFonts.workSans(
                            color: const Color(0xFF011F54), // Text-text-default
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            letterSpacing: -0.9,
                          ),
                        ),
                        SizedBox(width: 24),
                        Icon(Icons.access_time, color: primaryNavy, size: 20),
                        SizedBox(width: 6),
                        Text(
                          '7pm',
                          style: GoogleFonts.workSans(
                            color: const Color(0xFF011F54), // Text-text-default
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Subtasks label
                    Text(
                      '${subtasks.length} subtasks',
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF4C586E), // Primary text color
                        fontSize: 18,
                        fontWeight: FontWeight.w400, // Regular
                        height: 1.4,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtask list
                    ...subtasks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final task = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              subtasks[index]['checked'] =
                                  !subtasks[index]['checked'];
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: checkboxBorder,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: task['checked']
                                        ? primaryNavy
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Color(0xFF4542EB),
                                      width: 2,
                                    ),
                                  ),
                                  child: task['checked']
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  task['title'],
                                  style: GoogleFonts.workSans(
                                    color: const Color(
                                      0xFF011F54,
                                    ), // Text-text-default
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                    letterSpacing: -0.9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // Note text
                    SizedBox(
                      width: 288,
                      child: Text(
                        'You’re having a 10-minute call with your Bestie during this task.',
                        style: GoogleFonts.workSans(
                          color: const Color(
                            0xFF4C586E,
                          ), // Text-text-primary-default
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Save Reflection Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Container(
                width: 330,
                height: 64,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                decoration: ShapeDecoration(
                  color: const Color(
                    0xFF3F3CD6,
                  ), // Background-bg-primary-on-press
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Save reflection',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFFFFFDF7), // Text-text-light
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
