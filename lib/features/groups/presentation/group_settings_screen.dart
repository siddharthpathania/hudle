import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../data/groups_repository.dart';
import '../domain/group_member_model.dart';
import '../domain/group_model.dart';

class GroupSettingsScreen extends ConsumerWidget {
  const GroupSettingsScreen({required this.groupId, super.key});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupDetailProvider(groupId));
    final role = ref.watch(myGroupRoleProvider(groupId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Group settings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Members'),
              Tab(text: 'Invites'),
            ],
          ),
          actions: [
            role.maybeWhen(
              data: (r) {
                if (r == null) return const SizedBox.shrink();
                if (r != GroupRole.superAdmin && r != GroupRole.admin) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.fact_check_rounded),
                  tooltip: 'Approval queue',
                  onPressed: () =>
                      context.push('/groups/$groupId/announcements/queue'),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        body: group.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Failed: $e',
                  style: const TextStyle(color: AppColors.hudleRose)),
            ),
          ),
          data: (g) => TabBarView(
            children: [
              _GeneralTab(group: g, role: role.asData?.value),
              _MembersTab(groupId: groupId, myRole: role.asData?.value),
              _InvitesTab(groupId: groupId, myRole: role.asData?.value),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeneralTab extends ConsumerStatefulWidget {
  const _GeneralTab({required this.group, required this.role});
  final Group group;
  final GroupRole? role;

  @override
  ConsumerState<_GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends ConsumerState<_GeneralTab> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late bool _isPublic;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.group.name);
    _desc = TextEditingController(text: widget.group.description ?? '');
    _isPublic = widget.group.isPublic;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  bool get _canEdit =>
      widget.role == GroupRole.superAdmin || widget.role == GroupRole.admin;

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(groupsRepositoryProvider).updateGroup(
            groupId: widget.group.id,
            name: _name.text.trim(),
            description:
                _desc.text.trim().isEmpty ? null : _desc.text.trim(),
            isPublic: _isPublic,
          );
      ref.invalidate(groupDetailProvider(widget.group.id));
      messenger.showSnackBar(const SnackBar(content: Text('Saved')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete group?'),
        content: const Text(
            'This permanently deletes the group, tasks, and announcements.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.hudleRose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await ref.read(groupsRepositoryProvider).deleteGroup(widget.group.id);
      ref.invalidate(userGroupsProvider);
      nav.popUntil((r) => r.isFirst);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: _name,
          enabled: _canEdit,
          decoration: const InputDecoration(labelText: 'Group name'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _desc,
          enabled: _canEdit,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 16),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.public_rounded,
                color: AppColors.hudleTeal),
            title: const Text('Public group'),
            subtitle: Text(
              _isPublic
                  ? 'Anyone can find and request to join'
                  : 'Invite-only',
              style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            value: _isPublic,
            onChanged:
                _canEdit ? (v) => setState(() => _isPublic = v) : null,
          ),
        ),
        const SizedBox(height: UI.space32),
        if (_canEdit)
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save changes'),
          ),
        const SizedBox(height: 12),
        if (widget.role == GroupRole.superAdmin)
          OutlinedButton.icon(
            onPressed: _delete,
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Delete group'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.hudleRose,
              side: const BorderSide(color: AppColors.hudleRose),
            ),
          ),
      ],
    );
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.groupId, required this.myRole});
  final String groupId;
  final GroupRole? myRole;

  bool get _canManage =>
      myRole == GroupRole.superAdmin || myRole == GroupRole.admin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(groupMembersProvider(groupId));

    return members.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: ShimmerListTile(),
        ),
      ),
      error: (e, _) =>
          Center(child: Text('Failed: $e')),
      data: (list) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(groupMembersProvider(groupId)),
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (_, i) => _MemberTile(
            member: list[i],
            groupId: groupId,
            canManage: _canManage,
            isSuperAdmin: myRole == GroupRole.superAdmin,
          ),
        ),
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.member,
    required this.groupId,
    required this.canManage,
    required this.isSuperAdmin,
  });

  final GroupMember member;
  final String groupId;
  final bool canManage;
  final bool isSuperAdmin;

  Color _roleColor() => switch (member.role) {
        GroupRole.superAdmin => AppColors.emberOrange,
        GroupRole.admin => AppColors.amberGold,
        GroupRole.member => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.inkMuted,
          backgroundImage: member.avatarUrl != null
              ? NetworkImage(member.avatarUrl!)
              : null,
          child: member.avatarUrl == null
              ? Text(
                  (member.displayName ?? '?').characters.first.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                )
              : null,
        ),
        title: Text(
          member.displayName ?? 'User',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          member.role.label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: _roleColor(),
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: canManage && member.role != GroupRole.superAdmin
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                itemBuilder: (_) => [
                  if (isSuperAdmin && member.role == GroupRole.member)
                    const PopupMenuItem(
                        value: 'promote', child: Text('Promote to admin')),
                  if (isSuperAdmin && member.role == GroupRole.admin)
                    const PopupMenuItem(
                        value: 'demote', child: Text('Demote to member')),
                  PopupMenuItem(
                    value: member.isBanned ? 'unban' : 'ban',
                    child: Text(member.isBanned ? 'Unban' : 'Ban'),
                  ),
                  const PopupMenuItem(
                      value: 'remove', child: Text('Remove from group')),
                ],
                onSelected: (value) => _handle(context, ref, value),
              )
            : null,
      ),
    );
  }

  Future<void> _handle(
      BuildContext context, WidgetRef ref, String action) async {
    final repo = ref.read(groupsRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (action) {
        case 'promote':
          await repo.updateMemberRole(
              groupId, member.userId, GroupRole.admin);
        case 'demote':
          await repo.updateMemberRole(
              groupId, member.userId, GroupRole.member);
        case 'ban':
          await repo.setBanned(groupId, member.userId, true);
        case 'unban':
          await repo.setBanned(groupId, member.userId, false);
        case 'remove':
          await repo.removeMember(groupId, member.userId);
      }
      ref.invalidate(groupMembersProvider(groupId));
      messenger.showSnackBar(const SnackBar(content: Text('Done')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}

class _InvitesTab extends ConsumerWidget {
  const _InvitesTab({required this.groupId, required this.myRole});
  final String groupId;
  final GroupRole? myRole;

  bool get _canManage =>
      myRole == GroupRole.superAdmin || myRole == GroupRole.admin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = ref.watch(groupInvitesProvider(groupId));

    return Scaffold(
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              onPressed: () => _create(context, ref),
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('New invite'),
            )
          : null,
      body: invites.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No invites yet'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (_, i) {
              final inv = list[i];
              final expired = inv.expiresAt != null &&
                  inv.expiresAt!.isBefore(DateTime.now());
              final exhausted =
                  inv.maxUses != null && inv.useCount >= inv.maxUses!;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.link_rounded,
                      color: AppColors.hudleTeal),
                  title: Text(
                    inv.token,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    [
                      '${inv.useCount}${inv.maxUses != null ? "/${inv.maxUses}" : ""} uses',
                      if (inv.expiresAt != null)
                        'expires ${DateFormat.yMMMd().format(inv.expiresAt!)}',
                      if (expired) 'EXPIRED',
                      if (exhausted) 'EXHAUSTED',
                    ].join(' · '),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: (expired || exhausted)
                          ? AppColors.hudleRose
                          : AppColors.textSecondary,
                    ),
                  ),
                  trailing: _canManage
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: inv.token));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Copied')));
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18),
                              onPressed: () async {
                                await ref
                                    .read(groupsRepositoryProvider)
                                    .revokeInvite(inv.id);
                                ref.invalidate(
                                    groupInvitesProvider(groupId));
                              },
                            ),
                          ],
                        )
                      : IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: inv.token));
                          },
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({int? maxUses, DateTime? expiresAt})?>(
      context: context,
      builder: (ctx) => const _CreateInviteDialog(),
    );
    if (result == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(groupsRepositoryProvider).createInvite(
            groupId,
            maxUses: result.maxUses,
            expiresAt: result.expiresAt,
          );
      ref.invalidate(groupInvitesProvider(groupId));
      messenger.showSnackBar(const SnackBar(content: Text('Invite created')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}

class _CreateInviteDialog extends StatefulWidget {
  const _CreateInviteDialog();
  @override
  State<_CreateInviteDialog> createState() => _CreateInviteDialogState();
}

class _CreateInviteDialogState extends State<_CreateInviteDialog> {
  final _uses = TextEditingController();
  int _days = 0;

  @override
  void dispose() {
    _uses.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New invite link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _uses,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max uses (blank = unlimited)',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _days,
            decoration: const InputDecoration(labelText: 'Expires in'),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Never')),
              DropdownMenuItem(value: 1, child: Text('1 day')),
              DropdownMenuItem(value: 7, child: Text('7 days')),
              DropdownMenuItem(value: 30, child: Text('30 days')),
            ],
            onChanged: (v) => setState(() => _days = v ?? 0),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final max = int.tryParse(_uses.text.trim());
            final expires = _days == 0
                ? null
                : DateTime.now().add(Duration(days: _days));
            Navigator.pop<({int? maxUses, DateTime? expiresAt})>(
                context, (maxUses: max, expiresAt: expires));
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
