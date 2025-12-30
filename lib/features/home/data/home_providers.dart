// lib/features/home/data/home_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_client_provider.dart';
import '../domain/models/home_models.dart';

/// Repository بسيط لوحدة الصفحة الرئيسية
class HomeRepository {
  final SupabaseClient _client;

  HomeRepository(this._client);

  Future<List<HeroSlide>> getHeroSlides() async {
    final data = await _client
        .from('home_hero_slides')
        .select<Map<String, dynamic>>()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return data.map(HeroSlide.fromMap).toList();
  }

  Future<HomeStats> getHomeStats() async {
    // هنا استخدمت count() لكل جدول، عدّل أسماء الجداول حسب سكربت DB عندك
    final lands = await _client
        .from('waqf_lands')
        .select<Map<String, dynamic>>('id', const FetchOptions(count: CountOption.exact));
    final projects = await _client
        .from('waqf_projects')
        .select<Map<String, dynamic>>('id', const FetchOptions(count: CountOption.exact));
    final govs = await _client
        .from('governorates')
        .select<Map<String, dynamic>>('id', const FetchOptions(count: CountOption.exact));

    return HomeStats(
      landsCount: lands.count ?? 0,
      projectsCount: projects.count ?? 0,
      governoratesCount: govs.count ?? 0,
    );
  }

  Future<List<NewsItem>> getLatestNews({int limit = 5}) async {
    final data = await _client
        .from('news_items')
        .select<Map<String, dynamic>>()
        .eq('is_published', true)
        .order('published_at', ascending: false)
        .limit(limit);

    return data.map(NewsItem.fromMap).toList();
  }

  Future<List<NewsItem>> getLatestAnnouncements({int limit = 5}) async {
    final data = await _client
        .from('news_items')
        .select<Map<String, dynamic>>()
        .eq('is_published', true)
        .eq('type', 'announcement')
        .order('published_at', ascending: false)
        .limit(limit);

    return data.map(NewsItem.fromMap).toList();
  }
}

/// Provider لـ HomeRepository
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return HomeRepository(client);
});

/// Hero slides
final heroSlidesProvider = FutureProvider<List<HeroSlide>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getHeroSlides();
});

/// الإحصاءات
final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getHomeStats();
});

/// آخر الأخبار
final latestNewsProvider = FutureProvider<List<NewsItem>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getLatestNews(limit: 6);
});

/// آخر الإعلانات
final latestAnnouncementsProvider = FutureProvider<List<NewsItem>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getLatestAnnouncements(limit: 6);
});
