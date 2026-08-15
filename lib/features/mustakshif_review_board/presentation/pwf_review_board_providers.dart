import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/pwf_local_review_draft_store.dart';
import '../data/pwf_review_board_repository.dart';
import '../data/pwf_real_map_hook_contract.dart';
import '../data/pwf_supabase_review_board_repository.dart';
import '../domain/pwf_review_enums.dart';
import '../domain/pwf_review_record.dart';
import '../domain/pwf_source_locator.dart';

const Object _pwfUnset = Object();

const String _pwfRuntimeBackend = String.fromEnvironment(
  'PWF_MUSTAKSHIF_REVIEW_BOARD_BACKEND',
  defaultValue: 'csv_seed',
);

enum PwfReviewBoardRuntimeBackend {
  csvSeed,
  supabaseStaging,
}

extension PwfReviewBoardRuntimeBackendX on PwfReviewBoardRuntimeBackend {
  String get labelAr => switch (this) {
        PwfReviewBoardRuntimeBackend.supabaseStaging => 'Supabase staging',
        PwfReviewBoardRuntimeBackend.csvSeed => 'CSV seed + local drafts',
      };

  bool get isSupabase => this == PwfReviewBoardRuntimeBackend.supabaseStaging;
}

final pwfReviewBoardRuntimeBackendProvider =
    Provider<PwfReviewBoardRuntimeBackend>((ref) {
  return _pwfRuntimeBackend.trim().toLowerCase() == 'supabase_staging'
      ? PwfReviewBoardRuntimeBackend.supabaseStaging
      : PwfReviewBoardRuntimeBackend.csvSeed;
});

final pwfStagingReviewBoardRepositoryProvider =
    Provider<PwfStagingReviewBoardRepository>((ref) {
  return PwfSupabaseReviewBoardRepository(Supabase.instance.client);
});

final pwfReviewBoardRepositoryProvider =
    Provider<PwfReviewBoardRepository>((ref) {
  final backend = ref.watch(pwfReviewBoardRuntimeBackendProvider);
  if (backend.isSupabase)
    return ref.watch(pwfStagingReviewBoardRepositoryProvider);
  return const PwfCsvSeedReviewBoardRepository();
});

final pwfLocalReviewDraftStoreProvider =
    Provider<PwfLocalReviewDraftStore>((ref) {
  return const PwfLocalReviewDraftStore();
});

final pwfReviewBoardControllerProvider =
    StateNotifierProvider<PwfReviewBoardController, PwfReviewBoardState>((ref) {
  final repository = ref.watch(pwfReviewBoardRepositoryProvider);
  final stagingRepository = ref.watch(pwfStagingReviewBoardRepositoryProvider);
  final backend = ref.watch(pwfReviewBoardRuntimeBackendProvider);
  final draftStore = ref.watch(pwfLocalReviewDraftStoreProvider);
  return PwfReviewBoardController(
    repository,
    draftStore,
    stagingRepository,
    runtimeBackend: backend,
  )..load();
});

class PwfReviewBoardState {
  const PwfReviewBoardState({
    required this.records,
    required this.isLoading,
    required this.query,
    required this.selectedQueueCode,
    required this.selectedStatus,
    required this.selectedGateCode,
    required this.selectedSortCode,
    required this.showLocalDraftsOnly,
    required this.selectedRecordId,
    required this.localDraftRecordIds,
    this.localDraftHealthLabel,
    this.lastSaveVerificationLine,
    this.lastExportVerificationLine,
    this.stagingDiagnostics,
    this.isStagingBusy = false,
    this.stagingMessage,
    this.stagingLastRpcLine,
    this.stagingErrorMessage,
    this.runtimeBackend = PwfReviewBoardRuntimeBackend.csvSeed,
    this.errorMessage,
    this.persistenceMessage,
    this.lastPersistedAt,
  });

  factory PwfReviewBoardState.initial() {
    return const PwfReviewBoardState(
      records: [],
      isLoading: true,
      query: '',
      selectedQueueCode: 'all',
      selectedStatus: 'all',
      selectedGateCode: 'all',
      selectedSortCode: 'risk_desc',
      showLocalDraftsOnly: false,
      selectedRecordId: null,
      localDraftRecordIds: <String>{},
    );
  }

  final List<PwfReviewRecord> records;
  final bool isLoading;
  final String query;
  final String selectedQueueCode;
  final String selectedStatus;
  final String selectedGateCode;
  final String selectedSortCode;
  final bool showLocalDraftsOnly;
  final String? selectedRecordId;
  final Set<String> localDraftRecordIds;
  final String? localDraftHealthLabel;
  final String? lastSaveVerificationLine;
  final String? lastExportVerificationLine;
  final PwfReviewBoardAccessDiagnostics? stagingDiagnostics;
  final bool isStagingBusy;
  final String? stagingMessage;
  final String? stagingLastRpcLine;
  final String? stagingErrorMessage;
  final PwfReviewBoardRuntimeBackend runtimeBackend;
  final String? errorMessage;
  final String? persistenceMessage;
  final DateTime? lastPersistedAt;

  List<PwfReviewRecord> get filteredRecords {
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = records.where((record) {
      final queueMatches =
          selectedQueueCode == 'all' || record.queueCode == selectedQueueCode;
      final statusMatches =
          selectedStatus == 'all' || record.reviewStatus == selectedStatus;
      final gateMatches = selectedGateCode == 'all' ||
          record.operationalGateCode == selectedGateCode;
      final draftMatches =
          !showLocalDraftsOnly || localDraftRecordIds.contains(record.id);
      final queryMatches = normalizedQuery.isEmpty ||
          record.id.toLowerCase().contains(normalizedQuery) ||
          record.placeNameAr.toLowerCase().contains(normalizedQuery) ||
          record.currentCandidateAr.toLowerCase().contains(normalizedQuery) ||
          record.periodLabelAr.toLowerCase().contains(normalizedQuery) ||
          record.adminDivisionAr.toLowerCase().contains(normalizedQuery) ||
          record.geometryStatus.toLowerCase().contains(normalizedQuery) ||
          record.warningLabel.toLowerCase().contains(normalizedQuery);
      return queueMatches &&
          statusMatches &&
          gateMatches &&
          draftMatches &&
          queryMatches;
    }).toList(growable: true);

    filtered.sort(_recordComparator(selectedSortCode));
    return List<PwfReviewRecord>.unmodifiable(filtered);
  }

  PwfReviewRecord? get selectedRecord {
    if (selectedRecordId == null) {
      return filteredRecords.isEmpty ? null : filteredRecords.first;
    }
    for (final record in filteredRecords) {
      if (record.id == selectedRecordId) return record;
    }
    return filteredRecords.isEmpty ? null : filteredRecords.first;
  }

  List<String> get availableStatuses {
    final statuses =
        records.map((record) => record.reviewStatus).toSet().toList()..sort();
    return ['all', ...statuses];
  }

  List<String> get availableGateCodes {
    final gates = records
        .map((record) => record.operationalGateCode)
        .toSet()
        .toList()
      ..sort();
    return ['all', ...gates];
  }

  int get locatorReadyCount =>
      records.where((record) => record.hasLocator).length;
  int get dualDecisionCount =>
      records.where((record) => record.hasDualDecision).length;
  int get alignedDecisionCount =>
      records.where((record) => record.isDecisionAligned).length;
  int get decisionPackageReadyCount =>
      records.where((record) => record.isInternalDecisionPackageReady).length;
  int get blockedCount => records
      .where((record) => !record.hasLocator || !record.hasDualDecision)
      .length;
  int get localDraftCount => localDraftRecordIds.length;
  int get spatialRiskCount =>
      records.where((record) => record.requiresSpatialReview).length;
  int get geometryRepairCount =>
      records.where((record) => record.requiresGeometryRepair).length;
  int get manualResearchCount =>
      records.where((record) => record.requiresManualResearch).length;
  int get mapEvidenceReadyCount =>
      records.where((record) => record.hasMapEvidence).length;

