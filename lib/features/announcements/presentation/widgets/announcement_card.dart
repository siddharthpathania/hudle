import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/announcements_repository.dart';
import '../../domain/announcement_model.dart';
import '../../domain/announcements_provider.dart';
import 'poll_widget.dart';
import 'reactions_bar.dart';

class AnnouncementCard extends ConsumerWidget {
  const AnnouncementCard({
    required this.announcement,
    super.key,
    this.showGroup = false,
  });

  final Announcement announcement;
  final bool showGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = announcement;
    final time = a.createdAt;
    final timeStr = time == null
        ? ''
        : _relative(time);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.subtleSurface(context),
                  backgroundImage: a.author?.avatarUrl != null
                      ? NetworkImage(a.author!.avatarUrl!)
                      : null,
                  child: a.author?.avatarUrl == null
                      ? Text(
                          (a.author?.displayName ?? '?')
                              .characters
                              .first
                              .toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.author?.displayName ?? 'Unknown',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            timeStr,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.mutedText(context),
                            ),
                          ),
                          if (showGroup && a.groupName != null) ...[
                            Text(' · ',
                                style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: AppColors.mutedText(context))),
                            Text(
                              a.groupName!,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.amberGold,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (a.status == AnnouncementStatus.pending)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.amberGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(UI.radiusFull),
                    ),
                    child: Text(
                      'Pending',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppColors.amberGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (a.author?.id == SupabaseService.currentUser?.id)
                  _AnnouncementMenu(announcement: a),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              a.content,
              style: GoogleFonts.dmSans(fontSize: 14, height: 1.45),
            ),
            if (a.attachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final att in a.attachments)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file_rounded, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          att.fileName,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.hudleTeal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (a.poll != null)
              PollWidget(
                poll: a.poll!,
                onVote: (optId) async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(announcementsRepositoryProvider)
                        .castVote(a.poll!.id, optId);
                    ref.invalidate(groupAnnouncementsProvider(a.groupId));
                  } catch (e) {
                    messenger.showSnackBar(
                        SnackBar(content: Text('Vote failed: $e')));
                  }
                },
              ),
            const SizedBox(height: 12),
            ReactionsBar(
              reactions: a.reactions,
              onReact: (emoji) async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref
                      .read(announcementsRepositoryProvider)
                      .toggleReaction(a.id, emoji);
                  ref.invalidate(groupAnnouncementsProvider(a.groupId));
                } catch (e) {
                  messenger.showSnackBar(
                      SnackBar(content: Text('Reaction failed: $e')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _relative(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat.MMMd().format(d);
  }
}

class _AnnouncementMenu extends ConsumerWidget {
  const _AnnouncementMenu({required this.announcement});
  final Announcement announcement;

  bool get _hasPoll => announcement.poll != null;
  bool get _isPollOnly =>
      _hasPoll && announcement.content.trim() == '📊 Poll';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert,
          size: 20, color: AppColors.mutedText(context)),
      onSelected: (value) => _handle(context, ref, value),
      itemBuilder: (_) => [
        if (_hasPoll && !_isPollOnly)
          const PopupMenuItem(
            value: 'delete_poll',
            child: Text('Delete poll',
                style: TextStyle(color: AppColors.hudleRose)),
          ),
        PopupMenuItem(
          value: 'delete_post',
          child: Text(
            _isPollOnly ? 'Delete poll' : 'Delete post',
            style: const TextStyle(color: AppColors.hudleRose),
          ),
        ),
      ],
    );
  }

  Future<void> _handle(
      BuildContext context, WidgetRef ref, String value) async {
    final repo = ref.read(announcementsRepositoryProvider);
    if (value == 'delete_poll') {
      final ok = await _confirm(
        context,
        title: 'Delete poll',
        body: 'The poll will be removed. The announcement stays.',
      );
      if (ok != true || !context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await repo.deletePoll(announcement.poll!.id);
        ref.invalidate(groupAnnouncementsProvider(announcement.groupId));
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }
    if (value == 'delete_post') {
      final ok = await _confirm(
        context,
        title: _isPollOnly ? 'Delete poll' : 'Delete post',
        body: 'This cannot be undone.',
      );
      if (ok != true || !context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await repo.deleteAnnouncement(announcement.id);
        ref.invalidate(groupAnnouncementsProvider(announcement.groupId));
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.hudleRose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
