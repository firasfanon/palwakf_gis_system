class HistoricalAdminRelationCrudRow {
  final int id;
  final int sourceHistoricalAdminUnitId;
  final int targetHistoricalAdminUnitId;
  final String relationType;
  final double confidence;
  final bool isActive;
  final String? notes;

  const HistoricalAdminRelationCrudRow({
    required this.id,
    required this.sourceHistoricalAdminUnitId,
    required this.targetHistoricalAdminUnitId,
    required this.relationType,
    required this.confidence,
    required this.isActive,
    this.notes,
  });

  factory HistoricalAdminRelationCrudRow.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return HistoricalAdminRelationCrudRow(
      id: parseInt(json['id']),
      sourceHistoricalAdminUnitId:
          parseInt(json['source_historical_admin_unit_id']),
      targetHistoricalAdminUnitId:
          parseInt(json['target_historical_admin_unit_id']),
      relationType: (json['relation_type'] ?? '').toString(),
      confidence: parseDouble(json['confidence']),
      isActive: json['is_active'] == true,
      notes: json['notes']?.toString(),
    );
  }
}
