/// Local decision log for Smart Explorer sessions.
///
/// The log records proposed operational decisions only. It is not a legal,
/// cadastral, or sovereign approval record.
class SmartExplorerDecisionLog {
  const SmartExplorerDecisionLog({
    required this.entries,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerDecisionLogEntry> entries;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => entries.isEmpty;
  int get totalEntries => entries.length;
  int get blockedEntries => entries.where((item) => item.status == SmartExplorerDecisionLogStatus.blocked).length;

  String get summaryAr {
    if (entries.isEmpty) return 'لا توجد قرارات تشغيلية مسجلة ضمن النطاق الحالي.';
    return 'سجل قرارات يضم $totalEntries بندًا، منها $blockedEntries مانعة أو مؤجلة.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('سجل قرارات المستكشف الذكي')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('---');
    for (final entry in entries) {
      buffer
        ..writeln('[${entry.status.labelAr}] ${entry.titleAr}')
        ..writeln('السبب: ${entry.rationaleAr}')
        ..writeln('الأثر: ${entry.impactAr}')
        ..writeln('الخطوة التالية: ${entry.nextStepAr}')
        ..writeln('---');
    }
    return buffer.toString();
  }
}

enum SmartExplorerDecisionLogStatus { proposed, acceptedForReview, blocked, deferred }

extension SmartExplorerDecisionLogStatusX on SmartExplorerDecisionLogStatus {
  String get labelAr {
    switch (this) {
      case SmartExplorerDecisionLogStatus.proposed:
        return 'مقترح';
      case SmartExplorerDecisionLogStatus.acceptedForReview:
        return 'مقبول للمراجعة';
      case SmartExplorerDecisionLogStatus.blocked:
        return 'مانع';
      case SmartExplorerDecisionLogStatus.deferred:
        return 'مؤجل';
    }
  }
}

class SmartExplorerDecisionLogEntry {
  const SmartExplorerDecisionLogEntry({
    required this.titleAr,
    required this.rationaleAr,
    required this.impactAr,
    required this.nextStepAr,
    required this.status,
  });

  final String titleAr;
  final String rationaleAr;
  final String impactAr;
  final String nextStepAr;
  final SmartExplorerDecisionLogStatus status;
}
