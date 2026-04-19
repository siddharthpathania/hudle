import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../tasks/presentation/task_board_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({required this.groupId, super.key});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Group'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => context.push('/groups/$groupId/settings'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tasks'),
              Tab(text: 'Announcements'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TaskBoardScreen(groupId: groupId),
            const Center(child: Text('Announcements — coming in Phase 3')),
          ],
        ),
      ),
    );
  }
}
