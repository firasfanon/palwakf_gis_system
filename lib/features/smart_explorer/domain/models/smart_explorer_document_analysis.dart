/// Rule-based, non-sovereign document analysis result for Smart Explorer.
///
/// This model supports manual/pasted text analysis in the current batch and
/// can later be fed by OCR or LLM pipelines after review governance is fixed.
class SmartExplorerDocumentAnalysis {
  const SmartExplorerDocumentAnalysis({
    required this.originalText,
    required this.normalizedText,
    required this.entities,
    required this.boundaryClues,
    required this.directionClues,
    required this.timeClues,
    required this.spatialHypotheses,
    required this.confidence,
    required this.createdAt,
  });

  final String originalText;
  final String normalizedText;
  final List<SmartExplorerDocumentEntity> entities;
  final List<String> boundaryClues;
  final List<String> directionClues;
  final List<String> timeClues;
  final List<String> spatialHypotheses;
  final double confidence;
  final DateTime createdAt;

  bool get hasEvidence => evidenceCount > 0;
  int get evidenceCount =>
      entities.length + boundaryClues.length + directionClues.length + timeClues.length;
  int get confidencePercent => (confidence.clamp(0, 1) * 100).round();

  List<SmartExplorerDocumentEntity> get placeEntities => entities
      .where((item) => item.type == SmartExplorerDocumentEntityType.place)
      .toList(growable: false);

  List<SmartExplorerDocumentEntity> get waqfEntities => entities
      .where((item) => item.type == SmartExplorerDocumentEntityType.waqf)
      .toList(growable: false);

  List<SmartExplorerDocumentEntity> get parcelEntities => entities
      .where((item) => item.type == SmartExplorerDocumentEntityType.parcel)
      .toList(growable: false);

  String get summaryAr {
    if (!hasEvidence) {
      return 'لم يتم استخراج قرائن كافية من النص الحالي. أضف وصف حدود أو أسماء مواقع أو وقف أو أرقام حوض/قطعة.';
    }
    return 'تم استخراج $evidenceCount قرينة: ${placeEntities.length} موقع/تجمع، ${waqfEntities.length} وقف، ${parcelEntities.length} حوض/قطعة، وثقة أولية $confidencePercent%.';
  }
}

class SmartExplorerDocumentEntity {
  const SmartExplorerDocumentEntity({
    required this.value,
    required this.type,
    required this.evidence,
    required this.score,
  });

  final String value;
  final SmartExplorerDocumentEntityType type;
  final String evidence;
  final double score;

  int get scorePercent => (score.clamp(0, 1) * 100).round();

  String get typeLabelAr {
    switch (type) {
      case SmartExplorerDocumentEntityType.place:
        return 'موقع/تجمع';
      case SmartExplorerDocumentEntityType.waqf:
        return 'وقف';
      case SmartExplorerDocumentEntityType.parcel:
        return 'حوض/قطعة';
      case SmartExplorerDocumentEntityType.landmark:
        return 'معلم';
      case SmartExplorerDocumentEntityType.personOrFamily:
        return 'شخص/عائلة';
      case SmartExplorerDocumentEntityType.unknown:
        return 'قرينة';
    }
  }
}

enum SmartExplorerDocumentEntityType {
  place,
  waqf,
  parcel,
  landmark,
  personOrFamily,
  unknown,
}
