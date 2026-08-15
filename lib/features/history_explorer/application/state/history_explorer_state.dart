import '../../domain/enums/history_explorer_mode.dart';
import '../../domain/enums/history_period_kind.dart';
import '../../domain/models/history_level_item.dart';
import '../../domain/models/history_modern_context.dart';
import '../../domain/models/history_overlay_feature.dart';
import '../../domain/models/history_resolved_context.dart';
import '../../domain/models/history_period_item.dart';
import '../../domain/models/history_period_meta.dart';
import '../../domain/models/history_waqf_asset_link.dart';
import '../../domain/models/waqf_asset_model.dart';

class HistoryExplorerState {
  final HistoryExplorerMode mode;
  final bool isLoading;
  final String? errorMessage;
  final List<HistoryPeriodItem> periods;
  final int? selectedPeriodNo;
  final HistoryPeriodMeta? periodMeta;
  final List<HistoryLevelItem> levels;
  final String? selectedLevelKey;
  final List<HistoryOverlayFeature> overlayFeatures;
  final String? selectedFeatureId;
  final String searchQuery;
  final bool showModernContext;
  final bool showWaqfAssets;
  final bool showLineage;
  final bool showLabels;
  final bool boundariesOnly;
  final bool isResolvingContext;
  final String? contextErrorMessage;
  final HistoryResolvedContext resolvedContext;
  final List<HistoryModernContext> modernSearchResults;
  final String? selectedModernContextCode;
  final List<HistoryWaqfAssetLink> waqfSearchResults;
  final String? selectedWaqfAssetId;
  final List<WaqfAssetModel> waqfAssetRecords;
  final String? selectedNationalAssetCode;
  final List<Map<String, dynamic>> linkedParcels;
  final String? selectedEndowmentFilter;
  final bool showParcels;
  final bool isSearchDebouncing;
  final int runtimeRequestToken;
  final String? runtimeMessage;

  const HistoryExplorerState({
    this.mode = HistoryExplorerMode.historical,
    this.isLoading = false,
    this.errorMessage,
    this.periods = const [],
    this.selectedPeriodNo,
    this.periodMeta,
    this.levels = const [],
    this.selectedLevelKey,
    this.overlayFeatures = const [],
    this.selectedFeatureId,
    this.searchQuery = '',
    this.showModernContext = false,
    this.showWaqfAssets = false,
    this.showLineage = true,
    this.showLabels = true,
    this.boundariesOnly = false,
    this.isResolvingContext = false,
    this.contextErrorMessage,
    this.resolvedContext = HistoryResolvedContext.empty,
    this.modernSearchResults = const [],
    this.selectedModernContextCode,
    this.waqfSearchResults = const [],
    this.selectedWaqfAssetId,
    this.waqfAssetRecords = const [],
    this.selectedNationalAssetCode,
    this.linkedParcels = const [],
    this.selectedEndowmentFilter,
    this.showParcels = false,
    this.isSearchDebouncing = false,
    this.runtimeRequestToken = 0,
    this.runtimeMessage,
  });

