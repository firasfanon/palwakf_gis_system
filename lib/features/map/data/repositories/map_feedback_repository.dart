// lib/features/map/data/repositories/map_feedback_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/models/gis_feature_model.dart';

final mapFeedbackRepositoryProvider = Provider<MapFeedbackRepository>((ref) {
  return MapFeedbackRepository(ref.watch(supabaseClientProvider));
});

class MapFeedbackSubmission {
  final String categoryCode;
  final String categoryLabel;
  final String note;
  final LatLng point;
  final GisFeatureModel? feature;
  final String? reporterContact;
  final String priority;
  final Map<String, dynamic> clientContext;

  const MapFeedbackSubmission({
    required this.categoryCode,
    required this.categoryLabel,
    required this.note,
    required this.point,
    this.feature,
    this.reporterContact,
    this.priority = 'normal',
    this.clientContext = const {},
  });

  Map<String, dynamic> toRpcParams() {
    final f = feature;
    return {
      'p_category_code': categoryCode,
      'p_category_label': categoryLabel,
      'p_note': note,
      'p_lat': point.latitude,
      'p_lng': point.longitude,
      'p_source_layer_key': f?.layerKey,
      'p_source_feature_id': f?.id,
      'p_source_feature_title': f?.displayTitle,
      'p_source_feature_props': f?.props ?? const <String, dynamic>{},
      'p_reporter_contact': reporterContact,
      'p_client_context': clientContext,
      'p_priority': priority,
    };
  }
}

class MapFeedbackReport {
  final String id;
  final String categoryCode;
  final String? categoryLabel;
  final String status;
  final String priority;
  final String? note;
  final double lat;
  final double lng;
  final String? sourceLayerKey;
  final String? sourceFeatureId;
  final String? sourceFeatureTitle;
  final String? reporterContact;
  final String? reviewerNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? reviewedAt;

  const MapFeedbackReport({
    required this.id,
    required this.categoryCode,
    this.categoryLabel,
    required this.status,
    required this.priority,
    this.note,
    required this.lat,
    required this.lng,
    this.sourceLayerKey,
    this.sourceFeatureId,
    this.sourceFeatureTitle,
    this.reporterContact,
    this.reviewerNote,
    this.createdAt,
    this.updatedAt,
    this.reviewedAt,
  });

  String get displayCategory => categoryLabel?.trim().isNotEmpty == true
      ? categoryLabel!.trim()
      : categoryCode;

  String get locationLabel =>
      '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';

  factory MapFeedbackReport.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      final text = value?.toString();
      if (text == null || text.trim().isEmpty) return null;
      return DateTime.tryParse(text);
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return MapFeedbackReport(
      id: (json['id'] ?? '').toString(),
      categoryCode: (json['category_code'] ?? '').toString(),
      categoryLabel: json['category_label']?.toString(),
      status: (json['status'] ?? 'new').toString(),
      priority: (json['priority'] ?? 'normal').toString(),
      note: json['note']?.toString(),
      lat: parseDouble(json['lat']),
      lng: parseDouble(json['lng']),
      sourceLayerKey: json['source_layer_key']?.toString(),
      sourceFeatureId: json['source_feature_id']?.toString(),
      sourceFeatureTitle: json['source_feature_title']?.toString(),
      reporterContact: json['reporter_contact']?.toString(),
      reviewerNote: json['reviewer_note']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      reviewedAt: parseDate(json['reviewed_at']),
    );
  }
}


class MapFeedbackStatusCount {
  final String status;
  final int total;

  const MapFeedbackStatusCount({required this.status, required this.total});

  factory MapFeedbackStatusCount.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['total'] ?? json['count'] ?? 0;
    return MapFeedbackStatusCount(
      status: (json['status'] ?? 'new').toString(),
      total: rawTotal is num ? rawTotal.toInt() : int.tryParse(rawTotal.toString()) ?? 0,
    );
  }
}

class MapFeedbackReviewEvent {
  final String id;
  final String reportId;
  final String? oldStatus;
  final String newStatus;
  final String? note;
  final DateTime? createdAt;

  const MapFeedbackReviewEvent({
    required this.id,
    required this.reportId,
    this.oldStatus,
    required this.newStatus,
    this.note,
    this.createdAt,
  });

