// lib/features/map/data/repositories/map_layer_manager_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';

final mapLayerManagerRepositoryProvider =
    Provider<MapLayerManagerRepository>((ref) {
  return MapLayerManagerRepository(ref.watch(supabaseClientProvider));
});


class MapRuntimeLayerGovernanceConfig {
  final String layerKey;
  final String titleAr;
  final String? titleEn;
  final String layerClass;
  final String mirrorPolicy;
  final String loadPolicy;
  final bool isRuntimeAllowed;
  final bool isAdminVisible;
  final double minZoom;
  final double maxZoom;
  final String strokeColor;
  final String fillColor;
  final double strokeWidth;
  final bool labelsEnabled;
  final double labelMinZoom;
  final String labelTextColor;
  final String labelHaloColor;
  final String pointShape;
  final String? source;
  final String? category;
  final String deletionRiskLevel;
  final String? decisionReason;

  const MapRuntimeLayerGovernanceConfig({
    required this.layerKey,
    required this.titleAr,
    this.titleEn,
    required this.layerClass,
    required this.mirrorPolicy,
    required this.loadPolicy,
    required this.isRuntimeAllowed,
    required this.isAdminVisible,
    required this.minZoom,
    required this.maxZoom,
    required this.strokeColor,
    required this.fillColor,
    required this.strokeWidth,
    required this.labelsEnabled,
    required this.labelMinZoom,
    required this.labelTextColor,
    required this.labelHaloColor,
    required this.pointShape,
    this.source,
    this.category,
    required this.deletionRiskLevel,
    this.decisionReason,
  });

  String get displayName => titleAr.trim().isNotEmpty ? titleAr : layerKey;

  bool get isHeavyLayer =>
      layerClass == 'heavy_bbox_layer' || loadPolicy == 'bbox_zoom_driven';

  factory MapRuntimeLayerGovernanceConfig.fromJson(Map<String, dynamic> json) {
    bool asBool(dynamic value, {bool fallback = false}) {
      if (value is bool) return value;
      final text = value?.toString().trim().toLowerCase();
      if (text == 'true' || text == '1') return true;
      if (text == 'false' || text == '0') return false;
      return fallback;
    }

    double asDouble(dynamic value, {double fallback = 0}) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return MapRuntimeLayerGovernanceConfig(
      layerKey: (json['layer_key'] ?? '').toString(),
      titleAr: (json['layer_title_ar'] ?? json['layer_key'] ?? '').toString(),
      titleEn: json['layer_title_en']?.toString(),
      layerClass: (json['layer_class'] ?? 'needs_review').toString(),
      mirrorPolicy: (json['mirror_policy'] ?? 'not_decided').toString(),
      loadPolicy: (json['load_policy'] ?? 'not_decided').toString(),
      isRuntimeAllowed: asBool(json['is_runtime_allowed']),
      isAdminVisible: asBool(json['is_admin_visible']),
      minZoom: asDouble(json['min_zoom'], fallback: 0),
      maxZoom: asDouble(json['max_zoom'], fallback: 22),
      strokeColor: (json['stroke_color'] ?? '#1E3A8A').toString(),
      fillColor: (json['fill_color'] ?? '#DBEAFE').toString(),
      strokeWidth: asDouble(json['stroke_width'], fallback: 1.2),
      labelsEnabled: asBool(json['labels_enabled']),
      labelMinZoom: asDouble(json['label_min_zoom'], fallback: 12),
      labelTextColor: (json['label_text_color'] ?? '#111827').toString(),
      labelHaloColor: (json['label_halo_color'] ?? '#FFFFFF').toString(),
      pointShape: (json['point_shape'] ?? 'square').toString(),
      source: json['source']?.toString(),
      category: json['category']?.toString(),
      deletionRiskLevel:
          (json['deletion_risk_level'] ?? 'unknown').toString(),
      decisionReason: json['decision_reason']?.toString(),
    );
  }
}

class MapLayerAdminConfig {
  final String layerKey;
  final String unitId;
  final String nameAr;
  final String? nameEn;
  final String category;
  final int displayOrder;
  final bool isActive;
  final bool isPublic;
  final bool visiblePublic;
  final bool visibleEmployee;
  final bool visibleManager;
  final double minZoom;
  final double maxZoom;
  final bool bboxRequired;
  final String layerWeight;
  final int maxFeaturesPerRequest;
  final bool cacheEnabled;
  final bool clusteringEnabled;
  final bool identifyEnabled;
  final bool reportEnabled;
  final String exportPolicy;
  final String? adminNotes;
  final String symbologyMode;
  final String strokeColor;
  final String fillColor;
  final String markerColor;
  final double strokeWidth;
  final double fillOpacity;
  final double markerSize;
  final String pointShape;
  final String lineStyle;
  final String stylePreset;
  final String? legendLabelAr;
  final bool legendEnabled;
  final String? uniqueValueField;
  final List<Map<String, dynamic>> uniqueValueRules;
  final bool labelsEnabled;
  final String? labelField;
  final double labelMinZoom;
  final int labelMaxCount;
  final String labelTextColor;
  final String labelHaloColor;
  final double labelFontSize;
  final bool popupEnabled;
  final String? popupTitleField;
  final List<String> popupFields;
  final Map<String, String> popupFieldLabels;
  final bool popupShowDetailsAction;
  final bool popupShowReportAction;
  final bool popupShowTaskAction;
  final String? identifyTitleField;
  final List<String> identifyFields;
  final Map<String, String> identifyFieldLabels;
  final int identifyMaxFields;
  final Map<String, dynamic> style;
  final DateTime? updatedAt;

