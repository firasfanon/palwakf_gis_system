// lib/features/lands/domain/models/waqf_land.dart

import 'package:flutter/foundation.dart';

/// تصنيف الأرض الوقفية
enum LandClassification {
  mosque,
  investment,
  agricultural,
  residential,
  commercial,
  building,
  other,
}

/// حالة استخدام/إدارة الأرض
enum LandStatus {
  active,
  leased,
  underDispute,
  suspended,
  inactive,
  other,
}

// ---------------------- Helpers: Classification ----------------------

String landClassificationToDb(LandClassification value) {
  switch (value) {
    case LandClassification.mosque:
      return 'mosque';
    case LandClassification.investment:
      return 'investment';
    case LandClassification.agricultural:
      return 'agricultural';
    case LandClassification.residential:
      return 'residential';
    case LandClassification.commercial:
      return 'commercial';
    case LandClassification.building:
      return 'building';
    case LandClassification.other:
      return 'other';
  }
}

LandClassification landClassificationFromDb(String? value) {
  switch (value) {
    case 'mosque':
      return LandClassification.mosque;
    case 'investment':
      return LandClassification.investment;
    case 'agricultural':
      return LandClassification.agricultural;
    case 'residential':
      return LandClassification.residential;
    case 'commercial':
      return LandClassification.commercial;
    case 'building':
      return LandClassification.building;
    case 'other':
      return LandClassification.other;
    default:
      return LandClassification.other;
  }
}

String landClassificationLabelAr(LandClassification value) {
  switch (value) {
    case LandClassification.mosque:
      return 'مسجد / مصلى';
    case LandClassification.investment:
      return 'استثماري';
    case LandClassification.agricultural:
      return 'زراعي';
    case LandClassification.residential:
      return 'سكني';
    case LandClassification.commercial:
      return 'تجاري';
    case LandClassification.building:
      return 'مبنى / بناء';
    case LandClassification.other:
      return 'أخرى';
  }
}

// ---------------------- Helpers: Status ----------------------

String landStatusToDb(LandStatus value) {
  switch (value) {
    case LandStatus.active:
      return 'active';
    case LandStatus.leased:
      return 'leased';
    case LandStatus.underDispute:
      return 'under_dispute';
    case LandStatus.suspended:
      return 'suspended';
    case LandStatus.inactive:
      return 'inactive';
    case LandStatus.other:
      return 'other';
  }
}

LandStatus landStatusFromDb(String? value) {
  switch (value) {
    case 'active':
      return LandStatus.active;
    case 'leased':
      return LandStatus.leased;
    case 'under_dispute':
      return LandStatus.underDispute;
    case 'suspended':
      return LandStatus.suspended;
    case 'inactive':
      return LandStatus.inactive;
    case 'other':
      return LandStatus.other;
    default:
      return LandStatus.other;
  }
}

String landStatusLabelAr(LandStatus value) {
  switch (value) {
    case LandStatus.active:
      return 'نشط';
    case LandStatus.leased:
      return 'مؤجر';
    case LandStatus.underDispute:
      return 'قيد نزاع';
    case LandStatus.suspended:
      return 'موقوف مؤقتاً';
    case LandStatus.inactive:
      return 'غير فعّال';
    case LandStatus.other:
      return 'أخرى';
  }
}

// ---------------------- Model: WaqfLand ----------------------

@immutable
class WaqfLand {
  final int? id;
  final String pwfCode;
  final String nameAr;
  final String? nameEn;
  final String? governorate;
  final String? city;
  final double? areaDunum;
  final LandClassification classification;
  final LandStatus status;
  final double? lat;
  final double? lng;
  final String? notes;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WaqfLand({
    this.id,
    required this.pwfCode,
    required this.nameAr,
    this.nameEn,
    this.governorate,
    this.city,
    this.areaDunum,
    this.classification = LandClassification.other,
    this.status = LandStatus.active,
    this.lat,
    this.lng,
    this.notes,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  WaqfLand copyWith({
    int? id,
    String? pwfCode,
    String? nameAr,
    String? nameEn,
    String? governorate,
    String? city,
    double? areaDunum,
    LandClassification? classification,
    LandStatus? status,
    double? lat,
    double? lng,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WaqfLand(
      id: id ?? this.id,
      pwfCode: pwfCode ?? this.pwfCode,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      areaDunum: areaDunum ?? this.areaDunum,
      classification: classification ?? this.classification,
      status: status ?? this.status,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory WaqfLand.fromMap(Map<String, dynamic> map) {
    return WaqfLand(
      id: map['id'] as int?,
      pwfCode: map['pwf_code'] as String? ?? '',
      nameAr: map['name_ar'] as String? ?? '',
      nameEn: map['name_en'] as String?,
      governorate: map['governorate'] as String?,
      city: map['city'] as String?,
      areaDunum: (map['area_dunum'] as num?)?.toDouble(),
      classification:
      landClassificationFromDb(map['classification'] as String?),
      status: landStatusFromDb(map['status'] as String?),
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      metadata: (map['metadata'] as Map?)?.cast<String, dynamic>(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  /// خريطة للإدخال (INSERT) في Supabase - بدون حقل id
  Map<String, dynamic> toMapForInsert() {
    return <String, dynamic>{
      'pwf_code': pwfCode,
      'name_ar': nameAr,
      'name_en': nameEn,
      'governorate': governorate,
      'city': city,
      'area_dunum': areaDunum,
      'classification': landClassificationToDb(classification),
      'status': landStatusToDb(status),
      'lat': lat,
      'lng': lng,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// خريطة للتحديث (UPDATE) في Supabase - بدون حقل id
  Map<String, dynamic> toMapForUpdate() {
    return <String, dynamic>{
      'pwf_code': pwfCode,
      'name_ar': nameAr,
      'name_en': nameEn,
      'governorate': governorate,
      'city': city,
      'area_dunum': areaDunum,
      'classification': landClassificationToDb(classification),
      'status': landStatusToDb(status),
      'lat': lat,
      'lng': lng,
      'notes': notes,
      'metadata': metadata,
    };
  }
}
