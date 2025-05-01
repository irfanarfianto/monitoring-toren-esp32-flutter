import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url =
      "https://jaewdybdjwobsyqxxkld.supabase.co"; // Ganti dengan URL Supabase Anda
  static const String anonKey = "YOUR_ANON_KEY"; // Ganti dengan anonKey Anda

  static Future<SupabaseClient> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
    return Supabase.instance.client;
  }
}
