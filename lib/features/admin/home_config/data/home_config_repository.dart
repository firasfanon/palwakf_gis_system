// lib/features/admin/home_config/data/home_config_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/home_config.dart';

class HomeConfigRepository {
  final _client = Supabase.instance.client;

  Future<HomeConfig?> getDefault() async {
    final res = await _client.from('home_config').select().eq('id', 'default').maybeSingle();

    if (res != null) {
      return HomeConfig.fromMap(res);
    } else {
      // إنشاء تكوين افتراضي
      return const HomeConfig(
        id: 'default',
        heroTitle: 'مستكشف الوقف',
        heroSubtitle: 'منصة وطنية لاستكشاف الأوقاف',
      );
    }
  }

  Future<void> upsert(HomeConfig cfg) async {
    await _client.from('home_config').upsert(cfg.toMap());
  }
}