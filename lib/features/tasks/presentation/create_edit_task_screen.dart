import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/hudle_button.dart';
import '../../../core/widgets/priority_badge.dart';
import '../data/tasks_repository.dart';
import '../domain/task_model.dart';
import '../domain/tasks_provider.dart';

class CreateEditTaskScreen extends ConsumerStatefulWidget {
  const CreateEditTaskScreen({
    required this.groupId,
    this.taskId,
    super.key,
  });
  final String groupId;
  final String? taskId;

  @override
  ConsumerState<CreateEditTaskScreen> createState() =>
      _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends ConsumerState<CreateEditTaskScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  TaskVisibility _visibility = TaskVisibility.all;
  DateTime? _due;
  bool _saving = false;

  bool get _isEdit => widget.taskId != null;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
    );
    if (t == null) return;
    setState(() {
      _due = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await ref.read(tasksRepositoryProvider).createTask(
            CreateTaskInput(
              groupId: widget.groupId,
              title: _title.text.trim(),
              description:
                  _desc.text.trim().isEmpty ? null : _desc.text.trim(),
              priority: _priority,
              dueAt: _due,
              visibility: _visibility,
              // Always include the creator as an assignee so the task appears
              // on the dashboard (which queries by assignee or creator).
              assigneeIds: [SupabaseService.currentUser!.id],
            ),
          );
      ref.invalidate(groupTasksProvider(
          (groupId: widget.groupId, filter: TaskFilter.all)));
      if (nav.canPop()) nav.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit task' : 'New task')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What needs doing?',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            Text('Priority', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final p in TaskPriority.values)
                  ChoiceChip(
                    label: Text(switch (p) {
                      TaskPriority.low => '↓ Low',
                      TaskPriority.medium => '→ Medium',
                      TaskPriority.high => '↑ High',
                      TaskPriority.urgent => '⚡ Urgent',
                    }),
                    selected: _priority == p,
                    onSelected: (_) => setState(() => _priority = p),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today_rounded,
                    color: AppColors.emberOrange),
                title: const Text('Due date'),
                subtitle: Text(
                  _due == null
                      ? 'Not set'
                      : DateFormat.yMMMd().add_jm().format(_due!),
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                trailing: _due == null
                    ? const Icon(Icons.chevron_right_rounded)
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _due = null),
                      ),
                onTap: _pickDue,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.visibility_outlined,
                    color: AppColors.amberGold),
                title: const Text('Visible to everyone'),
                subtitle: Text(
                  _visibility == TaskVisibility.all
                      ? 'All group members can see this task'
                      : 'Only assignees and admins can see this',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                value: _visibility == TaskVisibility.all,
                onChanged: (v) => setState(() => _visibility =
                    v ? TaskVisibility.all : TaskVisibility.tagged),
              ),
            ),
            const SizedBox(height: UI.space32),
            HudleButton(
              label: _isEdit ? 'Save changes' : 'Create task',
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
