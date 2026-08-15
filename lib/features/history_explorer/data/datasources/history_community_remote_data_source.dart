import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryCommunityRemoteDataSource {
  HistoryCommunityRemoteDataSource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> searchCommunities({
    String? query,
    String? governorateCode,
    int limit = 120,
  }) async {
    final normalizedQuery = (query ?? '').trim();
    final normalizedGovernorateCode = (governorateCode ?? '').trim();

    dynamic builder = _client
        .from('v_mustakshif_communities_enriched_v1')
        .select(
      'core_id, code, name_ar, name_en, governorate_code, community_no, governorate_no, community_type, core_wakf_status, gis_id, communityn, gov_code, gis_community_no, gis_governorate_no, city_status, gis_wakf_status, shape_area',
    );

    if (normalizedGovernorateCode.isNotEmpty) {
      builder = builder.eq('governorate_code', normalizedGovernorateCode);
    }

    if (normalizedQuery.isNotEmpty) {
      final escaped = normalizedQuery.replaceAll(',', r'\,');
      builder = builder.or(
        'code.ilike.%$escaped%,name_ar.ilike.%$escaped%,name_en.ilike.%$escaped%,communityn.ilike.%$escaped%',
      );
    }

    final raw = await builder
        .order('governorate_code', ascending: true)
        .order('code', ascending: true)
        .limit(limit);

    return _asRows(raw);
  }

  List<Map<String, dynamic>> _asRows(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(growable: false);
    }
    return const [];
  }
}