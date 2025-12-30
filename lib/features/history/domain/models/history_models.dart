// lib/features/history/domain/models/history_models.dart

import 'dart:convert';

/// نوع طبقة التاريخ على الخريطة
enum HistoricalLayerType {
  wms,
  raster,
  vector,
  tile,
}

/// فترة تاريخية (عهد/حقبة)
class HistoricalPeriod {
  final int id;
  final String titleAr;
  final String? titleEn;
  final int? startYear;
  final int? endYear;
  final bool isDefault;

  const HistoricalPeriod({
    required this.id,
    required this.titleAr,
    this.titleEn,
    this.startYear,
    this.endYear,
    this.isDefault = false,
  });

  bool get hasRange => startYear != null || endYear != null;

  HistoricalPeriod copyWith({
    int? id,
    String? titleAr,
    String? titleEn,
    int? startYear,
    int? endYear,
    bool? isDefault,
  }) {
    return HistoricalPeriod(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory HistoricalPeriod.fromMap(Map<String, dynamic> map) {
    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    return HistoricalPeriod(
      id: _toInt(map['id']) ?? 0,
      titleAr: (map['title_ar'] ?? map['titleAr'] ?? map['name'] ?? '') as String,
      titleEn: map['title_en'] as String?,
      startYear: _toInt(map['start_year'] ?? map['startYear']),
      endYear: _toInt(map['end_year'] ?? map['endYear']),
      isDefault: (map['is_default'] ?? map['isDefault'] ?? false) == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title_ar': titleAr,
      'title_en': titleEn,
      'start_year': startYear,
      'end_year': endYear,
      'is_default': isDefault,
    };
  }
}

/// طبقة تاريخية تُعرض على الخريطة
class HistoricalLayer {
  final int id;
  final int periodId;
  final String nameAr;
  final String? nameEn;
  final HistoricalLayerType type;
  final String url;
  final int zIndex;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  const HistoricalLayer({
    required this.id,
    required this.periodId,
    required this.nameAr,
    this.nameEn,
    required this.type,
    required this.url,
    this.zIndex = 0,
    this.isActive = true,
    this.metadata,
  });

  HistoricalLayer copyWith({
    int? id,
    int? periodId,
    String? nameAr,
    String? nameEn,
    HistoricalLayerType? type,
    String? url,
    int? zIndex,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return HistoricalLayer(
      id: id ?? this.id,
      periodId: periodId ?? this.periodId,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      type: type ?? this.type,
      url: url ?? this.url,
      zIndex: zIndex ?? this.zIndex,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  static HistoricalLayerType _typeFromDb(dynamic raw) {
    final v = (raw ?? '').toString().toLowerCase();
    switch (v) {
      case 'wms':
        return HistoricalLayerType.wms;
      case 'raster':
        return HistoricalLayerType.raster;
      case 'vector':
        return HistoricalLayerType.vector;
      case 'tile':
        return HistoricalLayerType.tile;
      default:
        return HistoricalLayerType.wms;
    }
  }

  static String _typeToDb(HistoricalLayerType type) {
    switch (type) {
      case HistoricalLayerType.wms:
        return 'wms';
      case HistoricalLayerType.raster:
        return 'raster';
      case HistoricalLayerType.vector:
        return 'vector';
      case HistoricalLayerType.tile:
        return 'tile';
    }
  }

  factory HistoricalLayer.fromMap(Map<String, dynamic> map) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    Map<String, dynamic>? _meta(dynamic v) {
      if (v == null) return null;
      if (v is Map<String, dynamic>) return v;
      if (v is String) {
        try {
          final decoded = jsonDecode(v);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {}
      }
      return null;
    }

    return HistoricalLayer(
      id: _toInt(map['id']),
      periodId: _toInt(map['period_id'] ?? map['periodId']),
      nameAr: (map['name_ar'] ?? map['nameAr'] ?? '') as String,
      nameEn: map['name_en'] as String?,
      type: _typeFromDb(map['type']),
      url: (map['url'] ?? '') as String,
      zIndex: _toInt(map['z_index'] ?? map['zIndex']),
      isActive: (map['is_active'] ?? map['isActive'] ?? true) == true,
      metadata: _meta(map['metadata']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period_id': periodId,
      'name_ar': nameAr,
      'name_en': nameEn,
      'type': _typeToDb(type),
      'url': url,
      'z_index': zIndex,
      'is_active': isActive,
      'metadata': metadata,
    };
  }
}

/// صورة/لقطة تاريخية مرتبطة بفترة
class HistoricalMapSnapshot {
  final int id;
  final int periodId;
  final String titleAr;
  final String? titleEn;
  final String imageUrl;
  final String? description;
  final Map<String, dynamic>? metadata;

  const HistoricalMapSnapshot({
    required this.id,
    required this.periodId,
    required this.titleAr,
    this.titleEn,
    required this.imageUrl,
    this.description,
    this.metadata,
  });

  factory HistoricalMapSnapshot.fromMap(Map<String, dynamic> map) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    Map<String, dynamic>? _meta(dynamic v) {
      if (v == null) return null;
      if (v is Map<String, dynamic>) return v;
      if (v is String) {
        try {
          final decoded = jsonDecode(v);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {}
      }
      return null;
    }

    return HistoricalMapSnapshot(
      id: _toInt(map['id']),
      periodId: _toInt(map['period_id'] ?? map['periodId']),
      titleAr: (map['title_ar'] ?? map['titleAr'] ?? map['name'] ?? '') as String,
      titleEn: map['title_en'] as String?,
      imageUrl: (map['image_url'] ?? map['imageUrl'] ?? '') as String,
      description: map['description'] as String?,
      metadata: _meta(map['metadata']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period_id': periodId,
      'title_ar': titleAr,
      'title_en': titleEn,
      'image_url': imageUrl,
      'description': description,
      'metadata': metadata,
    };
  }
}
