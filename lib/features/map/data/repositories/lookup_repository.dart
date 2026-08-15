// lib/features/map/data/repositories/lookup_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/models/lookup_item.dart';

final lookupRepositoryProvider = Provider<LookupRepository>((ref) {
  return LookupRepository(ref.watch(supabaseClientProvider));
});

class LookupRepository {
  final SupabaseClient _client;
  LookupRepository(this._client);

  Future<List<LookupItem>> fetchGovernorates() async {
    final rows = await _tryRpcOrSelect(
      rpcName: 'rpc_gis_lookup_governorates',
      schema: 'gis',
      preferred: 'v_governorates_core',
      fallback: 'governorates_boundary',
    );
    final items = rows
        .map(LookupItem.fromJson)
        .where((item) => item.code.trim().isNotEmpty)
        .toList();
    items.sort((a, b) => a.bestLabel.compareTo(b.bestLabel));
    return items;
  }

  Future<List<LookupItem>> fetchLgus() async {
    final rows = await _tryRpcOrSelect(
      rpcName: 'rpc_gis_lookup_lgus',
      schema: 'gis',
      preferred: 'v_lgus_core',
      fallback: 'lgus_boundary',
    );
    final items = rows
        .map(LookupItem.fromJson)
        .where((item) => item.code.trim().isNotEmpty)
        .toList();
    items.sort((a, b) => a.bestLabel.compareTo(b.bestLabel));
    return items;
  }

  Future<List<LookupItem>> fetchCommunities() async {
    final rows = await _fetchCommunitiesRows();
    final items = rows
        .map(LookupItem.fromJson)
        .where((item) => item.code.trim().isNotEmpty)
        .toList();
    items.sort((a, b) => a.bestLabel.compareTo(b.bestLabel));
    return items;
  }

  Future<List<LookupItem>> fetchCommunitiesByGovernorate(
    String governorateCode, {
    String? governorateName,
  }) async {
    final normalizedCode = _normalize(governorateCode);
    final normalizedName = _normalize(governorateName);
    if (normalizedCode.isEmpty && normalizedName.isEmpty) return const [];

    final rows = await _fetchCommunitiesRows();
    final filteredRows = rows.where((row) {
      bool matches(List<String> keys, String expected) {
        if (expected.isEmpty) return false;
        for (final key in keys) {
          final value = _normalize(row[key]?.toString());
          if (value.isEmpty) continue;
          if (value == expected || value.contains(expected) || expected.contains(value)) {
            return true;
          }
        }
        return false;
      }

      final codeMatch = matches(const [
        'governorate_code',
        'gov_code',
        'governorate_no',
        'gov_no',
        'parent_code',
      ], normalizedCode);

      final nameMatch = matches(const [
        'governorate_name_ar',
        'gov_name_ar',
        'governorate_ar',
        'governorate',
        'governoraten',
        'parent_name_ar',
      ], normalizedName);

      return codeMatch || nameMatch;
    }).toList();

    final items = filteredRows
        .map(LookupItem.fromJson)
        .where((item) => item.code.trim().isNotEmpty)
        .toList();
    items.sort((a, b) => a.bestLabel.compareTo(b.bestLabel));
    return items;
  }

  Future<List<Map<String, dynamic>>> _fetchCommunitiesRows() {
    return _tryRpcOrSelect(
      rpcName: 'rpc_gis_lookup_communities',
      schema: 'gis',
      preferred: 'v_communities_core',
      fallback: 'communities_boundary',
    );
  }

  Future<List<Map<String, dynamic>>> _tryRpcOrSelect({
    required String rpcName,
    required String schema,
    required String preferred,
    required String fallback,
  }) async {
    try {
      final res = await _client.rpc(rpcName);
      final normalized = _normalizeRpcRows(res, rpcName);
      if (normalized.isNotEmpty) {
        return normalized;
      }
    } catch (_) {}

    return _trySelect(schema: schema, preferred: preferred, fallback: fallback);
  }

  List<Map<String, dynamic>> _normalizeRpcRows(dynamic res, String rpcName) {
    if (res is! List) return const [];
    final rows = <Map<String, dynamic>>[];
    for (final entry in res) {
      if (entry is! Map) continue;
      final raw = entry.cast<String, dynamic>();

      if (raw.length == 1 && raw.containsKey(rpcName)) {
        final nested = raw[rpcName];
        if (nested is Map) {
          rows.add(nested.cast<String, dynamic>());
          continue;
        }
      }

      rows.add(raw);
    }
    return rows;
  }

  Future<List<Map<String, dynamic>>> _trySelect({
    required String schema,
    required String preferred,
    required String fallback,
  }) async {
    try {
      final res = await _client.schema(schema).from(preferred).select();
      return (res as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
    } catch (_) {
      final res = await _client.schema(schema).from(fallback).select();
      return (res as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
    }
  }

  String _normalize(String? value) {
    return (value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