  factory MapFeedbackReviewEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      final text = value?.toString();
      if (text == null || text.trim().isEmpty) return null;
      return DateTime.tryParse(text);
    }

    return MapFeedbackReviewEvent(
      id: (json['id'] ?? '').toString(),
      reportId: (json['report_id'] ?? '').toString(),
      oldStatus: json['old_status']?.toString(),
      newStatus: (json['new_status'] ?? '').toString(),
      note: json['note']?.toString(),
      createdAt: parseDate(json['created_at']),
    );
  }
}


class MapFeedbackAuditTaskRequest {
  final String id;
  final String reportId;
  final String taskStatus;
  final String? taskId;
  final String title;
  final String? description;
  final String priority;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MapFeedbackAuditTaskRequest({
    required this.id,
    required this.reportId,
    required this.taskStatus,
    this.taskId,
    required this.title,
    this.description,
    required this.priority,
    this.errorMessage,
    this.createdAt,
    this.updatedAt,
  });

  String get displayStatus => switch (taskStatus) {
        'pending' => 'بانتظار الربط مع نظام المهام',
        'created' => 'تم إنشاء مهمة',
        'failed' => 'فشل إنشاء المهمة',
        'skipped' => 'مؤجل',
        _ => taskStatus,
      };

  factory MapFeedbackAuditTaskRequest.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      final text = value?.toString();
      if (text == null || text.trim().isEmpty) return null;
      return DateTime.tryParse(text);
    }

    return MapFeedbackAuditTaskRequest(
      id: (json['id'] ?? '').toString(),
      reportId: (json['report_id'] ?? '').toString(),
      taskStatus: (json['task_status'] ?? 'pending').toString(),
      taskId: json['task_id']?.toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      priority: (json['priority'] ?? 'normal').toString(),
      errorMessage: json['error_message']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}




class ExplorerGapAuditSubmission {
  final String domain;
  final String severity;
  final String title;
  final String detail;
  final String recommendedAction;
  final List<String> sample;
  final String explorerMode;
  final String priority;
  final String? reporterNote;
  final Map<String, dynamic> context;

  const ExplorerGapAuditSubmission({
    required this.domain,
    required this.severity,
    required this.title,
    required this.detail,
    required this.recommendedAction,
    this.sample = const [],
    required this.explorerMode,
    this.priority = 'normal',
    this.reporterNote,
    this.context = const {},
  });

  Map<String, dynamic> toRpcParams() {
    return {
      'p_domain': domain,
      'p_severity': severity,
      'p_title': title,
      'p_detail': detail,
      'p_recommended_action': recommendedAction,
      'p_sample': sample,
      'p_explorer_mode': explorerMode,
      'p_context': context,
      'p_priority': priority,
      'p_reporter_note': reporterNote,
      'p_create_feedback_report': false,
      'p_lat': null,
      'p_lng': null,
    };
  }
}

class ExplorerGapAuditRequest {
  final String id;
  final String domain;
  final String severity;
  final String title;
  final String detail;
  final String? recommendedAction;
  final List<String> sample;
  final String explorerMode;
  final String priority;
  final String status;
  final String? reporterNote;
  final String? feedbackReportId;
  final Map<String, dynamic> context;
  final String? reviewerNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? reviewedAt;

  const ExplorerGapAuditRequest({
    required this.id,
    required this.domain,
    required this.severity,
    required this.title,
    required this.detail,
    this.recommendedAction,
    this.sample = const [],
    required this.explorerMode,
    required this.priority,
    required this.status,
    this.reporterNote,
    this.feedbackReportId,
    this.context = const {},
    this.reviewerNote,
    this.createdAt,
    this.updatedAt,
    this.reviewedAt,
  });

  String get displayStatus => switch (status) {
        'new' => 'جديد',
        'triaged' => 'قيد الفرز',
        'accepted' => 'مقبول',
        'rejected' => 'مرفوض',
        'resolved' => 'مغلق',
        _ => status,
      };

