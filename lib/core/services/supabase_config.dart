import 'package:flutter_dotenv/flutter_dotenv.dart';

// lib/core/services/supabase_config.dart
// ????? ??????? Supabase ??? --dart-define ?????? ?? .env ?? ??? ?????.
// ?? ??? ?? ????? Flutter Web ??? .env ?? bundled asset.

class SupabaseConfig {
  static const String _placeholderUrl = 'https://placeholder.supabase.co';
  static const String _placeholderAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  static String _readDotEnv(String key) {
    try {
      return (dotenv.env[key] ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  static String get url {
    const defineValue = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );

    final value = defineValue.trim().isNotEmpty
        ? defineValue.trim()
        : _readDotEnv('SUPABASE_URL');

    if (value.startsWith('http') && !value.contains('YOUR_SUPABASE')) {
      return value;
    }

    return _placeholderUrl;
  }

  static String get anonKey {
    const defineValue = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );

    final value = defineValue.trim().isNotEmpty
        ? defineValue.trim()
        : _readDotEnv('SUPABASE_ANON_KEY');

    if (value.isNotEmpty && !value.contains('YOUR_SUPABASE')) {
      return value;
    }

    return _placeholderAnonKey;
  }

  static bool get isConfigured {
    final configuredUrl = url;
    final configuredAnonKey = anonKey;

    final urlOk = configuredUrl.startsWith('http') &&
        configuredUrl != _placeholderUrl &&
        !configuredUrl.contains('YOUR_SUPABASE');

    final keyOk = configuredAnonKey.isNotEmpty &&
        configuredAnonKey != _placeholderAnonKey &&
        !configuredAnonKey.contains('YOUR_SUPABASE');

    return urlOk && keyOk;
  }
}
