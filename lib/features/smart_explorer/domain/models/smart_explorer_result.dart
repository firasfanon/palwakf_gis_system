import 'smart_explorer_gap_signal.dart';
import 'smart_explorer_hypothesis.dart';

/// UI-safe result model for Smart Explorer.
///
/// It wraps a waqf asset search result with non-sovereign analysis signals. It
/// does not redefine the source of truth for the asset.
class SmartExplorerResult {
  const SmartExplorerResult({
    required this.id,
    required this.titleAr,
    required this.subtitleAr,
    required this.assetCode,
    required this.endowmentName,
    required this.governorate,
    required this.community,
    required this.lgu,
    required this.assetType,
    required this.status,
    required this.usage,
    required this.hasGeometry,
    required this.hasCenter,
    required this.hasCentroid,
    required this.linkedParcelsCount,
    required this.gapSignals,
    required this.hypotheses,
    required this.raw,
  });

  final String id;
  final String titleAr;
  final String subtitleAr;
  final String assetCode;
  final String endowmentName;
  final String governorate;
  final String community;
  final String lgu;
  final String assetType;
  final String status;
  final String usage;
  final bool hasGeometry;
  final bool hasCenter;
  final bool hasCentroid;
  final int linkedParcelsCount;
  final List<SmartExplorerGapSignal> gapSignals;
  final List<SmartExplorerHypothesis> hypotheses;
  final Object? raw;

  bool get hasAnySpatialReference => hasGeometry || hasCenter || hasCentroid;
  bool get hasLinkedParcels => linkedParcelsCount > 0;
  bool get needsReview => gapSignals.isNotEmpty || hypotheses.isNotEmpty;
  bool get missingAdministrativeContext => community.isEmpty || lgu.isEmpty;
  bool get missingReferenceContext => endowmentName.isEmpty || assetCode.isEmpty;
  bool get weakSpatialContext => !hasAnySpatialReference || !hasLinkedParcels;

  String get mapQuery => assetCode.trim().isNotEmpty ? assetCode : titleAr;

  int get confidenceScore {
    var score = 100;
    for (final signal in gapSignals) {
      switch (signal.severity) {
        case SmartExplorerSignalSeverity.critical:
          score -= 28;
          break;
        case SmartExplorerSignalSeverity.high:
          score -= 18;
          break;
        case SmartExplorerSignalSeverity.medium:
          score -= 10;
          break;
        case SmartExplorerSignalSeverity.low:
          score -= 5;
          break;
      }
      score -= signal.weight.clamp(0, 4) - 1;
    }
    return score.clamp(0, 100).toInt();
  }

  int get reviewScore {
    var score = 0;
    for (final signal in gapSignals) {
      switch (signal.severity) {
        case SmartExplorerSignalSeverity.critical:
          score += 40;
          break;
        case SmartExplorerSignalSeverity.high:
          score += 24;
          break;
        case SmartExplorerSignalSeverity.medium:
          score += 12;
          break;
        case SmartExplorerSignalSeverity.low:
          score += 5;
          break;
      }
      score += signal.weight.clamp(0, 5);
    }
    if (!hasAnySpatialReference) score += 12;
    if (!hasLinkedParcels) score += 8;
    if (endowmentName.isEmpty) score += 8;
    return score;
  }

  String get confidenceLabelAr {
    final score = confidenceScore;
    if (score >= 85) return 'عالٍ';
    if (score >= 65) return 'متوسط';
    if (score >= 40) return 'منخفض';
    return 'حرج';
  }

  String get reviewPriorityLabelAr {
    if (reviewScore >= 72) return 'عاجلة';
    if (reviewScore >= 45) return 'عالية';
    if (reviewScore >= 20) return 'متوسطة';
    if (reviewScore > 0) return 'منخفضة';
    return 'لا توجد فجوات ظاهرة';
  }

