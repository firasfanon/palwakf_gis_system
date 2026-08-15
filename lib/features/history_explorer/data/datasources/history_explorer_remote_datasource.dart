import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryExplorerRemoteDataSource {
  HistoryExplorerRemoteDataSource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _coreLguSchema = 'core';
  static const String _coreLguTable = 'core_lgus';
  static const String _waqfLguSearchRpc = 'rpc_waqf_lgu_search_v1';

  Future<List<Map<String, dynamic>>> fetchPeriods() async {
    final raw = await _client.rpc('rpc_historical_period_list_v1');
    return _asRows(raw);
  }

  Future<Map<String, dynamic>?> fetchPeriodMeta(int periodNo) async {
    final raw = await _client.rpc(
      'rpc_historical_period_meta_v1',
      params: {'p_period_no': periodNo},
    );
    final rows = _asRows(raw);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> fetchLevels(int periodNo) async {
    final raw = await _client.rpc(
      'rpc_historical_period_levels_v1',
      params: {'p_period_no': periodNo},
    );
    return _asRows(raw);
  }

  Future<Map<String, dynamic>?> tryResolveHistoricalContextRpc({
    required int periodNo,
    required String sourceId,
    String? entityCode,
    String? labelAr,
    String? labelEn,
    String? levelKey,
  }) async {
    return _tryFirstRpc(
      names: const [
        'rpc_history_explorer_resolve_context_v1',
        'rpc_history_lineage_resolve_v1',
        'rpc_historical_lineage_resolve_v1',
      ],
      params: {
        'p_period_no': periodNo,
        'p_source_id': sourceId,
        'p_entity_code': entityCode,
        'p_label_ar': labelAr,
        'p_label_en': labelEn,
        'p_level_key': levelKey,
      },
    );
  }

  Future<Map<String, dynamic>?> tryResolveModernContextRpc({
    required String communityCode,
    String? communityLabel,
  }) async {
    return _tryFirstRpc(
      names: const [
        'rpc_history_explorer_resolve_modern_context_v1',
        'rpc_history_lineage_from_modern_v1',
        'rpc_historical_lineage_from_modern_v1',
      ],
      params: {
        'p_community_code': communityCode,
        'p_community_label': communityLabel,
      },
    );
  }

  Future<Map<String, dynamic>?> tryResolveWaqfContextRpc({
    required String assetId,
    required String pwfKey,
    String? assetName,
  }) async {
    return _tryFirstRpc(
      names: const [
        'rpc_history_explorer_resolve_waqf_context_v1',
        'rpc_history_lineage_from_waqf_v1',
        'rpc_historical_lineage_from_waqf_v1',
      ],
      params: {
        'p_asset_id': assetId,
        'p_pwf_key': pwfKey,
        'p_asset_name': assetName,
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchHistoricalUnitsByCodes({
    required int periodNo,
    required List<String> codes,
  }) async {
    final normalized = codes.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList(growable: false);
    if (normalized.isEmpty) return const [];

    try {
      final exact = normalized.map((code) => 'code.eq.${_escapeOrValue(code)}').join(',');
      final raw = await _client
          .schema('public')
          .from('historical_admin_units')
          .select('id, code, period_id, origin_community_code, parent_id')
          .eq('period_id', periodNo)
          .or(exact);
      return _asRows(raw);
    } catch (_) {
      final raw = await _client
          .schema('public')
          .from('historical_admin_units')
          .select('id, code, period_id, origin_community_code, parent_id')
          .eq('period_id', periodNo)
          .limit(500);
      final rows = _asRows(raw);
      final lowered = normalized.map((e) => e.toLowerCase()).toSet();
      return rows.where((row) => lowered.contains((row['code'] ?? '').toString().trim().toLowerCase())).toList(growable: false);
    }
  }

  Future<List<Map<String, dynamic>>> fetchHistoricalUnitsByOriginCommunityCodes(List<String> codes) async {
    final normalized = codes.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList(growable: false);
    if (normalized.isEmpty) return const [];
    try {
      final raw = await _client
          .schema('public')
          .from('historical_admin_units')
          .select('id, code, period_id, origin_community_code, parent_id')
          .inFilter('origin_community_code', normalized)
          .limit(1000);
      return _asRows(raw);
    } catch (_) {
      final raw = await _client
          .schema('public')
          .from('historical_admin_units')
          .select('id, code, period_id, origin_community_code, parent_id')
          .limit(2000);
      final rows = _asRows(raw);
      final lowered = normalized.map((e) => e.toLowerCase()).toSet();
      return rows
          .where((row) => lowered.contains((row['origin_community_code'] ?? '').toString().trim().toLowerCase()))
          .toList(growable: false);
    }
  }

  Future<List<Map<String, dynamic>>> fetchHistoricalUnitsByIds(List<int> ids) async {
    final normalized = ids.toSet().toList(growable: false);
    if (normalized.isEmpty) return const [];
    final raw = await _client
        .schema('public')
        .from('historical_admin_units')
        .select('id, code, period_id, origin_community_code, parent_id')
        .inFilter('id', normalized);
    return _asRows(raw);
  }

  Future<List<Map<String, dynamic>>> fetchHistoricalRelationsByUnitIds(List<int> ids) async {
    final normalized = ids.toSet().toList(growable: false);
    if (normalized.isEmpty) return const [];
    final lhs = normalized.map((id) => 'source_historical_admin_unit_id.eq.$id').join(',');
    final rhs = normalized.map((id) => 'target_historical_admin_unit_id.eq.$id').join(',');
    final raw = await _client
        .schema('topology')
        .from('historical_admin_relations')
        .select('id, source_historical_admin_unit_id, target_historical_admin_unit_id, relation_type, confidence, is_active, notes')
        .eq('is_active', true)
        .or('$lhs,$rhs');
    return _asRows(raw);
  }

  Future<List<Map<String, dynamic>>> fetchLookupRows({
    required String rpcName,
    required String schema,
    required String preferred,
    required String fallback,
  }) async {
    try {
      final raw = await _client.rpc(rpcName);
      return _asRows(raw);
    } catch (_) {
      try {
        final raw = await _client.schema(schema).from(preferred).select().limit(5000);
        return _asRows(raw);
      } catch (_) {
        final raw = await _client.schema(schema).from(fallback).select().limit(5000);
        return _asRows(raw);
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchWaqfAssetsByContext({
    String? community,
    String? municipality,
    String? governorate,
  }) async {
    final tables = ['waqf_lands', 'waqf_assets', 'endowments', 'waqf_endowments'];
    final out = <Map<String, dynamic>>[];
    final seen = <String>{};

    final coreRows = await _fetchCoreLguWaqfRows(
      query: [community, municipality, governorate].whereType<String>().join(' ').trim(),
      limit: 80,
      community: community,
      municipality: municipality,
      governorate: governorate,
    );
    for (final row in coreRows) {
      final id = _waqfRowIdentity(row);
      if (!seen.add(id)) continue;
      out.add(row);
      if (out.length >= 24) return out;
    }

    for (final table in tables) {
      try {
        final raw = await _client.from(table).select().limit(120);
        for (final row in _asRows(raw)) {
          if (!_matchesContext(row, community: community, municipality: municipality, governorate: governorate)) continue;
          final id = _waqfRowIdentity(row);
          if (!seen.add(id)) continue;
          out.add(row);
          if (out.length >= 24) return out;
        }
      } catch (_) {}
    }

    final gisRows = await _fetchGisWaqfRows(query: [community, municipality, governorate].whereType<String>().join(' ').trim(), limit: 60);
    for (final row in gisRows) {
      if (!_matchesContext(row, community: community, municipality: municipality, governorate: governorate)) continue;
      final id = _waqfRowIdentity(row);
      if (!seen.add(id)) continue;
      out.add(row);
      if (out.length >= 24) break;
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> fetchWaqfAssets({String? query, int limit = 60}) async {
    final tables = ['waqf_lands', 'waqf_assets', 'endowments', 'waqf_endowments'];
    final normalized = query?.trim() ?? '';
    final out = <Map<String, dynamic>>[];
    final seen = <String>{};

    final coreRows = await _fetchCoreLguWaqfRows(query: normalized, limit: limit * 3);
    for (final row in coreRows) {
      final id = _waqfRowIdentity(row);
      if (!seen.add(id)) continue;
      out.add(row);
      if (out.length >= limit) return out;
    }

    for (final table in tables) {
      try {
        final raw = await _client.from(table).select().limit(limit * 3);
        final rows = _asRows(raw);
        for (final row in rows) {
          if (!_matchesWaqfQuery(row, normalized)) continue;
          final id = _waqfRowIdentity(row);
          if (!seen.add(id)) continue;
          out.add(row);
          if (out.length >= limit) return out;
        }
      } catch (_) {}
    }

    final gisRows = await _fetchGisWaqfRows(query: normalized, limit: limit * 2);
    for (final row in gisRows) {
      final id = _waqfRowIdentity(row);
      if (!seen.add(id)) continue;
      out.add(row);
      if (out.length >= limit) break;
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> _fetchCoreLguWaqfRows({
    String? query,
    int limit = 120,
    String? community,
    String? municipality,
    String? governorate,
  }) async {
    final normalizedQuery = (query ?? '').trim();

    try {
      final raw = await _client.rpc(_waqfLguSearchRpc, params: {
        'p_query': normalizedQuery.isEmpty ? null : normalizedQuery,
        'p_limit': limit,
      });
      final out = <Map<String, dynamic>>[];
      for (final row in _asRows(raw)) {
        final normalized = _normalizeCoreLguWaqfRow(row);
        if (!_matchesContext(normalized, community: community, municipality: municipality, governorate: governorate)) continue;
        out.add(normalized);
        if (out.length >= limit) break;
      }
      if (out.isNotEmpty) return out;
    } catch (e, st) {
      debugPrint('$_waqfLguSearchRpc failed in HistoryExplorerRemoteDataSource: $e');
      debugPrintStack(stackTrace: st);
    }

    try {
      final raw = await _client
          .schema(_coreLguSchema)
          .from(_coreLguTable)
          .select('id, code, community_code, name_ar, name_en, wakf_name, wakf_type, wakf_status, city_status, lgus_no, community_no, sort_order, is_active')
          .limit(2000);
      final rows = _asRows(raw);
      final out = <Map<String, dynamic>>[];
      for (final row in rows) {
        if (!_coreLguHasWaqfData(row)) continue;
        final normalized = _normalizeCoreLguWaqfRow(row);
        if (!_matchesWaqfQuery(normalized, normalizedQuery)) continue;
        if (!_matchesContext(normalized, community: community, municipality: municipality, governorate: governorate)) continue;
        out.add(normalized);
        if (out.length >= limit) break;
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  bool _coreLguHasWaqfData(Map<String, dynamic> row) {
    bool has(String key) => (row[key] ?? '').toString().trim().isNotEmpty;
    return has('wakf_name') || has('wakf_type') || has('wakf_status');
  }

  Map<String, dynamic> _normalizeCoreLguWaqfRow(Map<String, dynamic> row) {
    final lguName = (row['name_ar'] ?? '').toString().trim();
    final wakfName = (row['wakf_name'] ?? '').toString().trim();

    final code = (row['code'] ?? row['source_code'] ?? '').toString().trim();
    final sourceId = (row['source_id'] ?? row['id'] ?? '').toString().trim();
    final id = code.isNotEmpty ? code : (sourceId.isNotEmpty ? sourceId : code);

    final wakfType = (row['wakf_type'] ?? '').toString().trim();
    final wakfStatus = (row['wakf_status'] ?? '').toString().trim();
    final cityStatus = (row['city_status'] ?? '').toString().trim();

    return {
      'id': id,
      'pwf_key': code,
      'code': code,
      'name': wakfName.isNotEmpty ? wakfName : lguName,
      'name_ar': wakfName.isNotEmpty ? wakfName : lguName,
      'title_ar': wakfName.isNotEmpty ? wakfName : lguName,
      'municipality': lguName,
      'lgu_name': lguName,
      'community': lguName,
      'community_name': lguName,
      'type': wakfType,
      'category': cityStatus,
      'status': wakfStatus.isNotEmpty ? wakfStatus : cityStatus,
      'purpose': lguName.isNotEmpty ? 'الهيئة المحلية: $lguName' : null,
      'source_table': 'core.core_lgus',
      'raw_name_ar': lguName,
      'wakf_name': wakfName,
      'wakf_type': wakfType,
      'wakf_status': wakfStatus,
      'city_status': cityStatus,
      'community_code': (row['community_code'] ?? '').toString(),
      'lgus_no': row['lgus_no'],
      'community_no': row['community_no'],
      'source_id': (row['source_id'] ?? '').toString(),
      'source_code': (row['source_code'] ?? '').toString(),
    };
  }

  Future<List<Map<String, dynamic>>> _fetchGisWaqfRows({String? query, int limit = 120}) async {
    const layerKeys = ['waqf_lands', 'waqf_assets'];
    const west = 34.15;
    const south = 29.30;
    const east = 35.95;
    const north = 33.45;
    final out = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final layerKey in layerKeys) {
      try {
        final raw = await _client.schema('gis').rpc(
          'rpc_layer_features_in_bounds',
          params: {
            'p_layer_key': layerKey,
            'p_minx': west,
            'p_miny': south,
            'p_maxx': east,
            'p_maxy': north,
            'p_limit': limit,
            'p_unit_id': '00000000-0000-0000-0000-000000000000',
          },
        );
        for (final row in _asRows(raw)) {
          if (!_matchesWaqfQuery(row, query ?? '')) continue;
          final id = _waqfRowIdentity(row);
          if (!seen.add(id)) continue;
          out.add(row);
          if (out.length >= limit) return out;
        }
      } catch (_) {}
    }
    return out;
  }

  bool _matchesContext(
    Map<String, dynamic> row, {
    String? community,
    String? municipality,
    String? governorate,
  }) {
    bool containsAny(List<String> keys, String? needle) {
      final q = (needle ?? '').trim().toLowerCase();
      if (q.isEmpty) return true;
      final props = (row['props'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      for (final key in keys) {
        final value = (row[key] ?? props[key])?.toString().trim().toLowerCase();
        if (value != null && value.isNotEmpty && value.contains(q)) return true;
      }
      return false;
    }

    return containsAny(const ['community', 'community_name', 'community_ar', 'city', 'city_name'], community) &&
        containsAny(const ['municipality', 'lgu', 'lgu_name', 'municipality_name'], municipality) &&
        containsAny(const ['governorate', 'governorate_name', 'gov_name', 'gov_ar'], governorate);
  }

  bool _matchesWaqfQuery(Map<String, dynamic> row, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final props = (row['props'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final values = [
      row['id'],
      row['title_ar'],
      row['title_en'],
      row['pwf_key'],
      row['pwf'],
      row['code'],
      row['name'],
      row['name_ar'],
      row['title'],
      row['title_ar'],
      row['community'],
      row['community_name'],
      row['community_ar'],
      row['municipality'],
      row['lgu'],
      row['lgu_name'],
      row['governorate'],
      row['gov_name'],
      row['gov_ar'],
      row['endower_name'],
      row['founder_name'],
      row['waqif_name'],
      row['type'],
      row['category'],
      row['sub_type'],
      row['deed_number'],
      row['full_address'],
      row['address'],
      row['basin'],
      row['basin_no'],
      row['basin_number'],
      row['parcel'],
      row['parcel_no'],
      row['parcel_number'],
      props['pwf_key'],
      props['pwf'],
      props['code'],
      props['name'],
      props['name_ar'],
      props['title_ar'],
      props['community'],
      props['community_name'],
      props['community_ar'],
      props['municipality'],
      props['lgu'],
      props['lgu_name'],
      props['governorate'],
      props['gov_name'],
      props['gov_ar'],
      props['endower_name'],
      props['founder_name'],
      props['waqif_name'],
      props['deed_number'],
      props['full_address'],
      props['address'],
      props['basin'],
      props['basin_no'],
      props['basin_number'],
      props['parcel'],
      props['parcel_no'],
      props['parcel_number'],
      props['type'],
      props['category'],
      props['status'],
    ].where((e) => e != null).map((e) => e.toString().toLowerCase());
    return values.any((value) => value.contains(q));
  }

  String _waqfRowIdentity(Map<String, dynamic> row) {
    final props = (row['props'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final id = (row['id'] ?? props['id'] ?? '').toString().trim();
    final pwf = (row['pwf_key'] ?? row['pwf'] ?? props['pwf_key'] ?? props['pwf'] ?? props['code'] ?? '').toString().trim();
    final name = (row['name_ar'] ?? row['title_ar'] ?? row['name'] ?? props['name_ar'] ?? props['title_ar'] ?? props['name'] ?? '').toString().trim();
    if (id.isNotEmpty) return id;
    if (pwf.isNotEmpty) return pwf;
    if (name.isNotEmpty) return name;
    return row.toString();
  }

  Future<List<Map<String, dynamic>>> fetchLayerFeaturesInBounds({
    required String layerKey,
    required double west,
    required double south,
    required double east,
    required double north,
    int limit = 400,
    String unitId = '00000000-0000-0000-0000-000000000000',
  }) async {
    try {
      final raw = await _client.schema('gis').rpc(
        'rpc_layer_features_in_bounds',
        params: {
          'p_layer_key': layerKey,
          'p_minx': west,
          'p_miny': south,
          'p_maxx': east,
          'p_maxy': north,
          'p_limit': limit,
          'p_unit_id': unitId,
        },
      );
      return _asRows(raw);
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> searchPlaces({
    required String query,
    int limit = 8,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const [];
    try {
      final raw = await _client.schema('gis').rpc(
        'rpc_place_search',
        params: {
          'p_query': normalized,
          'p_limit': limit,
        },
      );
      return _asRows(raw);
    } catch (_) {
      return const [];
    }
  }


  Future<List<Map<String, dynamic>>> fetchOverlay({
    required int periodNo,
    String? levelKey,
  }) async {
    final params = <String, dynamic>{'p_period_no': periodNo};
    if (levelKey != null && levelKey.trim().isNotEmpty) {
      params['p_level_key'] = levelKey.trim();
    }
    final raw = await _client.rpc('rpc_historical_period_overlay_v4', params: params);
    return _asRows(raw);
  }

  Future<Map<String, dynamic>?> _tryFirstRpc({
    required List<String> names,
    required Map<String, dynamic> params,
  }) async {
    for (final name in names) {
      try {
        final cleanedParams = <String, dynamic>{};
        for (final entry in params.entries) {
          if (entry.value != null) cleanedParams[entry.key] = entry.value;
        }
        final raw = await _client.rpc(name, params: cleanedParams);
        final map = _asSingleMap(raw);
        if (map != null && map.isNotEmpty) {
          return map..putIfAbsent('_rpc_name', () => name);
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Map<String, dynamic>? _asSingleMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) return raw.cast<String, dynamic>();
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map) return first.cast<String, dynamic>();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        return _asSingleMap(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _escapeOrValue(String value) {
    return value.replaceAll(',', r'\,').replaceAll('(', r'\(').replaceAll(')', r'\)');
  }

  List<Map<String, dynamic>> _asRows(dynamic raw) {
    return (raw as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }
}
