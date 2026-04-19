import 'package:flutter/material.dart';

class ApprovalQueueScreen extends StatelessWidget {
  const ApprovalQueueScreen({required this.groupId, super.key});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approval queue')),
      body: const Center(child: Text('Coming in Phase 3')),
    );
  }
}
