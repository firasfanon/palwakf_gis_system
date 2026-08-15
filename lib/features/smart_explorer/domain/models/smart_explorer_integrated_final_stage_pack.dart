/// Integrated Q→Z final stage pack for Smart Explorer.
///
/// This model is intentionally deterministic and read-only. It captures the
/// operational closure path from Review Board timeline hardening through pilot,
/// production cutover preparation, and final governance closure without touching
/// map, search, router, activeLayers, or sovereign data sources.
class SmartExplorerIntegratedFinalStagePack {
  const SmartExplorerIntegratedFinalStagePack({
    required this.generatedAt,
    required this.stageLabelAr,
    required this.scopeLabelAr,
    required this.decisionLabelAr,
    required this.summaryAr,
    required this.stageSegments,
    required this.acceptanceGates,
    required this.artifacts,
    required this.runtimeRules,
    required this.cutoverRunbook,
    required this.errorRecords,
    required this.finalNextActions,
  });

  final DateTime generatedAt;
  final String stageLabelAr;
  final String scopeLabelAr;
  final String decisionLabelAr;
  final String summaryAr;
  final List<SmartExplorerIntegratedStageSegment> stageSegments;
  final List<SmartExplorerIntegratedAcceptanceGate> acceptanceGates;
  final List<SmartExplorerIntegratedArtifact> artifacts;
  final List<String> runtimeRules;
  final List<String> cutoverRunbook;
  final List<SmartExplorerIntegratedErrorRecord> errorRecords;
  final List<String> finalNextActions;

  int get blockingGates => acceptanceGates.where((gate) => gate.isBlocking).length;

  int get warningGates => acceptanceGates
      .where((gate) => gate.level == SmartExplorerIntegratedStageLevel.warning)
      .length;

  int get closedStages => stageSegments.where((stage) => stage.isClosed).length;

  int get openStages => stageSegments.length - closedStages;

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln(stageLabelAr)
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('قرار المرحلة: $decisionLabelAr')
      ..writeln('الملخص: $summaryAr')
      ..writeln('المراحل المغلقة: $closedStages / ${stageSegments.length}')
      ..writeln('بوابات مانعة: $blockingGates، بوابات تنبيه: $warningGates')
      ..writeln('---')
      ..writeln('1) مراحل Q→Z المدمجة');

    for (final stage in stageSegments) {
      buffer
        ..writeln('- ${stage.code}: ${stage.titleAr}')
        ..writeln('  الهدف: ${stage.goalAr}')
        ..writeln('  الحالة: ${stage.statusAr}')
        ..writeln('  مغلقة؟ ${stage.isClosed ? 'نعم' : 'لا'}')
        ..writeln('  الدليل: ${stage.evidenceAr}')
        ..writeln('  المخرجات: ${stage.outputs.join('، ')}')
        ..writeln('  إجراء القبول: ${stage.acceptanceActionAr}');
    }

    buffer
      ..writeln('---')
      ..writeln('2) بوابات قبول التشغيل النهائي');
    for (final gate in acceptanceGates) {
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
      ..writeln('3) ملف المخرجات التشغيلية');
    for (final artifact in artifacts) {
      buffer
        ..writeln('- ${artifact.nameAr}')
        ..writeln('  النوع: ${artifact.typeAr}')
        ..writeln('  المالك: ${artifact.ownerAr}')
        ..writeln('  الحالة: ${artifact.statusAr}')
        ..writeln('  الاعتماد: ${artifact.acceptanceAr}');
    }

    buffer
      ..writeln('---')
      ..writeln('4) قواعد runtime الحاكمة')
      ..writeln(runtimeRules.map((item) => '- $item').join('\n'))
      ..writeln('---')
      ..writeln('5) Runbook الانتقال المقيد')
      ..writeln(cutoverRunbook.map((item) => '- $item').join('\n'))
      ..writeln('---')
      ..writeln('6) Error Records احترازية');
    for (final record in errorRecords) {
      buffer
        ..writeln('- ${record.code}: ${record.titleAr}')
        ..writeln('  السبب: ${record.reasonAr}')
        ..writeln('  الملفات/النطاق: ${record.files.join('، ')}')
        ..writeln('  ما يفشل: ${record.failureAr}')
        ..writeln('  الحل: ${record.resolutionAr}')
        ..writeln('  آخر baseline مستقر: ${record.lastStableBaselineAr}');
    }

    buffer
      ..writeln('---')
      ..writeln('7) إجراءات ما بعد هذه المرحلة')
      ..writeln(finalNextActions.map((item) => '- $item').join('\n'));

    return buffer.toString();
  }

  String toCsv() {
    final rows = <List<String>>[
      <String>['section', 'code_or_title', 'level_or_status', 'blocking_or_closed', 'evidence', 'next_action'],
    ];

    for (final stage in stageSegments) {
      rows.add(<String>[
        'stage',
        '${stage.code} - ${stage.titleAr}',
        stage.statusAr,
        stage.isClosed ? 'closed' : 'open',
        stage.evidenceAr,
        stage.acceptanceActionAr,
      ]);
    }
    for (final gate in acceptanceGates) {
      rows.add(<String>[
        'acceptance_gate',
        gate.titleAr,
        gate.level.labelAr,
        gate.isBlocking ? 'blocking' : 'non_blocking',
        gate.evidenceAr,
        gate.nextActionAr,
      ]);
    }
    for (final artifact in artifacts) {
      rows.add(<String>[
        'artifact',
        artifact.nameAr,
        artifact.statusAr,
        artifact.typeAr,
        artifact.ownerAr,
        artifact.acceptanceAr,
      ]);
    }

    return rows.map((row) => row.map(_csv).join(',')).join('\n');
  }

