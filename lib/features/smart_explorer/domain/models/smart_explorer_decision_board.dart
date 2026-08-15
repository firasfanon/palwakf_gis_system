/// Operational decision board for Smart Explorer.
///
/// This is a local, non-sovereign decision-support model. It does not approve
/// or mutate waqf/core records; it only guides review priorities.
class SmartExplorerDecisionBoard {
  const SmartExplorerDecisionBoard({
    required this.items,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerDecisionItem> items;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => items.isEmpty;
  int get urgentCount => items.where((item) => item.isUrgent).length;
  int get highCount => items.where((item) => item.priority >= 70).length;

  List<SmartExplorerDecisionItem> get topItems {
    final out = List<SmartExplorerDecisionItem>.from(items)
      ..sort((a, b) => b.priority.compareTo(a.priority));
    return out.take(12).toList(growable: false);
  }

  String get summaryAr {
    if (items.isEmpty) return 'لا توجد قرارات تشغيلية مقترحة ضمن النطاق الحالي.';
    return 'لوحة قرارات تضم ${items.length} بندًا، منها $urgentCount عاجلة و$highCount عالية الأولوية.';
  }
}

class SmartExplorerDecisionItem {
  const SmartExplorerDecisionItem({
    required this.titleAr,
    required this.descriptionAr,
    required this.actionAr,
    required this.priority,
    required this.domainAr,
    this.resultId,
    this.resultTitleAr,
  });

  final String titleAr;
  final String descriptionAr;
  final String actionAr;
  final int priority;
  final String domainAr;
  final String? resultId;
  final String? resultTitleAr;

  bool get isUrgent => priority >= 85;

  String get priorityLabelAr {
    if (priority >= 85) return 'عاجل';
    if (priority >= 70) return 'عالٍ';
    if (priority >= 45) return 'متوسط';
    return 'منخفض';
  }
}
