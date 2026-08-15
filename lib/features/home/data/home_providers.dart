import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../domain/models/home_models.dart';

class HomeRepository {
  final SupabaseClient _client;

  HomeRepository(this._client);

  Future<List<HeroSlide>> getHeroSlides() async {
    final data = await _client
        .from('home_hero_slides')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return data
        .map((row) => HeroSlide.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<HomeStats> getHomeStats() async {
    final lands = await _client.from('waqf_lands').select('id');
    final projects = await _client.from('waqf_projects').select('id');
    final govs = await _client.from('governorates').select('id');

    return HomeStats(
      landsCount: lands.length,
      projectsCount: projects.length,
      governoratesCount: govs.length,
    );
  }

  Future<List<NewsItem>> getLatestNews({int limit = 5}) async {
    final data = await _client
        .from('news_items')
        .select()
        .eq('is_published', true)
        .order('published_at', ascending: false)
        .limit(limit);

    return data
        .map((row) => NewsItem.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<NewsItem>> getLatestAnnouncements({int limit = 5}) async {
    final data = await _client
        .from('news_items')
        .select()
        .eq('is_published', true)
        .eq('type', 'announcement')
        .order('published_at', ascending: false)
        .limit(limit);

    return data
        .map((row) => NewsItem.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return HomeRepository(client);
});

final heroSlidesProvider = FutureProvider<List<HeroSlide>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getHeroSlides();
});

final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getHomeStats();
});

final latestNewsProvider = FutureProvider<List<NewsItem>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getLatestNews(limit: 6);
});

final latestAnnouncementsProvider = FutureProvider<List<NewsItem>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getLatestAnnouncements(limit: 6);
});
