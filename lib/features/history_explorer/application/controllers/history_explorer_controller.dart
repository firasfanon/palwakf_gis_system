import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums/history_explorer_mode.dart';
import '../../domain/models/history_level_item.dart';
import '../../domain/models/history_modern_context.dart';
import '../../domain/models/history_overlay_feature.dart';
import '../../../waqf/domain/models/endowment_reference.dart';
import '../../../waqf/domain/repositories/waqf_reference_repository.dart';
import '../../domain/models/history_waqf_asset_link.dart';
import '../../domain/models/waqf_asset_model.dart';
import '../../domain/repositories/history_explorer_repository.dart';
import '../../domain/repositories/history_lineage_repository.dart';
import '../../data/repositories/waqf_asset_repository_impl.dart';
import '../../domain/models/history_resolved_context.dart';
import '../state/history_explorer_state.dart';

class HistoryExplorerController extends StateNotifier<HistoryExplorerState> {
  HistoryExplorerController(
    this._repository,
    this._lineageRepository,
    this._waqfReferenceRepository,
    this._waqfAssetRepository,
  ) : super(const HistoryExplorerState()) {
    initialize();
  }

  final HistoryExplorerRepository _repository;
  final HistoryLineageRepository _lineageRepository;
  final WaqfReferenceRepository _waqfReferenceRepository;
  final WaqfAssetRepositoryImpl _waqfAssetRepository;

  Timer? _searchDebounce;
  int _runtimeRequestSeq = 0;

  int _nextRuntimeRequestToken() => ++_runtimeRequestSeq;

  bool _isStaleRuntimeRequest(int token) => token != _runtimeRequestSeq;