  const MapLayerAdminConfig({
    required this.layerKey,
    required this.unitId,
    required this.nameAr,
    this.nameEn,
    required this.category,
    required this.displayOrder,
    required this.isActive,
    required this.isPublic,
    required this.visiblePublic,
    required this.visibleEmployee,
    required this.visibleManager,
    required this.minZoom,
    required this.maxZoom,
    required this.bboxRequired,
    required this.layerWeight,
    required this.maxFeaturesPerRequest,
    required this.cacheEnabled,
    required this.clusteringEnabled,
    required this.identifyEnabled,
    required this.reportEnabled,
    required this.exportPolicy,
    this.adminNotes,
    required this.symbologyMode,
    required this.strokeColor,
    required this.fillColor,
    required this.markerColor,
    required this.strokeWidth,
    required this.fillOpacity,
    required this.markerSize,
    required this.pointShape,
    required this.lineStyle,
    required this.stylePreset,
    this.legendLabelAr,
    required this.legendEnabled,
    this.uniqueValueField,
    this.uniqueValueRules = const [],
    required this.labelsEnabled,
    this.labelField,
    required this.labelMinZoom,
    required this.labelMaxCount,
    required this.labelTextColor,
    required this.labelHaloColor,
    required this.labelFontSize,
    required this.popupEnabled,
    this.popupTitleField,
    this.popupFields = const [],
    this.popupFieldLabels = const {},
    required this.popupShowDetailsAction,
    required this.popupShowReportAction,
    required this.popupShowTaskAction,
    this.identifyTitleField,
    this.identifyFields = const [],
    this.identifyFieldLabels = const {},
    required this.identifyMaxFields,
    this.style = const {},
    this.updatedAt,
  });

  String get displayName => nameAr.trim().isNotEmpty ? nameAr : layerKey;

  String get categoryLabelAr {
    switch (category.trim().toLowerCase()) {
      case 'core':
        return 'أساسية';
      case 'waqf':
        return 'وقفية';
      case 'historical':
      case 'history':
        return 'تاريخية';
      case 'gis':
        return 'GIS';
      default:
        return category.trim().isEmpty ? 'GIS' : category;
    }
  }

  String get layerWeightLabelAr {
    switch (layerWeight) {
      case 'light':
        return 'خفيفة';
      case 'heavy':
        return 'ثقيلة';
      default:
        return 'متوسطة';
    }
  }

  String get exportPolicyLabelAr {
    switch (exportPolicy) {
      case 'summary':
        return 'ملخص';
      case 'visible':
        return 'المعروض فقط';
      case 'manager_only':
        return 'المدير فقط';
      default:
        return 'ممنوع';
    }
  }

  String get pointShapeLabelAr {
    switch (pointShape) {
      case 'circle':
        return 'دائرة';
      case 'square':
        return 'مربع';
      case 'diamond':
        return 'معين';
      case 'mosque':
        return 'مسجد';
      case 'cemetery':
        return 'مقبرة';
      case 'landmark':
        return 'معلم';
      default:
        return 'دبوس';
    }
  }

  String get lineStyleLabelAr {
    switch (lineStyle) {
      case 'dashed':
        return 'متقطع';
      case 'dotted':
        return 'منقّط';
      default:
        return 'متصل';
    }
  }

  String get legendLabel =>
      (legendLabelAr ?? '').trim().isNotEmpty ? legendLabelAr!.trim() : displayName;

  bool get usesUniqueValues => symbologyMode == 'unique_value';

  String get uniqueValueFieldLabel =>
      (uniqueValueField ?? '').trim().isEmpty ? 'غير محدد' : uniqueValueField!.trim();

  String get labelFieldLabel =>
      (labelField ?? '').trim().isEmpty ? 'غير محدد' : labelField!.trim();

  String get popupTitleFieldLabel =>
      (popupTitleField ?? '').trim().isEmpty ? 'العنوان الافتراضي' : popupTitleField!.trim();

  String get identifyTitleFieldLabel =>
      (identifyTitleField ?? '').trim().isEmpty ? 'العنوان الافتراضي' : identifyTitleField!.trim();

