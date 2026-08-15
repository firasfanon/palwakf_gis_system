import 'dart:convert';

Map<String, dynamic> _asJsonObject(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  if (value is String && value.trim().isNotEmpty) {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  }
  return <String, dynamic>{};
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

class HistoricalStyleProfileRow {
  final String profileKey;
  final String profileNameAr;
  final String? profileNameEn;
  final String styleScope;
  final Map<String, dynamic> styleJson;
  final bool isSystem;
  final bool isActive;
  final String? notes;

  const HistoricalStyleProfileRow({
    required this.profileKey,
    required this.profileNameAr,
    this.profileNameEn,
    required this.styleScope,
    required this.styleJson,
    required this.isSystem,
    required this.isActive,
    this.notes,
  });

  factory HistoricalStyleProfileRow.fromJson(Map<String, dynamic> json) {
    return HistoricalStyleProfileRow(
      profileKey: (json['profile_key'] ?? '').toString(),
      profileNameAr: (json['profile_name_ar'] ?? '').toString(),
      profileNameEn: json['profile_name_en']?.toString(),
      styleScope: (json['style_scope'] ?? '').toString(),
      styleJson: _asJsonObject(json['style_json']),
      isSystem: json['is_system'] == true,
      isActive: json['is_active'] == true,
      notes: json['notes']?.toString(),
    );
  }
}

class HistoricalAdminLevelOptionRow {
  final String levelKey;
  final String levelNameAr;
  final String? levelNameEn;
  final String? levelScope;

  const HistoricalAdminLevelOptionRow({
    required this.levelKey,
    required this.levelNameAr,
    this.levelNameEn,
    this.levelScope,
  });

  factory HistoricalAdminLevelOptionRow.fromJson(Map<String, dynamic> json) {
    return HistoricalAdminLevelOptionRow(
      levelKey: (json['level_key'] ?? '').toString(),
      levelNameAr: (json['level_name_ar'] ?? '').toString(),
      levelNameEn: json['level_name_en']?.toString(),
      levelScope: json['level_scope']?.toString(),
    );
  }
}

class HistoricalPeriodStyleOptionRow {
  final int periodNo;
  final String titleAr;
  final bool isOperational;
  final String? defaultLevelKey;
  final String? periodKind;

  const HistoricalPeriodStyleOptionRow({
    required this.periodNo,
    required this.titleAr,
    required this.isOperational,
    this.defaultLevelKey,
    this.periodKind,
  });

  factory HistoricalPeriodStyleOptionRow.fromJson(Map<String, dynamic> json) {
    return HistoricalPeriodStyleOptionRow(
      periodNo: _parseInt(json['period_no']) ?? 0,
      titleAr: (json['ontology_label_ar'] ?? '').toString(),
      isOperational: json['is_operational'] == true,
      defaultLevelKey: json['default_level_key']?.toString(),
      periodKind: json['period_kind']?.toString(),
    );
  }
}

class HistoricalLevelStyleDefaultRow {
  final String levelKey;
  final String levelNameAr;
  final String? profileKey;
  final String? profileNameAr;
  final Map<String, dynamic> overrideStyleJson;
  final bool isActive;
  final String? notes;

  const HistoricalLevelStyleDefaultRow({
    required this.levelKey,
    required this.levelNameAr,
    this.profileKey,
    this.profileNameAr,
    required this.overrideStyleJson,
    required this.isActive,
    this.notes,
  });
}

class HistoricalPeriodLevelStyleOverrideRow {
  final int periodNo;
  final String periodTitleAr;
  final String levelKey;
  final String levelNameAr;
  final String? profileKey;
  final String? profileNameAr;
  final Map<String, dynamic> overrideStyleJson;
  final bool isActive;
  final String? notes;

  const HistoricalPeriodLevelStyleOverrideRow({
    required this.periodNo,
    required this.periodTitleAr,
    required this.levelKey,
    required this.levelNameAr,
    this.profileKey,
    this.profileNameAr,
    required this.overrideStyleJson,
    required this.isActive,
    this.notes,
  });
}

class HistoricalFeatureStyleOverrideRow {
  final int id;
  final int? periodNo;
  final String? periodTitleAr;
  final String levelKey;
  final String levelNameAr;
  final String sourceTable;
  final String sourceId;
  final String? profileKey;
  final String? profileNameAr;
  final Map<String, dynamic> overrideStyleJson;
  final bool isActive;
  final String? notes;

  const HistoricalFeatureStyleOverrideRow({
    required this.id,
    this.periodNo,
    this.periodTitleAr,
    required this.levelKey,
    required this.levelNameAr,
    required this.sourceTable,
    required this.sourceId,
    this.profileKey,
    this.profileNameAr,
    required this.overrideStyleJson,
    required this.isActive,
    this.notes,
  });
}
