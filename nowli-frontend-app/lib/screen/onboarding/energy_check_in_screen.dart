// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:go_router/go_router.dart';
// import 'package:nowlii/core/gen/assets.gen.dart';

// class EnergyCheckInScreen extends StatefulWidget {
//   const EnergyCheckInScreen({super.key});

//   @override
//   State<EnergyCheckInScreen> createState() => _EnergyCheckInScreenState();
// }

// class _EnergyCheckInScreenState extends State<EnergyCheckInScreen> {
//   String? selectedMood;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage(Assets.svgIcons.bkPopupChooseMood.path),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: SafeArea(
//           child: Stack(
//             children: [
//               // Close button
//               Positioned(
//                 top: 20,
//                 left: 20,
//                 child: Container(
//                   width: 36,
//                   height: 36,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withValues(alpha: 0.9),
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(alpha: 0.1),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: IconButton(
//                     padding: EdgeInsets.zero,
//                     icon: const Icon(
//                       Icons.close,
//                       size: 20,
//                       color: Color(0xFF7BA5E3),
//                     ),
//                     onPressed: () {
//                       // Handle close action
//                       Navigator.of(context).pop();
//                     },
//                   ),
//                 ),
//               ),

//               // Main content
//               CustomScrollView(
//                 slivers: [
//                   SliverToBoxAdapter(
//                     child: Column(
//                       children: [
//                         const SizedBox(height: 100),

//                         // Title
//                         Text(
//                           "HEY JULIE! HOW'S\nYOUR ENERGY TODAY?",
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: const Color(0xFF011F54),
//                             fontSize: 32,
//                             fontFamily: 'Wosker',
//                             fontWeight: FontWeight.w400,
//                             height: 0.9,
//                           ),
//                         ),

//                         const SizedBox(height: 12),

//                         // Subtitle
//                         const Text(
//                           "What kind of day are we having?",
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Color(0xFF6B7280),
//                           ),
//                         ),

//                         const SizedBox(height: 40),

//                         // Mood grid
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                           child: GridView.count(
//                             shrinkWrap: true,
//                             physics: const NeverScrollableScrollPhysics(),
//                             crossAxisCount: 3,
//                             mainAxisSpacing: 12,
//                             crossAxisSpacing: 12,
//                             childAspectRatio: 0.85,
//                             children: [
//                               _buildMoodCard("Sad", Assets.svgIcons.sad),
//                               _buildMoodCard("Happy", Assets.svgIcons.happy),
//                               _buildMoodCard(
//                                 "Awesome",
//                                 Assets.svgIcons.awosome,
//                               ),
//                               _buildMoodCard(
//                                 "Peacefull",
//                                 Assets.svgIcons.peacefull,
//                               ),
//                               _buildMoodCard("Angry", Assets.svgIcons.angry),
//                               _buildMoodCard(
//                                 "Anxious",
//                                 Assets.svgIcons.anxious,
//                               ),
//                               _buildMoodCard("Tired", Assets.svgIcons.tired),
//                               _buildMoodCard("Empty", Assets.svgIcons.empty),
//                               _buildMoodCard(
//                                 "Joyfull",
//                                 Assets.svgIcons.joyfull,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SliverFillRemaining(
//                     hasScrollBody: false,
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         // Bottom buttons
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 24.0,
//                             vertical: 8,
//                           ),
//                           child: Column(
//                             children: [
//                               SizedBox(
//                                 width: double.infinity,
//                                 height: 69,
//                                 child: OutlinedButton(
//                                   onPressed: () {
//                                     // Handle "I'm not sure" action
//                                   },
//                                   style: OutlinedButton.styleFrom(
//                                     side: const BorderSide(
//                                       color: Color(0xFF4A4AF4),
//                                       width: 2,
//                                     ),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(28),
//                                     ),
//                                     backgroundColor: Colors.white,
//                                   ),
//                                   child: const Text(
//                                     "I'm not sure",
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.bold,
//                                       color: Color(0xFF4A4AF4),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(height: 12),
//                               SizedBox(
//                                 width: double.infinity,
//                                 height: 69,
//                                 child: ElevatedButton(
//                                   onPressed: () {
//                                     // Handle "Share" action
//                                     context.push("/noticeLoaderScreen");
//                                   },
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: const Color(0xFF4A4AF4),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(28),
//                                     ),
//                                     elevation: 0,
//                                   ),
//                                   child: const Text(
//                                     "Share",
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(height: 20),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMoodCard(String label, AssetGenImage moodImage) {
//     final bool isSelected = selectedMood == label;

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           selectedMood = label;
//         });

//         // Optional: Show a snackbar when mood is selected
//         // ScaffoldMessenger.of(context).showSnackBar(
//         //   SnackBar(
//         //     content: Text('You selected: $label'),
//         //     duration: const Duration(seconds: 1),
//         //     behavior: SnackBarBehavior.floating,
//         //   ),
//         // );
//       },
//       child: Container(
//         height: 100.h,
//         width: 100.w,
//         decoration: BoxDecoration(
//           color: const Color(0xFFE8F2FF),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isSelected ? const Color(0xFF4A8BF4) : Colors.transparent,
//             width: 6,
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             SizedBox(
//               width: 50,
//               height: 50,
//               child: moodImage.image(fit: BoxFit.contain),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF011F54),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }\

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

class EnergyCheckInScreen extends StatefulWidget {
  const EnergyCheckInScreen({super.key});

  @override
  State<EnergyCheckInScreen> createState() => _EnergyCheckInScreenState();
}

class _EnergyCheckInScreenState extends State<EnergyCheckInScreen> {
  String? selectedMood;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Assets.svgIcons.bkPopupChooseMood.path),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Close button
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF7BA5E3),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),

              // Main content
              Column(
                children: [
                  const SizedBox(height: 60), // ✅ 100 → 60 করা হয়েছে
                  // Title
                  Text(
                    "HEY JULIE! HOW'S\nYOUR ENERGY TODAY?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF011F54),
                      fontSize: 32,
                      fontFamily: 'Wosker',
                      fontWeight: FontWeight.w400,
                      height: 0.9,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  const Text(
                    "What kind of day are we having?",
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),

                  const SizedBox(height: 20), // ✅ 40 → 20 করা হয়েছে
                  // ✅ Mood grid — Expanded দিয়ে বাকি space নেবে
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: GridView.count(
                        // ✅ shrinkWrap সরানো হয়েছে
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                        children: [
                          _buildMoodCard("Sad", Assets.svgIcons.sad),
                          _buildMoodCard("Happy", Assets.svgIcons.happy),
                          _buildMoodCard("Awesome", Assets.svgIcons.awosome),
                          _buildMoodCard(
                            "Peacefull",
                            Assets.svgIcons.peacefull,
                          ),
                          _buildMoodCard("Angry", Assets.svgIcons.angry),
                          _buildMoodCard("Anxious", Assets.svgIcons.anxious),
                          _buildMoodCard("Tired", Assets.svgIcons.tired),
                          _buildMoodCard("Empty", Assets.svgIcons.empty),
                          _buildMoodCard("Joyfull", Assets.svgIcons.joyfull),
                        ],
                      ),
                    ),
                  ),

                  // Bottom buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 69,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF4A4AF4),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: const Text(
                              "I'm not sure",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A4AF4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 69,
                          child: ElevatedButton(
                            onPressed: () {
                              context.push("/noticeLoaderScreen");
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A4AF4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Share",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodCard(String label, AssetGenImage moodImage) {
    final bool isSelected = selectedMood == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMood = label;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F2FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A8BF4) : Colors.transparent,
            width: 6,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: moodImage.image(fit: BoxFit.contain),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF011F54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
