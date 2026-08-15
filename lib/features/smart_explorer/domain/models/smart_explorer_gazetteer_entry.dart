import 'smart_explorer_document_analysis.dart';
import 'smart_explorer_result.dart';

/// Draft gazetteer entry generated locally by Smart Explorer.
///
/// It is intentionally non-sovereign: it can guide search/review, but it does
/// not update any authoritative place, waqf, or asset table.
class SmartExplorerGazetteerEntry {
  const SmartExplorerGazetteerEntry({
    required this.value,
    required this.normalizedValue,
    required this.typeLabelAr,
    required this.sourceLabelAr,
    required this.confidence,
    required this.suggestedQuery,
    required this.evidence,
    required this.notesAr,
  });

  factory SmartExplorerGazetteerEntry.fromEntity(
    SmartExplorerDocumentEntity entity,
  ) {
    return SmartExplorerGazetteerEntry(
      value: entity.value,
      normalizedValue: normalize(entity.value),
      typeLabelAr: entity.typeLabelAr,
      sourceLabelAr: 'تحليل وثيقة',
      confidence: entity.score,
      suggestedQuery: entity.value,
      evidence: entity.evidence,
      notesAr: 'مسودة اسم مستخرجة من نص وثائقي وتحتاج مراجعة بشرية.',
    );
  }

  factory SmartExplorerGazetteerEntry.fromResult(
    SmartExplorerResult result,
  ) {
    final label = result.endowmentName.trim().isNotEmpty
        ? result.endowmentName.trim()
        : result.titleAr.trim();
    return SmartExplorerGazetteerEntry(
      value: label,
      normalizedValue: normalize(label),
      typeLabelAr: result.endowmentName.trim().isNotEmpty ? 'وقف' : 'أصل وقفي',
      sourceLabelAr: 'نتيجة مستكشف',
      confidence: (result.confidenceScore / 100).clamp(0, 1).toDouble(),
      suggestedQuery: result.mapQuery,
      evidence: result.compactAuditSummary,
      notesAr: result.needsReview
          ? 'الاسم مرتبط بنتيجة تحتاج تدقيق قبل أي اعتماد.'
          : 'الاسم ظاهر في نتيجة مستقرة ظاهريًا ويمكن استخدامه كبذرة بحث.',
    );
  }

  final String value;
  final String normalizedValue;
  final String typeLabelAr;
  final String sourceLabelAr;
  final double confidence;
  final String suggestedQuery;
  final String evidence;
  final String notesAr;

  int get confidencePercent => (confidence.clamp(0, 1) * 100).round();

  static String normalize(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[إأآا]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }
}
