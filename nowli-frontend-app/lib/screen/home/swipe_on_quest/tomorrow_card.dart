import 'package:flutter/material.dart';

class TomorrowCard extends StatelessWidget {
  const TomorrowCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFBD58A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFFF6A23A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF0B1633),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Quest moved for tomorrow!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF081433),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
