import 'smart_explorer_runtime_diagnostics.dart';

/// Integrated Stage P pack for actual runtime wiring readiness and analyzer closure.
///
/// The pack is intentionally read-only. It documents the wiring contract between
/// Smart Explorer outputs and the current explorer baseline without replacing map,
/// search, or router files.
class SmartExplorerRuntimeWiringStagePack {
  const SmartExplorerRuntimeWiringStagePack({
    required this.generatedAt,
    required this.stageLabelAr,
    required this.scopeLabelAr,
    required this.decisionLabelAr,
    required this.summaryAr,
    required this.runtimeTracks,
    required this.analyzerClosures,
    required this.acceptanceGates,
    required this.wiringBoundaries,
    required this.cutoverSteps,
    required this.errorRecords,
    required this.nextActions,
  });

  final DateTime generatedAt;
  final String stageLabelAr;
  final String scopeLabelAr;
  final String decisionLabelAr;
  final String summaryAr;
  final List<SmartExplorerRuntimeWiringTrack> runtimeTracks;
  final List<SmartExplorerAnalyzerClosureItem> analyzerClosures;
  final List<SmartExplorerRuntimeWiringGate> acceptanceGates;
  final List<String> wiringBoundaries;
  final List<String> cutoverSteps;
  final List<SmartExplorerRuntimeWiringErrorRecord> errorRecords;
  final List<String> nextActions;

  int get blockingGates => acceptanceGates.where((gate) => gate.isBlocking).length;
  int get warningGates => acceptanceGates
      .where((gate) => gate.level == SmartExplorerRuntimeWiringLevel.warning)
      .length;
  int get openAnalyzerItems => analyzerClosures.where((item) => !item.isClosed).length;

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln(stageLabelAr)
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('قرار المرحلة: $decisionLabelAr')
      ..writeln('الملخص: $summaryAr')
      ..writeln('---')
      ..writeln('1) مسارات ربط runtime');

    for (final track in runtimeTracks) {
      buffer
        ..writeln('- ${track.titleAr}')
        ..writeln('  المصدر: ${track.sourceAr}')
        ..writeln('  الهدف التشغيلي: ${track.targetAr}')
        ..writeln('  طريقة الربط: ${track.wiringModeAr}')
        ..writeln('  حالة القبول: ${track.statusAr}')
        ..writeln('  مانع الاعتماد: ${track.blockerAr}')
        ..writeln('  مخرجات: ${track.outputs.join('، ')}');
    }

    buffer
      ..writeln('---')
      ..writeln('2) إغلاق المحلل المحلي');
    for (final item in analyzerClosures) {
      buffer
        ..writeln('- ${item.titleAr}')
        ..writeln('  الحالة: ${item.statusAr}')
        ..writeln('  مغلق؟ ${item.isClosed ? 'نعم' : 'لا'}')
        ..writeln('  الدليل: ${item.evidenceAr}')
        ..writeln('  الإجراء التالي: ${item.nextActionAr}');
    }

    buffer
      ..writeln('---')
      ..writeln('3) بوابات قبول Stage P');
    for (final gate in acceptanceGates) {
      buffer
        ..writeln('- ${gate.titleAr}')
        ..writeln('  المستوى: ${gate.level.labelAr}')
        ..writeln('  مانع؟ ${gate.isBlocking ? 'نعم' : 'لا'}')
        ..writeln('  القياس: ${gate.measureAr}')
        ..writeln('  الدليل: ${gate.evidenceAr}')
        ..writeln('  الإجراء التالي: ${gate.nextActionAr}');
    }

    buffer
      ..writeln('---')
      ..writeln('4) حدود الربط')
      ..writeln(wiringBoundaries.map((item) => '- $item').join('\n'))
      ..writeln('---')
      ..writeln('5) خطوات cutover المقيد')
      ..writeln(cutoverSteps.map((item) => '- $item').join('\n'))
      ..writeln('---')
      ..writeln('6) Error Records احترازية');
    for (final record in errorRecords) {
      buffer
        ..writeln('- ${record.code}: ${record.titleAr}')
        ..writeln('  السبب: ${record.reasonAr}')
        ..writeln('  الملفات: ${record.files.join('، ')}')
        ..writeln('  ما يفشل: ${record.failureAr}')
        ..writeln('  الحل: ${record.resolutionAr}')
        ..writeln('  آخر baseline مستقر: ${record.lastStableBaselineAr}');
    }