  factory ExplorerGapAuditRequest.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      final text = value?.toString();
      if (text == null || text.trim().isEmpty) return null;
      return DateTime.tryParse(text);
    }

    List<String> parseSample(dynamic value) {
      if (value is List) {
        return value
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList(growable: false);
      }
      return const [];
    }

    Map<String, dynamic> parseMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return value.cast<String, dynamic>();
      return const <String, dynamic>{};
    }

    return ExplorerGapAuditRequest(
      id: (json['id'] ?? '').toString(),
      domain: (json['domain'] ?? '').toString(),
      severity: (json['severity'] ?? 'medium').toString(),
      title: (json['title'] ?? '').toString(),
      detail: (json['detail'] ?? '').toString(),
      recommendedAction: json['recommended_action']?.toString(),
      sample: parseSample(json['sample']),
      explorerMode: (json['explorer_mode'] ?? 'historical').toString(),
      priority: (json['priority'] ?? 'normal').toString(),
      status: (json['status'] ?? 'new').toString(),
      reporterNote: json['reporter_note']?.toString(),
      feedbackReportId: json['feedback_report_id']?.toString(),
      context: parseMap(json['context']),
      reviewerNote: json['reviewer_note']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      reviewedAt: parseDate(json['reviewed_at']),
    );
  }
}

class ExplorerGapAuditEvidenceDraft {
  final String requestId;
  final String evidenceType;
  final String title;
  final String? referenceUrl;
  final String storageBucket;
  final String? storageObjectPath;
  final int? fileSizeBytes;
  final String? mimeType;
  final String? checksumSha256;
  final String? filePath;
  final String? note;
  final Map<String, dynamic> metadata;

  const ExplorerGapAuditEvidenceDraft({
    required this.requestId,
    required this.evidenceType,
    required this.title,
    this.referenceUrl,
    this.storageBucket = 'explorer-review-evidence',
    this.storageObjectPath,
    this.fileSizeBytes,
    this.mimeType,
    this.checksumSha256,
    this.filePath,
    this.note,
    this.metadata = const <String, dynamic>{},
  });

  Map<String, dynamic> toRpcParamsV2() {
    return {
      'p_request_id': requestId,
      'p_evidence_type': evidenceType,
      'p_title': title,
      'p_reference_url': referenceUrl,
      'p_storage_bucket': storageBucket,
      'p_storage_object_path': storageObjectPath ?? filePath,
      'p_file_size_bytes': fileSizeBytes,
      'p_mime_type': mimeType,
      'p_checksum_sha256': checksumSha256,
      'p_note': note,
      'p_metadata': metadata,
    };
  }

  Map<String, dynamic> toRpcParamsV1() {
    return {
      'p_request_id': requestId,
      'p_evidence_type': evidenceType,
      'p_title': title,
      'p_reference_url': referenceUrl,
      'p_file_path': storageObjectPath ?? filePath,
      'p_note': note,
      'p_metadata': metadata,
    };
  }
}

class ExplorerGapAuditEvidenceAttachment {
  final String id;
  final String requestId;
  final String evidenceType;
  final String title;
  final String? referenceUrl;
  final String? filePath;
  final String storageBucket;
  final String? storageObjectPath;
  final int? fileSizeBytes;
  final String? mimeType;
  final String? checksumSha256;
  final String retentionPolicy;
  final String reviewState;
  final String? note;
  final Map<String, dynamic> metadata;
  final String? createdByUserId;
  final String? createdByLabel;
  final DateTime? createdAt;
  final String? reviewedByUserId;
  final String? reviewedByLabel;
  final DateTime? reviewedAt;
  final String? reviewNote;

  const ExplorerGapAuditEvidenceAttachment({
    required this.id,
    required this.requestId,
    required this.evidenceType,
    required this.title,
    this.referenceUrl,
    this.filePath,
    this.storageBucket = 'explorer-review-evidence',
    this.storageObjectPath,
    this.fileSizeBytes,
    this.mimeType,
    this.checksumSha256,
    this.retentionPolicy = 'review_evidence_operational_7y',
    this.reviewState = 'submitted',
    this.note,
    this.metadata = const <String, dynamic>{},
    this.createdByUserId,
    this.createdByLabel,
    this.createdAt,
    this.reviewedByUserId,
    this.reviewedByLabel,
    this.reviewedAt,
    this.reviewNote,
  });

  String get displayReviewState => switch (reviewState) {
        'submitted' => 'مقدم',
        'under_review' => 'قيد المراجعة',
        'accepted' => 'مقبول',
        'rejected' => 'مرفوض',
        'superseded' => 'مستبدل',
        _ => reviewState,
      };

  String get displayStoragePath {
    final path = storageObjectPath ?? filePath;
    if (path == null || path.trim().isEmpty) return 'لا يوجد ملف مخزن';
    return '$storageBucket/$path';
  }

