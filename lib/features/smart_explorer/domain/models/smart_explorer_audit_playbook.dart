/// A field/document/GIS audit playbook generated for the current Smart Explorer
/// scope. It is an operational guide and not a task-system write.
class SmartExplorerAuditPlaybook {
  const SmartExplorerAuditPlaybook({
    required this.steps,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerAuditPlaybookStep> steps;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => steps.isEmpty;
  int get totalSteps => steps.length;

  String get summaryAr {
    if (steps.isEmpty) return 'لا يوجد دليل تدقيق تشغيلي للنطاق الحالي.';
    return 'دليل تدقيق من $totalSteps خطوات يوجه الفريق من القراءة إلى قرار الإغلاق.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('دليل التدقيق التشغيلي للمستكشف الذكي')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('---');
    for (final step in steps) {
      buffer
        ..writeln('${step.order}. ${step.titleAr}')
        ..writeln('   المسؤول المقترح: ${step.ownerAr}')
        ..writeln('   المدخل: ${step.inputAr}')
        ..writeln('   الإجراء: ${step.actionAr}')
        ..writeln('   مخرج الخطوة: ${step.outputAr}')
        ..writeln('   معيار التوقف/الإغلاق: ${step.stopCriterionAr}');
    }
    return buffer.toString();
  }
}

class SmartExplorerAuditPlaybookStep {
  const SmartExplorerAuditPlaybookStep({
    required this.order,
    required this.titleAr,
    required this.ownerAr,
    required this.inputAr,
    required this.actionAr,
    required this.outputAr,
    required this.stopCriterionAr,
  });

  final int order;
  final String titleAr;
  final String ownerAr;
  final String inputAr;
  final String actionAr;
  final String outputAr;
  final String stopCriterionAr;
}
