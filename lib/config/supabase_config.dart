import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_secrets.dart';

class SupabaseConfig {
  static const String supabaseUrl = SupabaseSecrets.url;
  static const String supabaseAnonKey = SupabaseSecrets.anonKey;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