  factory ExplorerGapAuditEvidenceAttachment.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      final text = value?.toString();
      if (text == null || text.trim().isEmpty) return null;
      return DateTime.tryParse(text);
    }

    Map<String, dynamic> parseMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return value.cast<String, dynamic>();
      return const <String, dynamic>{};
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return ExplorerGapAuditEvidenceAttachment(
      id: (json['id'] ?? '').toString(),
      requestId: (json['request_id'] ?? '').toString(),
      evidenceType: (json['evidence_type'] ?? 'note').toString(),
      title: (json['title'] ?? '').toString(),
      referenceUrl: json['reference_url']?.toString(),
      filePath: json['file_path']?.toString(),
      storageBucket: (json['storage_bucket'] ?? 'explorer-review-evidence').toString(),
      storageObjectPath: json['storage_object_path']?.toString(),
      fileSizeBytes: parseInt(json['file_size_bytes']),
      mimeType: json['mime_type']?.toString(),
      checksumSha256: json['checksum_sha256']?.toString(),
      retentionPolicy: (json['retention_policy'] ?? 'review_evidence_operational_7y').toString(),
      reviewState: (json['review_state'] ?? 'submitted').toString(),
      note: json['note']?.toString(),
      metadata: parseMap(json['metadata']),
      createdByUserId: json['created_by_user_id']?.toString(),
      createdByLabel: json['created_by_label']?.toString(),
      createdAt: parseDate(json['created_at']),
      reviewedByUserId: json['reviewed_by_user_id']?.toString(),
      reviewedByLabel: json['reviewed_by_label']?.toString(),
      reviewedAt: parseDate(json['reviewed_at']),
      reviewNote: json['review_note']?.toString(),
    );
  }
}

class ExplorerGapAuditStoragePolicy {
  final String bucketId;
  final bool isPublic;
  final int maxFileSizeBytes;
  final List<String> allowedMimeTypes;
  final String pathPrefix;
  final String pathTemplate;
  final String retentionPolicy;
  final Map<String, dynamic> requiredMetadata;
  final Map<String, dynamic> notes;

  const ExplorerGapAuditStoragePolicy({
    required this.bucketId,
    required this.isPublic,
    required this.maxFileSizeBytes,
    required this.allowedMimeTypes,
    required this.pathPrefix,
    required this.pathTemplate,
    required this.retentionPolicy,
    this.requiredMetadata = const <String, dynamic>{},
    this.notes = const <String, dynamic>{},
  });

  String get maxFileSizeLabel {
    final mb = maxFileSizeBytes / (1024 * 1024);
    final isWhole = mb == mb.truncateToDouble();
    return '${mb.toStringAsFixed(isWhole ? 0 : 1)} MB';
  }

  factory ExplorerGapAuditStoragePolicy.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parseMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return value.cast<String, dynamic>();
      return const <String, dynamic>{};
    }

    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList(growable: false);
      }
      return const <String>[];
    }

    int parseInt(dynamic value, int fallback) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return ExplorerGapAuditStoragePolicy(
      bucketId: (json['bucket_id'] ?? 'explorer-review-evidence').toString(),
      isPublic: json['is_public'] == true,
      maxFileSizeBytes: parseInt(json['max_file_size_bytes'], 10485760),
      allowedMimeTypes: parseStringList(json['allowed_mime_types']),
      pathPrefix: (json['path_prefix'] ?? 'gap-audits/').toString(),
      pathTemplate: (json['path_template'] ?? 'gap-audits/{request_id}/{yyyy}/{mm}/{safe_file_name_or_uuid}').toString(),
      retentionPolicy: (json['retention_policy'] ?? 'review_evidence_operational_7y').toString(),
      requiredMetadata: parseMap(json['required_metadata']),
      notes: parseMap(json['notes']),
    );
  }
}

class ExplorerGapAuditTimelineEvent {
  final String eventId;
  final String requestId;
  final String eventType;
  final String eventTitle;
  final String? eventDetail;
  final String? actorUserId;
  final String? actorLabel;
  final String? eventStatus;
  final Map<String, dynamic> eventPayload;
  final DateTime? occurredAt;
  final int sortRank;

  const ExplorerGapAuditTimelineEvent({
    required this.eventId,
    required this.requestId,
    required this.eventType,
    required this.eventTitle,
    this.eventDetail,
    this.actorUserId,
    this.actorLabel,
    this.eventStatus,
    this.eventPayload = const <String, dynamic>{},
    this.occurredAt,
    this.sortRank = 0,
  });

