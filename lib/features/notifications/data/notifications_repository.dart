import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../domain/notification_model.dart';

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((_) => NotificationsRepository());

class NotificationsRepository {
  Future<List<AppNotification>> fetchAll({int limit = 50}) async {
    final uid = SupabaseService.currentUser?.id;
    if (uid == null) return [];
    final data = await SupabaseService.client
        .from('notifications')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(limit) as List;
    return data
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<int> unreadCount() async {
    final uid = SupabaseService.currentUser?.id;
    if (uid == null) return 0;
    final data = await SupabaseService.client
        .from('notifications')
        .select('id')
        .eq('user_id', uid)
        .eq('is_read', false) as List;
    return data.length;
  }

  Future<void> markRead(String id) async {
    await SupabaseService.client
        .from('notifications')
        .update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllRead() async {
    final uid = SupabaseService.currentUser?.id;
    if (uid == null) return;
    await SupabaseService.client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', uid)
        .eq('is_read', false);
  }
}
