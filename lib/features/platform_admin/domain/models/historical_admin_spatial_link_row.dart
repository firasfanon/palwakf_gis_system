class HistoricalAdminSpatialLinkRow {
  final int id;
  final int historicalAdminUnitId;
  final String histLevel;
  final int histPeriodNo;
  final int histAdminNo;
  final String matchMethod;
  final double confidence;
  final bool isPrimary;
  final String? notes;

  const HistoricalAdminSpatialLinkRow({
    required this.id,
    required this.historicalAdminUnitId,
    required this.histLevel,
    required this.histPeriodNo,
    required this.histAdminNo,
    required this.matchMethod,
    required this.confidence,
    required this.isPrimary,
    this.notes,
  });

  factory HistoricalAdminSpatialLinkRow.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return HistoricalAdminSpatialLinkRow(
      id: parseInt(json['id']),
      historicalAdminUnitId: parseInt(json['historical_admin_unit_id']),
      histLevel: (json['hist_level'] ?? '').toString(),
      histPeriodNo: parseInt(json['hist_period_no']),
      histAdminNo: parseInt(json['hist_admin_no']),
      matchMethod: (json['match_method'] ?? '').toString(),
      confidence: parseDouble(json['confidence']),
      isPrimary: json['is_primary'] == true,
      notes: json['notes']?.toString(),
    );
  }
}