  HistoryExplorerState copyWith({
    HistoryExplorerMode? mode,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<HistoryPeriodItem>? periods,
    int? selectedPeriodNo,
    bool clearSelectedPeriod = false,
    HistoryPeriodMeta? periodMeta,
    bool clearPeriodMeta = false,
    List<HistoryLevelItem>? levels,
    String? selectedLevelKey,
    bool clearSelectedLevel = false,
    List<HistoryOverlayFeature>? overlayFeatures,
    String? selectedFeatureId,
    bool clearSelectedFeature = false,
    String? searchQuery,
    bool? showModernContext,
    bool? showWaqfAssets,
    bool? showLineage,
    bool? showLabels,
    bool? boundariesOnly,
    bool? isResolvingContext,
    String? contextErrorMessage,
    bool clearContextError = false,
    HistoryResolvedContext? resolvedContext,
    List<HistoryModernContext>? modernSearchResults,
    String? selectedModernContextCode,
    bool clearSelectedModernContext = false,
    List<HistoryWaqfAssetLink>? waqfSearchResults,
    String? selectedWaqfAssetId,
    bool clearSelectedWaqfAsset = false,
    List<WaqfAssetModel>? waqfAssetRecords,
    String? selectedNationalAssetCode,
    bool clearSelectedNationalAssetCode = false,
    List<Map<String, dynamic>>? linkedParcels,
    String? selectedEndowmentFilter,
    bool clearSelectedEndowmentFilter = false,
    bool? showParcels,
    bool? isSearchDebouncing,
    int? runtimeRequestToken,
    String? runtimeMessage,
    bool clearRuntimeMessage = false,
  }) {
    return HistoryExplorerState(
      mode: mode ?? this.mode,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      periods: periods ?? this.periods,
      selectedPeriodNo: clearSelectedPeriod ? null : (selectedPeriodNo ?? this.selectedPeriodNo),
      periodMeta: clearPeriodMeta ? null : (periodMeta ?? this.periodMeta),
      levels: levels ?? this.levels,
      selectedLevelKey: clearSelectedLevel ? null : (selectedLevelKey ?? this.selectedLevelKey),
      overlayFeatures: overlayFeatures ?? this.overlayFeatures,
      selectedFeatureId: clearSelectedFeature ? null : (selectedFeatureId ?? this.selectedFeatureId),
      searchQuery: searchQuery ?? this.searchQuery,
      showModernContext: showModernContext ?? this.showModernContext,
      showWaqfAssets: showWaqfAssets ?? this.showWaqfAssets,
      showLineage: showLineage ?? this.showLineage,
      showLabels: showLabels ?? this.showLabels,
      boundariesOnly: boundariesOnly ?? this.boundariesOnly,
      isResolvingContext: isResolvingContext ?? this.isResolvingContext,
      contextErrorMessage: clearContextError ? null : (contextErrorMessage ?? this.contextErrorMessage),
      resolvedContext: resolvedContext ?? this.resolvedContext,
      modernSearchResults: modernSearchResults ?? this.modernSearchResults,
      selectedModernContextCode: clearSelectedModernContext ? null : (selectedModernContextCode ?? this.selectedModernContextCode),
      waqfSearchResults: waqfSearchResults ?? this.waqfSearchResults,
      selectedWaqfAssetId: clearSelectedWaqfAsset ? null : (selectedWaqfAssetId ?? this.selectedWaqfAssetId),
      waqfAssetRecords: waqfAssetRecords ?? this.waqfAssetRecords,
      selectedNationalAssetCode: clearSelectedNationalAssetCode ? null : (selectedNationalAssetCode ?? this.selectedNationalAssetCode),
      linkedParcels: linkedParcels ?? this.linkedParcels,
      selectedEndowmentFilter: clearSelectedEndowmentFilter ? null : (selectedEndowmentFilter ?? this.selectedEndowmentFilter),
      showParcels: showParcels ?? this.showParcels,
      isSearchDebouncing: isSearchDebouncing ?? this.isSearchDebouncing,
      runtimeRequestToken: runtimeRequestToken ?? this.runtimeRequestToken,
      runtimeMessage: clearRuntimeMessage ? null : (runtimeMessage ?? this.runtimeMessage),
    );
  }

  HistoryPeriodItem? get selectedPeriod {
    final periodNo = selectedPeriodNo;
    if (periodNo == null) return null;
    for (final period in periods) {
      if (period.periodNo == periodNo) return period;
    }
    return null;
  }

  HistoryPeriodKind get selectedPeriodKind =>
      periodMeta?.periodKind ?? selectedPeriod?.periodKind ?? HistoryPeriodKind.unknown;

  bool get canDrawOverlay => selectedPeriodKind == HistoryPeriodKind.drawable;


  String? get selectedLevelLabel {
    final key = selectedLevelKey;
    if (key == null || key.trim().isEmpty) return null;
    for (final level in levels) {
      if (level.levelKey == key) {
        final ar = level.labelAr.trim();
        if (ar.isNotEmpty) return ar;
        final en = level.labelEn.trim();
        if (en.isNotEmpty) return en;
        return level.levelKey;
      }
    }
    return key;
  }

  HistoryOverlayFeature? get selectedFeature {
    final featureId = selectedFeatureId;
    if (featureId == null) return null;
    for (final feature in overlayFeatures) {
      if (feature.sourceId == featureId) return feature;
    }
    return null;
  }

  HistoryModernContext? get selectedModernContext {
    final code = selectedModernContextCode;
    if (code == null) return null;
    for (final item in modernSearchResults) {
      if (item.communityCode == code) return item;
    }
    for (final item in resolvedContext.modernContexts) {
      if (item.communityCode == code) return item;
    }
    return null;
  }

  WaqfAssetModel? get selectedWaqfAssetRecord {
    final id = selectedWaqfAssetId;
    final nationalCode = selectedNationalAssetCode;
    if (id == null && (nationalCode == null || nationalCode.trim().isEmpty)) return null;
    for (final item in waqfAssetRecords) {
      if ((id != null && item.waqfAssetId == id) ||
          (nationalCode != null && nationalCode.trim().isNotEmpty && item.nationalAssetCode == nationalCode)) {
        return item;
      }
    }
    return null;
  }

  HistoryWaqfAssetLink? get selectedWaqfAsset {
    final id = selectedWaqfAssetId;
    if (id == null) return null;
    for (final item in waqfSearchResults) {
      if (item.id == id || item.pwfKey == id) return item;
    }
    for (final item in resolvedContext.waqfAssets) {
      if (item.id == id || item.pwfKey == id) return item;
    }
    return null;
  }

  List<HistoryOverlayFeature> get filteredFeatures {
    if (mode != HistoryExplorerMode.historical) return overlayFeatures;
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return overlayFeatures;
    return overlayFeatures.where((feature) {
      return feature.displayLabel.toLowerCase().contains(query) ||
          (feature.entityCode ?? '').toLowerCase().contains(query) ||
          feature.sourceId.toLowerCase().contains(query);
    }).toList(growable: false);
  }
}
