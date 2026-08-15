import '../enums/mustakshif_map_layer_semantics.dart';

class MustakshifLayerCartography {
  const MustakshifLayerCartography({
    required this.layerKey,
    required this.layerNameAr,
    this.layerNameEn,
    required this.purpose,
    required this.geometryType,
    required this.scaleProfile,
    this.sourceName,
    this.sourceDate,
    this.importDate,
    required this.accuracyLevel,
    required this.legalWeight,
    required this.displayOrder,
    this.zoomMin,
    this.zoomMax,
    this.legendSchema = const <String, dynamic>{},
    this.warningAr,
    this.isReferenceLayer = false,
    this.isAnalysisLayer = false,
    this.isHistoricalLayer = false,
    this.isOperationalLayer = false,
    this.notes,
  });

  final String layerKey;
  final String layerNameAr;
  final String? layerNameEn;
  final MustakshifMapLayerPurpose purpose;
  final String geometryType;
  final String scaleProfile;
  final String? sourceName;
  final DateTime? sourceDate;
  final DateTime? importDate;
  final MustakshifLayerAccuracyLevel accuracyLevel;
  final MustakshifLayerLegalWeight legalWeight;
  final int displayOrder;
  final double? zoomMin;
  final double? zoomMax;
  final Map<String, dynamic> legendSchema;
  final String? warningAr;
  final bool isReferenceLayer;
  final bool isAnalysisLayer;
  final bool isHistoricalLayer;
  final bool isOperationalLayer;
  final String? notes;

  bool get requiresSourceReview => sourceName == null || sourceName!.trim().isEmpty || legalWeight.requiresReview || accuracyLevel == MustakshifLayerAccuracyLevel.unknown;

  bool isVisibleForZoom(double zoom) {
    final min = zoomMin;
    final max = zoomMax;
    if (min != null && zoom < min) return false;
    if (max != null && zoom > max) return false;
    return true;
  }

  String get readableSourceAr {
    final source = sourceName?.trim();
    if (source == null || source.isEmpty) return 'مصدر غير محدد';
    return source;
  }

  factory MustakshifLayerCartography.fromJson(Map<String, dynamic> json) {
    return MustakshifLayerCartography(
      layerKey: _asString(json['layer_key']),
      layerNameAr: _asString(json['layer_name_ar'], fallback: 'طبقة غير مسماة'),
      layerNameEn: _nullableString(json['layer_name_en']),
      purpose: MustakshifMapLayerPurposeX.fromKey(_nullableString(json['layer_purpose'])),
      geometryType: _asString(json['geometry_type'], fallback: 'mixed'),
      scaleProfile: _asString(json['scale_profile'], fallback: 'context'),
      sourceName: _nullableString(json['source_name']),
      sourceDate: _dateOrNull(json['source_date']),
      importDate: _dateOrNull(json['import_date']),
      accuracyLevel: MustakshifLayerAccuracyLevelX.fromKey(_nullableString(json['accuracy_level'])),
      legalWeight: MustakshifLayerLegalWeightX.fromKey(_nullableString(json['legal_weight'])),
      displayOrder: _asInt(json['display_order'], fallback: 100),
      zoomMin: _asDoubleOrNull(json['zoom_min']),
      zoomMax: _asDoubleOrNull(json['zoom_max']),
      legendSchema: _asMap(json['legend_schema']),
      warningAr: _nullableString(json['warning_ar']),
      isReferenceLayer: _asBool(json['is_reference_layer']),
      isAnalysisLayer: _asBool(json['is_analysis_layer']),
      isHistoricalLayer: _asBool(json['is_historical_layer']),
      isOperationalLayer: _asBool(json['is_operational_layer']),
      notes: _nullableString(json['notes']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'layer_key': layerKey,
      'layer_name_ar': layerNameAr,
      'layer_name_en': layerNameEn,
      'layer_purpose': purpose.key,
      'geometry_type': geometryType,
      'scale_profile': scaleProfile,
      'source_name': sourceName,
      'source_date': sourceDate?.toIso8601String(),
      'import_date': importDate?.toIso8601String(),
      'accuracy_level': accuracyLevel.key,
      'legal_weight': legalWeight.key,
      'display_order': displayOrder,
      'zoom_min': zoomMin,
      'zoom_max': zoomMax,
      'legend_schema': legendSchema,
      'warning_ar': warningAr,
      'is_reference_layer': isReferenceLayer,
      'is_analysis_layer': isAnalysisLayer,
      'is_historical_layer': isHistoricalLayer,
      'is_operational_layer': isOperationalLayer,
      'notes': notes,
    };
  }

  static String _asString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _asInt(Object? value, {required int fallback}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double? _asDoubleOrNull(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  static DateTime? _dateOrNull(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }
}
