/// Post-QZ operational closure pack for Smart Explorer.
///
/// This model closes the remaining Smart Explorer work as an integration-ready
/// package for the original Explorer. It is read-only, deterministic, and does
/// not control map layers, router, search boxes, activeLayers, or sovereign data.
class SmartExplorerPostQzOperationalClosurePack {
  const SmartExplorerPostQzOperationalClosurePack({
    required this.generatedAt,
    required this.stageLabelAr,
    required this.decisionLabelAr,
    required this.summaryAr,
    required this.integrationRules,
    required this.closureGates,
    required this.testScenarios,
    required this.explorerInstructions,
    required this.errorRecords,
    required this.finalArtifacts,
    required this.acceptanceDecisionAr,
  });

  final DateTime generatedAt;
  final String stageLabelAr;
  final String decisionLabelAr;
  final String summaryAr;
  final List<String> integrationRules;
  final List<SmartExplorerPostQzClosureGate> closureGates;
  final List<SmartExplorerPostQzTestScenario> testScenarios;
  final List<String> explorerInstructions;
  final List<SmartExplorerPostQzErrorRecord> errorRecords;
  final List<SmartExplorerPostQzArtifact> finalArtifacts;
  final String acceptanceDecisionAr;

  int get blockingGates => closureGates.where((gate) => gate.isBlocking).length;

  int get warningGates => closureGates.where((gate) => gate.level == SmartExplorerPostQzGateLevel.warning).length;

  int get passedGates => closureGates.where((gate) => gate.level == SmartExplorerPostQzGateLevel.pass).length;

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln(stageLabelAr)
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('قرار الإغلاق: $decisionLabelAr')
      ..writeln('قرار القبول: $acceptanceDecisionAr')
      ..writeln('الملخص: $summaryAr')
      ..writeln('البوابات الناجحة: $passedGates، التنبيهات: $warningGates، الموانع: $blockingGates')
      ..writeln('---')
      ..writeln('1) قواعد الاندماج النهائية');

    for (final rule in integrationRules) {
      buffer.writeln('- $rule');
    }

    buffer
      ..writeln('---')
      ..writeln('2) بوابات الإغلاق النهائي');
    for (final gate in closureGates) {
      buffer
        ..writeln('- ${gate.titleAr}')
        ..writeln('  المستوى: ${gate.level.labelAr}')
        ..writeln('  مانع؟ ${gate.isBlocking ? 'نعم' : 'لا'}')
        ..writeln('  القياس: ${gate.measureAr}')
        ..writeln('  الدليل: ${gate.evidenceAr}')
        ..writeln('  إجراء الإغلاق: ${gate.nextActionAr}');
    }

    buffer
      ..writeln('---')
      ..writeln('3) سيناريوهات الاختبار النهائية');
    for (final scenario in testScenarios) {
      buffer
        ..writeln('- ${scenario.code}: ${scenario.titleAr}')
        ..writeln('  الهدف: ${scenario.goalAr}')
        ..writeln('  الخطوات:')
        ..writeln(scenario.steps.map((step) => '    - $step').join('\n'))
        ..writeln('  نتيجة القبول: ${scenario.acceptanceAr}');
    }

    buffer
      ..writeln('---')
      ..writeln('4) تعليمات المستكشف الأصلي للدمج والاختبار')
      ..writeln(explorerInstructions.map((item) => '- $item').join('\n'))
      ..writeln('---')
      ..writeln('5) Error Records النهائية');
    for (final record in errorRecords) {
      buffer
        ..writeln('- ${record.code}: ${record.titleAr}')
        ..writeln('  السبب: ${record.reasonAr}')
        ..writeln('  النطاق: ${record.files.join('، ')}')
        ..writeln('  ما يفشل: ${record.failureAr}')
        ..writeln('  الحل: ${record.resolutionAr}')
        ..writeln('  آخر baseline مستقر: ${record.lastStableBaselineAr}');
    }

    buffer
      ..writeln('---')
      ..writeln('6) مخرجات الإغلاق')
      ..writeln(finalArtifacts.map((artifact) => '- ${artifact.nameAr}: ${artifact.statusAr} — ${artifact.pathHintAr}').join('\n'));

