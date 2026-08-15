import '../enums/history_period_kind.dart';

class HistoryPeriodItem {
  final int periodNo;
  final String titleAr;
  final String titleEn;
  final String? rangeLabelAr;
  final String? summaryAr;
  final String? imageUrl;
  final bool isEnabled;
  final bool hasOverlay;
  final String? defaultLevelKey;
  final String? scopeLabelAr;
  final String? modernFilterKey;
  final HistoryPeriodKind periodKind;

  const HistoryPeriodItem({
    required this.periodNo,
    required this.titleAr,
    required this.titleEn,
    required this.rangeLabelAr,
    required this.summaryAr,
    required this.imageUrl,
    required this.isEnabled,
    required this.hasOverlay,
    required this.defaultLevelKey,
    required this.scopeLabelAr,
    required this.modernFilterKey,
    required this.periodKind,
  });

  bool get isDrawable => periodKind == HistoryPeriodKind.drawable;
}
