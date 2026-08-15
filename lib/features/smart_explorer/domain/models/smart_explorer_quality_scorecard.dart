import 'smart_explorer_gap_signal.dart';

/// Non-sovereign quality scorecard for the Smart Explorer workspace.
///
/// The scorecard summarizes operational readiness only. It does not approve,
/// mutate, or publish any source-of-truth records.
class SmartExplorerQualityScorecard {
  const SmartExplorerQualityScorecard({
    required this.items,
    required this.overallScore,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerQualityScoreItem> items;
  final int overallScore;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => items.isEmpty;
  int get totalItems => items.length;
  int get failingItems => items.where((item) => item.score < 55).length;
  int get warningItems => items.where((item) => item.score >= 55 && item.score < 75).length;

  String get ratingLabelAr {
    if (overallScore >= 85) return 'جاهزية عالية';
    if (overallScore >= 70) return 'جاهزية جيدة مع تحفظات';
    if (overallScore >= 50) return 'جاهزية متوسطة تحتاج إغلاق فجوات';
    return 'جاهزية منخفضة';
  }

  String get summaryAr {
    if (items.isEmpty) return 'لا توجد عناصر كافية لبناء بطاقة جودة.';
    return '$ratingLabelAr — الدرجة الإجمالية $overallScore%، مع $failingItems عناصر حرجة و$warningItems عناصر تحذيرية.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('بطاقة جودة المستكشف الذكي')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('تنبيه: هذه بطاقة تشغيلية غير سيادية ولا تعتمد أي تعديل بيانات.')
      ..writeln('---');
    for (final item in items) {
      buffer
        ..writeln('${item.titleAr}: ${item.score}% — ${item.statusLabelAr}')
        ..writeln('الملاحظة: ${item.noteAr}')
        ..writeln('الإجراء المقترح: ${item.nextActionAr}')
        ..writeln('---');
    }
    return buffer.toString();
  }
}

class SmartExplorerQualityScoreItem {
  const SmartExplorerQualityScoreItem({
    required this.titleAr,
    required this.score,
    required this.noteAr,
    required this.nextActionAr,
    this.relatedSeverity,
  });

  final String titleAr;
  final int score;
  final String noteAr;
  final String nextActionAr;
  final SmartExplorerSignalSeverity? relatedSeverity;

  String get statusLabelAr {
    if (score >= 85) return 'ممتاز';
    if (score >= 70) return 'مقبول';
    if (score >= 55) return 'تحذيري';
    return 'حرج';
  }
}
