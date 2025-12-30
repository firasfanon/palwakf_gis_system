/// تكوين التطبيق
/// يحتوي على ثوابت التطبيق والإعدادات العامة
class AppConfig {
  // Supabase Configuration (سيتم إضافتها لاحقاً)
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // App Information
  static const String appName = 'نظام إدارة القضايا';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'نظام إدارة قضايا وزارة الأوقاف والشؤون الدينية';

  // API Configuration
  static const String apiBaseUrl = 'https://api.awqaf.gov.iq';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Local Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String authStateKey = 'auth_state';

  // Feature Flags
  static const bool enableLogging = true;
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = false;
}
