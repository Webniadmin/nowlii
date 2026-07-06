import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

class CustomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  @override
  void initState() {
    super.initState();
    // Register LanguageController only once
    if (!Get.isRegistered<LanguageController>()) {
      Get.put(LanguageController());
    }
  }

  // Indicator left position
  double _indicatorLeft(BuildContext context) =>
      MediaQuery.of(context).size.width / 3 * widget.currentIndex;

  // Navigation logic
  void _onNavTap(int index) {
    widget.onTap(index); // Updates UI on parent side

    switch (index) {
      case 0:
        context.go(AppRoutespath.homeScreen);
        break;
      case 1:
        context.go(AppRoutespath.questHomePage);
        break;
      case 2:
        context.go(AppRoutespath.progress);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFDFEFFF),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(6, 0),
            blurRadius: 10,
          ),
        ],
      ),
      child: Stack(
        children: [
          GetBuilder<LanguageController>(
            builder: (controller) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    icon: Assets.svgIcons.homeTab.path,
                    label: 'Home'.tr,
                    index: 0,
                    isSelected: widget.currentIndex == 0,
                  ),
                  _buildNavItem(
                    icon: Assets.svgIcons.magicWand.path,
                    label: 'Quests'.tr,
                    index: 1,
                    isSelected: widget.currentIndex == 1,
                  ),
                  _buildNavItem(
                    icon: Assets.svgIcons.fireTab.path,
                    label: 'Progress'.tr,
                    index: 2, // FIXED
                    isSelected: widget.currentIndex == 2, // FIXED
                  ),
                ],
              );
            },
          ),

          // Bottom indicator line
          AnimatedPositioned(
            bottom: 0,
            left: _indicatorLeft(context),
            duration: const Duration(milliseconds: 300),
            child: Container(
              height: 3,
              width: MediaQuery.of(context).size.width / 3,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final iconColor = isSelected
        ? const Color(0xFF4542EB)
        : const Color(0xFF011F54);
    final textColor = isSelected
        ? const Color(0xFF4542EB)
        : const Color(0xFF011F54);

    return GestureDetector(
      onTap: () => _onNavTap(index), // FIXED
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Image.asset(icon, color: iconColor, width: 24, height: 24),
          ],
        ),
      ),
    );
  }
}

class LanguageController extends GetxController {
  void updateLanguage(Locale locale) {
    Get.updateLocale(locale);
    update();
  }
}