  void _cancelPendingSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = null;
  }

  
  void dispose() {
    _cancelPendingSearch();
    super.dispose();
  }

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final periods = await _repository.getPeriods();
      if (periods.isEmpty) {
        state = state.copyWith(
          periods: const [],
          isLoading: false,
          errorMessage: 'لم يتم العثور على فترات تاريخية في المصدر السيادي.',
        );
        return;
      }

      state = state.copyWith(periods: periods, isLoading: false);

      final preferred = periods.firstWhere(
        (p) => p.periodKind.name == 'drawable' && p.isEnabled,
        orElse: () => periods.firstWhere((p) => p.isEnabled, orElse: () => periods.first),
      );
      await selectPeriod(preferred.periodNo);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر تحميل الفترات التاريخية: $e',
      );
    }
  }

  Future<void> selectMode(HistoryExplorerMode mode) async {
    _cancelPendingSearch();
    final requestToken = _nextRuntimeRequestToken();
    final normalizedQuery = state.searchQuery.trim();
    state = state.copyWith(
      mode: mode,
      searchQuery: mode == HistoryExplorerMode.historical ? normalizedQuery : normalizedQuery,
      clearSelectedFeature: mode != HistoryExplorerMode.historical,
      clearSelectedModernContext: mode != HistoryExplorerMode.modern,
      clearSelectedWaqfAsset: mode != HistoryExplorerMode.waqf,
      resolvedContext: HistoryResolvedContext.empty,
      clearContextError: true,
      isResolvingContext: false,
      showModernContext: mode == HistoryExplorerMode.modern ? true : state.showModernContext,
      showWaqfAssets: mode == HistoryExplorerMode.waqf ? true : state.showWaqfAssets,
    );

    switch (mode) {
      case HistoryExplorerMode.historical:
        await _activateHistoricalSelectionIfPossible();
        return;
      case HistoryExplorerMode.modern:
        await _loadModernContexts(requestToken: requestToken);
        return;
      case HistoryExplorerMode.waqf:
        await _loadWaqfAssets(requestToken: requestToken);
        return;
    }
  }

  Future<void> selectPeriod(int periodNo) async {
    _cancelPendingSearch();
    _nextRuntimeRequestToken();
    state = state.copyWith(
      mode: HistoryExplorerMode.historical,
      isLoading: true,
      clearError: true,
      selectedPeriodNo: periodNo,
      clearSelectedFeature: true,
      clearSelectedModernContext: true,
      clearSelectedWaqfAsset: true,
      overlayFeatures: const [],
      resolvedContext: HistoryResolvedContext.empty,
      isResolvingContext: false,
      clearContextError: true,
      levels: const [],
      clearSelectedLevel: true,
      clearPeriodMeta: true,
    );

    try {
      final meta = await _repository.getPeriodMeta(periodNo);
      final levels = await _repository.getLevels(periodNo);

      final selectedLevel = _resolveDefaultLevel(levels, meta?.defaultLevelKey);
      state = state.copyWith(
        periodMeta: meta,
        levels: levels,
        selectedLevelKey: selectedLevel,
      );

      if ((meta?.periodKind.name == 'drawable') && selectedLevel != null) {
        final overlay = await _repository.getOverlay(
          periodNo: periodNo,
          levelKey: selectedLevel,
        );
        state = state.copyWith(
          overlayFeatures: overlay,
          isLoading: false,
        );
        await _activateHistoricalSelectionIfPossible();
      } else {
        state = state.copyWith(overlayFeatures: const [], isLoading: false);
        await _activateHistoricalSelectionIfPossible();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر تحميل بيانات الفترة المختارة: $e',
      );
    }
  }

  Future<void> selectLevel(String? levelKey) async {
    _cancelPendingSearch();
    _nextRuntimeRequestToken();
    final periodNo = state.selectedPeriodNo;
    if (periodNo == null || levelKey == null || levelKey.trim().isEmpty) return;

    state = state.copyWith(
      mode: HistoryExplorerMode.historical,
      isLoading: true,
      clearError: true,
      selectedLevelKey: levelKey,
      clearSelectedFeature: true,
      clearSelectedModernContext: true,
      clearSelectedWaqfAsset: true,
      overlayFeatures: const [],
      resolvedContext: HistoryResolvedContext.empty,
      isResolvingContext: false,
      clearContextError: true,
    );

    try {
      final overlay = await _repository.getOverlay(periodNo: periodNo, levelKey: levelKey);
      state = state.copyWith(
        overlayFeatures: overlay,
        isLoading: false,
      );
      await _activateHistoricalSelectionIfPossible();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر تحميل الطبقة المكانية: $e',
      );
    }
  }

  Future<void> selectFeature(String? sourceId) async {
    state = state.copyWith(
      selectedFeatureId: sourceId,
      clearSelectedFeature: sourceId == null,
      clearSelectedModernContext: true,
      clearSelectedWaqfAsset: true,
      resolvedContext: HistoryResolvedContext.empty,
      isResolvingContext: false,
      clearContextError: true,
    );

    if (sourceId == null) return;
    final selected = state.selectedFeature;
    final periodNo = state.selectedPeriodNo;
    if (selected == null || periodNo == null) return;

    state = state.copyWith(isResolvingContext: true, clearContextError: true);
    try {
      final context = await _lineageRepository.resolveContext(periodNo: periodNo, feature: selected);
      state = state.copyWith(
        isResolvingContext: false,
        resolvedContext: context,
      );
    } catch (e) {
      state = state.copyWith(
        isResolvingContext: false,
        contextErrorMessage: 'تعذر تحليل السلالة والربط الحديث/الوقفي: $e',
      );
    }
  }

  Future<void> setSearchQuery(String value) async {
    final requestToken = _nextRuntimeRequestToken();
    state = state.copyWith(
      searchQuery: value,
      isSearchDebouncing: true,
      runtimeRequestToken: requestToken,
      runtimeMessage: 'جاري تجهيز البحث دون إعادة تحميل فوري...',
    );

    _cancelPendingSearch();
    _searchDebounce = Timer(const Duration(milliseconds: 420), () async {
      if (_isStaleRuntimeRequest(requestToken)) return;
      state = state.copyWith(
        isSearchDebouncing: false,
        runtimeMessage: 'تم تنفيذ آخر طلب بحث مع تجاهل الطلبات القديمة.',
      );
      switch (state.mode) {
        case HistoryExplorerMode.historical:
          await _activateHistoricalSelectionIfPossible();
          return;
        case HistoryExplorerMode.modern:
          await _loadModernContexts(requestToken: requestToken);
          return;
        case HistoryExplorerMode.waqf:
          await _loadWaqfAssets(requestToken: requestToken);
          return;
      }
    });
  }

  Future<void> selectModernContext(String? communityCode) async {
    _cancelPendingSearch();
    _nextRuntimeRequestToken();
    HistoryModernContext? selected;
    if (communityCode != null) {
      for (final item in state.modernSearchResults) {
        if (item.communityCode == communityCode) {
          selected = item;
          break;
        }
      }
      selected ??= state.selectedModernContext;
      if (selected == null) {
        for (final item in state.resolvedContext.modernContexts) {
          if (item.communityCode == communityCode) {
            selected = item;
            break;
          }
        }
      }
    }

    state = state.copyWith(
      mode: HistoryExplorerMode.modern,
      selectedModernContextCode: communityCode,
      clearSelectedModernContext: communityCode == null,
      clearSelectedFeature: true,
      clearSelectedWaqfAsset: true,
      resolvedContext: HistoryResolvedContext.empty,
      isResolvingContext: false,
      clearContextError: true,
      showModernContext: communityCode != null ? true : state.showModernContext,
    );
    if (communityCode == null || selected == null) return;

    state = state.copyWith(isResolvingContext: true, clearContextError: true);
    try {
      final context = await _lineageRepository.resolveContextFromModern(context: selected);
      state = state.copyWith(isResolvingContext: false, resolvedContext: context);
    } catch (e) {
      state = state.copyWith(
        isResolvingContext: false,
        contextErrorMessage: 'تعذر تحليل الجذر التاريخي للمرجع الحديث: $e',
      );
    }
  }

  Future<void> selectWaqfAsset(String? assetId) async {
    _cancelPendingSearch();
    _nextRuntimeRequestToken();
    HistoryWaqfAssetLink? selected;
    WaqfAssetModel? selectedRecord;
    if (assetId != null) {
      for (final item in state.waqfSearchResults) {
        if (item.id == assetId || item.pwfKey == assetId) {
          selected = item;
          break;
        }
      }
      selected ??= state.selectedWaqfAsset;
      if (selected == null) {
        for (final item in state.resolvedContext.waqfAssets) {
          if (item.id == assetId || item.pwfKey == assetId) {
            selected = item;
            break;
          }
        }
      }
      for (final item in state.waqfAssetRecords) {
        if (item.waqfAssetId == assetId || item.nationalAssetCode == assetId) {
          selectedRecord = item;
          break;
        }
      }
      selectedRecord ??= state.selectedWaqfAssetRecord;
      selected ??= selectedRecord != null ? _mapRecordToWaqfAssetLink(selectedRecord) : null;
    }

    state = state.copyWith(
      mode: HistoryExplorerMode.waqf,
      selectedWaqfAssetId: assetId,
      clearSelectedWaqfAsset: assetId == null,
      clearSelectedFeature: true,
      clearSelectedModernContext: true,
      resolvedContext: HistoryResolvedContext.empty,
      isResolvingContext: false,
      clearContextError: true,
      showModernContext: assetId != null ? true : state.showModernContext,
      showWaqfAssets: assetId != null ? true : state.showWaqfAssets,
      linkedParcels: assetId == null ? const [] : state.linkedParcels,
      selectedNationalAssetCode: selectedRecord?.nationalAssetCode,
      clearSelectedNationalAssetCode: assetId == null,
    );
    if (assetId == null || selected == null) return;

    final selectedAsset = selected;

    try {
      final details = await _waqfAssetRepository.getAssetDetails(
        waqfAssetId: selectedRecord?.waqfAssetId ?? selectedAsset.id,
        nationalAssetCode: selectedRecord?.nationalAssetCode.isNotEmpty == true
            ? selectedRecord!.nationalAssetCode
            : selectedAsset.pwfKey,
      );
      final linkedParcels = await _waqfAssetRepository.getLinkedParcels(
        waqfAssetId: details?.waqfAssetId ?? selectedRecord?.waqfAssetId ?? selectedAsset.id,
        nationalAssetCode: details?.nationalAssetCode ?? selectedRecord?.nationalAssetCode ?? selectedAsset.pwfKey,
      );
      final nextRecord = details ?? selectedRecord;
      final nextRecords = _mergeWaqfAssetRecords(state.waqfAssetRecords, nextRecord);
      final nextSelected = nextRecord != null ? _mapRecordToWaqfAssetLink(nextRecord) : selectedAsset;
      state = state.copyWith(
        waqfAssetRecords: nextRecords,
        linkedParcels: linkedParcels,
        selectedNationalAssetCode: nextRecord?.nationalAssetCode ?? selectedAsset.pwfKey,
        waqfSearchResults: _mergeWaqfSearchResults(state.waqfSearchResults, nextSelected),
      );
      selected = nextSelected;
    } catch (_) {
      // Keep the current selection flow even if sovereign details are unavailable.
    }

    state = state.copyWith(isResolvingContext: true, clearContextError: true);
    try {
      final context = await _lineageRepository.resolveContextFromWaqf(asset: selected ?? selectedAsset);
      state = state.copyWith(isResolvingContext: false, resolvedContext: context);
    } catch (e) {
      state = state.copyWith(
        isResolvingContext: false,
        contextErrorMessage: 'تعذر تحليل الجذر التاريخي للأصل الوقفي: $e',
      );
    }
  }

  void inspectModernContext(String? communityCode) {
    state = state.copyWith(
      mode: communityCode != null ? HistoryExplorerMode.modern : state.mode,
      selectedModernContextCode: communityCode,
      clearSelectedModernContext: communityCode == null,
      clearSelectedFeature: communityCode != null,
      showModernContext: communityCode != null ? true : state.showModernContext,
    );
  }

  void inspectWaqfAsset(String? assetId) {
    state = state.copyWith(
      mode: assetId != null ? HistoryExplorerMode.waqf : state.mode,
      selectedWaqfAssetId: assetId,
      clearSelectedWaqfAsset: assetId == null,
      clearSelectedFeature: assetId != null,
      showWaqfAssets: assetId != null ? true : state.showWaqfAssets,
      showModernContext: assetId != null ? true : state.showModernContext,
    );
  }

  void toggleModernContext() {
    state = state.copyWith(showModernContext: !state.showModernContext);
  }

  void toggleWaqfAssets() {
    state = state.copyWith(showWaqfAssets: !state.showWaqfAssets);
  }

  void toggleParcels() {
    state = state.copyWith(showParcels: !state.showParcels);
  }

  void toggleLineage() {
    state = state.copyWith(showLineage: !state.showLineage);
  }

  void toggleLabels() {
    state = state.copyWith(showLabels: !state.showLabels);
  }

  void toggleBoundariesOnly() {
    state = state.copyWith(boundariesOnly: !state.boundariesOnly);
  }

  Future<void> _loadModernContexts({int? requestToken}) async {
    final token = requestToken ?? _nextRuntimeRequestToken();
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      runtimeRequestToken: token,
      runtimeMessage: 'تحميل نتائج المرجع الحديث ضمن الطلب الحالي...',
    );
    try {
      final results = await _lineageRepository.searchModernContexts(query: state.searchQuery);
      if (_isStaleRuntimeRequest(token)) return;
      final currentSelectedCode = state.selectedModernContextCode;
      final hasCurrent = currentSelectedCode != null &&
          results.any((item) => item.communityCode == currentSelectedCode);
      final preferred = _pickPreferredModernContext(state.searchQuery, results);
      final nextSelectedCode = hasCurrent
          ? currentSelectedCode
          : (preferred != null ? preferred.communityCode : null);

      state = state.copyWith(
        modernSearchResults: results,
        isLoading: false,
        selectedModernContextCode: nextSelectedCode,
        clearSelectedModernContext: results.isEmpty,
        isSearchDebouncing: false,
        runtimeMessage: 'تم تحديث نتائج المستكشف الحديث.',
      );

      if (!hasCurrent && preferred != null) {
        await selectModernContext(preferred.communityCode);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSearchDebouncing: false,
        errorMessage: 'تعذر تحميل الوحدات الحديثة: $e',
      );
    }
  }

  Future<void> _loadWaqfAssets({int? requestToken}) async {
    final token = requestToken ?? _nextRuntimeRequestToken();
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      runtimeRequestToken: token,
      runtimeMessage: 'تحميل نتائج مستكشف الوقف ضمن الطلب الحالي...',
    );
    try {
      final query = state.searchQuery.trim();
      final results = <HistoryWaqfAssetLink>[];
      final records = <WaqfAssetModel>[];
      final seen = <String>{};

      final sovereign = await _waqfAssetRepository.searchByNameOrNationalCode(
        query: query.isEmpty ? null : query,
        limit: query.isEmpty ? 60 : 120,
        endowmentName: state.selectedEndowmentFilter,
      );
      if (_isStaleRuntimeRequest(token)) return;
      for (final item in sovereign) {
        final identity = item.waqfAssetId.trim().isNotEmpty ? item.waqfAssetId.trim() : item.nationalAssetCode.trim();
        if (identity.isEmpty || !seen.add(identity)) continue;
        records.add(item);
        results.add(_mapRecordToWaqfAssetLink(item));
      }

      if (results.isEmpty) {
        final direct = await _waqfReferenceRepository.searchEndowments(
          query: query.isEmpty ? null : query,
          limit: query.isEmpty ? 60 : 120,
        );
        if (_isStaleRuntimeRequest(token)) return;
        for (final item in direct) {
          final mapped = _mapReferenceToWaqfAsset(item);
          final identity = mapped.id.trim().isNotEmpty ? mapped.id.trim() : mapped.pwfKey.trim();
          if (identity.isEmpty || !seen.add(identity)) continue;
          results.add(mapped);
        }
      }

      if (results.isEmpty) {
        final fallback = await _lineageRepository.searchWaqfAssets(query: state.searchQuery);
        if (_isStaleRuntimeRequest(token)) return;
        for (final item in fallback) {
          final identity = item.id.trim().isNotEmpty ? item.id.trim() : item.pwfKey.trim();
          if (identity.isEmpty || !seen.add(identity)) continue;
          results.add(item);
        }
      }

      HistoryWaqfAssetLink? preferred;
      if (query.isNotEmpty) {
        preferred = _pickPreferredWaqfAsset(query, results);
      }

      final currentSelectedId = state.selectedWaqfAssetId;
      final hasCurrent = currentSelectedId != null &&
          results.any((item) => item.id == currentSelectedId || item.pwfKey == currentSelectedId);

      final nextSelectedId = hasCurrent
          ? currentSelectedId
          : (preferred != null ? preferred.id : null);
      final nextSelectedCode = (() {
        if (hasCurrent) return state.selectedNationalAssetCode;
        if (preferred != null) return preferred.pwfKey;
        return null;
      })();

      state = state.copyWith(
        waqfSearchResults: results,
        waqfAssetRecords: records,
        isLoading: false,
        selectedWaqfAssetId: nextSelectedId,
        selectedNationalAssetCode: nextSelectedCode,
        clearSelectedWaqfAsset: results.isEmpty,
        clearSelectedNationalAssetCode: results.isEmpty,
        isSearchDebouncing: false,
        runtimeMessage: 'تم تحديث نتائج مستكشف الوقف.',
      );

      if (!hasCurrent && preferred != null) {
        await selectWaqfAsset(preferred.id);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSearchDebouncing: false,
        errorMessage: 'تعذر تحميل الأصول الوقفية: $e',
      );
    }
  }

  Future<void> applyEndowmentFilter(String? endowmentName) async {
    final normalized = endowmentName?.trim();
    state = state.copyWith(
      selectedEndowmentFilter: (normalized == null || normalized.isEmpty) ? null : normalized,
      clearSelectedEndowmentFilter: normalized == null || normalized.isEmpty,
    );
    if (state.mode == HistoryExplorerMode.waqf) {
      await _loadWaqfAssets();
    }
  }

  Future<void> refreshCurrentMode() async {
    switch (state.mode) {
      case HistoryExplorerMode.historical:
        final periodNo = state.selectedPeriodNo;
        if (periodNo != null) {
          await selectPeriod(periodNo);
        }
        return;
      case HistoryExplorerMode.modern:
        await _loadModernContexts();
        return;
      case HistoryExplorerMode.waqf:
        await _loadWaqfAssets();
        return;
    }
  }



  Future<void> _activateHistoricalSelectionIfPossible() async {
    if (state.mode != HistoryExplorerMode.historical) return;
    final query = state.searchQuery.trim();
    final features = state.filteredFeatures;

    if (features.isEmpty) {
      if (state.selectedFeatureId != null || state.resolvedContext.hasAnyData) {
        state = state.copyWith(
          clearSelectedFeature: true,
          resolvedContext: HistoryResolvedContext.empty,
          isResolvingContext: false,
          clearContextError: true,
        );
      }
      return;
    }

    if (query.isEmpty) return;

    final currentSelectedId = state.selectedFeatureId;
    final hasCurrent = currentSelectedId != null && features.any((item) => item.sourceId == currentSelectedId);
    final preferred = _pickPreferredHistoricalFeature(query, features);
    final nextSelectedId = hasCurrent ? currentSelectedId : preferred?.sourceId;

    if (nextSelectedId == null) return;
    if (hasCurrent && state.resolvedContext.hasAnyData) return;

    await selectFeature(nextSelectedId);
  }

  HistoryModernContext? _pickPreferredModernContext(String query, List<HistoryModernContext> items) {
    if (items.isEmpty) return null;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return items.length == 1 ? items.first : null;
    }

    for (final item in items) {
      final values = <String>[
        item.communityCode,
        item.communityLabel,
        item.lguCode ?? '',
        item.lguLabel ?? '',
        item.governorateCode ?? '',
        item.governorateLabel ?? '',
      ].map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList(growable: false);
      if (values.any((value) => value == q)) return item;
    }

    for (final item in items) {
      final values = <String>[
        item.communityCode,
        item.communityLabel,
        item.lguCode ?? '',
        item.lguLabel ?? '',
        item.governorateCode ?? '',
        item.governorateLabel ?? '',
      ].map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList(growable: false);
      if (values.any((value) => value.contains(q))) return item;
    }

    return items.first;
  }

  HistoryOverlayFeature? _pickPreferredHistoricalFeature(String query, List<HistoryOverlayFeature> items) {
    if (items.isEmpty) return null;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items.length == 1 ? items.first : null;

    for (final item in items) {
      final values = <String>[
        item.displayLabel,
        item.sourceId,
        item.entityCode ?? '',
        item.parentSourceId ?? '',
        item.levelKey ?? '',
      ].map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList(growable: false);
      if (values.any((value) => value == q)) return item;
    }

    for (final item in items) {
      final values = <String>[
        item.displayLabel,
        item.sourceId,
        item.entityCode ?? '',
        item.parentSourceId ?? '',
        item.levelKey ?? '',
      ].map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList(growable: false);
      if (values.any((value) => value.contains(q))) return item;
    }

    return items.first;
  }

  HistoryWaqfAssetLink _mapRecordToWaqfAssetLink(WaqfAssetModel item) {
    return HistoryWaqfAssetLink(
      id: item.waqfAssetId.trim().isNotEmpty ? item.waqfAssetId : item.nationalAssetCode,
      pwfKey: item.nationalAssetCode.trim().isNotEmpty ? item.nationalAssetCode : item.waqfAssetId,
      name: item.nameAr.trim().isEmpty ? null : item.nameAr.trim(),
      governorate: item.currentGovernorate?.trim().isEmpty == true ? null : item.currentGovernorate?.trim(),
      community: item.communityName?.trim().isEmpty == true ? null : item.communityName?.trim(),
      municipality: item.currentLgu?.trim().isEmpty == true ? null : item.currentLgu?.trim(),
      area: null,
      typeLabel: item.assetType?.trim().isEmpty == true ? null : item.assetType?.trim(),
      categoryLabel: item.endowmentName?.trim().isEmpty == true ? null : item.endowmentName?.trim(),
      endowerName: null,
      statusLabel: item.status?.trim().isEmpty == true ? null : item.status?.trim(),
      purpose: item.usage?.trim().isEmpty == true ? null : item.usage?.trim(),
      centerLat: item.centerLat,
      centerLng: item.centerLng,
      geomJson: item.geomJson,
      centroidJson: item.centroidJson,
    );
  }

  List<WaqfAssetModel> _mergeWaqfAssetRecords(List<WaqfAssetModel> current, WaqfAssetModel? next) {
    if (next == null) return current;
    final merged = <WaqfAssetModel>[];
    final seen = <String>{};
    final nextKey = next.waqfAssetId.trim().isNotEmpty ? next.waqfAssetId.trim() : next.nationalAssetCode.trim();
    if (nextKey.isNotEmpty) {
      merged.add(next);
      seen.add(nextKey);
    }
    for (final item in current) {
      final key = item.waqfAssetId.trim().isNotEmpty ? item.waqfAssetId.trim() : item.nationalAssetCode.trim();
      if (key.isEmpty || !seen.add(key)) continue;
      merged.add(item);
    }
    return merged;
  }

  List<HistoryWaqfAssetLink> _mergeWaqfSearchResults(List<HistoryWaqfAssetLink> current, HistoryWaqfAssetLink next) {
    final merged = <HistoryWaqfAssetLink>[next];
    final seen = <String>{};
    final nextKey = next.id.trim().isNotEmpty ? next.id.trim() : next.pwfKey.trim();
    if (nextKey.isNotEmpty) seen.add(nextKey);
    for (final item in current) {
      final key = item.id.trim().isNotEmpty ? item.id.trim() : item.pwfKey.trim();
      if (key.isEmpty || !seen.add(key)) continue;
      merged.add(item);
    }
    return merged;
  }

  HistoryWaqfAssetLink _mapReferenceToWaqfAsset(EndowmentReference item) {
    final sourceId = item.id.trim();
    final key = item.nationalId.trim().isNotEmpty ? item.nationalId.trim() : sourceId;
    final location = item.cityName?.trim();
    return HistoryWaqfAssetLink(
      id: sourceId.isNotEmpty ? sourceId : key,
      pwfKey: key.isNotEmpty ? key : (sourceId.isNotEmpty ? sourceId : '—'),
      name: item.displayName,
      governorate: item.governorateName?.trim().isEmpty == true ? null : item.governorateName?.trim(),
      community: location?.isEmpty == true ? null : location,
      municipality: location?.isEmpty == true ? null : location,
      area: item.totalArea,
      typeLabel: item.type?.trim().isEmpty == true ? null : item.type?.trim(),
      categoryLabel: item.category?.trim().isEmpty == true ? null : item.category?.trim(),
      endowerName: item.endowerName?.trim().isEmpty == true ? null : item.endowerName?.trim(),
      statusLabel: item.status?.trim().isEmpty == true ? null : item.status?.trim(),
      purpose: item.purpose?.trim().isEmpty == true ? item.historicalNotes?.trim() : item.purpose?.trim(),
      centerLat: item.latitude,
      centerLng: item.longitude,
    );
  }

  HistoryWaqfAssetLink? _pickPreferredWaqfAsset(String query, List<HistoryWaqfAssetLink> items) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty || items.isEmpty) return null;
    for (final item in items) {
      final values = <String>[
        item.id,
        item.pwfKey,
        item.displayLabel,
        item.community ?? '',
        item.municipality ?? '',
        item.governorate ?? '',
        item.typeLabel ?? '',
        item.statusLabel ?? '',
      ].map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty);
      if (values.any((value) => value == q || value.startsWith(q))) {
        return item;
      }
    }
    return items.first;
  }

  String? _resolveDefaultLevel(List<HistoryLevelItem> levels, String? preferred) {
    if (levels.isEmpty) return null;
    if (preferred != null && preferred.trim().isNotEmpty) {
      for (final level in levels) {
        if (level.levelKey == preferred.trim()) return level.levelKey;
      }
    }
    for (final level in levels) {
      if (level.isDefault) return level.levelKey;
    }
    return levels.first.levelKey;
  }
}
