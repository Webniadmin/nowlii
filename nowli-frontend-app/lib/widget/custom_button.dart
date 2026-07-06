// // import 'package:flutter/material.dart';
// // import 'package:flutter_screenutil/flutter_screenutil.dart';
// // import 'package:flutter_svg/flutter_svg.dart';

// // class CustomNextButton extends StatelessWidget {
// //   final bool isEnabled;
// //   final VoidCallback? onTap;
// //   final String buttonText;
// //   final String? iconPath;
// //   final TextStyle? textStyle;
// //   final List<Color>? gradientColors;
// //   final double height;
// //   final double borderRadius;
// //   final EdgeInsetsGeometry padding;

// //   const CustomNextButton({
// //     super.key,
// //     required this.isEnabled,
// //     this.onTap,
// //     this.buttonText = 'NEXT',
// //     this.iconPath,
// //     this.textStyle,
// //     this.gradientColors,
// //     this.height = 100,
// //     this.borderRadius = 60,
// //     this.padding = const EdgeInsets.symmetric(horizontal: 25.0),
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     final defaultGradientColors =
// //         gradientColors ?? [const Color(0xFFFF9A3D), const Color(0xFFFF7A1A)];

// //     return Padding(
// //       padding: padding,
// //       child: GestureDetector(
// //         onTap: isEnabled ? onTap : null,
// //         child: Opacity(
// //           opacity: isEnabled ? 1.0 : 0.5,
// //           child: Container(
// //             width: double.infinity,
// //             height: height.h,
// //             decoration: BoxDecoration(
// //               gradient: LinearGradient(
// //                 colors: defaultGradientColors,
// //                 begin: Alignment.topCenter,
// //                 end: Alignment.bottomCenter,
// //               ),
// //               borderRadius: BorderRadius.circular(borderRadius.r),
// //               boxShadow: isEnabled
// //                   ? [
// //                       BoxShadow(
// //                         color: Colors.orange.withOpacity(0.3),
// //                         blurRadius: 10,
// //                         offset: const Offset(0, 5),
// //                       ),
// //                     ]
// //                   : [],
// //             ),
// //             child: Stack(
// //               children: [
// //                 /// 🔹 TEXT (20px gap maintain করবে icon এর সাথে)
// //                 if (iconPath != null)
// //                   Padding(
// //                     padding: EdgeInsets.only(
// //                       right: 108.w, // 80(icon) + 8(right) + 20(gap)
// //                     ),
// //                     child: Center(
// //                       child: Text(
// //                         buttonText,
// //                         style:
// //                             textStyle ??
// //                             TextStyle(
// //                               color: Colors.white,
// //                               fontSize: 28.sp,
// //                               fontWeight: FontWeight.bold,
// //                             ),
// //                       ),
// //                     ),
// //                   )
// //                 else
// //                   Center(
// //                     child: Text(
// //                       buttonText,
// //                       style:
// //                           textStyle ??
// //                           TextStyle(
// //                             color: Colors.white,
// //                             fontSize: 58.sp,
// //                             fontWeight: FontWeight.bold,
// //                           ),
// //                     ),
// //                   ),

