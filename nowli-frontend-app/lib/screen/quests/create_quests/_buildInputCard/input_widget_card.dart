import 'package:flutter/material.dart';
import 'package:nowlii/themes/create_qutes.dart';

class InputCardWidget extends StatelessWidget {
  final double scale;
  final TextEditingController? controller;
  final String? initialValue;

  const InputCardWidget({
    super.key, 
    this.scale = 1.0, 
    this.controller,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    // Create controller with initial value if provided
    final effectiveController = controller ?? 
      (initialValue != null ? TextEditingController(text: initialValue) : null);
    
    return Container(
      height: 160,
      width: double.infinity,
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8 * scale,
          ),
        ],
      ),
      child: TextField(
        controller: effectiveController,
        maxLines: null, // Allow multiple lines
        expands: true, // Expand to fill container
        textAlignVertical: TextAlignVertical.top, // Align text to top
        style: AppTextStylesQutes.workSansExtraBold32.copyWith(
          color: const Color(0xFF011F54), // Dark blue color for input text
        ),
        decoration: InputDecoration(
          hintText: 'Write down your \n quest...',
          hintStyle: AppTextStylesQutes.workSansExtraBold32.copyWith(
            color: const Color(0xFFB3B2B0), // Light gray for hint
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero, // Remove default padding
        ),
      ),
    );
  }
}
