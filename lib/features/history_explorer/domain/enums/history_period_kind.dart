enum HistoryPeriodKind {
  descriptive,
  reference,
  drawable,
  unknown;

  static HistoryPeriodKind fromRaw(dynamic value) {
    final raw = value?.toString().trim().toLowerCase();
    switch (raw) {
      case 'descriptive':
        return HistoryPeriodKind.descriptive;
      case 'reference':
        return HistoryPeriodKind.reference;
      case 'drawable':
        return HistoryPeriodKind.drawable;
      default:
        return HistoryPeriodKind.unknown;
    }
  }

  String get labelAr {
    switch (this) {
      case HistoryPeriodKind.descriptive:
        return 'وصفية';
      case HistoryPeriodKind.reference:
        return 'مرجعية';
      case HistoryPeriodKind.drawable:
        return 'تشغيلية';
      case HistoryPeriodKind.unknown:
        return 'غير محددة';
    }
  }
}
