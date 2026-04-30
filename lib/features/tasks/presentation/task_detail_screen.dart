import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
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

  /// Opens a bottom-sheet to pick/remove assignees for [task].
  Future<void> _editAssignees(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final repo = ref.read(tasksRepositoryProvider);
    List<GroupMember> members;
    try {
      members = await repo.fetchGroupMembers(task.groupId);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load members')),
        );
      }
      return;
    }
    if (!context.mounted) return;

    final currentUid = SupabaseService.currentUser?.id;
    final selected = <String>{
      for (final a in task.assignees) a.userId,
    };

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AssigneePickerSheet(
        members: members,
        selected: selected,
        creatorId: task.createdBy ?? currentUid ?? '',
      ),
    );

    if (saved != true || !context.mounted) return;
    await repo.setAssignees(task.id, selected.toList());
    
    // Automatically update visibility based on assignees
    if (selected.length > 1 && task.visibility == TaskVisibility.all) {
      await repo.updateTask(taskId: task.id, visibility: TaskVisibility.tagged);
    } else if (selected.length <= 1 && task.visibility == TaskVisibility.tagged) {
      await repo.updateTask(taskId: task.id, visibility: TaskVisibility.all);
    }
    
    ref.invalidate(taskDetailProvider(task.id));
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
              color: AppColors.mutedText(context),
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
                      : AppColors.mutedText(context),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        if (t.assignees.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Assignees', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              // Only creator or admins can edit assignees.
              if (t.createdBy == SupabaseService.currentUser?.id)
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  onPressed: () => _editAssignees(context, ref, t),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: t.assignees
                .map((a) => Chip(
                      avatar: CircleAvatar(
                        backgroundImage: a.avatarUrl != null
                            ? NetworkImage(a.avatarUrl!)
                            : null,
                        backgroundColor: AppColors.subtleSurface(context),
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
                          ? AppColors.mutedText(context)
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  secondary: IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: AppColors.mutedText(context)),
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
                      fontSize: 11, color: AppColors.mutedText(context)),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AssigneePickerSheet extends StatefulWidget {
  final List<GroupMember> members;
  final Set<String> selected;
  final String creatorId;

  const _AssigneePickerSheet({
    required this.members,
    required this.selected,
    required this.creatorId,
  });

  @override
  State<_AssigneePickerSheet> createState() => _AssigneePickerSheetState();
}

class _AssigneePickerSheetState extends State<_AssigneePickerSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit Assignees',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.members.map((m) {
              final isCreator = m.userId == widget.creatorId;
              final isSelected = _selected.contains(m.userId);
              return FilterChip(
                avatar: CircleAvatar(
                  backgroundImage: m.avatarUrl != null
                      ? NetworkImage(m.avatarUrl!)
                      : null,
                  backgroundColor: AppColors.subtleSurface(context),
                ),
                label: Text(m.displayName ?? 'Unknown'),
                selected: isSelected,
                onSelected: isCreator
                    ? null
                    : (val) {
                        setState(() {
                          if (val) {
                            _selected.add(m.userId);
                          } else {
                            _selected.remove(m.userId);
                          }
                        });
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              widget.selected.clear();
              widget.selected.addAll(_selected);
              Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
