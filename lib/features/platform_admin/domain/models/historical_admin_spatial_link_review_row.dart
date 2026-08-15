class HistoricalAdminSpatialLinkReviewRow {
  final int id;
  final String historicalAdminUnitId;
  final String historicalAdminCode;
  final int hauPeriodId;
  final String? originCommunityCode;
  final String histLevel;
  final int histPeriodNo;
  final int histAdminNo;
  final String? histAdminName;
  final String? authorityName;
  final int timelineMatchRows;
  final String matchMethod;
  final double confidence;
  final bool isPrimary;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HistoricalAdminSpatialLinkReviewRow({
    required this.id,
    required this.historicalAdminUnitId,
    required this.historicalAdminCode,
    required this.hauPeriodId,
    this.originCommunityCode,
    required this.histLevel,
    required this.histPeriodNo,
    required this.histAdminNo,
    this.histAdminName,
    this.authorityName,
    required this.timelineMatchRows,
    required this.matchMethod,
    required this.confidence,
    required this.isPrimary,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory HistoricalAdminSpatialLinkReviewRow.fromJson(
      Map<String, dynamic> json) {
    double parseDouble(dynamic value, {double fallback = 0}) {
      if (value is num) return value.toDouble();
      return double.tryParse('${value ?? ''}') ?? fallback;
    }

    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is num) return value.toInt();
      return int.tryParse('${value ?? ''}') ?? fallback;
    }

    return HistoricalAdminSpatialLinkReviewRow(
      id: parseInt(json['spatial_link_id']),
      historicalAdminUnitId:
          (json['historical_admin_unit_id'] ?? '').toString(),
      historicalAdminCode: (json['historical_admin_code'] ?? '').toString(),
      hauPeriodId: parseInt(json['hau_period_id']),
      originCommunityCode: json['origin_community_code']?.toString(),
      histLevel: (json['hist_level'] ?? '').toString(),
      histPeriodNo: parseInt(json['hist_period_no']),
      histAdminNo: parseInt(json['hist_admin_no']),
      histAdminName: json['hist_admin_name']?.toString(),
      authorityName: json['authority_name']?.toString(),
      timelineMatchRows: parseInt(json['timeline_match_rows']),
      matchMethod: (json['match_method'] ?? '').toString(),
      confidence: parseDouble(json['confidence']),
      isPrimary: (json['is_primary'] as bool?) ?? false,
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
