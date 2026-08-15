import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/models/lookup_item.dart';

final gisLookupRepositoryProvider = Provider<GisLookupRepository>((ref) {
  return GisLookupRepository(ref.watch(supabaseClientProvider));
});

class GisLookupRepository {
  final SupabaseClient _client;
  GisLookupRepository(this._client);

  Future<List<LookupItem>> _safeFetch(String table) async {
    final res = await _client.schema('gis').from(table).select().limit(5000);
    final items = (res as List)
        .map((e) => LookupItem.fromJson((e as Map).cast<String, dynamic>()))
        .where((i) => i.code.trim().isNotEmpty)
        .toList();
    items.sort((a, b) => a.labelAr.compareTo(b.labelAr));
    return items;
  }

  Future<List<LookupItem>> fetchGovernorates() async {
    try {
      return await _safeFetch('v_governorates_core');
    } catch (_) {
      return _safeFetch('governorates_boundary');
    }
  }

  Future<List<LookupItem>> fetchCommunities() async {
    try {
      return await _safeFetch('v_communities_core');
    } catch (_) {
      return _safeFetch('communities_boundary');
    }
  }

  Future<List<LookupItem>> fetchLgus() async {
    try {
      return await _safeFetch('v_lgus_core');
    } catch (_) {
      return _safeFetch('lgus_boundary');
    }
  }
}
