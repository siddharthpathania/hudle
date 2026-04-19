import 'package:flutter/material.dart';

class AnnouncementsFeedScreen extends StatelessWidget {
  const AnnouncementsFeedScreen({required this.groupId, super.key});
  final String groupId;

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Announcements feed — Phase 3'));
}
