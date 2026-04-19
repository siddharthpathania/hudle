import 'package:flutter/material.dart';

class GroupSettingsScreen extends StatelessWidget {
  const GroupSettingsScreen({required this.groupId, super.key});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group settings')),
      body: const Center(child: Text('Coming in Phase 4')),
    );
  }
}
