import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/env.dart';

class SupabaseService {
  SupabaseService._();

  static Future<void> init() async {
    if (!Env.isConfigured) {
      // App still boots so devs can see UI without creds.
      return;
    }
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static Session? get currentSession => client.auth.currentSession;
}
