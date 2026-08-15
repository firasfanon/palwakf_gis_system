import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/pwf_review_enums.dart';
import '../domain/pwf_review_record.dart';
import '../domain/pwf_source_locator.dart';
import 'pwf_real_map_hook_contract.dart';
import 'pwf_review_board_repository.dart';

/// Supabase staging adapter for Mustakshif Review Board.
///
/// This adapter is intentionally not bound to the default Riverpod provider yet.
/// The active UI must continue to use CSV/local drafts until SQL V1 + V1A pass
/// the sandbox test queries documented in the session handoff.
///
/// Governance guardrails:
/// - Reads/writes only through public RPC wrappers.
/// - No direct writes to core, waqf, awqaf_system, or gis.
/// - Map hook logging accepts navigation-only camera commands.
/// - No layer activation/deactivation and no activeLayers mutation.
abstract interface class PwfStagingReviewBoardRepository implements PwfReviewBoardRepository {
  Future<PwfReviewBoardAccessDiagnostics> fetchAccessDiagnostics();

  Future<PwfReviewBoardRpcResult> selfEnableSandbox({
    required String reason,
    int minutes = 120,
  });

  Future<PwfReviewBoardRpcResult> fetchRbacVerificationMatrix();

  Future<PwfReviewBoardRpcResult> fetchFinalIntegrationReadiness();

  Future<PwfReviewBoardRpcResult> retireAuthenticatedSandboxOverride({
    required String reason,
  });

  Future<PwfReviewBoardRpcResult> saveDraft({
    required PwfReviewRecord record,
    PwfSourceLocator? sourceLocator,
    int? reviewerIndex,
    PwfReviewDecision? decision,
    String? note,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  });

  Future<PwfReviewBoardRpcResult> logMapHookEvent({
    required PwfMapHookEnvelope envelope,
    required PwfMapHookCommand command,
  });

  Future<PwfReviewBoardRpcResult> logExportQa({
    required String exportScope,
    required String filename,
    required int rowCount,
    required int bytesLength,
    required String checksum,
    Map<String, dynamic> manifest = const <String, dynamic>{},
  });
}

class PwfSupabaseReviewBoardRepository implements PwfStagingReviewBoardRepository {
  const PwfSupabaseReviewBoardRepository(this._client);

  static const String queueRpc = 'rpc_mustakshif_review_board_queue_v1';
  static const String draftSaveRpc = 'rpc_mustakshif_review_board_draft_save_v1';
  static const String draftsForUserRpc = 'rpc_mustakshif_review_board_drafts_for_user_v1';
  static const String exportQaRpc = 'rpc_mustakshif_review_board_export_qa_v1';
  static const String mapHookLogRpc = 'rpc_mustakshif_map_hook_event_log_v1';
  static const String accessDiagnosticsRpc = 'rpc_mustakshif_review_board_access_diagnostics_v1';
  static const String selfEnableSandboxRpc = 'rpc_mustakshif_review_board_self_enable_sandbox_v1';
  static const String rbacVerificationMatrixRpc =
      'rpc_mustakshif_review_board_rbac_mapping_verification_matrix_v1';
  static const String finalIntegrationReadinessRpc =
      'rpc_mustakshif_review_board_final_integration_readiness_v1';
  static const String retireSandboxOverrideRpc =
      'rpc_mustakshif_review_board_retire_my_sandbox_override_v1';

  final SupabaseClient _client;

  @override
  Future<List<PwfReviewRecord>> fetchQueue({String? queueCode}) async {
    final response = await _client.rpc(queueRpc);
    final rows = response is List ? response : const <dynamic>[];
    final normalizedQueue = queueCode?.trim();
    final records = rows
        .map(_asMap)
        .where((row) => row.isNotEmpty)
        .map(_mapQueueRow)
        .where(
          (record) => normalizedQueue == null ||
              normalizedQueue.isEmpty ||
              normalizedQueue == 'all' ||
              record.queueCode == normalizedQueue,
        )
        .toList(growable: false);
    return records;
  }

  @override
  Future<PwfReviewBoardAccessDiagnostics> fetchAccessDiagnostics() async {
    final response = await _client.rpc(accessDiagnosticsRpc);
    return PwfReviewBoardAccessDiagnostics.fromJson(_asMap(response));
  }

  @override
  Future<PwfReviewBoardRpcResult> selfEnableSandbox({
    required String reason,
    int minutes = 120,
  }) async {
    final response = await _client.rpc(
      selfEnableSandboxRpc,
      params: <String, dynamic>{
        'p_reason': reason,
        'p_minutes': minutes,
      },
    );
    return PwfReviewBoardRpcResult.fromJson(_asMap(response));
  }

