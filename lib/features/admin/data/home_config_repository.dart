// lib/features/admin/data/home_config_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/home_config.dart';

class HomeConfigRepository {
  HomeConfigRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _table = 'home_config';

  Future<HomeConfig?> fetchConfig() async {
    // Always read the single canonical row.
    // This avoids relying on "limit(1)" which can silently return null
    // with RLS / ordering differences.
    final response = await _client
        .from(_table)
        .select()
        .eq('id', 'default')
        .maybeSingle();

    if (response == null) {
      // If the row doesn't exist yet, create it once (idempotent) then re-fetch.
      await _client.from(_table).upsert({
        'id': 'default',
        'hero_title': 'مستكشف الوقف',
        'hero_subtitle': 'منصة وطنية لاستكشاف الأوقاف',
      });

      final created = await _client
          .from(_table)
          .select()
          .eq('id', 'default')
          .maybeSingle();

      if (created == null) return null;
      return _convertToHomeConfig(Map<String, dynamic>.from(created as Map));
    }

    return _convertToHomeConfig(Map<String, dynamic>.from(response as Map));
  }

  Future<void> saveConfig(HomeConfig config) async {
    final data = _convertFromHomeConfig(config);
    await _client.from(_table).upsert(data);
  }

  HomeConfig _convertToHomeConfig(Map<String, dynamic> json) {
    final subtitle = (json['hero_subtitle'] as String?) ?? '';

    return HomeConfig(
      id: json['id'].toString(),
      heroTitle: json['hero_title'] as String? ?? '',
      heroSubtitle: subtitle,
    );
  }

  Map<String, dynamic> _convertFromHomeConfig(HomeConfig config) {
    return {
      // Force the canonical id to avoid accidental multi-row configs.
      'id': (config.id.isEmpty) ? 'default' : config.id,
      'hero_title': config.heroTitle,
      'hero_subtitle': config.heroSubtitle,
    };
  }
}
