import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../domain/announcements_provider.dart';
import 'widgets/announcement_card.dart';

class AnnouncementsFeedScreen extends ConsumerWidget {
  const AnnouncementsFeedScreen({required this.groupId, super.key});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(groupAnnouncementsProvider(groupId));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/groups/$groupId/announcements/new'),
        icon: const Icon(Icons.campaign_rounded),
        label: const Text('Post'),
      ),
      body: feed.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: UI.space8),
            child: ShimmerBox(height: 140, radius: UI.radiusLg),
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
          if (list.isEmpty) return const _EmptyFeed();
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(groupAnnouncementsProvider(groupId)),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: UI.space8),
              itemBuilder: (_, i) => AnnouncementCard(announcement: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined,
                size: 64, color: AppColors.hudleTeal),
            SizedBox(height: 12),
            Text('No announcements yet'),
            SizedBox(height: 4),
            Text('Be the first to post one',
                style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
