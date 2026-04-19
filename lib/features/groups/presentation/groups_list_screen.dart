import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/widgets/hudle_button.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../data/groups_repository.dart';
import '../domain/group_model.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final asyncGroups = ref.watch(userGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {/* TODO */},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search groups',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: asyncGroups.when(
              loading: () => ListView.builder(
                itemCount: 6,
                itemBuilder: (_, __) => const ShimmerListTile(),
              ),
              error: (e, _) => _ErrorState(
                error: e.toString(),
                onRetry: () => ref.invalidate(userGroupsProvider),
              ),
              data: (groups) {
                final filtered = _query.isEmpty
                    ? groups
                    : groups
                        .where((g) => g.name.toLowerCase().contains(_query))
                        .toList();
                if (filtered.isEmpty) {
                  return _EmptyState(onCreate: () => _showAddSheet(context));
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(userGroupsProvider),
                  child: ListView.separated(
                    padding: UI.pagePadding,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _GroupCard(group: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.inkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(UI.radiusXl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.group_add_rounded,
                  color: AppColors.emberOrange),
              title: const Text('Create Group'),
              subtitle: Text('Start a new team space',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded,
                  color: AppColors.amberGold),
              title: const Text('Join via Invite Link'),
              subtitle: Text('Paste a code shared with you',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showJoinDialog(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final name = TextEditingController();
    final desc = TextEditingController();
    var isPublic = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Create group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: desc,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
              ),
              SwitchListTile(
                value: isPublic,
                onChanged: (v) => setStateDialog(() => isPublic = v),
                contentPadding: EdgeInsets.zero,
                title: const Text('Public'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                if (name.text.trim().isEmpty) return;
                try {
                  await ref.read(groupsRepositoryProvider).createGroup(
                        name: name.text.trim(),
                        description: desc.text.trim().isEmpty
                            ? null
                            : desc.text.trim(),
                        isPublic: isPublic,
                      );
                  ref.invalidate(userGroupsProvider);
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    final token = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join group'),
        content: TextField(
          controller: token,
          decoration: const InputDecoration(labelText: 'Invite code'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                await ref
                    .read(groupsRepositoryProvider)
                    .joinViaInvite(token.text.trim());
                ref.invalidate(userGroupsProvider);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Invalid invite: $e')),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.emberSoft,
          backgroundImage: group.avatarUrl != null
              ? NetworkImage(group.avatarUrl!)
              : null,
          child: group.avatarUrl == null
              ? Text(
                  group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: AppColors.emberDeep,
                  ),
                )
              : null,
        ),
        title: Text(
          group.name,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          '${group.memberCount ?? 0} members'
          '${group.createdAt != null ? ' · ${timeago.format(group.createdAt!)}' : ''}',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push('/groups/${group.id}'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_2_rounded,
                size: 80, color: AppColors.emberOrange),
            const SizedBox(height: 16),
            Text(
              "You don't have any groups yet",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create one or join via invite to get started',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            HudleButton(
              label: 'Create a Group',
              fullWidth: false,
              onPressed: onCreate,
              icon: Icons.add_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.hudleRose),
            const SizedBox(height: 12),
            Text('Couldn\'t load groups',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(error,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
