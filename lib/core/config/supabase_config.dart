import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {

  // IMPORTANT: Use the SERVICE_ROLE key for admin dashboard, not anon key

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get serviceRoleKey => dotenv.env['SUPABASE_ROLE_KEY'] ?? '';
  
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: serviceRoleKey, // Admin uses service role key
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}
