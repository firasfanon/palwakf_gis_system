import 'package:flutter_dotenv/flutter_dotenv.dart';

// lib/core/services/supabase_config.dart
// قراءة إعدادات Supabase عبر --dart-define (مفضل للويب)

class SupabaseConfig {
  static String get url {
    const v = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    if (v.isNotEmpty) return v;
    return dotenv.env['SUPABASE_URL'] ?? 'YOUR_SUPABASE_URL';
  }

  static String get anonKey {
    const v = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    if (v.isNotEmpty) return v;
    return dotenv.env['SUPABASE_ANON_KEY'] ?? 'YOUR_SUPABASE_ANON_KEY';
  }

  static bool get isConfigured {
    final urlOk = url.startsWith('http') && !url.contains('YOUR_SUPABASE');
    final keyOk = anonKey.isNotEmpty && !anonKey.contains('YOUR_SUPABASE');
    return urlOk && keyOk;
  }
}
