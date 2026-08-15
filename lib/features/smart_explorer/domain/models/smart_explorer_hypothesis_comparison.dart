/// Comparison board for spatial/historical hypotheses.
///
/// It compares rule-based candidates only. It does not assert a final location
/// and must stay behind human review and map validation.
class SmartExplorerHypothesisComparison {
  const SmartExplorerHypothesisComparison({
    required this.candidates,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerHypothesisCandidate> candidates;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => candidates.isEmpty;
  int get totalCandidates => candidates.length;
  SmartExplorerHypothesisCandidate? get bestCandidate {
    if (candidates.isEmpty) return null;
    final sorted = List<SmartExplorerHypothesisCandidate>.from(candidates)
      ..sort((a, b) => b.score.compareTo(a.score));
    return sorted.first;
  }

  String get summaryAr {
    if (candidates.isEmpty) return 'لا توجد فرضيات كافية للمقارنة.';
    final best = bestCandidate;
    return 'تمت مقارنة $totalCandidates فرضية. الأعلى: ${best?.titleAr ?? 'غير محدد'} بدرجة ${best?.score ?? 0}.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('مقارنة فرضيات المستكشف الذكي')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('---');
    for (final item in candidates) {
      buffer
        ..writeln('${item.titleAr} — ${item.scoreLabelAr}')
        ..writeln('المصدر: ${item.sourceAr}')
        ..writeln('الاستخدام المقترح: ${item.recommendedUseAr}')
        ..writeln('الأدلة المؤيدة: ${item.supportCount} | التعارضات: ${item.contradictionCount}');
      for (final evidence in item.evidence.take(6)) {
        buffer.writeln('- $evidence');
      }
      if (item.contradictions.isNotEmpty) {
        buffer.writeln('تعارضات:');
        for (final contradiction in item.contradictions.take(4)) {
          buffer.writeln('- $contradiction');
        }
      }
      buffer.writeln('---');
    }
    return buffer.toString();
  }
}

class SmartExplorerHypothesisCandidate {
  const SmartExplorerHypothesisCandidate({
    required this.id,
    required this.titleAr,
    required this.sourceAr,
    required this.score,
    required this.recommendedUseAr,
    this.evidence = const <String>[],
    this.contradictions = const <String>[],
  });

  final String id;
  final String titleAr;
  final String sourceAr;
  final int score;
  final String recommendedUseAr;
  final List<String> evidence;
  final List<String> contradictions;

  int get supportCount => evidence.length;
  int get contradictionCount => contradictions.length;
  String get scoreLabelAr {
    if (score >= 80) return 'مرجحة بقوة ($score%)';
    if (score >= 60) return 'مرجحة مبدئيًا ($score%)';
    if (score >= 40) return 'احتمالية متوسطة ($score%)';
    return 'ضعيفة ($score%)';
  }
}