  @override
  Future<PwfReviewBoardRpcResult> fetchRbacVerificationMatrix() async {
    final response = await _client.rpc(rbacVerificationMatrixRpc);
    return PwfReviewBoardRpcResult.fromJson(_asMap(response));
  }

  @override
  Future<PwfReviewBoardRpcResult> fetchFinalIntegrationReadiness() async {
    final response = await _client.rpc(finalIntegrationReadinessRpc);
    return PwfReviewBoardRpcResult.fromJson(_asMap(response));
  }

  @override
  Future<PwfReviewBoardRpcResult> retireAuthenticatedSandboxOverride({
    required String reason,
  }) async {
    final response = await _client.rpc(
      retireSandboxOverrideRpc,
      params: <String, dynamic>{
        'p_reason': reason,
      },
    );
    return PwfReviewBoardRpcResult.fromJson(_asMap(response));
  }

  @override
  Future<PwfReviewBoardRpcResult> saveDraft({
    required PwfReviewRecord record,
    PwfSourceLocator? sourceLocator,
    int? reviewerIndex,
    PwfReviewDecision? decision,
    String? note,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final response = await _client.rpc(
      draftSaveRpc,
      params: <String, dynamic>{
        'p_record_id': record.id,
        'p_record_payload': _recordPayload(record),
        'p_source_locator': sourceLocator == null ? null : _sourceLocatorPayload(record, sourceLocator),
        'p_reviewer_index': reviewerIndex,
        'p_decision_code': _toSqlDecisionCode(decision),
        'p_note': note,
        'p_metadata': <String, dynamic>{
          'adapter': 'flutter_supabase_staging_preparation',
          'governance': 'review_only_not_final',
          'map_policy': 'navigation_only_no_layer_mutation',
          ...metadata,
        },
      },
    );
    return PwfReviewBoardRpcResult.fromJson(_asMap(response));
  }

  @override
  Future<PwfReviewBoardRpcResult> logMapHookEvent({
    required PwfMapHookEnvelope envelope,
    required PwfMapHookCommand command,
  }) async {
    if (!command.enabled) {
      return PwfReviewBoardRpcResult(
        ok: false,
        payload: <String, dynamic>{
          'ok': false,
          'record_id': envelope.recordId,
          'command_code': command.commandCode,
          'reason': command.reasonAr,
          'governance': 'disabled_navigation_command_not_sent',
        },
      );
    }

    final response = await _client.rpc(
      mapHookLogRpc,
      params: <String, dynamic>{
        'p_record_id': envelope.recordId,
        'p_command_code': command.commandCode,
        'p_command_payload': _mapCommandPayload(envelope, command),
        'p_validation_code': envelope.validationCode,
      },
    );
    return PwfReviewBoardRpcResult.fromJson(_asMap(response));
  }

  @override
  Future<PwfReviewBoardRpcResult> logExportQa({
    required String exportScope,
    required String filename,
    required int rowCount,
    required int bytesLength,
    required String checksum,
    Map<String, dynamic> manifest = const <String, dynamic>{},
  }) async {
    final response = await _client.rpc(
      exportQaRpc,
      params: <String, dynamic>{
        'p_export_scope': exportScope,
        'p_filename': filename,
        'p_row_count': rowCount,
        'p_bytes_length': bytesLength,
        'p_checksum': checksum,
        'p_manifest': <String, dynamic>{
          'adapter': 'flutter_supabase_staging_preparation',
          'governance': 'review_only_not_final',
          ...manifest,
        },
      },
    );
    return PwfReviewBoardRpcResult.fromJson(_asMap(response));
  }

  PwfReviewRecord _mapQueueRow(Map<String, dynamic> row) {
    final sourcePayload = _asMap(row['source_payload']);
    final metadata = _asMap(row['metadata']);
    final sourceLocator = _locatorFromPayload(sourcePayload, metadata);
    final hasLocator = _asBool(row['has_locator']);
    final queueCode = _normalizeQueueCode(_asText(row['queue_code'] ?? row['queue']));

    return PwfReviewRecord(
      id: _asText(row['record_id'] ?? row['id']),
      placeNameAr: _asText(row['place_name_ar'] ?? row['historical_name_ar'] ?? sourcePayload['place_name_ar']),
      currentCandidateAr: _asText(
        row['current_candidate_ar'] ?? row['core_candidate_name_ar'] ?? sourcePayload['current_candidate_ar'],
      ),
      queue: PwfReviewQueue.fromCode(queueCode),
      reviewStatus: _asText(row['review_status'], fallback: 'review_only_not_final'),
      distanceMeters: _asDouble(row['distance_meters'] ?? sourcePayload['distance_meters']),
      locatorStatus: _locatorStatusFromPayload(sourcePayload, hasLocator, sourceLocator),
      periodLabelAr: _asText(row['period_label_ar'] ?? row['period'] ?? sourcePayload['period_label_ar']),
      adminDivisionAr: _asText(row['admin_division_ar'] ?? sourcePayload['admin_division_ar']),
      candidateType: _asText(row['candidate_type'] ?? sourcePayload['candidate_type'] ?? metadata['candidate_type']),
      confidenceScore: _confidenceScore(row['confidence_score'] ?? sourcePayload['confidence_score']),
      geometryStatus: _asText(row['geometry_status'] ?? sourcePayload['geometry_status']),
      warningLabel: _asText(row['warning_label'] ?? sourcePayload['warning_label'], fallback: 'review_only_not_final'),
      sourceLocator: sourceLocator,
      historicalLat: _asDouble(row['historical_lat'] ?? sourcePayload['historical_lat'] ?? metadata['historical_lat']),
      historicalLon: _asDouble(row['historical_lon'] ?? sourcePayload['historical_lon'] ?? metadata['historical_lon']),
      candidateLat: _asDouble(row['candidate_lat'] ?? sourcePayload['candidate_lat'] ?? metadata['candidate_lat']),
      candidateLon: _asDouble(row['candidate_lon'] ?? sourcePayload['candidate_lon'] ?? metadata['candidate_lon']),
      bboxSouth: _asDouble(row['bbox_south'] ?? sourcePayload['bbox_south'] ?? metadata['bbox_south']),
      bboxWest: _asDouble(row['bbox_west'] ?? sourcePayload['bbox_west'] ?? metadata['bbox_west']),
      bboxNorth: _asDouble(row['bbox_north'] ?? sourcePayload['bbox_north'] ?? metadata['bbox_north']),
      bboxEast: _asDouble(row['bbox_east'] ?? sourcePayload['bbox_east'] ?? metadata['bbox_east']),
      updatedAt: _asDate(row['updated_at']),
      mapAdapterStatus: _asText(
        sourcePayload['map_adapter_status'] ?? metadata['map_adapter_status'],
        fallback: 'supabase_staging_queue_v1',
      ),
    );
  }

  static Map<String, dynamic> _recordPayload(PwfReviewRecord record) {
    return <String, dynamic>{
      'record_id': record.id,
      'place_name_ar': record.placeNameAr,
      'current_candidate_ar': record.currentCandidateAr,
      'period_label_ar': record.periodLabelAr,
      'admin_division_ar': record.adminDivisionAr,
      'queue_code': record.queueCode,
      'review_status': record.reviewStatus,
      'distance_meters': record.distanceMeters,
      'confidence_score': record.confidenceScore / 100,
      'geometry_status': record.geometryStatus,
      'warning_label': record.warningLabel,
      'candidate_type': record.candidateType,
      'historical_lat': record.historicalLat,
      'historical_lon': record.historicalLon,
      'candidate_lat': record.candidateLat,
      'candidate_lon': record.candidateLon,
      'bbox_south': record.bboxSouth,
      'bbox_west': record.bboxWest,
      'bbox_north': record.bboxNorth,
      'bbox_east': record.bboxEast,
      'map_adapter_status': record.mapAdapterStatus,
      'map_camera_intent_code': record.mapCameraIntentCode,
      'map_adapter_readiness_code': record.mapAdapterReadinessCode,
      'governance': 'review_only_not_final',
    }..removeWhere((_, value) => value == null || value == '');
  }

  static Map<String, dynamic> _sourceLocatorPayload(PwfReviewRecord record, PwfSourceLocator locator) {
    return <String, dynamic>{
      'locator_status': locator.isComplete ? 'submitted' : 'draft',
      'source_title': locator.sourceTitle,
      'source_type': locator.sourceType,
      'locator_text': locator.locatorText,
      'evidence_note': locator.evidenceNote,
      'page_reference': locator.page,
      'table_name': locator.tableName,
      'row_reference': locator.rowReference,
      'historical_lat': record.historicalLat,
      'historical_lon': record.historicalLon,
      'candidate_lat': record.candidateLat,
      'candidate_lon': record.candidateLon,
      'governance': 'source_locator_review_draft',
    }..removeWhere((_, value) => value == null || value == '');
  }

  static Map<String, dynamic> _mapCommandPayload(PwfMapHookEnvelope envelope, PwfMapHookCommand command) {
    return <String, dynamic>{
      'record_id': envelope.recordId,
      'camera_command': envelope.cameraCommand,
      'command_code': command.commandCode,
      'lat': command.lat,
      'lon': command.lon,
      'bbox': command.commandCode == 'fit_bbox'
          ? <String, dynamic>{
              'south': command.south,
              'west': command.west,
              'north': command.north,
              'east': command.east,
            }
          : null,
      'layer_policy': envelope.layerPolicy,
      'rpc_policy': envelope.rpcPolicy,
      'validation_code': envelope.validationCode,
      'governance': 'navigation_only_no_layer_mutation',
    }..removeWhere((_, value) => value == null || value == '');
  }

  static PwfSourceLocator? _locatorFromPayload(Map<String, dynamic> sourcePayload, Map<String, dynamic> metadata) {
    final locatorMap = _asMap(sourcePayload['source_locator']);
    final directMap = <String, dynamic>{
      'source_title': sourcePayload['source_title'] ?? metadata['source_title'],
      'source_type': sourcePayload['source_type'] ?? metadata['source_type'],
      'locator_text': sourcePayload['locator_text'] ?? metadata['locator_text'],
      'evidence_note': sourcePayload['evidence_note'] ?? metadata['evidence_note'],
      'page': sourcePayload['page'] ?? sourcePayload['page_reference'] ?? metadata['page'],
      'table_name': sourcePayload['table_name'] ?? metadata['table_name'],
      'row_reference': sourcePayload['row_reference'] ?? metadata['row_reference'],
    }..removeWhere((_, value) => value == null || '$value'.trim().isEmpty);

    final raw = locatorMap.isNotEmpty ? locatorMap : directMap;
    if (raw.isEmpty) return null;
    final locator = PwfSourceLocator.fromJson(raw);
    return locator.isComplete ? locator : null;
  }

  static PwfLocatorStatus _locatorStatusFromPayload(
    Map<String, dynamic> sourcePayload,
    bool hasLocator,
    PwfSourceLocator? sourceLocator,
  ) {
    final raw = _asText(sourcePayload['locator_status'] ?? sourcePayload['source_locator_status']).toLowerCase();
    return switch (raw) {
      'locator_verified' || 'verified' || 'reviewed' => PwfLocatorStatus.verified,
      'locator_rejected' || 'rejected' => PwfLocatorStatus.rejected,
      'locator_submitted' || 'submitted' => PwfLocatorStatus.submitted,
      'locator_draft' || 'draft' => PwfLocatorStatus.draft,
      _ => sourceLocator != null || hasLocator ? PwfLocatorStatus.submitted : PwfLocatorStatus.missing,
    };
  }

  static String _normalizeQueueCode(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (normalized == 'F1' || normalized == 'F2' || normalized == 'F3' || normalized == 'F4') {
      return normalized;
    }
    final lower = raw.trim().toLowerCase();
    if (lower.contains('source') || lower.contains('locator')) return 'F1';
    if (lower.contains('spatial') || lower.contains('boundary')) return 'F2';
    if (lower.contains('geometry') || lower.contains('repair')) return 'F3';
    return 'F4';
  }

  static String? _toSqlDecisionCode(PwfReviewDecision? decision) {
    return switch (decision) {
      null || PwfReviewDecision.none => null,
      PwfReviewDecision.approveCandidate => 'approve',
      PwfReviewDecision.rejectCandidate => 'reject',
      PwfReviewDecision.needsMoreEvidence => 'needs_more_evidence',
      PwfReviewDecision.needsGeometryRepair => 'spatial_review_required',
      PwfReviewDecision.manualResearch => 'needs_more_evidence',
    };
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  static String _asText(dynamic value, {String fallback = ''}) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? fallback : text;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    final text = '$value'.trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    final text = '$value'.trim();
    if (text.isEmpty || text == 'null') return null;
    return double.tryParse(text);
  }

  static int _confidenceScore(dynamic value) {
    final parsed = _asDouble(value);
    if (parsed == null) return 0;
    final percentage = parsed <= 1 ? parsed * 100 : parsed;
    return percentage.round().clamp(0, 100).toInt();
  }

  static DateTime? _asDate(dynamic value) {
    final text = '$value'.trim();
    if (text.isEmpty || text == 'null') return null;
    return DateTime.tryParse(text);
  }
}

class PwfReviewBoardAccessDiagnostics {
  const PwfReviewBoardAccessDiagnostics({
    required this.userId,
    required this.authRole,
    required this.jwtRole,
    required this.jwtRoles,
    required this.hasReadOverride,
    required this.hasWriteOverride,
    required this.readAllowed,
    required this.writeAllowed,
    required this.sqlEditorContext,
    required this.sqlEditorReadFlagActive,
    required this.sqlEditorWriteFlagActive,
    required this.effectiveActorId,
    required this.payload,
  });