    return buffer.toString();
  }

  String toCsv() {
    final rows = <List<String>>[
      <String>['section', 'code_or_title', 'level_or_status', 'blocking', 'evidence', 'next_action'],
    ];

    for (final gate in closureGates) {
      rows.add(<String>[
        'closure_gate',
        gate.titleAr,
        gate.level.labelAr,
        gate.isBlocking ? 'blocking' : 'non_blocking',
        gate.evidenceAr,
        gate.nextActionAr,
      ]);
    }

    for (final scenario in testScenarios) {
      rows.add(<String>[
        'test_scenario',
        '${scenario.code} - ${scenario.titleAr}',
        'uat',
        'non_blocking',
        scenario.goalAr,
        scenario.acceptanceAr,
      ]);
    }

    for (final artifact in finalArtifacts) {
      rows.add(<String>[
        'artifact',
        artifact.nameAr,
        artifact.statusAr,
        artifact.ownerAr,
        artifact.pathHintAr,
        artifact.acceptanceAr,
      ]);
    }

    return rows.map((row) => row.map(_csv).join(',')).join('\n');
  }

  String toExplorerIntegrationInstructionsText() {
    final buffer = StringBuffer()
      ..writeln('# تعليمات دمج المستكشف الذكي بعد Q→Z')
      ..writeln('')
      ..writeln('## قرار الإغلاق')
      ..writeln(decisionLabelAr)
      ..writeln('')
      ..writeln('## قاعدة التطبيق')
      ..writeln('طبّق ملفات `lib/features/smart_explorer/**` والوثائق والتعليمات فقط فوق baseline المستكشف الأصلي الحالي.')
      ..writeln('')
      ..writeln('## ممنوعات الدمج')
      ..writeln('- لا تستبدل `lib/router.dart`.')
      ..writeln('- لا تستبدل `lib/features/map/**`.')
      ..writeln('- لا تغيّر `activeLayers`.')
      ..writeln('- لا تجعل صناديق البحث ترسم أو توقف أو تشغل الطبقات.')
      ..writeln('- لا تجعل المستكشف الذكي يكتب مباشرة في جداول سيادية.')
      ..writeln('')
      ..writeln('## خطوات الدمج')
      ..writeln(explorerInstructions.asMap().entries.map((entry) => '${entry.key + 1}. ${entry.value}').join('\n'))
      ..writeln('')
      ..writeln('## أوامر الاختبار المحلية')
      ..writeln('```bash')
      ..writeln('flutter analyze')
      ..writeln('flutter run -d chrome')
      ..writeln('```')
      ..writeln('')
      ..writeln('## سيناريوهات الاختبار')
      ..writeln(testScenarios.map((scenario) => '- ${scenario.code}: ${scenario.titleAr} — ${scenario.acceptanceAr}').join('\n'))
      ..writeln('')
      ..writeln('## نتيجة القبول النهائية')
      ..writeln(acceptanceDecisionAr);
    return buffer.toString();
  }

  String toFinalUserGuideAddendumText() {
    final buffer = StringBuffer()
      ..writeln('# ملحق دليل استخدام المستكشف الذكي — Post-QZ Closure')
      ..writeln('')
      ..writeln('## متى يستخدم هذا الملحق؟')
      ..writeln('بعد دمج مرحلة Q→Z داخل المستكشف الأصلي وتشغيل `/admin/smart-explorer`.')
      ..writeln('')
      ..writeln('## سير العمل النهائي للمشغل')
      ..writeln('1. افتح صفحة المستكشف الذكي.')
      ..writeln('2. نفذ بحثًا واقعيًا أو تحليل وثيقة.')
      ..writeln('3. ولّد تقرير Q→Z، ثم تقرير الإغلاق النهائي Post-QZ.')
      ..writeln('4. راجع البوابات. إذا ظهر مانع، لا تعتمد التشغيل.')
      ..writeln('5. صدّر CSV واحفظه مع سجل UAT.')
      ..writeln('')
      ..writeln('## ماذا يعني الإغلاق؟')
      ..writeln('الإغلاق يعني أن أعمال المستكشف الذكي أصبحت مكتملة داخل نطاقه، وأن أي عمل لاحق يعتمد على نتائج `flutter analyze` وUAT في المستكشف الأصلي، لا على تطوير تأسيسي جديد داخل المستكشف الذكي.')
      ..writeln('')
      ..writeln('## قواعد ثابتة')
      ..writeln(integrationRules.map((rule) => '- $rule').join('\n'));
    return buffer.toString();
  }

  static String _csv(Object? value) {
    final text = (value ?? '').toString().replaceAll('"', '""');
    return '"$text"';
  }
}

class SmartExplorerPostQzClosureGate {
  const SmartExplorerPostQzClosureGate({
    required this.titleAr,
    required this.level,
    required this.isBlocking,
    required this.measureAr,
    required this.evidenceAr,
    required this.nextActionAr,
  });

  final String titleAr;
  final SmartExplorerPostQzGateLevel level;
  final bool isBlocking;
  final String measureAr;
  final String evidenceAr;
  final String nextActionAr;
}

class SmartExplorerPostQzTestScenario {
  const SmartExplorerPostQzTestScenario({
    required this.code,
    required this.titleAr,
    required this.goalAr,
    required this.steps,
    required this.acceptanceAr,
  });

  final String code;
  final String titleAr;
  final String goalAr;
  final List<String> steps;
  final String acceptanceAr;
}

class SmartExplorerPostQzErrorRecord {
  const SmartExplorerPostQzErrorRecord({
    required this.code,
    required this.titleAr,
    required this.reasonAr,
    required this.files,
    required this.failureAr,
    required this.resolutionAr,
    required this.lastStableBaselineAr,
  });

  final String code;
  final String titleAr;
  final String reasonAr;
  final List<String> files;
  final String failureAr;
  final String resolutionAr;
  final String lastStableBaselineAr;
}

class SmartExplorerPostQzArtifact {
  const SmartExplorerPostQzArtifact({
    required this.nameAr,
    required this.ownerAr,
    required this.statusAr,
    required this.pathHintAr,
    required this.acceptanceAr,
  });

  final String nameAr;
  final String ownerAr;
  final String statusAr;
  final String pathHintAr;
  final String acceptanceAr;
}

enum SmartExplorerPostQzGateLevel {
  pass,
  warning,
  blocking,
}

extension SmartExplorerPostQzGateLevelLabel on SmartExplorerPostQzGateLevel {
  String get labelAr {
    switch (this) {
      case SmartExplorerPostQzGateLevel.pass:
        return 'مغلق';
      case SmartExplorerPostQzGateLevel.warning:
        return 'تنبيه';
      case SmartExplorerPostQzGateLevel.blocking:
        return 'مانع';
    }
  }
}
