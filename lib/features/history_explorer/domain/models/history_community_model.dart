import 'history_modern_context.dart';

class HistoryCommunityModel {
  final String coreId;
  final String code;
  final String nameAr;
  final String? nameEn;
  final String? governorateCode;
  final int? communityNo;
  final int? governorateNo;
  final String? communityType;
  final String? coreWakfStatus;
  final int? gisId;
  final String? communityLabelAlt;
  final String? govCode;
  final int? gisCommunityNo;
  final int? gisGovernorateNo;
  final String? cityStatus;
  final String? gisWakfStatus;
  final double? shapeArea;
  final double? centerLat;
  final double? centerLng;
  final Map<String, dynamic>? geomJson;
  final Map<String, dynamic>? centroidJson;

  const HistoryCommunityModel({
    required this.coreId,
    required this.code,
    required this.nameAr,
    this.nameEn,
    this.governorateCode,
    this.communityNo,
    this.governorateNo,
    this.communityType,
    this.coreWakfStatus,
    this.gisId,
    this.communityLabelAlt,
    this.govCode,
    this.gisCommunityNo,
    this.gisGovernorateNo,
    this.cityStatus,
    this.gisWakfStatus,
    this.shapeArea,
    this.centerLat,
    this.centerLng,
    this.geomJson,
    this.centroidJson,
  });

  String get displayLabel {
    final primary = nameAr.trim();
    if (primary.isNotEmpty) return primary;
    final alt = (communityLabelAlt ?? '').trim();
    if (alt.isNotEmpty) return alt;
    final fallback = (nameEn ?? '').trim();
    if (fallback.isNotEmpty) return fallback;
    return code;
  }

  String? get effectiveWakfStatus {
    final primary = (coreWakfStatus ?? '').trim();
    if (primary.isNotEmpty) return primary;
    final fallback = (gisWakfStatus ?? '').trim();
    return fallback.isEmpty ? null : fallback;
  }

  bool get hasSpatialMatch => gisId != null;
  bool get hasGeometry => geomJson != null;
  bool get hasCentroidGeometry => centroidJson != null;
  bool get hasCenter =>
      centerLat != null &&
      centerLng != null &&
      centerLat!.isFinite &&
      centerLng!.isFinite &&
      centerLat!.abs() <= 90 &&
      centerLng!.abs() <= 180;

  HistoryCommunityModel copyWith({
    String? coreId,
    String? code,
    String? nameAr,
    String? nameEn,
    String? governorateCode,
    int? communityNo,
    int? governorateNo,
    String? communityType,
    String? coreWakfStatus,
    int? gisId,
    String? communityLabelAlt,
    String? govCode,
    int? gisCommunityNo,
    int? gisGovernorateNo,
    String? cityStatus,
    String? gisWakfStatus,
    double? shapeArea,
    double? centerLat,
    double? centerLng,
    Map<String, dynamic>? geomJson,
    Map<String, dynamic>? centroidJson,
    bool clearGeometry = false,
    bool clearCentroidGeometry = false,
    bool clearCenter = false,
  }) {
    return HistoryCommunityModel(
      coreId: coreId ?? this.coreId,
      code: code ?? this.code,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      governorateCode: governorateCode ?? this.governorateCode,
      communityNo: communityNo ?? this.communityNo,
      governorateNo: governorateNo ?? this.governorateNo,
      communityType: communityType ?? this.communityType,
      coreWakfStatus: coreWakfStatus ?? this.coreWakfStatus,
      gisId: gisId ?? this.gisId,
      communityLabelAlt: communityLabelAlt ?? this.communityLabelAlt,
      govCode: govCode ?? this.govCode,
      gisCommunityNo: gisCommunityNo ?? this.gisCommunityNo,
      gisGovernorateNo: gisGovernorateNo ?? this.gisGovernorateNo,
      cityStatus: cityStatus ?? this.cityStatus,
      gisWakfStatus: gisWakfStatus ?? this.gisWakfStatus,
      shapeArea: shapeArea ?? this.shapeArea,
      centerLat: clearCenter ? null : (centerLat ?? this.centerLat),
      centerLng: clearCenter ? null : (centerLng ?? this.centerLng),
      geomJson: clearGeometry ? null : (geomJson ?? this.geomJson),
      centroidJson: clearCentroidGeometry ? null : (centroidJson ?? this.centroidJson),
    );
  }

  HistoryModernContext toModernContext({
    String? governorateLabel,
    String? lguCode,
    String? lguLabel,
  }) {
    return HistoryModernContext(
      communityCode: code,
      communityLabel: displayLabel,
      lguCode: lguCode,
      lguLabel: lguLabel,
      governorateCode: governorateCode,
      governorateLabel: governorateLabel,
      centerLat: centerLat,
      centerLng: centerLng,
      geomJson: geomJson,
      centroidJson: centroidJson,
    );
  }

  static HistoryCommunityModel fromRow(Map<String, dynamic> row) {
    return HistoryCommunityModel(
      coreId: _readString(row, const ['core_id', 'id']) ?? '',
      code: _readString(row, const ['code', 'community_code', 'com_code']) ?? '',
      nameAr: _readString(row, const ['name_ar', 'communityn', 'community_name']) ?? '—',
      nameEn: _readString(row, const ['name_en']),
      governorateCode: _readString(row, const ['governorate_code', 'gov_code']),
      communityNo: _readInt(row, const ['community_no']),
      governorateNo: _readInt(row, const ['governorate_no']),
      communityType: _readString(row, const ['community_type', 'city_status']),
      coreWakfStatus: _readString(row, const ['core_wakf_status', 'wakf_status']),
      gisId: _readInt(row, const ['gis_id', 'id']),
      communityLabelAlt: _readString(row, const ['communityn', 'community_name']),
      govCode: _readString(row, const ['gov_code']),
      gisCommunityNo: _readInt(row, const ['gis_community_no', 'community_no']),
      gisGovernorateNo: _readInt(row, const ['gis_governorate_no', 'governorate_no']),
      cityStatus: _readString(row, const ['city_status']),
      gisWakfStatus: _readString(row, const ['gis_wakf_status', 'wakf_status']),
      shapeArea: _readDouble(row, const ['shape_area']),
      centerLat: _readDouble(row, const ['center_lat', 'lat', 'latitude']),
      centerLng: _readDouble(row, const ['center_lng', 'lng', 'longitude']),
      geomJson: _readGeoMap(row, const ['geom_json', 'geom', 'geometry']),
      centroidJson: _readGeoMap(row, const ['centroid_json', 'centroid']),
    );
  }

  static String? _readString(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) continue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static Map<String, dynamic>? _readGeoMap(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return value.cast<String, dynamic>();
    }
    return null;
  }
}