  String get topSeverityLabelAr {
    final severity = topSeverity;
    if (severity == null) return 'سليم ظاهريًا';
    switch (severity) {
      case SmartExplorerSignalSeverity.critical:
        return 'حرجة';
      case SmartExplorerSignalSeverity.high:
        return 'عالية';
      case SmartExplorerSignalSeverity.medium:
        return 'متوسطة';
      case SmartExplorerSignalSeverity.low:
        return 'منخفضة';
    }
  }

  SmartExplorerSignalSeverity? get topSeverity {
    if (hasSeverity(SmartExplorerSignalSeverity.critical)) {
      return SmartExplorerSignalSeverity.critical;
    }
    if (hasSeverity(SmartExplorerSignalSeverity.high)) {
      return SmartExplorerSignalSeverity.high;
    }
    if (hasSeverity(SmartExplorerSignalSeverity.medium)) {
      return SmartExplorerSignalSeverity.medium;
    }
    if (hasSeverity(SmartExplorerSignalSeverity.low)) {
      return SmartExplorerSignalSeverity.low;
    }
    return null;
  }

  bool hasSeverity(SmartExplorerSignalSeverity severity) {
    return gapSignals.any((signal) => signal.severity == severity);
  }

  int severityCount(SmartExplorerSignalSeverity severity) {
    return gapSignals.where((signal) => signal.severity == severity).length;
  }

  List<String> get evidenceLines {
    return <String>[
      if (assetCode.isNotEmpty) 'رمز الأصل: $assetCode',
      if (endowmentName.isNotEmpty) 'الوقف الأم: $endowmentName',
      if (governorate.isNotEmpty) 'المحافظة: $governorate',
      if (community.isNotEmpty) 'التجمع: $community',
      if (lgu.isNotEmpty) 'الهيئة المحلية: $lgu',
      if (assetType.isNotEmpty) 'نوع الأصل: $assetType',
      if (status.isNotEmpty) 'الحالة: $status',
      'تمثيل مكاني: ${hasAnySpatialReference ? 'متوفر' : 'غير متوفر'}',
      'قطع مرتبطة: $linkedParcelsCount',
      ...gapSignals.map((signal) => 'إشارة: ${signal.titleAr}'),
    ];
  }

  String get compactAuditSummary {
    final lines = <String>[
      titleAr,
      if (assetCode.isNotEmpty) 'الرمز: $assetCode',
      if (endowmentName.isNotEmpty) 'الوقف: $endowmentName',
      'الثقة: $confidenceScore% ($confidenceLabelAr)',
      'أولوية المراجعة: $reviewPriorityLabelAr',
      if (gapSignals.isNotEmpty)
        "الفجوات: ${gapSignals.map((e) => e.titleAr).join('، ')}",
      'الإجراء المقترح: $recommendedActionAr',
    ];
    return lines.join('\n');
  }

  String get recommendedActionAr {
    if (gapSignals.any((signal) => signal.isCritical)) {
      return 'فتح طلب تدقيق عاجل قبل اعتماد أي ربط مكاني.';
    }
    if (gapSignals.any((signal) => signal.isHigh)) {
      return 'مراجعة الربط المكاني/الوقفي واستكمال الأدلة.';
    }
    if (gapSignals.isNotEmpty) {
      return 'استكمال بيانات مرجعية وتحسين جودة النتيجة.';
    }
    return 'النتيجة صالحة للعرض والتحليل، مع بقاء الاعتماد البشري لازمًا.';
  }

  SmartExplorerResult copyWith({
    List<SmartExplorerGapSignal>? gapSignals,
    List<SmartExplorerHypothesis>? hypotheses,
  }) {
    return SmartExplorerResult(
      id: id,
      titleAr: titleAr,
      subtitleAr: subtitleAr,
      assetCode: assetCode,
      endowmentName: endowmentName,
      governorate: governorate,
      community: community,
      lgu: lgu,
      assetType: assetType,
      status: status,
      usage: usage,
      hasGeometry: hasGeometry,
      hasCenter: hasCenter,
      hasCentroid: hasCentroid,
      linkedParcelsCount: linkedParcelsCount,
      gapSignals: gapSignals ?? this.gapSignals,
      hypotheses: hypotheses ?? this.hypotheses,
      raw: raw,
    );
  }
}
