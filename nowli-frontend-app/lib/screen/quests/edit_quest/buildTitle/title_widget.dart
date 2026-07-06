import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/create_qutes.dart';

class TitleWidget extends StatelessWidget {
  final double scale;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMicPressed;
  const TitleWidget({
    super.key,
    this.scale = 1.0,
    this.onBackPressed,
    this.onMicPressed,
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
          mainAxisSize:
              MainAxisSize.min, // Prevent Row from expanding infinitely
          children: [
            GestureDetector(
              onTap: () {
                context.pop("");
              },
              child: CircleAvatar(
                // radius: 10 * scale,
                child: Image.asset(
                  Assets.svgIcons.settingsBackIcon.path,
                  height: 50,
                  width: 50,
                ),
              ),
            ),
            SizedBox(width: 30 * scale),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CREATE\nQUEST',
                    style: AppTextStylesQutes.alfaSlabOneTitle42,
                    overflow: TextOverflow.ellipsis, // Prevent text overflow
                  ),
                  SizedBox(height: 6 * scale),
                  Text(
                    'Small steps big progress',
                    style: AppTextStylesQutes.workSansRegular16,
                    overflow: TextOverflow.ellipsis, // Prevent text overflow
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
                  child: Image.asset(
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
