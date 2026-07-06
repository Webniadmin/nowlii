import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/create_qutes.dart';

class EditTitleWidget extends StatelessWidget {
  final double scale;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMicPressed;
  final bool isListening;
  
  const EditTitleWidget({
    super.key,
    this.scale = 1.0,
    this.onBackPressed,
    this.onMicPressed,
    this.isListening = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => context.pop(""),
              icon: Image.asset(
                Assets.svgIcons.settingsBackIcon.path,
                width: 32,
                height: 32,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            SizedBox(width: 30 * scale),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EDIT\nQUEST',
                    style: AppTextStylesQutes.alfaSlabOneTitle42,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6 * scale),
                  Text(
                    'Small steps big progress',
                    style: AppTextStylesQutes.workSansRegular16,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 20 * scale),
            GestureDetector(
              onTap: onMicPressed,
              child: Container(
                width: 44 * scale,
                height: 44 * scale,
                decoration: BoxDecoration(
                  color: isListening ? const Color(0xFFFF6B6B) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6 * scale,
                      offset: Offset(0, 3 * scale),
                    ),
                  ],
                ),
                child: Center(
                  child: isListening
                      ? Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 28 * scale,
                        )
                      : Image.asset(
                          Assets.svgIcons.voice.path,
                          width: 60 * scale,
                          height: 60 * scale,
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
