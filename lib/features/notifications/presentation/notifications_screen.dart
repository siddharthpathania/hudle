import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../data/notifications_repository.dart';
import '../domain/notification_model.dart';
import '../domain/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          async.maybeWhen(
            data: (list) {
              final any = list.any((n) => !n.isRead);
              if (!any) return const SizedBox.shrink();
              return TextButton(
                onPressed: () async {
                  await ref
                      .read(notificationsRepositoryProvider)
                      .markAllRead();
                  ref.invalidate(notificationsProvider);
                  ref.invalidate(unreadCountProvider);
                },
                child: const Text('Mark all read'),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: 6,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: ShimmerListTile(),
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed: $e',
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
                    Icon(Icons.notifications_none_rounded,
                        size: 64, color: AppColors.hudleTeal),
                    SizedBox(height: 12),
                    Text('No notifications yet'),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) =>
                  _NotificationTile(notification: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});
  final AppNotification notification;

  IconData _iconFor(String type) => switch (type) {
        'task_assigned' => Icons.assignment_ind_rounded,
        'due_reminder' => Icons.schedule_rounded,
        'announcement' => Icons.campaign_rounded,
        'announcement_approved' => Icons.check_circle_rounded,
        'announcement_rejected' => Icons.block_rounded,
        'group_invite' => Icons.groups_rounded,
        _ => Icons.notifications_rounded,
      };

  Color _colorFor(String type) => switch (type) {
        'task_assigned' => AppColors.emberOrange,
        'due_reminder' => AppColors.hudleRose,
        'announcement' => AppColors.amberGold,
        'announcement_approved' => AppColors.hudleTeal,
        'announcement_rejected' => AppColors.hudleRose,
        'group_invite' => AppColors.hudleTeal,
        _ => AppColors.textSecondary,
      };

  void _navigate(BuildContext context) {
    final type = notification.type;
    final eid = notification.entityId;
    final gid = notification.groupId;
    if (type == 'task_assigned' || type == 'due_reminder') {
      if (gid != null && eid != null) {
        context.push('/groups/$gid/tasks/$eid');
      }
      return;
    }
    if (type.startsWith('announcement') && gid != null) {
      context.push('/groups/$gid');
      return;
    }
    if (type == 'group_invite' && gid != null) {
      context.push('/groups/$gid');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = notification;
    return Card(
      color: n.isRead
          ? null
          : AppColors.emberOrange.withValues(alpha: 0.08),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _colorFor(n.type).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(UI.radiusSm),
          ),
          child: Icon(_iconFor(n.type), color: _colorFor(n.type), size: 18),
        ),
        title: Text(
          n.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (n.body != null)
              Text(
                n.body!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            if (n.createdAt != null) ...[
              const SizedBox(height: 2),
              Text(
                DateFormat.yMMMd().add_jm().format(n.createdAt!),
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        trailing: n.isRead
            ? null
            : const _Dot(),
        onTap: () async {
          if (!n.isRead) {
            await ref
                .read(notificationsRepositoryProvider)
                .markRead(n.id);
            ref.invalidate(notificationsProvider);
            ref.invalidate(unreadCountProvider);
          }
          if (context.mounted) _navigate(context);
        },
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.emberOrange,
        shape: BoxShape.circle,
      ),
    );
  }
}
