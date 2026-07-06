import 'package:flutter/material.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

class DeleteToast extends StatelessWidget {
  final VoidCallback onUndo;

  const DeleteToast({super.key, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 335,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: ShapeDecoration(
        color: const Color(0xFFFDDBDC) /* Background-bg-error-light */,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadows: [
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
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  Assets.svgIcons.selateQuest.path,
                  height: 44,
                  width: 44,
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              // spacing removed (not a valid Column property)
              children: [
                SizedBox(
                  width: 237,
                  child: Text(
                    'Quest deleted',
                    style: TextStyle(
                      color: const Color(0xFF011F54) /* Text-text-default */,
                      fontSize: 20,
                      fontFamily: 'Work Sans',
                      fontWeight: FontWeight.w800,
                      height: 1.20,
                      letterSpacing: -0.50,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onUndo,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFD53D3F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Undo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(
                              0xFFFFFDF7,
                            ) /* Text-text-light */,
                            fontSize: 18,
                            fontFamily: 'Work Sans',
                            fontWeight: FontWeight.w900,
                            height: 0.80,
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
