// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:nowlii/core/gen/assets.gen.dart';

// class AicallingTwo extends StatefulWidget {
//   const AicallingTwo({super.key});

//   @override
//   State createState() => _AiCallingState();
// }

// class _AiCallingState extends State {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: BoxDecoration(
//           image: DecorationImage(
//             image: Assets.svgImages.popupScreeLiner.image().image,
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // Close Button
//               Align(
//                 alignment: Alignment.topLeft,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: const CircleAvatar(
//                       backgroundColor: Colors.white,
//                       child: Icon(Icons.close, color: Colors.blue),
//                     ),
//                   ),
//                 ),
//               ),

//               SizedBox(
//                 width: 250,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Text(
//                       'Answer emails ✉️',
//                       textAlign: TextAlign.center,
//                       style: GoogleFonts.workSans(
//                         color: const Color(0xFF011F54),
//                         fontSize: 28,
//                         fontWeight: FontWeight.w800,
//                         height: 1.2,
//                         letterSpacing: -1,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(
//                 width: 324.39,
//                 child: Text(
//                   'Fuzzy\'s here, you\'ve got this',
//                   textAlign: TextAlign.center,
//                   style: GoogleFonts.workSans(
//                     color: const Color(0xFF011F54),
//                     fontSize: 18,
//                     fontWeight: FontWeight.w400,
//                     height: 1.4,
//                     letterSpacing: -0.5,
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 60),

//               // ✅ Progress Ring + Circles
//               Center(
//                 child: SizedBox(
//                   width: 252,
//                   height: 252,
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       // ✅ Progress Ring
//                       CustomPaint(
//                         size: const Size(248, 248),
//                         painter: RingPainter(0.30),
//                       ),

//                       // ✅ Outer Circle
//                       Container(
//                         width: 258,
//                         height: 255,
//                         decoration: const BoxDecoration(
//                           shape: BoxShape.circle,
//                           gradient: RadialGradient(
//                             center: Alignment(-0.08, 0.0),
//                             radius: 1.0,
//                             colors: [Color(0x003F3CD6), Color(0x333F3CD6)],
//                             stops: [0.0, 0.6683],
//                           ),
//                         ),

//                         // ✅ Inner Circle + Image
//                         child: Center(
//                           child: Container(
//                             width: 182.58,
//                             height: 182.58,
//                             decoration: ShapeDecoration(
//                               gradient: const RadialGradient(
//                                 center: Alignment(0.50, 0.50),
//                                 radius: 0.73,
//                                 colors: [Color(0xFF7270F3), Color(0xFF3F3CD6)],
//                               ),
//                               shape: const OvalBorder(),
//                               shadows: const [
//                                 BoxShadow(
//                                   color: Color(0x995550FF),
//                                   blurRadius: 19.60,
//                                   offset: Offset(0, 0),
//                                   spreadRadius: 11,
//                                 ),
//                               ],
//                             ),
//                             child: ClipOval(
//                               child: Assets.deaPng.popupSpeaking.image(
//                                 width: 130.58,
//                                 height: 129.58,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               // Timer Row
//               Row(
//                 mainAxisSize: MainAxisSize.min,
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Container(
//                     width: 40,
//                     height: 40,
//                     padding: const EdgeInsets.all(10),
//                     decoration: ShapeDecoration(
//                       color: const Color(0xFFC3DBFF),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(999),
//                       ),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         SizedBox(width: 20, height: 20, child: Stack()),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       const Text(
//                         '05:43',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Color(0xFF4542EB),
//                           fontSize: 52,
//                           fontFamily: 'Wosker',
//                           fontWeight: FontWeight.w400,
//                           height: 0.80,
//                         ),
//                       ),
//                       const Text(
//                         '/',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Color(0xFFA9A8F6),
//                           fontSize: 52,
//                           fontFamily: 'Wosker',
//                           fontWeight: FontWeight.w400,
//                           height: 0.80,
//                         ),
//                       ),
//                       const Text(
//                         '10:00',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Color(0xFFA9A8F6),
//                           fontSize: 52,
//                           fontFamily: 'Wosker',
//                           fontWeight: FontWeight.w400,
//                           height: 0.80,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),

//               // ✅ FIXED: Bottom Action Buttons Row
//               SizedBox(
//                 width: 335,
//                 child: Row(
//                   // ✅ FIX 1: Changed from MainAxisSize.min to MainAxisSize.max
//                   mainAxisSize: MainAxisSize.max,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   // ✅ FIX 2: Removed spacing: 124 — was causing 5px overflow
//                   children: [
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Container(
//                           width: 64,
//                           height: 64,
//                           padding: const EdgeInsets.all(10),
//                           decoration: ShapeDecoration(
//                             color: const Color(0xFFC3DBFF),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(999),
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               SizedBox(width: 24, height: 24, child: Stack()),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Container(
//                           width: 64,
//                           height: 64,
//                           padding: const EdgeInsets.all(10),
//                           decoration: ShapeDecoration(
//                             color: const Color(0xFFC3DBFF),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(999),
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               SizedBox(width: 24, height: 24, child: Stack()),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),

//                     // Mark as Done Button
//                     SizedBox(
//                       width: 80,
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Container(
//                             width: 64,
//                             height: 64,
//                             padding: const EdgeInsets.all(10),
//                             decoration: ShapeDecoration(
//                               color: const Color(0xFFC3DBFF),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(999),
//                               ),
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 SizedBox(
//                                   width: 28.88,
//                                   height: 28.88,
//                                   child: Stack(),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           const SizedBox(
//                             width: 80,
//                             child: Text(
//                               'Mark as done',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 color: Color(0xFF011F54),
//                                 fontSize: 12,
//                                 fontFamily: 'Work Sans',
//                                 fontWeight: FontWeight.w600,
//                                 height: 1,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ✅ Ring Painter
// class RingPainter extends CustomPainter {
//   final double progress;

//   RingPainter(this.progress);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = (size.width / 2) - 6;

//     // ✅ Progress Arc with Gradient
//     final progressPaint = Paint()
//       ..shader = const LinearGradient(
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//         colors: [Color(0xFF3D87F5), Color(0xFF68A2F9)],
//       ).createShader(Rect.fromCircle(center: center, radius: radius))
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 16
//       ..strokeCap = StrokeCap.round;

//     final startAngle = -pi / 2;
//     final sweepAngle = 2 * pi * progress;

//     canvas.drawArc(
//       Rect.fromCircle(center: center, radius: radius),
//       startAngle,
//       sweepAngle,
//       false,
//       progressPaint,
//     );
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }
