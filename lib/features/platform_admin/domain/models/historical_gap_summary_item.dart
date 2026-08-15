class HistoricalGapSummaryItem {
  final String finalGapReason;
  final int rowsCount;

  const HistoricalGapSummaryItem({
    required this.finalGapReason,
    required this.rowsCount,
  });

  factory HistoricalGapSummaryItem.fromJson(Map<String, dynamic> json) {
    final rawCount = json['rows_count'];
    return HistoricalGapSummaryItem(
      finalGapReason: (json['final_gap_reason'] ?? '').toString(),
      rowsCount: rawCount is num
          ? rawCount.toInt()
          : int.tryParse('${rawCount ?? ''}') ?? 0,
    );
  }
}
