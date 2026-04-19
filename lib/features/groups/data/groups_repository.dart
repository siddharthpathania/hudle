import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
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
}

final userGroupsProvider = FutureProvider<List<Group>>((ref) {
  return ref.read(groupsRepositoryProvider).fetchUserGroups();
});
