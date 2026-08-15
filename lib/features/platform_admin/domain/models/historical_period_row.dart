class HistoricalPeriodRow {
  final int periodNo;
  final String titleAr;
  final String rangeLabelAr;
  final String? summaryAr;
  final String? imageUrl;
  final bool isEnabled;
  final bool isOperational;
  final String? defaultLevelKey;
  final int totalOverlayRows;
  final bool hasOverlay;
  final String periodKind;
  final String? scopeLabelAr;
  final String? modernFilterKey;

  const HistoricalPeriodRow({
    required this.periodNo,
    required this.titleAr,
    required this.rangeLabelAr,
    this.summaryAr,
    this.imageUrl,
    required this.isEnabled,
    required this.isOperational,
    this.defaultLevelKey,
    required this.totalOverlayRows,
    required this.hasOverlay,
    required this.periodKind,
    this.scopeLabelAr,
    this.modernFilterKey,
  });

  factory HistoricalPeriodRow.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    final titleAr = (json['ontology_label_ar'] ?? '').toString();
    final periodKind = (json['period_kind'] ?? 'unknown').toString();
    final isOperational = json['is_operational'] == true;
    final totalOverlayRows = parseInt(json['total_overlay_rows']) ?? 0;

    return HistoricalPeriodRow(
      periodNo: parseInt(json['period_no']) ?? 0,
      titleAr: titleAr,
      rangeLabelAr: (json['range_label_ar'] ?? titleAr).toString(),
      summaryAr: _cleanNullable(json['summary_ar']),
      imageUrl: _cleanNullable(json['image_url']),
      isEnabled: json['is_enabled'] != false,
      isOperational: isOperational,
      defaultLevelKey: _cleanNullable(json['default_level_key']),
      totalOverlayRows: totalOverlayRows,
      hasOverlay: json['has_overlay'] == true || totalOverlayRows > 0,
      periodKind: periodKind,
      scopeLabelAr: _cleanNullable(json['scope_label_ar']),
      modernFilterKey: _cleanNullable(json['modern_filter_key']),
    );
  }

  static String? _cleanNullable(dynamic value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty || raw.toLowerCase() == 'null') {
      return null;
    }
    return raw;
  }

  bool get isDescriptive => periodKind == 'descriptive';
  bool get isReference => periodKind == 'reference';
  bool get isDrawable => periodKind == 'drawable' && hasOverlay;

  String get kindLabelAr {
    switch (periodKind) {
      case 'descriptive':
        return 'وصفية';
      case 'reference':
        return 'مرجعية';
      case 'drawable':
        return 'قابلة للرسم';
      default:
        return isOperational ? 'تشغيلية' : 'غير محددة';
    }
  }

  String get defaultLevelLabelAr {
    switch (defaultLevelKey) {
      case 'welaya':
        return 'ولاية';
      case 'sonjoq':
        return 'سنجق';
      case 'lewa':
        return 'لواء';
      case 'kada':
        return 'قضاء';
      case 'westbank_gaza':
        return 'الضفة/غزة';
      case 'governorate':
        return 'محافظة';
      case 'community':
        return 'تجمع';
      case 'lgu':
        return 'هيئة محلية';
      default:
        return defaultLevelKey ?? '—';
    }
  }

  String get statusHintAr {
    if (isDrawable) {
      return 'طبقة جاهزة للعرض على الخريطة.';
    }
    if (isReference) {
      return 'فترة مرجعية دون طبقة هندسية مستقلة حاليًا.';
    }
    return 'فترة وصفية تُعرض كبطاقة تاريخية مرجعية.';
  }
}
