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

    final now = DateTime.now();
    dynamic q = SupabaseService.client
        .from('tasks')
        .select(
          '*, task_assignees!inner(user_id), groups(name), '
          'task_statuses(id, label, color), '
          'task_subtasks(id, is_completed)',
        )
        .eq('task_assignees.user_id', uid);

    if (dateFilter == TaskDateFilter.today) {
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      q = q
          .gte('due_at', start.toIso8601String())
          .lt('due_at', end.toIso8601String());
    } else if (dateFilter == TaskDateFilter.overdue) {
      q = q.lt('due_at', now.toIso8601String());
    } else if (dateFilter == TaskDateFilter.upcoming) {
      q = q.gte('due_at', now.toIso8601String());
    }

    final data = await q.order('due_at', ascending: true) as List;
    return data
        .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
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
}