  String configuredTitle(
    Map<String, dynamic> props,
    String fallback, {
    bool identify = false,
  }) {
    final field = (identify ? identifyTitleField : popupTitleField)?.trim();
    if (field != null && field.isNotEmpty) {
      final value = props[field]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  List<MapEntry<String, String>> configuredEntries(
    Map<String, dynamic> props, {
    bool identify = false,
    int fallbackLimit = 8,
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

    final preferred = identify ? identifyFields : popupFields;
    final labels = identify ? identifyFieldLabels : popupFieldLabels;
    final result = <MapEntry<String, String>>[];
    final seen = <String>{};

    void addField(String rawKey) {
      final key = rawKey.trim();
      if (key.isEmpty || hiddenKeys.contains(key)) return;
      if (!seen.add(key.toLowerCase())) return;
      final value = props[key];
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty) return;
      final label = labels[key] ?? labels[key.toLowerCase()] ?? key;
      result.add(MapEntry(label, text));
    }

    for (final field in preferred) {
      addField(field);
    }

    if (result.isEmpty) {
      for (final entry in props.entries) {
        addField(entry.key);
        if (result.length >= (identify ? identifyMaxFields : fallbackLimit)) {
          break;
        }
      }
    }

    final max = identify ? identifyMaxFields : fallbackLimit;
    return result.take(max <= 0 ? fallbackLimit : max).toList(growable: false);
  }

  factory MapLayerAdminConfig.fromJson(Map<String, dynamic> json) {
    bool asBool(dynamic value, {bool fallback = false}) {
      if (value is bool) return value;
      final s = value?.toString().trim().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
      return fallback;
    }

    int asInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    double asDouble(dynamic value, {double fallback = 0}) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? fallback;
    }

    DateTime? asDate(dynamic value) {
      final text = value?.toString();
      if (text == null || text.trim().isEmpty) return null;
      return DateTime.tryParse(text);
    }

    Map<String, dynamic> asMap(dynamic value) {
      if (value is Map) return value.cast<String, dynamic>();
      return const <String, dynamic>{};
    }

    List<Map<String, dynamic>> asMapList(dynamic value) {
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList(growable: false);
      }
      return const <Map<String, dynamic>>[];
    }

    List<String> asStringList(dynamic value) {
      if (value is List) {
        return value
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      }
      return const <String>[];
    }

    Map<String, String> asStringMap(dynamic value) {
      if (value is Map) {
        final result = <String, String>{};
        for (final entry in value.entries) {
          final key = entry.key.toString().trim();
          final raw = entry.value?.toString().trim() ?? '';
          if (key.isNotEmpty && raw.isNotEmpty) result[key] = raw;
        }
        return result;
      }
      return const <String, String>{};
    }

    return MapLayerAdminConfig(
      layerKey: (json['layer_key'] ?? '').toString(),
      unitId: (json['unit_id'] ?? '00000000-0000-0000-0000-000000000000')
          .toString(),
      nameAr: (json['name_ar'] ?? json['layer_key'] ?? '').toString(),
      nameEn: json['name_en']?.toString(),
      category: (json['category'] ?? 'gis').toString(),
      displayOrder: asInt(json['display_order']),
      isActive: asBool(json['is_active'], fallback: true),
      isPublic: asBool(json['is_public'], fallback: true),
      visiblePublic: asBool(json['visible_public'], fallback: true),
      visibleEmployee: asBool(json['visible_employee'], fallback: true),
      visibleManager: asBool(json['visible_manager'], fallback: true),
      minZoom: asDouble(json['min_zoom']),
      maxZoom: asDouble(json['max_zoom'], fallback: 22),
      bboxRequired: asBool(json['bbox_required'], fallback: true),
      layerWeight: (json['layer_weight'] ?? 'medium').toString(),
      maxFeaturesPerRequest:
          asInt(json['max_features_per_request'], fallback: 2500),
      cacheEnabled: asBool(json['cache_enabled'], fallback: true),
      clusteringEnabled: asBool(json['clustering_enabled']),
      identifyEnabled: asBool(json['identify_enabled'], fallback: true),
      reportEnabled: asBool(json['report_enabled'], fallback: true),
      exportPolicy: (json['export_policy'] ?? 'none').toString(),
      adminNotes: json['admin_notes']?.toString(),
      symbologyMode: (json['symbology_mode'] ?? 'single').toString(),
      strokeColor: (json['stroke_color'] ?? '#1D4ED8').toString(),
      fillColor: (json['fill_color'] ?? '#D4AF37').toString(),
      markerColor: (json['marker_color'] ?? '#D4AF37').toString(),
      strokeWidth: asDouble(json['stroke_width'], fallback: 1.2),
      fillOpacity: asDouble(json['fill_opacity'], fallback: 0.08),
      markerSize: asDouble(json['marker_size'], fallback: 28),
      pointShape: (json['point_shape'] ?? 'pin').toString(),
      lineStyle: (json['line_style'] ?? 'solid').toString(),
      stylePreset: (json['style_preset'] ?? 'palwakf_default').toString(),
      legendLabelAr: json['legend_label_ar']?.toString(),
      legendEnabled: asBool(json['legend_enabled'], fallback: true),
      uniqueValueField: json['unique_value_field']?.toString(),
      uniqueValueRules: asMapList(json['unique_value_rules']),
      labelsEnabled: asBool(json['labels_enabled']),
      labelField: json['label_field']?.toString(),
      labelMinZoom: asDouble(json['label_min_zoom'], fallback: 12),
      labelMaxCount: asInt(json['label_max_count'], fallback: 250),
      labelTextColor: (json['label_text_color'] ?? '#111827').toString(),
      labelHaloColor: (json['label_halo_color'] ?? '#FFFFFF').toString(),
      labelFontSize: asDouble(json['label_font_size'], fallback: 12),
      popupEnabled: asBool(json['popup_enabled'], fallback: true),
      popupTitleField: json['popup_title_field']?.toString(),
      popupFields: asStringList(json['popup_fields']),
      popupFieldLabels: asStringMap(json['popup_field_labels']),
      popupShowDetailsAction:
          asBool(json['popup_show_details_action'], fallback: true),
      popupShowReportAction:
          asBool(json['popup_show_report_action'], fallback: true),
      popupShowTaskAction: asBool(json['popup_show_task_action']),
      identifyTitleField: json['identify_title_field']?.toString(),
      identifyFields: asStringList(json['identify_fields']),
      identifyFieldLabels: asStringMap(json['identify_field_labels']),
      identifyMaxFields: asInt(json['identify_max_fields'], fallback: 8),
      style: asMap(json['style']),
      updatedAt: asDate(json['updated_at']),
    );
  }
}

