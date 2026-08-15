import 'dart:convert';

import '../../domain/models/history_overlay_feature.dart';

class HistoryOverlayMapper {
  static HistoryOverlayFeature fromRow(Map<String, dynamic> row) {
    final labelAr = _readPreferredLabel(row, const [
          'label_ar',
          'display_name',
          'name_ar',
          'community_name_ar',
          'locality_name_ar',
          'municipality_name_ar',
          'admin_name_ar',
          'arabic_name',
          'title_ar',
        ]) ??
        '';
    final labelEn = _readPreferredLabel(row, const [
          'label_en',
          'name_en',
          'community_name',
          'locality_name',
          'municipality_name',
          'admin_name',
          'name',
          'title',
          'label',
        ]) ??
        '';

    return HistoryOverlayFeature(
      periodNo: (row['period_no'] as num?)?.toInt() ?? 0,
      periodLabelAr: _readString(row['period_label_ar']) ?? '',
      periodLabelEn: _readString(row['period_label_en']) ?? '',
      familyKey: _readString(row['family_key']),
      chainKey: _readString(row['chain_key']),
      levelKey: _readString(row['level_key']),
      sourceTable: _readString(row['source_table']),
      sourceId: _readString(row['source_id']) ?? _readString(row['id']) ?? 'unknown',
      parentSourceId: _readString(row['parent_source_id']),
      entityCode: _readString(row['entity_code']),
      labelAr: labelAr,
      labelEn: labelEn,
      geomJson: _castMap(row['geom_json']),
      centroidJson: _castMap(row['centroid_json']),
      displayOrder: (row['display_order'] as num?)?.toInt() ?? 0,
      attributes: _attributesMap(row),
      styleJson: _castMap(row['style_json']) ?? const <String, dynamic>{},
    );
  }

  static Map<String, dynamic> _attributesMap(Map<String, dynamic> row) {
    final nested = row['attributes'];
    if (nested is Map) return nested.cast<String, dynamic>();
    return row;
  }

  static String? _readPreferredLabel(Map<String, dynamic> row, List<String> keys) {
    final props = _attributesMap(row);
    for (final key in keys) {
      final value = _readString(props[key]);
      if (value != null && value.isNotEmpty && !_isNumericLike(value)) return value;
    }
    return null;
  }

  static bool _isNumericLike(String value) {
    return RegExp(r'^[0-9٠-٩\-\s_./()]+$').hasMatch(value.trim());
  }

  static String? _readString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static Map<String, dynamic>? _castMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return null;
  }
}
