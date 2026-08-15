/// Runtime diagnostics generated for the current Smart Explorer workspace.
///
/// The diagnostics are local/read-only and are intended to prevent silent
/// expansion when the workspace has not produced enough review evidence.
class SmartExplorerRuntimeDiagnostics {
  const SmartExplorerRuntimeDiagnostics({
    required this.items,
    required this.generatedAt,
    required this.scopeLabelAr,
    required this.recommendationAr,
  });

  final List<SmartExplorerRuntimeDiagnosticItem> items;
  final DateTime generatedAt;
  final String scopeLabelAr;
  final String recommendationAr;

  bool get isEmpty => items.isEmpty;
  int get totalItems => items.length;
  int get blockingItems => items.where((item) => item.isBlocking).length;
  int get warningItems => items
      .where((item) => item.level == SmartExplorerRuntimeDiagnosticLevel.warning)
      .length;

  String get summaryAr {
    if (items.isEmpty) return 'لا توجد عناصر تشخيص تشغيلية.';
    if (blockingItems > 0) {
      return 'يوجد $blockingItems مانع تشغيل يجب إغلاقه قبل التوسع.';
    }
    if (warningItems > 0) {
      return 'يوجد $warningItems تنبيه تشغيل، ولا توجد موانع مباشرة.';
    }
    return 'التشخيص التشغيلي مستقر ضمن النطاق الحالي.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('تشخيص تشغيل المستكشف الذكي')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('التوصية: $recommendationAr')
      ..writeln('---');

    for (final item in items) {
      buffer
        ..writeln('- ${item.titleAr}')
        ..writeln('  المستوى: ${item.level.labelAr}')
        ..writeln('  مانع؟ ${item.isBlocking ? 'نعم' : 'لا'}')
        ..writeln('  الحالة: ${item.statusAr}')
        ..writeln('  الدليل: ${item.evidenceAr}')
        ..writeln('  الإجراء التالي: ${item.nextActionAr}');
    }

    return buffer.toString();
  }
}

class SmartExplorerRuntimeDiagnosticItem {
  const SmartExplorerRuntimeDiagnosticItem({
    required this.titleAr,
    required this.level,
    required this.isBlocking,
    required this.statusAr,
    required this.evidenceAr,
    required this.nextActionAr,
  });

  final String titleAr;
  final SmartExplorerRuntimeDiagnosticLevel level;
  final bool isBlocking;
  final String statusAr;
  final String evidenceAr;
  final String nextActionAr;
}

enum SmartExplorerRuntimeDiagnosticLevel {
  pass,
  warning,
  blocking,
}

extension SmartExplorerRuntimeDiagnosticLevelLabel
    on SmartExplorerRuntimeDiagnosticLevel {
  String get labelAr {
    switch (this) {
      case SmartExplorerRuntimeDiagnosticLevel.pass:
        return 'مغلق';
      case SmartExplorerRuntimeDiagnosticLevel.warning:
        return 'تنبيه';
      case SmartExplorerRuntimeDiagnosticLevel.blocking:
        return 'مانع';
    }
  }
}