  String get displayType => switch (eventType) {
        'request_created' => 'إنشاء الطلب',
        'request_reviewed' => 'مراجعة الطلب',
        'evidence_attached' => 'إرفاق دليل',
        'evidence_reviewed' => 'مراجعة دليل',
        'task_created' => 'إنشاء مهمة',
        'task_status_change' => 'تحديث مهمة',
        'task_assignment_routing' => 'توجيه مهمة',
        _ => eventType.startsWith('task_') ? 'حدث مهمة' : eventType,
      };

  factory ExplorerGapAuditTimelineEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      final text = value?.toString();
      if (text == null || text.trim().isEmpty) return null;
      return DateTime.tryParse(text);
    }

    Map<String, dynamic> parseMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return value.cast<String, dynamic>();
      return const <String, dynamic>{};
    }

    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return ExplorerGapAuditTimelineEvent(
      eventId: (json['event_id'] ?? '').toString(),
      requestId: (json['request_id'] ?? '').toString(),
      eventType: (json['event_type'] ?? '').toString(),
      eventTitle: (json['event_title'] ?? '').toString(),
      eventDetail: json['event_detail']?.toString(),
      actorUserId: json['actor_user_id']?.toString(),
      actorLabel: json['actor_label']?.toString(),
      eventStatus: json['event_status']?.toString(),
      eventPayload: parseMap(json['event_payload']),
      occurredAt: parseDate(json['occurred_at']),
      sortRank: parseInt(json['sort_rank']),
    );
  }
}

class MapFeedbackRepository {
  final SupabaseClient _client;

  const MapFeedbackRepository(this._client);

  Future<MapFeedbackReport> createReport(
    MapFeedbackSubmission submission,
  ) async {
    final rows = await _client.schema('gis').rpc(
          'rpc_map_feedback_create',
          params: submission.toRpcParams(),
        );
    return _firstReport(rows);
  }

