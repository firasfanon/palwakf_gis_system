/// Current-baseline protection model for Smart Explorer overlays.
///
/// The guard is intentionally read-only. It describes which files must not be
/// overwritten when the user's active platform baseline is newer than the
/// development pack used to prepare a Smart Explorer patch.
enum SmartExplorerBaselineGuardStatus {
  safe,
  review,
  blocked,
}

extension SmartExplorerBaselineGuardStatusLabel on SmartExplorerBaselineGuardStatus {
  String get labelAr {
    switch (this) {
      case SmartExplorerBaselineGuardStatus.safe:
        return 'آمن';
      case SmartExplorerBaselineGuardStatus.review:
        return 'يتطلب مراجعة';
      case SmartExplorerBaselineGuardStatus.blocked:
        return 'ممنوع الاستبدال';
    }
  }

  String get code {
    switch (this) {
      case SmartExplorerBaselineGuardStatus.safe:
        return 'safe';
      case SmartExplorerBaselineGuardStatus.review:
        return 'review';
      case SmartExplorerBaselineGuardStatus.blocked:
        return 'blocked';
    }
  }
}

class SmartExplorerBaselineGuardItem {
  const SmartExplorerBaselineGuardItem({
    required this.titleAr,
    required this.pathPattern,
    required this.status,
    required this.reasonAr,
    required this.decisionAr,
    required this.nextActionAr,
  });

  final String titleAr;
  final String pathPattern;
  final SmartExplorerBaselineGuardStatus status;
  final String reasonAr;
  final String decisionAr;
  final String nextActionAr;

  bool get isBlocked => status == SmartExplorerBaselineGuardStatus.blocked;
  bool get needsReview => status == SmartExplorerBaselineGuardStatus.review;

  String toReportLine() {
    return '- ${status.labelAr} | $titleAr | $pathPattern | القرار: $decisionAr | التالي: $nextActionAr';
  }

  String toCsvLine() {
    return [
      status.code,
      titleAr,
      pathPattern,
      reasonAr,
      decisionAr,
      nextActionAr,
    ].map(_csv).join(',');
  }

  static String _csv(Object? value) {
    final text = (value ?? '').toString().replaceAll('"', '""');
    return '"$text"';
  }
}

class SmartExplorerCurrentBaselineGuard {
  const SmartExplorerCurrentBaselineGuard({
    required this.generatedAt,
    required this.scopeLabelAr,
    required this.items,
    required this.overlayFiles,
    required this.nonOverwriteFiles,
    required this.integrationStepsAr,
    required this.recommendationAr,
  });

  final DateTime generatedAt;
  final String scopeLabelAr;
  final List<SmartExplorerBaselineGuardItem> items;
  final List<String> overlayFiles;
  final List<String> nonOverwriteFiles;
  final List<String> integrationStepsAr;
  final String recommendationAr;

  bool get isEmpty => items.isEmpty && overlayFiles.isEmpty;
  int get blockedCount => items.where((item) => item.isBlocked).length;
  int get reviewCount => items.where((item) => item.needsReview).length;
  bool get canApplyOverlay => blockedCount == 0 || overlayFiles.isNotEmpty;

  String get summaryAr {
    return 'حارس baseline: $blockedCount ملفات/مسارات ممنوعة من الاستبدال، $reviewCount بنود تحتاج مراجعة، ${overlayFiles.length} ملفات overlay مسموحة.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('حارس baseline الحالي للمستكشف الذكي')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('الملخص: $summaryAr')
      ..writeln('التوصية: $recommendationAr')
      ..writeln('---')
      ..writeln('المسارات المحمية من الاستبدال:');

    for (final file in nonOverwriteFiles) {
      buffer.writeln('- $file');
    }

    buffer
      ..writeln('---')
      ..writeln('ملفات overlay المسموحة:');
    for (final file in overlayFiles) {
      buffer.writeln('- $file');
    }

    buffer
      ..writeln('---')
      ..writeln('قرارات الحارس:');
    for (final item in items) {
      buffer.writeln(item.toReportLine());
      buffer.writeln('  السبب: ${item.reasonAr}');
    }

    buffer
      ..writeln('---')
      ..writeln('خطوات الدمج الآمن:');
    for (var i = 0; i < integrationStepsAr.length; i++) {
      buffer.writeln('${i + 1}. ${integrationStepsAr[i]}');
    }

    buffer
      ..writeln('---')
      ..writeln('قاعدة حاكمة: لا يكتب المستكشف الذكي في waqf_assets أو awqaf_system أو core. مخرجاته مراجعة/تحليل فقط، والتحويل التشغيلي يتم عبر طلبات التدقيق المعتمدة.');
    return buffer.toString();
  }

  String toCsv() {
    final buffer = StringBuffer()
      ..writeln('status,title,path_pattern,reason,decision,next_action');
    for (final item in items) {
      buffer.writeln(item.toCsvLine());
    }
    return buffer.toString();
  }
}
