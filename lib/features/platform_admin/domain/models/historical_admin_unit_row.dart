class HistoricalAdminUnitRow {
  final int id;
  final String code;
  final int periodId;
  final String? periodTitleAr;
  final int? periodStartYear;
  final int? periodEndYear;
  final String? originCommunityCode;
  final int? parentId;

  const HistoricalAdminUnitRow({
    required this.id,
    required this.code,
    required this.periodId,
    this.periodTitleAr,
    this.periodStartYear,
    this.periodEndYear,
    this.originCommunityCode,
    this.parentId,
  });

  String get periodLabel {
    final title = (periodTitleAr ?? '').trim();
    if (title.isNotEmpty) return title;
    return 'الفترة $periodId';
  }

  String get periodRangeLabel {
    final start = periodStartYear?.toString() ?? '—';
    final end = periodEndYear?.toString() ?? '—';
    return '$start → $end';
  }

  factory HistoricalAdminUnitRow.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return HistoricalAdminUnitRow(
      id: parseInt(json['id']) ?? 0,
      code: (json['code'] ?? '').toString(),
      periodId: parseInt(json['period_id']) ?? 0,
      periodTitleAr: json['period_title_ar']?.toString(),
      periodStartYear: parseInt(json['period_start_year']),
      periodEndYear: parseInt(json['period_end_year']),
      originCommunityCode: json['origin_community_code']?.toString(),
      parentId: parseInt(json['parent_id']),
    );
  }
}