  String toUserGuideText() {
    final buffer = StringBuffer()
      ..writeln('# دليل استخدام المستكشف الذكي — المرحلة النهائية Q→Z')
      ..writeln('')
      ..writeln('## الغرض')
      ..writeln(summaryAr)
      ..writeln('')
      ..writeln('## كيف يستخدم المشغل المرحلة النهائية؟')
      ..writeln('1. افتح `/admin/smart-explorer` داخل baseline المستكشف الحالي.')
      ..writeln('2. نفذ بحثًا واقعيًا أو تحليل وثيقة حسب السيناريو المطلوب.')
      ..writeln('3. ولّد: ربط runtime، إغلاق analyzer، ثم المرحلة النهائية Q→Z.')
      ..writeln('4. راجع بوابات القبول. وجود مانع يعني منع cutover أو pilot الواسع.')
      ..writeln('5. صدّر CSV المرحلة النهائية لحفظ سجل تشغيلي قابل للمراجعة.')
      ..writeln('')
      ..writeln('## تفسير الحالات')
      ..writeln('- مغلق: لا توجد عوائق مباشرة ضمن حدود المستكشف الذكي.')
      ..writeln('- تنبيه: يعمل كنطاق تجريبي أو UAT، لكن يحتاج تدقيقًا قبل الإنتاج.')
      ..writeln('- مانع: يمنع الاعتماد أو cutover حتى الإغلاق.')
      ..writeln('')
      ..writeln('## المراحل المتاحة في هذه الحزمة');
    for (final stage in stageSegments) {
      buffer
        ..writeln('- ${stage.code}: ${stage.titleAr} — ${stage.statusAr}')
        ..writeln('  - ${stage.acceptanceActionAr}');
    }
    buffer
      ..writeln('')
      ..writeln('## حدود الاستخدام')
      ..writeln(runtimeRules.map((item) => '- $item').join('\n'));
    return buffer.toString();
  }

  String toOperationsManualText() {
    final buffer = StringBuffer()
      ..writeln('# دليل تشغيل المستكشف الذكي — Q→Z')
      ..writeln('')
      ..writeln('## قرار المرحلة')
      ..writeln(decisionLabelAr)
      ..writeln('')
      ..writeln('## Runbook الانتقال')
      ..writeln(cutoverRunbook.asMap().entries.map((entry) => '${entry.key + 1}. ${entry.value}').join('\n'))
      ..writeln('')
      ..writeln('## Error Records')
      ..writeln(errorRecords.map((record) => '- ${record.code}: ${record.titleAr} — ${record.resolutionAr}').join('\n'))
      ..writeln('')
      ..writeln('## إجراءات ما بعد الاعتماد')
      ..writeln(finalNextActions.map((item) => '- $item').join('\n'));
    return buffer.toString();
  }

  static String _csv(Object? value) {
    final text = (value ?? '').toString().replaceAll('"', '""');
    return '"$text"';
  }
}

class SmartExplorerIntegratedStageSegment {
  const SmartExplorerIntegratedStageSegment({
    required this.code,
    required this.titleAr,
    required this.goalAr,
    required this.statusAr,
    required this.isClosed,
    required this.evidenceAr,
    required this.outputs,
    required this.acceptanceActionAr,
  });

  final String code;
  final String titleAr;
  final String goalAr;
  final String statusAr;
  final bool isClosed;
  final String evidenceAr;
  final List<String> outputs;
  final String acceptanceActionAr;
}

class SmartExplorerIntegratedAcceptanceGate {
  const SmartExplorerIntegratedAcceptanceGate({
    required this.titleAr,
    required this.level,
    required this.isBlocking,
    required this.measureAr,
    required this.evidenceAr,
    required this.nextActionAr,
  });

  final String titleAr;
  final SmartExplorerIntegratedStageLevel level;
  final bool isBlocking;
  final String measureAr;
  final String evidenceAr;
  final String nextActionAr;
}

class SmartExplorerIntegratedArtifact {
  const SmartExplorerIntegratedArtifact({
    required this.nameAr,
    required this.typeAr,
    required this.ownerAr,
    required this.statusAr,
    required this.acceptanceAr,
  });

  final String nameAr;
  final String typeAr;
  final String ownerAr;
  final String statusAr;
  final String acceptanceAr;
}

class SmartExplorerIntegratedErrorRecord {
  const SmartExplorerIntegratedErrorRecord({
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

enum SmartExplorerIntegratedStageLevel {
  pass,
  warning,
  blocking,
}

extension SmartExplorerIntegratedStageLevelLabel on SmartExplorerIntegratedStageLevel {
  String get labelAr {
    switch (this) {
      case SmartExplorerIntegratedStageLevel.pass:
        return 'مغلق';
      case SmartExplorerIntegratedStageLevel.warning:
        return 'تنبيه';
      case SmartExplorerIntegratedStageLevel.blocking:
        return 'مانع';
    }
  }
}