  factory PwfReviewBoardAccessDiagnostics.fromJson(Map<String, dynamic> json) {
    final jwtRolesValue = json['jwt_roles'];
    final jwtRoles = jwtRolesValue is List
        ? jwtRolesValue.map((value) => '$value').where((value) => value.trim().isNotEmpty).toList(growable: false)
        : const <String>[];
    return PwfReviewBoardAccessDiagnostics(
      userId: _nullableText(json['user_id']),
      authRole: _nullableText(json['auth_role']),
      jwtRole: _nullableText(json['jwt_role']),
      jwtRoles: jwtRoles,
      hasReadOverride: PwfSupabaseReviewBoardRepository._asBool(json['has_read_override']),
      hasWriteOverride: PwfSupabaseReviewBoardRepository._asBool(json['has_write_override']),
      readAllowed: PwfSupabaseReviewBoardRepository._asBool(json['read_allowed']),
      writeAllowed: PwfSupabaseReviewBoardRepository._asBool(json['write_allowed']),
      sqlEditorContext: PwfSupabaseReviewBoardRepository._asBool(json['sql_editor_context']),
      sqlEditorReadFlagActive: PwfSupabaseReviewBoardRepository._asBool(json['sql_editor_read_flag_active']),
      sqlEditorWriteFlagActive: PwfSupabaseReviewBoardRepository._asBool(json['sql_editor_write_flag_active']),
      effectiveActorId: _nullableText(json['effective_actor_id']),
      payload: Map<String, dynamic>.unmodifiable(json),
    );
  }

