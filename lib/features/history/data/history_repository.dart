// lib/features/history/data/history_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/history_models.dart';

/// واجهة مجردة للوصول لبيانات التاريخ
abstract class IHistoryRepository {
  Future<List<HistoricalPeriod>> getPeriods();

  Future<HistoricalPeriod?> getPeriodById(int id);

  Future<List<HistoricalLayer>> getActiveLayersByPeriod(int periodId);

  Future<List<HistoricalMapSnapshot>> getSnapshotsByPeriod(int periodId);
}

class SupabaseHistoryRepository implements IHistoryRepository {
  SupabaseHistoryRepository(this._client);

  final SupabaseClient _client;

  static const _periodsTable = 'historical_periods';
  static const _layersTable = 'historical_layers';
  static const _snapshotsTable = 'historical_map_snapshots';

  @override
  Future<List<HistoricalPeriod>> getPeriods() async {
    final data = await _client
        .from(_periodsTable)
        .select()
        .order('order_index', ascending: true)
        .order('start_year', ascending: true);

    final list = List<Map<String, dynamic>>.from(data as List);
    return list.map(HistoricalPeriod.fromMap).toList();
  }

  @override
  Future<HistoricalPeriod?> getPeriodById(int id) async {
    final data = await _client
        .from(_periodsTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return HistoricalPeriod.fromMap(
      Map<String, dynamic>.from(data as Map),
    );
  }

  @override
  Future<List<HistoricalLayer>> getActiveLayersByPeriod(int periodId) async {
    final data = await _client
        .from(_layersTable)
        .select()
        .eq('period_id', periodId)
        .eq('is_active', true)
        .order('z_index', ascending: true);

    final list = List<Map<String, dynamic>>.from(data as List);
    return list.map(HistoricalLayer.fromMap).toList();
  }

  @override
  Future<List<HistoricalMapSnapshot>> getSnapshotsByPeriod(
      int periodId,
      ) async {
    final data = await _client
        .from(_snapshotsTable)
        .select()
        .eq('period_id', periodId)
        .order('id', ascending: true);

    final list = List<Map<String, dynamic>>.from(data as List);
    return list.map(HistoricalMapSnapshot.fromMap).toList();
  }
}
