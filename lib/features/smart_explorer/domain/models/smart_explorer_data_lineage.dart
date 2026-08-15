/// Data-lineage trace for Smart Explorer outputs.
///
/// The trace separates sovereign sources from smart, derived, or review-only
/// artifacts so reviewers know what can be trusted, what is only suggested, and
/// what needs human approval.
class SmartExplorerDataLineage {
  const SmartExplorerDataLineage({
    required this.items,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerLineageItem> items;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => items.isEmpty;
  int get totalItems => items.length;
  int get sovereignItems => items.where((item) => item.governance == SmartExplorerLineageGovernance.sovereign).length;
  int get reviewOnlyItems => items.where((item) => item.governance == SmartExplorerLineageGovernance.reviewOnly).length;

  String get summaryAr {
    if (items.isEmpty) return 'لا يوجد أثر بيانات ضمن النطاق الحالي.';
    return 'أثر بيانات يضم $totalItems عنصرًا، سيادي: $sovereignItems، مراجعة فقط: $reviewOnlyItems.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('أثر البيانات — المستكشف الذكي')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('---');
    for (final item in items) {
      buffer
        ..writeln(item.labelAr)
        ..writeln('المصدر: ${item.sourceAr}')
        ..writeln('الحوكمة: ${item.governance.labelAr}')
        ..writeln('الاستخدام: ${item.allowedUseAr}')
        ..writeln('التنبيه: ${item.warningAr}')
        ..writeln('---');
    }
    return buffer.toString();
  }
}

enum SmartExplorerLineageGovernance { sovereign, operational, derived, reviewOnly }

extension SmartExplorerLineageGovernanceX on SmartExplorerLineageGovernance {
  String get labelAr {
    switch (this) {
      case SmartExplorerLineageGovernance.sovereign:
        return 'مصدر سيادي';
      case SmartExplorerLineageGovernance.operational:
        return 'تشغيلي';
      case SmartExplorerLineageGovernance.derived:
        return 'مشتق/محسوب';
      case SmartExplorerLineageGovernance.reviewOnly:
        return 'للمراجعة فقط';
    }
  }
}

class SmartExplorerLineageItem {
  const SmartExplorerLineageItem({
    required this.labelAr,
    required this.sourceAr,
    required this.governance,
    required this.allowedUseAr,
    required this.warningAr,
  });

  final String labelAr;
  final String sourceAr;
  final SmartExplorerLineageGovernance governance;
  final String allowedUseAr;
  final String warningAr;
}
