class HistoryWaqfAssetLink {
  final String id;
  final String pwfKey;
  final String? name;
  final String? governorate;
  final String? community;
  final String? municipality;
  final double? area;
  final String? typeLabel;
  final String? categoryLabel;
  final String? endowerName;
  final String? statusLabel;
  final String? purpose;
  final double? centerLat;
  final double? centerLng;
  final Map<String, dynamic>? geomJson;
  final Map<String, dynamic>? centroidJson;

  const HistoryWaqfAssetLink({
    required this.id,
    required this.pwfKey,
    this.name,
    this.governorate,
    this.community,
    this.municipality,
    this.area,
    this.typeLabel,
    this.categoryLabel,
    this.endowerName,
    this.statusLabel,
    this.purpose,
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

  String get displayLabel {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    return pwfKey;
  }

  HistoryWaqfAssetLink copyWith({
    String? id,
    String? pwfKey,
    String? name,
    String? governorate,
    String? community,
    String? municipality,
    double? area,
    String? typeLabel,
    String? categoryLabel,
    String? endowerName,
    String? statusLabel,
    String? purpose,
    double? centerLat,
    double? centerLng,
    Map<String, dynamic>? geomJson,
    Map<String, dynamic>? centroidJson,
    bool clearCenter = false,
    bool clearGeometry = false,
    bool clearCentroidGeometry = false,
  }) {
    return HistoryWaqfAssetLink(
      id: id ?? this.id,
      pwfKey: pwfKey ?? this.pwfKey,
      name: name ?? this.name,
      governorate: governorate ?? this.governorate,
      community: community ?? this.community,
      municipality: municipality ?? this.municipality,
      area: area ?? this.area,
      typeLabel: typeLabel ?? this.typeLabel,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      endowerName: endowerName ?? this.endowerName,
      statusLabel: statusLabel ?? this.statusLabel,
      purpose: purpose ?? this.purpose,
      centerLat: clearCenter ? null : (centerLat ?? this.centerLat),
      centerLng: clearCenter ? null : (centerLng ?? this.centerLng),
      geomJson: clearGeometry ? null : (geomJson ?? this.geomJson),
      centroidJson: clearCentroidGeometry ? null : (centroidJson ?? this.centroidJson),
    );
  }
}
