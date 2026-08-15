import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WaqfAssetRemoteDataSource {
  WaqfAssetRemoteDataSource({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const List<String> _searchRpcCandidates = [
    'rpc_mustakshif_waqf_assets_search_v1',
    'rpc_waqf_assets_search_v1',
    'rpc_public_waqf_assets_search_v1',
  ];

  static const List<String> _detailsRpcCandidates = [
    'rpc_mustakshif_waqf_asset_details_v1',
    'rpc_waqf_asset_details_v1',
    'rpc_public_waqf_asset_details_v1',
  ];

  static const List<String> _linkedParcelsRpcCandidates = [
    'rpc_mustakshif_waqf_asset_linked_parcels_v1',
    'rpc_waqf_asset_linked_parcels_v1',
    'rpc_public_waqf_asset_linked_parcels_v1',
  ];

  static const List<String> _parcelTables = [
    'waqf_asset_parcels',
    'waqf_asset_parcel_links',
    'asset_parcels',
  ];

  Future<List<Map<String, dynamic>>> searchAssets({
    String? query,
    int limit = 40,
    String? endowmentName,
  }) async {
    final normalizedQuery = (query ?? '').trim();
    final normalizedEndowment = (endowmentName ?? '').trim();

    final rpcRows = await _tryRpcRows(
      candidates: _searchRpcCandidates,
      params: {
        'p_query': normalizedQuery.isEmpty ? null : normalizedQuery,
        'p_limit': limit,
        'p_endowment_name': normalizedEndowment.isEmpty ? null : normalizedEndowment,
      },
    );
    if (rpcRows.isNotEmpty) {
      return rpcRows;
    }

    try {
      final raw = await _client.from('waqf_assets').select().limit(limit * 4);
      final rows = _asRows(raw);
      return _filterAssetRows(
        rows,
        query: normalizedQuery,
        endowmentName: normalizedEndowment,
        limit: limit,
      );
    } catch (error, stackTrace) {
      debugPrint('WaqfAssetRemoteDataSource.searchAssets fallback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const [];
    }
  }

  Future<Map<String, dynamic>?> fetchAssetDetails({
    required String waqfAssetId,
    String? nationalAssetCode,
  }) async {
    final assetId = waqfAssetId.trim();
    final nationalCode = (nationalAssetCode ?? '').trim();
    if (assetId.isEmpty && nationalCode.isEmpty) return null;

    final rpcRows = await _tryRpcRows(
      candidates: _detailsRpcCandidates,
      params: {
        'p_waqf_asset_id': assetId.isEmpty ? null : assetId,
        'p_national_asset_code': nationalCode.isEmpty ? null : nationalCode,
      },
    );
    if (rpcRows.isNotEmpty) {
      return rpcRows.first;
    }

    try {
      final raw = await _client.from('waqf_assets').select().limit(300);
      for (final row in _asRows(raw)) {
        final rowAssetId = _readString(row, const ['waqf_asset_id', 'asset_id', 'id']);
        final rowNationalCode = _readString(row, const ['national_asset_code', 'national_code', 'pwf_key', 'code']);
        if ((assetId.isNotEmpty && rowAssetId == assetId) ||
            (nationalCode.isNotEmpty && rowNationalCode == nationalCode)) {
          return row;
        }
      }
    } catch (error, stackTrace) {
      debugPrint('WaqfAssetRemoteDataSource.fetchAssetDetails fallback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchLinkedParcels({
    required String waqfAssetId,
    String? nationalAssetCode,
  }) async {
    final assetId = waqfAssetId.trim();
    final nationalCode = (nationalAssetCode ?? '').trim();
    if (assetId.isEmpty && nationalCode.isEmpty) return const [];

    final rpcRows = await _tryRpcRows(
      candidates: _linkedParcelsRpcCandidates,
      params: {
        'p_waqf_asset_id': assetId.isEmpty ? null : assetId,
        'p_national_asset_code': nationalCode.isEmpty ? null : nationalCode,
      },
    );
    if (rpcRows.isNotEmpty) {
      return rpcRows;
    }

    for (final table in _parcelTables) {
      try {
        final raw = await _client.from(table).select().limit(400);
        final rows = _asRows(raw).where((row) {
          final rowAssetId = _readString(row, const ['waqf_asset_id', 'asset_id', 'id']);
          final rowNationalCode = _readString(row, const ['national_asset_code', 'national_code', 'pwf_key', 'asset_code']);
          return (assetId.isNotEmpty && rowAssetId == assetId) ||
              (nationalCode.isNotEmpty && rowNationalCode == nationalCode);
        }).toList(growable: false);
        if (rows.isNotEmpty) return rows;
      } catch (_) {
        // ignore and keep looking through candidate tables.
      }
    }

    return const [];
  }

  Future<List<Map<String, dynamic>>> _tryRpcRows({
    required List<String> candidates,
    required Map<String, dynamic> params,
  }) async {
    for (final rpcName in candidates) {
      try {
        final raw = await _client.rpc(rpcName, params: params);
        final rows = _asRows(raw);
        if (rows.isNotEmpty) return rows;
      } catch (_) {
        // ignore and try the next candidate.
      }
    }
    return const [];
  }

  List<Map<String, dynamic>> _asRows(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList(growable: false);
    }
    if (raw is Map<String, dynamic>) {
      return [raw];
    }
    if (raw is Map) {
      return [raw.cast<String, dynamic>()];
    }
    return const [];
  }

  List<Map<String, dynamic>> _filterAssetRows(
    List<Map<String, dynamic>> rows, {
    required String query,
    required String endowmentName,
    required int limit,
  }) {
    final q = query.toLowerCase();
    final endowment = endowmentName.toLowerCase();
    final filtered = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final row in rows) {
      if (endowment.isNotEmpty) {
        final rowEndowment = _readString(row, const [
          'endowment_name',
          'reference_endowment_name',
          'waqf_name',
          'wakf_name',
        ]).toLowerCase();
        if (!rowEndowment.contains(endowment)) continue;
      }

      if (q.isNotEmpty) {
        final haystack = [
          _readString(row, const ['national_asset_code', 'national_code', 'pwf_key', 'code']),
          _readString(row, const ['name_ar', 'asset_name_ar', 'name', 'asset_name']),
          _readString(row, const ['endowment_name', 'reference_endowment_name', 'waqf_name']),
          _readString(row, const ['governorate', 'governorate_name', 'current_governorate']),
          _readString(row, const ['municipality', 'lgu_name', 'current_lgu']),
        ].where((e) => e.isNotEmpty).join(' | ').toLowerCase();
        if (!haystack.contains(q)) continue;
      }

      final dedupeKey = _readString(row, const [
        'waqf_asset_id',
        'asset_id',
        'id',
        'national_asset_code',
        'national_code',
        'pwf_key',
        'code',
      ]);
      if (dedupeKey.isEmpty || !seen.add(dedupeKey)) continue;
      filtered.add(row);
      if (filtered.length >= limit) break;
    }

    return filtered;
  }

  String _readString(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }
}
