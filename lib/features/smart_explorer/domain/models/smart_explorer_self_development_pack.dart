/// Self-development pack for Smart Explorer overlays.
///
/// This model is intentionally UI/export focused. It does not write to
/// sovereign data, does not depend on map/router internals, and is designed to
/// help the module continue safe development while the current explorer
/// baseline is prepared elsewhere.
class SmartExplorerSelfDevelopmentPack {
  const SmartExplorerSelfDevelopmentPack({
    required this.generatedAt,
    required this.scopeLabelAr,
    required this.summaryAr,
    required this.guardRails,
    required this.workItems,
    required this.acceptanceChecks,
    required this.errorRecords,
    required this.localAnalyzerInputs,
    required this.nextPatchPlan,
  });

  final DateTime generatedAt;
  final String scopeLabelAr;
  final String summaryAr;
  final List<String> guardRails;
  final List<SmartExplorerSelfDevelopmentItem> workItems;
  final List<String> acceptanceChecks;
  final List<String> errorRecords;
  final List<String> localAnalyzerInputs;
  final List<String> nextPatchPlan;

  bool get isEmpty =>
      guardRails.isEmpty &&
      workItems.isEmpty &&
      acceptanceChecks.isEmpty &&
      errorRecords.isEmpty &&
      localAnalyzerInputs.isEmpty &&
      nextPatchPlan.isEmpty;

  int get blockingItems => workItems.where((item) => item.isBlocking).length;
  int get highPriorityItems =>
      workItems.where((item) => item.priority == SmartExplorerSelfDevelopmentPriority.high).length;

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('حزمة التطوير الذاتي للمستكشف الذكي')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('تنبيه حاكم: هذه الحزمة لا تستبدل ملفات الخريطة أو البحث أو الراوتر.')
      ..writeln('---')
      ..writeln('قواعد الحماية:');

    for (final item in guardRails) {
      buffer.writeln('- $item');
    }

    buffer
      ..writeln('---')
      ..writeln('بنود التطوير المقترحة:');
    if (workItems.isEmpty) {
      buffer.writeln('- لا توجد بنود تطوير مولدة للنطاق الحالي.');
    } else {
      for (final item in workItems) {
        buffer
          ..writeln('- ${item.titleAr}')
          ..writeln('  الأولوية: ${item.priority.labelAr}')
          ..writeln('  الحالة: ${item.statusAr}')
          ..writeln('  مانع؟ ${item.isBlocking ? 'نعم' : 'لا'}')
          ..writeln('  السبب: ${item.reasonAr}')
          ..writeln('  الإجراء التالي: ${item.nextActionAr}');
      }
    }

    buffer
      ..writeln('---')
      ..writeln('مدخلات المحلل المحلي المطلوبة:');
    for (final item in localAnalyzerInputs) {
      buffer.writeln('[ ] $item');
    }

    buffer
      ..writeln('---')
      ..writeln('فحوص القبول قبل اعتماد overlay:');
    for (final item in acceptanceChecks) {
      buffer.writeln('[ ] $item');
    }

    buffer
      ..writeln('---')
      ..writeln('Error Record احترازي:');
    for (final item in errorRecords) {
      buffer.writeln('- $item');
    }

    buffer
      ..writeln('---')
      ..writeln('خطة الباتش التالي:');
    for (final item in nextPatchPlan) {
      buffer.writeln('- $item');
    }

    return buffer.toString();
  }

  String toCsvText() {
    final buffer = StringBuffer()
      ..writeln('type,title,priority,status,is_blocking,reason,next_action');
    for (final item in workItems) {
      buffer.writeln([
        _csv('work_item'),
        _csv(item.titleAr),
        _csv(item.priority.labelAr),
        _csv(item.statusAr),
        _csv(item.isBlocking ? 'yes' : 'no'),
        _csv(item.reasonAr),
        _csv(item.nextActionAr),
      ].join(','));
    }
    for (final item in acceptanceChecks) {
      buffer.writeln([
        _csv('acceptance_check'),
        _csv(item),
        _csv(''),
        _csv('pending'),
        _csv('no'),
        _csv(''),
        _csv('نفّذ الفحص محليًا بعد تطبيق overlay.'),
      ].join(','));
    }
    return buffer.toString();
  }

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}

class SmartExplorerSelfDevelopmentItem {
  const SmartExplorerSelfDevelopmentItem({
    required this.titleAr,
    required this.priority,
    required this.statusAr,
    required this.isBlocking,
    required this.reasonAr,
    required this.nextActionAr,
  });

  final String titleAr;
  final SmartExplorerSelfDevelopmentPriority priority;
  final String statusAr;
  final bool isBlocking;
  final String reasonAr;
  final String nextActionAr;
}

enum SmartExplorerSelfDevelopmentPriority {
  high,
  medium,
  low,
}

extension SmartExplorerSelfDevelopmentPriorityLabel
    on SmartExplorerSelfDevelopmentPriority {
  String get labelAr {
    switch (this) {
      case SmartExplorerSelfDevelopmentPriority.high:
        return 'عالية';
      case SmartExplorerSelfDevelopmentPriority.medium:
        return 'متوسطة';
      case SmartExplorerSelfDevelopmentPriority.low:
        return 'منخفضة';
    }
  }
}
