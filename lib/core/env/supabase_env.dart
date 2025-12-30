class SupabaseEnv {
  // ضع رابط مشروع Supabase
  static const String url = 'https://lyeryfsrhrxuepuqepgi.supabase.co';

  // ضع anon public key
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5ZXJ5ZnNyaHJ4dWVwdXFlcGdpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3MTIzNDAsImV4cCI6MjA3NTI4ODM0MH0.KYXunDN4p1lALeclNLvGLu2m56wvMhqidDoZKH6npvI';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

