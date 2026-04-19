import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../data/announcements_repository.dart';
import '../domain/announcement_model.dart';
import '../domain/announcements_provider.dart';
import 'widgets/announcement_card.dart';

class ApprovalQueueScreen extends ConsumerWidget {
  const ApprovalQueueScreen({required this.groupId, super.key});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingAnnouncementsProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Approval queue')),
      body: pending.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: UI.space8),
            child: ShimmerBox(height: 160, radius: UI.radiusLg),
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
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 64, color: AppColors.hudleTeal),
                    SizedBox(height: 12),
                    Text('No pending announcements'),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(pendingAnnouncementsProvider(groupId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: UI.space8),
              itemBuilder: (_, i) => _PendingCard(
                announcement: list[i],
                onApprove: () => _approve(context, ref, list[i]),
                onReject: () => _reject(context, ref, list[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _approve(
      BuildContext context, WidgetRef ref, Announcement a) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(announcementsRepositoryProvider).approve(a.id);
      ref.invalidate(pendingAnnouncementsProvider(groupId));
      ref.invalidate(groupAnnouncementsProvider(groupId));
      messenger.showSnackBar(const SnackBar(content: Text('Approved')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _reject(
      BuildContext context, WidgetRef ref, Announcement a) async {
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Reject announcement'),
          content: TextField(
            controller: c,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'Let them know why',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.hudleRose),
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    if (note == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(announcementsRepositoryProvider)
          .reject(a.id, note: note.isEmpty ? null : note);
      ref.invalidate(pendingAnnouncementsProvider(groupId));
      messenger.showSnackBar(const SnackBar(content: Text('Rejected')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.announcement,
    required this.onApprove,
    required this.onReject,
  });

  final Announcement announcement;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnnouncementCard(announcement: announcement),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.hudleRose,
                  side: const BorderSide(color: AppColors.hudleRose),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  'Approve',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
