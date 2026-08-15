class HistoryLineageNode {
  final String id;
  final String label;
  final int? periodId;
  final String? periodLabel;
  final String? relationLabel;
  final String? originCommunityCode;
  final double? confidence;
  final bool isPrimary;

  const HistoryLineageNode({
    required this.id,
    required this.label,
    this.periodId,
    this.periodLabel,
    this.relationLabel,
    this.originCommunityCode,
    this.confidence,
    this.isPrimary = false,
  });
}
