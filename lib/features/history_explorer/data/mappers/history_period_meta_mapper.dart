import '../../domain/enums/history_period_kind.dart';
import '../../domain/models/history_period_meta.dart';

class HistoryPeriodMetaMapper {
  static HistoryPeriodMeta fromRow(Map<String, dynamic> row) {
    return HistoryPeriodMeta(
      periodNo: (row['period_no'] as num?)?.toInt() ?? 0,
      titleAr: _readString(row, const ['period_label_ar', 'ontology_label_ar', 'title_ar']) ?? 'فترة تاريخية',
      titleEn: _readString(row, const ['period_label_en', 'ontology_label_en', 'title_en']) ?? '',
      rangeLabelAr: _readString(row, const ['range_label_ar']),
      summaryAr: _readString(row, const ['summary_ar']),
      scopeLabelAr: _readString(row, const ['scope_label_ar']),
      modernFilterKey: _readString(row, const ['modern_filter_key']),
      familyKey: _readString(row, const ['family_key']),
      familyLabelAr: _readString(row, const ['family_label_ar']),
      chainKey: _readString(row, const ['chain_key']),
      chainLabelAr: _readString(row, const ['chain_label_ar']),
      defaultLevelKey: _readString(row, const ['default_level_key']),
      periodKind: HistoryPeriodKind.fromRaw(row['period_kind']),
      hasOverlay: _readBool(row['has_overlay'], false),
    );
  }

  static String? _readString(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static bool _readBool(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;
    return fallback;
  }
}
