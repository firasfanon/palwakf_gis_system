import '../../domain/models/history_level_item.dart';
import '../../domain/models/history_overlay_feature.dart';
import '../../domain/models/history_period_item.dart';
import '../../domain/models/history_period_meta.dart';
import '../../domain/repositories/history_explorer_repository.dart';
import '../datasources/history_explorer_remote_datasource.dart';
import '../mappers/history_level_mapper.dart';
import '../mappers/history_overlay_mapper.dart';
import '../mappers/history_period_mapper.dart';
import '../mappers/history_period_meta_mapper.dart';

class HistoryExplorerRepositoryImpl implements HistoryExplorerRepository {
  HistoryExplorerRepositoryImpl(this._remote);

  final HistoryExplorerRemoteDataSource _remote;

  @override
  Future<List<HistoryPeriodItem>> getPeriods() async {
    final rows = await _remote.fetchPeriods();
    final items = rows.map(HistoryPeriodMapper.fromRow).where((e) => e.periodNo > 0).toList();
    items.sort((a, b) => a.periodNo.compareTo(b.periodNo));
    return items;
  }

  @override
  Future<HistoryPeriodMeta?> getPeriodMeta(int periodNo) async {
    final row = await _remote.fetchPeriodMeta(periodNo);
    if (row == null) return null;
    return HistoryPeriodMetaMapper.fromRow(row);
  }

  @override
  Future<List<HistoryLevelItem>> getLevels(int periodNo) async {
    final rows = await _remote.fetchLevels(periodNo);
    final items = rows.map(HistoryLevelMapper.fromRow).where((e) => e.levelKey.isNotEmpty).toList();
    items.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return items;
  }

  @override
  Future<List<HistoryOverlayFeature>> getOverlay({
    required int periodNo,
    String? levelKey,
  }) async {
    final rows = await _remote.fetchOverlay(periodNo: periodNo, levelKey: levelKey);
    final seen = <String>{};
    final items = <HistoryOverlayFeature>[];
    for (final row in rows) {
      final item = HistoryOverlayMapper.fromRow(row);
      final dedupeKey = '${item.periodNo}|${item.sourceTable}|${item.sourceId}';
      if (!seen.add(dedupeKey)) continue;
      items.add(item);
    }
    items.sort((a, b) {
      final byOrder = a.displayOrder.compareTo(b.displayOrder);
      if (byOrder != 0) return byOrder;
      return a.displayLabel.compareTo(b.displayLabel);
    });
    return items;
  }
}
