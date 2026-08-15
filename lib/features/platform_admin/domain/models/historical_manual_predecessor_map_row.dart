class HistoricalManualPredecessorMapRow {
  final int id;
  final int reviewQueueId;
  final int targetUnitId;
  final String targetCode;
  final int targetPeriodId;
  final String? targetPeriodTitleAr;
  final int sourceUnitId;
  final String sourceCode;
  final int sourcePeriodId;
  final String? sourcePeriodTitleAr;
  final String suggestedRelationType;
  final double confidence;
  final String? notes;
  final bool isSelected;

  const HistoricalManualPredecessorMapRow({
    required this.id,
    required this.reviewQueueId,
    required this.targetUnitId,
    required this.targetCode,
    required this.targetPeriodId,
    this.targetPeriodTitleAr,
    required this.sourceUnitId,
    required this.sourceCode,
    required this.sourcePeriodId,
    this.sourcePeriodTitleAr,
    required this.suggestedRelationType,
    required this.confidence,
    this.notes,
    required this.isSelected,
  });

  factory HistoricalManualPredecessorMapRow.fromJson(
      Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return HistoricalManualPredecessorMapRow(
      id: parseInt(json['id']),
      reviewQueueId: parseInt(json['review_queue_id']),
      targetUnitId: parseInt(json['target_unit_id']),
      targetCode: (json['target_code'] ?? '').toString(),
      targetPeriodId: parseInt(json['target_period_id']),
      targetPeriodTitleAr: json['target_period_title_ar']?.toString(),
      sourceUnitId: parseInt(json['source_unit_id']),
      sourceCode: (json['source_code'] ?? '').toString(),
      sourcePeriodId: parseInt(json['source_period_id']),
      sourcePeriodTitleAr: json['source_period_title_ar']?.toString(),
      suggestedRelationType: (json['suggested_relation_type'] ?? '').toString(),
      confidence: parseDouble(json['confidence']),
      notes: json['notes']?.toString(),
      isSelected: json['is_selected'] == true,
    );
  }
}