  Map<PwfReviewQueue, int> get queueCounts {
    final counts = {for (final queue in PwfReviewQueue.values) queue: 0};
    for (final record in records) {
      counts[record.queue] = (counts[record.queue] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> get gateCounts {
    final counts = <String, int>{};
    for (final record in records) {
      counts[record.operationalGateCode] =
          (counts[record.operationalGateCode] ?? 0) + 1;
    }
    return counts;
  }

  bool isLocalDraft(String recordId) => localDraftRecordIds.contains(recordId);

  String get exportQaSummary {
    return 'filtered=${filteredRecords.length}; local_drafts=$localDraftCount; '
        'decision_ready=$decisionPackageReadyCount; map_evidence=$mapEvidenceReadyCount; '
        'governance=review_only_not_final';
  }

  List<PwfReviewRecord> get localDraftRecords {
    return records
        .where((record) => localDraftRecordIds.contains(record.id))
        .toList(growable: false);
  }

  List<PwfReviewRecord> get decisionPackageRecords {
    return records
        .where((record) => record.isInternalDecisionPackageReady)
        .toList(growable: false);
  }

  List<PwfReviewRecord> get mapEvidenceRecords {
    return records
        .where((record) => record.hasMapEvidence)
        .toList(growable: false);
  }

  int get fullMapEvidenceCount => records
      .where(
          (record) => record.mapAdapterReadinessCode == 'ready_full_evidence')
      .length;
  int get mapHookReadyCount => records.where((record) {
        final envelope =
            const PwfStandaloneRealMapHookAdapter().buildEnvelope(record);
        return envelope.isReadyForRealMapHook;
      }).length;

  bool get isSupabaseRuntime => runtimeBackend.isSupabase;
  String get runtimeBackendLabel => runtimeBackend.labelAr;
  bool get stagingReadAllowed => stagingDiagnostics?.readAllowed ?? false;
  bool get stagingWriteAllowed => stagingDiagnostics?.writeAllowed ?? false;

  String exportLocalDraftsCsv() => exportRecordsCsv(
        localDraftRecords,
        exportScope: 'local_browser_only_not_supabase',
        governanceStatus: 'draft_only_not_final',
      );

  String exportFilteredRecordsCsv() => exportRecordsCsv(
        filteredRecords,
        exportScope: 'filtered_runtime_view',
        governanceStatus: 'review_only_not_final',
      );

  String exportAllRecordsCsv() => exportRecordsCsv(
        records,
        exportScope: 'all_runtime_records',
        governanceStatus: 'review_only_not_final',
      );

  String exportDecisionPackageCsv() => exportRecordsCsv(
        decisionPackageRecords,
        exportScope: 'internal_decision_package_ready_only',
        governanceStatus: 'not_sovereign_export',
      );

  String exportMapEvidenceCsv() => exportRecordsCsv(
        mapEvidenceRecords,
        exportScope: 'explorer_map_evidence_payloads',
        governanceStatus: 'map_adapter_review_only_not_final',
      );

  String exportMapHookDiagnosticsCsv() {
    const adapter = PwfStandaloneRealMapHookAdapter();
    final rows = <List<String>>[
      [
        'record_id',
        'validation_code',
        'validation_label_ar',
        'camera_command',
        'layer_policy',
        'rpc_policy',
        'commands',
        'warnings_count',
        'governance_status',
      ],
      ...records.map((record) {
        final envelope = adapter.buildEnvelope(record);
        return [
          record.id,
          envelope.validationCode,
          envelope.validationLabelAr,
          envelope.cameraCommand,
          envelope.layerPolicy,
          envelope.rpcPolicy,
          envelope.commands.map((command) => command.commandCode).join('|'),
          '${envelope.warnings.length}',
          'review_only_not_final_no_layer_toggle',
        ];
      }),
    ];
    return rows.map((row) => row.map(_escapeCsvCell).join(',')).join('\n');
  }

  String exportRecordsCsv(
    Iterable<PwfReviewRecord> exportRecords, {
    required String exportScope,
    required String governanceStatus,
  }) {
    final rows = <List<String>>[
      [
        'record_id',
        'place_name_ar',
        'current_candidate_ar',
        'queue_code',
        'review_status',
        'distance_meters',
        'distance_risk_code',
        'distance_risk_label_ar',
        'confidence_score',
        'locator_status',
        'operational_gate_code',
        'operational_gate_status',
        'source_title',
        'source_type',
        'locator_text',
        'evidence_note',
        'page',
        'table_name',
        'row_reference',
        'reviewer_one_decision',
        'reviewer_one_note',
        'reviewer_two_decision',
        'reviewer_two_note',
        'map_evidence_summary',
        'historical_lat',
        'historical_lon',
        'candidate_lat',
        'candidate_lon',
        'bbox_south',
        'bbox_west',
        'bbox_north',
        'bbox_east',
        'map_adapter_status',
        'map_adapter_readiness_code',
        'map_adapter_readiness_label_ar',
        'map_camera_intent_code',
        'map_camera_intent_label_ar',
        'coordinate_evidence_status_ar',
        'updated_at',
        'governance_status',
        'export_scope',
      ],
      ...exportRecords.map((record) {
        final locator = record.sourceLocator;
        return [
          record.id,
          record.placeNameAr,
          record.currentCandidateAr,
          record.queueCode,
          record.reviewStatus,
          record.distanceMeters?.toStringAsFixed(2) ?? '',
          record.distanceRiskCode,
          record.distanceRiskLabelAr,
          '${record.confidenceScore}',
          record.locatorStatus.code,
          record.operationalGateCode,
          record.operationalGateStatus,
          locator?.sourceTitle ?? '',
          locator?.sourceType ?? '',
          locator?.locatorText ?? '',
          locator?.evidenceNote ?? '',
          locator?.page ?? '',
          locator?.tableName ?? '',
          locator?.rowReference ?? '',
          record.reviewerOneDecision.code,
          record.reviewerOneNote,
          record.reviewerTwoDecision.code,
          record.reviewerTwoNote,
          record.mapEvidenceSummary,
          record.historicalLat?.toStringAsFixed(6) ?? '',
          record.historicalLon?.toStringAsFixed(6) ?? '',
          record.candidateLat?.toStringAsFixed(6) ?? '',
          record.candidateLon?.toStringAsFixed(6) ?? '',
          record.bboxSouth?.toStringAsFixed(6) ?? '',
          record.bboxWest?.toStringAsFixed(6) ?? '',
          record.bboxNorth?.toStringAsFixed(6) ?? '',
          record.bboxEast?.toStringAsFixed(6) ?? '',
          record.mapAdapterStatus,
          record.mapAdapterReadinessCode,
          record.mapAdapterReadinessLabelAr,
          record.mapCameraIntentCode,
          record.mapCameraIntentLabelAr,
          record.coordinateEvidenceStatusAr,
          record.updatedAt?.toIso8601String() ?? '',
          governanceStatus,
          exportScope,
        ];
      }),
    ];
    return rows.map((row) => row.map(_escapeCsvCell).join(',')).join('\n');
  }

  static String _escapeCsvCell(String value) {
    final normalized = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (normalized.contains(',') ||
        normalized.contains('"') ||
        normalized.contains('\n')) {
      return '"${normalized.replaceAll('"', '""')}"';
    }
    return normalized;
  }

  static Comparator<PwfReviewRecord> _recordComparator(String code) {
    return switch (code) {
      'confidence_desc' => (a, b) =>
          b.confidenceScore.compareTo(a.confidenceScore),
      'confidence_asc' => (a, b) =>
          a.confidenceScore.compareTo(b.confidenceScore),
      'distance_asc' => (a, b) =>
          _distanceOrMax(a).compareTo(_distanceOrMax(b)),
      'distance_desc' => (a, b) =>
          _distanceOrMin(b).compareTo(_distanceOrMin(a)),
      'queue_asc' => (a, b) => a.queueCode.compareTo(b.queueCode),
      'updated_desc' => (a, b) =>
          _updatedOrEpoch(b).compareTo(_updatedOrEpoch(a)),
      _ => (a, b) => _riskRank(b).compareTo(_riskRank(a)),
    };
  }

  static double _distanceOrMax(PwfReviewRecord record) =>
      record.distanceMeters ?? 999999999;
  static double _distanceOrMin(PwfReviewRecord record) =>
      record.distanceMeters ?? -1;
  static DateTime _updatedOrEpoch(PwfReviewRecord record) =>
      record.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  static int _riskRank(PwfReviewRecord record) {
    return switch (record.distanceRiskCode) {
      'critical_distance' => 6,
      'geometry_missing' => 5,
      'high_distance' => 4,
      'medium_distance' => 3,
      'unknown_distance' => 2,
      'low_distance' => 1,
      _ => 0,
    };
  }

  PwfReviewBoardState copyWith({
    List<PwfReviewRecord>? records,
    bool? isLoading,
    String? query,
    String? selectedQueueCode,
    String? selectedStatus,
    String? selectedGateCode,
    String? selectedSortCode,
    bool? showLocalDraftsOnly,
    Object? selectedRecordId = _pwfUnset,
    Set<String>? localDraftRecordIds,
    Object? localDraftHealthLabel = _pwfUnset,
    Object? lastSaveVerificationLine = _pwfUnset,
    Object? lastExportVerificationLine = _pwfUnset,
    Object? stagingDiagnostics = _pwfUnset,
    bool? isStagingBusy,
    Object? stagingMessage = _pwfUnset,
    Object? stagingLastRpcLine = _pwfUnset,
    Object? stagingErrorMessage = _pwfUnset,
    PwfReviewBoardRuntimeBackend? runtimeBackend,
    Object? errorMessage = _pwfUnset,
    Object? persistenceMessage = _pwfUnset,
    Object? lastPersistedAt = _pwfUnset,
  }) {
    return PwfReviewBoardState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      selectedQueueCode: selectedQueueCode ?? this.selectedQueueCode,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedGateCode: selectedGateCode ?? this.selectedGateCode,
      selectedSortCode: selectedSortCode ?? this.selectedSortCode,
      showLocalDraftsOnly: showLocalDraftsOnly ?? this.showLocalDraftsOnly,
      selectedRecordId: identical(selectedRecordId, _pwfUnset)
          ? this.selectedRecordId
          : selectedRecordId as String?,
      localDraftRecordIds: localDraftRecordIds ?? this.localDraftRecordIds,
      localDraftHealthLabel: identical(localDraftHealthLabel, _pwfUnset)
          ? this.localDraftHealthLabel
          : localDraftHealthLabel as String?,
      lastSaveVerificationLine: identical(lastSaveVerificationLine, _pwfUnset)
          ? this.lastSaveVerificationLine
          : lastSaveVerificationLine as String?,
      lastExportVerificationLine:
          identical(lastExportVerificationLine, _pwfUnset)
              ? this.lastExportVerificationLine
              : lastExportVerificationLine as String?,
      stagingDiagnostics: identical(stagingDiagnostics, _pwfUnset)
          ? this.stagingDiagnostics
          : stagingDiagnostics as PwfReviewBoardAccessDiagnostics?,
      isStagingBusy: isStagingBusy ?? this.isStagingBusy,
      stagingMessage: identical(stagingMessage, _pwfUnset)
          ? this.stagingMessage
          : stagingMessage as String?,
      stagingLastRpcLine: identical(stagingLastRpcLine, _pwfUnset)
          ? this.stagingLastRpcLine
          : stagingLastRpcLine as String?,
      stagingErrorMessage: identical(stagingErrorMessage, _pwfUnset)
          ? this.stagingErrorMessage
          : stagingErrorMessage as String?,
      runtimeBackend: runtimeBackend ?? this.runtimeBackend,
      errorMessage: identical(errorMessage, _pwfUnset)
          ? this.errorMessage
          : errorMessage as String?,
      persistenceMessage: identical(persistenceMessage, _pwfUnset)
          ? this.persistenceMessage
          : persistenceMessage as String?,
      lastPersistedAt: identical(lastPersistedAt, _pwfUnset)
          ? this.lastPersistedAt
          : lastPersistedAt as DateTime?,
    );
  }
}

class PwfReviewBoardController extends StateNotifier<PwfReviewBoardState> {
  PwfReviewBoardController(
    this._repository,
    this._draftStore,
    this._stagingRepository, {
    required PwfReviewBoardRuntimeBackend runtimeBackend,
  }) : super(PwfReviewBoardState.initial()
            .copyWith(runtimeBackend: runtimeBackend));

  final PwfReviewBoardRepository _repository;
  final PwfLocalReviewDraftStore _draftStore;
  final PwfStagingReviewBoardRepository _stagingRepository;

  Future<void> load() async {
    state = state.copyWith(
        isLoading: true, errorMessage: null, persistenceMessage: null);
    try {
      final sourceRecords = await _repository.fetchQueue();
      final records = await _draftStore.mergeDrafts(sourceRecords);
      final draftIds = await _draftStore.loadDraftRecordIds();
      final draftHealth = await _draftStore.inspectHealth();
      final preferredSelectedId = state.selectedRecordId;
      final selectedExists = preferredSelectedId != null &&
          records.any((record) => record.id == preferredSelectedId);
      state = state.copyWith(
        records: records,
        isLoading: false,
        localDraftRecordIds: draftIds,
        selectedRecordId: selectedExists
            ? preferredSelectedId
            : records.isEmpty
                ? null
                : records.first.id,
        localDraftHealthLabel: draftHealth.labelAr,
        persistenceMessage: draftIds.isEmpty
            ? draftHealth.labelAr
            : 'ط·ع¾ط¸â€¦ ط·ع¾ط·آ­ط¸â€¦ط¸ظ¹ط¸â€‍ ${draftIds.length} ط¸â€¦ط·آ³ط¸ث†ط·آ¯ط·آ© ط¸â€¦ط·آ­ط¸â€‍ط¸ظ¹ط·آ© ط¸â€¦ط·آ­ط¸ظ¾ط¸ث†ط·آ¸ط·آ© ط¸ظ¾ط¸ظ¹ ط·آ§ط¸â€‍ط¸â€¦ط·ع¾ط·آµط¸ظ¾ط·آ­. ${draftHealth.labelAr}',
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  void updateQuery(String query) {
    state = state.copyWith(query: query, selectedRecordId: null);
  }

  void updateQueue(String queueCode) {
    state =
        state.copyWith(selectedQueueCode: queueCode, selectedRecordId: null);
  }

  void updateStatus(String status) {
    state = state.copyWith(selectedStatus: status, selectedRecordId: null);
  }

  void updateGate(String gateCode) {
    state = state.copyWith(selectedGateCode: gateCode, selectedRecordId: null);
  }

  void updateSort(String sortCode) {
    state = state.copyWith(selectedSortCode: sortCode, selectedRecordId: null);
  }

  void toggleLocalDraftsOnly(bool value) {
    state = state.copyWith(showLocalDraftsOnly: value, selectedRecordId: null);
  }

  void clearFilters() {
    state = state.copyWith(
      query: '',
      selectedQueueCode: 'all',
      selectedStatus: 'all',
      selectedGateCode: 'all',
      selectedSortCode: 'risk_desc',
      showLocalDraftsOnly: false,
      selectedRecordId: null,
    );
  }

  void selectRecord(String recordId) {
    state = state.copyWith(selectedRecordId: recordId);
  }

  void focusRecordFromExplorerMap(String recordId) {
    final exists = state.records.any((record) => record.id == recordId);
    if (!exists) return;
    state = state.copyWith(
      query: '',
      selectedQueueCode: 'all',
      selectedStatus: 'all',
      selectedGateCode: 'all',
      showLocalDraftsOnly: false,
      selectedRecordId: recordId,
      persistenceMessage:
          'ط·ع¾ط¸â€¦ ط·آ§ط¸â€‍ط·آ±ط·آ¬ط¸ث†ط·آ¹ ط·آ¥ط¸â€‍ط¸â€° ط·آ³ط·آ¬ط¸â€‍ ط·آ§ط¸â€‍ط¸â€¦ط·آ±ط·آ§ط·آ¬ط·آ¹ط·آ© ط¸â€¦ط¸â€  ط·آ®ط·آ±ط¸ظ¹ط·آ·ط·آ© ط·آ§ط¸â€‍ط¸â€¦ط·آ³ط·ع¾ط¸ئ’ط·آ´ط¸ظ¾: $recordId',
      lastPersistedAt: DateTime.now(),
    );
  }

  void upsertSourceLocator(String recordId, PwfSourceLocator locator) {
    final records = state.records.map((record) {
      if (record.id != recordId) return record;
      return record.copyWith(
        sourceLocator: locator,
        locatorStatus: locator.isComplete
            ? PwfLocatorStatus.submitted
            : PwfLocatorStatus.draft,
        updatedAt: DateTime.now(),
      );
    }).toList(growable: false);
    _updateRecordsAndPersist(
        records: records,
        recordId: recordId,
        message:
            'ط·ع¾ط¸â€¦ ط·آ­ط¸ظ¾ط·آ¸ ط·آ§ط¸â€‍ط¸â€¦ط·آµط·آ¯ط·آ± ط¸â€¦ط·آ­ط¸â€‍ط¸ظ¹ط¸â€¹ط·آ§ ط¸ظ¾ط¸ظ¹ ط·آ§ط¸â€‍ط¸â€¦ط·ع¾ط·آµط¸ظ¾ط·آ­.');
  }

  void submitReviewerDecision({
    required String recordId,
    required int reviewerIndex,
    required PwfReviewDecision decision,
    required String note,
  }) {
    final records = state.records.map((record) {
      if (record.id != recordId) return record;
      if (reviewerIndex == 1) {
        return record.copyWith(
          reviewerOneDecision: decision,
          reviewerOneNote: note,
          updatedAt: DateTime.now(),
        );
      }
      return record.copyWith(
        reviewerTwoDecision: decision,
        reviewerTwoNote: note,
        updatedAt: DateTime.now(),
      );
    }).toList(growable: false);
    _updateRecordsAndPersist(
        records: records,
        recordId: recordId,
        message:
            'ط·ع¾ط¸â€¦ ط·آ­ط¸ظ¾ط·آ¸ ط¸â€ڑط·آ±ط·آ§ط·آ± ط·آ§ط¸â€‍ط¸â€¦ط·آ±ط·آ§ط·آ¬ط·آ¹ ط¸â€¦ط·آ­ط¸â€‍ط¸ظ¹ط¸â€¹ط·آ§ ط¸ظ¾ط¸ظ¹ ط·آ§ط¸â€‍ط¸â€¦ط·ع¾ط·آµط¸ظ¾ط·آ­.');
  }

  Future<void> refreshStagingDiagnostics() async {
    state = state.copyWith(
      isStagingBusy: true,
      stagingErrorMessage: null,
      stagingMessage:
          'ط·آ¬ط·آ§ط·آ±ط¸ظ¹ ط¸ظ¾ط·آ­ط·آµ ط·آµط¸â€‍ط·آ§ط·آ­ط¸ظ¹ط·آ§ط·ع¾ mustakshif_staging...',
    );
    try {
      final diagnostics = await _stagingRepository.fetchAccessDiagnostics();
      state = state.copyWith(
        stagingDiagnostics: diagnostics,
        isStagingBusy: false,
        stagingMessage: diagnostics.labelAr,
        stagingLastRpcLine:
            'diagnostics read=${diagnostics.readAllowed}; write=${diagnostics.writeAllowed}; actor=${diagnostics.effectiveActorId ?? diagnostics.userId ?? "n/a"}',
        stagingErrorMessage: null,
        lastPersistedAt: DateTime.now(),
      );
    } catch (error) {
      state = state.copyWith(
        isStagingBusy: false,
        stagingErrorMessage:
            'ط¸ظ¾ط·آ´ط¸â€‍ ط·ع¾ط·آ´ط·آ®ط¸ظ¹ط·آµ Supabase staging: $error',
        stagingMessage: null,
      );
    }
  }

  Future<void> enableAuthenticatedStagingSandbox() async {
    state = state.copyWith(
      isStagingBusy: true,
      stagingErrorMessage: null,
      stagingMessage:
          'ط·آ¬ط·آ§ط·آ±ط¸ظ¹ ط·ع¾ط¸ظ¾ط·آ¹ط¸ظ¹ط¸â€‍ sandbox ط¸â€¦ط·آ¤ط¸â€ڑط·ع¾ ط¸â€‍ط¸â€،ط·آ°ط·آ§ ط·آ§ط¸â€‍ط¸â€¦ط·آ³ط·ع¾ط·آ®ط·آ¯ط¸â€¦ ط·آ§ط¸â€‍ط¸â€¦ط·آµط·آ§ط·آ¯ط¸عکط¸â€ڑ...',
    );
    try {
      final enableResult = await _stagingRepository.selfEnableSandbox(
        reason:
            'Flutter runtime sandbox enable for Mustakshif Review Board V1C authenticated user',
        minutes: 120,
      );
      final diagnostics = await _stagingRepository.fetchAccessDiagnostics();
      final enabledLine =
          'rpc=rpc_mustakshif_review_board_self_enable_sandbox_v1; ${enableResult.compactLine}';
      final diagnosticsLine =
          'diagnostics read=${diagnostics.readAllowed}; write=${diagnostics.writeAllowed}; actor=${diagnostics.effectiveActorId ?? diagnostics.userId ?? "n/a"}';
      state = state.copyWith(
        stagingDiagnostics: diagnostics,
        isStagingBusy: false,
        stagingMessage: enableResult.ok
            ? 'ط·ع¾ط¸â€¦ ط·ع¾ط¸ظ¾ط·آ¹ط¸ظ¹ط¸â€‍ sandbox ط¸â€‍ط¸â€،ط·آ°ط·آ§ ط·آ§ط¸â€‍ط¸â€¦ط·آ³ط·ع¾ط·آ®ط·آ¯ط¸â€¦. ${diagnostics.labelAr}'
            : 'ط·آ·ط¸â€‍ط·آ¨ ط·ع¾ط¸ظ¾ط·آ¹ط¸ظ¹ط¸â€‍ sandbox ط·آ¹ط·آ§ط·آ¯ ط·آ¨ط¸â€ ط·ع¾ط¸ظ¹ط·آ¬ط·آ© ط·ط›ط¸ظ¹ط·آ± ط¸â€ ط·آ§ط·آ¬ط·آ­ط·آ©. ${diagnostics.labelAr}',
        stagingLastRpcLine: '$enabledLine | $diagnosticsLine',
        stagingErrorMessage: enableResult.ok
            ? null
            : 'RPC ط·آ£ط·آ¹ط·آ§ط·آ¯ ok=false ط·آ¹ط¸â€ ط·آ¯ ط·ع¾ط¸ظ¾ط·آ¹ط¸ظ¹ط¸â€‍ sandbox ط¸â€‍ط¸â€،ط·آ°ط·آ§ ط·آ§ط¸â€‍ط¸â€¦ط·آ³ط·ع¾ط·آ®ط·آ¯ط¸â€¦.',
        lastPersistedAt: DateTime.now(),
      );
    } catch (error) {
      state = state.copyWith(
        isStagingBusy: false,
        stagingErrorMessage:
            'ط¸ظ¾ط·آ´ط¸â€‍ ط·ع¾ط¸ظ¾ط·آ¹ط¸ظ¹ط¸â€‍ sandbox ط¸â€‍ط¸â€،ط·آ°ط·آ§ ط·آ§ط¸â€‍ط¸â€¦ط·آ³ط·ع¾ط·آ®ط·آ¯ط¸â€¦: $error. ط·ع¾ط·آ£ط¸ئ’ط·آ¯ ط¸â€¦ط¸â€  ط¸ث†ط·آ¬ط¸ث†ط·آ¯ ط·آ¬ط¸â€‍ط·آ³ط·آ© Supabase auth ط·آ­ط¸â€ڑط¸ظ¹ط¸â€ڑط¸ظ¹ط·آ©ط·â€؛ SQL Editor ط¸ظ¹ط·آ³ط·ع¾ط·آ®ط·آ¯ط¸â€¦ ط¸â€¦ط·آ³ط·آ§ط·آ± V1C ط·آ§ط¸â€‍ط¸â€¦ط¸â€ ط¸ظ¾ط·آµط¸â€‍.',
        stagingMessage: null,
      );
    }
  }

  Future<void> verifyProductionRbacMapping() async {
    state = state.copyWith(
      isStagingBusy: true,
      stagingErrorMessage: null,
      stagingMessage:
          'ط·آ¬ط·آ§ط·آ±ط¸ظ¹ ط¸ظ¾ط·آ­ط·آµ ط¸â€¦ط·آµط¸ظ¾ط¸ث†ط¸ظ¾ط·آ© RBAC ط·آ§ط¸â€‍ط·آ¥ط¸â€ ط·ع¾ط·آ§ط·آ¬ط¸ظ¹ط·آ© ط·آ¯ط¸ث†ط¸â€  ط·ع¾ط¸â€ ط¸ظ¾ط¸ظ¹ط·آ° cutover...',
    );
    try {
      final result = await _stagingRepository.fetchRbacVerificationMatrix();
      state = state.copyWith(
        isStagingBusy: false,
        stagingMessage:
            'ط¸â€ ط·ع¾ط¸ظ¹ط·آ¬ط·آ© ط¸ظ¾ط·آ­ط·آµ RBAC ط·آ§ط¸â€‍ط·آ¥ط¸â€ ط·ع¾ط·آ§ط·آ¬ط¸ظ¹: ${result.compactLine}',
        stagingLastRpcLine:
            'rpc=rpc_mustakshif_review_board_rbac_mapping_verification_matrix_v1; ${result.compactLine}',
        stagingErrorMessage: result.ok
            ? null
            : 'RBAC verification matrix ط·آ£ط·آ¹ط·آ§ط·آ¯ ok=false.',
        lastPersistedAt: DateTime.now(),
      );
    } catch (error) {
      state = state.copyWith(
        isStagingBusy: false,
        stagingErrorMessage:
            'ط¸ظ¾ط·آ´ط¸â€‍ ط¸ظ¾ط·آ­ط·آµ RBAC ط·آ§ط¸â€‍ط·آ¥ط¸â€ ط·ع¾ط·آ§ط·آ¬ط¸ظ¹: $error',
        stagingMessage: null,
      );
    }
  }

  Future<void> verifyFinalIntegrationReadiness() async {
    state = state.copyWith(
      isStagingBusy: true,
      stagingErrorMessage: null,
      stagingMessage:
          'ط·آ¬ط·آ§ط·آ±ط¸ظ¹ ط¸ظ¾ط·آ­ط·آµ ط·آ¬ط·آ§ط¸â€،ط·آ²ط¸ظ¹ط·آ© ط·آ¥ط·ط›ط¸â€‍ط·آ§ط¸â€ڑ ط·آ§ط¸â€‍ط·آ§ط¸â€ ط·آ¯ط¸â€¦ط·آ§ط·آ¬ ط¸ث†ط·آ§ط¸â€‍ط·آ¹ط¸ث†ط·آ¯ط·آ© ط¸â€‍ط·ع¾ط·آ·ط¸ث†ط¸ظ¹ط·آ± ط·آ§ط¸â€‍ط¸â€¦ط·آ³ط·ع¾ط¸ئ’ط·آ´ط¸ظ¾...',
    );
    try {
      final result = await _stagingRepository.fetchFinalIntegrationReadiness();
      state = state.copyWith(
        isStagingBusy: false,
        stagingMessage: result.readyForExplorerDevelopment
            ? 'ط·آ¥ط·ط›ط¸â€‍ط·آ§ط¸â€ڑ ط·آ§ط¸â€‍ط·آ§ط¸â€ ط·آ¯ط¸â€¦ط·آ§ط·آ¬ ط·آ¬ط·آ§ط¸â€،ط·آ² ط¸ث†ط·آ¸ط¸ظ¹ط¸ظ¾ط¸ظ¹ط¸â€¹ط·آ§. ط¸ظ¹ط¸â€¦ط¸ئ’ط¸â€  ط·آ§ط¸â€‍ط·آ¹ط¸ث†ط·آ¯ط·آ© ط¸â€‍ط·ع¾ط·آ·ط¸ث†ط¸ظ¹ط·آ± ط·آ§ط¸â€‍ط¸â€¦ط·آ³ط·ع¾ط¸ئ’ط·آ´ط¸ظ¾ط·إ’ ط¸â€¦ط·آ¹ ط·آ¨ط¸â€ڑط·آ§ط·طŒ production cutover ط¸â€¦ط·آ¤ط·آ¬ط¸â€‍ط¸â€¹ط·آ§ ط¸â€‍ط·آ­ط¸ظ¹ط¸â€  ط·آ§ط·آ¹ط·ع¾ط¸â€¦ط·آ§ط·آ¯ RBAC ط·آ§ط¸â€‍ط·آ­ط¸â€ڑط¸ظ¹ط¸â€ڑط¸ظ¹. ${result.compactLine}'
            : 'ط·آ¬ط·آ§ط¸â€،ط·آ²ط¸ظ¹ط·آ© ط·آ§ط¸â€‍ط·آ¥ط·ط›ط¸â€‍ط·آ§ط¸â€ڑ ط·ط›ط¸ظ¹ط·آ± ط¸â€¦ط¸ئ’ط·ع¾ط¸â€¦ط¸â€‍ط·آ©. ${result.compactLine}',
        stagingLastRpcLine:
            'rpc=rpc_mustakshif_review_board_final_integration_readiness_v1; ${result.compactLine}',
        stagingErrorMessage: result.ok
            ? null
            : 'Final integration readiness ط·آ£ط·آ¹ط·آ§ط·آ¯ ok=false.',
        lastPersistedAt: DateTime.now(),
      );
    } catch (error) {
      state = state.copyWith(
        isStagingBusy: false,
        stagingErrorMessage:
            'ط¸ظ¾ط·آ´ط¸â€‍ ط¸ظ¾ط·آ­ط·آµ ط·آ¬ط·آ§ط¸â€،ط·آ²ط¸ظ¹ط·آ© ط·آ¥ط·ط›ط¸â€‍ط·آ§ط¸â€ڑ ط·آ§ط¸â€‍ط·آ§ط¸â€ ط·آ¯ط¸â€¦ط·آ§ط·آ¬: $error',
        stagingMessage: null,
      );
    }
  }

  Future<void> retireAuthenticatedSandboxOverrideIfProductionReady() async {
    state = state.copyWith(
      isStagingBusy: true,
      stagingErrorMessage: null,
      stagingMessage:
          'ط·آ¬ط·آ§ط·آ±ط¸ظ¹ ط·آ·ط¸â€‍ط·آ¨ ط·ع¾ط¸â€ڑط·آ§ط·آ¹ط·آ¯ sandbox ط¸â€‍ط¸â€‍ط¸â€¦ط·آ³ط·ع¾ط·آ®ط·آ¯ط¸â€¦ ط·آ§ط¸â€‍ط·آ­ط·آ§ط¸â€‍ط¸ظ¹ ط·آ¥ط·آ°ط·آ§ ط¸ئ’ط·آ§ط¸â€ ط·ع¾ ط·آµط¸â€‍ط·آ§ط·آ­ط¸ظ¹ط·آ§ط·ع¾ RBAC ط·آ§ط¸â€‍ط·آ¥ط¸â€ ط·ع¾ط·آ§ط·آ¬ط¸ظ¹ط·آ© ط¸ئ’ط·آ§ط¸ظ¾ط¸ظ¹ط·آ©...',
    );
    try {
      final result =
          await _stagingRepository.retireAuthenticatedSandboxOverride(
        reason:
            'Retire authenticated sandbox override after Mustakshif integration closure checks',
      );
      final diagnostics = await _stagingRepository.fetchAccessDiagnostics();
      state = state.copyWith(
        stagingDiagnostics: diagnostics,
        isStagingBusy: false,
        stagingMessage: result.ok
            ? 'ط·ع¾ط¸â€¦ ط·ع¾ط¸â€ڑط·آ§ط·آ¹ط·آ¯ sandbox ط¸â€‍ط¸â€‍ط¸â€¦ط·آ³ط·ع¾ط·آ®ط·آ¯ط¸â€¦ ط·آ§ط¸â€‍ط·آ­ط·آ§ط¸â€‍ط¸ظ¹ ط¸â€¦ط·آ¹ ط·آ¨ط¸â€ڑط·آ§ط·طŒ ط·آ§ط¸â€‍ط¸ث†ط·آµط¸ث†ط¸â€‍ ط¸â€¦ط·آ­ط¸ئ’ط¸ث†ط¸â€¦ط¸â€¹ط·آ§ ط·آ¨ط¸â‚¬ RBAC ط·آ§ط¸â€‍ط·آ¥ط¸â€ ط·ع¾ط·آ§ط·آ¬ط¸ظ¹. ${diagnostics.labelAr}'
            : 'ط¸â€‍ط¸â€¦ ط¸ظ¹ط·ع¾ط¸â€¦ ط·ع¾ط¸â€ڑط·آ§ط·آ¹ط·آ¯ sandbox. ط·ط›ط·آ§ط¸â€‍ط·آ¨ط¸â€¹ط·آ§ ط¸â€‍ط·آ£ط¸â€  RBAC ط·آ§ط¸â€‍ط·آ¥ط¸â€ ط·ع¾ط·آ§ط·آ¬ط¸ظ¹ ط·ط›ط¸ظ¹ط·آ± ط·آ¬ط·آ§ط¸â€،ط·آ² ط·آ¨ط·آ¹ط·آ¯ط·إ’ ط¸ث†ط¸â€،ط·آ°ط·آ§ ط·آ­ط·آ¬ط·آ¨ ط·آµط·آ­ط¸ظ¹ط·آ­. ${result.compactLine}',
        stagingLastRpcLine:
            'rpc=rpc_mustakshif_review_board_retire_my_sandbox_override_v1; ${result.compactLine}; diagnostics read=${diagnostics.readAllowed}; write=${diagnostics.writeAllowed}',
        stagingErrorMessage: result.ok
            ? null
            : 'ط¸â€‍ط¸â€¦ ط¸ظ¹ط·ع¾ط¸â€¦ ط·ع¾ط¸â€ڑط·آ§ط·آ¹ط·آ¯ sandbox ط¸â€‍ط·آ£ط¸â€  ط·آ´ط·آ±ط¸ث†ط·آ· ط·آ§ط¸â€‍ط·آ¥ط¸â€ ط·ع¾ط·آ§ط·آ¬ ط¸â€‍ط¸â€¦ ط·ع¾ط¸ئ’ط·ع¾ط¸â€¦ط¸â€‍.',
        lastPersistedAt: DateTime.now(),
      );
    } catch (error) {
      state = state.copyWith(
        isStagingBusy: false,
        stagingErrorMessage:
            'ط¸ظ¾ط·آ´ط¸â€‍ ط·آ·ط¸â€‍ط·آ¨ ط·ع¾ط¸â€ڑط·آ§ط·آ¹ط·آ¯ sandbox ط¸â€‍ط¸â€‍ط¸â€¦ط·آ³ط·ع¾ط·آ®ط·آ¯ط¸â€¦ ط·آ§ط¸â€‍ط·آ­ط·آ§ط¸â€‍ط¸ظ¹: $error',
        stagingMessage: null,
      );
    }
  }

  Future<void> loadFromStagingQueue() async {
    state = state.copyWith(
      isStagingBusy: true,
      isLoading: true,
      stagingErrorMessage: null,
      stagingMessage:
          'ط·آ¬ط·آ§ط·آ±ط¸ظ¹ ط·ع¾ط·آ­ط¸â€¦ط¸ظ¹ط¸â€‍ queue ط¸â€¦ط¸â€  Supabase staging ط·آ¹ط·آ¨ط·آ± public RPC...',
    );
    try {
      final sourceRecords = await _stagingRepository.fetchQueue();
      final records = await _draftStore.mergeDrafts(sourceRecords);
      final draftIds = await _draftStore.loadDraftRecordIds();
      final selectedId = records.isEmpty ? null : records.first.id;
      state = state.copyWith(
        records: records,
        isLoading: false,
        isStagingBusy: false,
        query: '',
        selectedQueueCode: 'all',
        selectedStatus: 'all',
        selectedGateCode: 'all',
        showLocalDraftsOnly: false,
        selectedRecordId: selectedId,
        localDraftRecordIds: draftIds,
        stagingMessage:
            'ط·ع¾ط¸â€¦ ط·ع¾ط·آ­ط¸â€¦ط¸ظ¹ط¸â€‍ ${records.length} ط·آ³ط·آ¬ط¸â€‍ ط¸â€¦ط¸â€  mustakshif_stagingط·إ’ ط¸ث†ط·ع¾ط¸â€¦ ط·آ¥ط¸ظ¹ط¸â€ڑط·آ§ط¸ظ¾ ط¸ظ¾ط¸â€‍ط·ع¾ط·آ± ط·آ§ط¸â€‍ط¸â€¦ط·آ³ط¸ث†ط·آ¯ط·آ§ط·ع¾ ط·آ§ط¸â€‍ط¸â€¦ط·آ­ط¸â€‍ط¸ظ¹ط·آ© ط·ع¾ط¸â€‍ط¸â€ڑط·آ§ط·آ¦ط¸ظ¹ط¸â€¹ط·آ§ ط¸â€‍ط·آ¹ط·آ±ط·آ¶ ط·آ³ط·آ¬ط¸â€‍ط·آ§ط·ع¾ staging.',
        stagingLastRpcLine:
            'rpc=rpc_mustakshif_review_board_queue_v1; rows=${records.length}; local_draft_filter=false',
        stagingErrorMessage: null,
        lastPersistedAt: DateTime.now(),
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isStagingBusy: false,
        stagingErrorMessage:
            'ط¸ظ¾ط·آ´ط¸â€‍ ط·ع¾ط·آ­ط¸â€¦ط¸ظ¹ط¸â€‍ queue ط¸â€¦ط¸â€  staging: $error',
        stagingMessage: null,
      );
    }
  }

  Future<void> createPositiveSpatialSmokeRecordInStaging() async {
    state = state.copyWith(
      isStagingBusy: true,
      stagingErrorMessage: null,
      stagingMessage:
          'ط·آ¬ط·آ§ط·آ±ط¸ظ¹ ط·آ¥ط¸â€ ط·آ´ط·آ§ط·طŒ ط·آ³ط·آ¬ط¸â€‍ ط·آ§ط·آ®ط·ع¾ط·آ¨ط·آ§ط·آ± ط¸â€¦ط¸ئ’ط·آ§ط¸â€ ط¸ظ¹ ط·آ¥ط¸ظ¹ط·آ¬ط·آ§ط·آ¨ط¸ظ¹ ط·آ¯ط·آ§ط·آ®ط¸â€‍ mustakshif_staging...',
    );
    try {
      final record = _buildPositiveSpatialSmokeRecord();
      final result = await _stagingRepository.saveDraft(
        record: record,
        sourceLocator: record.sourceLocator,
        reviewerIndex: 1,
        decision: PwfReviewDecision.needsMoreEvidence,
        note:
            'ط·آ§ط·آ®ط·ع¾ط·آ¨ط·آ§ط·آ± ط·آ¯ط·آ®ط·آ§ط¸â€  ط¸â€¦ط¸ئ’ط·آ§ط¸â€ ط¸ظ¹ ط·آ¥ط¸ظ¹ط·آ¬ط·آ§ط·آ¨ط¸ظ¹ ط¸â€¦ط¸â€  Flutter runtime: ط¸ظ¹ط·آ¬ط·آ¨ ط·آ£ط¸â€  ط¸ظ¹ط¸ظ¾ط·آ¹ط¸â€کط¸â€‍ fit_bbox ط·آ¯ط¸ث†ط¸â€  ط·ع¾ط·آ¹ط·آ¯ط¸ظ¹ط¸â€‍ ط·آ·ط·آ¨ط¸â€ڑط·آ§ط·ع¾ ط·آ£ط¸ث† activeLayers.',
        metadata: <String, dynamic>{
          'flutter_action': 'create_positive_spatial_payload_smoke_record',
          'smoke_test': 'positive_spatial_payload_runtime',
          'expected_map_command': record.mapCameraIntentCode,
          'policy': 'navigation_only_no_layer_mutation',
          'production_rbac': 'not_cutover_yet',
        },
      );

      if (!result.ok) {
        state = state.copyWith(
          isStagingBusy: false,
          stagingMessage:
              'ط·ع¾ط·آ¹ط·آ°ط·آ± ط·آ¥ط¸â€ ط·آ´ط·آ§ط·طŒ ط·آ³ط·آ¬ط¸â€‍ ط·آ§ط¸â€‍ط·آ§ط·آ®ط·ع¾ط·آ¨ط·آ§ط·آ± ط·آ§ط¸â€‍ط¸â€¦ط¸ئ’ط·آ§ط¸â€ ط¸ظ¹: ${result.compactLine}',
          stagingLastRpcLine:
              'rpc=rpc_mustakshif_review_board_draft_save_v1; smoke=positive_spatial_payload; ${result.compactLine}',
          stagingErrorMessage:
              'RPC ط·آ£ط·آ¹ط·آ§ط·آ¯ ok=false ط·آ¹ط¸â€ ط·آ¯ ط·آ¥ط¸â€ ط·آ´ط·آ§ط·طŒ ط·آ³ط·آ¬ط¸â€‍ ط·آ§ط¸â€‍ط·آ§ط·آ®ط·ع¾ط·آ¨ط·آ§ط·آ± ط·آ§ط¸â€‍ط¸â€¦ط¸ئ’ط·آ§ط¸â€ ط¸ظ¹.',
          lastPersistedAt: DateTime.now(),
        );
        return;
      }

      final sourceRecords = await _stagingRepository.fetchQueue();
      final records = await _draftStore.mergeDrafts(sourceRecords);
      final draftIds = await _draftStore.loadDraftRecordIds();
      final selectedId = records.any((item) => item.id == record.id)
          ? record.id
          : records.isEmpty
              ? null
              : records.first.id;
      state = state.copyWith(
        records: records,
        isLoading: false,
        isStagingBusy: false,
        query: '',
        selectedQueueCode: 'all',
        selectedStatus: 'all',
        selectedGateCode: 'all',
        showLocalDraftsOnly: false,
        selectedRecordId: selectedId,
        localDraftRecordIds: draftIds,
        stagingMessage:
            'ط·ع¾ط¸â€¦ ط·آ¥ط¸â€ ط·آ´ط·آ§ط·طŒ ط·آ³ط·آ¬ط¸â€‍ ط·آ§ط·آ®ط·ع¾ط·آ¨ط·آ§ط·آ± ط¸â€¦ط¸ئ’ط·آ§ط¸â€ ط¸ظ¹ ط·آ¥ط¸ظ¹ط·آ¬ط·آ§ط·آ¨ط¸ظ¹ ط¸ث†ط·آ§ط·آ®ط·ع¾ط¸ظ¹ط·آ§ط·آ±ط¸â€،. ط·آ§ط·آ³ط·ع¾ط·آ®ط·آ¯ط¸â€¦ ط·آ§ط¸â€‍ط·آ¢ط¸â€  ط·آ²ط·آ± ط·ع¾ط·آ³ط·آ¬ط¸ظ¹ط¸â€‍ map hook ط¸â€‍ط·آ¥ط·آ«ط·آ¨ط·آ§ط·ع¾ ط¸â€¦ط·آ³ط·آ§ط·آ± fit_bbox ط·آ§ط¸â€‍ط·آ¥ط¸ظ¹ط·آ¬ط·آ§ط·آ¨ط¸ظ¹ ط·آ¯ط¸ث†ط¸â€  ط·ع¾ط·ط›ط¸ظ¹ط¸ظ¹ط·آ± ط·آ·ط·آ¨ط¸â€ڑط·آ§ط·ع¾.',
        stagingLastRpcLine:
            'rpc=rpc_mustakshif_review_board_draft_save_v1; smoke=positive_spatial_payload; ${result.compactLine}; queue_rows=${records.length}; selected=$selectedId',
        stagingErrorMessage: null,
        lastPersistedAt: DateTime.now(),
      );
    } catch (error) {
      state = state.copyWith(
        isStagingBusy: false,
        stagingErrorMessage:
            'ط¸ظ¾ط·آ´ط¸â€‍ ط·آ¥ط¸â€ ط·آ´ط·آ§ط·طŒ ط·آ³ط·آ¬ط¸â€‍ ط·آ§ط¸â€‍ط·آ§ط·آ®ط·ع¾ط·آ¨ط·آ§ط·آ± ط·آ§ط¸â€‍ط¸â€¦ط¸ئ’ط·آ§ط¸â€ ط¸ظ¹ ط·آ§ط¸â€‍ط·آ¥ط¸ظ¹ط·آ¬ط·آ§ط·آ¨ط¸ظ¹: $error',
        stagingMessage: null,
      );
    }
  }

  Future<void> saveSelectedDraftToStaging() async {
    final record = state.selectedRecord;
    if (record == null) return;
    state = state.copyWith(
      isStagingBusy: true,
      stagingErrorMessage: null,
      stagingMessage:
          'ط·آ¬ط·آ§ط·آ±ط¸ظ¹ ط·آ­ط¸ظ¾ط·آ¸ ط·آ§ط¸â€‍ط·آ³ط·آ¬ط¸â€‍ ط·آ§ط¸â€‍ط¸â€¦ط·آ­ط·آ¯ط·آ¯ ط¸ظ¾ط¸ظ¹ mustakshif_staging ط¸ئ’ط¸â€¦ط·آ³ط¸ث†ط·آ¯ط·آ© ط¸â€¦ط·آ±ط·آ§ط·آ¬ط·آ¹ط·آ©...',
    );
    try {
      final decision = record.reviewerOneDecision != PwfReviewDecision.none
          ? record.reviewerOneDecision
          : record.reviewerTwoDecision != PwfReviewDecision.none
              ? record.reviewerTwoDecision
              : null;
      final result = await _stagingRepository.saveDraft(
        record: record,
        sourceLocator: record.sourceLocator,
        reviewerIndex: decision == null ? null : 1,
        decision: decision,
        note: record.reviewerOneNote.isNotEmpty
            ? record.reviewerOneNote
            : record.reviewerTwoNote,
        metadata: <String, dynamic>{
          'flutter_action': 'save_selected_draft_to_staging',
          'runtime_backend': state.runtimeBackendLabel,
          'policy': 'review_only_not_final',
        },
      );
      state = state.copyWith(
        isStagingBusy: false,
        stagingMessage:
            'ط¸â€ ط·ع¾ط¸ظ¹ط·آ¬ط·آ© ط·آ­ط¸ظ¾ط·آ¸ ط·آ§ط¸â€‍ط·آ³ط·آ¬ط¸â€‍: ${result.compactLine}',
        stagingLastRpcLine:
            'rpc=rpc_mustakshif_review_board_draft_save_v1; ${result.compactLine}',
        stagingErrorMessage: result.ok
            ? null
            : 'RPC ط·آ£ط·آ¹ط·آ§ط·آ¯ ok=false ط·آ¹ط¸â€ ط·آ¯ ط·آ­ط¸ظ¾ط·آ¸ ط·آ§ط¸â€‍ط·آ³ط·آ¬ط¸â€‍.',
        lastPersistedAt: DateTime.now(),
      );
    } catch (error) {
      state = state.copyWith(
        isStagingBusy: false,
        stagingErrorMessage:
            'ط¸ظ¾ط·آ´ط¸â€‍ ط·آ­ط¸ظ¾ط·آ¸ ط·آ§ط¸â€‍ط·آ³ط·آ¬ط¸â€‍ ط¸ظ¾ط¸ظ¹ staging: $error',
        stagingMessage: null,
      );
    }
  }

  Future<void> logSelectedMapHookToStaging() async {
    final record = state.selectedRecord;
    if (record == null) return;
    const adapter = PwfStandaloneRealMapHookAdapter();
    final envelope = adapter.buildEnvelope(record);
    final enabledCommands = envelope.commands
        .where((command) => command.enabled)
        .toList(growable: false);

    if (enabledCommands.isEmpty) {
      state = state.copyWith(
        isStagingBusy: false,
        stagingErrorMessage: null,
        stagingMessage:
            'ط¸â€‍ط¸â€¦ ط¸ظ¹ط·ع¾ط¸â€¦ ط·آ¥ط·آ±ط·آ³ط·آ§ط¸â€‍ map hook ط¸â€‍ط·آ£ط¸â€  ط·آ§ط¸â€‍ط·آ³ط·آ¬ط¸â€‍ ${record.id} ط¸â€‍ط·آ§ ط¸ظ¹ط·آ­ط·ع¾ط¸ث†ط¸ظ¹ ط¸â€ ط¸â€ڑط·آ·ط·آ© ط·ع¾ط·آ§ط·آ±ط¸ظ¹ط·آ®ط¸ظ¹ط·آ© ط·آ£ط¸ث† centroid ط¸â€¦ط·آ±ط·آ´ط·آ­ ط·آ£ط¸ث† bbox. ط¸â€،ط·آ°ط·آ§ ط·آ­ط·آ¬ط·آ¨ ط·آ­ط¸ث†ط¸ئ’ط¸â€¦ط¸ظ¹ ط·آµط·آ­ط¸ظ¹ط·آ­ ط¸ث†ط¸â€‍ط¸ظ¹ط·آ³ ط¸ظ¾ط·آ´ط¸â€‍ RPC.',
        stagingLastRpcLine:
            'rpc=not_sent; record=${record.id}; validation=${envelope.validationCode}; governance=blocked_no_navigation_payload; policy=navigation_only_no_layer_mutation',
        lastPersistedAt: DateTime.now(),
      );
      return;
    }

    final command = enabledCommands.firstWhere(
      (item) => item.commandCode == envelope.cameraCommand,
      orElse: () => enabledCommands.first,
    );

    state = state.copyWith(
      isStagingBusy: true,
      stagingErrorMessage: null,
      stagingMessage:
          'ط·آ¬ط·آ§ط·آ±ط¸ظ¹ ط·ع¾ط·آ³ط·آ¬ط¸ظ¹ط¸â€‍ map hook navigation-only...',
    );
    try {
      final result = await _stagingRepository.logMapHookEvent(
        envelope: envelope,
        command: command,
      );
      state = state.copyWith(
        isStagingBusy: false,
        stagingMessage: 'ط¸â€ ط·ع¾ط¸ظ¹ط·آ¬ط·آ© map hook: ${result.compactLine}',
        stagingLastRpcLine:
            'rpc=rpc_mustakshif_map_hook_event_log_v1; command=${command.commandCode}; ${result.compactLine}',
        stagingErrorMessage: result.ok
            ? null
            : 'RPC ط·آ£ط·آ¹ط·آ§ط·آ¯ ok=false ط·آ¹ط¸â€ ط·آ¯ ط·ع¾ط·آ³ط·آ¬ط¸ظ¹ط¸â€‍ map hook.',
        lastPersistedAt: DateTime.now(),
      );
    } catch (error) {
      state = state.copyWith(
        isStagingBusy: false,
        stagingErrorMessage:
            'ط¸ظ¾ط·آ´ط¸â€‍ ط·ع¾ط·آ³ط·آ¬ط¸ظ¹ط¸â€‍ map hook ط¸ظ¾ط¸ظ¹ staging: $error',
        stagingMessage: null,
      );
    }
  }

  Future<void> logFilteredExportQaToStaging() async {
    final csv = state.exportFilteredRecordsCsv();
    state = state.copyWith(
      isStagingBusy: true,
      stagingErrorMessage: null,
      stagingMessage:
          'ط·آ¬ط·آ§ط·آ±ط¸ظ¹ ط·ع¾ط·آ³ط·آ¬ط¸ظ¹ط¸â€‍ Export QA ط¸â€‍ط¸â€‍ط·آ¹ط·آ±ط·آ¶ ط·آ§ط¸â€‍ط¸â€¦ط¸ظ¾ط¸â€‍ط·ع¾ط·آ±...',
    );
    try {
      final result = await _stagingRepository.logExportQa(
        exportScope: 'filtered_runtime_view',
        filename: 'mustakshif_review_board_filtered_runtime_view.csv',
        rowCount: state.filteredRecords.length,
        bytesLength: utf8.encode('\ufeff$csv').length,
        checksum: _fnv1a32(utf8.encode('\ufeff$csv')),
        manifest: <String, dynamic>{
          'flutter_action': 'log_filtered_export_qa_to_staging',
          'governance': 'review_only_not_final',
          'map_policy': 'navigation_only_no_layer_mutation',
        },
      );
      state = state.copyWith(
        isStagingBusy: false,
        stagingMessage:
            'ط¸â€ ط·ع¾ط¸ظ¹ط·آ¬ط·آ© Export QA: ${result.compactLine}',
        stagingLastRpcLine:
            'rpc=rpc_mustakshif_review_board_export_qa_v1; rows=${state.filteredRecords.length}; ${result.compactLine}',
        stagingErrorMessage: result.ok
            ? null
            : 'RPC ط·آ£ط·آ¹ط·آ§ط·آ¯ ok=false ط·آ¹ط¸â€ ط·آ¯ ط·ع¾ط·آ³ط·آ¬ط¸ظ¹ط¸â€‍ Export QA.',
        lastPersistedAt: DateTime.now(),
      );
    } catch (error) {
      state = state.copyWith(
        isStagingBusy: false,
        stagingErrorMessage:
            'ط¸ظ¾ط·آ´ط¸â€‍ ط·ع¾ط·آ³ط·آ¬ط¸ظ¹ط¸â€‍ Export QA ط¸ظ¾ط¸ظ¹ staging: $error',
        stagingMessage: null,
      );
    }
  }

  static PwfReviewRecord _buildPositiveSpatialSmokeRecord() {
    return const PwfReviewRecord(
      id: 'TEST-Mredacted-local-placeholder',
      placeNameAr:
          'ط·آ³ط·آ¬ط¸â€‍ ط·آ§ط·آ®ط·ع¾ط·آ¨ط·آ§ط·آ± ط¸â€¦ط¸ئ’ط·آ§ط¸â€ ط¸ظ¹ ط·آ¥ط¸ظ¹ط·آ¬ط·آ§ط·آ¨ط¸ظ¹',
      currentCandidateAr:
          'ط¸â€¦ط·آ±ط·آ´ط·آ­ ط¸â€¦ط¸ئ’ط·آ§ط¸â€ ط¸ظ¹ ط·ع¾ط·آ¬ط·آ±ط¸ظ¹ط·آ¨ط¸ظ¹ أ¢â‚¬â€‌ fit bbox',
      queue: PwfReviewQueue.f2,
      reviewStatus: 'draft',
      distanceMeters: 650,
      locatorStatus: PwfLocatorStatus.submitted,
      periodLabelAr:
          'ط·آ§ط·آ®ط·ع¾ط·آ¨ط·آ§ط·آ± ط·آ¯ط·آ®ط·آ§ط¸â€  ط¸â€¦ط¸ئ’ط·آ§ط¸â€ ط¸ظ¹',
      adminDivisionAr:
          'ط·ع¾ط¸â€ڑط·آ³ط¸ظ¹ط¸â€¦ ط·آ§ط·آ®ط·ع¾ط·آ¨ط·آ§ط·آ± أ¢â‚¬â€‌ ط·ط›ط¸ظ¹ط·آ± ط·آ³ط¸ظ¹ط·آ§ط·آ¯ط¸ظ¹',
      candidateType: 'positive_spatial_payload_smoke_test',
      confidenceScore: 80,
      geometryStatus: 'ready_full_map_hook',
      warningLabel: 'positive_spatial_payload_smoke_test_not_production',
      sourceLocator: PwfSourceLocator(
        sourceTitle:
            'ط¸â€¦ط·آµط·آ¯ط·آ± ط·آ§ط·آ®ط·ع¾ط·آ¨ط·آ§ط·آ± ط¸â€¦ط¸ئ’ط·آ§ط¸â€ ط¸ظ¹ ط·آ¯ط·آ§ط·آ®ط¸â€‍ط¸ظ¹',
        sourceType: 'manual_sandbox_smoke_test',
        locatorText:
            'ط·آ³ط·آ¬ط¸â€‍ ط¸â€¦ط·آµط¸â€ ط¸ث†ط·آ¹ ط¸â€‍ط·آ§ط·آ®ط·ع¾ط·آ¨ط·آ§ط·آ± ط·آ¥ط·آ±ط·آ³ط·آ§ط¸â€‍ map hook ط·آ§ط¸â€‍ط·آ¥ط¸ظ¹ط·آ¬ط·آ§ط·آ¨ط¸ظ¹ ط¸â€¦ط¸â€  Flutter runtime ط¸ظ¾ط¸â€ڑط·آ·.',
        evidenceNote:
            'ط·ط›ط¸ظ¹ط·آ± ط¸â€¦ط·آ¹ط·ع¾ط¸â€¦ط·آ¯ ط·آ³ط¸ظ¹ط·آ§ط·آ¯ط¸ظ¹ط¸â€¹ط·آ§ط·â€؛ ط¸ظ¹ط·آ³ط·ع¾ط·آ®ط·آ¯ط¸â€¦ ط¸â€‍ط·آ¥ط·آ«ط·آ¨ط·آ§ط·ع¾ fit_bbox navigation-only ط·آ¯ط·آ§ط·آ®ط¸â€‍ mustakshif_staging.',
        page: 'sandbox',
        tableName: 'mustakshif_staging.review_board_records',
        rowReference: 'TEST-Mredacted-local-placeholder',
      ),
      reviewerOneDecision: PwfReviewDecision.needsMoreEvidence,
      reviewerOneNote:
          'ط·آ§ط·آ®ط·ع¾ط·آ¨ط·آ§ط·آ± ط·آ¥ط¸ظ¹ط·آ¬ط·آ§ط·آ¨ط¸ظ¹ ط¸â€‍ط¸â€¦ط·آ³ط·آ§ط·آ± map hook ط·آ¯ط¸ث†ط¸â€  ط·ع¾ط·ط›ط¸ظ¹ط¸ظ¹ط·آ± ط·آ·ط·آ¨ط¸â€ڑط·آ§ط·ع¾.',
      historicalLat: 31.70510,
      historicalLon: 35.20210,
      candidateLat: 31.70540,
      candidateLon: 35.20240,
      bboxSouth: 31.70470,
      bboxWest: 35.20170,
      bboxNorth: 31.70610,
      bboxEast: 35.20310,
      mapAdapterStatus: 'positive_spatial_payload_smoke_test',
    );
  }

  Future<void> refreshLocalDraftHealth() async {
    final draftHealth = await _draftStore.inspectHealth();
    state = state.copyWith(
      localDraftHealthLabel: draftHealth.labelAr,
      persistenceMessage: draftHealth.labelAr,
      lastPersistedAt: DateTime.now(),
      errorMessage: draftHealth.errorMessage == null
          ? null
          : 'ط·ع¾ط·آ­ط·آ°ط¸ظ¹ط·آ± ط¸â€ڑط·آ±ط·آ§ط·طŒط·آ© ط·آ§ط¸â€‍ط¸â€¦ط·آ³ط¸ث†ط·آ¯ط·آ§ط·ع¾ ط·آ§ط¸â€‍ط¸â€¦ط·آ­ط¸â€‍ط¸ظ¹ط·آ©: ${draftHealth.errorMessage}',
    );
  }

  Future<void> clearLocalDrafts() async {
    await _draftStore.clear();
    state = state.copyWith(
      localDraftRecordIds: <String>{},
      localDraftHealthLabel:
          'ط¸â€‍ط·آ§ ط·ع¾ط¸ث†ط·آ¬ط·آ¯ ط¸â€¦ط·آ³ط¸ث†ط·آ¯ط·آ§ط·ع¾ ط¸â€¦ط·آ­ط¸â€‍ط¸ظ¹ط·آ©',
      lastSaveVerificationLine: null,
      persistenceMessage:
          'ط·ع¾ط¸â€¦ ط¸â€¦ط·آ³ط·آ­ ط·آ§ط¸â€‍ط¸â€¦ط·آ³ط¸ث†ط·آ¯ط·آ§ط·ع¾ ط·آ§ط¸â€‍ط¸â€¦ط·آ­ط¸â€‍ط¸ظ¹ط·آ©. ط·آ£ط·آ¹ط·آ¯ ط·ع¾ط·آ­ط¸â€¦ط¸ظ¹ط¸â€‍ CSV ط¸â€‍ط¸â€‍ط·آ±ط·آ¬ط¸ث†ط·آ¹ ط·آ¥ط¸â€‍ط¸â€° ط·آ¨ط¸ظ¹ط·آ§ط¸â€ ط·آ§ط·ع¾ ط·آ§ط¸â€‍ط¸â€¦ط·آµط·آ¯ط·آ±.',
      lastPersistedAt: DateTime.now(),
    );
    await load();
  }

  void recordExportVerification(String verificationLine) {
    state = state.copyWith(
      lastExportVerificationLine: verificationLine,
      persistenceMessage:
          'ط·ع¾ط¸â€¦ ط·ع¾ط·آ³ط·آ¬ط¸ظ¹ط¸â€‍ ط·ع¾ط·آ­ط¸â€ڑط¸â€ڑ ط·آ§ط¸â€‍ط·ع¾ط·آµط·آ¯ط¸ظ¹ط·آ±: $verificationLine',
      lastPersistedAt: DateTime.now(),
      errorMessage: null,
    );
  }

  static String _fnv1a32(List<int> bytes) {
    var hash = 0x811c9dc5;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  void _updateRecordsAndPersist({
    required List<PwfReviewRecord> records,
    required String recordId,
    required String message,
  }) {
    final updatedRecord = records.firstWhere((record) => record.id == recordId);
    final draftIds = {...state.localDraftRecordIds, recordId};
    state = state.copyWith(
      records: records,
      selectedRecordId: recordId,
      localDraftRecordIds: draftIds,
      persistenceMessage: message,
      lastPersistedAt: DateTime.now(),
      errorMessage: null,
    );
    unawaited(
      _draftStore.saveRecord(updatedRecord).then((result) {
        state = state.copyWith(
          persistenceMessage: '$message ${result.messageAr}',
          lastSaveVerificationLine:
              'record=${result.recordId}; drafts=${result.draftCount}; bytes=${result.bytesLength}; checksum=${result.checksum}; verified=${result.verified}',
          localDraftHealthLabel:
              'drafts=${result.draftCount}; checksum=${result.checksum}',
          lastPersistedAt: result.savedAt,
          errorMessage: result.verified
              ? null
              : 'ط·ع¾ط¸â€¦ ط·آ§ط¸â€‍ط·آ­ط¸ظ¾ط·آ¸ ط¸â€‍ط¸ئ’ط¸â€  ط¸ظ¾ط·آ´ط¸â€‍ ط·ع¾ط·آ­ط¸â€ڑط¸â€ڑ ط·آ§ط¸â€‍ط¸â€ڑط·آ±ط·آ§ط·طŒط·آ© ط·آ§ط¸â€‍ط¸â€‍ط·آ§ط·آ­ط¸â€ڑط·آ© ط¸â€‍ط¸â€‍ط¸â€¦ط·آ³ط¸ث†ط·آ¯ط·آ©.',
        );
      }).catchError((Object error) {
        state = state.copyWith(
          errorMessage:
              'ط¸ظ¾ط·آ´ط¸â€‍ ط·آ­ط¸ظ¾ط·آ¸ ط·آ§ط¸â€‍ط¸â€¦ط·آ³ط¸ث†ط·آ¯ط·آ© ط¸â€¦ط·آ­ط¸â€‍ط¸ظ¹ط¸â€¹ط·آ§: $error',
          persistenceMessage: null,
        );
      }),
    );
  }
}
