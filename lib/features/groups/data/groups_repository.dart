import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../domain/group_member_model.dart';
import '../domain/group_model.dart';

final groupsRepositoryProvider =
    Provider<GroupsRepository>((_) => GroupsRepository());

class GroupsRepository {
  Future<List<Group>> fetchUserGroups() async {
    final uid = SupabaseService.currentUser?.id;
    if (uid == null) return [];

    final data = await SupabaseService.client
        .from('group_members')
        .select('groups(*, group_members(count))')
        .eq('user_id', uid)
        .eq('is_banned', false);

    return (data as List)
        .map((e) => Group.fromJson(
              Map<String, dynamic>.from(e['groups'] as Map),
            ))
        .toList();
  }

  Future<Group> createGroup({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    final uid = SupabaseService.currentUser!.id;
    final row = await SupabaseService.client
        .from('groups')
        .insert({
          'name': name,
          'description': description,
          'is_public': isPublic,
          'created_by': uid,
        })
        .select()
        .single();

    await SupabaseService.client.from('group_members').insert({
      'group_id': row['id'],
      'user_id': uid,
      'role': 'super_admin',
    });

    return Group.fromJson(row);
  }

  Future<void> joinViaInvite(String token) async {
    final uid = SupabaseService.currentUser!.id;
    final invite = await SupabaseService.client
        .from('group_invites')
        .select()
        .eq('token', token)
        .single();

    await SupabaseService.client.from('group_members').insert({
      'group_id': invite['group_id'],
      'user_id': uid,
      'role': 'member',
    });

    await SupabaseService.client.from('group_invites').update({
      'use_count': ((invite['use_count'] as int?) ?? 0) + 1,
    }).eq('id', invite['id'] as Object);
  }

  Future<Group> fetchGroup(String groupId) async {
    final data = await SupabaseService.client
        .from('groups')
        .select('*, group_members(count)')
        .eq('id', groupId)
        .single();
    return Group.fromJson(Map<String, dynamic>.from(data));
  }

  Future<GroupRole?> fetchMyRole(String groupId) async {
    final uid = SupabaseService.currentUser?.id;
    if (uid == null) return null;
    final row = await SupabaseService.client
        .from('group_members')
        .select('role')
        .eq('group_id', groupId)
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return null;
    return GroupRoleX.fromWire(row['role'] as String?);
  }

  Future<List<GroupMember>> fetchMembers(String groupId) async {
    final data = await SupabaseService.client
        .from('group_members')
        .select('user_id, role, is_banned, joined_at, '
            'users(display_name, avatar_url)')
        .eq('group_id', groupId)
        .order('role') as List;
    return data
        .map((e) =>
            GroupMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> updateMemberRole(
      String groupId, String userId, GroupRole role) async {
    await SupabaseService.client
        .from('group_members')
        .update({'role': role.wire})
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  Future<void> setBanned(
      String groupId, String userId, bool banned) async {
    await SupabaseService.client
        .from('group_members')
        .update({'is_banned': banned})
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  Future<void> removeMember(String groupId, String userId) async {
    await SupabaseService.client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  Future<List<GroupInvite>> fetchInvites(String groupId) async {
    final data = await SupabaseService.client
        .from('group_invites')
        .select()
        .eq('group_id', groupId)
        .order('created_at', ascending: false) as List;
    return data
        .map((e) => GroupInvite.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<GroupInvite> createInvite(
    String groupId, {
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    final uid = SupabaseService.currentUser!.id;
    final row = await SupabaseService.client
        .from('group_invites')
        .insert({
          'group_id': groupId,
          'created_by': uid,
          if (maxUses != null) 'max_uses': maxUses,
          if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
        })
        .select()
        .single();
    return GroupInvite.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> revokeInvite(String inviteId) async {
    await SupabaseService.client
        .from('group_invites')
        .delete()
        .eq('id', inviteId);
  }

  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (description != null) payload['description'] = description;
    if (isPublic != null) payload['is_public'] = isPublic;
    if (payload.isEmpty) return;
    await SupabaseService.client
        .from('groups')
        .update(payload)
        .eq('id', groupId);
  }

  Future<void> deleteGroup(String groupId) async {
    await SupabaseService.client.from('groups').delete().eq('id', groupId);
  }
}

final groupDetailProvider =
    FutureProvider.autoDispose.family<Group, String>(
  (ref, id) => ref.read(groupsRepositoryProvider).fetchGroup(id),
);

final groupMembersProvider =
    FutureProvider.autoDispose.family<List<GroupMember>, String>(
  (ref, id) => ref.read(groupsRepositoryProvider).fetchMembers(id),
);

final groupInvitesProvider =
    FutureProvider.autoDispose.family<List<GroupInvite>, String>(
  (ref, id) => ref.read(groupsRepositoryProvider).fetchInvites(id),
);

final myGroupRoleProvider =
    FutureProvider.autoDispose.family<GroupRole?, String>(
  (ref, id) => ref.read(groupsRepositoryProvider).fetchMyRole(id),
);

final userGroupsProvider = FutureProvider<List<Group>>((ref) {
  return ref.read(groupsRepositoryProvider).fetchUserGroups();
});
