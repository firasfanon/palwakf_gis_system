/// QA scenarios generated to test Smart Explorer conclusions before handoff.
class SmartExplorerQaScenario {
  const SmartExplorerQaScenario({
    required this.titleAr,
    required this.testSteps,
    required this.expectedEvidenceAr,
    required this.failureSignalAr,
    required this.priority,
    required this.domainAr,
  });

  final String titleAr;
  final List<String> testSteps;
  final String expectedEvidenceAr;
  final String failureSignalAr;
  final int priority;
  final String domainAr;

  String get priorityLabelAr {
    if (priority >= 85) return 'عاجل';
    if (priority >= 70) return 'عالٍ';
    if (priority >= 45) return 'متوسط';
    return 'منخفض';
  }
}
