import '../../../core/widgets/priority_badge.dart';

enum TaskVisibility { all, tagged }

extension TaskVisibilityX on TaskVisibility {
  String get wire => name;
  static TaskVisibility fromWire(String? v) =>
      TaskVisibility.values.firstWhere((e) => e.wire == v,
          orElse: () => TaskVisibility.all);
}

enum TaskFilter { all, mine, createdByMe }

enum TaskDateFilter { all, today, upcoming, overdue }

class TaskStatus {
  TaskStatus({
    required this.id,
    required this.label,
    required this.color,
    this.orderIndex = 0,
  });

  final String id;
  final String label;
  final String color;
  final int orderIndex;

  factory TaskStatus.fromJson(Map<String, dynamic> json) => TaskStatus(
        id: json['id'] as String,
        label: json['label'] as String,
        color: json['color'] as String? ?? '#64748B',
        orderIndex: (json['order_index'] as int?) ?? 0,
      );
}

class TaskAssignee {
  TaskAssignee({
    required this.userId,
    this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String? displayName;
  final String? avatarUrl;

  factory TaskAssignee.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map?;
    return TaskAssignee(
      userId: json['user_id'] as String,
      displayName: user?['display_name'] as String?,
      avatarUrl: user?['avatar_url'] as String?,
    );
  }
}

/// A lightweight model for displaying group members in the assignee picker.
class GroupMember {
  GroupMember({
    required this.userId,
    required this.role,
    this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String role;
  final String? displayName;
  final String? avatarUrl;

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map?;
    return GroupMember(
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      displayName: user?['display_name'] as String?,
      avatarUrl: user?['avatar_url'] as String?,
    );
  }
}

class Subtask {
  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.orderIndex = 0,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final int orderIndex;

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: (json['is_completed'] as bool?) ?? false,
        orderIndex: (json['order_index'] as int?) ?? 0,
      );
}

class TaskAttachment {
  TaskAttachment({
    required this.id,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    this.fileSize,
  });

  final String id;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final int? fileSize;

  factory TaskAttachment.fromJson(Map<String, dynamic> json) => TaskAttachment(
        id: json['id'] as String,
        fileUrl: json['file_url'] as String,
        fileName: json['file_name'] as String,
        fileType: json['file_type'] as String,
        fileSize: json['file_size'] as int?,
      );
}

class Task {
  Task({
    required this.id,
    required this.groupId,
    required this.title,
    this.description,
    this.createdBy,
    this.status,
    this.priority = TaskPriority.medium,
    this.dueAt,
    this.visibility = TaskVisibility.all,
    this.isRecurring = false,
    this.recurrenceRule,
    this.createdAt,
    this.assignees = const [],
    this.subtasks = const [],
    this.attachments = const [],
    this.groupName,
  });

  final String id;
  final String groupId;
  final String title;
  final String? description;
  final String? createdBy;
  final TaskStatus? status;
  final TaskPriority priority;
  final DateTime? dueAt;
  final TaskVisibility visibility;
  final bool isRecurring;
  final String? recurrenceRule;
  final DateTime? createdAt;
  final List<TaskAssignee> assignees;
  final List<Subtask> subtasks;
  final List<TaskAttachment> attachments;
  final String? groupName;

  bool get isOverdue =>
      dueAt != null && dueAt!.isBefore(DateTime.now()) && !isDone;
  bool get isDone =>
      status?.label.toLowerCase() == 'done' ||
      status?.label.toLowerCase() == 'completed';

  int get completedSubtaskCount =>
      subtasks.where((s) => s.isCompleted).length;

  factory Task.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['task_statuses'];
    final assigneesRaw = json['task_assignees'] as List?;
    final subsRaw = json['task_subtasks'] as List?;
    final attRaw = json['task_attachments'] as List?;
    final groupRaw = json['groups'] as Map?;

    return Task(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String?,
      status: statusRaw is Map
          ? TaskStatus.fromJson(Map<String, dynamic>.from(statusRaw))
          : null,
      priority: TaskPriorityX.fromWire(json['priority'] as String?),
      dueAt: json['due_at'] != null
          ? DateTime.tryParse(json['due_at'] as String)
          : null,
      visibility: TaskVisibilityX.fromWire(json['visibility'] as String?),
      isRecurring: (json['is_recurring'] as bool?) ?? false,
      recurrenceRule: json['recurrence_rule'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      assignees: (assigneesRaw ?? [])
          .map((e) => TaskAssignee.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subtasks: (subsRaw ?? [])
          .map((e) => Subtask.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      attachments: (attRaw ?? [])
          .map((e) => TaskAttachment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      groupName: groupRaw?['name'] as String?,
    );
  }
}

class CreateTaskInput {
  CreateTaskInput({
    required this.groupId,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.dueAt,
    this.visibility = TaskVisibility.all,
    this.assigneeIds = const [],
    this.isRecurring = false,
    this.recurrenceRule,
    this.statusId,
  });

  final String groupId;
  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? dueAt;
  final TaskVisibility visibility;
  final List<String> assigneeIds;
  final bool isRecurring;
  final String? recurrenceRule;
  final String? statusId;

  Map<String, dynamic> toJson() => {
        'group_id': groupId,
        'title': title,
        if (description != null) 'description': description,
        'priority': priority.wire,
        if (dueAt != null) 'due_at': dueAt!.toIso8601String(),
        'visibility': visibility.wire,
        'is_recurring': isRecurring,
        if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
        if (statusId != null) 'status_id': statusId,
      };
}
