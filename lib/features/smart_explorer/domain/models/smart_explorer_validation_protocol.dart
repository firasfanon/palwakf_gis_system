/// Human validation protocol for Smart Explorer outputs.
///
/// The protocol models gates that must be checked before using any smart output
/// in reports, field work, or governance follow-up.
class SmartExplorerValidationProtocol {
  const SmartExplorerValidationProtocol({
    required this.gates,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerValidationGate> gates;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => gates.isEmpty;
  int get totalGates => gates.length;
  int get blockingGates => gates.where((item) => item.isBlocking).length;
  int get passedGates => gates.where((item) => item.status == SmartExplorerValidationStatus.pass).length;

  String get summaryAr {
    if (gates.isEmpty) return 'لا توجد بوابات تحقق ضمن النطاق الحالي.';
    return 'بروتوكول تحقق يضم $totalGates بوابات، منها $blockingGates مانعة قبل الاعتماد.';
  }
}

enum SmartExplorerValidationStatus { pass, warning, blocked, pending }

extension SmartExplorerValidationStatusX on SmartExplorerValidationStatus {
  String get labelAr {
    switch (this) {
      case SmartExplorerValidationStatus.pass:
        return 'مقبول مبدئيًا';
      case SmartExplorerValidationStatus.warning:
        return 'تحذير';
      case SmartExplorerValidationStatus.blocked:
        return 'مانع';
      case SmartExplorerValidationStatus.pending:
        return 'بانتظار المراجعة';
    }
  }
}

class SmartExplorerValidationGate {
  const SmartExplorerValidationGate({
    required this.titleAr,
    required this.descriptionAr,
    required this.status,
    required this.requiredEvidenceAr,
    required this.nextActionAr,
    required this.domainAr,
    this.isBlocking = false,
  });

  final String titleAr;
  final String descriptionAr;
  final SmartExplorerValidationStatus status;
  final String requiredEvidenceAr;
  final String nextActionAr;
  final String domainAr;
  final bool isBlocking;
}
