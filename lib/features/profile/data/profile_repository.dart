import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../../core/services/supabase_service.dart';
import '../domain/profile_model.dart';

final profileRepositoryProvider =
    Provider<ProfileRepository>((_) => ProfileRepository());

class ProfileRepository {
  static const _avatarsBucket = 'avatars';

  Future<UserProfile> fetchMe() async {
    final uid = SupabaseService.currentUser!.id;
    final data = await SupabaseService.client
        .from('users')
        .select()
        .eq('id', uid)
        .single();
    return UserProfile.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> updateProfile({
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    final uid = SupabaseService.currentUser!.id;
    final payload = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (displayName != null) payload['display_name'] = displayName;
    if (username != null) payload['username'] = username;
    if (bio != null) payload['bio'] = bio;
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
    if (payload.length == 1) return;
    await SupabaseService.client.from('users').update(payload).eq('id', uid);
  }

  /// Uploads [file] to the avatars bucket under the user's id and returns
  /// the public URL (cache-busted).
  Future<String> uploadAvatar(File file) async {
    final uid = SupabaseService.currentUser!.id;
    final dot = file.path.lastIndexOf('.');
    final ext =
        (dot >= 0 ? file.path.substring(dot) : '.jpg').toLowerCase();
    final path = '$uid/avatar$ext';
    final storage = SupabaseService.client.storage.from(_avatarsBucket);
    await storage.upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true, cacheControl: '3600'),
    );
    final url = storage.getPublicUrl(path);
    return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
  }
}
