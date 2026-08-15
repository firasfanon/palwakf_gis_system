/// Integrated operational stage pack for Smart Explorer.
///
/// This model is intentionally read-only. It prepares the Smart Explorer for
/// practical integration inside Mustakshif without writing to sovereign tables
/// and without replacing map/search/router files owned by the current explorer
/// baseline.
class SmartExplorerOperationalStagePack {
  const SmartExplorerOperationalStagePack({
    required this.generatedAt,
    required this.stageLabelAr,
    required this.scopeLabelAr,
    required this.summaryAr,
    required this.integrationTracks,
    required this.acceptanceGates,
    required this.cutoverSteps,
    required this.runtimeRules,
    required this.blockingNotes,
    required this.nextOperatorActions,
  });

  final DateTime generatedAt;
  final String stageLabelAr;
  final String scopeLabelAr;
  final String summaryAr;
  final List<SmartExplorerOperationalTrack> integrationTracks;
  final List<SmartExplorerAcceptanceGate> acceptanceGates;
  final List<String> cutoverSteps;
  final List<String> runtimeRules;
  final List<String> blockingNotes;
  final List<String> nextOperatorActions;

  int get blockingGateCount =>
      acceptanceGates.where((gate) => gate.level == SmartExplorerAcceptanceLevel.blocking).length;

  int get warningGateCount =>
      acceptanceGates.where((gate) => gate.level == SmartExplorerAcceptanceLevel.warning).length;

  int get passedGateCount =>
      acceptanceGates.where((gate) => gate.level == SmartExplorerAcceptanceLevel.pass).length;

  String get decisionLabelAr {
    if (blockingGateCount > 0) return 'غير جاهز للتشغيل الكامل';
    if (warningGateCount > 0) return 'جاهز للتشغيل المقيد مع مراجعة';
    return 'جاهز للتشغيل read-only داخل المستكشف';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('مرحلة تشغيل متكاملة للمستكشف الذكي')
      ..writeln('المرحلة: $stageLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('القرار: $decisionLabelAr')
      ..writeln('الملخص: $summaryAr')
      ..writeln('---')
      ..writeln('1) مسارات الاندماج التشغيلي');

    for (final track in integrationTracks) {
      buffer
        ..writeln('- ${track.titleAr}')
        ..writeln('  الحالة: ${track.statusLabelAr}')
        ..writeln('  الهدف: ${track.goalAr}')
        ..writeln('  الاعتماد: ${track.ownerBoundaryAr}')
        ..writeln('  المخرجات: ${track.outputs.join('، ')}');
    }

    buffer
      ..writeln('---')
      ..writeln('2) بوابات القبول');
    for (final gate in acceptanceGates) {
      buffer
        ..writeln('- [${gate.level.labelAr}] ${gate.titleAr}')
        ..writeln('  المعيار: ${gate.measureAr}')
        ..writeln('  الدليل: ${gate.evidenceAr}')
        ..writeln('  الإجراء التالي: ${gate.nextActionAr}');
    }

    buffer
      ..writeln('---')
      ..writeln('3) خطوات cutover المقيد');
    for (var index = 0; index < cutoverSteps.length; index++) {
      buffer.writeln('${index + 1}. ${cutoverSteps[index]}');
    }

    buffer
      ..writeln('---')
      ..writeln('4) قواعد التشغيل');
    for (final rule in runtimeRules) {
      buffer.writeln('- $rule');
    }

    buffer
      ..writeln('---')
      ..writeln('5) الموانع والملاحظات');
    for (final note in blockingNotes) {
      buffer.writeln('- $note');
    }

    buffer
      ..writeln('---')
      ..writeln('6) إجراءات المشغل التالية');
    for (final action in nextOperatorActions) {
      buffer.writeln('- $action');
    }

    return buffer.toString();
  }

  String toChecklistText() {
    final buffer = StringBuffer()
      ..writeln('Checklist قبول تشغيل المستكشف الذكي')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('---');
    for (final gate in acceptanceGates) {
      buffer.writeln('[ ] ${gate.titleAr} — ${gate.level.labelAr}');
    }
    buffer.writeln('---');
    for (final step in cutoverSteps) {
      buffer.writeln('[ ] $step');
    }
    return buffer.toString();
  }
}

class SmartExplorerOperationalTrack {
  const SmartExplorerOperationalTrack({
    required this.titleAr,
    required this.goalAr,
    required this.statusLabelAr,
    required this.ownerBoundaryAr,
    required this.outputs,
  });

  final String titleAr;
  final String goalAr;
  final String statusLabelAr;
  final String ownerBoundaryAr;
  final List<String> outputs;
}

class SmartExplorerAcceptanceGate {
  const SmartExplorerAcceptanceGate({
    required this.titleAr,
    required this.level,
    required this.measureAr,
    required this.evidenceAr,
    required this.nextActionAr,
  });