  final String? userId;
  final String? authRole;
  final String? jwtRole;
  final List<String> jwtRoles;
  final bool hasReadOverride;
  final bool hasWriteOverride;
  final bool readAllowed;
  final bool writeAllowed;
  final bool sqlEditorContext;
  final bool sqlEditorReadFlagActive;
  final bool sqlEditorWriteFlagActive;
  final String? effectiveActorId;
  final Map<String, dynamic> payload;

  bool get canUseStagingWrites => writeAllowed || hasWriteOverride;

  String get labelAr {
    if (writeAllowed && sqlEditorContext) {
      return 'جاهز للكتابة التجريبية في SQL Editor sandbox عبر actor مؤقت';
    }
    if (writeAllowed) return 'جاهز للكتابة التجريبية في mustakshif_staging';
    if (readAllowed) return 'قراءة فقط؛ الكتابة تحتاج override sandbox أو RBAC';
    return 'غير مصرح؛ راجع JWT/RBAC أو V1C diagnostics';
  }

  static String? _nullableText(dynamic value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty || text == 'null' ? null : text;
  }
}

class PwfReviewBoardRpcResult {
  const PwfReviewBoardRpcResult({
    required this.ok,
    required this.payload,
  });

  factory PwfReviewBoardRpcResult.fromJson(Map<String, dynamic> json) {
    return PwfReviewBoardRpcResult(
      ok: PwfSupabaseReviewBoardRepository._asBool(json['ok']),
      payload: Map<String, dynamic>.unmodifiable(json),
    );
  }