// //                 /// 🔹 ICON (Position unchanged)
// //                 if (iconPath != null)
// //                   Positioned(
// //                     right: 1.w,
// //                     top: 8.h,
// //                     bottom: 8.h,
// //                     child: Container(
// //                       width: 80.w,
// //                       height: 78.h,
// //                       decoration: const BoxDecoration(
// //                         color: Color(0xFF1A1A40),
// //                         shape: BoxShape.circle,
// //                       ),
// //                       child: Center(
// //                         child: SvgPicture.asset(
// //                           iconPath!,
// //                           width: 60.w,
// //                           height: 60.h,
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomNextButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback? onTap;
  final String buttonText;
  final String? iconPath;
  final TextStyle? textStyle;
  final List<Color>? gradientColors;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const CustomNextButton({
    super.key,
    required this.isEnabled,
    this.onTap,
    this.buttonText = 'NEXT',
    this.iconPath,
    this.textStyle,
    this.gradientColors,
    this.height = 100,
    this.borderRadius = 60,
    this.padding = const EdgeInsets.symmetric(horizontal: 25.0),
  });

  @override
  Widget build(BuildContext context) {
    final defaultGradientColors =
        gradientColors ?? [const Color(0xFFFF9A3D), const Color(0xFFFF7A1A)];

    return Padding(
      padding: padding,
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Container(
            // width: 334.w, // Fixed width
            width: double.infinity,
            height: height.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: defaultGradientColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(borderRadius.r),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                // 🔹 TEXT (spacing adjusted if icon exists)
                if (iconPath != null)
                  Padding(
                    padding: EdgeInsets.only(
                      right: 108.w, // 80(icon) + 8(right padding) + 20(gap)
                    ),
                    child: Center(
                      child: Text(
                        buttonText,
                        style:
                            textStyle ??
                            TextStyle(
                              color: Colors.white,
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Text(
                      buttonText,
                      style:
                          textStyle ??
                          TextStyle(
                            color: Colors.white,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),

                // 🔹 ICON (if provided)
                if (iconPath != null)
                  Positioned(
                    right: 1.w,
                    top: 8.h,
                    bottom: 8.h,
                    child: Container(
                      width: 80.w,
                      height: 78.h,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A1A40),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          iconPath!,
                          width: 60.w,
                          height: 60.h,
                        ),
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

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/flutter_svg.dart';

// class CustomNextButton extends StatelessWidget {
//   final bool isEnabled;
//   final VoidCallback? onTap;
//   final String buttonText;
//   final String? iconPath;
//   final TextStyle? textStyle;
//   final List<Color>? gradientColors;
//   final double height;
//   final double borderRadius;
//   final EdgeInsetsGeometry padding;

//   const CustomNextButton({
//     super.key,
//     required this.isEnabled,
//     this.onTap,
//     this.buttonText = 'NEXT',
//     this.iconPath,
//     this.textStyle,
//     this.gradientColors,
//     this.height = 100,
//     this.borderRadius = 60,
//     this.padding = const EdgeInsets.symmetric(horizontal: 25.0),
//   });

//   @override
//   Widget build(BuildContext context) {
//     final defaultGradientColors =
//         gradientColors ?? [const Color(0xFFFF9A3D), const Color(0xFFFF7A1A)];

//     return Padding(
//       padding: padding,
//       child: GestureDetector(
//         onTap: isEnabled ? onTap : null,
//         child: Opacity(
//           opacity: isEnabled ? 1.0 : 0.5,
//           child: Container(
//             width: double.infinity,
//             height: height.h,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: defaultGradientColors,
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//               borderRadius: BorderRadius.circular(borderRadius.r),
//               boxShadow: isEnabled
//                   ? [
//                       BoxShadow(
//                         color: Colors.orange.withOpacity(0.3),
//                         blurRadius: 10,
//                         offset: const Offset(0, 5),
//                       ),
//                     ]
//                   : [],
//             ),
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 // 🔹 Centered Text
//                 Text(
//                   buttonText,
//                   textAlign: TextAlign.center,
//                   style:
//                       textStyle ??
//                       TextStyle(
//                         color: Colors.white,
//                         fontSize: 28.sp,
//                         fontWeight: FontWeight.bold,
//                       ),
//                 ),

//                 // 🔹 Positioned Icon (fixed on the right)
//                 if (iconPath != null)
//                   Positioned(
//                     right: 0.w,
//                     top: 8.h,
//                     bottom: 8.h,
//                     child: Container(
//                       width: 80.w,
//                       height: 78.h,
//                       decoration: const BoxDecoration(
//                         color: Color(0xFF1A1A40),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Center(
//                         child: SvgPicture.asset(
//                           iconPath!,
//                           width: 60.w,
//                           height: 60.h,
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
