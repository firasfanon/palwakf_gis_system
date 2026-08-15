/// Cross-system bridge plan for future integration with PalWakf systems.
///
/// The plan identifies handoff channels only. It does not invoke other systems
/// or write to their tables.
class SmartExplorerCrossSystemBridgePlan {
  const SmartExplorerCrossSystemBridgePlan({
    required this.items,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerCrossSystemBridgeItem> items;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => items.isEmpty;
  int get totalItems => items.length;
  int get blockedItems => items.where((item) => item.status == SmartExplorerBridgeStatus.blocked).length;
  int get readyItems => items.where((item) => item.status == SmartExplorerBridgeStatus.ready).length;

  String get summaryAr {
    if (items.isEmpty) return 'لا توجد قنوات تكامل كافية للنطاق الحالي.';
    return 'خطة تكامل تضم $totalItems قنوات، منها $readyItems جاهزة و$blockedItems مؤجلة/مانعة.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('خطة ربط المستكشف الذكي مع الأنظمة')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('تنبيه: هذه الخطة تصف التكامل ولا تنفذه تلقائيًا.')
      ..writeln('---');
    for (final item in items) {
      buffer
        ..writeln('${item.systemLabelAr} — ${item.status.labelAr}')
        ..writeln('القناة: ${item.bridgeChannelAr}')
        ..writeln('المدخل: ${item.inputAr}')
        ..writeln('المخرج المقترح: ${item.outputAr}')
        ..writeln('شرط التفعيل: ${item.activationConditionAr}')
        ..writeln('القيود: ${item.guardrailAr}')
        ..writeln('---');
    }
    return buffer.toString();
  }
}

enum SmartExplorerBridgeStatus { ready, pendingContract, blocked, later }

extension SmartExplorerBridgeStatusX on SmartExplorerBridgeStatus {
  String get labelAr {
    switch (this) {
      case SmartExplorerBridgeStatus.ready:
        return 'جاهز كمسار مراجعة';
      case SmartExplorerBridgeStatus.pendingContract:
        return 'بانتظار عقد تكامل';
      case SmartExplorerBridgeStatus.blocked:
        return 'مانع حاليًا';
      case SmartExplorerBridgeStatus.later:
        return 'لاحقًا';
    }
  }
}

class SmartExplorerCrossSystemBridgeItem {
  const SmartExplorerCrossSystemBridgeItem({
    required this.systemLabelAr,
    required this.bridgeChannelAr,
    required this.inputAr,
    required this.outputAr,
    required this.activationConditionAr,
    required this.guardrailAr,
    required this.status,
  });

  final String systemLabelAr;
  final String bridgeChannelAr;
  final String inputAr;
  final String outputAr;
  final String activationConditionAr;
  final String guardrailAr;
  final SmartExplorerBridgeStatus status;
}