    buffer
      ..writeln('---')
      ..writeln('7) إجراءات التشغيل التالية')
      ..writeln(nextActions.map((item) => '- $item').join('\n'));

    return buffer.toString();
  }

  String toAnalyzerClosureText() {
    final buffer = StringBuffer()
      ..writeln('إغلاق المحلل المحلي — المستكشف الذكي')
      ..writeln('المرحلة: $stageLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('العناصر المفتوحة: $openAnalyzerItems')
      ..writeln('---');

    for (final item in analyzerClosures) {
      buffer
        ..writeln('- ${item.titleAr}')
        ..writeln('  الحالة: ${item.statusAr}')
        ..writeln('  الدليل: ${item.evidenceAr}')
        ..writeln('  الإجراء التالي: ${item.nextActionAr}');
    }

    return buffer.toString();
  }

  String toCsv() {
    final rows = <List<String>>[
      <String>[
        'section',
        'title',
        'level_or_status',
        'blocking_or_closed',
        'evidence',
        'next_action',
      ],
    ];

    for (final track in runtimeTracks) {
      rows.add(<String>[
        'runtime_track',
        track.titleAr,
        track.statusAr,
        track.blockerAr,
        track.wiringModeAr,
        track.outputs.join(' | '),
      ]);
    }
    for (final item in analyzerClosures) {
      rows.add(<String>[
        'analyzer_closure',
        item.titleAr,
        item.statusAr,
        item.isClosed ? 'closed' : 'open',
        item.evidenceAr,
        item.nextActionAr,
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

    return rows
        .map((row) => row.map(_csv).join(','))
        .join('\n');
  }

  static String _csv(Object? value) {
    final text = (value ?? '').toString().replaceAll('"', '""');
    return '"$text"';
  }
}

class SmartExplorerRuntimeWiringTrack {
  const SmartExplorerRuntimeWiringTrack({
    required this.titleAr,
    required this.sourceAr,
    required this.targetAr,
    required this.wiringModeAr,
    required this.statusAr,
    required this.blockerAr,
    required this.outputs,
  });

  final String titleAr;
  final String sourceAr;
  final String targetAr;
  final String wiringModeAr;
  final String statusAr;
  final String blockerAr;
  final List<String> outputs;
}

class SmartExplorerAnalyzerClosureItem {
  const SmartExplorerAnalyzerClosureItem({
    required this.titleAr,
    required this.statusAr,
    required this.isClosed,
    required this.evidenceAr,
    required this.nextActionAr,
  });

  final String titleAr;
  final String statusAr;
  final bool isClosed;
  final String evidenceAr;
  final String nextActionAr;
}

class SmartExplorerRuntimeWiringGate {
  const SmartExplorerRuntimeWiringGate({
    required this.titleAr,
    required this.level,
    required this.isBlocking,
    required this.measureAr,
    required this.evidenceAr,
    required this.nextActionAr,
  });

  final String titleAr;
  final SmartExplorerRuntimeWiringLevel level;
  final bool isBlocking;
  final String measureAr;
  final String evidenceAr;
  final String nextActionAr;
}

class SmartExplorerRuntimeWiringErrorRecord {
  const SmartExplorerRuntimeWiringErrorRecord({
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

enum SmartExplorerRuntimeWiringLevel {
  pass,
  warning,
  blocking,
}

extension SmartExplorerRuntimeWiringLevelLabel on SmartExplorerRuntimeWiringLevel {
  String get labelAr {
    switch (this) {
      case SmartExplorerRuntimeWiringLevel.pass:
        return 'مغلق';
      case SmartExplorerRuntimeWiringLevel.warning:
        return 'تنبيه';
      case SmartExplorerRuntimeWiringLevel.blocking:
        return 'مانع';
    }
  }
}

SmartExplorerRuntimeWiringLevel smartExplorerRuntimeLevelFromDiagnostics(
  SmartExplorerRuntimeDiagnostics? diagnostics,
) {
  if (diagnostics == null) return SmartExplorerRuntimeWiringLevel.warning;
  if (diagnostics.blockingItems > 0) return SmartExplorerRuntimeWiringLevel.blocking;
  if (diagnostics.warningItems > 0) return SmartExplorerRuntimeWiringLevel.warning;
  return SmartExplorerRuntimeWiringLevel.pass;
}
