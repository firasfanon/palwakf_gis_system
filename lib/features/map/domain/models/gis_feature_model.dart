// lib/features/map/domain/models/gis_feature_model.dart
import 'dart:convert';

class GisFeatureModel {
  final String id;
  final String layerKey;
  final String? titleAr;
  final String? titleEn;
  final Map<String, dynamic> props;

  /// GeoJSON geometry (Map) in EPSG:4326
  final Map<String, dynamic>? geom;

  /// GeoJSON centroid (Point) in EPSG:4326
  final Map<String, dynamic>? centroid;

  final bool isPublic;

  Map<String, dynamic> get properties => props;
  String? get layerNameAr =>
      (props['layer_name_ar'] ?? props['layerNameAr'])?.toString();
  String? get layerNameEn =>
      (props['layer_name_en'] ?? props['layerNameEn'])?.toString();

  String get displayTitle {
    final candidates = [
      titleAr,
      titleEn,
      props['display_title']?.toString(),
      props['name_ar']?.toString(),
      props['name_en']?.toString(),
      props['label_ar']?.toString(),
      props['label_en']?.toString(),
      props['title_ar']?.toString(),
      props['title_en']?.toString(),
      props['name']?.toString(),
      props['title']?.toString(),
      props['code']?.toString(),
      id,
    ];
    for (final value in candidates) {
      if (value != null) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
    }
    return 'بدون عنوان';
  }

  List<MapEntry<String, String>> get previewEntries =>
      _normalizedEntries(limit: 4);

  List<MapEntry<String, String>> get detailEntries => _normalizedEntries();

  /// Full sovereign attributes for details cards. Keeps null/empty values as
  /// "غير مدخل" so reviewers can see every source field returned by RPC.
  List<MapEntry<String, String>> get allDetailEntries =>
      _normalizedEntries(includeEmpty: true);

  List<MapEntry<String, String>> _normalizedEntries({
    int? limit,
    bool includeEmpty = false,
  }) {
    const hiddenKeys = {
      'geom',
      'geometry',
      'centroid',
      'bbox',
      'shape',
      'wkb_geometry',
      'geojson',
    };

    final entries = <MapEntry<String, String>>[];
    for (final entry in props.entries) {
      final key = entry.key.trim();
      if (key.isEmpty) continue;
      if (hiddenKeys.contains(key)) continue;

      final value = entry.value;
      final textValue = value == null ? '' : value.toString().trim();
      if (textValue.isEmpty) {
        if (!includeEmpty) continue;
        entries.add(MapEntry(key, 'غير مدخل'));
      } else {
        entries.add(MapEntry(key, textValue));
      }
      if (limit != null && entries.length >= limit) break;
    }
    return entries;
  }

  const GisFeatureModel({
    required this.id,
    required this.layerKey,
    this.titleAr,
    this.titleEn,
    this.props = const {},
    this.geom,
    this.centroid,
    this.isPublic = true,
  });

  static Map<String, dynamic>? _parseGeo(dynamic v) {
    if (v == null) return null;
    if (v is Map) return v.cast<String, dynamic>();
    if (v is String && v.isNotEmpty) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {}
    }
    return null;
  }

  factory GisFeatureModel.fromJson(Map<String, dynamic> json) {
    return GisFeatureModel(
      id: (json['id'] ?? '').toString(),
      layerKey: (json['layer_key'] ?? '').toString(),
      titleAr: json['title_ar']?.toString(),
      titleEn: json['title_en']?.toString(),
      props: (json['props'] as Map?)?.cast<String, dynamic>() ?? const {},
      geom: _parseGeo(json['geom']),
      centroid: _parseGeo(json['centroid']),
      isPublic: (json['is_public'] as bool?) ?? true,
    );
  }
}
