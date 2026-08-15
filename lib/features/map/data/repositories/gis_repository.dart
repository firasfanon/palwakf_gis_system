// lib/features/map/data/repositories/gis_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/models/gis_feature_model.dart';
import '../../domain/models/gis_layer_model.dart';
import '../../domain/models/lookup_item.dart';

final gisRepositoryProvider = Provider<GisRepository>((ref) {
  return GisRepository(ref.watch(supabaseClientProvider));
});

class SpatialIdentifyHit {
  final GisFeatureModel feature;
  final double? distanceMeters;
  final String relation;
  final double score;
  final double? areaSqMeters;
  final int rank;

  const SpatialIdentifyHit({
    required this.feature,
    this.distanceMeters,
    required this.relation,
    required this.score,
    this.areaSqMeters,
    required this.rank,
  });

  factory SpatialIdentifyHit.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int asInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return SpatialIdentifyHit(
      feature: GisFeatureModel.fromJson(json),
      distanceMeters: asDouble(json['distance_meters']),
      relation: (json['relation'] ?? 'nearest').toString(),
      score: asDouble(json['score']) ?? 0,
      areaSqMeters: asDouble(json['area_sq_meters']),
      rank: asInt(json['rank_no']),
    );
  }
}

enum _LookupKind { governorate, lgu }

class GisRepository {
  final SupabaseClient _client;
  GisRepository(this._client);

  static const String _naturalBlocksLayerKey = 'natural_blocks_full';

  bool _isRetiredNaturalBlocksLayerKey(String key) {
    return key.trim().toLowerCase() == 'natural_blocks';
  }

  List<String> _cleanLayerKeys(Iterable<String> keys) {
    final seen = <String>{};
    final result = <String>[];
    for (final rawKey in keys) {
      final key = rawKey.trim();
      if (key.isEmpty) continue;

      // Sovereign rule: natural_blocks_full is the only approved modern
      // natural-blocks layer. The old natural_blocks key must not be loaded,
      // queried, aliased, or silently redirected.
      if (_isRetiredNaturalBlocksLayerKey(key)) continue;

      final marker = key.toLowerCase();
      if (seen.add(marker)) result.add(key);
    }
    return result;
  }

  Map<String, dynamic>? _parseRpcGeo(dynamic value) {
    if (value == null) return null;
    if (value is Map) return value.cast<String, dynamic>();
    return GisFeatureModel.fromJson({'geom': value}).geom;
  }

