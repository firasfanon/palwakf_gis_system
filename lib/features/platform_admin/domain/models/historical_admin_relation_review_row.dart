class HistoricalAdminRelationReviewRow {
  final int id;
  final String relationType;
  final double confidence;
  final bool isActive;
  final String sourceId;
  final String sourceCode;
  final int sourcePeriodId;
  final String? sourcePeriodTitleAr;
  final String? sourceOriginCommunityCode;
  final String targetId;
  final String targetCode;
  final int targetPeriodId;
  final String? targetPeriodTitleAr;
  final String? targetOriginCommunityCode;
  final int periodDelta;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HistoricalAdminRelationReviewRow({
    required this.id,
    required this.relationType,
    required this.confidence,
    required this.isActive,
    required this.sourceId,
    required this.sourceCode,
    required this.sourcePeriodId,
    this.sourcePeriodTitleAr,
    this.sourceOriginCommunityCode,
    required this.targetId,
    required this.targetCode,
    required this.targetPeriodId,
    this.targetPeriodTitleAr,
    this.targetOriginCommunityCode,
    required this.periodDelta,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory HistoricalAdminRelationReviewRow.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, {double fallback = 0}) {
      if (value is num) return value.toDouble();
      return double.tryParse('${value ?? ''}') ?? fallback;
    }

    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is num) return value.toInt();
      return int.tryParse('${value ?? ''}') ?? fallback;
    }

    return HistoricalAdminRelationReviewRow(
      id: parseInt(json['relation_id']),
      relationType: (json['relation_type'] ?? '').toString(),
      confidence: parseDouble(json['confidence']),
      isActive: (json['is_active'] as bool?) ?? true,
      sourceId: (json['source_id'] ?? '').toString(),
      sourceCode: (json['source_code'] ?? '').toString(),
      sourcePeriodId: parseInt(json['source_period_id']),
      sourcePeriodTitleAr: json['source_period_title_ar']?.toString(),
      sourceOriginCommunityCode:
          json['source_origin_community_code']?.toString(),
      targetId: (json['target_id'] ?? '').toString(),
      targetCode: (json['target_code'] ?? '').toString(),
      targetPeriodId: parseInt(json['target_period_id']),
      targetPeriodTitleAr: json['target_period_title_ar']?.toString(),
      targetOriginCommunityCode:
          json['target_origin_community_code']?.toString(),
      periodDelta: parseInt(json['period_delta']),
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
