/// Local analyzer contract for Smart Explorer.
///
/// The contract defines what must be collected from the current workspace before
/// a local analyzer, reviewer, or later SQL/RPC integration can consume the
/// Smart Explorer output safely.
class SmartExplorerLocalAnalyzerContract {
  const SmartExplorerLocalAnalyzerContract({
    required this.generatedAt,
    required this.scopeLabelAr,
    required this.contractItems,
    required this.rejectedInputs,
    required this.routingRules,
    required this.productionCutoverBlocks,
  });

  final DateTime generatedAt;
  final String scopeLabelAr;
  final List<SmartExplorerLocalAnalyzerContractItem> contractItems;
  final List<String> rejectedInputs;
  final List<String> routingRules;
  final List<String> productionCutoverBlocks;

  bool get isEmpty =>
      contractItems.isEmpty &&
      rejectedInputs.isEmpty &&
      routingRules.isEmpty &&
      productionCutoverBlocks.isEmpty;

  int get requiredCount => contractItems.where((item) => item.isRequired).length;
  int get blockingCount =>
      contractItems.where((item) => item.isBlockingWhenMissing).length +
      productionCutoverBlocks.length;

  String get summaryAr {
    if (isEmpty) return 'لا توجد بنود عقد محلل محلي.';
    return 'عقد محلل محلي يضم $requiredCount بنود إلزامية و$blockingCount موانع إنتاجية.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('عقد المحلل المحلي للمستكشف الذكي')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('تنبيه: العقد read-only ولا يكتب في waqf_assets أو core أو awqaf_system.')
      ..writeln('---')
      ..writeln('مدخلات العقد:');
    for (final item in contractItems) {
      buffer
        ..writeln('- ${item.nameAr}')
        ..writeln('  مطلوب؟ ${item.isRequired ? 'نعم' : 'لا'}')
        ..writeln('  مانع عند الغياب؟ ${item.isBlockingWhenMissing ? 'نعم' : 'لا'}')
        ..writeln('  الصيغة: ${item.formatAr}')
        ..writeln('  المصدر: ${item.sourceAr}')
        ..writeln('  الملاحظة: ${item.noteAr}');
    }
    buffer
      ..writeln('---')
      ..writeln('مدخلات مرفوضة:');
    for (final item in rejectedInputs) {
      buffer.writeln('- $item');
    }
    buffer
      ..writeln('---')
      ..writeln('قواعد التوجيه:');
    for (final item in routingRules) {
      buffer.writeln('- $item');
    }
    buffer
      ..writeln('---')
      ..writeln('موانع cutover للإنتاج:');
    for (final item in productionCutoverBlocks) {
      buffer.writeln('- $item');
    }
    return buffer.toString();
  }
}

class SmartExplorerLocalAnalyzerContractItem {
  const SmartExplorerLocalAnalyzerContractItem({
    required this.nameAr,
    required this.formatAr,
    required this.sourceAr,
    required this.noteAr,
    required this.isRequired,
    required this.isBlockingWhenMissing,
  });

  final String nameAr;
  final String formatAr;
  final String sourceAr;
  final String noteAr;
  final bool isRequired;
  final bool isBlockingWhenMissing;
}
