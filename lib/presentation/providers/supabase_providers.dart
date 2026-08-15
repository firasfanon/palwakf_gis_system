import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/supabase_service.dart';

/// Platform-compatible Supabase service provider.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});
