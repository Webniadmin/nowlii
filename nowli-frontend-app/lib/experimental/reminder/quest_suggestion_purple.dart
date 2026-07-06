// import 'package:flutter/material.dart';

// class QuestSuggestionPurpleq extends StatelessWidget {
//   const QuestSuggestionPurpleq({super.key});
//   @override
//   Widget build(BuildContext c) {
//     return CustomPaint(
//       child: Container(
//         width: 335,
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//         decoration: ShapeDecoration(
//           image: DecorationImage(
//             image: AssetImage("assets/svg_images/Toast.png"),
//             fit: BoxFit.cover,
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           shadows: [
//             BoxShadow(
//               color: Color(0x070A0C12),
//               blurRadius: 6,
//               offset: Offset(0, 4),
//               spreadRadius: -2,
//             ),
//             BoxShadow(
//               color: Color(0x140A0C12),
//               blurRadius: 16,
//               offset: Offset(0, 12),
//               spreadRadius: -4,
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           spacing: 10,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: ShapeDecoration(
//                 color: const Color(
//                   0xFF3F3CD6,
//                 ) /* Background-bg-primary-on-press */,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 spacing: 10,
//                 children: [
//                   Image.asset(
//                     "assets/svg_icons/sun.png",
//                     width: 24,
//                     height: 24,
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 spacing: 16,
//                 children: [
//                   SizedBox(
//                     width: 237,
//                     child: Text(
//                       'Wake up or wind down with Nowlli! 😴🌞',
//                       style: TextStyle(
//                         color: const Color(0xFF011F54) /* Text-text-default */,
//                         fontSize: 20,
//                         fontFamily: 'Work Sans',
//                         fontWeight: FontWeight.w800,
//                         height: 1.20,
//                         letterSpacing: -0.50,
//                       ),
//                     ),
//                   ),
//                   SizedBox(
//                     width: 237,
//                     child: Text(
//                       'You can schedule Nowlli for wake-up or bedtime calls! Just create a task, turn on repeat, and Nowlli will call you 10 minutes before — to help you wake up or drift off peacefully. 💕',
//                       style: TextStyle(
//                         color: const Color(
//                           0xFF595754,
//                         ) /* Text-text-secondary-default */,
//                         fontSize: 14,
//                         fontFamily: 'Work Sans',
//                         fontWeight: FontWeight.w400,
//                         height: 1.60,
//                       ),
//                     ),
//                   ),
//                   Container(
//                     width: double.infinity,
//                     height: 44,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 40,
//                       vertical: 14,
//                     ),
//                     decoration: ShapeDecoration(
//                       color: const Color(
//                         0xFF4542EB,
//                       ) /* Background-bg-primary */,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(999),
//                       ),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       spacing: 8,
//                       children: [
//                         const Icon(
//                           Icons.add,
//                           color: Color(0xFFFFFDF7),
//                           size: 18,
//                         ),
//                         Text(
//                           'Add quest',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: const Color(
//                               0xFFFFFDF7,
//                             ) /* Text-text-light */,
//                             fontSize: 18,
//                             fontFamily: 'Work Sans',
//                             fontWeight: FontWeight.w900,
//                             height: 0.80,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class QuestSuggestionPurpleq extends StatelessWidget {
  const QuestSuggestionPurpleq({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 282,
      height: 440,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: ShapeDecoration(
        image: const DecorationImage(
          image: AssetImage("assets/svg_images/Toast.png"),
          fit: BoxFit.cover,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadows: const [
          BoxShadow(
            color: Color(0x070A0C12),
            blurRadius: 6,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Color(0x140A0C12),
            blurRadius: 16,
            offset: Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ICON
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3F3CD6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Image.asset(
              "assets/svg_icons/sun.png",
              width: 24,
              height: 24,
            ),
          ),

          const SizedBox(width: 10),

          /// CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE
                const Text(
                  'Wake up or wind down with Nowlli! 😴🌞',
                  style: TextStyle(
                    color: Color(0xFF011F54),
                    fontSize: 20,
                    fontFamily: 'Work Sans',
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    // letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 16),

                /// DESCRIPTION
                const Text(
                  'You can schedule Nowlli for wake-up or bedtime calls! '
                  'Just create a task, turn on repeat, and Nowlli will call you '
                  '10 minutes before — to help you wake up or drift off peacefully. 💕',
                  style: TextStyle(
                    color: Color(0xFF595754),
                    fontSize: 14,
                    fontFamily: 'Work Sans',
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 20),

                /// BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4542EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      debugPrint('Add quest action pressed');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, color: Color(0xFFFFFDF7), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Add quest',
                          style: TextStyle(
                            color: Color(0xFFFFFDF7),
                            fontSize: 18,
                            fontFamily: 'Work Sans',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
