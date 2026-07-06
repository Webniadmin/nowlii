import 'package:flutter/material.dart';

class TaskCompletedCard extends StatelessWidget {
  const TaskCompletedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340, // fixed width similar to uploaded design
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFCFFFCF), // Light Green background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.celebration_rounded,
              size: 18,
              color: Color(0xFF1E1E1E),
            ),
          ),

          const SizedBox(width: 12),

          // Main Text
          const Expanded(
            child: Text(
              "Boom, your first task completed!",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Right streak badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "+1 streak",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
