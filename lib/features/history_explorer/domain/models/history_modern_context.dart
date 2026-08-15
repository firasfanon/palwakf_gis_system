class HistoryModernContext {
  final String communityCode;
  final String communityLabel;
  final String? lguCode;
  final String? lguLabel;
  final String? governorateCode;
  final String? governorateLabel;
  final double? centerLat;
  final double? centerLng;
  final Map<String, dynamic>? geomJson;
  final Map<String, dynamic>? centroidJson;

  const HistoryModernContext({
    required this.communityCode,
    required this.communityLabel,
    this.lguCode,
    this.lguLabel,
    this.governorateCode,
    this.governorateLabel,
    this.centerLat,
    this.centerLng,
    this.geomJson,
    this.centroidJson,
  });

  bool get hasCenter =>
      centerLat != null &&
      centerLng != null &&
      centerLat!.isFinite &&
      centerLng!.isFinite &&
      centerLat!.abs() <= 90 &&
      centerLng!.abs() <= 180;
  bool get hasGeometry => geomJson != null;
  bool get hasCentroidGeometry => centroidJson != null;

  HistoryModernContext copyWith({
    String? communityCode,
    String? communityLabel,
    String? lguCode,
    String? lguLabel,
    String? governorateCode,
    String? governorateLabel,
    double? centerLat,
    double? centerLng,
    Map<String, dynamic>? geomJson,
    Map<String, dynamic>? centroidJson,
    bool clearCenter = false,
    bool clearGeometry = false,
    bool clearCentroidGeometry = false,
  }) {
    return HistoryModernContext(
      communityCode: communityCode ?? this.communityCode,
      communityLabel: communityLabel ?? this.communityLabel,
      lguCode: lguCode ?? this.lguCode,
      lguLabel: lguLabel ?? this.lguLabel,
      governorateCode: governorateCode ?? this.governorateCode,
      governorateLabel: governorateLabel ?? this.governorateLabel,
      centerLat: clearCenter ? null : (centerLat ?? this.centerLat),
      centerLng: clearCenter ? null : (centerLng ?? this.centerLng),
      geomJson: clearGeometry ? null : (geomJson ?? this.geomJson),
      centroidJson: clearCentroidGeometry ? null : (centroidJson ?? this.centroidJson),
    );
  }
}
