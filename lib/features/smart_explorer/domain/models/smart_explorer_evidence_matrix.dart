/// Local document-to-result evidence matrix.
///
/// It ranks possible links between extracted textual clues and current explorer
/// search results. It is a decision-support view only.
class SmartExplorerEvidenceMatrix {
  const SmartExplorerEvidenceMatrix({
    required this.links,
    required this.generatedAt,
  });

  final List<SmartExplorerEvidenceLink> links;
  final DateTime generatedAt;

  bool get hasLinks => links.isNotEmpty;
  int get strongLinks => links.where((item) => item.matchScore >= 70).length;
  int get weakLinks => links.where((item) => item.matchScore < 40).length;

  List<SmartExplorerEvidenceLink> get topLinks {
    final out = List<SmartExplorerEvidenceLink>.from(links)
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return out.take(15).toList(growable: false);
  }

  String get summaryAr {
    if (links.isEmpty) {
      return 'لا توجد روابط كافية بين قرائن الوثيقة ونتائج المستكشف الحالية.';
    }
    return 'تم بناء ${links.length} رابط دليل، منها $strongLinks روابط قوية و$weakLinks روابط ضعيفة.';
  }
}

class SmartExplorerEvidenceLink {
  const SmartExplorerEvidenceLink({
    required this.entityValue,
    required this.entityTypeLabelAr,
    required this.resultId,
    required this.resultTitleAr,
    required this.assetCode,
    required this.matchScore,
    required this.matchedFields,
    required this.conflicts,
    required this.recommendationAr,
  });

  final String entityValue;
  final String entityTypeLabelAr;
  final String resultId;
  final String resultTitleAr;
  final String assetCode;
  final int matchScore;
  final List<String> matchedFields;
  final List<String> conflicts;
  final String recommendationAr;

  bool get isStrong => matchScore >= 70;
  bool get hasConflict => conflicts.isNotEmpty;

  String get scoreLabelAr {
    if (matchScore >= 80) return 'قوي جدًا';
    if (matchScore >= 65) return 'قوي';
    if (matchScore >= 45) return 'متوسط';
    if (matchScore > 0) return 'ضعيف';
    return 'غير مطابق';
  }
}
