/// Release readiness report for enabling or expanding Smart Explorer features.
class SmartExplorerReleaseReadiness {
  const SmartExplorerReleaseReadiness({
    required this.gates,
    required this.generatedAt,
    required this.scopeLabelAr,
    required this.recommendationAr,
  });

  final List<SmartExplorerReleaseGate> gates;
  final DateTime generatedAt;
  final String scopeLabelAr;
  final String recommendationAr;

  bool get isEmpty => gates.isEmpty;
  int get totalGates => gates.length;
  int get blockingGates => gates.where((gate) => gate.isBlocking).length;

  String get summaryAr {
    if (gates.isEmpty) return 'لا توجد بوابات جاهزية إصدار.';
    if (blockingGates == 0) {
      return 'جاهزية إصدار تشغيلية مبدئية دون بوابات مانعة.';
    }
    return 'توجد $blockingGates بوابات مانعة يجب إغلاقها قبل التوسع.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('جاهزية إصدار المستكشف الذكي')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('التوصية: $recommendationAr')
      ..writeln('---');
    for (final gate in gates) {
      buffer
        ..writeln('- ${gate.titleAr}')
        ..writeln('  الحالة: ${gate.statusLabelAr}')
        ..writeln('  مانعة؟ ${gate.isBlocking ? 'نعم' : 'لا'}')
        ..writeln('  الملاحظة: ${gate.noteAr}')
        ..writeln('  الإجراء المطلوب: ${gate.requiredActionAr}');
    }
    return buffer.toString();
  }
}

class SmartExplorerReleaseGate {
  const SmartExplorerReleaseGate({
    required this.titleAr,
    required this.statusLabelAr,
    required this.isBlocking,
    required this.noteAr,
    required this.requiredActionAr,
  });

  final String titleAr;
  final String statusLabelAr;
  final bool isBlocking;
  final String noteAr;
  final String requiredActionAr;
}