class MapLayerManagerUpdate {
  final String layerKey;
  final String unitId;
  final bool? isActive;
  final bool? isPublic;
  final int? displayOrder;
  final bool? visiblePublic;
  final bool? visibleEmployee;
  final bool? visibleManager;
  final double? minZoom;
  final double? maxZoom;
  final bool? bboxRequired;
  final String? layerWeight;
  final int? maxFeaturesPerRequest;
  final bool? cacheEnabled;
  final bool? clusteringEnabled;
  final bool? identifyEnabled;
  final bool? reportEnabled;
  final String? exportPolicy;
  final String? adminNotes;
  final String? symbologyMode;
  final String? strokeColor;
  final String? fillColor;
  final String? markerColor;
  final double? strokeWidth;
  final double? fillOpacity;
  final double? markerSize;
  final String? pointShape;
  final String? lineStyle;
  final String? stylePreset;
  final String? legendLabelAr;
  final bool? legendEnabled;
  final String? uniqueValueField;
  final List<Map<String, dynamic>>? uniqueValueRules;
  final bool? labelsEnabled;
  final String? labelField;
  final double? labelMinZoom;
  final int? labelMaxCount;
  final String? labelTextColor;
  final String? labelHaloColor;
  final double? labelFontSize;
  final bool? popupEnabled;
  final String? popupTitleField;
  final List<String>? popupFields;
  final Map<String, String>? popupFieldLabels;
  final bool? popupShowDetailsAction;
  final bool? popupShowReportAction;
  final bool? popupShowTaskAction;
  final String? identifyTitleField;
  final List<String>? identifyFields;
  final Map<String, String>? identifyFieldLabels;
  final int? identifyMaxFields;

  const MapLayerManagerUpdate({
    required this.layerKey,
    this.unitId = '00000000-0000-0000-0000-000000000000',
    this.isActive,
    this.isPublic,
    this.displayOrder,
    this.visiblePublic,
    this.visibleEmployee,
    this.visibleManager,
    this.minZoom,
    this.maxZoom,
    this.bboxRequired,
    this.layerWeight,
    this.maxFeaturesPerRequest,
    this.cacheEnabled,
    this.clusteringEnabled,
    this.identifyEnabled,
    this.reportEnabled,
    this.exportPolicy,
    this.adminNotes,
    this.symbologyMode,
    this.strokeColor,
    this.fillColor,
    this.markerColor,
    this.strokeWidth,
    this.fillOpacity,
    this.markerSize,
    this.pointShape,
    this.lineStyle,
    this.stylePreset,
    this.legendLabelAr,
    this.legendEnabled,
    this.uniqueValueField,
    this.uniqueValueRules,
    this.labelsEnabled,
    this.labelField,
    this.labelMinZoom,
    this.labelMaxCount,
    this.labelTextColor,
    this.labelHaloColor,
    this.labelFontSize,
    this.popupEnabled,
    this.popupTitleField,
    this.popupFields,
    this.popupFieldLabels,
    this.popupShowDetailsAction,
    this.popupShowReportAction,
    this.popupShowTaskAction,
    this.identifyTitleField,
    this.identifyFields,
    this.identifyFieldLabels,
    this.identifyMaxFields,
  });

  Map<String, dynamic> toRpcParams() {
    return {
      'p_layer_key': layerKey,
      'p_unit_id': unitId,
      'p_is_active': isActive,
      'p_is_public': isPublic,
      'p_display_order': displayOrder,
      'p_visible_public': visiblePublic,
      'p_visible_employee': visibleEmployee,
      'p_visible_manager': visibleManager,
      'p_min_zoom': minZoom,
      'p_max_zoom': maxZoom,
      'p_bbox_required': bboxRequired,
      'p_layer_weight': layerWeight,
      'p_max_features_per_request': maxFeaturesPerRequest,
      'p_cache_enabled': cacheEnabled,
      'p_clustering_enabled': clusteringEnabled,
      'p_identify_enabled': identifyEnabled,
      'p_report_enabled': reportEnabled,
      'p_export_policy': exportPolicy,
      'p_admin_notes': adminNotes,
      'p_symbology_mode': symbologyMode,
      'p_stroke_color': strokeColor,
      'p_fill_color': fillColor,
      'p_marker_color': markerColor,
      'p_stroke_width': strokeWidth,
      'p_fill_opacity': fillOpacity,
      'p_marker_size': markerSize,
      'p_point_shape': pointShape,
      'p_line_style': lineStyle,
      'p_style_preset': stylePreset,
      'p_legend_label_ar': legendLabelAr,
      'p_legend_enabled': legendEnabled,
      'p_unique_value_field': uniqueValueField,
      'p_unique_value_rules': uniqueValueRules,
      'p_labels_enabled': labelsEnabled,
      'p_label_field': labelField,
      'p_label_min_zoom': labelMinZoom,
      'p_label_max_count': labelMaxCount,
      'p_label_text_color': labelTextColor,
      'p_label_halo_color': labelHaloColor,
      'p_label_font_size': labelFontSize,
      'p_popup_enabled': popupEnabled,
      'p_popup_title_field': popupTitleField,
      'p_popup_fields': popupFields,
      'p_popup_field_labels': popupFieldLabels,
      'p_popup_show_details_action': popupShowDetailsAction,
      'p_popup_show_report_action': popupShowReportAction,
      'p_popup_show_task_action': popupShowTaskAction,
      'p_identify_title_field': identifyTitleField,
      'p_identify_fields': identifyFields,
      'p_identify_field_labels': identifyFieldLabels,
      'p_identify_max_fields': identifyMaxFields,
    };
  }
}


