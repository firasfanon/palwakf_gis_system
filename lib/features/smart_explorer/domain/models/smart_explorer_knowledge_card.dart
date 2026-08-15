/// Knowledge cards summarize extracted names, evidence links, and review context.
///
/// Cards are designed for analyst review and handoff, not for direct sovereign
/// data insertion.
class SmartExplorerKnowledgeCardSet {
  const SmartExplorerKnowledgeCardSet({
    required this.cards,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerKnowledgeCard> cards;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => cards.isEmpty;
  int get totalCards => cards.length;
  int get strongCards => cards.where((item) => item.confidence >= 70).length;

  List<SmartExplorerKnowledgeCard> get topCards {
    final out = List<SmartExplorerKnowledgeCard>.from(cards)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return out.take(18).toList(growable: false);
  }

  String get summaryAr {
    if (cards.isEmpty) return 'لا توجد بطاقات معرفة ضمن النطاق الحالي.';
    return 'بطاقات معرفة: $totalCards، قوية: $strongCards.';
  }
}

class SmartExplorerKnowledgeCard {
  const SmartExplorerKnowledgeCard({
    required this.titleAr,
    required this.typeAr,
    required this.summaryAr,
    required this.confidence,
    required this.sources,
    required this.reviewQuestionAr,
    this.relatedResultId,
    this.relatedResultTitleAr,
  });

  final String titleAr;
  final String typeAr;
  final String summaryAr;
  final int confidence;
  final List<String> sources;
  final String reviewQuestionAr;
  final String? relatedResultId;
  final String? relatedResultTitleAr;

  String get confidenceLabelAr {
    if (confidence >= 80) return 'قوية';
    if (confidence >= 60) return 'متوسطة';
    if (confidence >= 35) return 'أولية';
    return 'ضعيفة';
  }
}
