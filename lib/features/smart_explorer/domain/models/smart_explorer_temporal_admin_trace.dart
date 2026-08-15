/// A review trace for linking historical or descriptive context to modern
/// administrative geography without creating sovereign records.
class SmartExplorerTemporalAdminTrace {
  const SmartExplorerTemporalAdminTrace({
    required this.steps,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerTemporalAdminStep> steps;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => steps.isEmpty;
  int get totalSteps => steps.length;

  String get summaryAr {
    if (steps.isEmpty) return 'لا توجد سلسلة إدارية زمنية مقترحة.';
    return 'أثر إداري/زمني من $totalSteps خطوات يساعد على مراجعة السلالة التاريخية.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('الأثر الإداري الزمني')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('تنبيه: الأثر المقترح لا يعتمد علاقة تاريخية إلا بعد مراجعة مصادرها.')
      ..writeln('---');
    for (final step in steps) {
      buffer
        ..writeln('- ${step.periodLabelAr}')
        ..writeln('  الكيان/النطاق: ${step.adminUnitLabelAr}')
        ..writeln('  الدليل: ${step.evidenceAr}')
        ..writeln('  مستوى اليقين: ${step.certaintyLabelAr}')
        ..writeln('  الإجراء التالي: ${step.nextActionAr}');
    }
    return buffer.toString();
  }
}

class SmartExplorerTemporalAdminStep {
  const SmartExplorerTemporalAdminStep({
    required this.periodLabelAr,
    required this.adminUnitLabelAr,
    required this.evidenceAr,
    required this.certaintyLabelAr,
    required this.nextActionAr,
  });

  final String periodLabelAr;
  final String adminUnitLabelAr;
  final String evidenceAr;
  final String certaintyLabelAr;
  final String nextActionAr;
}
