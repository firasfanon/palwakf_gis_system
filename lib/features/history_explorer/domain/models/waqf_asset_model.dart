class WaqfAssetModel {
  final String waqfAssetId;
  final String nationalAssetCode;
  final String nameAr;
  final String? endowmentName;
  final String? currentGovernorate;
  final String? currentLgu;
  final String? assetType;
  final String? status;
  final String? usage;
  final String? communityName;
  final double? centerLat;
  final double? centerLng;
  final Map<String, dynamic>? geomJson;
  final Map<String, dynamic>? centroidJson;
  final int? linkedParcelsCount;
  final List<String> parcelIds;
  final Map<String, dynamic> raw;

  const WaqfAssetModel({
    required this.waqfAssetId,
    required this.nationalAssetCode,
    required this.nameAr,
    this.endowmentName,
    this.currentGovernorate,
    this.currentLgu,
    this.assetType,
    this.status,
    this.usage,
    this.communityName,
    this.centerLat,
    this.centerLng,
    this.geomJson,
    this.centroidJson,
    this.linkedParcelsCount,
    this.parcelIds = const [],
    this.raw = const {},
  });

  factory WaqfAssetModel.fromRow(Map<String, dynamic> row) {
    final assetId = _readFirstString(row, const [
      'waqf_asset_id',
      'asset_id',
      'id',
      'source_id',
    ]);
    final nationalAssetCode = _readFirstString(row, const [
      'national_asset_code',
      'national_code',
      'pwf_key',
      'asset_code',
      'code',
      'source_code',
    ]);
    final nameAr = _readFirstString(row, const [
      'name_ar',
      'asset_name_ar',
      'name',
      'asset_name',
      'label_ar',
      'title_ar',
    ]);

    final parcelIds = _readParcelIds(row);
    final linkedParcelsCount = _readInt(row, const [
          'linked_parcels_count',
          'parcels_count',
          'parcel_count',
        ]) ??
        (parcelIds.isEmpty ? null : parcelIds.length);

    return WaqfAssetModel(
      waqfAssetId: assetId.isNotEmpty ? assetId : nationalAssetCode,
      nationalAssetCode: nationalAssetCode,
      nameAr: nameAr.isNotEmpty ? nameAr : nationalAssetCode,
      endowmentName: _readNullableString(row, const [
        'endowment_name',
        'reference_endowment_name',
        'waqf_name',
        'wakf_name',
      ]),
      currentGovernorate: _readNullableString(row, const [
        'current_governorate',
        'governorate_name',
        'governorate',
      ]),
      currentLgu: _readNullableString(row, const [
        'current_lgu',
        'lgu_name',
        'municipality',
        'municipality_name',
      ]),
      assetType: _readNullableString(row, const [
        'asset_type',
        'type_label',
        'type',
      ]),
      status: _readNullableString(row, const [
        'status',
        'status_label',
        'asset_status',
      ]),
      usage: _readNullableString(row, const [
        'usage',
        'usage_label',
        'purpose',
        'current_usage',
      ]),
      communityName: _readNullableString(row, const [
        'community_name',
        'community',
        'current_community',
      ]),
      centerLat: _readDouble(row, const [
        'center_lat',
        'lat',
        'latitude',
        'y',
      ]),
      centerLng: _readDouble(row, const [
        'center_lng',
        'lng',
        'longitude',
        'x',
      ]),
      geomJson: _readMap(row, const ['geom_json', 'geometry_json', 'geom', 'geometry']),
      centroidJson: _readMap(row, const ['centroid_json', 'center_json', 'centroid']),
      linkedParcelsCount: linkedParcelsCount,
      parcelIds: parcelIds,
      raw: Map<String, dynamic>.from(row),
    );
  }

  bool get hasGeometry => geomJson != null;
  bool get hasCentroid => centroidJson != null;
  bool get hasCenter =>
      centerLat != null &&
      centerLng != null &&
      centerLat!.isFinite &&
      centerLng!.isFinite &&
      centerLat!.abs() <= 90 &&
      centerLng!.abs() <= 180;

  String get displayLabel {
    final trimmedName = nameAr.trim();
    if (trimmedName.isNotEmpty) return trimmedName;
    final trimmedCode = nationalAssetCode.trim();
    if (trimmedCode.isNotEmpty) return trimmedCode;
    return waqfAssetId;
  }

  WaqfAssetModel copyWith({
    String? waqfAssetId,
    String? nationalAssetCode,
    String? nameAr,
    String? endowmentName,
    String? currentGovernorate,
    String? currentLgu,
    String? assetType,
    String? status,
    String? usage,
    String? communityName,
    double? centerLat,
    double? centerLng,
    Map<String, dynamic>? geomJson,
    Map<String, dynamic>? centroidJson,
    int? linkedParcelsCount,
    List<String>? parcelIds,
    Map<String, dynamic>? raw,
    bool clearCenter = false,
    bool clearGeometry = false,
    bool clearCentroid = false,
  }) {
    return WaqfAssetModel(
      waqfAssetId: waqfAssetId ?? this.waqfAssetId,
      nationalAssetCode: nationalAssetCode ?? this.nationalAssetCode,
      nameAr: nameAr ?? this.nameAr,
      endowmentName: endowmentName ?? this.endowmentName,
      currentGovernorate: currentGovernorate ?? this.currentGovernorate,
      currentLgu: currentLgu ?? this.currentLgu,
      assetType: assetType ?? this.assetType,
      status: status ?? this.status,
      usage: usage ?? this.usage,
      communityName: communityName ?? this.communityName,
      centerLat: clearCenter ? null : (centerLat ?? this.centerLat),
      centerLng: clearCenter ? null : (centerLng ?? this.centerLng),
      geomJson: clearGeometry ? null : (geomJson ?? this.geomJson),
      centroidJson: clearCentroid ? null : (centroidJson ?? this.centroidJson),
      linkedParcelsCount: linkedParcelsCount ?? this.linkedParcelsCount,
      parcelIds: parcelIds ?? this.parcelIds,
      raw: raw ?? this.raw,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'waqf_asset_id': waqfAssetId,
      'national_asset_code': nationalAssetCode,
      'name_ar': nameAr,
      'endowment_name': endowmentName,
      'current_governorate': currentGovernorate,
      'current_lgu': currentLgu,
      'asset_type': assetType,
      'status': status,
      'usage': usage,
      'community_name': communityName,
      'center_lat': centerLat,
      'center_lng': centerLng,
      'geom_json': geomJson,
      'centroid_json': centroidJson,
      'linked_parcels_count': linkedParcelsCount,
      'parcel_ids': parcelIds,
    };
  }

  static String _readFirstString(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      final parsed = _stringify(value);
      if (parsed != null && parsed.isNotEmpty) return parsed;
    }
    return '';
  }

  static String? _readNullableString(Map<String, dynamic> row, List<String> keys) {
    final value = _readFirstString(row, keys);
    return value.isEmpty ? null : value;
  }

  static double? _readDouble(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _readMap(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return value.cast<String, dynamic>();
    }
    return null;
  }

  static List<String> _readParcelIds(Map<String, dynamic> row) {
    for (final key in const [
      'parcel_ids',
      'linked_parcel_ids',
      'parcel_codes',
      'parcels',
    ]) {
      final value = row[key];
      if (value is List) {
        return value
            .map((e) => _stringify(e) ?? '')
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      }
      if (value is String && value.trim().isNotEmpty) {
        return value
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      }
    }
    return const [];
  }

  static String? _stringify(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }
}