class MapLayerIntegrityResult {
  final String layerKey;
  final String nameAr;
  final String category;
  final String? source;
  final bool isActive;
  final bool isPublic;
  final int featureCount;
  final int nullGeomCount;
  final int invalidGeomCount;
  final int sridMismatchCount;
  final int emptyGeomCount;
  final Map<String, dynamic> geometryTypes;
  final Map<String, dynamic> issues;
  final Map<String, dynamic>? bbox;
  final String severity;
  final DateTime? checkedAt;

  const MapLayerIntegrityResult({
    required this.layerKey,
    required this.nameAr,
    required this.category,
    this.source,
    required this.isActive,
    required this.isPublic,
    required this.featureCount,
    required this.nullGeomCount,
    required this.invalidGeomCount,
    required this.sridMismatchCount,
    required this.emptyGeomCount,
    required this.geometryTypes,
    required this.issues,
    this.bbox,
    required this.severity,
    this.checkedAt,
  });

  String get displayName => nameAr.trim().isNotEmpty ? nameAr : layerKey;

  String get severityLabelAr {
    switch (severity.trim().toLowerCase()) {
      case 'critical':
        return 'حرجة';
      case 'warning':
        return 'تحذير';
      default:
        return 'سليمة';
    }
  }

  bool get hasIssues => severity.trim().toLowerCase() != 'ok';

  String get issueSummaryAr {
    if (issues.isEmpty) return 'لا توجد مؤشرات خلل ظاهرة.';
    final parts = <String>[];
    if (issues['noFeatures'] == true) parts.add('لا توجد عناصر');
    if (issues['nullGeometry'] != null) parts.add("هندسة مفقودة: ${issues['nullGeometry']}");
    if (issues['invalidGeometry'] != null) parts.add("هندسة غير صالحة: ${issues['invalidGeometry']}");
    if (issues['sridMismatch'] != null) parts.add("SRID غير 4326: ${issues['sridMismatch']}");
    if (issues['emptyGeometry'] != null) parts.add("هندسة فارغة: ${issues['emptyGeometry']}");
    if (issues['inactivePublic'] == true) parts.add('عام لكنه غير مفعّل');
    if (issues['heavyWithoutBboxReview'] == true) parts.add('طبقة كبيرة تحتاج مراجعة BBOX/Zoom');
    return parts.isEmpty ? issues.toString() : parts.join(' • ');
  }

  factory MapLayerIntegrityResult.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool asBool(dynamic value) {
      if (value is bool) return value;
      final text = value?.toString().trim().toLowerCase();
      return text == 'true' || text == '1';
    }

    Map<String, dynamic> asMap(dynamic value) {
      if (value is Map) return value.cast<String, dynamic>();
      return const <String, dynamic>{};
    }

    DateTime? asDate(dynamic value) {
      final text = value?.toString();
      if (text == null || text.trim().isEmpty) return null;
      return DateTime.tryParse(text);
    }

    return MapLayerIntegrityResult(
      layerKey: (json['layer_key'] ?? '').toString(),
      nameAr: (json['name_ar'] ?? json['layer_key'] ?? '').toString(),
      category: (json['category'] ?? 'gis').toString(),
      source: json['source']?.toString(),
      isActive: asBool(json['is_active']),
      isPublic: asBool(json['is_public']),
      featureCount: asInt(json['feature_count']),
      nullGeomCount: asInt(json['null_geom_count']),
      invalidGeomCount: asInt(json['invalid_geom_count']),
      sridMismatchCount: asInt(json['srid_mismatch_count']),
      emptyGeomCount: asInt(json['empty_geom_count']),
      geometryTypes: asMap(json['geometry_types']),
      bbox: json['bbox'] == null ? null : asMap(json['bbox']),
      issues: asMap(json['issues']),
      severity: (json['severity'] ?? 'ok').toString(),
      checkedAt: asDate(json['checked_at']),
    );
  }
}

class MapLayerSettingRevision {
  final String id;
  final String unitId;
  final String layerKey;
  final int revisionNo;
  final String action;
  final String? changedBy;
  final DateTime? changedAt;
  final String? note;
  final Map<String, dynamic> snapshot;

  const MapLayerSettingRevision({
    required this.id,
    required this.unitId,
    required this.layerKey,
    required this.revisionNo,
    required this.action,
    this.changedBy,
    this.changedAt,
    this.note,
    this.snapshot = const {},
  });

  String get actionLabelAr {
    switch (action.trim().toLowerCase()) {
      case 'rollback':
        return 'استرجاع';
      case 'seed':
        return 'تهيئة';
      case 'system':
        return 'نظام';
      default:
        return 'تعديل';
    }
  }

