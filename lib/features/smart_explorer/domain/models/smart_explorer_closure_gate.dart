/// Closure gate for deciding whether the current smart-explorer workspace is
/// ready for handoff, field review, or integration with the wider explorer.
class SmartExplorerClosureGate {
  const SmartExplorerClosureGate({
    required this.gates,
    required this.readinessScore,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerClosureGateItem> gates;
  final int readinessScore;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => gates.isEmpty;
  bool get canProceed => gates.isNotEmpty && gates.every((gate) => !gate.isBlocking);
  int get blockingCount => gates.where((gate) => gate.isBlocking).length;
  int get warningCount => gates.where((gate) => gate.status == SmartExplorerClosureGateStatus.warning).length;

  String get readinessLabelAr {
    if (readinessScore >= 85 && canProceed) return 'جاهز للتوريث التشغيلي';
    if (readinessScore >= 65) return 'جاهز جزئيًا مع تحفظات';
    if (readinessScore >= 40) return 'يحتاج استكمال قبل التوريث';
    return 'غير جاهز';
  }

  String get summaryAr {
    if (gates.isEmpty) return 'لا توجد بوابات إغلاق ضمن النطاق الحالي.';
    return '$readinessLabelAr — درجة $readinessScore%، موانع: $blockingCount، تحذيرات: $warningCount.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('بوابة إغلاق المستكشف الذكي')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('---');
    for (final gate in gates) {
      buffer
        ..writeln('[${gate.status.labelAr}] ${gate.titleAr}')
        ..writeln('الوصف: ${gate.descriptionAr}')
        ..writeln('الإجراء التالي: ${gate.nextActionAr}')
        ..writeln('مانعة: ${gate.isBlocking ? 'نعم' : 'لا'}')
        ..writeln('---');
    }
    return buffer.toString();
  }
}

enum SmartExplorerClosureGateStatus { pass, warning, blocked }

extension SmartExplorerClosureGateStatusX on SmartExplorerClosureGateStatus {
  String get labelAr {
    switch (this) {
      case SmartExplorerClosureGateStatus.pass:
        return 'ناجحة';
      case SmartExplorerClosureGateStatus.warning:
        return 'تحذير';
      case SmartExplorerClosureGateStatus.blocked:
        return 'مانعة';
    }
  }
}

class SmartExplorerClosureGateItem {
  const SmartExplorerClosureGateItem({
    required this.titleAr,
    required this.descriptionAr,
    required this.status,
    required this.nextActionAr,
    this.isBlocking = false,
  });

  final String titleAr;
  final String descriptionAr;
  final SmartExplorerClosureGateStatus status;
  final String nextActionAr;
  final bool isBlocking;
}
