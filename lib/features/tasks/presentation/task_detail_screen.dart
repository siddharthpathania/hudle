import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/tasks_repository.dart';
import '../domain/task_model.dart';
import '../domain/tasks_provider.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({required this.taskId, super.key});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskDetailProvider(taskId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          taskAsync.maybeWhen(
            data: (t) => IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _confirmDelete(context, ref, t),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: taskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $e'),
          ),
        ),
        data: (task) => _TaskDetailBody(task: task),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.hudleRose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(tasksRepositoryProvider).deleteTask(task.id);
    ref.invalidate(groupTasksProvider(
        (groupId: task.groupId, filter: TaskFilter.all)));
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _TaskDetailBody extends ConsumerStatefulWidget {
  const _TaskDetailBody({required this.task});
  final Task task;

  @override
  ConsumerState<_TaskDetailBody> createState() => _TaskDetailBodyState();
}

class _TaskDetailBodyState extends ConsumerState<_TaskDetailBody> {
  final _subtaskCtrl = TextEditingController();

  @override
  void dispose() {
    _subtaskCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(String hex) {
    final n = hex.replaceFirst('#', '');
    return Color(int.parse('FF$n', radix: 16));
  }

  Future<void> _toggleSubtask(Subtask s) async {
    await ref
        .read(tasksRepositoryProvider)
        .toggleSubtask(s.id, !s.isCompleted);
    ref.invalidate(taskDetailProvider(widget.task.id));
  }

  Future<void> _addSubtask() async {
    final title = _subtaskCtrl.text.trim();
    if (title.isEmpty) return;
    _subtaskCtrl.clear();
    await ref.read(tasksRepositoryProvider).addSubtask(
          widget.task.id,
          title,
          widget.task.subtasks.length,
        );
    ref.invalidate(taskDetailProvider(widget.task.id));
  }

  Future<void> _deleteSubtask(String id) async {
    await ref.read(tasksRepositoryProvider).deleteSubtask(id);
    ref.invalidate(taskDetailProvider(widget.task.id));
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            PriorityBadge(priority: t.priority),
            const SizedBox(width: 8),
            if (t.status != null)
              StatusBadge(
                label: t.status!.label,
                color: _statusColor(t.status!.color),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          t.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (t.description != null && t.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            t.description!,
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (t.dueAt != null)
          Card(
            child: ListTile(
              leading: Icon(
                Icons.calendar_today_rounded,
                color: t.isOverdue
                    ? AppColors.hudleRose
                    : AppColors.emberOrange,
              ),
              title: Text(t.isOverdue ? 'Overdue' : 'Due'),
              subtitle: Text(
                DateFormat.yMMMMEEEEd().add_jm().format(t.dueAt!),
                style: GoogleFonts.dmSans(
                  color: t.isOverdue
                      ? AppColors.hudleRose
                      : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        if (t.assignees.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Assignees', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: t.assignees
                .map((a) => Chip(
                      avatar: CircleAvatar(
                        backgroundImage: a.avatarUrl != null
                            ? NetworkImage(a.avatarUrl!)
                            : null,
                        backgroundColor: AppColors.inkMuted,
                      ),
                      label: Text(a.displayName ?? 'User'),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 24),
        Text('Subtasks', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (final s in t.subtasks)
                CheckboxListTile(
                  value: s.isCompleted,
                  onChanged: (_) => _toggleSubtask(s),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    s.title,
                    style: TextStyle(
                      decoration:
                          s.isCompleted ? TextDecoration.lineThrough : null,
                      color: s.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  secondary: IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textSecondary),
                    onPressed: () => _deleteSubtask(s.id),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskCtrl,
                        onSubmitted: (_) => _addSubtask(),
                        decoration: const InputDecoration(
                          hintText: 'Add a subtask',
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded,
                          color: AppColors.emberOrange),
                      onPressed: _addSubtask,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (t.attachments.isNotEmpty) ...[
          Text('Attachments', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...t.attachments.map(
            (a) => Card(
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(a.fileName),
                subtitle: Text(
                  a.fileType,
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
