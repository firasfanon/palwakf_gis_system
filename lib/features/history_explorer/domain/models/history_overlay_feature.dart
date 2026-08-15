class HistoryOverlayFeature {
  final int periodNo;
  final String periodLabelAr;
  final String periodLabelEn;
  final String? familyKey;
  final String? chainKey;
  final String? levelKey;
  final String? sourceTable;
  final String sourceId;
  final String? parentSourceId;
  final String? entityCode;
  final String labelAr;
  final String labelEn;
  final Map<String, dynamic>? geomJson;
  final Map<String, dynamic>? centroidJson;
  final int displayOrder;
  final Map<String, dynamic> attributes;
  final Map<String, dynamic> styleJson;

  const HistoryOverlayFeature({
    required this.periodNo,
    required this.periodLabelAr,
    required this.periodLabelEn,
    required this.familyKey,
    required this.chainKey,
    required this.levelKey,
    required this.sourceTable,
    required this.sourceId,
    required this.parentSourceId,
    required this.entityCode,
    required this.labelAr,
    required this.labelEn,
    required this.geomJson,
    required this.centroidJson,
    required this.displayOrder,
    required this.attributes,
    required this.styleJson,
  });

  String get displayLabel {
    if (labelAr.trim().isNotEmpty) return labelAr.trim();
    if (labelEn.trim().isNotEmpty) return labelEn.trim();
    if ((entityCode ?? '').trim().isNotEmpty) return entityCode!.trim();
    return sourceId;
  }
}
