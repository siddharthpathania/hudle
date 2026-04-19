import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tasks_repository.dart';
import 'task_model.dart';

final groupTasksProvider = FutureProvider.family
    .autoDispose<List<Task>, ({String groupId, TaskFilter filter})>(
  (ref, args) =>
      ref.read(tasksRepositoryProvider).fetchGroupTasks(args.groupId, filter: args.filter),
);

final dashboardTasksProvider =
    FutureProvider.autoDispose.family<List<Task>, TaskDateFilter>(
  (ref, dateFilter) => ref
      .read(tasksRepositoryProvider)
      .fetchMyDashboardTasks(dateFilter: dateFilter),
);

final taskDetailProvider =
    FutureProvider.autoDispose.family<Task, String>(
  (ref, id) => ref.read(tasksRepositoryProvider).fetchTask(id),
);

final taskStatusesProvider =
    FutureProvider.autoDispose.family<List<TaskStatus>, String>(
  (ref, groupId) => ref.read(tasksRepositoryProvider).fetchStatuses(groupId),
);
