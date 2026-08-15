import '../../domain/enums/history_period_kind.dart';
import '../../domain/models/history_period_item.dart';

class HistoryPeriodMapper {
  static HistoryPeriodItem fromRow(Map<String, dynamic> row) {
    return HistoryPeriodItem(
      periodNo: (row['period_no'] as num?)?.toInt() ?? 0,
      titleAr: _readString(row, const ['ontology_label_ar', 'period_label_ar', 'label_ar', 'title_ar']) ?? 'فترة تاريخية',
      titleEn: _readString(row, const ['ontology_label_en', 'period_label_en', 'label_en', 'title_en']) ?? '',
      rangeLabelAr: _readString(row, const ['range_label_ar']),
      summaryAr: _readString(row, const ['summary_ar']),
      imageUrl: _readString(row, const ['image_url']),
      isEnabled: _readBool(row['is_enabled'], true),
      hasOverlay: _readBool(row['has_overlay'], false),
      defaultLevelKey: _readString(row, const ['default_level_key']),
      scopeLabelAr: _readString(row, const ['scope_label_ar']),
      modernFilterKey: _readString(row, const ['modern_filter_key']),
      periodKind: HistoryPeriodKind.fromRaw(row['period_kind']),
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
