import 'package:flutter/material.dart';

class CreateEditTaskScreen extends StatelessWidget {
  const CreateEditTaskScreen({required this.groupId, this.taskId, super.key});
  final String groupId;
  final String? taskId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(taskId == null ? 'New task' : 'Edit task')),
      body: const Center(child: Text('Coming in Phase 2')),
    );
  }
}
