/// Autonomous QA and merge-readiness pack for Smart Explorer overlays.
///
/// This model is intentionally read-only. It turns the current Smart Explorer
/// workspace into review gates, merge checks, and naming controls without
/// changing map/router/search files or writing to sovereign platform tables.
class SmartExplorerAutonomousQaPack {
  const SmartExplorerAutonomousQaPack({
    required this.generatedAt,
    required this.scopeLabelAr,
    required this.summaryAr,
    required this.gates,
    required this.mergeControls,
    required this.namingControls,
    required this.localCommands,
    required this.blockingNotes,
    required this.nextBatchPlan,
  });

  final DateTime generatedAt;
  final String scopeLabelAr;
  final String summaryAr;
  final List<SmartExplorerAutonomousQaGate> gates;
  final List<String> mergeControls;
  final List<String> namingControls;
  final List<String> localCommands;
  final List<String> blockingNotes;
  final List<String> nextBatchPlan;

  bool get isEmpty =>
      gates.isEmpty &&
      mergeControls.isEmpty &&
      namingControls.isEmpty &&
      localCommands.isEmpty &&
      blockingNotes.isEmpty &&
      nextBatchPlan.isEmpty;

  int get blockingGates => gates.where((gate) => gate.isBlocking).length;
  int get warningGates => gates
      .where((gate) => gate.level == SmartExplorerAutonomousQaLevel.warning)
      .length;
  int get passedGates => gates
      .where((gate) => gate.level == SmartExplorerAutonomousQaLevel.pass)
      .length;

  String get readinessLabelAr {
    if (blockingGates > 0) return 'غير جاهز للدمج قبل إغلاق الموانع';
    if (warningGates > 0) return 'جاهز جزئيًا مع تنبيهات موثقة';
    if (gates.isEmpty) return 'غير مقيم';
    return 'جاهز كـ overlay للمستكشف الذكي فقط';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('حزمة QA ذاتي للمستكشف الذكي')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('قرار الجاهزية: $readinessLabelAr')
      ..writeln('تنبيه حاكم: هذه الحزمة baseline overlay للمستكشف الذكي فقط، وليست baseline للمستكشف الأصلي أو الخريطة.')
      ..writeln('---')
      ..writeln('بوابات QA:');

    if (gates.isEmpty) {
      buffer.writeln('- لا توجد بوابات QA مولدة.');
    } else {
      for (final gate in gates) {
        buffer
          ..writeln('- ${gate.titleAr}')
          ..writeln('  المستوى: ${gate.level.labelAr}')
          ..writeln('  مانع؟ ${gate.isBlocking ? 'نعم' : 'لا'}')
          ..writeln('  القياس: ${gate.measureAr}')
          ..writeln('  الدليل: ${gate.evidenceAr}')
          ..writeln('  الإجراء: ${gate.nextActionAr}');
      }
    }

    buffer
      ..writeln('---')
      ..writeln('ضوابط الدمج فوق baseline الحالي:');
    for (final item in mergeControls) {
      buffer.writeln('[ ] $item');
    }

    buffer
      ..writeln('---')
      ..writeln('ضوابط التسمية لمنع الخلط مع المستكشف الأصلي:');
    for (final item in namingControls) {
      buffer.writeln('[ ] $item');
    }

    buffer
      ..writeln('---')
      ..writeln('أوامر التحقق المحلي المقترحة:');
    for (final item in localCommands) {
      buffer.writeln('- $item');
    }

    buffer
      ..writeln('---')
      ..writeln('ملاحظات مانعة أو احترازية:');
    for (final item in blockingNotes) {
      buffer.writeln('- $item');
    }

    buffer
      ..writeln('---')
      ..writeln('خطة الدفعة التالية:');
    for (final item in nextBatchPlan) {
      buffer.writeln('- $item');
    }

    return buffer.toString();
  }

  String toCsvText() {
    final buffer = StringBuffer()
      ..writeln('type,title,level,is_blocking,measure,evidence,next_action');
    for (final gate in gates) {
      buffer.writeln([
        _csv('qa_gate'),
        _csv(gate.titleAr),
        _csv(gate.level.labelAr),
        _csv(gate.isBlocking ? 'yes' : 'no'),
        _csv(gate.measureAr),
        _csv(gate.evidenceAr),
        _csv(gate.nextActionAr),
      ].join(','));
    }
    for (final item in mergeControls) {
      buffer.writeln([
        _csv('merge_control'),
        _csv(item),
        _csv(''),
        _csv('no'),
        _csv('pending'),
        _csv('local verification'),
        _csv('تحقق محليًا بعد تطبيق baseline overlay.'),
      ].join(','));
    }
    for (final item in namingControls) {
      buffer.writeln([
        _csv('naming_control'),
        _csv(item),
        _csv(''),
        _csv('no'),
        _csv('pending'),
        _csv('artifact governance'),
        _csv('استخدم SMART_EXPLORER / المستكشف_الذكي في اسم الملف.'),
      ].join(','));
    }
    return buffer.toString();
  }

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}

class SmartExplorerAutonomousQaGate {
  const SmartExplorerAutonomousQaGate({
    required this.titleAr,
    required this.level,
    required this.isBlocking,
    required this.measureAr,
    required this.evidenceAr,
    required this.nextActionAr,
  });

  final String titleAr;
  final SmartExplorerAutonomousQaLevel level;
  final bool isBlocking;
  final String measureAr;
  final String evidenceAr;
  final String nextActionAr;
}

enum SmartExplorerAutonomousQaLevel {
  pass,
  warning,
  blocking,
}

extension SmartExplorerAutonomousQaLevelLabel on SmartExplorerAutonomousQaLevel {
  String get labelAr {
    switch (this) {
      case SmartExplorerAutonomousQaLevel.pass:
        return 'مغلق';
      case SmartExplorerAutonomousQaLevel.warning:
        return 'تنبيه';
      case SmartExplorerAutonomousQaLevel.blocking:
        return 'مانع';
    }
  }
}

class SmartExplorerNamedBaselineManifest {
  const SmartExplorerNamedBaselineManifest({
    required this.generatedAt,
    required this.batchLabelAr,
    required this.allowedOutputPrefixes,
    required this.forbiddenOutputLabels,
    required this.includedPathRules,
    required this.excludedPathRules,
    required this.releaseNotes,
  });

  final DateTime generatedAt;
  final String batchLabelAr;
  final List<String> allowedOutputPrefixes;
  final List<String> forbiddenOutputLabels;
  final List<String> includedPathRules;
  final List<String> excludedPathRules;
  final List<String> releaseNotes;

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('بيان تسمية baseline — المستكشف الذكي')
      ..writeln('الدفعة: $batchLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('---')
      ..writeln('بادئات أسماء مسموحة للمخرجات:');
    for (final item in allowedOutputPrefixes) {
      buffer.writeln('- $item');
    }
    buffer
      ..writeln('---')
      ..writeln('تسميات ممنوعة لتجنب الخلط:');
    for (final item in forbiddenOutputLabels) {
      buffer.writeln('- $item');
    }
    buffer
      ..writeln('---')
      ..writeln('مسارات مسموح تضمينها:');
    for (final item in includedPathRules) {
      buffer.writeln('- $item');
    }
    buffer
      ..writeln('---')
      ..writeln('مسارات مستبعدة إلزاميًا:');
    for (final item in excludedPathRules) {
      buffer.writeln('- $item');
    }
    buffer
      ..writeln('---')
      ..writeln('ملاحظات الإصدار:');
    for (final item in releaseNotes) {
      buffer.writeln('- $item');
    }
    return buffer.toString();
  }
}
