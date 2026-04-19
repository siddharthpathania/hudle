import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../domain/task_model.dart';
import '../domain/tasks_provider.dart';
import 'widgets/task_card.dart';

class TaskBoardScreen extends ConsumerStatefulWidget {
  const TaskBoardScreen({required this.groupId, super.key});
  final String groupId;

  @override
  ConsumerState<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends ConsumerState<TaskBoardScreen> {
  TaskFilter _filter = TaskFilter.all;

  @override
  Widget build(BuildContext context) {
    final args = (groupId: widget.groupId, filter: _filter);
    final tasks = ref.watch(groupTasksProvider(args));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/groups/${widget.groupId}/tasks/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add task'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in TaskFilter.values) ...[
                    ChoiceChip(
                      label: Text(switch (f) {
                        TaskFilter.all => 'All',
                        TaskFilter.mine => 'Mine',
                        TaskFilter.createdByMe => 'Created by me',
                      }),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                    const SizedBox(width: UI.space8),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: tasks.when(
              loading: () => ListView.builder(
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: ShimmerBox(height: 90, radius: UI.radiusLg),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Failed to load: $e',
                      style: const TextStyle(color: AppColors.hudleRose)),
                ),
              ),
              data: (list) {
                if (list.isEmpty) return const _EmptyTasks();
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(groupTasksProvider(args)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: UI.space8),
                    itemBuilder: (_, i) => TaskCard(task: list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt_rounded, size: 72, color: AppColors.hudleTeal),
            SizedBox(height: 12),
            Text('No tasks yet', style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            Text('Tap + to add one', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
