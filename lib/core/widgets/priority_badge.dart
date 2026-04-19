import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

enum TaskPriority { low, medium, high, urgent }

extension TaskPriorityX on TaskPriority {
  String get wire => name;
  static TaskPriority fromWire(String? v) =>
      TaskPriority.values.firstWhere((p) => p.wire == v, orElse: () => TaskPriority.medium);
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({required this.priority, super.key});
  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (priority) {
      TaskPriority.low => (AppColors.priorityLow, '↓ Low'),
      TaskPriority.medium => (AppColors.priorityMedium, '→ Medium'),
      TaskPriority.high => (AppColors.priorityHigh, '↑ High'),
      TaskPriority.urgent => (AppColors.priorityUrgent, '⚡ Urgent'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
