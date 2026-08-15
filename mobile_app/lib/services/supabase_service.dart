import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Ported from src/lib/supabaseClient.ts — same project, same anon key.
class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
