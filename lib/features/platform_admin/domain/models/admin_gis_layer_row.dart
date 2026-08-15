// lib/features/platform_admin/domain/models/admin_gis_layer_row.dart
import '../../../../core/constants/enums.dart';

/// Admin row model for gis.gis_layers.
///
/// Keeps raw identifiers (id/unit_id) when available to make updates safe.
class AdminGisLayerRow {
  final String? id;
  final String? unitId;

  /// Optional last update timestamp (if column exists).
  final DateTime? updatedAt;

  final String key;
  final String nameAr;
  final String? nameEn;
  final LayerCategory category;
  final int displayOrder;
  final bool isPublic;
  final bool isActive;
  final Map<String, dynamic> style;

  const AdminGisLayerRow({
    required this.key,
    required this.nameAr,
    this.nameEn,
    required this.category,
    this.displayOrder = 0,
    required this.isPublic,
    required this.isActive,
    this.style = const {},
    this.id,
    this.unitId,
    this.updatedAt,
  });

  String get layerType => (style['type'] ?? '').toString().trim().toLowerCase();
  String get sourceSchema => (style['sourceSchema'] ?? '').toString().trim();
  String get sourceTable => (style['sourceTable'] ?? '').toString().trim();
  String get urlTemplate => (style['urlTemplate'] ?? '').toString().trim();

  bool get isRasterXyz => layerType == 'raster_xyz' && urlTemplate.isNotEmpty;

  bool get isRasterLike {
    if (urlTemplate.isEmpty) return false;
    if (layerType.isEmpty) return true;
    return layerType == 'raster_xyz' ||
        layerType.contains('raster') ||
        layerType.contains('xyz') ||
        layerType.contains('tile') ||
        layerType.contains('wmts');
  }

  bool get canCompareVisually => isRasterLike && category != LayerCategory.core;

  double get defaultOpacity {
    final raw = style['defaultOpacity'];
    if (raw is num) return raw.toDouble().clamp(0.1, 1.0);
    final parsed = double.tryParse('${raw ?? ''}');
    return (parsed ?? 1.0).clamp(0.1, 1.0);
  }

  bool get compareEnabled {
    if (!canCompareVisually) return false;
    final raw = style['compareEnabled'];
    if (raw is bool) return raw;
    final s = '${raw ?? ''}'.trim().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return true;
  }

  String get bestSourceLabel {
    if (sourceSchema.isNotEmpty && sourceTable.isNotEmpty) {
      return '$sourceSchema.$sourceTable';
    }
    if (sourceTable.isNotEmpty) return sourceTable;
    if (urlTemplate.isNotEmpty) return 'XYZ Raster';
    return 'غير محدد';
  }

  factory AdminGisLayerRow.fromJson(Map<String, dynamic> json) {
    final rawCategory = (json['category'] ?? '').toString().trim();
    LayerCategory _parseCategory(String v) {
      if (v.isEmpty) return LayerCategory.gis;
      for (final e in LayerCategory.values) {
        if (e.name == v) return e;
      }
      for (final e in LayerCategory.values) {
        if (e.arLabel == v) return e;
      }
      final lower = v.toLowerCase();
      if (lower == 'boundary' || lower == 'base' || lower == 'core')
        return LayerCategory.core;
      if (lower == 'waqf') return LayerCategory.waqf;
      if (lower == 'historical' || lower == 'history')
        return LayerCategory.historical;
      if (lower == 'gis') return LayerCategory.gis;
      if (v.startsWith('hist.') ||
          v.startsWith('hist_raw.') ||
          v.startsWith('ontology.')) return LayerCategory.historical;
      if (v.startsWith('waqf.') || v.startsWith('gis_waqf.'))
        return LayerCategory.waqf;
      if (v.startsWith('core.') || v.startsWith('gis_ref.'))
        return LayerCategory.core;
      return LayerCategory.gis;
    }

    final category = _parseCategory(rawCategory);

    return AdminGisLayerRow(
      id: json['id']?.toString(),
      unitId: json['unit_id']?.toString(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      key: (json['key'] ?? '').toString(),
      nameAr: (json['name_ar'] ?? json['key'] ?? '').toString(),
      nameEn: json['name_en']?.toString(),
      category: category,
      displayOrder: (json['display_order'] is num)
          ? (json['display_order'] as num).toInt()
          : int.tryParse('${json['display_order'] ?? ''}') ?? 0,
      isPublic: (json['is_public'] as bool?) ?? true,
      isActive: (json['is_active'] as bool?) ?? true,
      style: (json['style'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
