/// Expected outcomes produced by the Smart Explorer workspace.
///
/// These outcomes are review artifacts only. They describe what the current
/// scope can produce and what needs validation before any sovereign update.
class SmartExplorerExpectedOutcomes {
  const SmartExplorerExpectedOutcomes({
    required this.items,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerExpectedOutcomeItem> items;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => items.isEmpty;
  int get totalItems => items.length;

  int countByCategory(SmartExplorerOutcomeCategory category) =>
      items.where((item) => item.category == category).length;

  String get summaryAr {
    if (items.isEmpty) {
      return 'لا توجد نتائج متوقعة قابلة للتقييم في النطاق الحالي.';
    }
    return 'تم تحديد $totalItems نتيجة متوقعة موزعة على جودة البيانات، الخريطة، الوثائق، الميدان، الحوكمة، والذكاء اللاحق.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('ملف النتائج المتوقعة للمستكشف الذكي')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('تنبيه: هذه النتائج مؤشرات تشغيلية غير سيادية وتحتاج مراجعة واعتماد.')
      ..writeln('---');

    for (final category in SmartExplorerOutcomeCategory.values) {
      final categoryItems = items.where((item) => item.category == category);
      if (categoryItems.isEmpty) continue;
      buffer..writeln('## ${category.labelAr}')..writeln();
      for (final item in categoryItems) {
        buffer
          ..writeln('- ${item.titleAr}')
          ..writeln('  الوصف: ${item.descriptionAr}')
          ..writeln('  أفق النتيجة: ${item.horizonLabelAr}')
          ..writeln('  مؤشر القياس: ${item.indicatorAr}')
          ..writeln('  مصدر الدليل: ${item.evidenceSourceAr}')
          ..writeln('  خطر عدم الإغلاق: ${item.riskIfMissingAr}');
      }
      buffer.writeln('---');
    }

    return buffer.toString();
  }
}

enum SmartExplorerOutcomeCategory {
  dataQuality,
  mapReadiness,
  documentIntelligence,
  fieldAudit,
  governance,
  aiRoadmap,
}

extension SmartExplorerOutcomeCategoryX on SmartExplorerOutcomeCategory {
  String get labelAr {
    switch (this) {
      case SmartExplorerOutcomeCategory.dataQuality:
        return 'جودة البيانات';
      case SmartExplorerOutcomeCategory.mapReadiness:
        return 'جاهزية الخريطة وGIS';
      case SmartExplorerOutcomeCategory.documentIntelligence:
        return 'تحليل الوثائق والمسميات';
      case SmartExplorerOutcomeCategory.fieldAudit:
        return 'التدقيق الميداني';
      case SmartExplorerOutcomeCategory.governance:
        return 'الحوكمة والاعتماد';
      case SmartExplorerOutcomeCategory.aiRoadmap:
        return 'خارطة الذكاء اللاحقة';
    }
  }
}

class SmartExplorerExpectedOutcomeItem {
  const SmartExplorerExpectedOutcomeItem({
    required this.titleAr,
    required this.descriptionAr,
    required this.category,
    required this.horizonLabelAr,
    required this.indicatorAr,
    required this.evidenceSourceAr,
    required this.riskIfMissingAr,
  });

  final String titleAr;
  final String descriptionAr;
  final SmartExplorerOutcomeCategory category;
  final String horizonLabelAr;
  final String indicatorAr;
  final String evidenceSourceAr;
  final String riskIfMissingAr;
}