  final String titleAr;
  final SmartExplorerAcceptanceLevel level;
  final String measureAr;
  final String evidenceAr;
  final String nextActionAr;
}

enum SmartExplorerAcceptanceLevel {
  pass,
  warning,
  blocking,
}

extension SmartExplorerAcceptanceLevelLabel on SmartExplorerAcceptanceLevel {
  String get labelAr {
    switch (this) {
      case SmartExplorerAcceptanceLevel.pass:
        return 'مغلق';
      case SmartExplorerAcceptanceLevel.warning:
        return 'تنبيه';
      case SmartExplorerAcceptanceLevel.blocking:
        return 'مانع';
    }
  }
}

class SmartExplorerUserGuidePack {
  const SmartExplorerUserGuidePack({
    required this.generatedAt,
    required this.titleAr,
    required this.audienceAr,
    required this.quickStartSteps,
    required this.workflows,
    required this.roles,
    required this.safetyRules,
    required this.troubleshooting,
    required this.trainingExercises,
  });

  final DateTime generatedAt;
  final String titleAr;
  final String audienceAr;
  final List<String> quickStartSteps;
  final List<SmartExplorerUserWorkflow> workflows;
  final List<SmartExplorerUserRoleGuide> roles;
  final List<String> safetyRules;
  final List<SmartExplorerTroubleshootingItem> troubleshooting;
  final List<String> trainingExercises;

  String toGuideText() {
    final buffer = StringBuffer()
      ..writeln('# $titleAr')
      ..writeln()
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الجمهور المستهدف: $audienceAr')
      ..writeln()
      ..writeln('## 1. البدء السريع');
    for (var index = 0; index < quickStartSteps.length; index++) {
      buffer.writeln('${index + 1}. ${quickStartSteps[index]}');
    }

    buffer.writeln();
    buffer.writeln('## 2. مسارات العمل');
    for (final workflow in workflows) {
      buffer
        ..writeln('### ${workflow.titleAr}')
        ..writeln('الهدف: ${workflow.goalAr}')
        ..writeln('المدخلات: ${workflow.inputs.join('، ')}')
        ..writeln('المخرجات: ${workflow.outputs.join('، ')}')
        ..writeln('خطوات العمل:');
      for (var index = 0; index < workflow.steps.length; index++) {
        buffer.writeln('${index + 1}. ${workflow.steps[index]}');
      }
      buffer.writeln();
    }

    buffer.writeln('## 3. أدوار المستخدمين');
    for (final role in roles) {
      buffer
        ..writeln('- ${role.roleAr}: ${role.descriptionAr}')
        ..writeln('  الصلاحيات المقترحة: ${role.allowedActions.join('، ')}')
        ..writeln('  الممنوع: ${role.forbiddenActions.join('، ')}');
    }

    buffer.writeln();
    buffer.writeln('## 4. قواعد السلامة التشغيلية');
    for (final rule in safetyRules) {
      buffer.writeln('- $rule');
    }

    buffer.writeln();
    buffer.writeln('## 5. معالجة المشاكل المتكررة');
    for (final item in troubleshooting) {
      buffer
        ..writeln('### ${item.symptomAr}')
        ..writeln('- السبب المحتمل: ${item.causeAr}')
        ..writeln('- الحل: ${item.solutionAr}')
        ..writeln('- التصعيد: ${item.escalationAr}');
    }

    buffer.writeln();
    buffer.writeln('## 6. تمارين تدريب');
    for (final exercise in trainingExercises) {
      buffer.writeln('- $exercise');
    }

    return buffer.toString();
  }

  String toQuickStartText() {
    final buffer = StringBuffer()
      ..writeln('بطاقة البدء السريع — المستكشف الذكي')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('---');
    for (var index = 0; index < quickStartSteps.length; index++) {
      buffer.writeln('${index + 1}. ${quickStartSteps[index]}');
    }
    return buffer.toString();
  }
}

class SmartExplorerUserWorkflow {
  const SmartExplorerUserWorkflow({
    required this.titleAr,
    required this.goalAr,
    required this.inputs,
    required this.steps,
    required this.outputs,
  });

  final String titleAr;
  final String goalAr;
  final List<String> inputs;
  final List<String> steps;
  final List<String> outputs;
}

class SmartExplorerUserRoleGuide {
  const SmartExplorerUserRoleGuide({
    required this.roleAr,
    required this.descriptionAr,
    required this.allowedActions,
    required this.forbiddenActions,
  });

  final String roleAr;
  final String descriptionAr;
  final List<String> allowedActions;
  final List<String> forbiddenActions;
}

class SmartExplorerTroubleshootingItem {
  const SmartExplorerTroubleshootingItem({
    required this.symptomAr,
    required this.causeAr,
    required this.solutionAr,
    required this.escalationAr,
  });

  final String symptomAr;
  final String causeAr;
  final String solutionAr;
  final String escalationAr;
}
