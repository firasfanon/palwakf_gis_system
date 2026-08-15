import 'smart_explorer_result.dart';

/// Readiness assessment for using a Smart Explorer result in different flows.
///
/// It is local/rule-based and does not approve records.
class SmartExplorerReadinessAssessment {
  const SmartExplorerReadinessAssessment({
    required this.resultId,
    required this.titleAr,
    required this.assetCode,
    required this.publicMapScore,
    required this.fieldAuditScore,
    required this.historyScore,
    required this.governanceScore,
    required this.blockers,
    required this.nextActions,
  });

  factory SmartExplorerReadinessAssessment.fromResult(
    SmartExplorerResult result,
  ) {
    var publicMap = 100;
    var field = 100;
    var history = 100;
    var governance = 100;
    final blockers = <String>[];
    final actions = <String>[];

    if (!result.hasAnySpatialReference) {
      publicMap -= 55;
      field -= 35;
      blockers.add('لا يوجد تمثيل مكاني ظاهر.');
      actions.add('إنشاء طلب تدقيق مكاني وربطه بنقطة أو قطعة.');
    }
    if (!result.hasGeometry) {
      publicMap -= 15;
      history -= 12;
      actions.add('اختبار وجود هندسة أصل أو قطعة مرتبطة عند الزوم المناسب.');
    }
    if (!result.hasLinkedParcels) {
      publicMap -= 18;
      field -= 22;
      blockers.add('لا توجد قطع مرتبطة.');
      actions.add('مطابقة محتملة مع التسوية/الأحواض قبل اعتماد العرض العام.');
    }
    if (result.endowmentName.trim().isEmpty) {
      history -= 30;
      governance -= 20;
      blockers.add('الوقف الأم غير ظاهر.');
      actions.add('مراجعة الربط المرجعي داخل awqaf_system.');
    }
    if (result.assetCode.trim().isEmpty) {
      governance -= 30;
      blockers.add('الرمز الوطني غير ظاهر.');
      actions.add('التحقق من الرمز الوطني السيادي دون توليده داخل المستكشف.');
    }
    if (result.community.trim().isEmpty || result.lgu.trim().isEmpty) {
      field -= 12;
      governance -= 12;
      actions.add('استكمال السياق الإداري الحديث قبل التقارير النهائية.');
    }
    if (result.status.trim().isEmpty || result.assetType.trim().isEmpty) {
      governance -= 10;
      actions.add('استكمال نوع/حالة الأصل لتحسين الفلاتر والتقارير.');
    }

    if (blockers.isEmpty) {
      actions.add('يمكن استخدام النتيجة للعرض والتحليل مع بقاء المراجعة البشرية مطلوبة.');
    }

    return SmartExplorerReadinessAssessment(
      resultId: result.id,
      titleAr: result.titleAr,
      assetCode: result.assetCode,
      publicMapScore: publicMap.clamp(0, 100).toInt(),
      fieldAuditScore: field.clamp(0, 100).toInt(),
      historyScore: history.clamp(0, 100).toInt(),
      governanceScore: governance.clamp(0, 100).toInt(),
      blockers: blockers,
      nextActions: actions,
    );
  }

  final String resultId;
  final String titleAr;
  final String assetCode;
  final int publicMapScore;
  final int fieldAuditScore;
  final int historyScore;
  final int governanceScore;
  final List<String> blockers;
  final List<String> nextActions;

  int get overallScore {
    return ((publicMapScore + fieldAuditScore + historyScore + governanceScore) / 4).round();
  }

  String get readinessLabelAr {
    final score = overallScore;
    if (score >= 85) return 'جاهز ظاهريًا';
    if (score >= 65) return 'جاهزية متوسطة';
    if (score >= 40) return 'يحتاج تدقيقًا';
    return 'غير جاهز';
  }
}
