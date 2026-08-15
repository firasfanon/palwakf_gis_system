import '../models/history_level_item.dart';
import '../models/history_overlay_feature.dart';
import '../models/history_period_item.dart';
import '../models/history_period_meta.dart';

abstract class HistoryExplorerRepository {
  Future<List<HistoryPeriodItem>> getPeriods();
  Future<HistoryPeriodMeta?> getPeriodMeta(int periodNo);
  Future<List<HistoryLevelItem>> getLevels(int periodNo);
  Future<List<HistoryOverlayFeature>> getOverlay({
    required int periodNo,
    String? levelKey,
  });
}
