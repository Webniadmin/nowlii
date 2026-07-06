import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  final double scale;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMicPressed;

  const HeaderWidget({
    super.key,
    this.scale = 1.0,
    this.onBackPressed,
    this.onMicPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // GestureDetector(
        //   onTap: onBackPressed,
        //   child: CircleAvatar(
        //     radius: 18 * scale,

        //     child: Image.asset(Assets.svgIcons.settingsBackIcon.path),
        //   ),
        // ),

        // GestureDetector(
        //   onTap: onMicPressed,
        //   child: Container(
        //     width: 44 * scale,
        //     height: 44 * scale,
        //     decoration: BoxDecoration(
        //       borderRadius: BorderRadius.circular(10 * scale),
        //       boxShadow: [
        //         BoxShadow(
        //           color: Colors.black.withOpacity(0.08),
        //           blurRadius: 6 * scale,
        //           offset: Offset(0, 3 * scale),
        //         ),
        //       ],
        //     ),
        //     child: Center(
        //       child: Image.asset(
        //         Assets.svgIcons.voice.path,
        //         width: 20 * scale,
        //         height: 20 * scale,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
