// lib/features/history/domain/models/history_admin_models.dart

import 'dart:convert';

/// مستوى إداري تاريخي (لواء / قضاء / محافظة / مدينة / قرية / ...).
enum HistoricalAdminLevel {
  liwa,
  qada,
  muhafaza,
  nahiya,
  city,
  village,
  hamlet,
  quarter,
  camp,
}

/// تحويل المستوى الإداري إلى قيمة نصية تُخزَّن في قاعدة البيانات.
/// مهم: القيم هنا يجب أن تطابق ENUM public.historical_admin_level في Postgres.
String historicalAdminLevelToDb(HistoricalAdminLevel level) {
  switch (level) {
    case HistoricalAdminLevel.liwa:
      return 'liwa';
    case HistoricalAdminLevel.qada:
      return 'qada';
    case HistoricalAdminLevel.muhafaza:
      return 'muhafaza';
    case HistoricalAdminLevel.nahiya:
      return 'nahiya';
    case HistoricalAdminLevel.city:
      return 'city';
    case HistoricalAdminLevel.village:
      return 'village';
    case HistoricalAdminLevel.hamlet:
      return 'hamlet';
    case HistoricalAdminLevel.quarter:
      return 'quarter';
    case HistoricalAdminLevel.camp:
      return 'camp';
  }
}

/// تحويل النص القادم من قاعدة البيانات إلى enum.
HistoricalAdminLevel historicalAdminLevelFromDb(String value) {
  switch (value) {
    case 'liwa':
      return HistoricalAdminLevel.liwa;
    case 'qada':
      return HistoricalAdminLevel.qada;
    case 'muhafaza':
      return HistoricalAdminLevel.muhafaza;
    case 'nahiya':
      return HistoricalAdminLevel.nahiya;
    case 'city':
      return HistoricalAdminLevel.city;
    case 'village':
      return HistoricalAdminLevel.village;
    case 'hamlet':
      return HistoricalAdminLevel.hamlet;
    case 'quarter':
      return HistoricalAdminLevel.quarter;
    case 'camp':
      return HistoricalAdminLevel.camp;
    default:
      return HistoricalAdminLevel.city;
  }
}

/// وحدة إدارية تاريخية (لواء / قضاء / محافظة / مدينة / قرية ...).
class HistoricalAdminUnit {
  final int id;
  final int periodId;
  final HistoricalAdminLevel level;

  final String nameAr;
  final String? nameEn;

  /// Optional "code" (يمكن استخدامه كمرجع ثابت/slug)
  final String? code;

  final int? parentId;
  final double? areaKm2;
  final int? population;

  /// أسماء بديلة (JSON) - مثال: {"ar": ["بيت لحم", "بيت لحم القديمة"]}
  final Map<String, dynamic>? altNames;

  final Map<String, dynamic>? metadata;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HistoricalAdminUnit({
    required this.id,
    required this.periodId,
    required this.level,
    required this.nameAr,
    this.nameEn,
    this.code,
    this.parentId,
    this.areaKm2,
    this.population,
    this.altNames,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  HistoricalAdminUnit copyWith({
    int? id,
    int? periodId,
    HistoricalAdminLevel? level,
    String? nameAr,
    String? nameEn,
    String? code,
    int? parentId,
    double? areaKm2,
    int? population,
    Map<String, dynamic>? altNames,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HistoricalAdminUnit(
      id: id ?? this.id,
      periodId: periodId ?? this.periodId,
      level: level ?? this.level,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      code: code ?? this.code,
      parentId: parentId ?? this.parentId,
      areaKm2: areaKm2 ?? this.areaKm2,
      population: population ?? this.population,
      altNames: altNames ?? this.altNames,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static int? _toIntNullable(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _toDoubleNullable(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static Map<String, dynamic>? _toJsonMap(dynamic v) {
    if (v == null) return null;
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.cast<String, dynamic>();
    if (v is String) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {}
    }
    return null;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory HistoricalAdminUnit.fromJson(Map<String, dynamic> json) {
    return HistoricalAdminUnit(
      id: _toInt(json['id']),
      periodId: _toInt(json['period_id'] ?? json['periodId']),
      level: historicalAdminLevelFromDb((json['level'] ?? 'city').toString()),
      nameAr: (json['name_ar'] ?? json['nameAr'] ?? '') as String,
      nameEn: json['name_en'] as String?,
      code: json['code'] as String?,
      parentId: _toIntNullable(json['parent_id']),
      areaKm2: _toDoubleNullable(json['area_km2']),
      population: _toIntNullable(json['population']),
      altNames: _toJsonMap(json['alt_names'] ?? json['altNames']),
      metadata: _toJsonMap(json['metadata']),
      createdAt: _toDate(json['created_at']),
      updatedAt: _toDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period_id': periodId,
      'level': historicalAdminLevelToDb(level),
      'code': code,
      'name_ar': nameAr,
      'name_en': nameEn,
      'parent_id': parentId,
      'area_km2': areaKm2,
      'population': population,
      'alt_names': altNames,
      'metadata': metadata,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// ارتباط أرض بوحدة إدارية تاريخية (تاريخيًا هذه الأرض تبعت لقرية/لواء/قضاء...).
class LandAdminHistoryEntry {
  final int id;
  final int landId;
  final int periodId;
  final int adminUnitId;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const LandAdminHistoryEntry({
    required this.id,
    required this.landId,
    required this.periodId,
    required this.adminUnitId,
    this.notes,
    this.metadata,
  });

  LandAdminHistoryEntry copyWith({
    int? id,
    int? landId,
    int? periodId,
    int? adminUnitId,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return LandAdminHistoryEntry(
      id: id ?? this.id,
      landId: landId ?? this.landId,
      periodId: periodId ?? this.periodId,
      adminUnitId: adminUnitId ?? this.adminUnitId,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static Map<String, dynamic>? _toJsonMap(dynamic v) {
    if (v == null) return null;
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.cast<String, dynamic>();
    if (v is String) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {}
    }
    return null;
  }

  factory LandAdminHistoryEntry.fromJson(Map<String, dynamic> json) {
    return LandAdminHistoryEntry(
      id: _toInt(json['id']),
      landId: _toInt(json['land_id']),
      periodId: _toInt(json['period_id']),
      adminUnitId: _toInt(json['admin_unit_id']),
      notes: json['notes'] as String?,
      metadata: _toJsonMap(json['metadata']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'land_id': landId,
      'period_id': periodId,
      'admin_unit_id': adminUnitId,
      'notes': notes,
      'metadata': metadata,
    };
  }
}
