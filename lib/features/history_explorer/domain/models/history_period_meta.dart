import '../enums/history_period_kind.dart';

class HistoryPeriodMeta {
  final int periodNo;
  final String titleAr;
  final String titleEn;
  final String? rangeLabelAr;
  final String? summaryAr;
  final String? scopeLabelAr;
  final String? modernFilterKey;
  final String? familyKey;
  final String? familyLabelAr;
  final String? chainKey;
  final String? chainLabelAr;
  final String? defaultLevelKey;
  final HistoryPeriodKind periodKind;
  final bool hasOverlay;

  const HistoryPeriodMeta({
    required this.periodNo,
    required this.titleAr,
    required this.titleEn,
    required this.rangeLabelAr,
    required this.summaryAr,
    required this.scopeLabelAr,
    required this.modernFilterKey,
    required this.familyKey,
    required this.familyLabelAr,
    required this.chainKey,
    required this.chainLabelAr,
    required this.defaultLevelKey,
    required this.periodKind,
    required this.hasOverlay,
  });
}
