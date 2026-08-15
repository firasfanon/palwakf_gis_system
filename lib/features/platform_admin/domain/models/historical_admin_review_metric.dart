class HistoricalAdminReviewMetric {
  final String metric;
  final int value;

  const HistoricalAdminReviewMetric({
    required this.metric,
    required this.value,
  });

  factory HistoricalAdminReviewMetric.fromJson(Map<String, dynamic> json) {
    final rawValue = json['value'];
    return HistoricalAdminReviewMetric(
      metric: (json['metric'] ?? '').toString(),
      value: rawValue is num
          ? rawValue.toInt()
          : int.tryParse('${rawValue ?? ''}') ?? 0,
    );
  }
}
