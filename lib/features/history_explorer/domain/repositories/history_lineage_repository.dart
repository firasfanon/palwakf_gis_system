import '../models/history_modern_context.dart';
import '../models/history_overlay_feature.dart';
import '../models/history_resolved_context.dart';
import '../models/history_waqf_asset_link.dart';

abstract class HistoryLineageRepository {
  Future<HistoryResolvedContext> resolveContext({
    required int periodNo,
    required HistoryOverlayFeature feature,
  });

  Future<List<HistoryModernContext>> searchModernContexts({String? query});

  Future<HistoryResolvedContext> resolveContextFromModern({
    required HistoryModernContext context,
  });

  Future<List<HistoryWaqfAssetLink>> searchWaqfAssets({String? query});

  Future<HistoryResolvedContext> resolveContextFromWaqf({
    required HistoryWaqfAssetLink asset,
  });
}
