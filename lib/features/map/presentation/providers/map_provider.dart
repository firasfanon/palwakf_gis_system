// lib/features/map/presentation/providers/map_provider.dart
import 'dart:async';
import 'dart:collection';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/repositories/gis_repository.dart';
import '../../data/repositories/waqf_repository.dart';
import '../../domain/models/gis_feature_model.dart';
import '../../domain/models/gis_layer_model.dart';
import '../../domain/models/waqf_model.dart';
import '../../../../core/constants/enums.dart';

final mapControllerProvider = Provider<MapController>((ref) {
  return MapController();
});

final mapNotifierProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier(
    waqfRepository: ref.watch(waqfRepositoryProvider),
    gisRepository: ref.watch(gisRepositoryProvider),
  );
});

class ViewportBounds {
  final double west;
  final double south;
  final double east;
  final double north;

  const ViewportBounds({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  bool nearlyEquals(ViewportBounds other, {double eps = 1e-6}) {
    return (west - other.west).abs() < eps &&
        (south - other.south).abs() < eps &&
        (east - other.east).abs() < eps &&
        (north - other.north).abs() < eps;
  }
}

class MapRuntimeInfo {
  final List<String> requestedLayerKeys;
  final List<String> queryLayerKeys;
  final List<String> blockedLayerKeys;
  final List<String> blockedReasons;
  final bool usingNaturalBlocksOverview;
  final bool servedFromCache;
  final double simplifyMeters;
  final int featureLimit;
  final int featureCount;
  final double boundsPadding;

  const MapRuntimeInfo({
    this.requestedLayerKeys = const [],
    this.queryLayerKeys = const [],
    this.blockedLayerKeys = const [],
    this.blockedReasons = const [],
    this.usingNaturalBlocksOverview = false,
    this.servedFromCache = false,
    this.simplifyMeters = 0,
    this.featureLimit = 0,
    this.featureCount = 0,
    this.boundsPadding = 0,
  });

  bool get hasBlockedLayers => blockedLayerKeys.isNotEmpty;
  bool get hasQueryLayers => queryLayerKeys.isNotEmpty;
}

class MapState {
  final List<WaqfModel> waqfResults;
  final WaqfModel? selectedWaqf;

  final List<GisLayerModel> gisLayers;
  final List<GisFeatureModel> gisFeatures;
  final GisFeatureModel? selectedFeature;
  final GisFeatureModel? governoratePreviewFeature;
  final GisFeatureModel? communityPreviewFeature;
  final GisFeatureModel? blockPreviewFeature;
  final GisFeatureModel? sitePreviewFeature;

  /// Geometry overlays controlled by the Modern Explorer filters.
  /// These are direct sovereign GIS boundary previews for governorates and LGUs.
  final List<GisFeatureModel> modernExplorerBoundaryFeatures;

  final bool isLoading;
  final String? error;

  final bool gisLoading;
  final String? gisError;

  final LatLng? currentLocation;
  final double zoom;
  final LayerCategory activeCategory;
  final List<String> activeLayers;
  final Map<String, double> layerOpacity;

  /// Optional operational scope for heavy settlement/parcel layers.
  /// When null, zoom-driven settlement layers stay blocked so the map never
  /// loads parcel/taswyeh data for all local authorities at once.
  final String? settlementScopeLguCode;
  final String? settlementScopeLguName;

  /// Temporary reference layer opened only by the Search tab context.
  /// It is intentionally separate from activeLayers so search can expose
  /// reference basins without mutating the sovereign zoom-driven layer state.
  final String? temporarySearchReferenceLayerKey;
  final String? temporarySearchReferenceLayerLabel;

  final MapRuntimeInfo runtimeInfo;

  final ViewportBounds? viewport;

  final bool showSwipeComparison;
  final String? leftLayer;
  final String? rightLayer;

  const MapState({
    this.waqfResults = const [],
    this.selectedWaqf,
    this.gisLayers = const [],
    this.gisFeatures = const [],
    this.selectedFeature,
    this.governoratePreviewFeature,
    this.communityPreviewFeature,
    this.blockPreviewFeature,
    this.sitePreviewFeature,
    this.modernExplorerBoundaryFeatures = const [],
    this.isLoading = false,
    this.error,
    this.gisLoading = false,
    this.gisError,
    this.currentLocation,
    this.zoom = 7.5,
    this.activeCategory = LayerCategory.gis,
    this.activeLayers = const [],
    this.layerOpacity = const {},
    this.settlementScopeLguCode,
    this.settlementScopeLguName,
    this.temporarySearchReferenceLayerKey,
    this.temporarySearchReferenceLayerLabel,
    this.runtimeInfo = const MapRuntimeInfo(),
    this.viewport,
    this.showSwipeComparison = false,
    this.leftLayer,
    this.rightLayer,
  });

  MapState copyWith({
    List<WaqfModel>? waqfResults,
    WaqfModel? selectedWaqf,
    bool clearSelectedWaqf = false,
    List<GisLayerModel>? gisLayers,
    List<GisFeatureModel>? gisFeatures,
    GisFeatureModel? selectedFeature,
    bool clearSelectedFeature = false,
    GisFeatureModel? governoratePreviewFeature,
    bool clearGovernoratePreviewFeature = false,
    GisFeatureModel? communityPreviewFeature,
    bool clearCommunityPreviewFeature = false,
    GisFeatureModel? blockPreviewFeature,
    bool clearBlockPreviewFeature = false,
    GisFeatureModel? sitePreviewFeature,
    bool clearSitePreviewFeature = false,
    List<GisFeatureModel>? modernExplorerBoundaryFeatures,
    bool clearModernExplorerBoundaryFeatures = false,
    bool? isLoading,
    String? error,
    bool? gisLoading,
    String? gisError,
    LatLng? currentLocation,
    double? zoom,
    LayerCategory? activeCategory,
    List<String>? activeLayers,
    Map<String, double>? layerOpacity,
    String? settlementScopeLguCode,
    String? settlementScopeLguName,
    bool clearSettlementScope = false,
    String? temporarySearchReferenceLayerKey,
    String? temporarySearchReferenceLayerLabel,
    bool clearTemporarySearchReferenceLayer = false,
    MapRuntimeInfo? runtimeInfo,
    ViewportBounds? viewport,
    bool? showSwipeComparison,
    String? leftLayer,
    String? rightLayer,
  }) {
    return MapState(
      waqfResults: waqfResults ?? this.waqfResults,
      selectedWaqf:
          clearSelectedWaqf ? null : (selectedWaqf ?? this.selectedWaqf),
      gisLayers: gisLayers ?? this.gisLayers,
      gisFeatures: gisFeatures ?? this.gisFeatures,
      selectedFeature: clearSelectedFeature
          ? null
          : (selectedFeature ?? this.selectedFeature),
      governoratePreviewFeature: clearGovernoratePreviewFeature
          ? null
          : (governoratePreviewFeature ?? this.governoratePreviewFeature),
      communityPreviewFeature: clearCommunityPreviewFeature
          ? null
          : (communityPreviewFeature ?? this.communityPreviewFeature),
      blockPreviewFeature: clearBlockPreviewFeature
          ? null
          : (blockPreviewFeature ?? this.blockPreviewFeature),
      sitePreviewFeature: clearSitePreviewFeature
          ? null
          : (sitePreviewFeature ?? this.sitePreviewFeature),
      modernExplorerBoundaryFeatures: clearModernExplorerBoundaryFeatures
          ? const []
          : (modernExplorerBoundaryFeatures ?? this.modernExplorerBoundaryFeatures),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      gisLoading: gisLoading ?? this.gisLoading,
      gisError: gisError,
      currentLocation: currentLocation ?? this.currentLocation,
      zoom: zoom ?? this.zoom,
      activeCategory: activeCategory ?? this.activeCategory,
      activeLayers: activeLayers ?? this.activeLayers,
      layerOpacity: layerOpacity ?? this.layerOpacity,
      settlementScopeLguCode: clearSettlementScope
          ? null
          : (settlementScopeLguCode ?? this.settlementScopeLguCode),
      settlementScopeLguName: clearSettlementScope
          ? null
          : (settlementScopeLguName ?? this.settlementScopeLguName),
      temporarySearchReferenceLayerKey: clearTemporarySearchReferenceLayer
          ? null
          : (temporarySearchReferenceLayerKey ??
              this.temporarySearchReferenceLayerKey),
      temporarySearchReferenceLayerLabel: clearTemporarySearchReferenceLayer
          ? null
          : (temporarySearchReferenceLayerLabel ??
              this.temporarySearchReferenceLayerLabel),
      runtimeInfo: runtimeInfo ?? this.runtimeInfo,
      viewport: viewport ?? this.viewport,
      showSwipeComparison: showSwipeComparison ?? this.showSwipeComparison,
      leftLayer: leftLayer ?? this.leftLayer,
      rightLayer: rightLayer ?? this.rightLayer,
    );
  }
}

class MapNotifier extends StateNotifier<MapState> {
  final WaqfRepository _waqfRepository;
  final GisRepository _gisRepository;

  Timer? _debounce;
  int _gisFeaturesRequestSeq = 0;
  int _modernExplorerBoundaryRequestSeq = 0;
  final LinkedHashMap<String, List<GisFeatureModel>> _featureCache =
      LinkedHashMap<String, List<GisFeatureModel>>();

  static const int _featureCacheMaxEntries = 10;
  static const String _naturalBlocksFullLayerKey = 'natural_blocks_full';
  static const String _naturalBlocksOverviewLayerKey = 'natural_blocks_overview';
  static const String _guessingBlocksLayerKey = 'guessing_blocks';
  static const String _locationsLayerKey = 'locations';
  static const double _naturalBlocksOverviewMaxZoom = 11.0;
  static const double _zoomDrivenGovernoratesMinZoom = 9.0;
  static const double _zoomDrivenCommunitiesMinZoom = 10.0;
  static const double _zoomDrivenCommunityLabelsMinZoom = 10.5;
  static const double _zoomDrivenNaturalBlocksMinZoom = 11.0;
  static const double _zoomDrivenLgusMinZoom = 12.0;
  static const double _zoomDrivenLocationsMinZoom = 13.0;
  static const double _zoomDrivenGuessingBlocksMinZoom = 14.0;
  static const double _zoomDrivenSettlementMinZoom = 15.0;
  static const String _palestineBoundaryFallbackLayerKey = 'westbank_gaza';
  static const List<String> _palestineBoundaryKeyTokens = [
    'westbank_gaza',
    'west_bank_gaza',
    'west_bank_and_gaza',
    'west_bank_gaza_boundary',
    'west_bank_and_gaza_boundary',
    'palestine',
    'palestine_boundary',
    'palestine_boundaries',
    'palestine_wb_gaza',
    'wb_gaza',
    'wb_gaza_boundary',
    'gaza_wb',
    'gaza_wb_boundary',
    'historical_boundary',
    'historical_boundaries',
    'historical_wb_gaza',
    'historical_wb_gaza_boundary',
    'historical_palestine_boundary',
    'wb_gaza_historical_boundary',
  ];
  static const List<String> _palestineBoundaryArTokens = [
    'فلسطين',
    'حدود فلسطين',
    'الحدود التاريخية',
    'حدود تاريخية',
    'الضفة وغزة',
    'الضفة الغربية وغزة',
    'الضفة الغربية وقطاع غزة',
    'حدود الضفة الغربية وقطاع غزة',
  ];
  static const List<String> _palestineBoundaryEnTokens = [
    'palestine',
    'palestine boundary',
    'historical boundary',
    'historical boundaries',
    'west bank and gaza',
    'westbank gaza',
    'west bank gaza boundary',
    'west bank and gaza boundary',
  ];

  MapNotifier({
    required WaqfRepository waqfRepository,
    required GisRepository gisRepository,
  })  : _waqfRepository = waqfRepository,
        _gisRepository = gisRepository,
        super(const MapState());

  bool _isRetiredNaturalBlocksLayerKey(String key) {
    return key.trim().toLowerCase() == 'natural_blocks';
  }

  bool _isSovereignNaturalBlocksLayerKey(String key) {
    return key.trim().toLowerCase() == _naturalBlocksFullLayerKey;
  }

  bool _isGuessingBlocksLayerKey(String key) {
    return key.trim().toLowerCase() == _guessingBlocksLayerKey;
  }

  bool _isLocationsLayerKey(String key) {
    final normalized = key.trim().toLowerCase();
    return normalized == _locationsLayerKey ||
        normalized == 'gis_locations' ||
        normalized == 'operational_locations';
  }

  bool _isCommunitiesBoundaryLayerKey(String key) {
    final normalized = key.trim().toLowerCase();
    return normalized.contains('communities_boundary') ||
        normalized.contains('v_communities_core') ||
        normalized.contains('community_boundary') ||
        normalized.contains('community_boundaries');
  }

  bool _isCommunityLabelsLayerKey(String key) {
    final normalized = key.trim().toLowerCase();
    return normalized.contains('community_labels') ||
        normalized.contains('communities_labels') ||
        normalized.contains('v_communities_labels') ||
        normalized.contains('community_names');
  }

  bool _isModernExplorerWaqfPointLayerKey(String key) {
    return key.trim().toLowerCase().startsWith('gis_waqf_');
  }

  bool _shouldUseNaturalBlocksOverview(double zoom) {
    return zoom < _naturalBlocksOverviewMaxZoom;
  }

  List<String> _effectiveRenderLayerKeysForZoom(
    Iterable<String> activeKeys,
    double zoom,
  ) {
    final useOverview = _shouldUseNaturalBlocksOverview(zoom);
    final seen = <String>{};
    final result = <String>[];
    for (final key in _withoutRetiredLayerKeys(activeKeys)) {
      final effectiveKey =
          _isSovereignNaturalBlocksLayerKey(key) && useOverview
              ? _naturalBlocksOverviewLayerKey
              : key;
      if (seen.add(effectiveKey)) result.add(effectiveKey);
    }
    return result;
  }

  List<String> _withoutRetiredLayerKeys(Iterable<String> keys) {
    return keys
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty && !_isRetiredNaturalBlocksLayerKey(key))
        .toList(growable: false);
  }

  List<String> _dedupeLayerKeys(Iterable<String> keys) {
    final seen = <String>{};
    final result = <String>[];
    for (final rawKey in keys) {
      final key = rawKey.trim();
      if (key.isEmpty) continue;
      if (seen.add(key.toLowerCase())) result.add(key);
    }
    return result;
  }

  /// Load GIS layers once (catalog).
  Future<void> bootstrapGis({String? unitId}) async {
    state = state.copyWith(gisLoading: true, gisError: null);
    try {
      final layers = (await _gisRepository.fetchLayers(unitId: unitId))
          .where((layer) => !_isRetiredNaturalBlocksLayerKey(layer.key))
          .toList(growable: false);
      final defaultActive = _withoutRetiredLayerKeys(
        _defaultInitialActiveLayers(layers),
      );
      final defaultOpacity = <String, double>{
        for (final l in layers) l.key: l.defaultOpacity,
      };
      state = state.copyWith(
        gisLayers: layers,
        activeLayers: defaultActive,
        layerOpacity: defaultOpacity,
        gisLoading: false,
        gisError: null,
      );

      // If we already have viewport (map ready), load features.
      if (state.viewport != null) {
        await reloadGisFeatures(unitId: unitId);
      }
    } catch (e) {
      state = state.copyWith(gisLoading: false, gisError: e.toString());
    }
  }


  List<String> _defaultInitialActiveLayers(List<GisLayerModel> layers) {
    // Opening rule: the historical West Bank/Gaza boundary is always active at
    // map startup. Its canonical layer key is westbank_gaza. The layer catalog
    // may still be useful for styling/metadata, but startup visibility must not
    // depend on fuzzy name detection or optional aliases.
    return const [_palestineBoundaryFallbackLayerKey];
  }

  bool _sameLayerList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String _normalizeLayerLookupText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _layerMatchesTokens(
    GisLayerModel layer, {
    required List<String> keyTokens,
    required List<String> arTokens,
    required List<String> enTokens,
  }) {
    if (!layer.isActive || !layer.isPublic) return false;
    final key = layer.key.trim().toLowerCase();
    final nameAr = _normalizeLayerLookupText(layer.nameAr);
    final nameEn = (layer.nameEn ?? '').trim().toLowerCase();
    return keyTokens.any((token) => key.contains(token.trim().toLowerCase())) ||
        arTokens.any((token) => nameAr.contains(_normalizeLayerLookupText(token))) ||
        enTokens.any((token) => nameEn.contains(token.trim().toLowerCase()));
  }

  String? _firstLayerKey({
    required List<String> keyTokens,
    required List<String> arTokens,
    required List<String> enTokens,
  }) {
    for (final layer in state.gisLayers) {
      if (_layerMatchesTokens(
        layer,
        keyTokens: keyTokens,
        arTokens: arTokens,
        enTokens: enTokens,
      )) {
        return layer.key;
      }
    }
    return null;
  }

  bool _isPalestineBoundaryLayerKey(String rawKey) {
    final key = rawKey.trim().toLowerCase();
    if (key.isEmpty) return false;
    return _palestineBoundaryKeyTokens.any((token) => key.contains(token));
  }

  String? _palestineBoundaryLayerKey() => _palestineBoundaryFallbackLayerKey;

  String? _firstExactLayerKey(List<String> exactKeys) {
    final normalizedExactKeys = exactKeys
        .map((key) => key.trim().toLowerCase())
        .where((key) => key.isNotEmpty)
        .toList(growable: false);

    for (final exactKey in normalizedExactKeys) {
      for (final layer in state.gisLayers) {
        if (!layer.isActive || !layer.isPublic) continue;
        if (layer.key.trim().toLowerCase() == exactKey) return layer.key;
      }
    }
    return null;
  }

  String? _governoratesBoundaryLayerKey() {
    return _firstExactLayerKey(const [
          'governorates_boundary',
          'v_governorates_core',
        ]) ??
        _firstLayerKey(
          keyTokens: const ['governorates_boundary', 'v_governorates_core'],
          arTokens: const ['حدود المحافظات'],
          enTokens: const ['governorate boundaries'],
        );
  }

  String? _communitiesBoundaryLayerKey() {
    return _firstExactLayerKey(const [
          'communities_boundary',
          'v_communities_core',
        ]) ??
        _firstLayerKey(
          keyTokens: const [
            'communities_boundary',
            'v_communities_core',
            'community_boundary',
            'community_boundaries',
          ],
          arTokens: const ['حدود التجمعات', 'التجمعات'],
          enTokens: const ['community boundaries', 'communities'],
        );
  }

  String? _lgusBoundaryLayerKey() {
    // Do not fallback to generic "lgu" or "v_lgus_light" here. In some DBs
    // those keys resolve to centroid/point helper layers, which produced the
    // clustered gold points seen instead of the real local-authority polygons.
    return _firstExactLayerKey(const [
          'lgus_boundary',
          'v_lgus_core',
        ]) ??
        _firstLayerKey(
          keyTokens: const ['lgus_boundary', 'v_lgus_core'],
          arTokens: const ['حدود الهيئات المحلية'],
          enTokens: const ['lgu boundaries', 'local authority boundaries'],
        );
  }

  String? _lgusLabelLayerKey() {
    return _firstExactLayerKey(const [
          'lgu_labels',
          'lgus_labels',
          'v_lgus_labels',
          'lgu_names',
        ]) ??
        _firstLayerKey(
          keyTokens: const [
            'lgu_labels',
            'lgus_labels',
            'v_lgus_labels',
            'lgu_names',
          ],
          arTokens: const ['أسماء الهيئات المحلية', 'تسميات الهيئات المحلية'],
          enTokens: const ['lgu labels', 'lgu names'],
        );
  }

  String? _locationsBoundaryLayerKey() {
    return _firstExactLayerKey(const [
          'locations',
          'gis_locations',
          'operational_locations',
        ]) ??
        _firstLayerKey(
          keyTokens: const [
            'locations',
            'gis_locations',
            'operational_locations',
          ],
          arTokens: const ['المواقع', 'طبقة المواقع', 'حدود المواقع'],
          enTokens: const ['locations', 'operational locations'],
        );
  }

  bool _hasSettlementScope() {
    return (state.settlementScopeLguCode ?? '').trim().isNotEmpty ||
        (state.settlementScopeLguName ?? '').trim().isNotEmpty;
  }

  int? _settlementScopeLguNo() {
    final raw = (state.settlementScopeLguCode ?? '').trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  bool _isRuntimeParcelFeature(GisFeatureModel feature) {
    final key = feature.layerKey.trim().toLowerCase();
    final kind = (feature.props['layer_kind'] ?? '').toString().toLowerCase();
    return key == 'parcels_registered' || kind == 'parcels_registered';
  }

  bool _looksLikeLguScopedFeature(GisFeatureModel feature) {
    final key = feature.layerKey.trim().toLowerCase();
    if (key.contains('lgus_boundary') || key.contains('v_lgus_core')) {
      return true;
    }
    return _firstFeatureProp(feature.props, const ['lgusb_no', 'lgu_no']) != null &&
        _firstFeatureProp(feature.props, const ['lgusn', 'lgu_name_ar']) != null;
  }

  bool _isZoomGovernedLayerKey(String rawKey) {
    final key = rawKey.trim().toLowerCase();
    if (key.isEmpty) return false;
    if (_isPalestineBoundaryLayerKey(key)) return true;
    if (key.contains('governorates_boundary') ||
        key.contains('v_governorates_core') ||
        key.contains('governorate')) return true;
    if (key.contains('lgus_boundary') ||
        key.contains('v_lgus_core') ||
        key.contains('v_lgus_light') ||
        key.contains('lgu_labels') ||
        key.contains('lgus_labels') ||
        key.contains('lgu_names')) return true;
    return _isSettlementOrHeavyDetailLayerKey(key);
  }

  List<String> _coreBoundaryLayerKeys() {
    // The canonical operational key is confirmed from the platform database.
    // Do not request speculative aliases here; the opening map must load one
    // sovereign layer only: westbank_gaza.
    return const [_palestineBoundaryFallbackLayerKey];
  }

  String? _settlementParcelsLayerKey() => 'parcels_registered';

  List<String> _zoomDrivenLayerKeysForZoom(double zoom) {
    // Sovereign display rule: zoom is the only driver for the core map
    // sequence. Search/dropdown controls must never open or close these layers;
    // they only move the camera to a target.
    final keys = <String>[];

    void add(String? key) {
      final normalized = (key ?? '').trim();
      if (normalized.isEmpty || keys.contains(normalized)) return;
      keys.add(normalized);
    }

    for (final key in _coreBoundaryLayerKeys()) {
      add(key);
    }
    if (zoom >= _zoomDrivenGovernoratesMinZoom) {
      add(_governoratesBoundaryLayerKey());
    }
    // Communities are part of the visual sequence at zoom 10, but they are
    // not automatically activated. They may be enabled explicitly and are
    // then gated by _applyZoomThresholdsToLayerKeys().
    if (zoom >= _zoomDrivenLgusMinZoom) {
      add(_lgusBoundaryLayerKey());
    }
    if (zoom >= _zoomDrivenSettlementMinZoom) {
      add(_settlementParcelsLayerKey());
    }
    return _withoutRetiredLayerKeys(keys);
  }

  List<String> _autoAdjustedActiveLayerKeys(
    Iterable<String> current,
    double zoom,
  ) {
    final next = <String>[];

    void add(String? key) {
      final normalized = (key ?? '').trim();
      if (normalized.isEmpty || next.contains(normalized)) return;
      next.add(normalized);
    }

    for (final key in _zoomDrivenLayerKeysForZoom(zoom)) {
      add(key);
    }

    // Optional analytical layers may remain user-controlled. Core Palestine,
    // governorate, LGU and settlement visibility is recalculated from zoom only.
    for (final key in _withoutRetiredLayerKeys(current)) {
      if (_isZoomGovernedLayerKey(key)) continue;
      add(key);
    }
    return next;
  }

  /// Called from MapPage on zoom/pan. Debounced to avoid spamming RPC.
  void updateViewport(ViewportBounds bounds, {String? unitId, double? zoom}) {
    final nextZoom = zoom ?? state.zoom;
    final previousZoom = state.zoom;
    final previousBounds = state.viewport;
    final previousActive = _withoutRetiredLayerKeys(state.activeLayers);
    final nextActive = _autoAdjustedActiveLayerKeys(previousActive, nextZoom);
    final activeChanged = !_sameLayerList(previousActive, nextActive);
    final temporaryReferenceKey =
        _temporarySearchReferenceLayerKeyForZoom(nextZoom);
    final denseLayerMode = nextActive.any(_isSovereignNaturalBlocksLayerKey) ||
        ((temporaryReferenceKey ?? '').trim().isNotEmpty &&
            _isSovereignNaturalBlocksLayerKey(temporaryReferenceKey!)) ||
        nextActive.any(_isSettlementOrHeavyDetailLayerKey);

    // Update zoom, viewport and zoom-governed layers in state first so the UI
    // stays responsive and layers close/open immediately while moving.
    if (activeChanged) _featureCache.clear();
    state = state.copyWith(
      zoom: nextZoom,
      viewport: bounds,
      activeLayers: activeChanged ? nextActive : null,
    );

    if (!activeChanged &&
        !_shouldReloadForViewportChange(
          previousBounds: previousBounds,
          nextBounds: bounds,
          previousZoom: previousZoom,
          nextZoom: nextZoom,
          denseLayerMode: denseLayerMode,
        )) {
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(
      denseLayerMode
          ? const Duration(milliseconds: 750)
          : const Duration(milliseconds: 350),
      () {
        reloadGisFeatures(unitId: unitId);
      },
    );
  }

  bool _shouldReloadForViewportChange({
    required ViewportBounds? previousBounds,
    required ViewportBounds nextBounds,
    required double previousZoom,
    required double nextZoom,
    required bool denseLayerMode,
  }) {
    if (previousBounds == null) return true;

    final zoomDelta = (previousZoom - nextZoom).abs();
    if (zoomDelta >= (denseLayerMode ? 0.35 : 0.08)) return true;

    // Dense national vector layers are expensive. Avoid reloading for tiny
    // pan/zoom noise generated by FlutterMap while the user is still moving.
    return !previousBounds.nearlyEquals(
      nextBounds,
      eps: denseLayerMode ? 0.035 : 0.002,
    );
  }

  double _simplifyMetersForZoom(double zoom) {
    if (zoom < 9) return 150;
    if (zoom < 11) return 80;
    if (zoom < 13) return 30;
    if (zoom < 15) return 10;
    return 0;
  }

  double _naturalBlocksSimplifyMetersForZoom(double zoom) {
    // Keep the sovereign source complete, but generalize geometry at national
    // zoom levels. Full-detail rings are restored automatically when the user
    // zooms in. This avoids rendering thousands of heavy polygons at once.
    if (zoom < 7.5) return 120;
    if (zoom < 9) return 60;
    if (zoom < 10.5) return 25;
    if (zoom < 12) return 10;
    return 0;
  }

  ViewportBounds _expandedBounds(ViewportBounds bounds, {double padding = 0.12}) {
    return ViewportBounds(
      west: bounds.west - padding,
      south: bounds.south - padding,
      east: bounds.east + padding,
      north: bounds.north + padding,
    );
  }

  bool _isSettlementOrHeavyDetailLayerKey(String key) {
    final normalized = key.trim().toLowerCase();
    return normalized.contains('settlement') ||
        normalized.contains('taswyeh') ||
        normalized.contains('parcel') ||
        normalized.contains('cadastre') ||
        normalized.contains('cadastral');
  }

  List<String> _applyZoomThresholdsToLayerKeys(
    Iterable<String> layerKeys,
    double zoom, {
    Map<String, String>? blockedReasons,
  }) {
    final result = <String>[];
    for (final key in layerKeys) {
      final normalized = key.trim().toLowerCase();
      if (_isCommunitiesBoundaryLayerKey(normalized)) {
        if (zoom < _zoomDrivenCommunitiesMinZoom) {
          blockedReasons?[key] =
              'محجوبة حتى Zoom ${_zoomDrivenCommunitiesMinZoom.toStringAsFixed(1)} لأن طبقة التجمعات غير مفعلة تلقائيًا قبل مستواها';
          continue;
        }
      }
      if (_isCommunityLabelsLayerKey(normalized)) {
        if (zoom < _zoomDrivenCommunityLabelsMinZoom) {
          blockedReasons?[key] =
              'محجوبة حتى Zoom ${_zoomDrivenCommunityLabelsMinZoom.toStringAsFixed(1)} لأن أسماء التجمعات غير مفعلة تلقائيًا قبل مستواها';
          continue;
        }
      }
      if (_isSovereignNaturalBlocksLayerKey(normalized) ||
          normalized == _naturalBlocksOverviewLayerKey) {
        if (zoom < _zoomDrivenNaturalBlocksMinZoom) {
          blockedReasons?[key] =
              'محجوبة حتى Zoom ${_zoomDrivenNaturalBlocksMinZoom.toStringAsFixed(1)} لأن طبقة الأحواض الطبيعية غير مفعلة تلقائيًا قبل مستواها';
          continue;
        }
      }
      if (_isLocationsLayerKey(normalized)) {
        if (zoom < _zoomDrivenLocationsMinZoom) {
          blockedReasons?[key] =
              'محجوبة حتى Zoom ${_zoomDrivenLocationsMinZoom.toStringAsFixed(1)} لأن طبقة المواقع غير مفعلة تلقائيًا قبل مستواها';
          continue;
        }
      }
      if (_isGuessingBlocksLayerKey(normalized)) {
        if (zoom < _zoomDrivenGuessingBlocksMinZoom) {
          blockedReasons?[key] =
              'محجوبة حتى Zoom ${_zoomDrivenGuessingBlocksMinZoom.toStringAsFixed(1)} لأن طبقة أحواض التخمين غير مفعلة تلقائيًا قبل مستواها';
          continue;
        }
      }
      if (_isSettlementOrHeavyDetailLayerKey(normalized)) {
        if (zoom < _zoomDrivenSettlementMinZoom) {
          blockedReasons?[key] =
              'محجوبة حتى Zoom ${_zoomDrivenSettlementMinZoom.toStringAsFixed(1)} بسبب ثقل طبقة التسوية/القطع';
          continue;
        }
      }
      result.add(key);
    }
    return result;
  }

  String _normalizeScopeText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _sameScopeValue(String? left, String? right) {
    final a = _normalizeScopeText(left ?? '');
    final b = _normalizeScopeText(right ?? '');
    if (a.isEmpty || b.isEmpty) return false;
    return a == b || a.contains(b) || b.contains(a);
  }

  String? _firstFeatureProp(Map<String, dynamic> props, List<String> keys) {
    for (final key in keys) {
      final value = props[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return null;
  }

  static const List<String> _settlementScopeCodeProps = [
    'lgus_code',
    'lgus_xcode',
    'lgu_code',
    'lgu_no',
    'lgu_id',
    'municipality_code',
    'municipality_no',
    'locality_code',
    'community_no',
    'com_code',
    'local_body_code',
    'code',
  ];

  static const List<String> _settlementScopeNameProps = [
    'lgusn',
    'lgun',
    'lgu_name_ar',
    'lgu_name',
    'municipality_name_ar',
    'municipality_name',
    'locality_name_ar',
    'locality_name',
    'communityn',
    'community_name_ar',
    'community_name',
    'name_ar',
    'label_ar',
    'name',
    'title_ar',
  ];

  bool _settlementFeatureHasScopeHint(GisFeatureModel feature) {
    return _firstFeatureProp(feature.props, _settlementScopeCodeProps) != null ||
        _firstFeatureProp(feature.props, _settlementScopeNameProps) != null;
  }

  bool _settlementFeatureMatchesScope(GisFeatureModel feature) {
    final scopeCode = (state.settlementScopeLguCode ?? '').trim();
    final scopeName = (state.settlementScopeLguName ?? '').trim();
    if (scopeCode.isEmpty && scopeName.isEmpty) return false;

    final props = feature.props;
    final code = _firstFeatureProp(props, _settlementScopeCodeProps);
    final name = _firstFeatureProp(props, _settlementScopeNameProps);

    return _sameScopeValue(code, scopeCode) ||
        _sameScopeValue(code, scopeName) ||
        _sameScopeValue(name, scopeName) ||
        _sameScopeValue(name, scopeCode);
  }

  List<GisFeatureModel> _filterSettlementFeaturesForScope(
    List<GisFeatureModel> features,
  ) {
    if (!_hasSettlementScope()) return features;
    var changed = false;
    final filtered = <GisFeatureModel>[];
    for (final feature in features) {
      if (!_isSettlementOrHeavyDetailLayerKey(feature.layerKey)) {
        filtered.add(feature);
        continue;
      }
      if (!_settlementFeatureHasScopeHint(feature) ||
          _settlementFeatureMatchesScope(feature)) {
        // If the settlement source does not expose LGU/community fields, keep
        // the feature here and let MapPage apply the selected-boundary geometry
        // filter. This prevents valid parcels from disappearing solely because
        // their source attributes use an unknown naming convention.
        filtered.add(feature);
      } else {
        changed = true;
      }
    }
    return changed ? filtered : features;
  }

  String _boundsCachePart(ViewportBounds bounds) {
    String q(double value) => value.toStringAsFixed(4);
    return '${q(bounds.west)},${q(bounds.south)},${q(bounds.east)},${q(bounds.north)}';
  }

  String _featureCacheKey({
    required Iterable<String> layerKeys,
    required ViewportBounds bounds,
    required double zoom,
    required double simplifyMeters,
    required int limit,
    required String unitId,
    required String scopeSignature,
  }) {
    final sortedKeys = layerKeys
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList()
      ..sort();
    final zoomBucket = (zoom * 2).round() / 2.0;
    return [
      unitId,
      scopeSignature,
      sortedKeys.join('|'),
      _boundsCachePart(bounds),
      zoomBucket.toStringAsFixed(1),
      simplifyMeters.toStringAsFixed(1),
      limit.toString(),
    ].join('::');
  }

  List<GisFeatureModel>? _readFeatureCache(String key) {
    final cached = _featureCache.remove(key);
    if (cached == null) return null;
    _featureCache[key] = cached;
    return cached;
  }

  void _writeFeatureCache(String key, List<GisFeatureModel> features) {
    _featureCache[key] = features;
    while (_featureCache.length > _featureCacheMaxEntries) {
      _featureCache.remove(_featureCache.keys.first);
    }
  }

  int _operationalParcelLimitForZoom(double zoom) {
    if (zoom < 13.2) return 550;
    if (zoom < 14.2) return 900;
    if (zoom < 15.2) return 1400;
    return 2200;
  }

  String? _temporarySearchReferenceLayerKeyForZoom(double zoom) {
    final key = (state.temporarySearchReferenceLayerKey ?? '').trim();
    if (key.isEmpty) return null;

    // Search-reference layers are contextual overlays, not activeLayers.
    // They still respect their map sequence level.
    if (_isSovereignNaturalBlocksLayerKey(key) &&
        zoom < _zoomDrivenNaturalBlocksMinZoom) {
      return null;
    }
    if (_isGuessingBlocksLayerKey(key) && zoom < _zoomDrivenGuessingBlocksMinZoom) {
      return null;
    }
    return key;
  }

  int _renderOrderForLayerKey(String rawKey) {
    final key = rawKey.trim().toLowerCase();
    if (_isPalestineBoundaryLayerKey(key)) return 10;
    if (key.contains('governorates_boundary') ||
        key.contains('v_governorates_core') ||
        key.contains('governorate')) return 20;
    if (_isCommunitiesBoundaryLayerKey(key)) return 30;
    if (_isSovereignNaturalBlocksLayerKey(key) ||
        key == _naturalBlocksOverviewLayerKey) return 35;
    if (key.contains('lgus_boundary') ||
        key.contains('v_lgus_core') ||
        key.contains('v_lgus_light') ||
        key.contains('lgu_labels') ||
        key.contains('lgus_labels') ||
        key.contains('lgu_names')) return 40;
    if (_isLocationsLayerKey(key)) return 43;
    if (_isGuessingBlocksLayerKey(key)) return 45;
    if (_isSettlementOrHeavyDetailLayerKey(key)) return 50;
    return 90;
  }

  List<GisFeatureModel> _sortFeaturesForRenderOrder(
    List<GisFeatureModel> features,
  ) {
    final sorted = List<GisFeatureModel>.from(features);
    sorted.sort((a, b) {
      final byLayer = _renderOrderForLayerKey(a.layerKey)
          .compareTo(_renderOrderForLayerKey(b.layerKey));
      if (byLayer != 0) return byLayer;
      return a.displayTitle.compareTo(b.displayTitle);
    });
    return sorted;
  }

  Future<void> reloadGisFeatures({String? unitId}) async {
    final vp = state.viewport;
    if (vp == null) return;

    final requestId = ++_gisFeaturesRequestSeq;

    try {
      final activeKeys = _withoutRetiredLayerKeys(state.activeLayers);
      final temporaryReferenceKey =
          _temporarySearchReferenceLayerKeyForZoom(state.zoom);
      final requestedLayerKeys = _withoutRetiredLayerKeys(<String>[
        ...activeKeys,
        if ((temporaryReferenceKey ?? '').trim().isNotEmpty)
          temporaryReferenceKey!.trim(),
      ]);
      final simplify = _simplifyMetersForZoom(state.zoom);

      if (requestedLayerKeys.isEmpty) {
        if (state.gisFeatures.isNotEmpty || state.runtimeInfo.hasQueryLayers) {
          state = state.copyWith(
            gisFeatures: const [],
            gisError: null,
            runtimeInfo: const MapRuntimeInfo(),
          );
        }
        return;
      }

      final hasNaturalBlocksLayer =
          requestedLayerKeys.any(_isSovereignNaturalBlocksLayerKey);
      final hasModernExplorerWaqfPointLayer =
          requestedLayerKeys.any(_isModernExplorerWaqfPointLayerKey);
      final useNaturalBlocksOverview =
          hasNaturalBlocksLayer && _shouldUseNaturalBlocksOverview(state.zoom);
      final effectiveLayerKeys =
          _effectiveRenderLayerKeysForZoom(requestedLayerKeys, state.zoom);
      final blockedLayerReasons = <String, String>{};
      final queryLayerKeys = _applyZoomThresholdsToLayerKeys(
        effectiveLayerKeys,
        state.zoom,
        blockedReasons: blockedLayerReasons,
      ).where((key) => !_isSettlementOrHeavyDetailLayerKey(key)).toList(growable: false);
      final hasActiveSettlementLayer =
          activeKeys.any(_isSettlementOrHeavyDetailLayerKey);
      final shouldLoadOperationalParcels = hasActiveSettlementLayer &&
          state.zoom >= _zoomDrivenSettlementMinZoom;

      if (queryLayerKeys.isEmpty && !shouldLoadOperationalParcels) {
        if (requestId != _gisFeaturesRequestSeq) return;
        state = state.copyWith(
          gisFeatures: const [],
          gisError: null,
          runtimeInfo: MapRuntimeInfo(
            requestedLayerKeys: requestedLayerKeys,
            queryLayerKeys: const [],
            blockedLayerKeys: blockedLayerReasons.keys.toList(growable: false),
            blockedReasons: blockedLayerReasons.values.toList(growable: false),
            usingNaturalBlocksOverview: useNaturalBlocksOverview,
          ),
        );
        return;
      }

      // Sovereign rendering rule:
      // natural_blocks_full remains the only user-facing operational layer key.
      // At far zoom levels we query the hidden derived overview layer
      // natural_blocks_overview, generated only from natural_blocks_full, to
      // avoid drawing 6654 detailed geometries at national scale. Medium/high
      // zoom automatically returns to natural_blocks_full detail.
      final boundsPadding = hasNaturalBlocksLayer
          ? 0.18
          : (hasModernExplorerWaqfPointLayer ? 0.06 : 0.0);
      final queryBounds = boundsPadding > 0
          ? _expandedBounds(vp, padding: boundsPadding)
          : vp;

      final effectiveSimplify = hasNaturalBlocksLayer
          ? (useNaturalBlocksOverview
              ? 0.0
              : _naturalBlocksSimplifyMetersForZoom(state.zoom))
          : simplify;

      final effectiveUnitId =
          unitId ?? '00000000-0000-0000-0000-000000000000';
      final effectiveLimit = hasNaturalBlocksLayer
          ? (useNaturalBlocksOverview
              ? (hasModernExplorerWaqfPointLayer ? 5000 : 3000)
              : 12000)
          : (hasModernExplorerWaqfPointLayer ? 3500 : 2500);
      final scopeSignature = [
        state.settlementScopeLguCode ?? '',
        state.settlementScopeLguName ?? '',
        state.temporarySearchReferenceLayerKey ?? '',
      ].join('|');
      final cacheKey = _featureCacheKey(
        layerKeys: <String>[
          ...queryLayerKeys,
          if (shouldLoadOperationalParcels) 'runtime:parcels_registered',
        ],
        bounds: queryBounds,
        zoom: state.zoom,
        simplifyMeters: effectiveSimplify,
        limit: effectiveLimit,
        unitId: effectiveUnitId,
        scopeSignature: scopeSignature,
      );
      final cached = _readFeatureCache(cacheKey);
      if (cached != null) {
        if (requestId != _gisFeaturesRequestSeq) return;
        state = state.copyWith(
          gisFeatures: cached,
          gisError: null,
          runtimeInfo: MapRuntimeInfo(
            requestedLayerKeys: requestedLayerKeys,
            queryLayerKeys: queryLayerKeys,
            blockedLayerKeys: blockedLayerReasons.keys.toList(growable: false),
            blockedReasons: blockedLayerReasons.values.toList(growable: false),
            usingNaturalBlocksOverview: useNaturalBlocksOverview,
            servedFromCache: true,
            simplifyMeters: effectiveSimplify,
            featureLimit: effectiveLimit,
            featureCount: cached.length,
            boundsPadding: boundsPadding,
          ),
        );
        return;
      }

      final fetchedFeatures = queryLayerKeys.isEmpty
          ? const <GisFeatureModel>[]
          : await _gisRepository.fetchFeaturesInBounds(
              layerKeys: queryLayerKeys,
              unitId: effectiveUnitId,
              west: queryBounds.west,
              south: queryBounds.south,
              east: queryBounds.east,
              north: queryBounds.north,
              simplifyMeters: effectiveSimplify,
              // Overview is already dissolved/generalized and should remain small.
              // Full detail keeps the raised cap to avoid false incompleteness.
              limit: effectiveLimit,
            );

      var sovereignFetchedFeatures = fetchedFeatures;
      final shouldContainPalestineBoundary = queryLayerKeys.any(
        (key) => key.trim().toLowerCase() == _palestineBoundaryFallbackLayerKey,
      );
      final hasPalestineBoundaryFeature = fetchedFeatures.any(
        (feature) =>
            feature.layerKey.trim().toLowerCase() ==
            _palestineBoundaryFallbackLayerKey,
      );
      if (shouldContainPalestineBoundary && !hasPalestineBoundaryFeature) {
        try {
          final boundaryOnly = await _gisRepository.fetchFeaturesInBounds(
            layerKeys: const [_palestineBoundaryFallbackLayerKey],
            unitId: effectiveUnitId,
            west: queryBounds.west,
            south: queryBounds.south,
            east: queryBounds.east,
            north: queryBounds.north,
            publicOnly: false,
            simplifyMeters: 0,
            limit: 50,
          );
          if (boundaryOnly.isNotEmpty) {
            final seen = <String>{
              for (final feature in fetchedFeatures)
                '${feature.layerKey.trim().toLowerCase()}::${feature.id}',
            };
            sovereignFetchedFeatures = <GisFeatureModel>[
              ...fetchedFeatures,
              ...boundaryOnly.where(
                (feature) => seen.add(
                  '${feature.layerKey.trim().toLowerCase()}::${feature.id}',
                ),
              ),
            ];
          }
        } catch (_) {
          // Keep normal map loading alive; the runtime diagnostics will still
          // show that westbank_gaza was requested with zero returned features.
        }
      }

      final scopedOperationalFeatures = <GisFeatureModel>[];
      if (shouldLoadOperationalParcels) {
        try {
          scopedOperationalFeatures.addAll(
            await _gisRepository.fetchParcelsInBounds(
              west: queryBounds.west,
              south: queryBounds.south,
              east: queryBounds.east,
              north: queryBounds.north,
              limit: _operationalParcelLimitForZoom(state.zoom),
            ),
          );
        } catch (_) {
          // Keep the page usable if the parcels bbox wrapper has not been applied yet.
        }
      }

      final features = _sortFeaturesForRenderOrder(
        _filterSettlementFeaturesForScope(<GisFeatureModel>[
          ...sovereignFetchedFeatures,
          ...scopedOperationalFeatures,
        ]),
      );

      if (requestId != _gisFeaturesRequestSeq) return;
      _writeFeatureCache(cacheKey, features);
      state = state.copyWith(
        gisFeatures: features,
        gisError: null,
        runtimeInfo: MapRuntimeInfo(
          requestedLayerKeys: requestedLayerKeys,
          queryLayerKeys: queryLayerKeys,
          blockedLayerKeys: blockedLayerReasons.keys.toList(growable: false),
          blockedReasons: blockedLayerReasons.values.toList(growable: false),
          usingNaturalBlocksOverview: useNaturalBlocksOverview,
          servedFromCache: false,
          simplifyMeters: effectiveSimplify,
          featureLimit: effectiveLimit,
          featureCount: features.length,
          boundsPadding: boundsPadding,
        ),
      );
    } catch (e) {
      if (requestId != _gisFeaturesRequestSeq) return;
      state = state.copyWith(gisError: e.toString());
    }
  }

  /// Legacy search (waqf_assets table). Keep for later, but not used for GIS-only dev.
  Future<void> searchWaqf({
    String? pwfKey,
    String? governorate,
    String? municipality,
    String? community,
    String? basin,
    String? parcel,
    WaqfType? type,
    WaqfStatus? status,
  }) async {
    state =
        state.copyWith(isLoading: true, error: null, clearSelectedWaqf: true);

    try {
      final results = await _waqfRepository.searchWaqf(
        pwfKey: pwfKey,
        governorate: governorate,
        municipality: municipality,
        community: community,
        basin: basin,
        parcel: parcel,
        type: type,
        status: status,
      );

      state = state.copyWith(waqfResults: results, isLoading: false);
    } catch (e) {
      // If waqf_assets table is not available, fallback to GIS features (layer_key = 'waqf_assets')
      final msg = e.toString();
      final looksLikeMissingTable = msg.contains('waqf_assets') &&
          (msg.contains('does not exist') || msg.contains('42P01'));

      if (!looksLikeMissingTable) {
        state = state.copyWith(error: msg, isLoading: false);
        return;
      }

      try {
        final vp = state.viewport;
        if (vp == null) {
          throw Exception(
              'حرّك الخريطة إلى المنطقة المطلوبة ثم أعد البحث (Viewport غير جاهز).');
        }

        final features = await _gisRepository.fetchFeaturesInBounds(
          layerKeys: const ['waqf_assets'],
          unitId: '00000000-0000-0000-0000-000000000000',
          west: vp.west,
          south: vp.south,
          east: vp.east,
          north: vp.north,
          simplifyMeters: 0,
          limit: 2000,
        );

        bool matchStringAny(
            Map<String, dynamic> props, List<String> keys, String needle) {
          final n = needle.trim().toLowerCase();
          if (n.isEmpty) return true;
          for (final k in keys) {
            final v = props[k];
            if (v == null) continue;
            final s = v.toString().trim().toLowerCase();
            if (s.isEmpty) continue;
            if (s.contains(n)) return true;
          }
          return false;
        }

        bool matchEqualsAny(
            Map<String, dynamic> props, List<String> keys, String needle) {
          final n = needle.trim();
          if (n.isEmpty) return true;
          for (final k in keys) {
            final v = props[k];
            if (v == null) continue;
            final s = v.toString().trim();
            if (s == n) return true;
          }
          return false;
        }

        final filtered = features.where((f) {
          final p = f.props;
          if (pwfKey != null && pwfKey.trim().isNotEmpty) {
            if (!matchStringAny(
                p,
                const ['pwf_key', 'pwfKey', 'PWF', 'pwf', 'key', 'code'],
                pwfKey)) return false;
          }
          if (governorate != null && governorate.trim().isNotEmpty) {
            if (!matchStringAny(
                p,
                const [
                  'governorate',
                  'gov_name',
                  'gov_ar',
                  'governorate_ar',
                  'governorate_name'
                ],
                governorate)) return false;
          }
          if (municipality != null && municipality.trim().isNotEmpty) {
            if (!matchStringAny(
                p,
                const [
                  'municipality',
                  'lgu',
                  'lgu_name',
                  'municipality_name',
                  'lgu_ar'
                ],
                municipality)) return false;
          }
          if (community != null && community.trim().isNotEmpty) {
            if (!matchStringAny(
                p,
                const ['community', 'community_name', 'community_ar'],
                community)) return false;
          }
          if (basin != null && basin.trim().isNotEmpty) {
            if (!matchEqualsAny(
                p, const ['basin', 'basin_no', 'basin_number'], basin))
              return false;
          }
          if (parcel != null && parcel.trim().isNotEmpty) {
            if (!matchEqualsAny(
                p, const ['parcel', 'parcel_no', 'parcel_number'], parcel))
              return false;
          }
          return true;
        }).toList();

        WaqfModel fromFeature(GisFeatureModel f) {
          final p = f.props;
          final pwf = (p['pwf_key'] ??
                  p['pwfKey'] ??
                  p['PWF'] ??
                  p['key'] ??
                  p['code'] ??
                  '')
              .toString();
          final name = (p['name'] ??
                  p['name_ar'] ??
                  p['title_ar'] ??
                  f.titleAr ??
                  f.titleEn)
              ?.toString();
          final gov =
              (p['governorate'] ?? p['gov_name'] ?? p['gov_ar'])?.toString();
          final mun = (p['municipality'] ??
                  p['lgu'] ??
                  p['lgu_name'] ??
                  p['municipality_name'])
              ?.toString();
          final com =
              (p['community'] ?? p['community_name'] ?? p['community_ar'])
                  ?.toString();
          final basinV =
              (p['basin'] ?? p['basin_no'] ?? p['basin_number'])?.toString();
          final parcelV =
              (p['parcel'] ?? p['parcel_no'] ?? p['parcel_number'])?.toString();
          final areaV = p['area'];
          final areaD = (areaV is num)
              ? areaV.toDouble()
              : double.tryParse(areaV?.toString() ?? '');

          return WaqfModel(
            id: f.id,
            pwfKey: pwf.isEmpty ? f.id : pwf,
            name: name,
            type: WaqfType.land,
            status: WaqfStatus.active,
            governorate: gov,
            municipality: mun,
            community: com,
            basin: basinV,
            parcel: parcelV,
            area: areaD,
            geometry: f.geom,
            isSensitive: (p['is_sensitive'] as bool?) ??
                (p['isSensitive'] as bool?) ??
                false,
          );
        }

        final results = filtered.map(fromFeature).toList();
        state =
            state.copyWith(waqfResults: results, isLoading: false, error: null);
      } catch (inner) {
        state = state.copyWith(error: inner.toString(), isLoading: false);
      }
    }
  }

  void selectWaqf(WaqfModel waqf) {
    state = state.copyWith(selectedWaqf: waqf, clearSelectedFeature: true);
  }


  String? _detectGovernoratesBoundaryLayerKey() {
    for (final layer in state.gisLayers) {
      final key = layer.key.trim().toLowerCase();
      final nameAr = layer.nameAr.trim().toLowerCase();
      final nameEn = (layer.nameEn ?? '').trim().toLowerCase();
      final matches = key == 'governorates_boundary' ||
          key.contains('governorates_boundary') ||
          key.contains('governorate') ||
          nameAr.contains('المحافظ') ||
          nameEn.contains('governorate');
      if (matches) return layer.key;
    }
    return null;
  }

  Future<void> previewGovernorateBoundary({
    required String governorateCode,
    required String governorateName,
    String? unitId,
  }) async {
    try {
      final boundaryKey = _detectGovernoratesBoundaryLayerKey() ?? 'governorates_boundary';
      final feature = await _gisRepository.fetchGovernorateBoundaryFeature(
        governorateCode: governorateCode,
        governorateName: governorateName,
        layerKey: boundaryKey,
        unitId: unitId ?? '00000000-0000-0000-0000-000000000000',
      );

      if (feature == null) {
        state = state.copyWith(
          gisError: 'تعذر تحميل حدود المحافظة المختارة من طبقة المحافظات.',
        );
        return;
      }

      state = state.copyWith(
        governoratePreviewFeature: feature,
        clearCommunityPreviewFeature: true,
        clearBlockPreviewFeature: true,
        clearSitePreviewFeature: true,
        clearSelectedFeature: true,
        clearSelectedWaqf: true,
        gisError: null,
      );
    } catch (e) {
      state = state.copyWith(gisError: e.toString());
    }
  }


  String? _detectCommunitiesBoundaryLayerKey() {
    for (final layer in state.gisLayers) {
      final key = layer.key.trim().toLowerCase();
      final nameAr = layer.nameAr.trim().toLowerCase();
      final nameEn = (layer.nameEn ?? '').trim().toLowerCase();
      final matches = key == 'communities_boundary' ||
          key.contains('communities_boundary') ||
          key.contains('community') ||
          nameAr.contains('التجمع') ||
          nameAr.contains('القرى') ||
          nameAr.contains('المدن') ||
          nameEn.contains('community');
      if (matches) return layer.key;
    }
    return null;
  }

  Future<void> previewCommunityBoundary({
    required String communityCode,
    required String communityName,
    String? unitId,
  }) async {
    try {
      final boundaryKey = _detectCommunitiesBoundaryLayerKey() ?? 'communities_boundary';
      final feature = await _gisRepository.fetchCommunityBoundaryFeature(
        communityCode: communityCode,
        communityName: communityName,
        layerKey: boundaryKey,
        unitId: unitId ?? '00000000-0000-0000-0000-000000000000',
      );

      if (feature == null) {
        state = state.copyWith(
          clearCommunityPreviewFeature: true,
          clearBlockPreviewFeature: true,
          clearSitePreviewFeature: true,
          clearSelectedFeature: true,
          clearSelectedWaqf: true,
          gisError: null,
        );
        return;
      }

      state = state.copyWith(
        communityPreviewFeature: feature,
        clearBlockPreviewFeature: true,
        clearSitePreviewFeature: true,
        clearSelectedFeature: true,
        clearSelectedWaqf: true,
        gisError: null,
      );
    } catch (e) {
      state = state.copyWith(gisError: e.toString());
    }
  }

  Future<void> previewNaturalBlock({
    String? governorateNo,
    String? communityNo,
    String? blockNo,
    String? siteName,
    String? unitId,
  }) async {
    if ((governorateNo ?? '').trim().isEmpty ||
        (communityNo ?? '').trim().isEmpty ||
        (((blockNo ?? '').trim().isEmpty) && ((siteName ?? '').trim().isEmpty))) {
      state = state.copyWith(
        clearBlockPreviewFeature: (blockNo ?? '').trim().isEmpty,
        clearSitePreviewFeature: true,
        gisError: null,
      );
      return;
    }

    try {
      if ((blockNo ?? '').trim().isNotEmpty) {
        final blockFeature = await _gisRepository.fetchNaturalBlockFeature(
          governorateNo: governorateNo,
          communityNo: communityNo,
          blockNo: blockNo,
          unitId: unitId ?? '00000000-0000-0000-0000-000000000000',
        );

        if (blockFeature == null) {
          state = state.copyWith(
            clearBlockPreviewFeature: true,
            clearSitePreviewFeature: true,
            gisError: 'تعذر تحميل الحوض المختار من القائمة.',
          );
          return;
        }

        state = state.copyWith(
          blockPreviewFeature: blockFeature,
          clearSelectedFeature: true,
          clearSelectedWaqf: true,
          gisError: null,
        );
      }

      if ((siteName ?? '').trim().isNotEmpty) {
        final siteFeature = await _gisRepository.fetchNaturalBlockFeature(
          governorateNo: governorateNo,
          communityNo: communityNo,
          blockNo: blockNo,
          siteName: siteName,
          unitId: unitId ?? '00000000-0000-0000-0000-000000000000',
        );

        if (siteFeature == null) {
          state = state.copyWith(
            clearSitePreviewFeature: true,
            gisError: 'تعذر تحميل اسم الحوض المختار من القائمة.',
          );
          return;
        }

        state = state.copyWith(
          sitePreviewFeature: siteFeature,
          clearSelectedFeature: true,
          clearSelectedWaqf: true,
          gisError: null,
        );
      } else {
        state = state.copyWith(clearSitePreviewFeature: true, gisError: null);
      }
    } catch (e) {
      state = state.copyWith(gisError: e.toString());
    }
  }

  void clearModernExplorerBoundaryOverlays() {
    ++_modernExplorerBoundaryRequestSeq;
    state = state.copyWith(
      clearModernExplorerBoundaryFeatures: true,
      gisError: null,
    );
  }

  Future<void> previewModernExplorerBoundaries({
    String? governorateCode,
    String? lguCode,
  }) async {
    final requestId = ++_modernExplorerBoundaryRequestSeq;
    final gov = (governorateCode ?? '').trim();
    final lgu = (lguCode ?? '').trim();

    try {
      final governorates = await _gisRepository
          .fetchModernExplorerGovernorateBoundaryFeatures(
        governorateNo: gov.isEmpty ? null : gov,
      );
      final lgus = await _gisRepository.fetchModernExplorerLguBoundaryFeatures(
        governorateNo: gov.isEmpty ? null : gov,
        lguCode: lgu.isEmpty ? null : lgu,
      );

      if (requestId != _modernExplorerBoundaryRequestSeq) return;

      state = state.copyWith(
        modernExplorerBoundaryFeatures: <GisFeatureModel>[
          ...governorates,
          ...lgus,
        ],
        clearGovernoratePreviewFeature: true,
        clearCommunityPreviewFeature: true,
        clearBlockPreviewFeature: true,
        clearSitePreviewFeature: true,
        clearSelectedFeature: true,
        clearSelectedWaqf: true,
        gisError: null,
      );
    } catch (e) {
      if (requestId != _modernExplorerBoundaryRequestSeq) return;
      state = state.copyWith(
        modernExplorerBoundaryFeatures: const [],
        gisError: e.toString(),
      );
    }
  }

  void selectGisFeature(GisFeatureModel f) {
    final scopeCode = _firstFeatureProp(f.props, const [
      'lgusb_no',
      'lgu_no',
      'lgus_code',
      'code',
      'community_no',
    ]);
    final scopeName = _firstFeatureProp(f.props, const [
      'lgusn',
      'lgu_name_ar',
      'community_name_ar',
      'name_ar',
    ]);
    final shouldApplyScope = _looksLikeLguScopedFeature(f) &&
        ((scopeCode ?? '').trim().isNotEmpty ||
            (scopeName ?? '').trim().isNotEmpty);

    final scopeChanged = shouldApplyScope &&
        ((state.settlementScopeLguCode ?? '').trim() != (scopeCode ?? '').trim() ||
            (state.settlementScopeLguName ?? '').trim() != (scopeName ?? '').trim());

    state = state.copyWith(
      selectedFeature: f,
      settlementScopeLguCode: shouldApplyScope ? (scopeCode ?? '') : null,
      settlementScopeLguName: shouldApplyScope ? (scopeName ?? '') : null,
      clearSelectedWaqf: true,
      gisError: null,
    );

    if (scopeChanged) {
      _featureCache.clear();
      unawaited(reloadGisFeatures());
    }
    if (_isRuntimeParcelFeature(f)) {
      unawaited(_hydrateSelectedParcelDetails(f));
    }
  }

  Future<void> _hydrateSelectedParcelDetails(GisFeatureModel selected) async {
    try {
      final details = await _gisRepository.fetchParcelDetails(id: selected.id);
      if (details == null || state.selectedFeature?.id != selected.id) return;
      state = state.copyWith(
        selectedFeature: GisFeatureModel(
          id: selected.id,
          layerKey: selected.layerKey,
          titleAr: selected.titleAr,
          titleEn: selected.titleEn,
          props: <String, dynamic>{
            ...details,
            ...selected.props,
            'details_loaded': true,
          },
          geom: selected.geom,
          centroid: selected.centroid,
          isPublic: selected.isPublic,
        ),
        gisError: null,
      );
    } catch (_) {
      // Details loading is optional; keep the selected geometry card available.
    }
  }

  void clearSelection() {
    state = state.copyWith(
      clearSelectedWaqf: true,
      clearSelectedFeature: true,
      clearGovernoratePreviewFeature: true,
      clearCommunityPreviewFeature: true,
      clearBlockPreviewFeature: true,
      clearSitePreviewFeature: true,
      gisError: null,
      error: null,
    );
  }

  Future<void> setTemporarySearchReferenceLayer({
    required String? layerKey,
    String? labelAr,
    String? unitId,
  }) async {
    final key = (layerKey ?? '').trim();
    final label = (labelAr ?? '').trim();
    final previousKey = (state.temporarySearchReferenceLayerKey ?? '').trim();
    final previousLabel =
        (state.temporarySearchReferenceLayerLabel ?? '').trim();
    if (previousKey == key && previousLabel == label) return;

    _featureCache.clear();
    state = state.copyWith(
      temporarySearchReferenceLayerKey: key.isEmpty ? null : key,
      temporarySearchReferenceLayerLabel: label.isEmpty ? null : label,
      clearTemporarySearchReferenceLayer: key.isEmpty,
      clearSelectedFeature: true,
      clearSelectedWaqf: true,
      gisError: null,
    );
    await reloadGisFeatures(unitId: unitId);
  }

  Future<void> clearTemporarySearchReferenceLayer({String? unitId}) {
    return setTemporarySearchReferenceLayer(
      layerKey: null,
      labelAr: null,
      unitId: unitId,
    );
  }

  Future<void> setSettlementScope({
    String? lguCode,
    String? lguName,
    String? unitId,
  }) async {
    final code = (lguCode ?? '').trim();
    final name = (lguName ?? '').trim();
    final shouldClear = code.isEmpty && name.isEmpty;
    final previousCode = (state.settlementScopeLguCode ?? '').trim();
    final previousName = (state.settlementScopeLguName ?? '').trim();
    if (previousCode == code && previousName == name) return;

    _featureCache.clear();
    state = state.copyWith(
      settlementScopeLguCode: shouldClear ? null : code,
      settlementScopeLguName: shouldClear ? null : name,
      clearSettlementScope: shouldClear,
      clearSelectedFeature: true,
      clearSelectedWaqf: true,
      gisError: null,
    );
    await reloadGisFeatures(unitId: unitId);
  }

  Future<void> setActiveLayers(
    Iterable<String> layerIds, {
    String? unitId,
  }) async {
    final allowedKeys = state.gisLayers
        .where((layer) => layer.isActive && layer.isPublic)
        .map((layer) => layer.key)
        .toSet();
    allowedKeys.add('parcels_registered');
    allowedKeys.add(_palestineBoundaryFallbackLayerKey);
    final seen = <String>{};
    final next = <String>[];

    void add(String? rawKey) {
      final key = (rawKey ?? '').trim();
      if (key.isEmpty || !allowedKeys.contains(key)) return;
      if (seen.add(key)) next.add(key);
    }

    // Core operational visibility is zoom-driven. External callers may still
    // control optional analytical overlays, but cannot open/close the sovereign
    // zoom sequence.
    for (final key in _zoomDrivenLayerKeysForZoom(state.zoom)) {
      add(key);
    }
    for (final rawKey in _withoutRetiredLayerKeys(layerIds)) {
      final key = rawKey.trim();
      if (_isZoomGovernedLayerKey(key)) continue;
      add(key);
    }

    final nextOpacity = Map<String, double>.from(state.layerOpacity);
    for (final layer in state.gisLayers) {
      if (next.contains(layer.key)) {
        nextOpacity.putIfAbsent(layer.key, () => layer.defaultOpacity);
      }
    }

    _featureCache.clear();
    state = state.copyWith(activeLayers: next, layerOpacity: nextOpacity);
    await reloadGisFeatures(unitId: unitId);
  }

  Future<void> deactivateAllLayers({String? unitId}) async {
    await resetToCoreBoundaryLayers(unitId: unitId);
  }

  Future<void> resetToCoreBoundaryLayers({String? unitId}) async {
    _featureCache.clear();
    ++_modernExplorerBoundaryRequestSeq;
    state = state.copyWith(
      activeLayers: _zoomDrivenLayerKeysForZoom(state.zoom),
      gisFeatures: const [],
      clearModernExplorerBoundaryFeatures: true,
      clearGovernoratePreviewFeature: true,
      clearCommunityPreviewFeature: true,
      clearBlockPreviewFeature: true,
      clearSitePreviewFeature: true,
      clearSelectedFeature: true,
      clearSelectedWaqf: true,
      clearSettlementScope: true,
      clearTemporarySearchReferenceLayer: true,
      runtimeInfo: const MapRuntimeInfo(),
      gisError: null,
      error: null,
    );
    await reloadGisFeatures(unitId: unitId);
  }

  Future<void> toggleLayer(String layerId, {String? unitId}) async {
    if (_isRetiredNaturalBlocksLayerKey(layerId)) {
      state = state.copyWith(
        activeLayers: _withoutRetiredLayerKeys(state.activeLayers),
        gisError: 'طبقة natural_blocks القديمة غير معتمدة. استخدم natural_blocks_full فقط.',
      );
      await reloadGisFeatures(unitId: unitId);
      return;
    }

    if (_isZoomGovernedLayerKey(layerId)) {
      final next = _autoAdjustedActiveLayerKeys(state.activeLayers, state.zoom);
      if (!_sameLayerList(_withoutRetiredLayerKeys(state.activeLayers), next)) {
        _featureCache.clear();
        state = state.copyWith(activeLayers: next);
        await reloadGisFeatures(unitId: unitId);
      }
      return;
    }

    final current = _withoutRetiredLayerKeys(state.activeLayers)
        .where((key) => !_isZoomGovernedLayerKey(key))
        .toList();
    if (current.contains(layerId)) {
      current.remove(layerId);
    } else {
      current.add(layerId);
    }

    final next = _autoAdjustedActiveLayerKeys(current, state.zoom);
    final nextOpacity = Map<String, double>.from(state.layerOpacity);
    GisLayerModel? layer;
    for (final candidate in state.gisLayers) {
      if (candidate.key == layerId) {
        layer = candidate;
        break;
      }
    }
    if (layer != null) {
      nextOpacity.putIfAbsent(layerId, () => layer!.defaultOpacity);
    }
    _featureCache.clear();
    state = state.copyWith(
      activeLayers: next,
      layerOpacity: nextOpacity,
      clearSelectedFeature: true,
      clearSelectedWaqf: true,
    );
    await reloadGisFeatures(unitId: unitId);
  }

  void setLayerOpacity(String layerKey, double opacity) {
    final next = Map<String, double>.from(state.layerOpacity);
    next[layerKey] = opacity.clamp(0.0, 1.0).toDouble();
    state = state.copyWith(layerOpacity: next);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