  String get summaryAr {
    final parts = <String>[];
    final weight = snapshot['layer_weight']?.toString();
    final minZoom = snapshot['min_zoom']?.toString();
    final maxZoom = snapshot['max_zoom']?.toString();
    final isActive = snapshot['is_active']?.toString();
    final isPublic = snapshot['is_public']?.toString();
    if (isActive != null) parts.add('تفعيل: $isActive');
    if (isPublic != null) parts.add('عام: $isPublic');
    if (weight != null && weight.isNotEmpty) parts.add('الوزن: $weight');
    if (minZoom != null && maxZoom != null) parts.add('Zoom $minZoom-$maxZoom');
    return parts.isEmpty ? 'نسخة إعدادات طبقة' : parts.join(' • ');
  }

  factory MapLayerSettingRevision.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    DateTime? asDate(dynamic value) {
      final text = value?.toString();
      if (text == null || text.trim().isEmpty) return null;
      return DateTime.tryParse(text);
    }

    Map<String, dynamic> asMap(dynamic value) {
      if (value is Map) return value.cast<String, dynamic>();
      return const <String, dynamic>{};
    }

    return MapLayerSettingRevision(
      id: (json['id'] ?? '').toString(),
      unitId: (json['unit_id'] ?? '00000000-0000-0000-0000-000000000000').toString(),
      layerKey: (json['layer_key'] ?? '').toString(),
      revisionNo: asInt(json['revision_no']),
      action: (json['action'] ?? 'change').toString(),
      changedBy: json['changed_by']?.toString(),
      changedAt: asDate(json['changed_at']),
      note: json['note']?.toString(),
      snapshot: asMap(json['snapshot']),
    );
  }
}

class MapLayerRolePreview {
  final String roleKey;
  final String roleLabelAr;
  final int totalLayers;
  final int visibleLayers;
  final int activeVisibleLayers;
  final int publicVisibleLayers;
  final int heavyVisibleLayers;
  final int bboxRequiredLayers;
  final int exportableLayers;

  const MapLayerRolePreview({
    required this.roleKey,
    required this.roleLabelAr,
    required this.totalLayers,
    required this.visibleLayers,
    required this.activeVisibleLayers,
    required this.publicVisibleLayers,
    required this.heavyVisibleLayers,
    required this.bboxRequiredLayers,
    required this.exportableLayers,
  });

  String get riskLabelAr {
    if (roleKey == 'public' && heavyVisibleLayers > 0) {
      return 'مراجعة مطلوبة: طبقات ثقيلة ظاهرة للجمهور';
    }
    if (visibleLayers == 0) return 'لا توجد طبقات ظاهرة';
    return 'متوازن';
  }

  factory MapLayerRolePreview.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return MapLayerRolePreview(
      roleKey: (json['role_key'] ?? '').toString(),
      roleLabelAr: (json['role_label_ar'] ?? '').toString(),
      totalLayers: asInt(json['total_layers']),
      visibleLayers: asInt(json['visible_layers']),
      activeVisibleLayers: asInt(json['active_visible_layers']),
      publicVisibleLayers: asInt(json['public_visible_layers']),
      heavyVisibleLayers: asInt(json['heavy_visible_layers']),
      bboxRequiredLayers: asInt(json['bbox_required_layers']),
      exportableLayers: asInt(json['exportable_layers']),
    );
  }
}

class MapLayerManagerRepository {
  final SupabaseClient _client;

  const MapLayerManagerRepository(this._client);


