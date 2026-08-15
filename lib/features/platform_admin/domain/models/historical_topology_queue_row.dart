class HistoricalTopologyQueueRow {
  final int id;
  final String historicalAdminUnitId;
  final String code;
  final int periodId;
  final String? periodTitleAr;
  final String? originCommunityCode;
  final String finalGapReason;
  final String? suggestedEventFamily;
  final String? reviewNote;
  final String? relationDirection;
  final String? decisionStatus;
  final String? approvedRelationType;
  final double? confidence;
  final String? adminNotes;
  final String? candidateTargetUnitId;
  final String? candidateTargetCode;
  final int? candidateTargetPeriodId;
  final String? candidateTargetPeriodTitleAr;
  final DateTime? appliedAt;
  final int? appliedRelationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HistoricalTopologyQueueRow({
    required this.id,
    required this.historicalAdminUnitId,
    required this.code,
    required this.periodId,
    this.periodTitleAr,
    this.originCommunityCode,
    required this.finalGapReason,
    this.suggestedEventFamily,
    this.reviewNote,
    this.relationDirection,
    this.decisionStatus,
    this.approvedRelationType,
    this.confidence,
    this.adminNotes,
    this.candidateTargetUnitId,
    this.candidateTargetCode,
    this.candidateTargetPeriodId,
    this.candidateTargetPeriodTitleAr,
    this.appliedAt,
    this.appliedRelationId,
    this.createdAt,
    this.updatedAt,
  });

  bool get isApplied => appliedAt != null || appliedRelationId != null;
  bool get isApproved => decisionStatus == 'approved';
  bool get isRejected => decisionStatus == 'rejected';
  bool get isIgnored => decisionStatus == 'ignored';
  bool get isPending => decisionStatus == null || decisionStatus == 'pending';
  bool get isApprovedPendingApply => isApproved && !isApplied;

  bool get queueIsSource => relationDirection == 'queue_is_source';
  bool get queueIsTarget => relationDirection == 'queue_is_target';

  String get sourceCodeForDisplay {
    if (queueIsTarget) return candidateTargetCode ?? '—';
    return code;
  }

  String get targetCodeForDisplay {
    if (queueIsTarget) return code;
    return candidateTargetCode ?? '—';
  }

  int? get sourcePeriodForDisplay {
    if (queueIsTarget) return candidateTargetPeriodId;
    return periodId;
  }

  int? get targetPeriodForDisplay {
    if (queueIsTarget) return periodId;
    return candidateTargetPeriodId;
  }

  String? get sourcePeriodTitleForDisplay {
    if (queueIsTarget) return candidateTargetPeriodTitleAr;
    return periodTitleAr;
  }

  String? get targetPeriodTitleForDisplay {
    if (queueIsTarget) return periodTitleAr;
    return candidateTargetPeriodTitleAr;
  }

  factory HistoricalTopologyQueueRow.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('${value ?? ''}') ?? 0;
    }

    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse('${value ?? ''}');
    }

    double? parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse('${value ?? ''}');
    }

    return HistoricalTopologyQueueRow(
      id: parseInt(json['id']),
      historicalAdminUnitId:
          (json['historical_admin_unit_id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      periodId: parseInt(json['period_id']),
      periodTitleAr: json['period_title_ar']?.toString(),
      originCommunityCode: json['origin_community_code']?.toString(),
      finalGapReason: (json['final_gap_reason'] ?? '').toString(),
      suggestedEventFamily: json['suggested_event_family']?.toString(),
      reviewNote: json['review_note']?.toString(),
      relationDirection: json['relation_direction']?.toString(),
      decisionStatus: json['decision_status']?.toString(),
      approvedRelationType: json['approved_relation_type']?.toString(),
      confidence: parseNullableDouble(json['confidence']),
      adminNotes: json['admin_notes']?.toString(),
      candidateTargetUnitId: json['candidate_target_unit_id']?.toString(),
      candidateTargetCode: json['candidate_target_code']?.toString(),
      candidateTargetPeriodId:
          parseNullableInt(json['candidate_target_period_id']),
      candidateTargetPeriodTitleAr:
          json['candidate_target_period_title_ar']?.toString(),
      appliedAt: json['applied_at'] != null
          ? DateTime.tryParse(json['applied_at'].toString())
          : null,
      appliedRelationId: parseNullableInt(json['applied_relation_id']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
