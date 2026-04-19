import 'package:flutter/material.dart';

class TaskBoardScreen extends StatelessWidget {
  const TaskBoardScreen({required this.groupId, super.key});
  final String groupId;

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Task board — Phase 2'));
}
