// import 'package:flutter/material.dart';
// import 'package:nowlii/core/gen/assets.gen.dart';
// import 'package:nowlii/screen/reminder_notification/choose_your_mood/loader.dart';
// import 'package:nowlii/themes/text_styles.dart';
// import 'package:nowlii/utils/color_palette/color_palette.dart';

// class RestrictedTopicsPopup extends StatefulWidget {
//   const RestrictedTopicsPopup({Key? key}) : super(key: key);

//   static Future<List<String>?> show(BuildContext context) {
//     return showModalBottomSheet<List<String>>(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) => const RestrictedTopicsPopup(),
//     );
//   }

//   @override
//   State<RestrictedTopicsPopup> createState() => _RestrictedTopicsPopupState();
// }

// class _RestrictedTopicsPopupState extends State<RestrictedTopicsPopup> {
//   final Set<String> _selectedTopics = {};

//   final List<String> _topics = [
//     'Health or medical discussions',
//     'Relationship advice',
//     'Emotionally heavy or distress topics',
//     'Sensitive news / politics',
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 0, 16, 30),
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: AppColorsApps.skyBlueLight,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Drag handle
//           Center(
//             child: Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade400,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),

//           // Title and description
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF1E3A8A),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Assets.svgIcons.restrictedTopics.path((
//                   width: 24,
//                   height: 24,
//                 )),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   'Restricted Topics',
//                   style: AppsTextStyles.myWorkSansStyle,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'You control what Nowlli talks about - for a safe, positive space.',
//             style: AppsTextStyles.workSansRegular16,
//           ),
//           const SizedBox(height: 20),

//           // Topics list
//           ..._topics.map((topic) => _buildTopicCheckbox(topic)),

//           const SizedBox(height: 24),

//           // Buttons
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     side: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   child: const Text(
//                     'Cancel',
//                     style: TextStyle(
//                       color: Color(0xFF1E3A8A),
//                       fontSize: 16,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(context, _selectedTopics.toList());
//                   },
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     backgroundColor: const Color(0xFF4C3EDD),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: const Text(
//                     'Save',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTopicCheckbox(String topic) {
//     final isSelected = _selectedTopics.contains(topic);

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Material(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         child: InkWell(
//           onTap: () {
//             setState(() {
//               if (isSelected) {
//                 _selectedTopics.remove(topic);
//               } else {
//                 _selectedTopics.add(topic);
//               }
//             });
//           },
//           borderRadius: BorderRadius.circular(12),
//           child: Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: isSelected ? const Color(0xFFFFF9E6) : Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: isSelected
//                     ? const Color(0xFF4C3EDD)
//                     : Colors.transparent,
//                 width: 2,
//               ),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: 24,
//                   height: 24,
//                   decoration: BoxDecoration(
//                     color: isSelected ? const Color(0xFF4C3EDD) : Colors.white,
//                     borderRadius: BorderRadius.circular(6),
//                     border: Border.all(
//                       color: isSelected
//                           ? const Color(0xFF4C3EDD)
//                           : const Color(0xFFD1D5DB),
//                       width: 2,
//                     ),
//                   ),
//                   child: isSelected
//                       ? const Icon(Icons.check, color: Colors.white, size: 16)
//                       : null,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     topic,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF1E3A8A),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

import 'package:nowlii/utils/color_palette/color_palette.dart';

class RestrictedTopicsPopup extends StatefulWidget {
  const RestrictedTopicsPopup({super.key});

  static Future<List<String>?> show(BuildContext context) {
    return showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const RestrictedTopicsPopup(),
    );
  }

  @override
  State<RestrictedTopicsPopup> createState() => _RestrictedTopicsPopupState();
}

class _RestrictedTopicsPopupState extends State<RestrictedTopicsPopup> {
  final Set<String> _selectedTopics = {};

  final List<String> _topics = [
    'Health or medical discussions',
    'Relationship advice',
    'Emotionally heavy or distress topics',
    'Sensitive news / politics',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColorsApps.skyBlueLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title and description
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),

                child: Image.asset(
                  Assets.svgIcons.restrictedTopics.path,
                  width: 28,
                  height: 28,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Restricted Topics',
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54), // Text-text-default
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.20,
                    letterSpacing: -0.50,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: 295,
            child: Text(
              'You control what Nowlli talks about - for a safe, positive space.',
              style: GoogleFonts.workSans(
                color: const Color(0xFF011F54), // Text-text-default
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.40,
                letterSpacing: -0.50,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Topics list
          ..._topics.map((topic) => _buildTopicCheckbox(topic)),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: const Color(0xFF1E3A8A),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'Cancel',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF011F54), // Text-text-default
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 0.80,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context, _selectedTopics.toList());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4C3EDD),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'Save',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.workSans(
                        color: const Color(0xFFFFFDF7), // Text-text-light
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 0.80,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCheckbox(String topic) {
    final isSelected = _selectedTopics.contains(topic);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedTopics.remove(topic);
              } else {
                _selectedTopics.add(topic);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFF9E6) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4C3EDD)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4C3EDD) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4C3EDD)
                          : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    topic,

                    style: GoogleFonts.workSans(
                      color: const Color(0xFF011F54), // Text-text-default
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.40,
                      letterSpacing: -0.90,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
