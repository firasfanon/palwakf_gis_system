/// Stakeholder matrix for routing Smart Explorer outputs to the right review
/// actors. It is a planning artifact only, not an authorization model.
class SmartExplorerStakeholderMatrix {
  const SmartExplorerStakeholderMatrix({
    required this.items,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerStakeholderItem> items;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => items.isEmpty;
  int get totalItems => items.length;
  int get approvalItems => items.where((item) => item.needsApproval).length;

  String get summaryAr {
    if (items.isEmpty) return 'لا توجد أدوار مراجعة محددة ضمن النطاق الحالي.';
    return 'مصفوفة أصحاب علاقة تضم $totalItems أدوار، منها $approvalItems تحتاج قرار اعتماد/إغلاق.';
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('مصفوفة أصحاب العلاقة للمستكشف الذكي')
      ..writeln('النطاق: $scopeLabelAr')
      ..writeln('وقت التوليد: ${generatedAt.toIso8601String()}')
      ..writeln('الملخص: $summaryAr')
      ..writeln('---');
    for (final item in items) {
      buffer
        ..writeln('${item.roleAr} — ${item.responsibilityAr}')
        ..writeln('المدخلات: ${item.inputNeededAr}')
        ..writeln('المخرجات: ${item.outputExpectedAr}')
        ..writeln('مرحلة التدخل: ${item.reviewStageAr}')
        ..writeln('اعتماد مطلوب: ${item.needsApproval ? 'نعم' : 'لا'}')
        ..writeln('---');
    }
    return buffer.toString();
  }
}

class SmartExplorerStakeholderItem {
  const SmartExplorerStakeholderItem({
    required this.roleAr,
    required this.responsibilityAr,
    required this.inputNeededAr,
    required this.outputExpectedAr,
    required this.reviewStageAr,
    this.needsApproval = false,
  });

  final String roleAr;
  final String responsibilityAr;
  final String inputNeededAr;
  final String outputExpectedAr;
  final String reviewStageAr;
  final bool needsApproval;
}