  GisFeatureModel _featureFromPublicGeoRpc(
    Map<String, dynamic> row, {
    required String layerKey,
    required String layerNameAr,
  }) {
    final props = (row['properties'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final id = (row['id'] ?? props['id'] ?? '').toString();
    final title = (props['display_title'] ??
            props['name_ar'] ??
            props['arab_name'] ??
            props['block_no'] ??
            props['parcel_display_no'] ??
            id)
        .toString();
    return GisFeatureModel(
      id: id,
      layerKey: layerKey,
      titleAr: title.trim().isEmpty ? null : title,
      props: <String, dynamic>{
        ...props,
        'layer_key': layerKey,
        'layer_kind': props['layer_kind'] ?? layerKey,
        'layer_name_ar': props['layer_name_ar'] ?? layerNameAr,
      },
      geom: _parseRpcGeo(row['geojson']),
      centroid: _parseRpcGeo(row['centroid']),
      isPublic: true,
    );
  }

  List<GisFeatureModel> _featuresFromRows(
    dynamic rows, {
    required String layerKey,
    required String layerNameAr,
  }) {
    if (rows is! List) return const <GisFeatureModel>[];
    return rows
        .whereType<Map>()
        .map((row) => _featureFromPublicGeoRpc(
              row.cast<String, dynamic>(),
              layerKey: layerKey,
              layerNameAr: layerNameAr,
            ))
        .where((feature) => feature.geom != null)
        .toList(growable: false);
  }

  Future<List<GisFeatureModel>> fetchParcelsInBounds({
    required double west,
    required double south,
    required double east,
    required double north,
    int limit = 1800,
  }) async {
    final rows = await _client.rpc(
      'rpc_map_get_parcels_in_bbox_v1',
      params: {
        'min_lng': west,
        'min_lat': south,
        'max_lng': east,
        'max_lat': north,
        'p_limit': limit,
      },
    );
    return _featuresFromRows(
      rows,
      layerKey: 'parcels_registered',
      layerNameAr: 'قطع أراضي التسوية',
    );
  }

  Future<List<GisFeatureModel>> fetchParcelsByLgu({
    required int lguNo,
    double? west,
    double? south,
    double? east,
    double? north,
    int limit = 2000,
  }) async {
    final hasBbox =
        west != null && south != null && east != null && north != null;
    if (hasBbox) {
      try {
        final rows = await _client.rpc(
          'rpc_map_get_parcels_by_lgu_bbox_v1',
          params: {
            'p_lgu_no': lguNo,
            'min_lng': west,
            'min_lat': south,
            'max_lng': east,
            'max_lat': north,
            'p_limit': limit,
          },
        );
        return _featuresFromRows(
          rows,
          layerKey: 'parcels_registered',
          layerNameAr: 'قطع أراضي التسوية',
        );
      } catch (_) {
        // Fallback for databases that have not applied the bbox wrapper yet.
      }
    }

    final rows = await _client.rpc(
      'rpc_map_get_parcels_by_lgu_v1',
      params: {
        'p_lgu_no': lguNo,
        'p_limit': limit,
      },
    );
    return _featuresFromRows(
      rows,
      layerKey: 'parcels_registered',
      layerNameAr: 'قطع أراضي التسوية',
    );
  }

  Future<List<GisFeatureModel>> fetchGuessingBlocksByLgu({
    required int lguNo,
    double? west,
    double? south,
    double? east,
    double? north,
    int limit = 2000,
  }) async {
    final hasBbox =
        west != null && south != null && east != null && north != null;
    if (hasBbox) {
      try {
        final rows = await _client.rpc(
          'rpc_map_get_guessing_blocks_by_lgu_bbox_v1',
          params: {
            'p_lgu_no': lguNo,
            'min_lng': west,
            'min_lat': south,
            'max_lng': east,
            'max_lat': north,
            'p_limit': limit,
          },
        );
        return _featuresFromRows(
          rows,
          layerKey: 'guessing_blocks',
          layerNameAr: 'أحواض التخمين',
        );
      } catch (_) {
        // Fallback for databases that have not applied the bbox wrapper yet.
      }
    }

    final rows = await _client.rpc(
      'rpc_map_get_guessing_blocks_by_lgu_v1',
      params: {
        'p_lgu_no': lguNo,
        'p_limit': limit,
      },
    );
    return _featuresFromRows(
      rows,
      layerKey: 'guessing_blocks',
      layerNameAr: 'أحواض التخمين',
    );
  }

  Future<List<GisFeatureModel>> fetchLocationsInBounds({
    required double west,
    required double south,
    required double east,
    required double north,
    int limit = 1000,
  }) async {
    final rows = await _client.rpc(
      'rpc_map_get_locations_in_bbox_v1',
      params: {
        'min_lng': west,
        'min_lat': south,
        'max_lng': east,
        'max_lat': north,
        'p_limit': limit,
      },
    );
    return _featuresFromRows(
      rows,
      layerKey: 'locations',
      layerNameAr: 'المواقع',
    );
  }

  Future<List<GisFeatureModel>> searchParcels({
    required int lguNo,
    String? blockNo,
    String? quarterName,
    String? parcelNo,
    int limit = 500,
  }) async {
    final rows = await _client.rpc(
      'rpc_map_search_parcels_registered_v1',
      params: {
        'p_lgu_no': lguNo,
        'p_block_no': _emptyToNull(blockNo),
        'p_quarter_name': _emptyToNull(quarterName),
        'p_parcel_no': _emptyToNull(parcelNo),
        'p_limit': limit,
      },
    );
    return _featuresFromRows(
      rows,
      layerKey: 'parcels_registered',
      layerNameAr: 'قطع أراضي التسوية',
    );
  }

  Future<List<GisFeatureModel>> searchGuessingBlocks({
    required int lguNo,
    String? blockNo,
    int limit = 500,
  }) async {
    final rows = await _client.rpc(
      'rpc_map_search_guessing_blocks_v1',
      params: {
        'p_lgu_no': lguNo,
        'p_block_no': _emptyToNull(blockNo),
        'p_limit': limit,
      },
    );
    return _featuresFromRows(
      rows,
      layerKey: 'guessing_blocks',
      layerNameAr: 'أحواض التخمين',
    );
  }

  String? _emptyToNull(String? value) {
    final trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<Map<String, dynamic>?> fetchParcelDetails({
    required String id,
  }) async {
    final parsedId = int.tryParse(id.trim());
    if (parsedId == null) return null;
    final rows = await _client.rpc(
      'rpc_map_get_parcel_details_v1',
      params: {'p_id': parsedId},
    );
    if (rows is List && rows.isNotEmpty) {
      final first = rows.first;
      if (first is Map) {
        final properties = first['properties'];
        if (properties is Map) return properties.cast<String, dynamic>();
      }
    }
    if (rows is Map) {
      final properties = rows['properties'];
      if (properties is Map) return properties.cast<String, dynamic>();
    }
    return null;
  }

  Future<List<GisLayerModel>> fetchLayers({
    bool activeOnly = true,
    bool publicOnly = true,
    String? unitId,
  }) async {
    final safeUnitId = (unitId == null || unitId.trim().isEmpty)
        ? '00000000-0000-0000-0000-000000000000'
        : unitId.trim();

    // Prefer the governed runtime RPC so Dashboard/Layer Manager symbology
    // becomes the single source used by the map. Fallback keeps older DBs safe
    // until the symbology SQL patch is applied.
    try {
      final res = await _client.schema('gis').rpc(
        'rpc_map_layers_runtime_list_v3',
        params: {
          'p_unit_id': safeUnitId,
          'p_active_only': activeOnly,
          'p_public_only': publicOnly,
        },
      );
      final layers = (res as List)
          .map(
              (e) => GisLayerModel.fromJson((e as Map).cast<String, dynamic>()))
          .where((layer) => !_isRetiredNaturalBlocksLayerKey(layer.key))
          .toList();
      return layers;
    } catch (_) {
      try {
        final res = await _client.schema('gis').rpc(
          'rpc_map_layers_runtime_list_v2',
          params: {
            'p_unit_id': safeUnitId,
            'p_active_only': activeOnly,
            'p_public_only': publicOnly,
          },
        );
        final layers = (res as List)
            .map((e) =>
                GisLayerModel.fromJson((e as Map).cast<String, dynamic>()))
            .where((layer) => !_isRetiredNaturalBlocksLayerKey(layer.key))
            .toList();
        return layers;
      } catch (_) {
        try {
          final res = await _client.schema('gis').rpc(
            'rpc_map_layers_runtime_list_v1',
            params: {
              'p_unit_id': safeUnitId,
              'p_active_only': activeOnly,
              'p_public_only': publicOnly,
            },
          );
          final layers = (res as List)
              .map((e) =>
                  GisLayerModel.fromJson((e as Map).cast<String, dynamic>()))
              .where((layer) => !_isRetiredNaturalBlocksLayerKey(layer.key))
              .toList();
          return layers;
        } catch (_) {}
      }

      var q = _client.schema('gis').from('gis_layers').select();

      if (activeOnly) q = q.eq('is_active', true);
      if (publicOnly) q = q.eq('is_public', true);
      if (unitId != null && unitId.isNotEmpty) q = q.eq('unit_id', unitId);

      try {
        final res =
            await q.order('category').order('display_order').order('key');
        final layers = (res as List)
            .map((e) =>
                GisLayerModel.fromJson((e as Map).cast<String, dynamic>()))
            .where((layer) => !_isRetiredNaturalBlocksLayerKey(layer.key))
            .toList();
        return layers;
      } catch (_) {
        final res = await q.order('category').order('key');
        final layers = (res as List)
            .map((e) =>
                GisLayerModel.fromJson((e as Map).cast<String, dynamic>()))
            .where((layer) => !_isRetiredNaturalBlocksLayerKey(layer.key))
            .toList();
        return layers;
      }
    }
  }

  Future<void> updateLayerFlags({
    required String key,
    required String unitId,
    String? layerId,
    bool? isActive,
    bool? isPublic,
  }) async {
    final data = <String, dynamic>{};
    if (isActive != null) data['is_active'] = isActive;
    if (isPublic != null) data['is_public'] = isPublic;
    if (data.isEmpty) return;

    var q = _client.schema('gis').from('gis_layers').update(data);
    if (layerId != null && layerId.isNotEmpty) {
      q = q.eq('id', layerId);
    } else {
      q = q.eq('unit_id', unitId).eq('key', key);
    }
    await q;
  }

  Future<List<GisFeatureModel>> fetchFeaturesInBounds({
    required List<String> layerKeys,
    required double west,
    required double south,
    required double east,
    required double north,
    bool publicOnly = true,
    String unitId = '00000000-0000-0000-0000-000000000000',
    double simplifyMeters = 0,
    int limit = 2000,
  }) async {
    final cleanedLayerKeys = _cleanLayerKeys(layerKeys);
    if (cleanedLayerKeys.isEmpty) return [];

    final params = <String, dynamic>{
      'p_unit_id': unitId,
      'p_west': west,
      'p_south': south,
      'p_east': east,
      'p_north': north,
      'p_layer_keys': cleanedLayerKeys,
      'p_simplify_m': simplifyMeters,
      'p_limit': limit,
    };

    final rows = await _rpcPaged(
      functionName: 'rpc_features_in_bounds',
      params: params,
      requestedLimit: limit,
    );

    return rows
        .map((e) => GisFeatureModel.fromJson(e.cast<String, dynamic>()))
        .where((f) => !publicOnly || f.isPublic)
        .toList();
  }

  Future<List<GisFeatureModel>> fetchLayerFeaturesInBounds({
    required String layerKey,
    required double west,
    required double south,
    required double east,
    required double north,
    String unitId = '00000000-0000-0000-0000-000000000000',
    int limit = 2000,
  }) async {
    final normalizedKey = layerKey.trim();
    if (normalizedKey.isEmpty ||
        _isRetiredNaturalBlocksLayerKey(normalizedKey)) {
      return [];
    }

    // Align single-layer preview/loading with the proven multi-layer rendering
    // RPC. DB testing showed rpc_features_in_bounds returns gis_waqf_% point
    // layers correctly, while older rpc_layer_features_in_bounds definitions
    // can return 0 for the same canonical layer key. This still reads only the
    // sovereign gis.gis_features mirror and creates no alias/fallback key.
    return fetchFeaturesInBounds(
      layerKeys: [normalizedKey],
      west: west,
      south: south,
      east: east,
      north: north,
      unitId: unitId,
      simplifyMeters: 0,
      limit: limit,
    );
  }

  Future<List<SpatialIdentifyHit>> spatialIdentify({
    required double lat,
    required double lng,
    List<String> layerKeys = const [],
    String unitId = '00000000-0000-0000-0000-000000000000',
    double radiusMeters = 80,
    int limit = 8,
  }) async {
    final cleanedLayerKeys = _cleanLayerKeys(layerKeys);
    final rows = await _client.schema('gis').rpc(
      'rpc_spatial_identify_v1',
      params: {
        'p_lat': lat,
        'p_lng': lng,
        'p_layer_keys': cleanedLayerKeys.isEmpty ? null : cleanedLayerKeys,
        'p_unit_id': unitId,
        'p_radius_m': radiusMeters,
        'p_limit': limit,
      },
    );

    if (rows is List) {
      return rows
          .whereType<Map>()
          .map((e) => SpatialIdentifyHit.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    }
    if (rows is Map) {
      return [SpatialIdentifyHit.fromJson(rows.cast<String, dynamic>())];
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> _rpcPaged({
    required String functionName,
    required Map<String, dynamic> params,
    required int requestedLimit,
  }) async {
    // Supabase/PostgREST can cap each client response at 1000 rows even when
    // SQL Editor confirms the RPC itself can return all 6654 natural-block
    // features. Page the API response without changing sovereign SQL data.
    const apiPageSize = 1000;
    final safeLimit = requestedLimit <= 0 ? apiPageSize : requestedLimit;
    final rows = <Map<String, dynamic>>[];

    var from = 0;
    while (from < safeLimit) {
      final remaining = safeLimit - from;
      final pageSize = remaining < apiPageSize ? remaining : apiPageSize;
      final to = from + pageSize - 1;

      final res = await _client
          .schema('gis')
          .rpc(functionName, params: params)
          .range(from, to);

      final page = (res as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList(growable: false);

      rows.addAll(page);
      if (page.length < pageSize) break;
      from += pageSize;
    }

    return rows;
  }

  String _normalizeText(String? value) {
    return (value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _sameText(String? left, String? right) {
    final a = _normalizeText(left);
    final b = _normalizeText(right);
    if (a.isEmpty || b.isEmpty) return false;
    return a == b || a.contains(b) || b.contains(a);
  }

  bool _sameScalar(dynamic left, dynamic right) {
    final a = (left?.toString() ?? '').trim();
    final b = (right?.toString() ?? '').trim();
    if (a.isEmpty || b.isEmpty) return false;
    return a == b;
  }

  bool _isReferenceOnlyCommunity(dynamic value) {
    final code = (value?.toString() ?? '').trim();
    const referenceOnly = <String>{
      '361',
      '362',
      '363',
      '364',
      '365',
      '366',
      '367',
      '368',
      '369',
    };
    return referenceOnly.contains(code);
  }

  bool _isPolygonLike(Map<String, dynamic>? geom) {
    final type = geom?['type'];
    return type == 'Polygon' || type == 'MultiPolygon';
  }

  List<dynamic> _asMultiPolygonCoordinates(Map<String, dynamic>? geom) {
    if (geom == null) return const [];
    final type = geom['type'];
    final coords = geom['coordinates'];
    if (type == 'Polygon' && coords is List && coords.isNotEmpty) {
      return <dynamic>[coords];
    }
    if (type == 'MultiPolygon' && coords is List) {
      return List<dynamic>.from(coords);
    }
    return const [];
  }

  GisFeatureModel _withNaturalOverlayProps(
    GisFeatureModel feature, {
    String? title,
    String? layerNameAr,
    int? featureCount,
  }) {
    final props = <String, dynamic>{
      ...feature.props,
      if (layerNameAr != null && layerNameAr.trim().isNotEmpty)
        'layer_name_ar': layerNameAr.trim(),
      if (featureCount != null) 'feature_count': featureCount,
    };

    return GisFeatureModel(
      id: feature.id,
      layerKey: feature.layerKey,
      titleAr:
          (title ?? '').trim().isNotEmpty ? title!.trim() : feature.titleAr,
      titleEn: feature.titleEn,
      props: props,
      geom: feature.geom,
      centroid: feature.centroid,
      isPublic: feature.isPublic,
    );
  }

  GisFeatureModel? _composeNaturalBlockOverlayFeature(
    List<GisFeatureModel> features, {
    String? blockNo,
    String? siteName,
  }) {
    if (features.isEmpty) return null;

    final polygonFeatures =
        features.where((feature) => _isPolygonLike(feature.geom)).toList();
    final first =
        polygonFeatures.isNotEmpty ? polygonFeatures.first : features.first;
    final normalizedBlockNo =
        (blockNo ?? _naturalBasinNoFromFeature(first)).trim();
    final normalizedSiteName = (siteName ?? '').trim();
    final firstName = _naturalBasinNameFromFeature(first).trim();
    final displayName = normalizedSiteName.isNotEmpty
        ? normalizedSiteName
        : firstName.isNotEmpty
            ? firstName
            : normalizedBlockNo.isNotEmpty
                ? 'حوض $normalizedBlockNo'
                : first.displayTitle;

    if (polygonFeatures.length <= 1) {
      return _withNaturalOverlayProps(
        first,
        title: displayName,
        layerNameAr: normalizedSiteName.isNotEmpty ? 'اسم الحوض' : 'رقم الحوض',
        featureCount: features.length,
      );
    }

    final multiPolygonCoordinates = <dynamic>[];
    for (final feature in polygonFeatures) {
      multiPolygonCoordinates.addAll(_asMultiPolygonCoordinates(feature.geom));
    }

    if (multiPolygonCoordinates.isEmpty) {
      return _withNaturalOverlayProps(
        first,
        title: displayName,
        layerNameAr: normalizedSiteName.isNotEmpty ? 'اسم الحوض' : 'رقم الحوض',
        featureCount: features.length,
      );
    }

    final props = <String, dynamic>{
      ...first.props,
      'block_no': normalizedBlockNo,
      'blockname_': displayName,
      'layer_name_ar':
          normalizedSiteName.isNotEmpty ? 'اسم الحوض' : 'رقم الحوض',
      'feature_count': polygonFeatures.length,
    };

    return GisFeatureModel(
      id: [
        _naturalBlocksLayerKey,
        normalizedBlockNo,
        if (normalizedSiteName.isNotEmpty) normalizedSiteName,
      ].where((part) => part.trim().isNotEmpty).join(':'),
      layerKey: _naturalBlocksLayerKey,
      titleAr: displayName,
      titleEn: first.titleEn,
      props: props,
      geom: <String, dynamic>{
        'type': 'MultiPolygon',
        'coordinates': multiPolygonCoordinates,
      },
      centroid: first.centroid,
      isPublic: polygonFeatures.every((feature) => feature.isPublic),
    );
  }

  Future<List<GisFeatureModel>> _fetchLayerPreviewUniverse({
    required String layerKey,
    String unitId = '00000000-0000-0000-0000-000000000000',
    int limit = 5000,
  }) {
    return fetchLayerFeaturesInBounds(
      layerKey: layerKey,
      west: 34.15,
      south: 31.10,
      east: 35.95,
      north: 32.75,
      unitId: unitId,
      limit: limit,
    );
  }

  Future<GisFeatureModel?> fetchGovernorateBoundaryFeature({
    required String governorateCode,
    required String governorateName,
    String layerKey = 'governorates_boundary',
    String unitId = '00000000-0000-0000-0000-000000000000',
  }) async {
    final features = await _fetchLayerPreviewUniverse(
      layerKey: layerKey,
      unitId: unitId,
      limit: 120,
    );

    for (final feature in features) {
      final props = feature.props;
      final codeCandidates = <String?>[
        props['code']?.toString(),
        props['gov_code']?.toString(),
        props['governorate_code']?.toString(),
        props['governorate_no']?.toString(),
        props['id']?.toString(),
        props['gid']?.toString(),
      ];
      final nameCandidates = <String?>[
        feature.titleAr,
        feature.titleEn,
        props['name_ar']?.toString(),
        props['name_en']?.toString(),
        props['governorate_ar']?.toString(),
        props['governorate_name_ar']?.toString(),
        props['governoraten']?.toString(),
        props['governorate']?.toString(),
        props['name']?.toString(),
      ];

      final hasCode = governorateCode.trim().isNotEmpty;
      final codeMatches =
          codeCandidates.any((value) => _sameScalar(value, governorateCode));
      final nameMatches =
          nameCandidates.any((value) => _sameText(value, governorateName));

      if ((hasCode && codeMatches) || (!hasCode && nameMatches)) {
        final mergedProps = <String, dynamic>{
          ...props,
          'name_ar': (props['name_ar'] ?? governorateName).toString(),
          'layer_name_ar':
              (props['layer_name_ar'] ?? 'حدود المحافظات').toString(),
        };
        return GisFeatureModel(
          id: feature.id,
          layerKey: layerKey,
          titleAr: feature.titleAr?.trim().isNotEmpty == true
              ? feature.titleAr
              : governorateName,
          titleEn: feature.titleEn,
          props: mergedProps,
          geom: feature.geom,
          centroid: feature.centroid,
          isPublic: feature.isPublic,
        );
      }
    }

    return null;
  }

  Future<GisFeatureModel?> fetchCommunityBoundaryFeature({
    required String communityCode,
    required String communityName,
    String layerKey = 'communities_boundary',
    String unitId = '00000000-0000-0000-0000-000000000000',
  }) async {
    final features = await _fetchLayerPreviewUniverse(
      layerKey: layerKey,
      unitId: unitId,
      limit: 4000,
    );

    for (final feature in features) {
      final props = feature.props;
      final codeCandidates = <String?>[
        props['code']?.toString(),
        props['community_code']?.toString(),
        props['locality_code']?.toString(),
        props['community_no']?.toString(),
        props['com_code']?.toString(),
        props['id']?.toString(),
        props['gid']?.toString(),
      ];
      final nameCandidates = <String?>[
        feature.titleAr,
        feature.titleEn,
        props['name_ar']?.toString(),
        props['community_name_ar']?.toString(),
        props['communityn']?.toString(),
        props['locality_name_ar']?.toString(),
        props['community_name']?.toString(),
        props['name']?.toString(),
      ];

      final hasCode = communityCode.trim().isNotEmpty;
      final codeMatches =
          codeCandidates.any((value) => _sameScalar(value, communityCode));
      final nameMatches =
          nameCandidates.any((value) => _sameText(value, communityName));

      if ((hasCode && codeMatches) || (!hasCode && nameMatches)) {
        final mergedProps = <String, dynamic>{
          ...props,
          'name_ar': (props['name_ar'] ?? communityName).toString(),
          'layer_name_ar':
              (props['layer_name_ar'] ?? 'حدود التجمعات').toString(),
        };
        return GisFeatureModel(
          id: feature.id,
          layerKey: layerKey,
          titleAr: feature.titleAr?.trim().isNotEmpty == true
              ? feature.titleAr
              : communityName,
          titleEn: feature.titleEn,
          props: mergedProps,
          geom: feature.geom,
          centroid: feature.centroid,
          isPublic: feature.isPublic,
        );
      }
    }

    return null;
  }

  String _naturalGovernorateFromFeature(GisFeatureModel feature) {
    final props = feature.props;
    final candidates = <String?>[
      props['governorate']?.toString(),
      props['governorate_name_ar']?.toString(),
      props['governorate_ar']?.toString(),
      props['gov_name_ar']?.toString(),
    ];
    for (final value in candidates) {
      final s = (value ?? '').trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  String _naturalCommunityFromFeature(GisFeatureModel feature) {
    final props = feature.props;
    final candidates = <String?>[
      props['communityn']?.toString(),
      props['community_name_ar']?.toString(),
      props['locality_name_ar']?.toString(),
      props['community_name']?.toString(),
      props['locality_name']?.toString(),
    ];
    for (final value in candidates) {
      final s = (value ?? '').trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  String _naturalBasinNameFromFeature(GisFeatureModel feature) {
    final props = feature.props;
    final candidates = <String?>[
      props['blockname_']?.toString(),
      props['block_name']?.toString(),
      props['sitename_a']?.toString(),
      props['site_name_ar']?.toString(),
      props['basin_name']?.toString(),
      props['name_ar']?.toString(),
      feature.titleAr,
      props['name']?.toString(),
    ];
    for (final value in candidates) {
      final s = (value ?? '').trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  String _naturalBasinNoFromFeature(GisFeatureModel feature) {
    final props = feature.props;
    final candidates = <String?>[
      props['block_no']?.toString(),
      props['basin_no']?.toString(),
      props['basin_number']?.toString(),
      props['block_number']?.toString(),
      props['blocknumbe']?.toString(),
    ];
    for (final value in candidates) {
      final s = (value ?? '').trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  Future<List<GisFeatureModel>> _fetchNaturalBlocksUniverse({
    String unitId = '00000000-0000-0000-0000-000000000000',
    int limit = 20000,
  }) {
    return _fetchLayerPreviewUniverse(
      layerKey: _naturalBlocksLayerKey,
      unitId: unitId,
      limit: limit,
    );
  }

  Future<List<LookupItem>> fetchNaturalGovernorates() async {
    final res = await _client
        .schema('gis')
        .from('governorates_boundary')
        .select('governorate_no, governorate, gov_code')
        .order('governorate_no');

    final seen = <String>{};
    final items = <LookupItem>[];
    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      final code = (row['governorate_no']?.toString() ?? '').trim();
      final name = (row['governorate']?.toString() ?? '').trim();
      final govCode = (row['gov_code']?.toString() ?? '').trim();
      if (code.isEmpty || name.isEmpty || !seen.add(code)) continue;
      items.add(LookupItem.fromJson({
        'code': code,
        'id': code,
        'name_ar': name,
        'label_ar': name,
        'governorate': name,
        'governorate_no': row['governorate_no'],
        'gov_code': govCode,
      }));
    }
    _sortLookupItems(items, kind: _LookupKind.governorate);
    return items;
  }

  Future<List<LookupItem>> fetchNaturalCommunitiesByGovernorate({
    required String governorateNo,
  }) async {
    // For the natural-blocks flow, derive the community dropdown from the
    // operational natural_blocks_full table. This keeps reference-only
    // communities out of the modern map while still allowing communities that
    // have blocks but do not yet have a community boundary geometry.
    final res = await _client
        .schema('gis')
        .from(_naturalBlocksLayerKey)
        .select('community_no, communityn, com_code, governorate_no')
        .eq('governorate_no', int.tryParse(governorateNo) ?? -1)
        .order('community_no');

    final seen = <String>{};
    final items = <LookupItem>[];
    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      final code = (row['community_no']?.toString() ?? '').trim();
      final name = (row['communityn']?.toString() ?? '').trim();
      final comCode = (row['com_code']?.toString() ?? '').trim();
      if (code.isEmpty || name.isEmpty || _isReferenceOnlyCommunity(code)) {
        continue;
      }
      if (!seen.add(code)) continue;
      items.add(LookupItem.fromJson({
        'code': code,
        'id': code,
        'name_ar': name,
        'label_ar': name,
        'communityn': name,
        'community_no': row['community_no'],
        'com_code': comCode,
        'parent_code': governorateNo,
      }));
    }
    items.sort((a, b) => a.bestLabel.compareTo(b.bestLabel));
    return items;
  }

  Future<List<LookupItem>> fetchNaturalBlockNumbers({
    required String governorateNo,
    required String communityNo,
  }) async {
    final res = await _client
        .schema('gis')
        .from(_naturalBlocksLayerKey)
        .select('block_no, blockname_, governorate_no, community_no')
        .eq('governorate_no', int.tryParse(governorateNo) ?? -1)
        .eq('community_no', int.tryParse(communityNo) ?? -1)
        .order('block_no');

    final seen = <String>{};
    final items = <LookupItem>[];
    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      final blockNo = (row['block_no']?.toString() ?? '').trim();
      if (blockNo.isEmpty || !seen.add(blockNo)) continue;
      final blockName = (row['blockname_']?.toString() ?? '').trim();
      items.add(LookupItem.fromJson({
        'code': blockNo,
        'id': blockNo,
        'name_ar': blockName.isEmpty ? blockNo : blockName,
        'label_ar': blockName.isEmpty ? blockNo : blockName,
        'block_no': row['block_no'],
        'blockname_': blockName,
        'governorate_no': row['governorate_no'],
        'community_no': row['community_no'],
      }));
    }
    items.sort((a, b) =>
        (int.tryParse(a.code) ?? 0).compareTo(int.tryParse(b.code) ?? 0));
    return items;
  }

  Future<List<LookupItem>> fetchNaturalSiteNames({
    required String governorateNo,
    required String communityNo,
    required String blockNo,
  }) async {
    final res = await _client
        .schema('gis')
        .from(_naturalBlocksLayerKey)
        .select(
            'block_no, blockname_, sitename_a, governorate_no, community_no')
        .eq('governorate_no', int.tryParse(governorateNo) ?? -1)
        .eq('community_no', int.tryParse(communityNo) ?? -1)
        .eq('block_no', int.tryParse(blockNo) ?? -1)
        .order('blockname_');

    final seen = <String>{};
    final items = <LookupItem>[];
    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      final siteName = ((row['blockname_']?.toString() ?? '').trim().isNotEmpty
                  ? row['blockname_']?.toString()
                  : row['sitename_a']?.toString())
              ?.trim() ??
          '';
      if (siteName.isEmpty || !seen.add(siteName)) continue;
      items.add(LookupItem.fromJson({
        'code': siteName,
        'id': siteName,
        'name_ar': siteName,
        'label_ar': siteName,
        'block_no': row['block_no'],
        'blockname_': row['blockname_'],
        'sitename_a': row['sitename_a'],
        'governorate_no': row['governorate_no'],
        'community_no': row['community_no'],
      }));
    }
    items.sort((a, b) => a.bestLabel.compareTo(b.bestLabel));
    return items;
  }

  Future<List<LookupItem>> fetchNaturalBasins({
    required String governorateNo,
    required String communityNo,
  }) async {
    final res = await _client
        .schema('gis')
        .from(_naturalBlocksLayerKey)
        .select(
            'blockname_, sitename_a, block_no, governorate_no, community_no')
        .eq('governorate_no', int.tryParse(governorateNo) ?? -1)
        .eq('community_no', int.tryParse(communityNo) ?? -1)
        .order('block_no');

    final seen = <String>{};
    final items = <LookupItem>[];
    for (final row in (res as List).cast<Map<String, dynamic>>()) {
      final blockNo = (row['block_no']?.toString() ?? '').trim();
      final blockName =
          (((row['blockname_']?.toString() ?? '').trim().isNotEmpty
                      ? row['blockname_']?.toString()
                      : row['sitename_a']?.toString()) ??
                  '')
              .trim();
      if (blockNo.isEmpty || blockName.isEmpty || !seen.add(blockNo)) continue;
      items.add(LookupItem.fromJson({
        'code': blockNo,
        'id': blockNo,
        'name_ar': blockName,
        'label_ar': blockName,
        'block_no': row['block_no'],
        'blockname_': blockName,
        'governorate_no': row['governorate_no'],
        'community_no': row['community_no'],
      }));
    }
    return items;
  }

  Future<GisFeatureModel?> fetchNaturalBlockFeature({
    String? governorateNo,
    String? communityNo,
    String? blockNo,
    String? siteName,
    String unitId = '00000000-0000-0000-0000-000000000000',
  }) async {
    final results = await searchNaturalBlocks(
      governorateNo: governorateNo,
      communityNo: communityNo,
      blockNo: blockNo,
      siteName: siteName,
      limit: 500,
      unitId: unitId,
    );
    return _composeNaturalBlockOverlayFeature(
      results,
      blockNo: blockNo,
      siteName: siteName,
    );
  }

  Future<List<GisFeatureModel>> searchNaturalBlocks({
    String? governorateNo,
    String? communityNo,
    String? blockNo,
    String? siteName,
    int limit = 80,
    String unitId = '00000000-0000-0000-0000-000000000000',
  }) async {
    final features = await _fetchNaturalBlocksUniverse(unitId: unitId);

    bool matchesFeature(GisFeatureModel feature) {
      final props = feature.props;
      final featureGovNo = props['governorate_no'];
      final featureCommunityNo = props['community_no'];
      final featureBasinNo = _naturalBasinNoFromFeature(feature);
      final featureBasinName = _naturalBasinNameFromFeature(feature);

      if (_isReferenceOnlyCommunity(featureCommunityNo)) return false;

      final matchesGovernorate = (governorateNo ?? '').trim().isEmpty ||
          _sameScalar(featureGovNo, governorateNo);
      final matchesCommunity = (communityNo ?? '').trim().isEmpty ||
          _sameScalar(featureCommunityNo, communityNo);
      final matchesBasinNo = (blockNo ?? '').trim().isEmpty ||
          _sameScalar(featureBasinNo, blockNo);
      final matchesBasinName = (siteName ?? '').trim().isEmpty ||
          _sameText(featureBasinName, siteName);

      return matchesGovernorate &&
          matchesCommunity &&
          matchesBasinNo &&
          matchesBasinName;
    }

    final filtered = features.where(matchesFeature).toList()
      ..sort((a, b) {
        final noA = int.tryParse(_naturalBasinNoFromFeature(a)) ?? 0;
        final noB = int.tryParse(_naturalBasinNoFromFeature(b)) ?? 0;
        if (noA != noB) return noA.compareTo(noB);
        return _naturalBasinNameFromFeature(a)
            .compareTo(_naturalBasinNameFromFeature(b));
      });

    if (filtered.length <= limit) return filtered;
    return filtered.take(limit).toList();
  }

  Future<List<LookupItem>> fetchModernExplorerGovernoratesFromGis() async {
    // Sovereign lookup source for the Modern Explorer governorate dropdown:
    // read the actual GIS governorates table first, and exclude rows without
    // geometry. Do not search in free text fields such as about, because they
    // can mention another governorate and pollute the dropdown/filter.
    try {
      final res = await _client
          .schema('gis')
          .from('governorates_boundary')
          .select(
            'governorate_no, governorate, governorate_english, gov_code, '
            'part_arabic, governorate_type',
          )
          .not('geom', 'is', null)
          .limit(200);
      final items = _lookupItemsFromRows(res, kind: _LookupKind.governorate)
          .where(_isModernGovernorateLookupItem)
          .toList(growable: false);
      if (items.isNotEmpty) return items;
    } catch (_) {}

    // Fallback to the renderable GIS feature mirror only if direct table access
    // is unavailable.
    final boundaryFeatures = await _fetchBoundaryLayerFeatures(
      layerKeys: const ['governorates_boundary', 'v_governorates_core'],
      limit: 5000,
    );
    final fromGeometry = _lookupItemsFromFeatures(
      boundaryFeatures
          .where(_isRenderableGovernorateFeature)
          .toList(growable: false),
      kind: _LookupKind.governorate,
    ).where(_isModernGovernorateLookupItem).toList(growable: false);
    if (fromGeometry.isNotEmpty) return fromGeometry;

    try {
      final res = await _client.schema('gis').rpc(
            'rpc_modern_explorer_governorates_v1',
          );
      final items = _lookupItemsFromRows(res, kind: _LookupKind.governorate)
          .where(_isModernGovernorateLookupItem)
          .toList(growable: false);
      if (items.isNotEmpty) return items;
    } catch (_) {}

    return const [];
  }

  Future<List<LookupItem>> fetchModernExplorerLgusFromGis({
    String? governorateNo,
  }) async {
    final gov = (governorateNo ?? '').trim();

    // Public runtime source: use the renderable GIS feature mirror first.
    // Direct gis.lgus_boundary table access can be denied for public roles.
    final boundaryFeatures = await _fetchBoundaryLayerFeatures(
      layerKeys: const ['lgus_boundary', 'v_lgus_core', 'v_lgus_light'],
      limit: 12000,
    );
    final renderableLguFeatures = boundaryFeatures.where((feature) {
      if (!_isRenderableLguFeature(feature)) return false;
      if (gov.isEmpty) return true;
      return _sameScalar(_pickRaw(feature.props, _governorateCodeKeys), gov) ||
          _sameScalar(_pickRaw(feature.props, const ['parent_code']), gov) ||
          _sameText(_pickString(feature.props, _governorateLabelKeys), gov);
    }).toList(growable: false);
    var fromFeatures = _lookupItemsFromFeatures(
      renderableLguFeatures,
      kind: _LookupKind.lgu,
    );

    if (gov.isNotEmpty) {
      fromFeatures = fromFeatures.where((item) {
        final parent = item.parentCode ?? '';
        return _sameScalar(parent, gov) ||
            _normalizeText(parent).contains(_normalizeText(gov));
      }).toList(growable: false);
    }
    if (fromFeatures.isNotEmpty) return fromFeatures;

    try {
      final res = await _client.schema('gis').rpc(
        'rpc_modern_explorer_lgus_v1',
        params: {
          'p_governorate_no': gov.isEmpty ? null : gov,
        },
      );
      final items = _lookupItemsFromRows(res, kind: _LookupKind.lgu);
      if (items.isNotEmpty) return items;
    } catch (_) {}

    // Last fallback only: direct table access may be denied for public/runtime roles.
    try {
      final res = await _client
          .schema('gis')
          .from('lgus_boundary')
          .select(
            'lgus_code, lgus_xcode, lgusn, governorate_no, governorate, '
            'governor01, community_no, communityn',
          )
          .not('geom', 'is', null)
          .limit(5000);

      final rows = (res)
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .where((row) {
        if (gov.isEmpty) return true;
        return _sameScalar(row['governorate_no'], gov) ||
            _sameScalar(row['gov_code'], gov) ||
            _sameText(row['governorate']?.toString(), gov) ||
            _sameText(row['governor01']?.toString(), gov);
      }).toList(growable: false);

      final items = _lookupItemsFromRows(rows, kind: _LookupKind.lgu);
      if (items.isNotEmpty) return items;
    } catch (_) {}

    return const [];
  }

  bool _featureHasRenderableGeometry(GisFeatureModel feature) {
    return feature.geom != null || feature.centroid != null;
  }

  bool _isRenderableGovernorateFeature(GisFeatureModel feature) {
    if (!_featureHasRenderableGeometry(feature)) return false;
    final haystack = _normalizeText(
      '${feature.layerKey} ${feature.titleAr ?? ''} ${feature.props.values.join(' ')}',
    );

    const blockedTerms = [
      'تاريخ',
      'عثمان',
      'انتداب',
      'لواء',
      'سنجق',
      'قضاء تاريخي',
      'historical',
      'ottoman',
      'mandate',
    ];
    if (blockedTerms.any(haystack.contains)) return false;

    return _isModernGovernorateName(haystack);
  }

  bool _isRenderableLguFeature(GisFeatureModel feature) {
    if (!_featureHasRenderableGeometry(feature)) return false;
    final label = _pickLookupLabel(feature.props, _lguLabelKeys, code: '');
    if (label.isEmpty) return false;
    return !_isModernGovernorateName(_normalizeText(label));
  }

  bool _isModernGovernorateLookupItem(LookupItem item) {
    final text = _normalizeText('${item.bestLabel} ${item.labelEn ?? ''}');
    return _isModernGovernorateName(text);
  }

  bool _isModernGovernorateName(String normalizedText) {
    if (normalizedText.isEmpty) return false;
    const terms = [
      'الخليل',
      'بيت لحم',
      'القدس',
      'اريحا',
      'الاغوار',
      'رام الله',
      'البيره',
      'سلفيت',
      'قلقيليه',
      'نابلس',
      'طوباس',
      'طولكرم',
      'جنين',
      'شمال غزه',
      'غزه',
      'دير البلح',
      'خان يونس',
      'خانيونس',
      'رفح',
      'hebron',
      'bethlehem',
      'jerusalem',
      'jericho',
      'ramallah',
      'al-bireh',
      'albireh',
      'salfit',
      'qalqilya',
      'nablus',
      'tubas',
      'tulkarm',
      'jenin',
      'north gaza',
      'gaza',
      'deir al-balah',
      'deir albalah',
      'khan yunis',
      'khan younis',
      'rafah',
    ];
    return terms.any(normalizedText.contains);
  }

  List<GisFeatureModel> _gisFeaturesFromRows(dynamic res) {
    if (res is! List) return const [];
    return res
        .whereType<Map>()
        .map((entry) => GisFeatureModel.fromJson(entry.cast<String, dynamic>()))
        .where((feature) => feature.geom != null)
        .toList(growable: false);
  }

  Future<List<GisFeatureModel>> fetchModernExplorerGovernorateBoundaryFeatures({
    String? governorateNo,
  }) async {
    // Use the same layer-feature RPC that already renders public map layers.
    final features = (await _fetchBoundaryLayerFeatures(
      layerKeys: const ['governorates_boundary', 'v_governorates_core'],
      limit: 5000,
    ))
        .where(_isRenderableGovernorateFeature)
        .toList(growable: false);
    final gov = (governorateNo ?? '').trim();
    if (features.isNotEmpty) {
      if (gov.isEmpty) return features;
      return features.where((feature) {
        final p = feature.props;
        return _sameScalar(_pickRaw(p, _governorateCodeKeys), gov) ||
            _sameScalar(_pickRaw(p, const ['code', 'id']), gov) ||
            _sameText(_pickString(p, _governorateLabelKeys), gov);
      }).toList(growable: false);
    }

    // Optional helper if installed later.
    try {
      final res = await _client.schema('gis').rpc(
        'rpc_modern_explorer_governorate_features_v1',
        params: {'p_governorate_no': gov.isEmpty ? null : gov},
      );
      return _gisFeaturesFromRows(res);
    } catch (_) {
      return const [];
    }
  }

  Future<List<GisFeatureModel>> fetchModernExplorerLguBoundaryFeatures({
    String? governorateNo,
    String? lguCode,
  }) async {
    // Use the same layer-feature RPC that already renders public map layers.
    final features = (await _fetchBoundaryLayerFeatures(
      layerKeys: const ['lgus_boundary', 'v_lgus_core', 'v_lgus_light'],
      limit: 12000,
    ))
        .where(_isRenderableLguFeature)
        .toList(growable: false);
    final gov = (governorateNo ?? '').trim();
    final lgu = (lguCode ?? '').trim();
    if (features.isNotEmpty) {
      return features.where((feature) {
        final p = feature.props;
        final matchesGov = gov.isEmpty ||
            _sameScalar(_pickRaw(p, _governorateCodeKeys), gov) ||
            _sameScalar(_pickRaw(p, const ['parent_code']), gov) ||
            _sameText(_pickString(p, _governorateLabelKeys), gov);
        final matchesLgu = lgu.isEmpty ||
            _sameScalar(_pickRaw(p, _lguCodeKeys), lgu) ||
            _sameScalar(_pickRaw(p, const ['code', 'id']), lgu) ||
            _sameText(_pickString(p, _lguLabelKeys), lgu);
        return matchesGov && matchesLgu;
      }).toList(growable: false);
    }

    // Optional helper if installed later.
    try {
      final res = await _client.schema('gis').rpc(
        'rpc_modern_explorer_lgu_features_v1',
        params: {
          'p_governorate_no': gov.isEmpty ? null : gov,
          'p_lgu_code': lgu.isEmpty ? null : lgu,
        },
      );
      return _gisFeaturesFromRows(res);
    } catch (_) {
      return const [];
    }
  }

  Future<List<GisFeatureModel>> _fetchBoundaryLayerFeatures({
    required List<String> layerKeys,
    required int limit,
  }) {
    return fetchFeaturesInBounds(
      layerKeys: layerKeys,
      unitId: '00000000-0000-0000-0000-000000000000',
      west: 34.0,
      south: 29.0,
      east: 36.0,
      north: 34.0,
      simplifyMeters: 0,
      limit: limit,
    );
  }

  static const List<String> _governorateCodeKeys = [
    'governorate_no',
    'governoratename_no',
    'gov_no',
    'gov_code',
    'governorate_code',
    'code',
  ];

  static const List<String> _governorateLabelKeys = [
    // Keep real name fields before title_ar. In the public GIS feature mirror,
    // title_ar may be a numeric source title/code for boundary features.
    'name_ar',
    'label_ar',
    'governorate_name_ar',
    'governorate_name',
    'governorate_ar',
    'governorate',
    'governorat',
    'governoraten',
    'gov_name_ar',
    'gov_name',
    'name',
    'title_ar',
  ];

  static const List<String> _lguCodeKeys = [
    'lgusb_no',
    'lgus_code',
    'lgus_xcode',
    'lgu_code',
    'lgu_no',
    'lgu_id',
    'municipality_code',
    'municipality_no',
    'locality_code',
    'code',
    'id',
  ];

  static const List<String> _lguLabelKeys = [
    // Prefer locality/LGU-specific labels. Generic name_ar/title_ar can be the
    // governorate name in some GIS mirrors, so they stay near the end.
    'lgusn',
    'lgun',
    'lgu_name_ar',
    'lgu_name',
    'lgus_name_ar',
    'lgus_name',
    'municipality_name_ar',
    'municipality_name',
    'locality_name_ar',
    'locality_name',
    'local_body_name_ar',
    'local_body_name',
    'town_name_ar',
    'town_name',
    'village_name_ar',
    'village_name',
    'site_name_ar',
    'site_name',
    'nname',
    'name_ar',
    'label_ar',
    'name',
    'title_ar',
  ];

  static const List<String> _locationCodeKeys = [
    'location_no',
    'location_code',
    'location_id',
    'loc_no',
    'loc_code',
    'site_no',
    'site_code',
    'area_no',
    'area_code',
    'code',
    'id',
    'gid',
  ];

  static const List<String> _locationLabelKeys = [
    'location_name_ar',
    'location_name',
    'loc_name_ar',
    'loc_name',
    'site_name_ar',
    'site_name',
    'site_ar',
    'location',
    'adress',
    'address',
    'area_name_ar',
    'area_name',
    'name_ar',
    'label_ar',
    'name',
    'title_ar',
  ];

  static const List<String> _locationLguCodeKeys = [
    'lgusb_no',
    'lgus_no',
    'lgus_code',
    'lgus_xcode',
    'lgu_no',
    'lgu_code',
    'lgu_id',
    'municipality_no',
    'municipality_code',
    'local_body_code',
  ];

  dynamic _pickRaw(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      if (!row.containsKey(key)) continue;
      final value = row[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') continue;
      return value;
    }
    return null;
  }

  String _pickString(Map<String, dynamic> row, List<String> keys) {
    final value = _pickRaw(row, keys);
    return value?.toString().trim() ?? '';
  }

  bool _looksLikeCodeOnlyLabel(String value) {
    final text = value.trim();
    if (text.isEmpty) return true;
    if (RegExp(r'^\d+(?:\.0+)?$').hasMatch(text)) return true;
    if (text.toLowerCase() == 'null') return true;
    return false;
  }

  String _pickLookupLabel(
    Map<String, dynamic> row,
    List<String> keys, {
    required String code,
  }) {
    for (final key in keys) {
      if (!row.containsKey(key)) continue;
      final value = row[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') continue;
      if (code.trim().isNotEmpty && text == code.trim()) continue;
      if (_looksLikeCodeOnlyLabel(text)) continue;
      return text;
    }
    return '';
  }

  List<LookupItem> _lookupItemsFromFeatures(
    List<GisFeatureModel> features, {
    required _LookupKind kind,
  }) {
    final rows = features.map((feature) {
      return <String, dynamic>{
        ...feature.props,
        // Do not overwrite a source title_ar/name if it exists in props.
        'title_ar': feature.props['title_ar'] ?? feature.titleAr,
        'title_en': feature.props['title_en'] ?? feature.titleEn,
        'feature_title_ar': feature.titleAr,
        'feature_title_en': feature.titleEn,
        'layer_key': feature.layerKey,
      };
    }).toList(growable: false);
    return _lookupItemsFromRows(rows, kind: kind);
  }

  List<LookupItem> _lookupItemsFromRows(
    dynamic res, {
    required _LookupKind kind,
  }) {
    if (res is! List) return const [];
    final seen = <String>{};
    final items = <LookupItem>[];
    for (final entry in res) {
      if (entry is! Map) continue;
      final raw = entry.cast<String, dynamic>();
      final code = kind == _LookupKind.governorate
          ? _pickString(raw, _governorateCodeKeys)
          : _pickString(raw, _lguCodeKeys);
      final label = kind == _LookupKind.governorate
          ? _pickLookupLabel(raw, _governorateLabelKeys, code: code)
          : _pickLookupLabel(raw, _lguLabelKeys, code: code);
      final parentCode =
          kind == _LookupKind.lgu ? _pickString(raw, _governorateCodeKeys) : '';
      final parentLabel = kind == _LookupKind.lgu
          ? _pickLookupLabel(raw, _governorateLabelKeys, code: parentCode)
          : '';
      final parent = [parentCode, parentLabel]
          .where((value) => value.trim().isNotEmpty)
          .join(' | ');
      if (code.isEmpty || label.isEmpty) continue;
      if (kind == _LookupKind.lgu) {
        final normalizedLabel = _normalizeText(label);
        final normalizedParent = _normalizeText(parentLabel);
        if (normalizedParent.isNotEmpty &&
            normalizedLabel == normalizedParent) {
          continue;
        }
        if (_isModernGovernorateName(normalizedLabel)) continue;
      }
      final marker = '${kind.name}|$code';
      if (!seen.add(marker)) continue;
      items.add(
        LookupItem(
          code: code,
          labelAr: label,
          parentCode: parent.isEmpty ? null : parent,
        ),
      );
    }
    _sortLookupItems(items, kind: kind);
    return items;
  }

  void _sortLookupItems(
    List<LookupItem> items, {
    required _LookupKind kind,
  }) {
    int regionGroup(LookupItem item) {
      final haystack = _normalizeText(
        '${item.bestLabel} ${item.labelEn ?? ''} ${item.parentCode ?? ''}',
      );
      const gazaTerms = [
        'غزه',
        'gaza',
        'شمال غزه',
        'دير البلح',
        'خانيونس',
        'خان يونس',
        'رفح',
      ];
      return gazaTerms.any(haystack.contains) ? 1 : 0;
    }

    items.sort((a, b) {
      final groupA = regionGroup(a);
      final groupB = regionGroup(b);
      if (groupA != groupB) return groupA.compareTo(groupB);
      final labelCompare = a.bestLabel.compareTo(b.bestLabel);
      if (labelCompare != 0) return labelCompare;
      return a.code.compareTo(b.code);
    });
  }

  bool _locationFeatureMatchesLgu(
    GisFeatureModel feature,
    String lguCode,
  ) {
    final target = lguCode.trim();
    if (target.isEmpty) return true;
    final props = feature.props;
    return _sameScalar(_pickRaw(props, _locationLguCodeKeys), target) ||
        _sameScalar(_pickRaw(props, _lguCodeKeys), target) ||
        _sameText(_pickString(props, _lguLabelKeys), target) ||
        _sameScalar(_pickRaw(props, const ['parent_code']), target);
  }

  Future<List<LookupItem>> fetchLocationLookupsByLgu({
    required String lguCode,
    int limit = 5000,
  }) async {
    final target = lguCode.trim();
    if (target.isEmpty) return const <LookupItem>[];

    final features = await _fetchLayerPreviewUniverse(
      layerKey: 'locations',
      limit: limit,
    );
    final filtered = features
        .where((feature) => _locationFeatureMatchesLgu(feature, target))
        .toList(growable: false);

    final seen = <String>{};
    final items = <LookupItem>[];
    for (final feature in filtered) {
      final props = feature.props;
      var code = _pickString(props, _locationCodeKeys);
      if (code.isEmpty) code = feature.id.trim();
      var label = _pickLookupLabel(props, _locationLabelKeys, code: code);
      if (label.isEmpty) label = feature.displayTitle.trim();
      if (code.isEmpty) code = label;
      if (code.isEmpty || label.isEmpty) continue;

      final marker = '${_normalizeText(code)}|${_normalizeText(label)}';
      if (!seen.add(marker)) continue;
      final parentCode = _pickString(props, _locationLguCodeKeys);
      items.add(
        LookupItem(
          code: code,
          labelAr: label,
          parentCode: parentCode.isEmpty ? target : parentCode,
        ),
      );
    }
    items.sort((a, b) => a.bestLabel.compareTo(b.bestLabel));
    return items;
  }

  Future<GisFeatureModel?> fetchLocationBoundaryFeature({
    required String locationCode,
    required String locationName,
    String? lguCode,
    int limit = 5000,
  }) async {
    final code = locationCode.trim();
    final name = locationName.trim();
    if (code.isEmpty && name.isEmpty) return null;

    final features = await _fetchLayerPreviewUniverse(
      layerKey: 'locations',
      limit: limit,
    );
    final targetLgu = (lguCode ?? '').trim();

    for (final feature in features) {
      if (!_locationFeatureMatchesLgu(feature, targetLgu)) continue;
      final props = feature.props;
      final featureCode = _pickString(props, _locationCodeKeys);
      final featureLabel = _pickLookupLabel(
        props,
        _locationLabelKeys,
        code: featureCode,
      );
      final codeMatches = code.isNotEmpty &&
          (_sameScalar(featureCode, code) || _sameScalar(feature.id, code));
      final nameMatches = name.isNotEmpty &&
          (_sameText(featureLabel, name) ||
              _sameText(feature.titleAr, name) ||
              _sameText(feature.displayTitle, name));
      if (!codeMatches && !nameMatches) continue;

      final displayName = featureLabel.isNotEmpty
          ? featureLabel
          : name.isNotEmpty
              ? name
              : feature.displayTitle;
      return GisFeatureModel(
        id: feature.id,
        layerKey: 'locations',
        titleAr: displayName,
        titleEn: feature.titleEn,
        props: <String, dynamic>{
          ...props,
          'name_ar': (props['name_ar'] ?? displayName).toString(),
          'layer_name_ar': (props['layer_name_ar'] ?? 'المواقع').toString(),
        },
        geom: feature.geom,
        centroid: feature.centroid,
        isPublic: feature.isPublic,
      );
    }
    return null;
  }

  Future<List<GisFeatureModel>> searchExplorerNavigationFeatures({
    required String query,
    int limit = 18,
  }) async {
    final needle = _normalizeText(query);
    if (needle.length < 2) return const <GisFeatureModel>[];

    bool matches(GisFeatureModel feature, String layerLabel) {
      final values = <String>[
        feature.id,
        feature.layerKey,
        feature.displayTitle,
        feature.titleAr ?? '',
        feature.titleEn ?? '',
        feature.layerNameAr ?? '',
        feature.layerNameEn ?? '',
        layerLabel,
      ];
      for (final entry in feature.props.entries) {
        final value = entry.value;
        if (value == null || value is Map || value is Iterable) continue;
        values.add(entry.key);
        values.add(value.toString());
      }
      final haystack = _normalizeText(values.join(' '));
      return haystack.contains(needle);
    }

    GisFeatureModel withNavigationLabel(
      GisFeatureModel feature,
      String layerLabel,
      String targetKind,
    ) {
      return GisFeatureModel(
        id: feature.id,
        layerKey: feature.layerKey,
        titleAr: feature.titleAr,
        titleEn: feature.titleEn,
        props: <String, dynamic>{
          ...feature.props,
          'layer_name_ar':
              (feature.props['layer_name_ar'] ?? layerLabel).toString(),
          'navigation_target_kind': targetKind,
          'navigation_only': true,
        },
        geom: feature.geom,
        centroid: feature.centroid,
        isPublic: feature.isPublic,
      );
    }

    final output = <GisFeatureModel>[];
    final seen = <String>{};

    void addMatches(
      Iterable<GisFeatureModel> features, {
      required String layerLabel,
      required String targetKind,
    }) {
      for (final feature in features) {
        if (output.length >= limit) return;
        if (!matches(feature, layerLabel)) continue;
        final marker =
            '${feature.layerKey.trim().toLowerCase()}::${feature.id}';
        if (!seen.add(marker)) continue;
        output.add(withNavigationLabel(feature, layerLabel, targetKind));
      }
    }

    try {
      addMatches(
        await fetchModernExplorerGovernorateBoundaryFeatures(),
        layerLabel: 'محافظة',
        targetKind: 'governorate',
      );
    } catch (_) {}

    if (output.length < limit) {
      try {
        addMatches(
          await fetchModernExplorerLguBoundaryFeatures(),
          layerLabel: 'هيئة محلية / تجمع',
          targetKind: 'lgu',
        );
      } catch (_) {}
    }

    if (output.length < limit) {
      try {
        addMatches(
          await _fetchLayerPreviewUniverse(
              layerKey: 'communities_boundary', limit: 8000),
          layerLabel: 'تجمع',
          targetKind: 'community',
        );
      } catch (_) {}
    }

    if (output.length < limit) {
      try {
        addMatches(
          await _fetchLayerPreviewUniverse(layerKey: 'locations', limit: 5000),
          layerLabel: 'موقع',
          targetKind: 'location',
        );
      } catch (_) {}
    }

    final looksLikeOperationalBlockQuery =
        RegExp(r'\d').hasMatch(query) || needle.length >= 4;
    if (looksLikeOperationalBlockQuery && output.length < limit) {
      try {
        addMatches(
          await _fetchLayerPreviewUniverse(
              layerKey: 'guessing_blocks', limit: 7000),
          layerLabel: 'حوض تخمين',
          targetKind: 'guessing_block',
        );
      } catch (_) {}
    }

    if (looksLikeOperationalBlockQuery && output.length < limit) {
      try {
        addMatches(
          await _fetchNaturalBlocksUniverse(),
          layerLabel: 'حوض طبيعي',
          targetKind: 'natural_block',
        );
      } catch (_) {}
    }

    output.sort((a, b) {
      int score(GisFeatureModel feature) {
        final title = _normalizeText(feature.displayTitle);
        final kind = (feature.props['navigation_target_kind'] ?? '').toString();
        var value = 10;
        if (title == needle) value -= 6;
        if (title.startsWith(needle)) value -= 3;
        if (kind == 'governorate') value -= 2;
        if (kind == 'lgu') value -= 1;
        return value;
      }

      final byScore = score(a).compareTo(score(b));
      if (byScore != 0) return byScore;
      return a.displayTitle.compareTo(b.displayTitle);
    });

    return output.length <= limit
        ? output
        : output.take(limit).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> searchPlaces({
    required String query,
    int limit = 8,
  }) async {
    final res = await _client.schema('gis').rpc(
      'rpc_place_search',
      params: {
        'p_query': query,
        'p_limit': limit,
      },
    );

    return (res as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }
}
