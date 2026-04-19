import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/widgets/avatar_stack.dart';
import '../../../../core/widgets/priority_badge.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/task_model.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({required this.task, super.key, this.showGroup = false});
  final Task task;
  final bool showGroup;

  Color _priorityColor() => switch (task.priority) {
        TaskPriority.low => AppColors.priorityLow,
        TaskPriority.medium => AppColors.priorityMedium,
        TaskPriority.high => AppColors.priorityHigh,
        TaskPriority.urgent => AppColors.priorityUrgent,
      };

  Color _statusColor() {
    final hex = task.status?.color ?? '#64748B';
    final normalized = hex.replaceFirst('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final total = task.subtasks.length;
    final done = task.completedSubtaskCount;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/groups/${task.groupId}/tasks/${task.id}'),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: _priorityColor()),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          PriorityBadge(priority: task.priority),
                        ],
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AvatarStack(
                            avatarUrls:
                                task.assignees.map((a) => a.avatarUrl).toList(),
                            size: 22,
                          ),
                          const Spacer(),
                          if (task.status != null) ...[
                            StatusBadge(
                              label: task.status!.label,
                              color: _statusColor(),
                            ),
                            const SizedBox(width: UI.space8),
                          ],
                          if (task.dueAt != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 11,
                                  color: task.isOverdue
                                      ? AppColors.hudleRose
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat.MMMd().format(task.dueAt!),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: task.isOverdue
                                        ? AppColors.hudleRose
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (total > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '$done/$total',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: total == 0 ? 0 : done / total,
                                  minHeight: 4,
                                  backgroundColor: AppColors.inkBorder,
                                  color: AppColors.hudleTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (showGroup && task.groupName != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '· ${task.groupName}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.amberGold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
