import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/priority_badge.dart';
import '../domain/task_model.dart';

final tasksRepositoryProvider =
    Provider<TasksRepository>((_) => TasksRepository());

class TasksRepository {
  Future<List<Task>> fetchGroupTasks(
    String groupId, {
    TaskFilter filter = TaskFilter.all,
  }) async {
    final uid = SupabaseService.currentUser?.id;
    final builder = SupabaseService.client
        .from('tasks')
        .select(
          '*, task_assignees(user_id, users(display_name, avatar_url)), '
          'task_statuses(id, label, color, order_index), '
          'task_subtasks(id, title, is_completed, order_index)',
        )
        .eq('group_id', groupId);

    dynamic q = builder;
    if (filter == TaskFilter.mine && uid != null) {
      q = q.eq('task_assignees.user_id', uid);
    } else if (filter == TaskFilter.createdByMe && uid != null) {
      q = q.eq('created_by', uid);
    }

    final data = await q.order('due_at', ascending: true) as List;
    return data
        .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Task>> fetchMyDashboardTasks({
    TaskDateFilter dateFilter = TaskDateFilter.all,
  }) async {
    final uid = SupabaseService.currentUser?.id;
    if (uid == null) return [];

    // Use UTC so Supabase (which stores timestamps in UTC) comparisons are exact.
    final now = DateTime.now().toUtc();
    final todayStart = DateTime.utc(now.year, now.month, now.day);
    final todayEnd   = todayStart.add(const Duration(days: 1));

    // Applies the chosen date filter to any PostgREST query builder.
    dynamic applyDateFilter(dynamic q) {
      if (dateFilter == TaskDateFilter.today) {
        return q
            .gte('due_at', todayStart.toIso8601String())
            .lt('due_at',  todayEnd.toIso8601String());
      } else if (dateFilter == TaskDateFilter.overdue) {
        return q.lt('due_at', now.toIso8601String());
      } else if (dateFilter == TaskDateFilter.upcoming) {
        return q.gte('due_at', now.toIso8601String());
      }
      return q;
    }

    const selectCols =
        '*, groups(name), '
        'task_statuses(id, label, color), '
        'task_subtasks(id, is_completed)';

    // Query A — tasks where I am an explicit assignee (INNER JOIN keeps only
    // rows that have a matching task_assignees entry for this user).
    final assignedQ = applyDateFilter(
      SupabaseService.client
          .from('tasks')
          .select('$selectCols, task_assignees!inner(user_id)')
          .eq('task_assignees.user_id', uid),
    );

    // Query B — tasks I created (creator may never have been added as an
    // assignee, especially when tasks are created without picking assignees).
    final createdQ = applyDateFilter(
      SupabaseService.client
          .from('tasks')
          .select('$selectCols, task_assignees(user_id)')
          .eq('created_by', uid),
    );

    // Run both in parallel, then merge and deduplicate by task id.
    final results = await Future.wait([
      assignedQ.order('due_at', ascending: true) as Future<List<dynamic>>,
      createdQ.order('due_at', ascending: true) as Future<List<dynamic>>,
    ]);

    final seen   = <String>{};
    final merged = <Task>[];
    for (final row in [...results[0], ...results[1]]) {
      final t = Task.fromJson(Map<String, dynamic>.from(row as Map));
      if (seen.add(t.id)) merged.add(t);
    }
    // Re-sort after merge since we interleaved two ordered lists.
    merged.sort((a, b) {
      if (a.dueAt == null && b.dueAt == null) return 0;
      if (a.dueAt == null) return 1;
      if (b.dueAt == null) return -1;
      return a.dueAt!.compareTo(b.dueAt!);
    });
    return merged;
  }

  Future<Task> fetchTask(String taskId) async {
    final data = await SupabaseService.client
        .from('tasks')
        .select(
          '*, task_assignees(user_id, users(display_name, avatar_url)), '
          'task_statuses(id, label, color, order_index), '
          'task_subtasks(id, title, is_completed, order_index), '
          'task_attachments(id, file_url, file_name, file_type, file_size), '
          'groups(name)',
        )
        .eq('id', taskId)
        .single();
    return Task.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Task> createTask(CreateTaskInput input) async {
    final uid = SupabaseService.currentUser!.id;
    final row = await SupabaseService.client
        .from('tasks')
        .insert({...input.toJson(), 'created_by': uid})
        .select()
        .single();

    if (input.assigneeIds.isNotEmpty) {
      await SupabaseService.client.from('task_assignees').insert(
            input.assigneeIds
                .map((id) => {'task_id': row['id'], 'user_id': id})
                .toList(),
          );
    }
    return fetchTask(row['id'] as String);
  }

  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueAt,
    TaskVisibility? visibility,
    String? statusId,
  }) async {
    final payload = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (title != null) payload['title'] = title;
    if (description != null) payload['description'] = description;
    if (priority != null) payload['priority'] = priority.wire;
    if (dueAt != null) payload['due_at'] = dueAt.toIso8601String();
    if (visibility != null) payload['visibility'] = visibility.wire;
    if (statusId != null) payload['status_id'] = statusId;

    await SupabaseService.client.from('tasks').update(payload).eq('id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    await SupabaseService.client.from('tasks').delete().eq('id', taskId);
  }

  Future<void> addSubtask(String taskId, String title, int orderIndex) async {
    await SupabaseService.client.from('task_subtasks').insert({
      'task_id': taskId,
      'title': title,
      'order_index': orderIndex,
    });
  }

  Future<void> toggleSubtask(String subtaskId, bool isCompleted) async {
    await SupabaseService.client
        .from('task_subtasks')
        .update({'is_completed': isCompleted}).eq('id', subtaskId);
  }

  Future<void> deleteSubtask(String subtaskId) async {
    await SupabaseService.client
        .from('task_subtasks')
        .delete()
        .eq('id', subtaskId);
  }

  Future<void> setAssignees(String taskId, List<String> userIds) async {
    await SupabaseService.client
        .from('task_assignees')
        .delete()
        .eq('task_id', taskId);
    if (userIds.isEmpty) return;
    await SupabaseService.client.from('task_assignees').insert(
          userIds.map((u) => {'task_id': taskId, 'user_id': u}).toList(),
        );
  }

  Future<List<TaskStatus>> fetchStatuses(String groupId) async {
    final data = await SupabaseService.client
        .from('task_statuses')
        .select()
        .eq('group_id', groupId)
        .order('order_index') as List;
    return data
        .map((e) => TaskStatus.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Returns all active (non-banned) members of a group so the UI can
  /// display an assignee picker.
  Future<List<GroupMember>> fetchGroupMembers(String groupId) async {
    final data = await SupabaseService.client
        .from('group_members')
        .select('user_id, role, users(id, display_name, avatar_url)')
        .eq('group_id', groupId)
        .eq('is_banned', false) as List;
    return data
        .map((e) => GroupMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