  final bool ok;
  final Map<String, dynamic> payload;

  String? get recordId => _nullableText(payload['record_id']);
  String? get eventId => _nullableText(payload['event_id']);
  String? get qualityLabel => _nullableText(payload['quality_label']);
  String? get governance => _nullableText(payload['governance']);
  String? get integrationState => _nullableText(payload['integration_state'] ?? payload['state']);
  String? get interpretation => _nullableText(payload['interpretation']);
  String? get nextAction => _nullableText(payload['next_action']);
  bool get productionCutover => PwfSupabaseReviewBoardRepository._asBool(payload['production_cutover']);
  bool get readyForExplorerDevelopment =>
      PwfSupabaseReviewBoardRepository._asBool(payload['ready_for_explorer_development']);

  String get compactLine {
    final parts = <String>[
      'ok=$ok',
      if (recordId != null) 'record=$recordId',
      if (eventId != null) 'event=$eventId',
      if (qualityLabel != null) 'quality=$qualityLabel',
      if (governance != null) 'governance=$governance',
      if (integrationState != null) 'state=$integrationState',
      if (interpretation != null) 'interpretation=$interpretation',
      if (nextAction != null) 'next=$nextAction',
    ];
    return parts.join('; ');
  }

  static String? _nullableText(dynamic value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty || text == 'null' ? null : text;
  }
}