  Future<List<MapRuntimeLayerGovernanceConfig>> listRuntimeLayerAllowlist() async {
    final rows = await _client.schema('gis').rpc(
      'rpc_map_runtime_layer_allowlist_v1',
    );
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map(
            (e) => MapRuntimeLayerGovernanceConfig.fromJson(
              e.cast<String, dynamic>(),
            ),
          )
          .where((e) => e.layerKey.trim().isNotEmpty)
          .toList(growable: false);
    }
    if (rows is Map) {
      return [
        MapRuntimeLayerGovernanceConfig.fromJson(rows.cast<String, dynamic>())
      ].where((e) => e.layerKey.trim().isNotEmpty).toList(growable: false);
    }
    return const <MapRuntimeLayerGovernanceConfig>[];
  }

  Future<List<MapLayerRolePreview>> fetchRolePreview({
    String unitId = '00000000-0000-0000-0000-000000000000',
  }) async {
    final rows = await _client.schema('gis').rpc(
      'rpc_map_layer_role_preview_v1',
      params: {'p_unit_id': unitId},
    );
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map((e) => MapLayerRolePreview.fromJson(e.cast<String, dynamic>()))
          .where((e) => e.roleKey.trim().isNotEmpty)
          .toList(growable: false);
    }
    if (rows is Map) {
      return [MapLayerRolePreview.fromJson(rows.cast<String, dynamic>())]
          .where((e) => e.roleKey.trim().isNotEmpty)
          .toList(growable: false);
    }
    return const <MapLayerRolePreview>[];
  }

  Future<List<MapLayerSettingRevision>> listSettingRevisions({
    String? layerKey,
    String unitId = '00000000-0000-0000-0000-000000000000',
    int limit = 30,
  }) async {
    final rows = await _client.schema('gis').rpc(
      'rpc_map_layer_setting_revisions_v1',
      params: {
        'p_layer_key': layerKey,
        'p_unit_id': unitId,
        'p_limit': limit,
      },
    );
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map((e) => MapLayerSettingRevision.fromJson(e.cast<String, dynamic>()))
          .where((e) => e.id.trim().isNotEmpty)
          .toList(growable: false);
    }
    if (rows is Map) {
      return [MapLayerSettingRevision.fromJson(rows.cast<String, dynamic>())]
          .where((e) => e.id.trim().isNotEmpty)
          .toList(growable: false);
    }
    return const <MapLayerSettingRevision>[];
  }

  Future<MapLayerAdminConfig> rollbackSettingRevision({
    required String revisionId,
    required String layerKey,
    String? note,
  }) async {
    await _client.schema('gis').rpc(
      'rpc_map_layer_setting_rollback_v1',
      params: {
        'p_revision_id': revisionId,
        'p_note': note,
      },
    );
    final layers = await listLayerConfigs(includeInactive: true);
    return layers.firstWhere(
      (layer) => layer.layerKey == layerKey,
      orElse: () => throw StateError('لم يتم العثور على الطبقة بعد الاسترجاع.'),
    );
  }

  Future<List<MapLayerIntegrityResult>> checkLayerIntegrity({
    String? layerKey,
    String unitId = '00000000-0000-0000-0000-000000000000',
    bool persist = true,
  }) async {
    final rows = await _client.schema('gis').rpc(
      'rpc_map_layer_integrity_check_v1',
      params: {
        'p_layer_key': layerKey,
        'p_unit_id': unitId,
        'p_persist': persist,
      },
    );
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map((e) => MapLayerIntegrityResult.fromJson(e.cast<String, dynamic>()))
          .where((e) => e.layerKey.trim().isNotEmpty)
          .toList(growable: false);
    }
    if (rows is Map) {
      return [MapLayerIntegrityResult.fromJson(rows.cast<String, dynamic>())]
          .where((e) => e.layerKey.trim().isNotEmpty)
          .toList(growable: false);
    }
    return const <MapLayerIntegrityResult>[];
  }

  Future<List<MapLayerAdminConfig>> listLayerConfigs({
    String? category,
    bool includeInactive = true,
  }) async {
    try {
      final rows = await _client.schema('gis').rpc(
        'rpc_map_layer_manager_list_v4',
        params: {
          'p_category': category,
          'p_include_inactive': includeInactive,
        },
      );
      return _configList(rows);
    } catch (_) {
      try {
        final rows = await _client.schema('gis').rpc(
          'rpc_map_layer_manager_list_v3',
          params: {
            'p_category': category,
            'p_include_inactive': includeInactive,
          },
        );
        return _configList(rows);
      } catch (_) {
        try {
          final rows = await _client.schema('gis').rpc(
            'rpc_map_layer_manager_list_v2',
            params: {
              'p_category': category,
              'p_include_inactive': includeInactive,
            },
          );
          return _configList(rows);
        } catch (_) {
          final rows = await _client.schema('gis').rpc(
            'rpc_map_layer_manager_list',
            params: {
              'p_category': category,
              'p_include_inactive': includeInactive,
            },
          );
          return _configList(rows);
        }
      }
    }
  }


  Future<MapLayerAdminConfig> saveRuntimeLayerAdminSettings(
    MapLayerManagerUpdate update,
  ) async {
    final rows = await _client.schema('gis').rpc(
      'rpc_map_runtime_layer_admin_save_v3',
      params: {
        'p_layer_key': update.layerKey,
        'p_unit_id': update.unitId,
        'p_is_active': update.isActive,
        'p_is_public': update.isPublic,
        'p_min_zoom': update.minZoom,
        'p_max_zoom': update.maxZoom,
        'p_stroke_color': update.strokeColor,
        'p_fill_color': update.fillColor,
        'p_stroke_width': update.strokeWidth,
        'p_labels_enabled': update.labelsEnabled,
        'p_label_min_zoom': update.labelMinZoom,
        'p_label_text_color': update.labelTextColor,
        'p_label_halo_color': update.labelHaloColor,
        'p_point_shape': update.pointShape,
      },
    );
    final list = _configList(rows);
    if (list.isEmpty) {
      throw StateError('لم يرجع RPC إعدادات الطبقة بعد الحفظ الإداري.');
    }
    return list.first;
  }

  Future<MapLayerAdminConfig> updateLayerConfig(
    MapLayerManagerUpdate update,
  ) async {
    dynamic rows;
    try {
      rows = await _client.schema('gis').rpc(
        'rpc_map_layer_manager_update_v5',
        params: update.toRpcParams(),
      );
    } catch (_) {
      try {
        rows = await _client.schema('gis').rpc(
          'rpc_map_layer_manager_update_v4',
          params: update.toRpcParams(),
        );
      } catch (_) {
        try {
          rows = await _client.schema('gis').rpc(
            'rpc_map_layer_manager_update_v3',
            params: _uniqueLabelsUpdateParams(update),
          );
        } catch (_) {
          try {
            rows = await _client.schema('gis').rpc(
              'rpc_map_layer_manager_update_v2',
              params: _symbologyUpdateParams(update),
            );
          } catch (_) {
            rows = await _client.schema('gis').rpc(
              'rpc_map_layer_manager_update',
              params: _legacyUpdateParams(update),
            );
          }
        }
      }
    }
    final list = _configList(rows);
    if (list.isEmpty) {
      throw StateError('لم يرجع RPC إعدادات الطبقة بعد التحديث.');
    }
    return list.first;
  }

  Map<String, dynamic> _uniqueLabelsUpdateParams(MapLayerManagerUpdate update) {
    return {
      'p_layer_key': update.layerKey,
      'p_unit_id': update.unitId,
      'p_is_active': update.isActive,
      'p_is_public': update.isPublic,
      'p_display_order': update.displayOrder,
      'p_visible_public': update.visiblePublic,
      'p_visible_employee': update.visibleEmployee,
      'p_visible_manager': update.visibleManager,
      'p_min_zoom': update.minZoom,
      'p_max_zoom': update.maxZoom,
      'p_bbox_required': update.bboxRequired,
      'p_layer_weight': update.layerWeight,
      'p_max_features_per_request': update.maxFeaturesPerRequest,
      'p_cache_enabled': update.cacheEnabled,
      'p_clustering_enabled': update.clusteringEnabled,
      'p_identify_enabled': update.identifyEnabled,
      'p_report_enabled': update.reportEnabled,
      'p_export_policy': update.exportPolicy,
      'p_admin_notes': update.adminNotes,
      'p_symbology_mode': update.symbologyMode,
      'p_stroke_color': update.strokeColor,
      'p_fill_color': update.fillColor,
      'p_marker_color': update.markerColor,
      'p_stroke_width': update.strokeWidth,
      'p_fill_opacity': update.fillOpacity,
      'p_marker_size': update.markerSize,
      'p_point_shape': update.pointShape,
      'p_line_style': update.lineStyle,
      'p_style_preset': update.stylePreset,
      'p_legend_label_ar': update.legendLabelAr,
      'p_legend_enabled': update.legendEnabled,
      'p_unique_value_field': update.uniqueValueField,
      'p_unique_value_rules': update.uniqueValueRules,
      'p_labels_enabled': update.labelsEnabled,
      'p_label_field': update.labelField,
      'p_label_min_zoom': update.labelMinZoom,
      'p_label_max_count': update.labelMaxCount,
      'p_label_text_color': update.labelTextColor,
      'p_label_halo_color': update.labelHaloColor,
      'p_label_font_size': update.labelFontSize,
    };
  }

  Map<String, dynamic> _symbologyUpdateParams(MapLayerManagerUpdate update) {
    return {
      'p_layer_key': update.layerKey,
      'p_unit_id': update.unitId,
      'p_is_active': update.isActive,
      'p_is_public': update.isPublic,
      'p_display_order': update.displayOrder,
      'p_visible_public': update.visiblePublic,
      'p_visible_employee': update.visibleEmployee,
      'p_visible_manager': update.visibleManager,
      'p_min_zoom': update.minZoom,
      'p_max_zoom': update.maxZoom,
      'p_bbox_required': update.bboxRequired,
      'p_layer_weight': update.layerWeight,
      'p_max_features_per_request': update.maxFeaturesPerRequest,
      'p_cache_enabled': update.cacheEnabled,
      'p_clustering_enabled': update.clusteringEnabled,
      'p_identify_enabled': update.identifyEnabled,
      'p_report_enabled': update.reportEnabled,
      'p_export_policy': update.exportPolicy,
      'p_admin_notes': update.adminNotes,
      'p_symbology_mode': update.symbologyMode,
      'p_stroke_color': update.strokeColor,
      'p_fill_color': update.fillColor,
      'p_marker_color': update.markerColor,
      'p_stroke_width': update.strokeWidth,
      'p_fill_opacity': update.fillOpacity,
      'p_marker_size': update.markerSize,
      'p_point_shape': update.pointShape,
      'p_line_style': update.lineStyle,
      'p_style_preset': update.stylePreset,
      'p_legend_label_ar': update.legendLabelAr,
      'p_legend_enabled': update.legendEnabled,
    };
  }

  Map<String, dynamic> _legacyUpdateParams(MapLayerManagerUpdate update) {
    return {
      'p_layer_key': update.layerKey,
      'p_unit_id': update.unitId,
      'p_is_active': update.isActive,
      'p_is_public': update.isPublic,
      'p_display_order': update.displayOrder,
      'p_visible_public': update.visiblePublic,
      'p_visible_employee': update.visibleEmployee,
      'p_visible_manager': update.visibleManager,
      'p_min_zoom': update.minZoom,
      'p_max_zoom': update.maxZoom,
      'p_bbox_required': update.bboxRequired,
      'p_layer_weight': update.layerWeight,
      'p_max_features_per_request': update.maxFeaturesPerRequest,
      'p_cache_enabled': update.cacheEnabled,
      'p_clustering_enabled': update.clusteringEnabled,
      'p_identify_enabled': update.identifyEnabled,
      'p_report_enabled': update.reportEnabled,
      'p_export_policy': update.exportPolicy,
      'p_admin_notes': update.adminNotes,
    };
  }

  List<MapLayerAdminConfig> _configList(dynamic rows) {
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map((e) => MapLayerAdminConfig.fromJson(e.cast<String, dynamic>()))
          .where((e) => e.layerKey.trim().isNotEmpty)
          .toList(growable: false);
    }
    if (rows is Map) {
      return [MapLayerAdminConfig.fromJson(rows.cast<String, dynamic>())]
          .where((e) => e.layerKey.trim().isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }
}
