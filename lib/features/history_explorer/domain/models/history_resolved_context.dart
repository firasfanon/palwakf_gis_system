import 'history_lineage_node.dart';
import 'history_modern_context.dart';
import 'history_waqf_asset_link.dart';

class HistoryResolvedContext {
  final String? matchedUnitCode;
  final int? matchedUnitPeriodId;
  final List<HistoryLineageNode> lineageNodes;
  final List<HistoryModernContext> modernContexts;
  final List<HistoryWaqfAssetLink> waqfAssets;
  final String? note;
  final String resolutionMethod;
  final bool isSovereign;

  const HistoryResolvedContext({
    this.matchedUnitCode,
    this.matchedUnitPeriodId,
    this.lineageNodes = const [],
    this.modernContexts = const [],
    this.waqfAssets = const [],
    this.note,
    this.resolutionMethod = 'fallback_matching',
    this.isSovereign = false,
  });

  static const empty = HistoryResolvedContext();

  bool get hasAnyData =>
      lineageNodes.isNotEmpty || modernContexts.isNotEmpty || waqfAssets.isNotEmpty || matchedUnitCode != null;

  HistoryResolvedContext copyWith({
    String? matchedUnitCode,
    int? matchedUnitPeriodId,
    List<HistoryLineageNode>? lineageNodes,
    List<HistoryModernContext>? modernContexts,
    List<HistoryWaqfAssetLink>? waqfAssets,
    String? note,
    bool clearNote = false,
    String? resolutionMethod,
    bool? isSovereign,
  }) {
    return HistoryResolvedContext(
      matchedUnitCode: matchedUnitCode ?? this.matchedUnitCode,
      matchedUnitPeriodId: matchedUnitPeriodId ?? this.matchedUnitPeriodId,
      lineageNodes: lineageNodes ?? this.lineageNodes,
      modernContexts: modernContexts ?? this.modernContexts,
      waqfAssets: waqfAssets ?? this.waqfAssets,
      note: clearNote ? null : (note ?? this.note),
      resolutionMethod: resolutionMethod ?? this.resolutionMethod,
      isSovereign: isSovereign ?? this.isSovereign,
    );
  }
}