  Future<List<MapFeedbackReport>> listReports({
    String status = 'new',
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await _client.schema('gis').rpc(
      'rpc_map_feedback_list',
      params: {
        'p_status': status,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return _reportList(rows);
  }

  Future<List<MapFeedbackStatusCount>> fetchStatusCounts() async {
    final rows = await _client.schema('gis').rpc('rpc_map_feedback_status_counts');
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map((e) => MapFeedbackStatusCount.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    }
    if (rows is Map) {
      return [MapFeedbackStatusCount.fromJson(rows.cast<String, dynamic>())];
    }
    return const [];
  }

  Future<List<MapFeedbackReviewEvent>> listReviewEvents({
    required String reportId,
    int limit = 20,
  }) async {
    final rows = await _client.schema('gis').rpc(
      'rpc_map_feedback_events',
      params: {
        'p_report_id': reportId,
        'p_limit': limit,
      },
    );
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map((e) => MapFeedbackReviewEvent.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    }
    if (rows is Map) {
      return [MapFeedbackReviewEvent.fromJson(rows.cast<String, dynamic>())];
    }
    return const [];
  }

  Future<MapFeedbackReport> reviewReport({
    required String reportId,
    required String newStatus,
    String? reviewerNote,
  }) async {
    final rows = await _client.schema('gis').rpc(
      'rpc_map_feedback_review',
      params: {
        'p_report_id': reportId,
        'p_new_status': newStatus,
        'p_reviewer_note': reviewerNote,
      },
    );
    return _firstReport(rows);
  }

  Future<MapFeedbackAuditTaskRequest> createAuditTaskRequest({
    required String reportId,
    String? title,
    String? description,
    String priority = 'normal',
    bool tryCreateExternalTask = false,
  }) async {
    final rows = await _client.schema('gis').rpc(
      'rpc_map_feedback_create_audit_task',
      params: {
        'p_report_id': reportId,
        'p_title': title,
        'p_description': description,
        'p_priority': priority,
        'p_try_create_external_task': tryCreateExternalTask,
      },
    );
    return _firstAuditTaskRequest(rows);
  }

  Future<List<MapFeedbackAuditTaskRequest>> listAuditTaskRequests({
    String? taskStatus,
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await _client.schema('gis').rpc(
      'rpc_map_feedback_audit_task_list',
      params: {
        'p_task_status': taskStatus,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return _auditTaskRequestList(rows);
  }


  Future<ExplorerGapAuditRequest> createExplorerGapAuditRequest(
    ExplorerGapAuditSubmission submission,
  ) async {
    final rows = await _client.schema('gis').rpc(
      'rpc_explorer_gap_audit_create_v1',
      params: submission.toRpcParams(),
    );
    return _firstExplorerGapAuditRequest(rows);
  }

  Future<List<ExplorerGapAuditRequest>> listExplorerGapAuditRequests({
    String? status,
    String? domain,
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await _client.schema('gis').rpc(
      'rpc_explorer_gap_audit_list_v1',
      params: {
        'p_status': status,
        'p_domain': domain,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return _explorerGapAuditRequestList(rows);
  }

  Future<ExplorerGapAuditRequest> reviewExplorerGapAuditRequest({
    required String requestId,
    required String newStatus,
    String? reviewerNote,
  }) async {
    final rows = await _client.schema('gis').rpc(
      'rpc_explorer_gap_audit_review_v1',
      params: {
        'p_request_id': requestId,
        'p_new_status': newStatus,
        'p_reviewer_note': reviewerNote,
      },
    );
    return _firstExplorerGapAuditRequest(rows);
  }

  Future<ExplorerGapAuditEvidenceAttachment> createExplorerGapAuditEvidence(
    ExplorerGapAuditEvidenceDraft draft,
  ) async {
    try {
      final rows = await _client.schema('gis').rpc(
        'rpc_explorer_gap_audit_evidence_attach_v2',
        params: draft.toRpcParamsV2(),
      );
      return _firstExplorerGapAuditEvidenceAttachment(rows);
    } catch (e) {
      if (!_isMissingRpcError(e)) rethrow;
      final rows = await _client.schema('gis').rpc(
        'rpc_explorer_gap_audit_evidence_attach_v1',
        params: draft.toRpcParamsV1(),
      );
      return _firstExplorerGapAuditEvidenceAttachment(rows);
    }
  }

  Future<List<ExplorerGapAuditEvidenceAttachment>> listExplorerGapAuditEvidence({
    required String requestId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final rows = await _client.schema('gis').rpc(
        'rpc_explorer_gap_audit_evidence_list_v3',
        params: {
          'p_request_id': requestId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      return _explorerGapAuditEvidenceAttachmentList(rows);
    } catch (e) {
      if (!_isMissingRpcError(e)) rethrow;
      try {
        final rows = await _client.schema('gis').rpc(
          'rpc_explorer_gap_audit_evidence_list_v2',
          params: {
            'p_request_id': requestId,
            'p_limit': limit,
            'p_offset': offset,
          },
        );
        return _explorerGapAuditEvidenceAttachmentList(rows);
      } catch (fallbackError) {
        if (!_isMissingRpcError(fallbackError)) rethrow;
        final rows = await _client.schema('gis').rpc(
          'rpc_explorer_gap_audit_evidence_list_v1',
          params: {
            'p_request_id': requestId,
            'p_limit': limit,
            'p_offset': offset,
          },
        );
        return _explorerGapAuditEvidenceAttachmentList(rows);
      }
    }
  }

  Future<ExplorerGapAuditEvidenceAttachment> reviewExplorerGapAuditEvidence({
    required String evidenceId,
    required String reviewState,
    String? reviewNote,
  }) async {
    final rows = await _client.schema('gis').rpc(
      'rpc_explorer_gap_audit_evidence_review_v1',
      params: {
        'p_evidence_id': evidenceId,
        'p_review_state': reviewState,
        'p_review_note': reviewNote,
      },
    );
    return _firstExplorerGapAuditEvidenceAttachment(rows);
  }

  Future<List<ExplorerGapAuditTimelineEvent>> listExplorerGapAuditTimeline({
    required String requestId,
    int limit = 200,
  }) async {
    dynamic rows;
    try {
      rows = await _client.schema('gis').rpc(
        'rpc_explorer_gap_audit_timeline_v2',
        params: {
          'p_request_id': requestId,
          'p_limit': limit,
        },
      );
    } catch (e) {
      if (!_isMissingRpcError(e)) rethrow;
      rows = await _client.schema('gis').rpc(
        'rpc_explorer_gap_audit_timeline_v1',
        params: {
          'p_request_id': requestId,
          'p_limit': limit,
        },
      );
    }
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map((e) => ExplorerGapAuditTimelineEvent.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    }
    if (rows is Map) {
      return [ExplorerGapAuditTimelineEvent.fromJson(rows.cast<String, dynamic>())];
    }
    return const [];
  }

  Future<ExplorerGapAuditStoragePolicy> fetchExplorerGapAuditStoragePolicy({
    String? requestId,
  }) async {
    final rows = await _client.schema('gis').rpc(
      'rpc_explorer_gap_audit_storage_policy_v1',
      params: {'p_request_id': requestId},
    );
    if (rows is List && rows.isNotEmpty && rows.first is Map) {
      return ExplorerGapAuditStoragePolicy.fromJson(
        (rows.first as Map).cast<String, dynamic>(),
      );
    }
    if (rows is Map) {
      return ExplorerGapAuditStoragePolicy.fromJson(rows.cast<String, dynamic>());
    }
    return const ExplorerGapAuditStoragePolicy(
      bucketId: 'explorer-review-evidence',
      isPublic: false,
      maxFileSizeBytes: 10485760,
      allowedMimeTypes: <String>[
        'application/pdf',
        'image/jpeg',
        'image/png',
        'image/webp',
        'text/plain',
        'text/csv',
      ],
      pathPrefix: 'gap-audits/',
      pathTemplate: 'gap-audits/{request_id}/{yyyy}/{mm}/{safe_file_name_or_uuid}',
      retentionPolicy: 'review_evidence_operational_7y',
    );
  }

  bool _isMissingRpcError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('could not find the function') ||
        (text.contains('function') && text.contains('does not exist')) ||
        (text.contains('404') && text.contains('rpc'));
  }

  MapFeedbackReport _firstReport(dynamic rows) {
    final list = _reportList(rows);
    if (list.isEmpty) {
      throw StateError('لم يرجع RPC أي سجل بلاغ.');
    }
    return list.first;
  }

  List<MapFeedbackReport> _reportList(dynamic rows) {
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map((e) => MapFeedbackReport.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    }
    if (rows is Map) {
      return [MapFeedbackReport.fromJson(rows.cast<String, dynamic>())];
    }
    return const [];
  }

  MapFeedbackAuditTaskRequest _firstAuditTaskRequest(dynamic rows) {
    final list = _auditTaskRequestList(rows);
    if (list.isEmpty) {
      throw StateError('لم يرجع RPC أي سجل طلب مهمة تدقيق.');
    }
    return list.first;
  }

  List<MapFeedbackAuditTaskRequest> _auditTaskRequestList(dynamic rows) {
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map(
            (e) => MapFeedbackAuditTaskRequest.fromJson(
              e.cast<String, dynamic>(),
            ),
          )
          .toList(growable: false);
    }
    if (rows is Map) {
      return [
        MapFeedbackAuditTaskRequest.fromJson(rows.cast<String, dynamic>()),
      ];
    }
    return const [];
  }


  ExplorerGapAuditEvidenceAttachment _firstExplorerGapAuditEvidenceAttachment(
    dynamic rows,
  ) {
    final list = _explorerGapAuditEvidenceAttachmentList(rows);
    if (list.isEmpty) {
      throw StateError('لم يرجع RPC أي مرفق دليل.');
    }
    return list.first;
  }

  List<ExplorerGapAuditEvidenceAttachment>
      _explorerGapAuditEvidenceAttachmentList(dynamic rows) {
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map((e) => ExplorerGapAuditEvidenceAttachment.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    }
    if (rows is Map) {
      return [ExplorerGapAuditEvidenceAttachment.fromJson(rows.cast<String, dynamic>())];
    }
    return const [];
  }

  ExplorerGapAuditRequest _firstExplorerGapAuditRequest(dynamic rows) {
    final list = _explorerGapAuditRequestList(rows);
    if (list.isEmpty) {
      throw StateError('لم يرجع RPC أي سجل طلب تدقيق فجوة.');
    }
    return list.first;
  }

  List<ExplorerGapAuditRequest> _explorerGapAuditRequestList(dynamic rows) {
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map(
            (e) => ExplorerGapAuditRequest.fromJson(
              e.cast<String, dynamic>(),
            ),
          )
          .toList(growable: false);
    }
    if (rows is Map) {
      return [ExplorerGapAuditRequest.fromJson(rows.cast<String, dynamic>())];
    }
    return const [];
  }
}
