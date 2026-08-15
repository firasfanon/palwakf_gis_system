// ============================================
// 12. MAP DOMAIN MODELS
// ============================================

// lib/features/map/domain/models/waqf_model.dart
import '../../../../core/constants/enums.dart';

class WaqfModel {
  final String id;
  final String pwfKey;
  final String? name;
  final WaqfType type;
  final WaqfStatus status;
  final String? governorate;
  final String? community;
  final String? municipality;
  final String? basin;
  final String? parcel;
  final double? area;
  final Map<String, dynamic>? geometry;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSensitive;

  WaqfModel({
    required this.id,
    required this.pwfKey,
    this.name,
    required this.type,
    required this.status,
    this.governorate,
    this.community,
    this.municipality,
    this.basin,
    this.parcel,
    this.area,
    this.geometry,
    this.createdAt,
    this.updatedAt,
    this.isSensitive = false,
  });

  factory WaqfModel.fromJson(Map<String, dynamic> json) {
    String pickString(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return '';
    }

    return WaqfModel(
      id: pickString(const ['id', 'gid', 'uuid', 'land_id']),
      pwfKey:
          pickString(const ['pwf_key', 'pwfKey', 'pwf', 'pwf_code', 'code']),
      name: pickString(const ['name', 'name_ar', 'title', 'title_ar']).isEmpty
          ? null
          : pickString(const ['name', 'name_ar', 'title', 'title_ar']),
      type: WaqfType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WaqfType.land,
      ),
      status: WaqfStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WaqfStatus.active,
      ),
      governorate: pickString(
                  const ['governorate', 'gov_name', 'gov_ar', 'governorate_ar'])
              .isEmpty
          ? null
          : pickString(
              const ['governorate', 'gov_name', 'gov_ar', 'governorate_ar']),
      community: pickString(
              const ['community', 'community_name', 'community_ar']).isEmpty
          ? null
          : pickString(const ['community', 'community_name', 'community_ar']),
      municipality: pickString(const [
        'municipality',
        'lgu',
        'lgu_name',
        'municipality_name'
      ]).isEmpty
          ? null
          : pickString(
              const ['municipality', 'lgu', 'lgu_name', 'municipality_name']),
      basin: pickString(const ['basin', 'basin_no', 'basin_number']).isEmpty
          ? null
          : pickString(const ['basin', 'basin_no', 'basin_number']),
      parcel: pickString(const ['parcel', 'parcel_no', 'parcel_number']).isEmpty
          ? null
          : pickString(const ['parcel', 'parcel_no', 'parcel_number']),
      area: json['area']?.toDouble(),
      geometry: (json['geometry'] is Map)
          ? (json['geometry'] as Map).cast<String, dynamic>()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isSensitive: json['is_sensitive'] ?? false,
    );
  }
}
