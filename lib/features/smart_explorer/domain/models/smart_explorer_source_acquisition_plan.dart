/// A non-sovereign plan for collecting missing sources needed to improve
/// confidence in Smart Explorer results.
class SmartExplorerSourceAcquisitionPlan {
  const SmartExplorerSourceAcquisitionPlan({
    required this.items,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerSourceAcquisitionItem> items;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => items.isEmpty;
  int get totalItems => items.length;

  String get summaryAr {
    if (items.isEmpty) return 'لا توجد مصادر إضافية مقترحة للنطاق الحالي.';
    return 'خطة تحصيل مصادر تضم $totalItems بندًا لرفع الثقة قبل الاعتماد.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('خطة تحصيل المصادر والأدلة')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('تنبيه: لا تعتبر هذه الخطة أمرًا بإضافة سجل سيادي؛ هي طلبات تحصيل ومراجعة فقط.')
      ..writeln('---');
    for (final item in items) {
      buffer
        ..writeln('- ${item.titleAr}')
        ..writeln('  النوع: ${item.sourceTypeLabelAr}')
        ..writeln('  الأولوية: ${item.priorityLabelAr}')
        ..writeln('  السبب: ${item.reasonAr}')
        ..writeln('  أين نبحث: ${item.suggestedLocationAr}')
        ..writeln('  معيار الإغلاق: ${item.closureCriterionAr}');
    }
    return buffer.toString();
  }
}

class SmartExplorerSourceAcquisitionItem {
  const SmartExplorerSourceAcquisitionItem({
    required this.titleAr,
    required this.sourceTypeLabelAr,
    required this.priorityLabelAr,
    required this.reasonAr,
    required this.suggestedLocationAr,
    required this.closureCriterionAr,
  });

  final String titleAr;
  final String sourceTypeLabelAr;
  final String priorityLabelAr;
  final String reasonAr;
  final String suggestedLocationAr;
  final String closureCriterionAr;
}
