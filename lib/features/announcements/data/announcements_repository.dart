import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../domain/announcement_model.dart';

final announcementsRepositoryProvider =
    Provider<AnnouncementsRepository>((_) => AnnouncementsRepository());

class AnnouncementsRepository {
  static const _select =
      '*, users!announcements_posted_by_fkey(id, display_name, avatar_url), '
      'announcement_attachments(id, file_url, file_name, file_type), '
      'announcement_reactions(emoji, user_id), '
      'polls(id, question, is_closed, '
      '     poll_options(id, option_text, order_index), '
      '     poll_votes(option_id, user_id)), '
      'groups(name)';

  Future<List<Announcement>> fetchGroupFeed(
    String groupId, {
    AnnouncementStatus status = AnnouncementStatus.approved,
  }) async {
    final uid = SupabaseService.currentUser?.id;
    final data = await SupabaseService.client
        .from('announcements')
        .select(_select)
        .eq('group_id', groupId)
        .eq('status', status.wire)
        .order('created_at', ascending: false) as List;

    return data
        .map((e) => Announcement.fromJson(
              Map<String, dynamic>.from(e as Map),
              currentUserId: uid,
            ))
        .toList();
  }

  Future<List<Announcement>> fetchPendingForGroup(String groupId) async {
    final uid = SupabaseService.currentUser?.id;
    final data = await SupabaseService.client
        .from('announcements')
        .select(_select)
        .eq('group_id', groupId)
        .eq('status', AnnouncementStatus.pending.wire)
        .order('created_at', ascending: true) as List;
    return data
        .map((e) => Announcement.fromJson(
              Map<String, dynamic>.from(e as Map),
              currentUserId: uid,
            ))
        .toList();
  }

  Future<Announcement> createAnnouncement(CreateAnnouncementInput input) async {
    final uid = SupabaseService.currentUser!.id;
    final roleRow = await SupabaseService.client
        .from('group_members')
        .select('role')
        .eq('group_id', input.groupId)
        .eq('user_id', uid)
        .maybeSingle();
    final role = (roleRow?['role'] as String?) ?? 'member';
    final autoApprove = role == 'super_admin' || role == 'admin';

    final row = await SupabaseService.client
        .from('announcements')
        .insert({
          'group_id': input.groupId,
          'posted_by': uid,
          'content': (input.content?.trim().isEmpty ?? true) ? '📊 Poll' : input.content,
          'status': autoApprove ? 'approved' : 'pending',
          if (autoApprove) 'approved_by': uid,
          if (autoApprove) 'approved_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    if (input.hasPoll) {
      final pollRow = await SupabaseService.client
          .from('polls')
          .insert({
            'announcement_id': row['id'],
            'question': input.pollQuestion,
            'allow_multiple': input.allowMultiple,
          })
          .select()
          .single();

      final opts = input.pollOptions
          .where((o) => o.trim().isNotEmpty)
          .toList(growable: false);
      await SupabaseService.client.from('poll_options').insert([
        for (var i = 0; i < opts.length; i++)
          {
            'poll_id': pollRow['id'],
            'option_text': opts[i].trim(),
            'order_index': i,
          },
      ]);
    }

    return fetchOne(row['id'] as String);
  }

  Future<Announcement> fetchOne(String id) async {
    final uid = SupabaseService.currentUser?.id;
    final data = await SupabaseService.client
        .from('announcements')
        .select(_select)
        .eq('id', id)
        .single();
    return Announcement.fromJson(Map<String, dynamic>.from(data),
        currentUserId: uid);
  }

  Future<void> approve(String announcementId) async {
    final uid = SupabaseService.currentUser!.id;
    await SupabaseService.client.from('announcements').update({
      'status': 'approved',
      'approved_by': uid,
      'approved_at': DateTime.now().toIso8601String(),
      'reject_note': null,
    }).eq('id', announcementId);
  }

  Future<void> reject(String announcementId, {String? note}) async {
    await SupabaseService.client.from('announcements').update({
      'status': 'rejected',
      'reject_note': note,
    }).eq('id', announcementId);
  }

  Future<void> deleteAnnouncement(String id) async {
    final rows = await SupabaseService.client
        .from('announcements')
        .delete()
        .eq('id', id)
        .select('id') as List;
    if (rows.isEmpty) {
      throw Exception(
          "Couldn't delete: you may not have permission, or it's already gone.");
    }
  }

  Future<void> deletePoll(String pollId) async {
    final rows = await SupabaseService.client
        .from('polls')
        .delete()
        .eq('id', pollId)
        .select('id') as List;
    if (rows.isEmpty) {
      throw Exception(
          "Couldn't delete poll: you may not have permission, or it's already gone.");
    }
  }

  Future<void> toggleReaction(String announcementId, String emoji) async {
    final uid = SupabaseService.currentUser!.id;
    final existing = await SupabaseService.client
        .from('announcement_reactions')
        .select('id, emoji')
        .eq('announcement_id', announcementId)
        .eq('user_id', uid)
        .maybeSingle();

    if (existing == null) {
      await SupabaseService.client.from('announcement_reactions').insert({
        'announcement_id': announcementId,
        'user_id': uid,
        'emoji': emoji,
      });
      return;
    }
    if (existing['emoji'] == emoji) {
      await SupabaseService.client
          .from('announcement_reactions')
          .delete()
          .eq('id', existing['id'] as String);
    } else {
      await SupabaseService.client
          .from('announcement_reactions')
          .update({'emoji': emoji})
          .eq('id', existing['id'] as String);
    }
  }

  Future<void> castVote(
    String pollId,
    String optionId, {
    required bool allowMultiple,
  }) async {
    final uid = SupabaseService.currentUser!.id;

    if (!allowMultiple) {
      await SupabaseService.client
          .from('poll_votes')
          .delete()
          .eq('poll_id', pollId)
          .eq('user_id', uid);
      await SupabaseService.client.from('poll_votes').insert({
        'poll_id': pollId,
        'option_id': optionId,
        'user_id': uid,
      });
      return;
    }

    final existing = await SupabaseService.client
        .from('poll_votes')
        .select('id')
        .eq('poll_id', pollId)
        .eq('user_id', uid)
        .eq('option_id', optionId)
        .maybeSingle();
    if (existing != null) {
      await SupabaseService.client
          .from('poll_votes')
          .delete()
          .eq('id', existing['id'] as String);
    } else {
      await SupabaseService.client.from('poll_votes').insert({
        'poll_id': pollId,
        'option_id': optionId,
        'user_id': uid,
      });
    }
  }
}
