// import 'package:flutter/material.dart';
// import 'package:nowlii/core/gen/assets.gen.dart';
// import 'package:nowlii/themes/text_styles.dart';

// class ClearMemoryPopup extends StatelessWidget {
//   const ClearMemoryPopup({Key? key}) : super(key: key);

//   static Future<bool?> show(BuildContext context) {
//     return showModalBottomSheet<bool>(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => const ClearMemoryPopup(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 0, 16, 30),
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFE5E5),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Column(
//         // mainAxisSize: MainAxisSize.s,
//         children: [
//           // Drag handle
//           Container(
//             width: 40,
//             height: 4,
//             decoration: BoxDecoration(
//               color: Colors.grey.shade400,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           const SizedBox(height: 20),

//           // Icon
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               // color: const Color(0xFFE53935),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Assets.svgIcons.clearAllAIMemory.pathWidget(
//               width: 40,
//               height: 40,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 20),

//           // Title
//           Text('Clear All AI Memory?', style: AppsTextStyles.workSansRegular16),
//           const SizedBox(height: 16),

//           // Description
//           Text(
//             'This will erase everything Nowlli has learned about you - moods, reflections, and conversation history. Your connection will start fresh, like meeting for the first time.\n\nAre you sure you want to continue?',
//             textAlign: TextAlign.center,
//             style: AppsTextStyles.workSansRegularF16,
//           ),
//           const SizedBox(height: 24),

//           // Buttons
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     side: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
//                     backgroundColor: Colors.transparent,
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
//                   onPressed: () => Navigator.pop(context, true),
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     backgroundColor: const Color(0xFFE53935),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: const Text(
//                     'Clear',
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
// }
import 'package:flutter/material.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/text_styles.dart';

class ClearMemoryPopup extends StatelessWidget {
  const ClearMemoryPopup({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ClearMemoryPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                Assets.images.device.path,
                width: 40,
                height: 40,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text('Clear All AI Memory?', style: AppsTextStyles.textDefaultStyle),
            const SizedBox(height: 16),

            // Description
            Text(
              'This will erase everything Nowlli has learned about you - moods, reflections, and conversation history. Your connection will start fresh, like meeting for the first time.\n\nAre you sure you want to continue?',
              textAlign: TextAlign.center,
              style: AppsTextStyles.workSansRegularF16,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
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
                        style: AppsTextStyles.textDefaultStyle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'Clear',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
