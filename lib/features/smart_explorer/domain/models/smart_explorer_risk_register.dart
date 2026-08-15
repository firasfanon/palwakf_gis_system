/// Local operational risk register for Smart Explorer review scope.
///
/// It is a decision-support artifact only. It does not represent legal,
/// financial, or sovereign approval.
class SmartExplorerRiskRegister {
  const SmartExplorerRiskRegister({
    required this.risks,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerRiskItem> risks;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => risks.isEmpty;
  int get totalRisks => risks.length;
  int get criticalRisks => risks.where((item) => item.score >= 20).length;
  int get highRisks => risks.where((item) => item.score >= 12).length;

  int get overallScore {
    if (risks.isEmpty) return 0;
    final total = risks.fold<int>(0, (sum, item) => sum + item.score);
    return (total / risks.length).round().clamp(0, 25).toInt();
  }

  String get overallLabelAr {
    if (overallScore >= 20) return 'حرج';
    if (overallScore >= 12) return 'عالٍ';
    if (overallScore >= 6) return 'متوسط';
    if (overallScore > 0) return 'منخفض';
    return 'لا توجد مخاطر ظاهرة';
  }

  List<SmartExplorerRiskItem> get topRisks {
    final out = List<SmartExplorerRiskItem>.from(risks)
      ..sort((a, b) => b.score.compareTo(a.score));
    return out.take(15).toList(growable: false);
  }

  String get summaryAr {
    if (risks.isEmpty) return 'لا توجد مخاطر تشغيلية ظاهرة ضمن النطاق الحالي.';
    return 'سجل مخاطر يضم $totalRisks بندًا، منها $criticalRisks حرجة، والتقييم العام: $overallLabelAr.';
  }
}

class SmartExplorerRiskItem {
  const SmartExplorerRiskItem({
    required this.titleAr,
    required this.descriptionAr,
    required this.mitigationAr,
    required this.domainAr,
    required this.severity,
    required this.likelihood,
    this.resultId,
    this.resultTitleAr,
  });

  final String titleAr;
  final String descriptionAr;
  final String mitigationAr;
  final String domainAr;
  final int severity;
  final int likelihood;
  final String? resultId;
  final String? resultTitleAr;

  int get score => (severity.clamp(1, 5) * likelihood.clamp(1, 5)).toInt();

  String get scoreLabelAr {
    if (score >= 20) return 'حرج';
    if (score >= 12) return 'عالٍ';
    if (score >= 6) return 'متوسط';
    return 'منخفض';
  }
}
