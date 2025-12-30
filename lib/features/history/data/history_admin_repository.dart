// lib/features/history/data/history_admin_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/history_admin_models.dart';

abstract class IHistoryAdminRepository {
  Future<List<HistoricalAdminUnit>> getAdminUnitsByPeriod({
    required int periodId,
    HistoricalAdminLevel? level,
    int? parentId,
  });

  Future<List<HistoricalAdminUnit>> getChildrenOfUnit(int parentId);

  Future<List<LandAdminHistoryEntry>> getLandAdminHistory(int landId);

  Future<HistoricalAdminUnit?> getAdminUnitById(int id);

  Future<HistoricalAdminUnit> createAdminUnit(HistoricalAdminUnit unit);

  Future<HistoricalAdminUnit> updateAdminUnit(HistoricalAdminUnit unit);

  Future<void> deleteAdminUnit(int id);
}

class SupabaseHistoryAdminRepository implements IHistoryAdminRepository {
  SupabaseHistoryAdminRepository(this._client);

  final SupabaseClient _client;

  static const _adminUnitsTable = 'historical_admin_units';
  static const _landAdminHistoryTable = 'land_admin_history';

  @override
  Future<List<HistoricalAdminUnit>> getAdminUnitsByPeriod({
    required int periodId,
    HistoricalAdminLevel? level,
    int? parentId,
  }) async {
    var query = _client.from(_adminUnitsTable).select();

    query = query.eq('period_id', periodId);

    if (level != null) {
      query = query.eq('level', historicalAdminLevelToDb(level));
    }

    if (parentId != null) {
      query = query.eq('parent_id', parentId);
    }

    final data = await query.order('name_ar', ascending: true);
    final rows = data as List<dynamic>;
    return rows.map((row) => _fromAdminRow(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<HistoricalAdminUnit>> getChildrenOfUnit(int parentId) async {
    final rows = await _client
        .from(_adminUnitsTable)
        .select()
        .eq('parent_id', parentId)
        .order('name_ar', ascending: true);

    final list = rows as List<dynamic>;
    return list.map((row) => _fromAdminRow(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<LandAdminHistoryEntry>> getLandAdminHistory(int landId) async {
    final rows = await _client
        .from(_landAdminHistoryTable)
        .select()
        .eq('land_id', landId)
        .order('period_id', ascending: true);

    final list = rows as List<dynamic>;
    return list.map((row) => _fromLandHistoryRow(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<HistoricalAdminUnit?> getAdminUnitById(int id) async {
    final row = await _client
        .from(_adminUnitsTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;
    return _fromAdminRow(row as Map<String, dynamic>);
  }

  @override
  Future<HistoricalAdminUnit> createAdminUnit(
      HistoricalAdminUnit unit,
      ) async {
    final payload = unit.toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');

    final row = await _client
        .from(_adminUnitsTable)
        .insert(payload)
        .select()
        .single();

    return _fromAdminRow(row as Map<String, dynamic>);
  }

  @override
  Future<HistoricalAdminUnit> updateAdminUnit(
      HistoricalAdminUnit unit,
      ) async {
    final payload = unit.toJson()
      ..remove('created_at')
      ..remove('updated_at');

    final row = await _client
        .from(_adminUnitsTable)
        .update(payload)
        .eq('id', unit.id)
        .select()
        .single();

    return _fromAdminRow(row as Map<String, dynamic>);
  }

  @override
  Future<void> deleteAdminUnit(int id) async {
    await _client.from(_adminUnitsTable).delete().eq('id', id);
  }

  HistoricalAdminUnit _fromAdminRow(Map<String, dynamic> row) {
    final normalized = Map<String, dynamic>.from(row);
    if (row['alt_names'] != null && row['alt_names'] is! Map<String, dynamic>) {
      normalized['alt_names'] = row['alt_names'];
    }
    if (row['metadata'] != null && row['metadata'] is! Map<String, dynamic>) {
      normalized['metadata'] = row['metadata'];
    }
    return HistoricalAdminUnit.fromJson(normalized);
  }

  LandAdminHistoryEntry _fromLandHistoryRow(Map<String, dynamic> row) {
    final normalized = Map<String, dynamic>.from(row);
    if (row['metadata'] != null && row['metadata'] is! Map<String, dynamic>) {
      normalized['metadata'] = row['metadata'];
    }
    return LandAdminHistoryEntry.fromJson(normalized);
  }
}