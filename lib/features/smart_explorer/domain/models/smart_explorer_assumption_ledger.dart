/// Assumptions extracted from the current Smart Explorer workspace.
///
/// Assumptions must be reviewed and either confirmed, rejected, or converted
/// into audit requests. They are never sovereign facts by themselves.
class SmartExplorerAssumptionLedger {
  const SmartExplorerAssumptionLedger({
    required this.items,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerAssumptionItem> items;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => items.isEmpty;
  int get totalItems => items.length;
  int get highRiskItems => items.where((item) => item.riskLevel >= 75).length;

  String get summaryAr {
    if (items.isEmpty) return 'لا توجد افتراضات ظاهرة ضمن النطاق الحالي.';
    return 'سجل افتراضات يضم $totalItems بندًا، منها $highRiskItems عالية المخاطر.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('سجل افتراضات المستكشف الذكي')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('تنبيه: كل بند هنا افتراض يحتاج إثباتًا ولا يمثل حقيقة سيادية.')
      ..writeln('---');
    for (final item in items) {
      buffer
        ..writeln('[${item.riskLabelAr}] ${item.assumptionAr}')
        ..writeln('المصدر: ${item.sourceAr}')
        ..writeln('لماذا هو افتراض؟ ${item.reasonAr}')
        ..writeln('طريقة التحقق: ${item.verificationAr}')
        ..writeln('الأثر إن كان خاطئًا: ${item.impactIfWrongAr}')
        ..writeln('---');
    }
    return buffer.toString();
  }
}

class SmartExplorerAssumptionItem {
  const SmartExplorerAssumptionItem({
    required this.assumptionAr,
    required this.sourceAr,
    required this.reasonAr,
    required this.verificationAr,
    required this.impactIfWrongAr,
    required this.riskLevel,
  });

  final String assumptionAr;
  final String sourceAr;
  final String reasonAr;
  final String verificationAr;
  final String impactIfWrongAr;
  final int riskLevel;

  String get riskLabelAr {
    if (riskLevel >= 85) return 'حرج';
    if (riskLevel >= 70) return 'عالٍ';
    if (riskLevel >= 45) return 'متوسط';
    return 'منخفض';
  }
}
