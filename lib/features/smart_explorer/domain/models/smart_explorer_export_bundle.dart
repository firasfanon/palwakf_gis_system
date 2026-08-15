/// A text-based export bundle that collects the most important Smart Explorer
/// artifacts for handoff. It intentionally remains fileless/plain-text inside
/// Flutter so it can be copied, reviewed, or later persisted through an approved
/// governance path.
class SmartExplorerExportBundle {
  const SmartExplorerExportBundle({
    required this.sections,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerExportSection> sections;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => sections.isEmpty;
  int get totalSections => sections.length;

  String get summaryAr {
    if (sections.isEmpty) return 'لا توجد مواد جاهزة للتصدير التشغيلي.';
    return 'حزمة تسليم تضم $totalSections أقسام تشغيلية قابلة للنسخ والمراجعة.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('حزمة تصدير/تسليم المستكشف الذكي')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('تنبيه: الحزمة مخرجات مراجعة غير سيادية ولا تغني عن اعتماد بشري.')
      ..writeln('---');
    for (final section in sections) {
      buffer
        ..writeln('# ${section.titleAr}')
        ..writeln(section.bodyAr.trim().isEmpty ? 'لا توجد بيانات.' : section.bodyAr.trim())
        ..writeln('---');
    }
    return buffer.toString();
  }
}

class SmartExplorerExportSection {
  const SmartExplorerExportSection({
    required this.titleAr,
    required this.bodyAr,
  });

  final String titleAr;
  final String bodyAr;
}
