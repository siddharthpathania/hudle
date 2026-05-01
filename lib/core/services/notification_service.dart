import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../router/app_router.dart';
import 'supabase_service.dart';

class NotificationService {
  NotificationService._();

  static Future<void> init() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) {
        await _persistToken(token);
      }
      messaging.onTokenRefresh.listen(_persistToken);
      FirebaseMessaging.onMessage.listen(_handleForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
  }

  static Future<void> _persistToken(String token) async {
    try {
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) return;
      await SupabaseService.client
          .from('users')
          .update({'fcm_token': token}).eq('id', uid);
    } catch (e) {
      debugPrint('FCM token persist failed: $e');
    }
  }

  static void _handleForeground(RemoteMessage message) {
    debugPrint('FCM foreground: ${message.data}');
  }

  static void _handleTap(RemoteMessage message) {
    final type = message.data['type'];
    final groupId = message.data['group_id'];
    final taskId = message.data['task_id'];
    switch (type) {
      case 'task_assigned':
      case 'due_reminder':
        if (groupId != null && taskId != null) {
          router.push('/groups/$groupId/tasks/$taskId');
        }
      case 'announcement':
        if (groupId != null) {
          router.push('/groups/$groupId');
        }
      case 'announcement_approved':
      case 'announcement_rejected':
        router.push('/notifications');
    }
  }
}
