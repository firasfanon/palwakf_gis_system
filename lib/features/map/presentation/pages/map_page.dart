// lib/features/map/presentation/pages/map_page.dart
import 'dart:math' as math;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/enums.dart';
import '../../domain/models/gis_feature_model.dart';
import '../../domain/models/gis_layer_model.dart';
import '../../domain/models/lookup_item.dart';
import '../../domain/models/waqf_model.dart';
import '../providers/map_provider.dart';
import '../providers/map_ui_providers.dart';
import '../providers/toolbox_providers.dart';
import '../widgets/toolbox/toolbox_drawer.dart';
import '../widgets/toolbox/tool_sections/search_section.dart';
import '../../../../core/services/map_layers_refresh_bus.dart';
import '../../data/repositories/gis_repository.dart';
import '../../data/repositories/map_layer_manager_repository.dart';

const String _naturalBlocksFullLayerKey = 'natural_blocks_full';
const String _naturalBlocksOverviewLayerKey = 'natural_blocks_overview';
const String _guessingBlocksLayerKey = 'guessing_blocks';

enum _ModernExplorerTab { layers, search }


double? _firstQueryDouble(Map<String, String> query, List<String> keys) {
  for (final key in keys) {
    final raw = query[key]?.trim();
    if (raw == null || raw.isEmpty) continue;
    final parsed = double.tryParse(raw);
    if (parsed != null) return parsed;
  }
  return null;
}

String? _firstQueryText(Map<String, String> query, List<String> keys) {
  for (final key in keys) {
    final raw = query[key]?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
  }
  return null;
}

/// Runtime bridge command passed from Mustakshif Review Board into the real
/// explorer map. It is intentionally camera-only: it never toggles layers,
/// never mutates activeLayers, and never writes to GIS/core/waqf sources.
class PwfExplorerReviewMapCommand {
  const PwfExplorerReviewMapCommand({
    required this.recordId,
    required this.labelAr,
    required this.cameraCommand,
    this.historicalPoint,
    this.candidatePoint,
    this.bounds,
    this.bboxSouth,
    this.bboxWest,
    this.bboxNorth,
    this.bboxEast,
    this.source = 'mustakshif_review_board',
  });

  factory PwfExplorerReviewMapCommand.fromQuery(Map<String, String> query) {
    final recordId = _firstQueryText(query, const [
      'review_record_id',
      'record_id',
      'recordId',
      'msk_record_id',
    ]);
    final label = _firstQueryText(query, const [
      'label',
      'place_name_ar',
      'place',
      'title',
    ]);
    final camera = _firstQueryText(query, const [
      'camera',
      'cmd',
      'command',
      'camera_command',
    ]);

    final hLat = _firstQueryDouble(query, const ['historical_lat', 'h_lat', 'hlat']);
    final hLon = _firstQueryDouble(query, const ['historical_lon', 'h_lon', 'hlon']);
    final cLat = _firstQueryDouble(query, const ['candidate_lat', 'c_lat', 'clat']);
    final cLon = _firstQueryDouble(query, const ['candidate_lon', 'c_lon', 'clon']);
    final south = _firstQueryDouble(query, const ['bbox_south', 'south', 's']);
    final west = _firstQueryDouble(query, const ['bbox_west', 'west', 'w']);
    final north = _firstQueryDouble(query, const ['bbox_north', 'north', 'n']);
    final east = _firstQueryDouble(query, const ['bbox_east', 'east', 'e']);

    final historicalPoint = hLat == null || hLon == null ? null : LatLng(hLat, hLon);
    final candidatePoint = cLat == null || cLon == null ? null : LatLng(cLat, cLon);
    final bounds = south == null || west == null || north == null || east == null
        ? null
        : LatLngBounds(LatLng(south, west), LatLng(north, east));

    return PwfExplorerReviewMapCommand(
      recordId: recordId ?? '',
      labelAr: label ?? recordId ?? 'سجل مراجعة مستكشف',
      cameraCommand: camera ?? (bounds != null
          ? 'fit_bbox'
          : historicalPoint != null
              ? 'focus_historical_point'
              : candidatePoint != null
                  ? 'focus_candidate_centroid'
                  : 'show_placeholder_only'),
      historicalPoint: historicalPoint,
      candidatePoint: candidatePoint,
      bounds: bounds,
      bboxSouth: south,
      bboxWest: west,
      bboxNorth: north,
      bboxEast: east,
      source: query['source'] ?? 'mustakshif_review_board',
    );
  }

  final String recordId;
  final String labelAr;
  final String cameraCommand;
  final LatLng? historicalPoint;
  final LatLng? candidatePoint;
  final LatLngBounds? bounds;
  final double? bboxSouth;
  final double? bboxWest;
  final double? bboxNorth;
  final double? bboxEast;
  final String source;

  bool get hasEvidence => historicalPoint != null || candidatePoint != null || bounds != null;
  bool get hasRecordId => recordId.trim().isNotEmpty;

  LatLng? get preferredPoint => historicalPoint ?? candidatePoint;

  LatLng? get initialCenter {
    final b = bounds;
    if (b != null && bboxSouth != null && bboxNorth != null && bboxWest != null && bboxEast != null) {
      return LatLng(
        (bboxSouth! + bboxNorth!) / 2,
        (bboxWest! + bboxEast!) / 2,
      );
    }
    return preferredPoint;
  }

  double get suggestedZoom => bounds != null ? 16.0 : 15.0;

  String get governanceLine =>
      'review-map camera-only; no layer toggle; no activeLayers mutation; no GIS write';
}

const Map<String, String> _modernExplorerFeatureTypeLabels = {
  'mosques': 'مساجد',
  'maqamat': 'مقامات',
  'takaya': 'تكايا',
  'cemeteries': 'مقابر',
  'archaeological': 'مواقع أثرية',
};

class _ModernExplorerSectionSpec {
  const _ModernExplorerSectionSpec({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<_ModernExplorerLayerSpec> items;
}

class _ModernExplorerLayerSpec {
  const _ModernExplorerLayerSpec({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.defaultOn = false,
    this.isBaseMap = false,
    this.showLabelHint = false,
    this.employeeOnly = false,
    this.managerOnly = false,
    this.requiresScopedSelection = false,
    this.minZoom,
    this.keyHints = const [],
    this.arHints = const [],
    this.enHints = const [],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool defaultOn;
  final bool isBaseMap;
  final bool showLabelHint;

  /// UI governance only. RPC/RLS remain the real access boundary.
  final bool employeeOnly;
  final bool managerOnly;

  /// Dense layers such as settlement parcels must be requested only after the
  /// user narrows the scope or reaches a close zoom level.
  final bool requiresScopedSelection;
  final double? minZoom;

  final List<String> keyHints;
  final List<String> arHints;
  final List<String> enHints;
}

class _ModernExplorerLayerGate {
  const _ModernExplorerLayerGate.allowed() : reason = null;
  const _ModernExplorerLayerGate.blocked(this.reason);

  final String? reason;
  bool get allowed => reason == null;
}

const List<_ModernExplorerSectionSpec> _modernExplorerSections = [
  _ModernExplorerSectionSpec(
    title: 'القسم الأول: الطبقات الأساسية',
    subtitle: 'تُعرض بالترتيب التشغيلي: أول عنصر هو الأسفل وآخر عنصر هو الأعلى.',
    items: [
      _ModernExplorerLayerSpec(
        title: 'الخريطة الأساسية',
        subtitle: 'طبقة الخلفية / الخريطة المرئية',
        icon: Icons.map_outlined,
        defaultOn: true,
        isBaseMap: true,
      ),
      _ModernExplorerLayerSpec(
        title: 'حدود فلسطين',
        subtitle: 'حدود الضفة الغربية وقطاع غزة',
        icon: Icons.public,
        defaultOn: true,
        keyHints: [
          'westbank_gaza',
          'west_bank_gaza',
          'palestine',
          'palestine_boundary',
          'palestine_boundaries',
          'palestine_wb_gaza',
          'wb_gaza',
          'wb_gaza_boundary',
          'west_bank_and_gaza',
          'west_bank_gaza_boundary',
          'west_bank_and_gaza_boundary',
          'gaza_wb_boundary',
          'historical_boundary',
          'historical_boundaries',
          'historical_wb_gaza_boundary',
          'historical_palestine_boundary',
          'wb_gaza_historical_boundary',
        ],
        arHints: [
          'فلسطين',
          'حدود فلسطين',
          'الضفة وغزة',
          'الضفة الغربية وغزة',
          'حدود الضفة الغربية وقطاع غزة',
          'الحدود التاريخية',
          'حدود تاريخية',
        ],
        enHints: [
          'palestine',
          'palestine boundary',
          'west bank and gaza',
          'westbank gaza',
          'west bank gaza boundary',
          'historical boundary',
          'historical boundaries',
          'west bank and gaza boundary',
        ],
      ),
      _ModernExplorerLayerSpec(
        title: 'المحافظات',
        subtitle: 'حدود المحافظات الحديثة',
        icon: Icons.account_tree_outlined,
        keyHints: ['governorates_boundary', 'v_governorates_core', 'governorate'],
        arHints: ['المحافظات'],
        enHints: ['governorates', 'governorate boundaries'],
      ),
      _ModernExplorerLayerSpec(
        title: 'حدود التجمعات',
        subtitle: 'حدود التجمعات السكانية — تظهر عند زوم 10 ولا تُفعّل تلقائيًا',
        icon: Icons.grid_view_rounded,
        minZoom: 10.0,
        keyHints: ['communities_boundary', 'v_communities_core', 'community'],
        arHints: ['التجمعات', 'حدود التجمعات'],
        enHints: ['communities', 'community boundaries'],
      ),
      _ModernExplorerLayerSpec(
        title: 'أسماء التجمعات',
        subtitle: 'تظهر عند زوم 10.5 ولا تُفعّل تلقائيًا',
        icon: Icons.label_outline,
        minZoom: 10.5,
        keyHints: ['community_labels', 'communities_labels', 'v_communities_labels', 'community_names'],
        arHints: ['أسماء التجمعات', 'تسميات التجمعات'],
        enHints: ['community labels', 'community names'],
      ),
      _ModernExplorerLayerSpec(
        title: 'الأحواض الطبيعية',
        subtitle: 'المصدر السيادي: natural_blocks_full',
        icon: Icons.layers_outlined,
        keyHints: ['natural_blocks_full'],
        arHints: ['الأحواض الطبيعية'],
        enHints: ['natural blocks full'],
      ),
      _ModernExplorerLayerSpec(
        title: 'أطلس',
        subtitle: 'طبقة أطلس المرجعية من gis_ref إن وُجدت',
        icon: Icons.travel_explore_outlined,
        keyHints: ['gis_ref_atlas', 'atlas', 'atlas_layer', 'atlas_wb', 'atlas_ps'],
        arHints: ['أطلس', 'اطلس'],
        enHints: ['atlas'],
      ),
      _ModernExplorerLayerSpec(
        title: 'حدود الهيئات المحلية',
        subtitle: 'حدود LGUs الحديثة',
        icon: Icons.location_city_outlined,
        keyHints: ['lgus_boundary', 'v_lgus_core'],
        arHints: ['حدود الهيئات المحلية'],
        enHints: ['lgu boundaries', 'local authority boundaries'],
      ),
      _ModernExplorerLayerSpec(
        title: 'أسماء الهيئات المحلية',
        subtitle: 'طبقة أسماء/تسميات الهيئات المحلية إن وُجدت',
        icon: Icons.sell_outlined,
        keyHints: ['lgu_labels', 'lgus_labels', 'v_lgus_labels', 'lgu_names'],
        arHints: ['أسماء الهيئات المحلية', 'تسميات الهيئات المحلية'],
        enHints: ['lgu labels', 'lgu names'],
      ),
      _ModernExplorerLayerSpec(
        title: 'أحواض التخمين',
        subtitle: 'طبقة أحواض التخمين إن وُجدت',
        icon: Icons.layers_clear_outlined,
        keyHints: ['guess_blocks', 'guessing_blocks', 'guessed_blocks', 'estimated_blocks', 'takmeen', 'takhmin'],
        arHints: ['أحواض التخمين', 'التخمين'],
        enHints: ['guess blocks', 'estimated blocks'],
      ),
      _ModernExplorerLayerSpec(
        title: 'المواقع',
        subtitle: 'حدود المواقع داخل الهيئة المحلية، تظهر بالزوم فوق طبقة الهيئات',
        icon: Icons.location_on_outlined,
        keyHints: ['locations', 'gis_locations', 'operational_locations'],
        arHints: ['المواقع', 'طبقة المواقع'],
        enHints: ['locations', 'operational locations'],
      ),
      _ModernExplorerLayerSpec(
        title: 'أحواض التسوية',
        subtitle: 'أحواض/قطع التسوية إن وُجدت، وتظهر عند الزوم التشغيلي',
        icon: Icons.fact_check_outlined,
        managerOnly: true,
        minZoom: 15.0,
        keyHints: ['parcels_registered', 'settlement_blocks', 'taswyeh_blocks', 'settlement_basins', 'settlement'],
        arHints: ['أحواض التسوية', 'التسوية'],
        enHints: ['settlement blocks', 'settlement basins'],
      ),
    ],
  ),
  _ModernExplorerSectionSpec(
    title: 'قسم الطبقات الاختيارية: الضفة الغربية',
    subtitle: 'غير مفعلة افتراضيًا وتعرض الأسماء عند التكبير المناسب.',
    items: [
      _ModernExplorerLayerSpec(
        title: 'المساجد - الضفة الغربية',
        subtitle: 'مع عرض اسم المسجد عند التكبير',
        icon: Icons.account_balance_outlined,
        showLabelHint: true,
        keyHints: ['gis_waqf_mosque_wb'],
        arHints: ['المساجد - الضفة', 'مساجد الضفة'],
        enHints: ['mosques - west bank', 'mosque wb'],
      ),
      _ModernExplorerLayerSpec(
        title: 'المقامات - الضفة الغربية',
        subtitle: 'مع عرض اسم المقام',
        icon: Icons.account_balance_outlined,
        showLabelHint: true,
        keyHints: ['gis_waqf_maqamat_wb'],
        arHints: ['المقامات - الضفة', 'المقامات'],
        enHints: ['maqamat - west bank', 'maqamat'],
      ),
      _ModernExplorerLayerSpec(
        title: 'التكايا - الضفة الغربية',
        subtitle: 'مع عرض اسم التكية عند توفر الطبقة',
        icon: Icons.volunteer_activism_outlined,
        showLabelHint: true,
        keyHints: ['gis_waqf_takaya_wb', 'takaya_wb', 'zawaya_wb'],
        arHints: ['التكايا', 'الزوايا'],
        enHints: ['takaya', 'zawaya'],
      ),
      _ModernExplorerLayerSpec(
        title: 'المقابر - الضفة الغربية',
        subtitle: 'مع عرض اسم المقبرة',
        icon: Icons.park_outlined,
        showLabelHint: true,
        keyHints: ['gis_waqf_cemeteries_wb'],
        arHints: ['المقابر - الضفة', 'المقابر'],
        enHints: ['cemeteries - west bank', 'cemeteries'],
      ),
      _ModernExplorerLayerSpec(
        title: 'المواقع الأثرية - الضفة الغربية',
        subtitle: 'مع عرض اسم الموقع الأثري',
        icon: Icons.account_balance,
        showLabelHint: true,
        keyHints: ['gis_waqf_archaeological_wb'],
        arHints: ['المواقع الأثرية', 'آثار', 'اثرية'],
        enHints: ['archaeological sites - west bank', 'archaeological'],
      ),
    ],
  ),
  _ModernExplorerSectionSpec(
    title: 'قسم الطبقات الاختيارية: قطاع غزة',
    subtitle: 'غير مفعلة افتراضيًا.',
    items: [
      _ModernExplorerLayerSpec(
        title: 'المساجد - غزة',
        subtitle: 'مع عرض اسم المسجد عند التكبير',
        icon: Icons.account_balance,
        showLabelHint: true,
        keyHints: ['gis_waqf_mosque_gaza'],
        arHints: ['المساجد - غزة', 'مساجد غزة'],
        enHints: ['mosques - gaza', 'mosque gaza'],
      ),
    ],
  ),
];

bool _isPointLikeGeometry(Map<String, dynamic>? geometry) {
  final type = geometry?['type']?.toString();
  return type == 'Point' || type == 'MultiPoint';
}

LatLng? _extractCoordinates(Map<String, dynamic>? geometry) {
  if (geometry == null) return null;
  try {
    final type = geometry['type'];
    final coords = geometry['coordinates'];

    if (type == 'Point' && coords is List && coords.length >= 2) {
      return LatLng(
          (coords[1] as num).toDouble(), (coords[0] as num).toDouble());
    }

    if (coords is List && coords.isNotEmpty) {
      dynamic cursor = coords;
      while (cursor is List && cursor.isNotEmpty) {
        final first = cursor[0];
        if (first is List &&
            first.length >= 2 &&
            first[0] is num &&
            first[1] is num) {
          return LatLng(
              (first[1] as num).toDouble(), (first[0] as num).toDouble());
        }
        cursor = first;
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

List<LatLng> _toLatLngList(dynamic ring) {
  if (ring is! List) return const [];
  final pts = <LatLng>[];
  for (final p in ring) {
    if (p is List && p.length >= 2 && p[0] is num && p[1] is num) {
      pts.add(LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()));
    }
  }
  return pts;
}

class _PointFeatureCluster {
  const _PointFeatureCluster({
    required this.center,
    required this.features,
  });

  final LatLng center;
  final List<GisFeatureModel> features;

  bool get isCluster => features.length > 1;

  bool containsFeatureId(String? id) {
    if (id == null) return false;
    return features.any((feature) => feature.id == id);
  }
}

class MapPage extends ConsumerStatefulWidget {
  final String? initialWaqfId;
  final LatLng? initialCenter;
  final double? initialZoom;
  final PwfExplorerReviewMapCommand? reviewMapCommand;
  final bool embeddedInAdmin;

  const MapPage({
    super.key,
    this.initialWaqfId,
    this.initialCenter,
    this.initialZoom,
    this.reviewMapCommand,
    this.embeddedInAdmin = false,
  });

  factory MapPage.fromQuery({
    Key? key,
    String? initialWaqfId,
    required Map<String, String> queryParameters,
    bool embeddedInAdmin = false,
  }) {
    final reviewCommand = PwfExplorerReviewMapCommand.fromQuery(queryParameters);
    final queryLat = _firstQueryDouble(queryParameters, const ['lat', 'latitude']);
    final queryLng = _firstQueryDouble(queryParameters, const ['lng', 'lon', 'longitude']);
    final queryZoom = _firstQueryDouble(queryParameters, const ['z', 'zoom']);
    final queryCenter = queryLat == null || queryLng == null ? null : LatLng(queryLat, queryLng);

    return MapPage(
      key: key,
      initialWaqfId: initialWaqfId,
      initialCenter: reviewCommand.hasEvidence ? reviewCommand.initialCenter : queryCenter,
      initialZoom: reviewCommand.hasEvidence ? reviewCommand.suggestedZoom : queryZoom,
      reviewMapCommand: reviewCommand.hasEvidence || reviewCommand.hasRecordId ? reviewCommand : null,
      embeddedInAdmin: embeddedInAdmin,
    );
  }

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  static const double _mapMinZoom = 6.5;
  static const double _mapMaxZoom = 18.0;
  static const double _openingZoom = 7.5;
  static const double _governoratesMinZoom = 9.0;
  static const double _communitiesMinZoom = 10.0;
  static const double _naturalBlocksMinZoom = 11.0;
  static const double _naturalBlockLabelsMinZoom = 11.5;
  static const double _lgusMinZoom = 12.0;
  static const double _lguLabelsMinZoom = 12.5;
  static const double _locationsMinZoom = 13.0;
  static const double _locationLabelsMinZoom = 13.5;
  static const double _guessingBlocksMinZoom = 14.0;
  static const double _guessingParcelLabelsMinZoom = 14.5;
  static const double _settlementParcelsMinZoom = 15.0;
  static const double _settlementParcelLabelsMinZoom = 16.5;

  // --- rotation / north reset ---
  double _rotationDeg = 0.0;
  StreamSubscription? _mapEventSub;
  bool get _isRotated => _rotationDeg.abs() > 0.0001;

  void _resetNorth() {
    try {
      _mapController.rotate(0.0);
    } catch (_) {}
    if (mounted) {
      setState(() => _rotationDeg = 0.0);
    }
  }

  late final MapController _mapController;
  late final ProviderSubscription<MapState> _mapSub;
  late final ProviderSubscription<String?> _toolSub;
  late final ProviderSubscription<int> _layersRefreshSub;
  late final ProviderSubscription<LatLng?> _gotoMarkerSub;
  bool _reviewMapCommandApplied = false;

  final TextEditingController _placeCtrl = TextEditingController();
  bool _placeLoading = false;
  List<_PlaceResult> _placeResults = const [];
  Timer? _placeSearchDebounce;
  int _placeSearchRequestSeq = 0;
  int _identifyRequestSeq = 0;


  bool _toolboxVisible = false;
  bool _modernExplorerVisible = false;
  _ModernExplorerTab _modernExplorerTab = _ModernExplorerTab.layers;
  String? _modernExplorerGovernorateFilter;
  String? _modernExplorerLocalityFilter;
  String? _modernExplorerFeatureTypeFilter;
  bool _modernExplorerFeatureLayerSelectionApplied = false;
  List<GisFeatureModel> _modernExplorerFilterSourceFeatures = const [];
  List<LookupItem> _modernExplorerGovernorateItems = const [];
  List<LookupItem> _modernExplorerLguItems = const [];
  String? _modernExplorerLguItemsGovernorateScope;
  bool _modernExplorerFilterSourceLoading = false;
  bool _modernExplorerLookupSourceLoading = false;
  int _modernExplorerLookupRequestSeq = 0;
  int _modernExplorerFilterSourceRequestSeq = 0;
  String? _modernExplorerFilterSourceError;
  String? _modernExplorerLookupSourceError;
  final Map<String, _ExplorerLayerVisualOverride> _explorerLayerVisualOverrides = {};

  List<GisFeatureModel>? _cachedPolygonFeatureSource;
  String? _cachedPolygonStyleSignature;
  List<Polygon> _cachedGisPolygons = const [];

  static const double _toolboxTopOffset = 72;
  static const double _toolboxBottomOffset = 36;
  static const double _toolboxRightMargin = 0;
  static const double _leftControlsTopOffset = 118;


  List<LatLng> _selectionBoxPolygonPoints(List<LatLng> points) {
    if (points.length < 2) return points;
    final a = points[0];
    final b = points[1];
    final minLat = math.min(a.latitude, b.latitude);
    final maxLat = math.max(a.latitude, b.latitude);
    final minLng = math.min(a.longitude, b.longitude);
    final maxLng = math.max(a.longitude, b.longitude);
    return <LatLng>[
      LatLng(minLat, minLng),
      LatLng(minLat, maxLng),
      LatLng(maxLat, maxLng),
      LatLng(maxLat, minLng),
    ];
  }

  void _applyReviewMapCommandOnce() {
    if (_reviewMapCommandApplied) return;
    final command = widget.reviewMapCommand;
    if (command == null || !command.hasEvidence) return;
    _reviewMapCommandApplied = true;

    try {
      final bounds = command.bounds;
      if (bounds != null) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(70),
          ),
        );
      } else {
        final point = command.preferredPoint;
        if (point != null) {
          _mapController.move(point, _clampOperationalZoom(command.suggestedZoom));
        }
      }
      final point = command.preferredPoint;
      if (point != null) {
        ref.read(gotoMarkerProvider.notifier).state = point;
      }
    } catch (_) {
      // The command is camera-only. If flutter_map is not attached yet, keep
      // the overlay visible; the user can press the focus button in the banner.
    }
  }

  void _focusReviewMapCommand() {
    _reviewMapCommandApplied = false;
    _applyReviewMapCommandOnce();
  }

  void _returnToReviewBoardRecord() {
    final recordId = widget.reviewMapCommand?.recordId.trim();
    final uri = Uri(
      path: '/admin/mustakshif/review-board',
      queryParameters: {
        if (recordId != null && recordId.isNotEmpty) 'record_id': recordId,
      },
    );
    context.go(uri.toString());
  }

  void _clearVisualFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
  void _moveToBridgeTarget(LatLng point) {
    try {
      final currentZoom = _safeZoom();
      final targetZoom = currentZoom < _settlementParcelsMinZoom ? _settlementParcelsMinZoom : currentZoom;
      _mapController.move(point, _clampOperationalZoom(targetZoom));
    } catch (_) {
      // MapController may still be attaching during first frame; the marker
      // remains visible and the next provider update will move the map.
    }
  }


  String _featureIdentity(GisFeatureModel? feature) {
    if (feature == null) return '';
    return '${feature.layerKey}|${feature.id}|${feature.displayTitle}';
  }

  String _featureListIdentity(List<GisFeatureModel> features) {
    if (features.isEmpty) return '';
    return features.map(_featureIdentity).join('||');
  }

  GisFeatureModel? _priorityModernBoundaryFeature(MapState state) {
    final boundaries = state.modernExplorerBoundaryFeatures
        .where((feature) => _isPolygonGeometry(feature.geom))
        .toList(growable: false);
    if (boundaries.isEmpty) return null;

    final scopeCode = (state.settlementScopeLguCode ?? '').trim();
    final scopeName = (state.settlementScopeLguName ?? '').trim();
    if (scopeCode.isNotEmpty || scopeName.isNotEmpty) {
      for (final feature in boundaries) {
        final featureCode = _firstNonEmptyProp(feature, const [
          'lgusb_no',
          'lgu_no',
          'lgus_code',
          'lgus_xcode',
          'community_no',
          'code',
        ]);
        final featureName = _firstNonEmptyProp(feature, const [
          'lgusn',
          'lgun',
          'lgu_name_ar',
          'communityn',
          'community_name_ar',
          'name_ar',
          'label_ar',
          'name',
        ]);
        if (_sameExplorerValue(featureCode, scopeCode) ||
            _sameExplorerValue(featureCode, scopeName) ||
            _sameExplorerValue(featureName, scopeName) ||
            _sameExplorerValue(featureName, scopeCode)) {
          return feature;
        }
      }
    }

    return boundaries.first;
  }

  GisFeatureModel? _priorityPreviewFeature(MapState state) {
    return state.sitePreviewFeature ??
        state.blockPreviewFeature ??
        state.communityPreviewFeature ??
        state.governoratePreviewFeature;
  }

  void _focusFeature(GisFeatureModel feature, MapState next) {
    final bounds = _boundsFromGeometry(feature.geom);
    if (bounds != null) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(28),
        ),
      );
    } else {
      final coords = _extractCoordinates(feature.centroid ?? feature.geom);
      if (coords != null) {
        final targetZoom = next.zoom < 12 ? 12.0 : next.zoom;
        _mapController.move(coords, _clampOperationalZoom(targetZoom));
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _mapController = ref.read(mapControllerProvider);

    // Track rotation (flutter_map ^6): used for compass visibility & needle rotation.
    _mapEventSub = _mapController.mapEventStream.listen((event) {
      if (!mounted) return;
      final rot = event.camera.rotation;
      if ((rot - _rotationDeg).abs() > 0.0001) {
        setState(() => _rotationDeg = rot);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapNotifierProvider.notifier).bootstrapGis();
      final pendingGoto = ref.read(gotoMarkerProvider);
      if (pendingGoto != null) {
        _moveToBridgeTarget(pendingGoto);
      }
      _applyReviewMapCommandOnce();
    });

    _gotoMarkerSub = ref.listenManual<LatLng?>(gotoMarkerProvider, (prev, next) {
      if (!mounted || next == null) return;
      if (prev != null &&
          (prev.latitude - next.latitude).abs() < 0.000001 &&
          (prev.longitude - next.longitude).abs() < 0.000001) {
        return;
      }
      _moveToBridgeTarget(next);
    });

    // When admin toggles layers, refresh map layers/features without reloading the page.
    _layersRefreshSub =
        ref.listenManual<int>(mapLayersRefreshTickProvider, (prev, next) {
      if (prev == next) return;
      ref.read(mapNotifierProvider.notifier).bootstrapGis();
    });

    // Move map when selection changes (Waqf OR GisFeature)
    _mapSub = ref.listenManual<MapState>(mapNotifierProvider, (prev, next) {
      final prevWaqfId = prev?.selectedWaqf?.id;
      final nextWaqf = next.selectedWaqf;

      final prevFeatureId = prev?.selectedFeature?.id;
      final nextFeature = next.selectedFeature;

      final prevPreviewIdentity = prev == null
          ? ''
          : _featureIdentity(_priorityPreviewFeature(prev));
      final nextPreviewIdentity = _featureIdentity(_priorityPreviewFeature(next));
      final prevModernBoundaryIdentity = prev == null
          ? ''
          : _featureListIdentity(prev.modernExplorerBoundaryFeatures);
      final nextModernBoundaryIdentity =
          _featureListIdentity(next.modernExplorerBoundaryFeatures);

      if (nextWaqf != null && nextWaqf.id != prevWaqfId) {
        final coords = _extractCoordinates(nextWaqf.geometry);
        if (coords != null) {
          final targetZoom = next.zoom < _settlementParcelsMinZoom ? _settlementParcelsMinZoom : next.zoom;
          _mapController.move(coords, _clampOperationalZoom(targetZoom));
        }
      } else if (nextFeature != null && nextFeature.id != prevFeatureId) {
        _focusFeature(nextFeature, next);
      } else {
        final previewFeature = _priorityPreviewFeature(next);
        if (previewFeature != null && nextPreviewIdentity != prevPreviewIdentity) {
          _focusFeature(previewFeature, next);
        } else if (nextModernBoundaryIdentity != prevModernBoundaryIdentity) {
          final boundaryFeature = _priorityModernBoundaryFeature(next);
          if (boundaryFeature != null) _focusFeature(boundaryFeature, next);
        }
      }
    });

    // React to map tools actions (show coords, share, go-to, open layers)
    _toolSub = ref.listenManual<String?>(activeToolProvider, (prev, next) {
      if (!mounted || next == null) return;

      void clearTool() => ref.read(activeToolProvider.notifier).state = null;

      if (next == 'layers') {
        ref.read(activeToolSectionProvider.notifier).state = ToolSection.layers;
        clearTool();
        return;
      }

      if (next == 'show_coords') {
        final current = ref.read(showCoordinatesProvider);
        ref.read(showCoordinatesProvider.notifier).state = !current;
        clearTool();
        return;
      }

      if (next == 'share') {
        final p = ref.read(lastTapLatLngProvider);
        final center = p ?? _safeCenter();
        final zoom = _safeZoom();
        final uri = Uri(
          path: '/#/map',
          queryParameters: {
            'lat': center.latitude.toStringAsFixed(6),
            'lng': center.longitude.toStringAsFixed(6),
            'z': zoom.toStringAsFixed(2),
          },
        );
        Clipboard.setData(ClipboardData(text: uri.toString()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نسخ رابط الموقع')),
        );
        clearTool();
        return;
      }

      if (next == 'coordinates') {
        clearTool();
        _openGoToDialog();
        return;
      }

      if (next == 'measure_distance' || next == 'measure_area') {
        return;
      }

      if (next == 'draw' || next == 'directions') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('هذه الأداة قيد التطوير في النسخة الحالية')),
        );
        clearTool();
        return;
      }
    });
  }

  @override
  void dispose() {
    _mapEventSub?.cancel();
    _placeSearchDebounce?.cancel();
    _placeCtrl.dispose();
    _mapSub.close();
    _toolSub.close();
    _layersRefreshSub.close();
    _gotoMarkerSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapNotifierProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);
    final baseKey = ref.watch(baseMapProvider);
    final showBaseMap = ref.watch(showBaseMapProvider);
    final fallbackDark = baseKey == 'dark' || isDarkMode;
    final settlementModeNoRoadLabels = mapState.zoom >= _settlementParcelsMinZoom;
    final fallbackTileTemplate = _fallbackTileTemplate(
      baseKey: baseKey,
      fallbackDark: fallbackDark,
      noRoadLabels: settlementModeNoRoadLabels,
    );

    final lastTap = ref.watch(lastTapLatLngProvider);
    final showCoords = ref.watch(showCoordinatesProvider);
    final snapPoint = ref.watch(snapPointProvider);
    final snapEnabled = ref.watch(snapEnabledProvider);
    final gotoMarker = ref.watch(gotoMarkerProvider);
    final measureMode = ref.watch(measureModeProvider);
    final measurePoints = ref.watch(measurePointsProvider);
    final measureResultLabel = ref.watch(measureResultLabelProvider);
    final drawShape = ref.watch(drawShapeTypeProvider);
    final drawEditing = ref.watch(drawEditingProvider);
    final drawPoints = ref.watch(drawPointsProvider);
    final directionsStart = ref.watch(directionsStartProvider);
    final directionsEnd = ref.watch(directionsEndProvider);
    final directionsPick = ref.watch(directionsPickTargetProvider);
    final realInteractionMode = ref.watch(realMapInteractionModeProvider);
    final selectionBoxPoints = ref.watch(selectionBoxPointsProvider);

    final rasterBase = _findRasterLayer(mapState.gisLayers, baseKey);

    // Build style map for vector layers, including UI style overrides.
    final layerStyle = _buildEffectiveLayerStyle(mapState);

    // The low-zoom overview layer is hidden from the public layer catalog so
    // users still see only the sovereign natural_blocks_full layer. Reuse the
    // public style for its derived render key to keep visual continuity.
    final naturalBlocksStyle = layerStyle[_naturalBlocksFullLayerKey];
    if (naturalBlocksStyle != null &&
        !layerStyle.containsKey(_naturalBlocksOverviewLayerKey)) {
      layerStyle[_naturalBlocksOverviewLayerKey] = <String, dynamic>{
        ...naturalBlocksStyle,
        'weight': 0.9,
        'fillOpacity': 0.10,
      };
    }

    final renderedGisFeatures = _filterMapBehaviorFeatures(
      mapState.gisFeatures,
      mapState,
    );

    final rawPointFeatures = renderedGisFeatures.where((f) {
      // Only render real point geometries as point markers. Polygon layers have
      // centroids for labels and hit-testing only; treating those centroids as
      // points caused parcel/location-style pins to appear over settlement parcels.
      if (_isZoomDrivenBoundaryLayerKey(f.layerKey) ||
          _isZoomDrivenSettlementLayerKey(f.layerKey) ||
          _isZoomDrivenLocationLayerKey(f.layerKey)) {
        return false;
      }
      return _isPointLikeGeometry(f.geom);
    }).toList();
    final pointFeatures = _applyModernExplorerPointFilters(
      rawPointFeatures,
      boundaryFeatures: mapState.modernExplorerBoundaryFeatures,
    );
    final pointLayerCounts = <String, int>{};
    for (final feature in pointFeatures) {
      pointLayerCounts[feature.layerKey] =
          (pointLayerCounts[feature.layerKey] ?? 0) + 1;
    }
    final pointClusters = _clusterPointFeatures(
      pointFeatures,
      zoom: mapState.zoom,
    );

    // Dense layers such as natural_blocks_full should not rebuild thousands of
    // Polygon objects on every unrelated widget rebuild. Cache by source-list
    // identity and relevant style signature; the cache is invalidated whenever
    // GIS features or layer styling changes.
    final gisPolygons = _buildCachedPolygons(renderedGisFeatures, layerStyle);
    final boundaryLabelMarkers = _buildBoundaryLabelMarkers(
      renderedGisFeatures,
      zoom: mapState.zoom,
    );
    final settlementParcelLabelMarkers = _buildSettlementParcelLabelMarkers(
      renderedGisFeatures,
      mapState: mapState,
      onTap: (feature) => ref
          .read(mapNotifierProvider.notifier)
          .selectGisFeature(feature),
    );

    final previewOverlayFeatures = <MapEntry<int, GisFeatureModel>>[
      if (mapState.governoratePreviewFeature != null)
        MapEntry(0, mapState.governoratePreviewFeature!),
      if (mapState.communityPreviewFeature != null)
        MapEntry(1, mapState.communityPreviewFeature!),
      if (mapState.blockPreviewFeature != null)
        MapEntry(2, mapState.blockPreviewFeature!),
      if (mapState.sitePreviewFeature != null)
        MapEntry(3, mapState.sitePreviewFeature!),
    ];

    final selectedOverlayFeature = mapState.selectedFeature;
    final selectedOverlayPoint = selectedOverlayFeature == null
        ? null
        : _extractCoordinates(
            selectedOverlayFeature.centroid ?? selectedOverlayFeature.geom);

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            Positioned.fill(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          widget.initialCenter ?? const LatLng(31.85, 35.00),
                      initialZoom: _clampOperationalZoom(widget.initialZoom ?? _openingZoom),
                      onTap: (_, latlng) {
                        _clearVisualFocus();
                        ref.read(lastTapLatLngProvider.notifier).state = latlng;
                        if (_placeResults.isNotEmpty) {
                          setState(() => _placeResults = const []);
                        }

                        final pickTarget =
                            ref.read(directionsPickTargetProvider);
                        if (pickTarget != null) {
                          if (pickTarget == 'start') {
                            ref.read(directionsStartProvider.notifier).state =
                                latlng;
                          } else {
                            ref.read(directionsEndProvider.notifier).state =
                                latlng;
                          }
                          ref
                              .read(directionsPickTargetProvider.notifier)
                              .state = null;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(pickTarget == 'start'
                                    ? 'تم تحديد نقطة البداية'
                                    : 'تم تحديد نقطة الوصول')),
                          );
                          return;
                        }

                        final activeDrawShape = ref.read(drawShapeTypeProvider);
                        final isDrawEditing = ref.read(drawEditingProvider);
                        if (activeDrawShape != null && isDrawEditing) {
                          final pts = [...ref.read(drawPointsProvider)];
                          pts.add(latlng);
                          ref.read(drawPointsProvider.notifier).state = pts;
                          return;
                        }

                        final currentMeasure = ref.read(measureModeProvider);
                        if (currentMeasure != null) {
                          final pts = [...ref.read(measurePointsProvider)];
                          pts.add(latlng);
                          ref.read(measurePointsProvider.notifier).state = pts;
                          ref.read(measureResultLabelProvider.notifier).state =
                              _computeMeasureLabel(pts, currentMeasure);
                          return;
                        }

                        final activeToolsSubPanel =
                            ref.read(activeToolsSubPanelProvider);
                        if (activeToolsSubPanel == ToolsSubPanel.realInteractions) {
                          final realMode = ref.read(realMapInteractionModeProvider);
                          if (realMode == ExplorerRealMapInteractionMode.identify) {
                            _identifyAtPoint(latlng, mapState);
                            return;
                          }
                          if (realMode == ExplorerRealMapInteractionMode.coordinatePicker) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تم التقاط الإحداثية: '
                                  '${latlng.latitude.toStringAsFixed(6)}, '
                                  '${latlng.longitude.toStringAsFixed(6)}',
                                ),
                              ),
                            );
                            return;
                          }
                          if (realMode == ExplorerRealMapInteractionMode.selectionBox) {
                            final current = ref.read(selectionBoxPointsProvider);
                            final nextPoints = current.length >= 2
                                ? <LatLng>[latlng]
                                : <LatLng>[...current, latlng];
                            ref.read(selectionBoxPointsProvider.notifier).state =
                                nextPoints;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  nextPoints.length < 2
                                      ? 'تم تثبيت النقطة الأولى للنطاق.'
                                      : 'تم تثبيت نطاق التحديد.',
                                ),
                              ),
                            );
                            return;
                          }
                        }
                        if (activeToolsSubPanel == ToolsSubPanel.identify) {
                          _identifyAtPoint(latlng, mapState);
                          return;
                        }
                        if (activeToolsSubPanel == ToolsSubPanel.reportIssue) {
                          _prepareReportDraftAtPoint(latlng, mapState);
                          return;
                        }

                        final settlementHit = _findSettlementLayerHit(
                          latlng,
                          _filterMapBehaviorFeatures(mapState.gisFeatures, mapState),
                          mapState.zoom,
                        );
                        if (settlementHit != null) {
                          ref
                              .read(mapNotifierProvider.notifier)
                              .selectGisFeature(settlementHit.feature);
                          ref.read(identifyResultProvider.notifier).state =
                              MapIdentifyResult(
                            point: latlng,
                            feature: settlementHit.feature,
                            distanceMeters: settlementHit.distanceMeters,
                            source: 'local_settlement_layer',
                            candidatesCount: 1,
                            message: 'تم عرض معلومات قطعة/حوض التسوية من الطبقة المحمّلة.',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم تحديد قطعة التسوية: ${settlementHit.feature.displayTitle}',
                              ),
                            ),
                          );
                          return;
                        }

                        if (snapEnabled) {
                          final snap = _findSnap(
                              latlng, mapState.gisFeatures, mapState.zoom);
                          if (snap != null) {
                            ref.read(snapPointProvider.notifier).state =
                                snap.point;
                            ref
                                .read(mapNotifierProvider.notifier)
                                .selectGisFeature(snap.feature);
                          } else {
                            ref.read(snapPointProvider.notifier).state = null;
                            ref
                                .read(mapNotifierProvider.notifier)
                                .clearSelection();
                          }
                        } else {
                          ref.read(snapPointProvider.notifier).state = null;
                          ref
                              .read(mapNotifierProvider.notifier)
                              .clearSelection();
                        }
                      },
                      onPositionChanged: (pos, hasGesture) {
                        final currentZoom = pos.zoom ?? mapState.zoom;
                        final clampedZoom = _clampOperationalZoom(currentZoom);
                        if ((currentZoom - clampedZoom).abs() > 0.0001) {
                          _mapController.move(_safeCenter(), clampedZoom);
                          return;
                        }

                        final b = pos.bounds;
                        if (b != null) {
                          final sw = b.southWest;
                          final ne = b.northEast;

                          ref.read(mapNotifierProvider.notifier).updateViewport(
                                ViewportBounds(
                                  west: sw.longitude,
                                  south: sw.latitude,
                                  east: ne.longitude,
                                  north: ne.latitude,
                                ),
                                zoom: clampedZoom,
                              );
                        }
                      },
                    ),
                    children: [
                      // Fallback base (controlled by Modern Explorer)
                      if (showBaseMap)
                        TileLayer(
                          urlTemplate: fallbackTileTemplate,
                          userAgentPackageName: 'com.palwakf.explorer',
                        ),

                      // Raster base from DB (Sentinel-2 etc.) if selected
                      if (showBaseMap && rasterBase != null)
                        TileLayer(
                          urlTemplate: rasterBase.urlTemplate,
                          userAgentPackageName: 'com.palwakf.explorer',
                          // Some providers may require headers/cors handling; keep minimal here.
                        ),

                      // Vector polygons (boundaries)
                      if (gisPolygons.isNotEmpty)
                        PolygonLayer(
                          polygons: gisPolygons,
                        ),

                      if (boundaryLabelMarkers.isNotEmpty)
                        MarkerLayer(markers: boundaryLabelMarkers),

                      if (settlementParcelLabelMarkers.isNotEmpty)
                        MarkerLayer(markers: settlementParcelLabelMarkers),


                      for (final entry in previewOverlayFeatures)
                        if (_isPolygonGeometry(entry.value.geom))
                          PolygonLayer(
                            polygons: _buildPreviewOverlayPolygons(
                              entry.value,
                              level: entry.key,
                            ),
                          ),

                      for (final entry in previewOverlayFeatures)
                        if (_extractCoordinates(entry.value.centroid ?? entry.value.geom) != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _extractCoordinates(entry.value.centroid ?? entry.value.geom)!,
                                width: 220,
                                height: 44,
                                child: IgnorePointer(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: _previewOverlayBorderColor(entry.key),
                                          width: 1.4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.10),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _previewOverlayLabelText(entry.value, level: entry.key),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: _previewOverlayBorderColor(entry.key),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                      if (selectedOverlayFeature != null &&
                          _isPolygonGeometry(selectedOverlayFeature.geom))
                        PolygonLayer(
                          polygons: _buildSelectedOverlayPolygons(
                              selectedOverlayFeature),
                        ),

                      if (selectedOverlayFeature != null &&
                          selectedOverlayPoint != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: selectedOverlayPoint,
                              width: 180,
                              height: 44,
                              child: IgnorePointer(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                          color: PwfColors.royalRed,
                                          width: 1.4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.12),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      selectedOverlayFeature.displayTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: PwfColors.royalRed,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      // Waqf markers (from search table; optional)
                      if (mapState.waqfResults.isNotEmpty)
                        MarkerLayer(
                          markers: mapState.waqfResults
                              .map((waqf) {
                                final coords =
                                    _extractCoordinates(waqf.geometry);
                                if (coords == null) return null;

                                final isSelected =
                                    mapState.selectedWaqf?.id == waqf.id;

                                return Marker(
                                  point: coords,
                                  width: isSelected ? 52 : 40,
                                  height: isSelected ? 52 : 40,
                                  child: GestureDetector(
                                    onTap: () => ref
                                        .read(mapNotifierProvider.notifier)
                                        .selectWaqf(waqf),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      decoration: BoxDecoration(
                                        color: waqf.status.color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white,
                                            width: isSelected ? 3 : 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.30),
                                            blurRadius: isSelected ? 10 : 6,
                                            spreadRadius: isSelected ? 1 : 0,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          waqf.pwfKey.length >= 2
                                              ? waqf.pwfKey.substring(0, 2)
                                              : waqf.pwfKey,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              })
                              .whereType<Marker>()
                              .toList(),
                        ),

                      // GIS Point features markers. At far zoom levels,
                      // point layers are clustered locally so the map stays
                      // readable without adding a new dependency.
                      if (pointClusters.isNotEmpty)
                        MarkerLayer(
                          markers: pointClusters.map((cluster) {
                            if (cluster.isCluster) {
                              final selected = cluster.containsFeatureId(
                                mapState.selectedFeature?.id,
                              );
                              final color = _clusterColorForFeatures(
                                cluster.features,
                                layerStyle,
                              );
                              return Marker(
                                point: cluster.center,
                                width: selected ? 54 : 48,
                                height: selected ? 54 : 48,
                                child: GestureDetector(
                                  onTap: () {
                                    _mapController.move(
                                      cluster.center,
                                      math.max(mapState.zoom + 1.8, 12.0),
                                    );
                                  },
                                  child: _ClusterPointMarker(
                                    count: cluster.features.length,
                                    color: color,
                                    selected: selected,
                                  ),
                                ),
                              );
                            }

                            final f = cluster.features.first;
                            final coords =
                                _extractCoordinates(f.centroid ?? f.geom);
                            if (coords == null) {
                              return Marker(
                                point: cluster.center,
                                width: 1,
                                height: 1,
                                child: const SizedBox.shrink(),
                              );
                            }
                            final isSelected =
                                mapState.selectedFeature?.id == f.id;
                            final pointStyle = layerStyle[f.layerKey] ?? const <String, dynamic>{};
                            final markerColor =
                                _markerColorForFeature(f, layerStyle);
                            final markerOpacity =
                                _markerOpacityForFeature(f, layerStyle);
                            final markerSize =
                                _markerSizeForFeature(f, layerStyle);
                            final markerIcon =
                                _markerIconForFeature(f, layerStyle);
                            final compactMarkerSize =
                                (isSelected ? markerSize + 10 : markerSize)
                                    .clamp(18.0, 82.0)
                                    .toDouble();

                            final showLabel = _shouldShowPointLabel(
                              f,
                              zoom: mapState.zoom,
                              layerStyle: layerStyle,
                              visibleLayerCount: pointLayerCounts[f.layerKey] ?? 0,
                            );
                            final label = _pointLabelForFeature(f, layerStyle);

                            return Marker(
                              point: coords,
                              width: showLabel ? 174 : compactMarkerSize,
                              height: showLabel ? 42 : compactMarkerSize,
                              child: GestureDetector(
                                onTap: () => ref
                                    .read(mapNotifierProvider.notifier)
                                    .selectGisFeature(f),
                                child: showLabel
                                    ? _LabeledPointMarker(
                                        label: label,
                                        color: markerColor,
                                        opacity: markerOpacity,
                                        selected: isSelected,
                                        icon: markerIcon,
                                        markerSize: markerSize,
                                        labelTextColor: _parseHex(
                                          pointStyle['labelTextColor']?.toString(),
                                          fallback: PwfColors.onSurface,
                                        ),
                                        labelHaloColor: _parseHex(
                                          pointStyle['labelHaloColor']?.toString(),
                                          fallback: Colors.white,
                                        ),
                                        labelFontSize: _styleDoubleValue(
                                          pointStyle['labelFontSize'],
                                          10.6,
                                        ).clamp(8.0, 24.0).toDouble(),
                                      )
                                    : AnimatedContainer(
                                        duration: const Duration(milliseconds: 140),
                                        decoration: BoxDecoration(
                                          color: markerColor.withValues(
                                            alpha: 0.95 * markerOpacity,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? PwfColors.royalRed
                                                : Colors.white,
                                            width: isSelected ? 3 : 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.25),
                                              blurRadius: isSelected ? 10 : 6,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          markerIcon,
                                          size: (markerSize * 0.50)
                                              .clamp(12.0, 32.0)
                                              .toDouble(),
                                          color: Colors.black87,
                                        ),
                                      ),
                              ),
                            );
                          }).toList(),
                        ),

                      ..._buildReviewMapCommandLayers(),

                      // Go-to coordinates marker
                      if (gotoMarker != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: gotoMarker,
                              width: 44,
                              height: 44,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: PwfColors.royalRed
                                      .withValues(alpha: 0.95),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.18),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.location_on,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),

                      // Live measurement overlay
                      if (measurePoints.length >= 2 &&
                          measureMode == MeasureMode.distance)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: measurePoints,
                              color: PwfColors.royalRed,
                              strokeWidth: 3,
                            ),
                          ],
                        ),
                      if (measurePoints.length >= 3 &&
                          measureMode == MeasureMode.area)
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: measurePoints,
                              color: PwfColors.royalRed.withValues(alpha: 0.15),
                              borderColor: PwfColors.royalRed,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                      if (measurePoints.isNotEmpty)
                        MarkerLayer(
                          markers: [
                            for (var i = 0; i < measurePoints.length; i++)
                              Marker(
                                point: measurePoints[i],
                                width: 24,
                                height: 24,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: PwfColors.primaryBlue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),

                      // Draw overlay
                      if (drawShape == 'line' && drawPoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: drawPoints,
                              color: PwfColors.primaryBlue,
                              strokeWidth: 3,
                            ),
                          ],
                        ),
                      if (drawShape == 'polygon' && drawPoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [
                                ...drawPoints,
                                if (drawPoints.length >= 3) drawPoints.first
                              ],
                              color: PwfColors.primaryBlue,
                              strokeWidth: 3,
                            ),
                          ],
                        ),
                      if (drawShape == 'polygon' && drawPoints.length >= 3)
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: drawPoints,
                              color:
                                  PwfColors.primaryBlue.withValues(alpha: 0.15),
                              borderColor: PwfColors.primaryBlue,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                      if (drawPoints.isNotEmpty)
                        MarkerLayer(
                          markers: [
                            for (var i = 0; i < drawPoints.length; i++)
                              Marker(
                                point: drawPoints[i],
                                width: drawShape == 'point' ? 30 : 20,
                                height: drawShape == 'point' ? 30 : 20,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: PwfColors.primaryBlue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: drawShape == 'point'
                                      ? const Icon(Icons.edit_location_alt,
                                          color: Colors.white, size: 16)
                                      : Text(
                                          '${i + 1}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                          ],
                        ),


                      // Real interaction selection-box overlay
                      if (realInteractionMode == ExplorerRealMapInteractionMode.selectionBox &&
                          selectionBoxPoints.length >= 2)
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: _selectionBoxPolygonPoints(selectionBoxPoints),
                              color: PwfColors.royalRed.withValues(alpha: 0.08),
                              borderColor: PwfColors.royalRed,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                      if (realInteractionMode == ExplorerRealMapInteractionMode.selectionBox &&
                          selectionBoxPoints.isNotEmpty)
                        MarkerLayer(
                          markers: [
                            for (var i = 0; i < selectionBoxPoints.length; i++)
                              Marker(
                                point: selectionBoxPoints[i],
                                width: 28,
                                height: 28,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: PwfColors.royalRed,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      // Directions overlay
                      if (directionsStart != null && directionsEnd != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [directionsStart, directionsEnd],
                              color: PwfColors.success,
                              strokeWidth: 4,
                            ),
                          ],
                        ),
                      if (directionsStart != null || directionsEnd != null)
                        MarkerLayer(
                          markers: [
                            if (directionsStart != null)
                              Marker(
                                point: directionsStart,
                                width: 28,
                                height: 28,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: PwfColors.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Text('A',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            if (directionsEnd != null)
                              Marker(
                                point: directionsEnd,
                                width: 28,
                                height: 28,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: PwfColors.warning,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Text('B',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),

                      // Snap point marker (dev)
                      if (snapEnabled && snapPoint != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: snapPoint,
                              width: 26,
                              height: 26,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: PwfColors.royalRed
                                      .withValues(alpha: 0.90),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.center_focus_strong,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  if (mapState.gisError != null)
                    _GisErrorChip(error: mapState.gisError!),

                  if (mapState.selectedWaqf != null)
                    _SelectedWaqfCard(waqf: mapState.selectedWaqf!),
                  if (mapState.selectedFeature != null)
                    _SelectedFeatureCard(feature: mapState.selectedFeature!),

                  // Bottom status bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: isDarkMode
                          ? Colors.black87
                          : Colors.white.withValues(alpha: 0.92),
                      child: Row(
                        children: [
                          Text(
                            'EPSG:4326',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Zoom: ${mapState.zoom.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          if (showCoords)
                            Text(
                              lastTap == null
                                  ? 'اضغط على الخريطة لعرض الإحداثيات'
                                  : 'Lat: ${lastTap.latitude.toStringAsFixed(6)}  Lng: ${lastTap.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          // GIS feature/polygon audit was useful while
                          // closing the natural-block rendering bug, but it
                          // crowds the public map. Keep the status bar focused
                          // on user-facing coordinates and measurement output.
                          if (measureResultLabel != null) ...[
                            const SizedBox(width: 16),
                            Text(
                              measureResultLabel,
                              style: const TextStyle(
                                color: PwfColors.royalRed,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Top header: search + brand (GeoPST-like)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: _buildTopHeader(context, mapState),
              ),
            ),

            if (widget.reviewMapCommand != null)
              Positioned(
                top: widget.embeddedInAdmin ? 86 : 88,
                left: 16,
                child: _ReviewMapCommandBanner(
                  command: widget.reviewMapCommand!,
                  onFocus: _focusReviewMapCommand,
                  onBackToReview: _returnToReviewBoardRecord,
                ),
              ),

            // Left navigation controls
            if (_placeResults.isEmpty)
              Positioned(
                top: _leftControlsTopOffset,
                left: 16,
                child: _buildTopLeftNav(context),
              ),

            // Basemap selector (bottom-right, shifted left when toolbox visible)
            Positioned(
              bottom: 72,
              right: _rightInsetForMapOverlays(context, ref),
              child: _buildBasemapButton(context, ref),
            ),

            // Toolbox drawer overlay (right)
            _buildToolboxOverlay(context, ref),

            if (_modernExplorerVisible)
              _buildModernExplorerOverlay(context, mapState),

            // Search suggestions
            if (_placeResults.isNotEmpty)
              Positioned(
                top: 72,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: _buildPlaceResultsOverlay(context),
                ),
              ),
          ],
        ),
      ),
    );
  }


  List<Widget> _buildReviewMapCommandLayers() {
    final command = widget.reviewMapCommand;
    if (command == null || !command.hasEvidence) return const [];

    final layers = <Widget>[];
    final bounds = command.bounds;
    if (bounds != null) {
      layers.add(
        PolygonLayer(
          polygons: [
            Polygon(
              points: [
                LatLng(command.bboxSouth!, command.bboxWest!),
                LatLng(command.bboxSouth!, command.bboxEast!),
                LatLng(command.bboxNorth!, command.bboxEast!),
                LatLng(command.bboxNorth!, command.bboxWest!),
              ],
              color: PwfColors.primaryGold.withValues(alpha: 0.16),
              borderColor: PwfColors.royalRed,
              borderStrokeWidth: 2.4,
            ),
          ],
        ),
      );
    }

    final markers = <Marker>[];
    final historicalPoint = command.historicalPoint;
    if (historicalPoint != null) {
      markers.add(
        Marker(
          point: historicalPoint,
          width: 170,
          height: 46,
          child: const _ReviewEvidenceMarker(
            label: 'النقطة التاريخية',
            icon: Icons.history_edu_outlined,
            tone: PwfColors.royalRed,
          ),
        ),
      );
    }
    final candidatePoint = command.candidatePoint;
    if (candidatePoint != null) {
      markers.add(
        Marker(
          point: candidatePoint,
          width: 170,
          height: 46,
          child: const _ReviewEvidenceMarker(
            label: 'المرشح الحالي',
            icon: Icons.center_focus_strong_outlined,
            tone: PwfColors.primaryBlue,
          ),
        ),
      );
    }
    if (markers.isNotEmpty) {
      layers.add(MarkerLayer(markers: markers));
    }
    return layers;
  }

  // ---------------------------------------------------------------------------
  // GeoPST-like UI Overlays (Header / Nav / Basemap / Toolbox / Place Search)
  // ---------------------------------------------------------------------------

  void _schedulePlaceSearch() {
    setState(() {});
    _placeSearchDebounce?.cancel();
    final q = _placeCtrl.text.trim();
    if (q.length < 2) {
      _placeSearchRequestSeq++;
      setState(() => _placeResults = const []);
      return;
    }
    _placeSearchDebounce = Timer(const Duration(milliseconds: 420), () {
      if (mounted) unawaited(_runPlaceSearch());
    });
  }

  Future<void> _runPlaceSearch() async {
    final requestId = ++_placeSearchRequestSeq;
    final q = _placeCtrl.text.trim();
    if (q.length < 2) {
      setState(() {
        _placeResults = const [];
        _placeLoading = false;
      });
      return;
    }

    setState(() => _placeLoading = true);

    try {
      final repo = ref.read(gisRepositoryProvider);
      final mapState = ref.read(mapNotifierProvider);
      final activeLayerKeys = mapState.activeLayers
          .map((key) => key.trim())
          .where((key) => key.isNotEmpty)
          .toList(growable: false);
      final layerLookup = <String, GisLayerModel>{
        for (final layer in mapState.gisLayers) layer.key: layer,
      };

      if (activeLayerKeys.isNotEmpty) {
        var searchableFeatures = mapState.gisFeatures
            .where((feature) => activeLayerKeys.contains(feature.layerKey))
            .toList(growable: false);
        var openLayerResults = _searchOpenLayerFeatures(
          q,
          searchableFeatures,
          layerLookup,
          limit: 12,
        );

        if (openLayerResults.isEmpty && mapState.viewport != null) {
          try {
            final vp = mapState.viewport!;
            searchableFeatures = await repo.fetchFeaturesInBounds(
              layerKeys: activeLayerKeys,
              unitId: '00000000-0000-0000-0000-000000000000',
              west: vp.west,
              south: vp.south,
              east: vp.east,
              north: vp.north,
              simplifyMeters: 0,
              limit: 3000,
            );
            if (!mounted || requestId != _placeSearchRequestSeq) return;
            openLayerResults = _searchOpenLayerFeatures(
              q,
              searchableFeatures,
              layerLookup,
              limit: 12,
            );
          } catch (_) {}
        }


        if (openLayerResults.isNotEmpty) {
          if (!mounted || requestId != _placeSearchRequestSeq) return;
          setState(() {
            _placeResults = openLayerResults;
            _placeLoading = false;
          });
          return;
        }
      }

      final navigationFeatures = await repo.searchExplorerNavigationFeatures(
        query: q,
        limit: 14,
      );
      if (!mounted || requestId != _placeSearchRequestSeq) return;
      if (navigationFeatures.isNotEmpty) {
        final out = <_PlaceResult>[];
        for (final feature in navigationFeatures) {
          final coords = _extractCoordinates(feature.centroid ?? feature.geom);
          if (coords == null) continue;
          final layerLabel = (feature.props['layer_name_ar'] ??
                  feature.layerNameAr ??
                  layerLookup[feature.layerKey]?.nameAr ??
                  feature.layerKey)
              .toString();
          final kind = (feature.props['navigation_target_kind'] ?? 'gis_target')
              .toString();
          out.add(
            _PlaceResult(
              kind: kind,
              nameAr: feature.displayTitle,
              nameEn: feature.titleEn,
              center: coords,
              feature: feature,
              layerLabel: layerLabel,
            ),
          );
        }
        if (out.isNotEmpty) {
          setState(() {
            _placeResults = out;
            _placeLoading = false;
          });
          return;
        }
      }

      final rows = await repo.searchPlaces(query: q, limit: 8);
      if (!mounted || requestId != _placeSearchRequestSeq) return;

      final out = <_PlaceResult>[];
      for (final r in rows) {
        final kind = (r['kind'] ?? '').toString();
        final nameAr = (r['name_ar'] ?? '').toString();
        final nameEn = (r['name_en'] as String?)?.toString();
        final lat = (r['center_lat'] as num?)?.toDouble();
        final lng = (r['center_lng'] as num?)?.toDouble();
        if (nameAr.trim().isEmpty || lat == null || lng == null) continue;

        out.add(
          _PlaceResult(
            kind: kind,
            nameAr: nameAr,
            nameEn: nameEn,
            center: LatLng(lat, lng),
          ),
        );
      }

      if (!mounted || requestId != _placeSearchRequestSeq) return;
      setState(() {
        _placeResults = out;
        _placeLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _placeSearchRequestSeq) return;
      setState(() {
        _placeResults = const [];
        _placeLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر البحث: $e'),
          ),
        );
      }
    }
  }

  List<_PlaceResult> _searchOpenLayerFeatures(
    String query,
    List<GisFeatureModel> features,
    Map<String, GisLayerModel> layerLookup, {
    int limit = 12,
  }) {
    final needle = _normalizeExplorerText(query);
    if (needle.isEmpty) return const [];

    final results = <_PlaceResult>[];
    final seen = <String>{};
    for (final feature in features) {
      if (results.length >= limit) break;
      final coords = _extractCoordinates(feature.centroid ?? feature.geom);
      if (coords == null) continue;

      final layer = layerLookup[feature.layerKey];
      final haystack = _openLayerSearchText(feature, layer);
      if (!haystack.contains(needle)) continue;

      final marker = '${feature.layerKey}|${feature.id}';
      if (!seen.add(marker)) continue;

      final layerLabel = _openLayerLabel(feature, layer);
      results.add(
        _PlaceResult(
          kind: 'layer_feature',
          nameAr: feature.displayTitle,
          nameEn: feature.titleEn,
          center: coords,
          feature: feature,
          layerLabel: layerLabel,
        ),
      );
    }
    return results;
  }

  String _openLayerSearchText(GisFeatureModel feature, GisLayerModel? layer) {
    final values = <String>[
      feature.id,
      feature.layerKey,
      feature.displayTitle,
      feature.titleAr ?? '',
      feature.titleEn ?? '',
      feature.layerNameAr ?? '',
      feature.layerNameEn ?? '',
      layer?.key ?? '',
      layer?.nameAr ?? '',
      layer?.nameEn ?? '',
    ];

    for (final entry in feature.props.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is Map || value is Iterable) continue;
      values.add(entry.key);
      values.add(value.toString());
    }

    return _normalizeExplorerText(values.join(' '));
  }

  String _openLayerLabel(GisFeatureModel feature, GisLayerModel? layer) {
    final label = layer?.nameAr.trim();
    if (label != null && label.isNotEmpty) return label;
    final featureLabel = feature.layerNameAr?.trim();
    if (featureLabel != null && featureLabel.isNotEmpty) return featureLabel;
    return feature.layerKey;
  }

  void _selectPlace(_PlaceResult r) {
    setState(() => _placeResults = const []);

    final feature = r.feature;
    if (feature != null) {
      ref.read(mapNotifierProvider.notifier).selectGisFeature(feature);
    }

    final z = feature != null
        ? (_isPointLikeGeometry(feature.geom) || _isPointLikeGeometry(feature.centroid)
            ? 15.4
            : 13.2)
        : switch (r.kind) {
            'governorate' => _governoratesMinZoom,
            'lgu' => _lgusMinZoom,
            'community' => _communitiesMinZoom,
            _ => _lgusMinZoom,
          };

    _mapController.move(r.center, _clampOperationalZoom(z));
  }

  bool _canShowDualSidePanels(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 920;
  }

  Widget _buildModernExplorerOverlay(BuildContext context, MapState mapState) {
    final width = MediaQuery.sizeOf(context).width;
    final panelWidth = math.min(360.0, math.max(304.0, width - 16));
    if (_modernExplorerGovernorateItems.isEmpty &&
        !_modernExplorerLookupSourceLoading &&
        mapState.gisLayers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ensureModernExplorerLookupSource();
      });
    }

    final governorateOptions = _modernExplorerGovernorateOptions();
    final governorateLabels = _modernExplorerLookupLabels(
      _modernExplorerGovernorateItems,
    );
    final localityItems = _modernExplorerVisibleLguItems();
    final localityOptions = localityItems.map((item) => item.code).toList();
    final localityLabels = _modernExplorerLookupLabels(localityItems);
    final featureTypeOptions =
        _modernExplorerAvailableFeatureTypeOptions(mapState);
    final governorateValue =
        governorateOptions.contains(_modernExplorerGovernorateFilter)
            ? _modernExplorerGovernorateFilter
            : null;
    final localityValue = localityOptions.contains(_modernExplorerLocalityFilter)
        ? _modernExplorerLocalityFilter
        : null;
    final featureTypeValue =
        featureTypeOptions.contains(_modernExplorerFeatureTypeFilter)
            ? _modernExplorerFeatureTypeFilter
            : null;
    final layerCounts = _modernExplorerLayerCounts(mapState);
    final audience = ref.watch(mapToolAudienceProvider);

    return Positioned(
      top: _toolboxTopOffset,
      right: 0,
      bottom: _toolboxBottomOffset,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: panelWidth,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.98),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              border: Border.all(color: PwfColors.outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.13),
                  blurRadius: 18,
                  offset: const Offset(-4, 8),
                ),
              ],
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  _ModernExplorerHeader(
                    onClose: () => setState(() => _modernExplorerVisible = false),
                    defaults: _modernExplorerDefaultLayerLabels(mapState),
                  ),
                  _ModernExplorerTabBar(
                    activeTab: _modernExplorerTab,
                    onChanged: (tab) => setState(() => _modernExplorerTab = tab),
                  ),
                  Expanded(
                    child: _modernExplorerTab == _ModernExplorerTab.search
                        ? const SearchSection(embedded: true)
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                            children: [
                              _ModernExplorerAdvancedFilters(
                                governorate: governorateValue,
                                governorates: governorateOptions,
                                governorateLabels: governorateLabels,
                                locality: localityValue,
                                localities: localityOptions,
                                localityLabels: localityLabels,
                                featureType: featureTypeValue,
                                featureTypes: featureTypeOptions,
                                loading: _modernExplorerFilterSourceLoading ||
                                    _modernExplorerLookupSourceLoading,
                                error: _modernExplorerLookupSourceError ??
                                    _modernExplorerFilterSourceError,
                                onGovernorateChanged: _setModernExplorerGovernorateFilter,
                                onLocalityChanged: _setModernExplorerLocalityFilter,
                                onFeatureTypeChanged: (value) =>
                                    _setModernExplorerFeatureTypeFilter(mapState, value),
                              ),
                              _ModernExplorerRuntimeStatus(
                                mapState: mapState,
                                audience: audience,
                                scoped: _hasModernExplorerScopedSelection(),
                              ),
                              ..._modernExplorerSections.map((section) {
                                return _ModernExplorerSectionCard(
                                  section: section,
                                  mapState: mapState,
                                  layerCounts: layerCounts,
                                  showBaseMap: ref.watch(showBaseMapProvider),
                                  resolveLayer: (spec) =>
                                      _resolveModernExplorerLayer(mapState, spec),
                                  gateForSpec: (spec) =>
                                      _modernExplorerLayerGate(mapState, spec, audience),
                                  onChanged: (spec, active) =>
                                      _setExplorerLayerActive(mapState, spec, active),
                                  onMore: _showModernExplorerLayerMoreMenu,
                                );
                              }),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, MapState mapState) {
    final border = PwfColors.royalRed.withValues(alpha: 0.18);

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: Border(bottom: BorderSide(color: border, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.only(start: 10, end: 10),
      child: Row(
        children: [
          _HeaderToolboxButton(ref: ref, visible: _toolboxVisible, onTap: _toggleToolbox),
          const SizedBox(width: 6),
          _HeaderModernExplorerButton(
            visible: _modernExplorerVisible,
            onTap: _toggleModernExplorer,
          ),
          const SizedBox(width: 8),
          _HeaderIcon(icon: Icons.facebook, onTap: () {}, tooltip: 'فيسبوك'),
          const SizedBox(width: 8),
          _HeaderSearchBox(
            controller: _placeCtrl,
            loading: _placeLoading,
            onChanged: _schedulePlaceSearch,
            onClear: () {
              _placeSearchDebounce?.cancel();
              _placeSearchRequestSeq++;
              _placeCtrl.clear();
              setState(() => _placeResults = const []);
            },
            onSearch: _runPlaceSearch,
          ),
          const SizedBox(width: 10),
          _HeaderIcon(icon: Icons.camera_alt_outlined, onTap: () {}, tooltip: 'الصور'),
          const SizedBox(width: 8),
          _HeaderIcon(icon: Icons.email_outlined, onTap: () {}, tooltip: 'البريد'),
          const SizedBox(width: 12),
          Expanded(
            child: Center(
              child: _HeaderWorkspaceStrip(
                mapState: mapState,
                toolboxVisible: _toolboxVisible,
                selectionLabel: _currentSelectionLabel(mapState),
                onFocusPalestine: _focusPalestine,
                onClearSelection: () => ref.read(mapNotifierProvider.notifier).clearSelection(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'مستكشف الوقف',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: PwfColors.onSurface,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: PwfColors.royalRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.public, color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleToolbox() {
    _clearVisualFocus();
    final allowDualPanels = _canShowDualSidePanels(context);
    setState(() {
      _toolboxVisible = !_toolboxVisible;
      if (_toolboxVisible && !allowDualPanels) {
        _modernExplorerVisible = false;
      }
    });
    if (!_toolboxVisible) return;
    ref.read(toolboxExpandedProvider.notifier).state = true;
    ref.read(activeToolSectionProvider.notifier).state = null;
  }

  void _toggleModernExplorer() {
    _clearVisualFocus();
    final allowDualPanels = _canShowDualSidePanels(context);
    var willOpen = false;
    setState(() {
      _modernExplorerVisible = !_modernExplorerVisible;
      willOpen = _modernExplorerVisible;
      if (_modernExplorerVisible && !allowDualPanels) {
        _toolboxVisible = false;
      }
    });
    if (willOpen) {
      unawaited(_resetModernExplorerWorkspace());
    }
  }

  Future<void> _resetModernExplorerWorkspace() async {
    ref.read(showBaseMapProvider.notifier).state = true;
    setState(() {
      _modernExplorerTab = _ModernExplorerTab.layers;
      _modernExplorerGovernorateFilter = null;
      _modernExplorerLocalityFilter = null;
      _modernExplorerFeatureTypeFilter = null;
      _modernExplorerFeatureLayerSelectionApplied = false;
    });
    // Opening the Modern Explorer is a navigation reset only. It recenters
    // the camera; layer visibility is then resolved naturally by zoom/bbox.
    ref.read(mapNotifierProvider.notifier).clearModernExplorerBoundaryOverlays();
    _mapController.move(const LatLng(31.95, 35.2), _openingZoom);
    _ensureModernExplorerLookupSource();
  }

  void _setBaseMapVisible(bool visible) {
    ref.read(showBaseMapProvider.notifier).state = visible;
  }

  bool _isAutomaticZoomLayerSpec(_ModernExplorerLayerSpec spec) {
    if (spec.isBaseMap || spec.defaultOn) return true;
    final title = _normalizeExplorerText(spec.title);
    return title.contains('محافظات') ||
        title.contains('الهيئات المحليه') ||
        title.contains('حدود الهيئات') ||
        title.contains('احواض التسويه') ||
        title.contains('التسويه');
  }

  Future<void> _setExplorerLayerActive(
    MapState mapState,
    _ModernExplorerLayerSpec spec,
    bool active,
  ) async {
    if (spec.isBaseMap) {
      _setBaseMapVisible(true);
      return;
    }
    if (_isAutomaticZoomLayerSpec(spec)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذه الطبقة تظهر تلقائيًا حسب الزوم، وليست مفتاح تشغيل أو إيقاف.')),
      );
      return;
    }
    final audience = ref.read(mapToolAudienceProvider);
    final gate = _modernExplorerLayerGate(mapState, spec, audience);
    if (active && !gate.allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(gate.reason ?? 'هذه الطبقة غير متاحة حاليًا.')),
      );
      return;
    }
    final layer = _resolveModernExplorerLayer(mapState, spec);
    if (layer == null) return;
    final current = List<String>.from(mapState.activeLayers);
    final specType = _modernExplorerSpecFeatureType(spec);

    if (active) {
      if (!current.contains(layer.key)) current.add(layer.key);
      if (specType != null) {
        setState(() {
          // تشغيل الطبقات الاختيارية من بطاقاتها لا يجعل الفئات متبادلة الإقصاء.
          // قائمة "اختر الطبقة" وحدها تضبط فئة واحدة؛ أما البطاقات فتسمح
          // بإظهار أكثر من طبقة اختيارية معًا.
          _modernExplorerFeatureLayerSelectionApplied = true;
          _modernExplorerFeatureTypeFilter = null;
        });
      }
    } else {
      current.remove(layer.key);
      if (specType != null) {
        final hasAnyOptionalLeft = current.any(_isModernExplorerOptionalWaqfLayerKey);
        setState(() {
          _modernExplorerFeatureLayerSelectionApplied = hasAnyOptionalLeft;
          if (!hasAnyOptionalLeft || _modernExplorerFeatureTypeFilter == specType) {
            _modernExplorerFeatureTypeFilter = null;
          }
        });
      }
    }
    await ref.read(mapNotifierProvider.notifier).setActiveLayers(current);
  }

  Future<void> _turnOffAllModernExplorerLayers() async {
    _setBaseMapVisible(true);
    setState(() {
      _modernExplorerFeatureLayerSelectionApplied = false;
      _modernExplorerFeatureTypeFilter = null;
    });
    await ref.read(mapNotifierProvider.notifier).resetToCoreBoundaryLayers();
  }

  Future<void> _turnOnModernExplorerDefaults(MapState _) async {
    _setBaseMapVisible(true);
    await ref.read(mapNotifierProvider.notifier).resetToCoreBoundaryLayers();
  }

  _ModernExplorerLayerGate _modernExplorerLayerGate(
    MapState mapState,
    _ModernExplorerLayerSpec spec,
    MapToolAudience audience,
  ) {
    if (spec.isBaseMap) return const _ModernExplorerLayerGate.allowed();

    if (spec.managerOnly && !audience.canUseManagerTools) {
      return const _ModernExplorerLayerGate.blocked('متاحة لمدير الخريطة فقط');
    }
    if (spec.employeeOnly && !audience.canUseEmployeeTools) {
      return const _ModernExplorerLayerGate.blocked('متاحة للموظفين فقط');
    }

    // minZoom is an execution hint, not a toggle blocker. The provider blocks
    // heavy layer fetching until the zoom threshold is reached.
    if (spec.requiresScopedSelection && !_hasModernExplorerScopedSelection()) {
      return const _ModernExplorerLayerGate.blocked(
        'اختر محافظة أو هيئة محلية قبل تشغيلها',
      );
    }

    return const _ModernExplorerLayerGate.allowed();
  }

  bool _hasModernExplorerScopedSelection() {
    return (_modernExplorerGovernorateFilter ?? '').trim().isNotEmpty ||
        (_modernExplorerLocalityFilter ?? '').trim().isNotEmpty;
  }

  GisLayerModel? _resolveModernExplorerLayer(
    MapState mapState,
    _ModernExplorerLayerSpec spec,
  ) {
    if (spec.isBaseMap) return null;
    final available = mapState.gisLayers
        .where((layer) => layer.isActive && layer.isPublic)
        .toList(growable: false);

    for (final hint in spec.keyHints) {
      final normalized = hint.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      for (final layer in available) {
        if (layer.key.trim().toLowerCase() == normalized) return layer;
      }
    }

    bool containsAny(String value, List<String> hints) {
      final normalized = _normalizeExplorerText(value);
      return hints.any((hint) {
        final h = _normalizeExplorerText(hint);
        return h.isNotEmpty && normalized.contains(h);
      });
    }

    for (final layer in available) {
      final key = layer.key;
      final nameAr = layer.nameAr;
      final nameEn = layer.nameEn ?? '';
      if (containsAny(key, spec.keyHints) ||
          containsAny(nameAr, spec.arHints) ||
          containsAny(nameEn, spec.enHints)) {
        return layer;
      }
    }

    final normalizedTitle = _normalizeExplorerText(spec.title);
    if (normalizedTitle.contains('التسويه') ||
        spec.keyHints.any((hint) => hint.trim().toLowerCase() == 'parcels_registered')) {
      return const GisLayerModel(
        key: 'parcels_registered',
        nameAr: 'أحواض التسوية',
        nameEn: 'Settlement parcels',
        category: LayerCategory.gis,
        isPublic: true,
        isActive: true,
        style: {'defaultOpacity': 0.72},
      );
    }
    return null;
  }

  String _normalizeExplorerText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  Map<String, int> _modernExplorerLayerCounts(MapState mapState) {
    final counts = <String, int>{};
    for (final feature in mapState.gisFeatures) {
      if (_isModernExplorerWaqfPointFeature(feature)) continue;
      counts.update(feature.layerKey, (value) => value + 1, ifAbsent: () => 1);
    }

    final visiblePointFeatures = _applyModernExplorerPointFilters(
      mapState.gisFeatures.where((feature) {
        return _isPointLikeGeometry(feature.geom) ||
            _isPointLikeGeometry(feature.centroid);
      }).toList(growable: false),
      boundaryFeatures: mapState.modernExplorerBoundaryFeatures,
    ).where(_isModernExplorerWaqfPointFeature);

    for (final feature in visiblePointFeatures) {
      counts.update(feature.layerKey, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  List<String> _modernExplorerDefaultLayerLabels(MapState mapState) {
    final labels = <String>[];
    for (final section in _modernExplorerSections) {
      for (final spec in section.items) {
        if (!spec.defaultOn) continue;
        if (spec.isBaseMap) {
          labels.add(spec.title);
          continue;
        }
        final layer = _resolveModernExplorerLayer(mapState, spec);
        if (layer != null) labels.add(spec.title);
      }
    }
    return labels;
  }


  bool _isZoomDrivenGovernorateLayerKey(String layerKey) {
    final key = layerKey.trim().toLowerCase();
    return key.contains('governorates_boundary') ||
        key.contains('v_governorates_core') ||
        key.contains('governorate');
  }

  bool _isZoomDrivenCommunityLayerKey(String layerKey) {
    final key = layerKey.trim().toLowerCase();
    return key.contains('communities_boundary') ||
        key.contains('v_communities_core') ||
        key.contains('community_boundary') ||
        key.contains('community_boundaries');
  }

  bool _isZoomDrivenLguLayerKey(String layerKey) {
    final key = layerKey.trim().toLowerCase();
    return key.contains('lgus_boundary') ||
        key.contains('v_lgus_core') ||
        key.contains('v_lgus_light') ||
        key.contains('lgu_labels') ||
        key.contains('lgus_labels') ||
        key.contains('lgu_names');
  }

  bool _isZoomDrivenSettlementLayerKey(String layerKey) {
    final key = layerKey.trim().toLowerCase();
    return key == 'parcels_registered' ||
        key.contains('settlement') ||
        key.contains('taswyeh') ||
        key.contains('parcel') ||
        key.contains('cadastre') ||
        key.contains('cadastral');
  }

  bool _isZoomDrivenLocationLayerKey(String layerKey) {
    final key = layerKey.trim().toLowerCase();
    return key == 'locations' ||
        key == 'gis_locations' ||
        key == 'operational_locations';
  }

  bool _isNaturalBlocksLayerKey(String layerKey) {
    final key = layerKey.trim().toLowerCase();
    return key == _naturalBlocksFullLayerKey || key == _naturalBlocksOverviewLayerKey;
  }

  bool _isGuessingBlocksLayerKey(String layerKey) {
    final key = layerKey.trim().toLowerCase();
    return key == _guessingBlocksLayerKey ||
        key.contains('guessing_blocks') ||
        key.contains('guess_blocks') ||
        key.contains('estimated_blocks') ||
        key.contains('takmeen') ||
        key.contains('takhmin');
  }

  bool _isAutoScopedOperationalLayerVisible(
    String layerKey,
    MapState mapState,
  ) {
    final key = layerKey.trim().toLowerCase();
    if (key == 'parcels_registered') return mapState.zoom >= _settlementParcelsMinZoom;
    return false;
  }

  bool _isZoomDrivenBoundaryLayerKey(String layerKey) {
    return _isZoomDrivenGovernorateLayerKey(layerKey) ||
        _isZoomDrivenCommunityLayerKey(layerKey) ||
        _isZoomDrivenLguLayerKey(layerKey);
  }

  bool _settlementFeatureMatchesSelectedLocality(
    GisFeatureModel feature,
    List<GisFeatureModel> selectedLguBoundaries,
  ) {
    final localityCode = (_modernExplorerLocalityFilter ?? '').trim();
    if (localityCode.isEmpty) return false;
    if (_modernExplorerFeatureMatchesLgu(feature, localityCode)) return true;

    final point = _extractCoordinates(feature.centroid ?? feature.geom);
    if (point == null || selectedLguBoundaries.isEmpty) return false;
    for (final boundary in selectedLguBoundaries) {
      if (_geoJsonContainsPoint(boundary.geom, point)) return true;
    }
    return false;
  }

  List<GisFeatureModel> _filterMapBehaviorFeatures(
    List<GisFeatureModel> features,
    MapState mapState,
  ) {
    if (features.isEmpty) return features;

    final activeLayerKeys = mapState.activeLayers
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toSet();
    final filtered = <GisFeatureModel>[];

    for (final feature in features) {
      final layerKey = feature.layerKey.trim();
      final isBoundary = _isZoomDrivenBoundaryLayerKey(layerKey);
      final isSettlement = _isZoomDrivenSettlementLayerKey(layerKey);
      final isLocation = _isZoomDrivenLocationLayerKey(layerKey);

      if (isLocation && !activeLayerKeys.contains(layerKey)) {
        continue;
      }

      // Zoom-governed boundaries and settlement layers render only when the
      // notifier has placed their layer key in the zoom-driven active sequence.
      // Search-reference layers (natural/guessing basins) are intentionally
      // separate and pass through because they are not activeLayers.
      if ((isBoundary || isSettlement) &&
          !activeLayerKeys.contains(layerKey)) {
        continue;
      }

      if (isSettlement) {
        if (_isAutoScopedOperationalLayerVisible(layerKey, mapState)) {
          filtered.add(feature);
        }
        continue;
      }

      filtered.add(feature);
    }

    return filtered;
  }

  String _boundaryLabelText(GisFeatureModel feature) {
    if (_isZoomDrivenGovernorateLayerKey(feature.layerKey)) {
      return _firstNonEmptyProp(feature, const [
            'name_ar',
            'label_ar',
            'governorate_name_ar',
            'governorate_name',
            'governorate_ar',
            'governorate',
            'governoraten',
            'gov_name_ar',
            'gov_name',
            'name',
            'title_ar',
          ]) ??
          feature.displayTitle;
    }
    if (_isNaturalBlocksLayerKey(feature.layerKey)) {
      final number = _firstNonEmptyProp(feature, const [
        'block_no',
        'block_display_no',
        'natural_block_no',
        'basin_no',
        'basin_number',
        'hod_no',
        'hod_number',
      ]);
      final name = _firstNonEmptyProp(feature, const [
        'block_name_ar',
        'block_name',
        'natural_block_name_ar',
        'basin_name_ar',
        'basin_name',
        'hod_name_ar',
        'name_ar',
        'label_ar',
        'name',
        'title_ar',
      ]);
      if ((number ?? '').isNotEmpty && (name ?? '').isNotEmpty) {
        return '$number — $name';
      }
      return number ?? name ?? feature.displayTitle;
    }
    if (_isGuessingBlocksLayerKey(feature.layerKey)) {
      return _firstNonEmptyProp(feature, const [
            'parcel_no',
            'parcel_display_no',
            'parcel_number',
            'plot_no',
            'plot_number',
            'block_no',
            'guessing_block_no',
            'basin_no',
            'hod_no',
            'name_ar',
            'label_ar',
            'name',
            'title_ar',
          ]) ??
          feature.displayTitle;
    }
    if (_isZoomDrivenLocationLayerKey(feature.layerKey)) {
      return _firstNonEmptyProp(feature, const [
            'location_name_ar',
            'location_name',
            'loc_name_ar',
            'loc_name',
            'site_name_ar',
            'site_name',
            'location',
            'adress',
            'address',
            'name_ar',
            'label_ar',
            'name',
            'title_ar',
          ]) ??
          feature.displayTitle;
    }
    return _firstNonEmptyProp(feature, const [
          'lgusn',
          'lgun',
          'lgu_name_ar',
          'lgu_name',
          'municipality_name_ar',
          'municipality_name',
          'locality_name_ar',
          'locality_name',
          'local_body_name_ar',
          'local_body_name',
          'communityn',
          'community_name_ar',
          'community_name',
          'name_ar',
          'label_ar',
          'name',
          'title_ar',
        ]) ??
        feature.displayTitle;
  }

  List<Marker> _buildBoundaryLabelMarkers(
    List<GisFeatureModel> features, {
    required double zoom,
  }) {
    final polygonFeatures = features.where((feature) {
      return _isPolygonGeometry(feature.geom) &&
          (_isZoomDrivenGovernorateLayerKey(feature.layerKey) ||
              _isNaturalBlocksLayerKey(feature.layerKey) ||
              _isZoomDrivenLguLayerKey(feature.layerKey) ||
              _isZoomDrivenLocationLayerKey(feature.layerKey) ||
              _isGuessingBlocksLayerKey(feature.layerKey));
    }).toList(growable: false);
    if (polygonFeatures.isEmpty) return const [];

    final governorateCount = polygonFeatures
        .where((feature) => _isZoomDrivenGovernorateLayerKey(feature.layerKey))
        .length;
    final naturalBlockCount = polygonFeatures
        .where((feature) => _isNaturalBlocksLayerKey(feature.layerKey))
        .length;
    final lguCount = polygonFeatures
        .where((feature) => _isZoomDrivenLguLayerKey(feature.layerKey))
        .length;
    final locationCount = polygonFeatures
        .where((feature) => _isZoomDrivenLocationLayerKey(feature.layerKey))
        .length;
    final guessingBlockCount = polygonFeatures
        .where((feature) => _isGuessingBlocksLayerKey(feature.layerKey))
        .length;
    final markers = <Marker>[];

    for (final feature in polygonFeatures) {
      final isGovernorate = _isZoomDrivenGovernorateLayerKey(feature.layerKey);
      final isNaturalBlock = _isNaturalBlocksLayerKey(feature.layerKey);
      final isLgu = _isZoomDrivenLguLayerKey(feature.layerKey);
      final isLocation = _isZoomDrivenLocationLayerKey(feature.layerKey);
      final isGuessingBlock = _isGuessingBlocksLayerKey(feature.layerKey);
      if (isGovernorate && (zoom < _governoratesMinZoom || governorateCount > 60)) continue;
      if (isNaturalBlock && (zoom < _naturalBlockLabelsMinZoom || naturalBlockCount > 900)) continue;
      if (isLgu && (zoom < _lguLabelsMinZoom || lguCount > 420)) continue;
      if (isLocation && (zoom < _locationLabelsMinZoom || locationCount > 700)) continue;
      if (isGuessingBlock && (zoom < _guessingParcelLabelsMinZoom || guessingBlockCount > 1200)) continue;

      final point = _extractCoordinates(feature.centroid ?? feature.geom);
      if (point == null) continue;
      final label = _boundaryLabelText(feature).trim();
      if (label.isEmpty) continue;
      markers.add(
        Marker(
          point: point,
          width: (isNaturalBlock || isGuessingBlock) ? 130 : (isGovernorate ? 190 : 170),
          height: 36,
          child: IgnorePointer(
            child: _BoundaryLabelChip(
              label: label,
              emphasized: isGovernorate || isNaturalBlock || isGuessingBlock,
            ),
          ),
        ),
      );
    }
    return markers;
  }

  String _parcelNumberLabel(GisFeatureModel feature) {
    return _firstNonEmptyProp(feature, const [
          'parcel_display_no',
          'parcel_no',
          'parcelnumb',
          'parcelnumbe',
          'parcelsno_',
          'parcel_number',
          'parcelnum',
          'plot_no',
          'plot_number',
          'plotnum',
          'id',
        ]) ??
        feature.id;
  }

  List<Marker> _buildSettlementParcelLabelMarkers(
    List<GisFeatureModel> features, {
    required MapState mapState,
    required void Function(GisFeatureModel feature) onTap,
  }) {
    if (mapState.zoom < _settlementParcelLabelsMinZoom || features.isEmpty) return const [];

    final parcelFeatures = features.where((feature) {
      final key = feature.layerKey.trim().toLowerCase();
      final kind = (feature.props['layer_kind'] ?? '').toString().toLowerCase();
      return key == 'parcels_registered' || kind == 'parcels_registered';
    }).toList(growable: false);
    if (parcelFeatures.isEmpty) return const [];

    final maxLabels = mapState.zoom < 17.8
        ? 520
        : (mapState.zoom < 18.6 ? 1200 : 2200);
    final markers = <Marker>[];
    for (final feature in parcelFeatures.take(maxLabels)) {
      final point = _extractCoordinates(feature.centroid ?? feature.geom);
      if (point == null) continue;
      final label = _parcelNumberLabel(feature).trim();
      if (label.isEmpty) continue;
      final selected = mapState.selectedFeature?.id == feature.id;
      markers.add(
        Marker(
          point: point,
          width: selected ? 72 : 58,
          height: selected ? 34 : 28,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(feature),
            child: _ParcelNumberMarker(
              label: label,
              selected: selected,
            ),
          ),
        ),
      );
    }
    return markers;
  }

  _IdentifyHit? _findSettlementLayerHit(
    LatLng tap,
    List<GisFeatureModel> features,
    double zoom,
  ) {
    if (zoom < _settlementParcelsMinZoom) return null;
    final settlementFeatures = features
        .where((feature) => _isZoomDrivenSettlementLayerKey(feature.layerKey))
        .toList(growable: false);
    if (settlementFeatures.isEmpty) return null;

    for (final feature in settlementFeatures) {
      if (!_isPolygonGeometry(feature.geom)) continue;
      if (_geoJsonContainsPoint(feature.geom, tap) ||
          _geometryBoundsContains(feature.geom, tap)) {
        return _IdentifyHit(feature: feature, distanceMeters: null);
      }
    }
    return _findIdentifyHit(tap, settlementFeatures, zoom);
  }

  List<_PointFeatureCluster> _clusterPointFeatures(
    List<GisFeatureModel> features, {
    required double zoom,
  }) {
    if (features.isEmpty) return const [];

    final clusterCellSize = _pointClusterCellSizeForZoom(zoom);
    if (clusterCellSize <= 0) {
      return features
          .map((feature) {
            final center = _extractCoordinates(feature.centroid ?? feature.geom);
            if (center == null) return null;
            return _PointFeatureCluster(center: center, features: [feature]);
          })
          .whereType<_PointFeatureCluster>()
          .toList(growable: false);
    }

    final buckets = <String, List<MapEntry<GisFeatureModel, LatLng>>>{};
    for (final feature in features) {
      final center = _extractCoordinates(feature.centroid ?? feature.geom);
      if (center == null) continue;
      final row = ((center.latitude + 90.0) / clusterCellSize).floor();
      final col = ((center.longitude + 180.0) / clusterCellSize).floor();
      final key = '$row:$col';
      buckets.putIfAbsent(key, () => <MapEntry<GisFeatureModel, LatLng>>[]).add(
            MapEntry(feature, center),
          );
    }

    final clusters = <_PointFeatureCluster>[];
    for (final entries in buckets.values) {
      if (entries.isEmpty) continue;
      if (entries.length == 1) {
        clusters.add(
          _PointFeatureCluster(
            center: entries.first.value,
            features: [entries.first.key],
          ),
        );
        continue;
      }

      var lat = 0.0;
      var lng = 0.0;
      for (final entry in entries) {
        lat += entry.value.latitude;
        lng += entry.value.longitude;
      }
      clusters.add(
        _PointFeatureCluster(
          center: LatLng(lat / entries.length, lng / entries.length),
          features: entries.map((entry) => entry.key).toList(growable: false),
        ),
      );
    }

    return clusters;
  }

  double _pointClusterCellSizeForZoom(double zoom) {
    // Degrees per bucket. At close zooms, return zero to render exact points
    // and labels. The BBOX query still limits what reaches this local pass.
    if (zoom >= 13.4) return 0;
    if (zoom < 8) return 0.28;
    if (zoom < 9) return 0.18;
    if (zoom < 10) return 0.10;
    if (zoom < 11) return 0.055;
    if (zoom < 12) return 0.030;
    if (zoom < 13) return 0.016;
    return 0.008;
  }

  Color _clusterColorForFeatures(
    List<GisFeatureModel> features,
    Map<String, Map<String, dynamic>> layerStyle,
  ) {
    if (features.isEmpty) return PwfColors.primaryBlue;
    final counts = <String, int>{};
    for (final feature in features) {
      counts.update(feature.layerKey, (value) => value + 1, ifAbsent: () => 1);
    }
    var bestKey = features.first.layerKey;
    var bestCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        bestKey = entry.key;
        bestCount = entry.value;
      }
    }
    final dominant = features.firstWhere(
      (feature) => feature.layerKey == bestKey,
      orElse: () => features.first,
    );
    return _markerColorForFeature(dominant, layerStyle);
  }

  List<GisFeatureModel> _applyModernExplorerPointFilters(
    List<GisFeatureModel> features, {
    List<GisFeatureModel> boundaryFeatures = const [],
  }) {
    final hasFilter = _modernExplorerGovernorateFilter != null ||
        _modernExplorerLocalityFilter != null ||
        _modernExplorerFeatureLayerSelectionApplied;
    final selectedLguBoundaries = _modernExplorerSelectedLguBoundaryFeatures(
      boundaryFeatures,
    );

    // In the Modern Explorer, optional waqf point layers must not appear just
    // because they are active in the generic layer state. They become visible
    // only after the user applies the Modern Explorer filters or explicitly
    // selects an optional waqf layer from the explorer.
    if (!hasFilter) {
      return features
          .where((feature) => !_isModernExplorerWaqfPointFeature(feature))
          .toList(growable: false);
    }

    return features.where((feature) {
      if (!_isModernExplorerWaqfPointFeature(feature)) return true;

      final type = _modernExplorerFeatureTypeForLayerKey(feature.layerKey);
      if (_modernExplorerFeatureTypeFilter != null &&
          type != _modernExplorerFeatureTypeFilter) {
        return false;
      }

      if (_modernExplorerGovernorateFilter != null &&
          !_modernExplorerFeatureMatchesGovernorate(
            feature,
            _modernExplorerGovernorateFilter!,
          )) {
        return false;
      }

      if (_modernExplorerLocalityFilter != null) {
        final matchesSelectedLgu = _modernExplorerFeatureMatchesLgu(
              feature,
              _modernExplorerLocalityFilter!,
            ) ||
            _modernExplorerPointInsideAnyBoundary(
              feature,
              selectedLguBoundaries,
            );
        if (!matchesSelectedLgu) return false;
      }

      return true;
    }).toList(growable: false);
  }

  bool _isModernExplorerWaqfPointFeature(GisFeatureModel feature) {
    return feature.layerKey.startsWith('gis_waqf_');
  }

  String? _modernExplorerFeatureTypeForLayerKey(String layerKey) {
    final key = layerKey.trim().toLowerCase();
    if (key.contains('mosque')) return 'mosques';
    if (key.contains('maqamat')) return 'maqamat';
    if (key.contains('takaya') || key.contains('zawaya')) return 'takaya';
    if (key.contains('cemeter')) return 'cemeteries';
    if (key.contains('archaeological')) return 'archaeological';
    return null;
  }

  bool _isModernExplorerOptionalWaqfLayerKey(String layerKey) {
    return _modernExplorerFeatureTypeForLayerKey(layerKey) != null;
  }

  String? _modernExplorerGovernorateCode(GisFeatureModel feature) {
    return _firstNonEmptyProp(feature, const [
      'governorate_no',
      'governoratename_no',
      'gov_no',
      'gov_code',
      'governorate_code',
    ]);
  }

  String? _modernExplorerGovernorateName(GisFeatureModel feature) {
    return _firstNonEmptyProp(feature, const [
      'governorat',
      'governorate',
      'governorate_name',
      'governorate_name_ar',
      'governorat_e',
      'region_ara',
      'region_eng',
    ]);
  }

  String? _modernExplorerLguCode(GisFeatureModel feature) {
    return _firstNonEmptyProp(feature, const [
      'lgus_code',
      'lgus_xcode',
      'lgu_code',
      'lgu_no',
      'municipality_code',
      'municipality_no',
    ]);
  }

  String? _modernExplorerLocalityName(GisFeatureModel feature) {
    return _firstNonEmptyProp(feature, const [
      'lgusn',
      'lgun',
      'lgu_name_ar',
      'lgu_name',
      'municipality_name_ar',
      'municipality_name',
      'locality',
      'location',
      'adress',
      'address',
    ]);
  }

  String? _firstNonEmptyProp(GisFeatureModel feature, List<String> keys) {
    for (final key in keys) {
      final value = feature.props[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return null;
  }

  bool _sameExplorerValue(String? left, String? right) {
    final a = _normalizeExplorerText(left ?? '');
    final b = _normalizeExplorerText(right ?? '');
    if (a.isEmpty || b.isEmpty) return false;
    return a == b || a.contains(b) || b.contains(a);
  }

  LookupItem? _lookupByCode(List<LookupItem> items, String code) {
    final target = code.trim();
    if (target.isEmpty) return null;
    for (final item in items) {
      if (item.code.trim() == target) return item;
    }
    return null;
  }

  Map<String, String> _modernExplorerLookupLabels(List<LookupItem> items) {
    return {
      for (final item in items)
        if (item.code.trim().isNotEmpty) item.code: item.bestLabel,
    };
  }

  List<String> _modernExplorerGovernorateOptions() {
    return _modernExplorerGovernorateItems
        .map((item) => item.code)
        .where((code) => code.trim().isNotEmpty)
        .toList(growable: false);
  }

  List<LookupItem> _modernExplorerVisibleLguItems() {
    final gov = _modernExplorerGovernorateFilter;
    if (gov == null || gov.trim().isEmpty) return _modernExplorerLguItems;

    final selectedGov = _lookupByCode(_modernExplorerGovernorateItems, gov);
    final selectedGovLabel = selectedGov?.bestLabel;
    final filtered = _modernExplorerLguItems.where((item) {
      return _sameExplorerValue(item.parentCode, gov) ||
          _sameExplorerValue(item.parentCode, selectedGovLabel);
    }).toList(growable: false);

    // إذا كان المصدر نفسه رجّع قائمة مفلترة فعلًا لكنه لا يحمل parentCode
    // كافيًا، لا نُفرغ القائمة. أما عند وجود parentCode نلتزم بالفلترة.
    if (filtered.isNotEmpty) return filtered;
    if (_modernExplorerLguItemsGovernorateScope == gov) {
      return _modernExplorerLguItems;
    }
    return const [];
  }

  bool _modernExplorerFeatureMatchesGovernorate(
    GisFeatureModel feature,
    String governorateCode,
  ) {
    final selected = _lookupByCode(
      _modernExplorerGovernorateItems,
      governorateCode,
    );
    final featureCode = _modernExplorerGovernorateCode(feature);
    if (_sameExplorerValue(featureCode, governorateCode)) return true;
    final selectedLabel = selected?.bestLabel;
    if (_sameExplorerValue(_modernExplorerGovernorateName(feature), selectedLabel)) {
      return true;
    }
    return false;
  }

  bool _modernExplorerFeatureMatchesLgu(
    GisFeatureModel feature,
    String lguCode,
  ) {
    final selected = _lookupByCode(_modernExplorerLguItems, lguCode);
    final featureCode = _modernExplorerLguCode(feature);
    if (_sameExplorerValue(featureCode, lguCode)) return true;

    // Modern Explorer LGU filtering uses the local body label from
    // gis.lgus_boundary.lgusn, not communityn.
    final selectedLabel = selected?.bestLabel;
    if (_sameExplorerValue(_modernExplorerLocalityName(feature), selectedLabel)) {
      return true;
    }
    return false;
  }

  List<GisFeatureModel> _modernExplorerSelectedLguBoundaryFeatures(
    List<GisFeatureModel> boundaryFeatures,
  ) {
    final selectedLgu = _modernExplorerLocalityFilter;
    if (selectedLgu == null || selectedLgu.trim().isEmpty) {
      return const [];
    }
    return boundaryFeatures.where((feature) {
      if (!_isPolygonGeometry(feature.geom)) return false;
      return _modernExplorerFeatureMatchesLgu(feature, selectedLgu);
    }).toList(growable: false);
  }

  bool _modernExplorerPointInsideAnyBoundary(
    GisFeatureModel pointFeature,
    List<GisFeatureModel> boundaries,
  ) {
    if (boundaries.isEmpty) return false;
    final point = _extractCoordinates(pointFeature.centroid ?? pointFeature.geom);
    if (point == null) return false;
    for (final boundary in boundaries) {
      if (_geoJsonContainsPoint(boundary.geom, point)) return true;
    }
    return false;
  }

  bool _geoJsonContainsPoint(Map<String, dynamic>? geometry, LatLng point) {
    if (geometry == null) return false;
    final type = geometry['type']?.toString();
    final coords = geometry['coordinates'];
    if (type == 'Polygon') return _polygonCoordsContainPoint(coords, point);
    if (type == 'MultiPolygon' && coords is List) {
      for (final polygon in coords) {
        if (_polygonCoordsContainPoint(polygon, point)) return true;
      }
    }
    return false;
  }

  bool _polygonCoordsContainPoint(dynamic polygon, LatLng point) {
    if (polygon is! List || polygon.isEmpty) return false;
    if (!_ringCoordsContainPoint(polygon.first, point)) return false;
    for (var i = 1; i < polygon.length; i++) {
      if (_ringCoordsContainPoint(polygon[i], point)) return false;
    }
    return true;
  }

  bool _ringCoordsContainPoint(dynamic ring, LatLng point) {
    if (ring is! List || ring.length < 3) return false;
    final x = point.longitude;
    final y = point.latitude;
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final pi = ring[i];
      final pj = ring[j];
      if (pi is! List || pj is! List || pi.length < 2 || pj.length < 2) {
        continue;
      }
      final xi = (pi[0] as num).toDouble();
      final yi = (pi[1] as num).toDouble();
      final xj = (pj[0] as num).toDouble();
      final yj = (pj[1] as num).toDouble();
      final denom = (yj - yi).abs() < 1e-12 ? 1e-12 : (yj - yi);
      final intersects = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / denom + xi);
      if (intersects) inside = !inside;
    }
    return inside;
  }

  List<String> _modernExplorerAvailableFeatureTypeOptions(MapState mapState) {
    final values = <String>{};
    for (final section in _modernExplorerSections) {
      for (final spec in section.items) {
        final type = _modernExplorerSpecFeatureType(spec);
        if (type == null) continue;
        if (_resolveModernExplorerLayer(mapState, spec) != null) {
          values.add(type);
        }
      }
    }

    // Keep the layer-type dropdown stable if features are loaded before the
    // catalog refresh finishes, or if a point layer is already active.
    for (final feature in [
      ..._modernExplorerFilterSourceFeatures,
      ...mapState.gisFeatures,
    ]) {
      final type = _modernExplorerFeatureTypeForLayerKey(feature.layerKey);
      if (type != null) values.add(type);
    }

    final ordered = <String>[];
    for (final key in _modernExplorerFeatureTypeLabels.keys) {
      if (values.contains(key)) ordered.add(key);
    }
    return ordered;
  }

  List<String> _modernExplorerFeatureTypeOptions(
    List<GisFeatureModel> features,
  ) {
    final values = <String>{};
    for (final feature in features) {
      if (!_isModernExplorerWaqfPointFeature(feature)) continue;
      if (_modernExplorerGovernorateFilter != null &&
          !_modernExplorerFeatureMatchesGovernorate(
            feature,
            _modernExplorerGovernorateFilter!,
          )) {
        continue;
      }
      if (_modernExplorerLocalityFilter != null &&
          !_modernExplorerFeatureMatchesLgu(
            feature,
            _modernExplorerLocalityFilter!,
          )) {
        continue;
      }
      final type = _modernExplorerFeatureTypeForLayerKey(feature.layerKey);
      if (type != null) values.add(type);
    }

    final ordered = <String>[];
    for (final key in _modernExplorerFeatureTypeLabels.keys) {
      if (values.contains(key)) ordered.add(key);
    }
    return ordered;
  }

  Future<void> _ensureModernExplorerLookupSource() async {
    if (_modernExplorerLookupSourceLoading ||
        _modernExplorerGovernorateItems.isNotEmpty) {
      return;
    }

    final requestId = ++_modernExplorerLookupRequestSeq;
    setState(() {
      _modernExplorerLookupSourceLoading = true;
      _modernExplorerLookupSourceError = null;
    });

    try {
      final repo = ref.read(gisRepositoryProvider);
      final governorates = await repo.fetchModernExplorerGovernoratesFromGis();
      final lgus = await repo.fetchModernExplorerLgusFromGis();

      if (!mounted || requestId != _modernExplorerLookupRequestSeq) return;
      setState(() {
        _modernExplorerGovernorateItems = governorates;
        _modernExplorerLguItems = lgus;
        _modernExplorerLguItemsGovernorateScope = null;
        _modernExplorerLookupSourceLoading = false;
      });
      unawaited(_refreshModernExplorerBoundaryOverlays());
    } catch (e) {
      if (!mounted || requestId != _modernExplorerLookupRequestSeq) return;
      setState(() {
        _modernExplorerLookupSourceLoading = false;
        _modernExplorerLookupSourceError = e.toString();
      });
    }
  }

  Future<void> _reloadModernExplorerLgusForGovernorate(String? governorateCode) async {
    final requestId = ++_modernExplorerLookupRequestSeq;
    setState(() {
      _modernExplorerLookupSourceLoading = true;
      _modernExplorerLookupSourceError = null;
    });

    try {
      final repo = ref.read(gisRepositoryProvider);
      final lgus = await repo.fetchModernExplorerLgusFromGis(
        governorateNo: governorateCode,
      );
      if (!mounted || requestId != _modernExplorerLookupRequestSeq) return;
      setState(() {
        _modernExplorerLguItems = lgus;
        _modernExplorerLguItemsGovernorateScope =
            (governorateCode ?? '').trim().isEmpty
                ? null
                : (governorateCode ?? '').trim();
        _modernExplorerLookupSourceLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _modernExplorerLookupRequestSeq) return;
      setState(() {
        _modernExplorerLookupSourceLoading = false;
        _modernExplorerLookupSourceError = e.toString();
      });
    }
  }

  Future<void> _ensureModernExplorerFilterSource(MapState mapState) async {
    if (_modernExplorerFilterSourceLoading ||
        _modernExplorerFilterSourceFeatures.isNotEmpty) {
      return;
    }

    final vp = mapState.viewport;
    if (vp == null) return;

    final layerKeys = _modernExplorerOptionalWaqfLayerKeys(mapState);
    if (layerKeys.isEmpty) return;

    final requestId = ++_modernExplorerFilterSourceRequestSeq;
    setState(() {
      _modernExplorerFilterSourceLoading = true;
      _modernExplorerFilterSourceError = null;
    });

    try {
      final rows = await ref.read(gisRepositoryProvider).fetchFeaturesInBounds(
            layerKeys: layerKeys,
            unitId: '00000000-0000-0000-0000-000000000000',
            west: vp.west,
            south: vp.south,
            east: vp.east,
            north: vp.north,
            simplifyMeters: 0,
            limit: 3500,
          );

      if (!mounted || requestId != _modernExplorerFilterSourceRequestSeq) return;
      setState(() {
        _modernExplorerFilterSourceFeatures = rows
            .where((feature) => _isModernExplorerWaqfPointFeature(feature))
            .toList(growable: false);
        _modernExplorerFilterSourceLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _modernExplorerFilterSourceRequestSeq) return;
      setState(() {
        _modernExplorerFilterSourceLoading = false;
        _modernExplorerFilterSourceError = e.toString();
      });
    }
  }

  List<String> _modernExplorerOptionalWaqfLayerKeys(MapState mapState) {
    final keys = <String>[];
    for (final section in _modernExplorerSections) {
      for (final spec in section.items) {
        if (_modernExplorerSpecFeatureType(spec) == null) continue;
        final layer = _resolveModernExplorerLayer(mapState, spec);
        if (layer != null && !keys.contains(layer.key)) keys.add(layer.key);
      }
    }
    return keys;
  }

  Future<void> _refreshModernExplorerBoundaryOverlays() async {
    final governorateCode = (_modernExplorerGovernorateFilter ?? '').trim();
    final lguCode = (_modernExplorerLocalityFilter ?? '').trim();

    // Search/dropdown controls are navigation-only. They must not draw
    // preview layers or mutate activeLayers; they only fit the camera to the
    // selected sovereign GIS geometry.
    ref.read(mapNotifierProvider.notifier).clearModernExplorerBoundaryOverlays();
    if (governorateCode.isEmpty && lguCode.isEmpty) return;

    try {
      final repo = ref.read(gisRepositoryProvider);
      final candidates = lguCode.isNotEmpty
          ? await repo.fetchModernExplorerLguBoundaryFeatures(
              governorateNo: governorateCode.isEmpty ? null : governorateCode,
              lguCode: lguCode,
            )
          : await repo.fetchModernExplorerGovernorateBoundaryFeatures(
              governorateNo: governorateCode,
            );
      if (!mounted || candidates.isEmpty) return;

      GisFeatureModel? focusFeature;
      if (lguCode.isNotEmpty) {
        for (final feature in candidates) {
          if (_modernExplorerFeatureMatchesLgu(feature, lguCode)) {
            focusFeature = feature;
            break;
          }
        }
      }
      if (focusFeature == null && governorateCode.isNotEmpty) {
        for (final feature in candidates) {
          if (_modernExplorerFeatureMatchesGovernorate(feature, governorateCode)) {
            focusFeature = feature;
            break;
          }
        }
      }
      focusFeature ??= candidates.first;
      _focusFeature(focusFeature, ref.read(mapNotifierProvider));
    } catch (_) {
      // Navigation failure must not affect layer state.
    }
  }

  void _setModernExplorerGovernorateFilter(String? value) {
    setState(() {
      _modernExplorerGovernorateFilter = value;
      _modernExplorerLocalityFilter = null;
    });
    _reloadModernExplorerLgusForGovernorate(value);
    unawaited(_refreshModernExplorerBoundaryOverlays());
  }

  void _setModernExplorerLocalityFilter(String? value) {
    setState(() => _modernExplorerLocalityFilter = value);
    unawaited(_refreshModernExplorerBoundaryOverlays());
  }

  void _setModernExplorerFeatureTypeFilter(MapState mapState, String? value) {
    setState(() {
      _modernExplorerFeatureTypeFilter = value;
      _modernExplorerFeatureLayerSelectionApplied = true;
    });
    _syncModernExplorerFeatureTypeLayers(mapState, value);
  }

  Future<void> _syncModernExplorerFeatureTypeLayers(
    MapState mapState,
    String? type,
  ) async {
    final next = mapState.activeLayers
        .where((key) => !_isModernExplorerOptionalWaqfLayerKey(key))
        .toList(growable: true);

    for (final section in _modernExplorerSections) {
      for (final spec in section.items) {
        final specType = _modernExplorerSpecFeatureType(spec);
        if (specType == null) continue;
        if (type != null && specType != type) continue;
        final layer = _resolveModernExplorerLayer(mapState, spec);
        if (layer != null && !next.contains(layer.key)) next.add(layer.key);
      }
    }

    await ref.read(mapNotifierProvider.notifier).setActiveLayers(next);
  }

  String? _modernExplorerSpecFeatureType(_ModernExplorerLayerSpec spec) {
    for (final key in spec.keyHints) {
      final type = _modernExplorerFeatureTypeForLayerKey(key);
      if (type != null) return type;
    }
    final title = _normalizeExplorerText(spec.title);
    if (title.contains('مساجد') || title.contains('مسجد')) return 'mosques';
    if (title.contains('مقامات') || title.contains('مقام')) return 'maqamat';
    if (title.contains('تكايا') || title.contains('تكيه')) return 'takaya';
    if (title.contains('مقابر') || title.contains('مقبره')) return 'cemeteries';
    if (title.contains('اثريه') || title.contains('اثار')) return 'archaeological';
    return null;
  }

  void _focusPalestine() {
    _clearVisualFocus();
    _mapController.move(const LatLng(31.95, 35.2), 8.2);
  }

  String? _currentSelectionLabel(MapState mapState) {
    final waqf = mapState.selectedWaqf;
    if (waqf != null) {
      final name = waqf.name?.trim();
      if (name != null && name.isNotEmpty) return name;
      return 'أصل وقفي محدد';
    }
    final feature = mapState.selectedFeature ??
        mapState.sitePreviewFeature ??
        mapState.blockPreviewFeature ??
        mapState.communityPreviewFeature ??
        mapState.governoratePreviewFeature;
    if (feature != null) {
      final ar = feature.titleAr?.trim();
      if (ar != null && ar.isNotEmpty) return ar;
      final en = feature.titleEn?.trim();
      if (en != null && en.isNotEmpty) return en;
      return 'عنصر محدد';
    }
    return null;
  }

  Widget _buildWorkspaceStatusBar(BuildContext context, MapState mapState) {
    final selectionLabel = _currentSelectionLabel(mapState);
    final activeLayersCount = mapState.activeLayers.length;
    final hasSelection = selectionLabel != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: Colors.white.withValues(alpha: 0.96),
            elevation: 3,
            shadowColor: Colors.black.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: PwfColors.outline),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  _WorkspaceInfoChip(
                    icon: Icons.map_outlined,
                    label: 'الخريطة الحديثة',
                    emphasized: true,
                  ),
                  _WorkspaceInfoChip(
                    icon: Icons.layers_outlined,
                    label: 'الطبقات المفعلة: $activeLayersCount',
                  ),
                  _WorkspaceInfoChip(
                    icon: _toolboxVisible ? Icons.tune : Icons.tune_outlined,
                    label: _toolboxVisible ? 'صندوق الأدوات مفتوح' : 'صندوق الأدوات مغلق',
                  ),
                  if (hasSelection)
                    _WorkspaceInfoChip(
                      icon: Icons.place_outlined,
                      label: selectionLabel!,
                      highlighted: true,
                    ),
                  OutlinedButton.icon(
                    onPressed: _focusPalestine,
                    icon: const Icon(Icons.public, size: 18),
                    label: const Text('إعادة التموضع إلى فلسطين'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PwfColors.royalRed,
                      side: BorderSide(
                        color: PwfColors.royalRed.withValues(alpha: 0.28),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  if (hasSelection)
                    TextButton.icon(
                      onPressed: () => ref.read(mapNotifierProvider.notifier).clearSelection(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('إغلاق التحديد'),
                      style: TextButton.styleFrom(
                        foregroundColor: PwfColors.onSurface.withValues(alpha: 0.72),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopLeftNav(BuildContext context) {
    Widget pill(IconData icon, VoidCallback onTap, {String? tip}) {
      return Tooltip(
        message: tip ?? '',
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: PwfColors.royalRed),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        pill(Icons.info_outline, () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('معلومات'),
              content: const Text(
                  'مستكشف الوقف — خريطة تفاعلية لعرض طبقات GIS وإجراء البحث.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إغلاق')),
              ],
            ),
          );
        }, tip: 'معلومات'),
        const SizedBox(height: 10),
        pill(Icons.add,
            () => _mapController.move(_safeCenter(), _clampOperationalZoom(_safeZoom() + 1)),
            tip: 'تكبير'),
        const SizedBox(height: 10),
        pill(Icons.remove,
            () => _mapController.move(_safeCenter(), _clampOperationalZoom(_safeZoom() - 1)),
            tip: 'تصغير'),
        const SizedBox(height: 10),
        if (_isRotated)
          _CompassButton(rotationRad: _rotationDeg, onReset: _resetNorth),
        const SizedBox(height: 10),
        pill(Icons.my_location, _focusPalestine, tip: 'تركيز فلسطين'),
      ],
    );
  }

  double _rightInsetForMapOverlays(BuildContext context, WidgetRef ref) {
    if (_modernExplorerVisible) return 368;
    if (!_toolboxVisible) return 16;
    final toolboxOnLeft = _modernExplorerVisible && _canShowDualSidePanels(context);
    if (toolboxOnLeft) return 16;
    final isExpanded = ref.watch(toolboxExpandedProvider);
    final w = ToolboxDrawer.widthFor(context, expanded: isExpanded);
    return w + 8;
  }

  Widget _buildBasemapButton(BuildContext context, WidgetRef ref) {
    final baseKey = ref.watch(baseMapProvider);
    final thumb = _basemapThumbAsset(baseKey);

    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          _clearVisualFocus();
          _openBasemapPicker(context, ref);
        },
        child: SizedBox(
          width: 146,
          height: 76,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _BasemapThumb(assetPath: thumb),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.18),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'الخرائط',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          color: PwfColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _basemapTitle(baseKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: PwfColors.onSurface.withValues(alpha: 0.68),
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: PwfColors.outline),
                  ),
                  child: const Icon(Icons.expand_more,
                      size: 18, color: PwfColors.onSurface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _basemapThumbAsset(String baseKey) {
    if (baseKey == 'satellite')
      return 'assets/images/basemaps/thumb_satellite.jpg';
    if (baseKey == 'dark') return 'assets/images/basemaps/thumb_dark.jpg';
    if (baseKey == 'standard' || baseKey == 'osm') {
      return 'assets/images/basemaps/thumb_osm.jpg';
    }
    return 'assets/images/basemaps/thumb_raster.jpg';
  }

  String _basemapTitle(String baseKey) {
    if (baseKey == 'satellite') return 'صورة فضائية';
    if (baseKey == 'dark') return 'خريطة داكنة';
    if (baseKey == 'standard' || baseKey == 'osm') return 'خريطة قياسية';
    return 'طبقة Raster';
  }

  Future<void> _openBasemapPicker(BuildContext context, WidgetRef ref) async {
    _clearVisualFocus();
    final mapState = ref.read(mapNotifierProvider);
    final selectedBase = ref.read(baseMapProvider);
    final dbRasters = mapState.gisLayers.where((l) {
      final type = (l.style['type'] ?? '').toString();
      return type == 'raster_xyz';
    }).toList();

    final items = <({
      String key,
      String title,
      String subtitle,
      String thumb,
      IconData icon
    })>[
      (
        key: 'standard',
        title: 'خريطة قياسية',
        subtitle: 'OpenStreetMap',
        thumb: 'assets/images/basemaps/thumb_osm.jpg',
        icon: Icons.public,
      ),
      (
        key: 'dark',
        title: 'خريطة داكنة',
        subtitle: 'واجهة مريحة لليل',
        thumb: 'assets/images/basemaps/thumb_dark.jpg',
        icon: Icons.dark_mode,
      ),
      (
        key: 'satellite',
        title: 'صورة فضائية',
        subtitle: 'Esri Imagery',
        thumb: 'assets/images/basemaps/thumb_satellite.jpg',
        icon: Icons.satellite_alt,
      ),
      ...dbRasters.take(3).map((l) => (
            key: l.key,
            title: l.nameAr,
            subtitle: (l.nameEn?.trim().isNotEmpty ?? false)
                ? l.nameEn!.trim()
                : 'Raster DB',
            thumb: 'assets/images/basemaps/thumb_raster.jpg',
            icon: Icons.layers,
          )),
    ];

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              width: 390,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: PwfColors.outline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: PwfColors.primaryBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.layers_outlined,
                            color: PwfColors.primaryBlue),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الخريطة الأساسية',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: PwfColors.onSurface,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'اختر الخلفية الأنسب للعرض والمقارنة البصرية.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: PwfColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon:
                            const Icon(Icons.close, color: PwfColors.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.08,
                    ),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final isActive = selectedBase == item.key;
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          ref.read(baseMapProvider.notifier).state = item.key;
                          Navigator.of(ctx).pop();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? PwfColors.primaryBlue.withValues(alpha: 0.05)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isActive
                                  ? PwfColors.primaryBlue
                                  : PwfColors.outline,
                              width: isActive ? 1.6 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(13),
                                        child: _BasemapThumb(
                                            assetPath: item.thumb),
                                      ),
                                    ),
                                    if (isActive)
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.94),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_circle,
                                                  size: 14,
                                                  color: PwfColors.primaryBlue),
                                              SizedBox(width: 4),
                                              Text(
                                                'محددة',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 11,
                                                  color: PwfColors.primaryBlue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 9),
                              Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 16,
                                    color: isActive
                                        ? PwfColors.primaryBlue
                                        : PwfColors.onSurface
                                            .withValues(alpha: 0.68),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12.5,
                                        color: PwfColors.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: PwfColors.onSurface
                                      .withValues(alpha: 0.60),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: PwfColors.outline),
                    ),
                    child: Text(
                      'الخريطة الحالية: ${_basemapTitle(selectedBase)}',
                      style: TextStyle(
                        color: PwfColors.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    _clearVisualFocus();
  }

  bool _shouldShowPointLabel(
    GisFeatureModel feature, {
    required double zoom,
    required Map<String, Map<String, dynamic>> layerStyle,
    required int visibleLayerCount,
  }) {
    final style = layerStyle[feature.layerKey] ?? const <String, dynamic>{};
    final labelsEnabled = _styleBoolValue(style['labelsEnabled'], false);
    if (labelsEnabled) {
      final field = (style['labelField'] ?? '').toString().trim();
      if (field.isEmpty) return false;
      final minZoom = _styleDoubleValue(style['labelMinZoom'], 12.0);
      final maxCount = _styleDoubleValue(style['labelMaxCount'], 250).round();
      return zoom >= minZoom && visibleLayerCount <= maxCount;
    }

    final key = feature.layerKey.trim().toLowerCase();
    const labeledKeys = {
      'gis_waqf_mosque_wb',
      'gis_waqf_mosque_gaza',
      'gis_waqf_maqamat_wb',
      'gis_waqf_cemeteries_wb',
      'gis_waqf_takaya_wb',
    };
    if (!labeledKeys.contains(key)) return false;
    return zoom >= 11.5 || key == 'gis_waqf_maqamat_wb';
  }

  String _pointLabelForFeature(
    GisFeatureModel feature,
    Map<String, Map<String, dynamic>> layerStyle,
  ) {
    final style = layerStyle[feature.layerKey] ?? const <String, dynamic>{};
    final configuredField = (style['labelField'] ?? '').toString().trim();
    if (configuredField.isNotEmpty) {
      final configured = _featureTextValue(feature, configuredField);
      if (configured != null && configured.trim().isNotEmpty) return configured.trim();
    }

    final candidates = [
      feature.titleAr,
      feature.props['nname']?.toString(),
      feature.props['name']?.toString(),
      feature.props['poi']?.toString(),
      feature.props['sitename_a']?.toString(),
      feature.titleEn,
      feature.displayTitle,
    ];
    for (final value in candidates) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return 'بدون اسم';
  }

  String? _featureTextValue(GisFeatureModel feature, String field) {
    final key = field.trim();
    if (key.isEmpty) return null;
    final direct = feature.props[key];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString();
    }
    final lower = key.toLowerCase();
    for (final entry in feature.props.entries) {
      if (entry.key.toString().toLowerCase() == lower &&
          entry.value != null &&
          entry.value.toString().trim().isNotEmpty) {
        return entry.value.toString();
      }
    }
    switch (lower) {
      case 'title_ar':
      case 'name_ar':
        return feature.titleAr;
      case 'title_en':
      case 'name_en':
        return feature.titleEn;
      case 'layer_key':
        return feature.layerKey;
      case 'id':
        return feature.id;
    }
    return null;
  }

  bool _styleBoolValue(dynamic value, bool fallback) {
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return fallback;
  }

  Color? _uniqueValueColorForFeature(
    GisFeatureModel feature,
    Map<String, dynamic> style,
  ) {
    final mode = (style['symbologyMode'] ?? '').toString().trim().toLowerCase();
    if (mode != 'unique_value') return null;
    final field = (style['uniqueValueField'] ?? '').toString().trim();
    if (field.isEmpty) return null;
    final featureValue = _featureTextValue(feature, field)?.trim().toLowerCase();
    if (featureValue == null || featureValue.isEmpty) return null;
    final rules = style['uniqueValueRules'];
    if (rules is! List) return null;
    for (final rawRule in rules) {
      if (rawRule is! Map) continue;
      final value = (rawRule['value'] ?? rawRule['key'] ?? rawRule['code'])
          ?.toString()
          .trim()
          .toLowerCase();
      if (value == null || value.isEmpty || value != featureValue) continue;
      return _parseHex(rawRule['color']?.toString(), fallback: PwfColors.primaryGold);
    }
    return null;
  }

  Map<String, dynamic> _featureEffectiveStyle(
    GisFeatureModel feature,
    Map<String, Map<String, dynamic>> layerStyle,
  ) {
    final base = <String, dynamic>{
      ...(layerStyle[feature.layerKey] ?? const <String, dynamic>{}),
    };
    final sequenceStyle = _operationalSequenceStyleForLayer(feature.layerKey);
    if (sequenceStyle != null) {
      base.addAll(sequenceStyle);
    }

    final color = _uniqueValueColorForFeature(feature, base);
    if (color != null) {
      final hex = _colorToHex(color);
      base['stroke'] = hex;
      base['fill'] = hex;
      base['markerColor'] = hex;
    }
    return base;
  }

  Map<String, dynamic>? _operationalSequenceStyleForLayer(String layerKey) {
    final key = layerKey.trim().toLowerCase();
    if (key.contains('westbank_gaza') ||
        key.contains('west_bank_gaza') ||
        key.contains('west_bank_and_gaza') ||
        key.contains('wb_gaza') ||
        key.contains('gaza_wb') ||
        key.contains('palestine') ||
        key.contains('historical_boundary') ||
        key.contains('historical_boundaries')) {
      return const {
        'stroke': '#003B73',
        'fill': '#003B73',
        'weight': 3.2,
        'fillOpacity': 0.030,
      };
    }
    if (_isZoomDrivenGovernorateLayerKey(layerKey)) {
      return const {
        'stroke': '#B22222',
        'fill': '#B22222',
        'weight': 2.8,
        'fillOpacity': 0.050,
      };
    }
    if (_isZoomDrivenCommunityLayerKey(layerKey)) {
      return const {
        'stroke': '#111111',
        'fill': '#111111',
        'weight': 3.6,
        'fillOpacity': 0.012,
      };
    }
    if (_isNaturalBlocksLayerKey(layerKey)) {
      return const {
        'stroke': '#2E7D32',
        'fill': '#2E7D32',
        'weight': 1.8,
        'fillOpacity': 0.025,
      };
    }
    if (_isZoomDrivenLguLayerKey(layerKey)) {
      return const {
        'stroke': '#FFD400',
        'fill': '#FFD400',
        'weight': 2.2,
        'fillOpacity': 0.045,
      };
    }
    if (_isZoomDrivenLocationLayerKey(layerKey)) {
      return const {
        'stroke': '#4B5563',
        'fill': '#4B5563',
        'weight': 1.8,
        'fillOpacity': 0.020,
      };
    }
    if (_isGuessingBlocksLayerKey(layerKey)) {
      return const {
        'stroke': '#7C3AED',
        'fill': '#7C3AED',
        'weight': 1.7,
        'fillOpacity': 0.025,
      };
    }
    if (_isZoomDrivenSettlementLayerKey(layerKey)) {
      return const {
        'stroke': '#F28C28',
        'fill': '#F28C28',
        'weight': 1.9,
        'fillOpacity': 0.030,
      };
    }
    return null;
  }

  String _fallbackTileTemplate({
    required String baseKey,
    required bool fallbackDark,
    required bool noRoadLabels,
  }) {
    if (baseKey == 'satellite') {
      return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
    if (noRoadLabels) {
      return fallbackDark
          ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png'
          : 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png';
    }
    return fallbackDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }


  Color _markerColorForFeature(
    GisFeatureModel feature,
    Map<String, Map<String, dynamic>> layerStyle,
  ) {
    final style = layerStyle[feature.layerKey] ?? const <String, dynamic>{};
    final uniqueColor = _uniqueValueColorForFeature(feature, style);
    if (uniqueColor != null) return uniqueColor;

    final rawColor = (style['markerColor'] ??
            style['fill'] ??
            style['stroke'] ??
            feature.props['markerColor'] ??
            feature.props['color'])
        ?.toString();
    return _parseHex(rawColor, fallback: PwfColors.primaryGold);
  }

  double _markerOpacityForFeature(
    GisFeatureModel feature,
    Map<String, Map<String, dynamic>> layerStyle,
  ) {
    final style = layerStyle[feature.layerKey] ?? const <String, dynamic>{};
    final raw = style['opacity'];
    if (raw is num) return raw.toDouble().clamp(0.0, 1.0).toDouble();
    return 1.0;
  }

  double _markerSizeForFeature(
    GisFeatureModel feature,
    Map<String, Map<String, dynamic>> layerStyle,
  ) {
    final style = layerStyle[feature.layerKey] ?? const <String, dynamic>{};
    final raw = style['markerSize'] ?? style['pointSize'];
    if (raw is num) return raw.toDouble().clamp(18.0, 72.0).toDouble();
    final parsed = double.tryParse(raw?.toString() ?? '');
    return (parsed ?? 28).clamp(18.0, 72.0).toDouble();
  }

  String _pointShapeForFeature(
    GisFeatureModel feature,
    Map<String, Map<String, dynamic>> layerStyle,
  ) {
    final style = layerStyle[feature.layerKey] ?? const <String, dynamic>{};
    return (style['pointShape'] ?? style['markerShape'] ?? 'pin')
        .toString()
        .trim()
        .toLowerCase();
  }

  IconData _markerIconForFeature(
    GisFeatureModel feature,
    Map<String, Map<String, dynamic>> layerStyle,
  ) {
    switch (_pointShapeForFeature(feature, layerStyle)) {
      case 'mosque':
        return Icons.mosque_outlined;
      case 'cemetery':
        return Icons.account_balance_outlined;
      case 'landmark':
        return Icons.location_city_outlined;
      case 'square':
        return Icons.stop_rounded;
      case 'diamond':
        return Icons.diamond_outlined;
      case 'circle':
        return Icons.circle_outlined;
      default:
        return Icons.place;
    }
  }

  Map<String, Map<String, dynamic>> _buildEffectiveLayerStyle(MapState mapState) {
    final out = <String, Map<String, dynamic>>{
      for (final layer in mapState.gisLayers) layer.key: <String, dynamic>{...layer.style},
    };

    for (final entry in mapState.layerOpacity.entries) {
      final style = out.putIfAbsent(entry.key, () => <String, dynamic>{});
      style['opacity'] = entry.value.clamp(0.0, 1.0).toDouble();
    }

    for (final entry in _explorerLayerVisualOverrides.entries) {
      final style = out.putIfAbsent(entry.key, () => <String, dynamic>{});
      final override = entry.value;
      style['weight'] = override.strokeWidth;
      style['stroke'] = _colorToHex(override.strokeColor);
      style['fill'] = _colorToHex(override.fillColor);
      style['markerColor'] = _colorToHex(override.strokeColor);
      style['fillOpacity'] = override.fillOpacity;
    }

    return out;
  }

  String _colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  double _styleDoubleValue(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  void _showModernExplorerLayerMoreMenu(GisLayerModel layer) {
    final currentMapState = ref.read(mapNotifierProvider);
    var visual = _explorerLayerVisualOverrides[layer.key] ??
        _ExplorerLayerVisualOverride(
          strokeWidth: _styleDoubleValue(layer.style['weight'], 1.2).clamp(0.5, 8.0).toDouble(),
          strokeColor: _parseHex(
            layer.style['stroke']?.toString() ?? layer.style['markerColor']?.toString(),
            fallback: PwfColors.primaryBlue,
          ),
          fillColor: _parseHex(
            layer.style['fill']?.toString() ?? layer.style['markerColor']?.toString(),
            fallback: PwfColors.primaryGold,
          ),
          fillOpacity: _styleDoubleValue(layer.style['fillOpacity'], 0.08).clamp(0.0, 0.85).toDouble(),
        );
    var opacity = (currentMapState.layerOpacity[layer.key] ?? layer.defaultOpacity)
        .clamp(0.0, 1.0).toDouble();

    void applyVisual(_ExplorerLayerVisualOverride next) {
      visual = next;
      setState(() {
        _explorerLayerVisualOverrides[layer.key] = next;
        _cachedPolygonFeatureSource = null;
        _cachedPolygonStyleSignature = null;
        _cachedGisPolygons = const [];
      });
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: PwfColors.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded, color: PwfColors.primaryBlue, size: 18),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'المزيد: ${layer.nameAr}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: PwfColors.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'إغلاق',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _ExplorerLayerMoreSlider(
                        label: 'سمك خط تمثيل الطبقة الهندسية',
                        value: visual.strokeWidth,
                        min: 0.5,
                        max: 8.0,
                        divisions: 15,
                        valueLabel: visual.strokeWidth.toStringAsFixed(1),
                        onChanged: (value) {
                          setModalState(() {
                            applyVisual(visual.copyWith(strokeWidth: value));
                          });
                        },
                      ),
                      _ExplorerLayerMoreSlider(
                        label: 'شفافية الطبقة',
                        value: opacity,
                        min: 0.05,
                        max: 1.0,
                        divisions: 19,
                        valueLabel: '${(opacity * 100).round()}%',
                        onChanged: (value) {
                          setModalState(() => opacity = value);
                          ref.read(mapNotifierProvider.notifier).setLayerOpacity(layer.key, value);
                          setState(() {
                            _cachedPolygonFeatureSource = null;
                            _cachedPolygonStyleSignature = null;
                            _cachedGisPolygons = const [];
                          });
                        },
                      ),
                      _ExplorerLayerMoreSlider(
                        label: 'شفافية تظليل الطبقة',
                        value: visual.fillOpacity,
                        min: 0.0,
                        max: 0.85,
                        divisions: 17,
                        valueLabel: '${(visual.fillOpacity * 100).round()}%',
                        onChanged: (value) {
                          setModalState(() {
                            applyVisual(visual.copyWith(fillOpacity: value));
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _ExplorerColorPickerRow(
                        label: 'لون خط الطبقة',
                        value: visual.strokeColor,
                        onChanged: (color) {
                          setModalState(() {
                            applyVisual(visual.copyWith(strokeColor: color));
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _ExplorerColorPickerRow(
                        label: 'لون تظليل الطبقة',
                        value: visual.fillColor,
                        onChanged: (color) {
                          setModalState(() {
                            applyVisual(visual.copyWith(fillColor: color));
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              _explorerLayerVisualOverrides.remove(layer.key);
                              opacity = layer.defaultOpacity;
                            });
                            ref.read(mapNotifierProvider.notifier).setLayerOpacity(layer.key, layer.defaultOpacity);
                            setState(() {
                              _cachedPolygonFeatureSource = null;
                              _cachedPolygonStyleSignature = null;
                              _cachedGisPolygons = const [];
                            });
                          },
                          icon: const Icon(Icons.restart_alt_rounded, size: 16),
                          label: const Text('إعادة ضبط إعدادات العرض'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildToolboxToggle(WidgetRef ref) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(16),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _toolboxVisible = !_toolboxVisible),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PwfColors.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _toolboxVisible ? Icons.close_rounded : Icons.tune_rounded,
                color: PwfColors.royalRed,
              ),
              const SizedBox(width: 8),
              Text(
                _toolboxVisible ? 'إغلاق الأدوات' : 'صندوق الأدوات',
                style: const TextStyle(
                  color: PwfColors.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolboxOverlay(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(toolboxExpandedProvider);
    final w = ToolboxDrawer.widthFor(context, expanded: isExpanded);
    final showOnLeft = _toolboxVisible &&
        _modernExplorerVisible &&
        _canShowDualSidePanels(context);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      top: _toolboxTopOffset,
      bottom: _toolboxBottomOffset,
      left: showOnLeft ? 0 : null,
      right: showOnLeft
          ? null
          : (_toolboxVisible ? _toolboxRightMargin : -(w + 28)),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          width: w,
          child: const ToolboxDrawer(),
        ),
      ),
    );
  }

  Widget _buildPlaceResultsOverlay(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final maxW = w > 900 ? 720.0 : w - 24;

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: maxW,
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PwfColors.royalRed.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _placeResults.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
          itemBuilder: (ctx, i) {
            final r = _placeResults[i];
            final kindLabel = switch (r.kind) {
              'governorate' => 'محافظة',
              'lgu' => 'بلدية/هيئة',
              'community' => 'تجمع',
              'location' => 'موقع',
              'natural_block' => 'حوض طبيعي',
              'guessing_block' => 'حوض تخمين',
              'gis_target' => 'نتيجة GIS',
              'layer_feature' => 'نتيجة من الطبقات المفتوحة',
              _ => 'موقع',
            };
            final subtitle = r.layerLabel == null
                ? kindLabel
                : '$kindLabel • ${r.layerLabel}';

            return ListTile(
              dense: true,
              leading:
                  const Icon(Icons.place_outlined, color: PwfColors.royalRed),
              title: Text(r.nameAr,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(subtitle),
              onTap: () => _selectPlace(r),
            );
          },
        ),
      ),
    );
  }

  LatLng _safeCenter() {
    try {
      final cam = (_mapController as dynamic).camera;
      if (cam != null && cam.center is LatLng) return cam.center as LatLng;
    } catch (_) {}
    try {
      final c = (_mapController as dynamic).center;
      if (c is LatLng) return c;
    } catch (_) {}
    return const LatLng(31.95, 35.2);
  }

  double _clampOperationalZoom(double zoom) {
    if (zoom < _mapMinZoom) return _mapMinZoom;
    if (zoom > _mapMaxZoom) return _mapMaxZoom;
    return zoom;
  }

  double _safeZoom() {
    try {
      final cam = (_mapController as dynamic).camera;
      if (cam != null && cam.zoom is num) return (cam.zoom as num).toDouble();
    } catch (_) {}
    try {
      final z = (_mapController as dynamic).zoom;
      if (z is num) return (z as num).toDouble();
    } catch (_) {}
    return ref.read(mapNotifierProvider).zoom;
  }

  void _openGoToDialog() {
    final latC = TextEditingController();
    final lngC = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('الذهاب إلى الإحداثيات'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latC,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'Latitude'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: lngC,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'Longitude'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            TextButton(
              onPressed: () {
                final lat = double.tryParse(latC.text.trim());
                final lng = double.tryParse(lngC.text.trim());
                if (lat == null || lng == null) return;
                _mapController.move(LatLng(lat, lng), 16);
                ref.read(lastTapLatLngProvider.notifier).state =
                    LatLng(lat, lng);
                Navigator.pop(ctx);
              },
              child: const Text('اذهب'),
            ),
          ],
        );
      },
    ).then((_) {
      latC.dispose();
      lngC.dispose();
    });
  }

  Future<void> _identifyAtPoint(LatLng tap, MapState mapState) async {
    final requestId = ++_identifyRequestSeq;
    final localHit = _findIdentifyHit(tap, mapState.gisFeatures, mapState.zoom);
    final layerKeys = mapState.activeLayers.isNotEmpty
        ? mapState.activeLayers
        : mapState.gisFeatures.map((f) => f.layerKey).toSet().toList();

    ref.read(lastTapLatLngProvider.notifier).state = tap;
    ref.read(identifyResultProvider.notifier).state = MapIdentifyResult(
      point: tap,
      feature: localHit?.feature,
      distanceMeters: localHit?.distanceMeters,
      source: 'postgis',
      isLoading: true,
      message: localHit?.feature == null
          ? 'جاري التعريف المكاني عبر PostGIS...'
          : 'جاري التحقق المكاني الدقيق عبر PostGIS...',
    );

    try {
      final hits = await ref.read(gisRepositoryProvider).spatialIdentify(
            lat: tap.latitude,
            lng: tap.longitude,
            layerKeys: layerKeys,
            radiusMeters: _identifyRadiusMetersForZoom(mapState.zoom),
            limit: 8,
          );
      if (!mounted || requestId != _identifyRequestSeq) return;

      if (hits.isNotEmpty) {
        final hit = hits.first;
        ref.read(identifyResultProvider.notifier).state = MapIdentifyResult(
          point: tap,
          feature: hit.feature,
          distanceMeters: hit.distanceMeters,
          source: 'postgis',
          relation: hit.relation,
          score: hit.score,
          candidatesCount: hits.length,
          message: 'تم التعريف المكاني الدقيق عبر PostGIS.',
        );
        ref.read(mapNotifierProvider.notifier).selectGisFeature(hit.feature);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تعريف العنصر: ${hit.feature.displayTitle}')),
        );
        return;
      }

      ref.read(identifyResultProvider.notifier).state = MapIdentifyResult(
        point: tap,
        feature: localHit?.feature,
        distanceMeters: localHit?.distanceMeters,
        source: 'local_fallback',
        candidatesCount: localHit?.feature == null ? 0 : 1,
        message: localHit?.feature == null
            ? 'لم يرجع PostGIS نتيجة ضمن النطاق الحالي.'
            : 'لم يرجع PostGIS نتيجة؛ تم استخدام العنصر المحمّل محليًا.',
      );
      if (localHit?.feature != null) {
        ref.read(mapNotifierProvider.notifier).selectGisFeature(localHit!.feature);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localHit?.feature == null
                ? 'لم يتم العثور على عنصر قريب.'
                : 'تم تعريف العنصر محليًا: ${localHit!.feature.displayTitle}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted || requestId != _identifyRequestSeq) return;
      ref.read(identifyResultProvider.notifier).state = MapIdentifyResult(
        point: tap,
        feature: localHit?.feature,
        distanceMeters: localHit?.distanceMeters,
        source: 'local_fallback',
        candidatesCount: localHit?.feature == null ? 0 : 1,
        message: 'تعذر تنفيذ التعريف المكاني عبر PostGIS؛ تم استخدام التعريف المحلي. $e',
      );
      if (localHit?.feature != null) {
        ref.read(mapNotifierProvider.notifier).selectGisFeature(localHit!.feature);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localHit?.feature == null
                ? 'تعذر التعريف عبر PostGIS ولا توجد نتيجة محلية.'
                : 'تعذر التعريف عبر PostGIS، وتم استخدام نتيجة محلية.',
          ),
        ),
      );
    }
  }

  double _identifyRadiusMetersForZoom(double zoom) {
    if (zoom >= 17) return 25;
    if (zoom >= 15) return 45;
    if (zoom >= 13) return 90;
    if (zoom >= 11) return 180;
    return 350;
  }

  void _prepareReportDraftAtPoint(LatLng tap, MapState mapState) {
    final hit = _findIdentifyHit(tap, mapState.gisFeatures, mapState.zoom);
    ref.read(lastTapLatLngProvider.notifier).state = tap;
    ref.read(mapReportDraftProvider.notifier).state = MapReportDraft(
      point: tap,
      feature: hit?.feature,
      createdAt: DateTime.now(),
    );
    if (hit?.feature != null) {
      ref.read(mapNotifierProvider.notifier).selectGisFeature(hit!.feature);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hit?.feature == null
              ? 'تم تثبيت موقع البلاغ بدون عنصر مرتبط.'
              : 'تم ربط البلاغ مبدئيًا بـ ${hit!.feature.displayTitle}',
        ),
      ),
    );
  }

  bool _geometryBoundsContains(Map<String, dynamic>? geometry, LatLng tap) {
    if (!_isPolygonGeometry(geometry)) return false;
    final points = <LatLng>[];
    final type = geometry?['type'];
    final coords = geometry?['coordinates'];

    if (type == 'Polygon' && coords is List) {
      for (final ring in coords) {
        points.addAll(_toLatLngList(ring));
      }
    } else if (type == 'MultiPolygon' && coords is List) {
      for (final polygon in coords) {
        if (polygon is! List) continue;
        for (final ring in polygon) {
          points.addAll(_toLatLngList(ring));
        }
      }
    }

    if (points.isEmpty) return false;
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    return tap.latitude >= minLat &&
        tap.latitude <= maxLat &&
        tap.longitude >= minLng &&
        tap.longitude <= maxLng;
  }

  _IdentifyHit? _findIdentifyHit(
    LatLng tap,
    List<GisFeatureModel> features,
    double zoom,
  ) {
    final snap = _findSnap(tap, features, zoom);
    if (snap != null) {
      final distanceMeters = const Distance()(tap, snap.point);
      return _IdentifyHit(feature: snap.feature, distanceMeters: distanceMeters);
    }

    for (final feature in features) {
      if (!_isPolygonGeometry(feature.geom)) continue;
      if (_geometryBoundsContains(feature.geom, tap)) {
        return _IdentifyHit(feature: feature, distanceMeters: null);
      }
    }
    return null;
  }

  _SnapResult? _findSnap(
      LatLng tap, List<GisFeatureModel> features, double zoom) {
    if (features.isEmpty) return null;

    // Radius in meters (dev) — tighter on higher zoom.
    final radiusM = zoom >= 16
        ? 30.0
        : zoom >= 14
            ? 60.0
            : 120.0;

    final dist = const Distance();
    _SnapResult? best;
    double bestD = radiusM;

    for (final f in features) {
      final p = _extractCoordinates(f.centroid ?? f.geom);
      if (p == null) continue;
      final d = dist(tap, p);
      if (d <= bestD) {
        bestD = d;
        best = _SnapResult(point: p, feature: f);
      }
    }

    return best;
  }

  _RasterBase? _findRasterLayer(List<GisLayerModel> layers, String baseKey) {
    if (baseKey == 'standard' || baseKey == 'dark' || baseKey == 'satellite')
      return null;

    final match = layers.where((l) {
      final type = (l.style['type'] ?? '').toString();
      return l.key == baseKey && type == 'raster_xyz';
    }).toList();

    if (match.isEmpty) return null;

    final style = match.first.style;
    final url = (style['urlTemplate'] ?? '').toString();
    if (url.isEmpty) return null;

    return _RasterBase(
      key: match.first.key,
      urlTemplate: url,
      attribution: (style['attribution'] ?? '').toString(),
    );
  }


  bool _isPolygonGeometry(Map<String, dynamic>? geometry) {
    final type = geometry?['type'];
    return type == 'Polygon' || type == 'MultiPolygon';
  }

  Color _previewOverlayBorderColor(int level) {
    switch (level) {
      case 0:
        return PwfColors.royalRed;
      case 1:
        return const Color(0xFF2563EB);
      case 2:
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF0F766E);
    }
  }

  Color _previewOverlayFillColor(int level) {
    switch (level) {
      case 0:
        return PwfColors.royalRed.withValues(alpha: 0.05);
      case 1:
        return const Color(0xFF2563EB).withValues(alpha: 0.07);
      case 2:
        return const Color(0xFF7C3AED).withValues(alpha: 0.08);
      default:
        return const Color(0xFF0F766E).withValues(alpha: 0.10);
    }
  }

  String _previewOverlayLabelText(GisFeatureModel feature, {required int level}) {
    final title = feature.displayTitle.trim();
    final blockNo = (feature.props['block_no']?.toString() ?? '').trim();
    if (level == 2 && blockNo.isNotEmpty && title.isNotEmpty) {
      return '$title • حوض $blockNo';
    }
    if (level == 2 && blockNo.isNotEmpty) return 'حوض $blockNo';
    return title;
  }

  List<Polygon> _buildPreviewOverlayPolygons(GisFeatureModel feature, {required int level}) {
    final geom = feature.geom;
    if (geom == null) return const [];
    final out = <Polygon>[];
    final type = geom['type'];
    final coords = geom['coordinates'];

    void addPolygonPoints(List<LatLng> pts) {
      if (pts.length < 3) return;
      out.add(
        Polygon(
          points: pts,
          color: _previewOverlayFillColor(level),
          borderColor: _previewOverlayBorderColor(level),
          borderStrokeWidth: 2.8,
        ),
      );
    }

    if (type == 'Polygon' && coords is List && coords.isNotEmpty) {
      addPolygonPoints(_toLatLngList(coords.first));
    } else if (type == 'MultiPolygon' && coords is List) {
      for (final polygon in coords) {
        if (polygon is List && polygon.isNotEmpty) {
          addPolygonPoints(_toLatLngList(polygon.first));
        }
      }
    }
    return out;
  }

  List<Polygon> _buildSelectedOverlayPolygons(GisFeatureModel feature) {
    final geom = feature.geom;
    if (geom == null) return const [];
    final out = <Polygon>[];
    final type = geom['type'];
    final coords = geom['coordinates'];

    void addPolygonPoints(List<LatLng> pts) {
      if (pts.length < 3) return;
      out.add(
        Polygon(
          points: pts,
          color: PwfColors.primaryGold.withValues(alpha: 0.08),
          borderColor: PwfColors.royalRed,
          borderStrokeWidth: 3.0,
        ),
      );
    }

    if (type == 'Polygon' && coords is List && coords.isNotEmpty) {
      addPolygonPoints(_toLatLngList(coords.first));
    } else if (type == 'MultiPolygon' && coords is List) {
      for (final polygon in coords) {
        if (polygon is List && polygon.isNotEmpty) {
          addPolygonPoints(_toLatLngList(polygon.first));
        }
      }
    }
    return out;
  }

  LatLngBounds? _boundsFromGeometry(Map<String, dynamic>? geometry) {
    if (!_isPolygonGeometry(geometry)) return null;
    final points = <LatLng>[];
    final type = geometry?['type'];
    final coords = geometry?['coordinates'];

    if (type == 'Polygon' && coords is List) {
      for (final ring in coords) {
        points.addAll(_toLatLngList(ring));
      }
    } else if (type == 'MultiPolygon' && coords is List) {
      for (final polygon in coords) {
        if (polygon is! List) continue;
        for (final ring in polygon) {
          points.addAll(_toLatLngList(ring));
        }
      }
    }

    final valid = points
        .where((p) => p.latitude.isFinite && p.longitude.isFinite)
        .toList();
    if (valid.length < 3) return null;
    return LatLngBounds.fromPoints(valid);
  }

  List<Polygon> _buildCachedPolygons(
    List<GisFeatureModel> features,
    Map<String, Map<String, dynamic>> layerStyle,
  ) {
    final styleSignature = _polygonStyleSignature(features, layerStyle);
    if (identical(_cachedPolygonFeatureSource, features) &&
        _cachedPolygonStyleSignature == styleSignature) {
      return _cachedGisPolygons;
    }

    final polygonFeatures = features.where((f) {
      final t = f.geom?['type'];
      return t == 'Polygon' || t == 'MultiPolygon';
    }).toList(growable: false);

    final polygons = _buildPolygons(polygonFeatures, layerStyle);
    _cachedPolygonFeatureSource = features;
    _cachedPolygonStyleSignature = styleSignature;
    _cachedGisPolygons = polygons;
    return polygons;
  }

  String _polygonStyleSignature(
    List<GisFeatureModel> features,
    Map<String, Map<String, dynamic>> layerStyle,
  ) {
    final keys = features
        .where((f) {
          final t = f.geom?['type'];
          return t == 'Polygon' || t == 'MultiPolygon';
        })
        .map((f) => f.layerKey)
        .toSet()
        .toList()
      ..sort();

    return keys.map((key) {
      final style = layerStyle[key] ?? const <String, dynamic>{};
      return [
        key,
        style['stroke'],
        style['fill'],
        style['weight'],
        style['fillOpacity'],
        style['symbologyMode'],
        style['uniqueValueField'],
        style['uniqueValueRules'],
      ].join(':');
    }).join('|');
  }

  List<Polygon> _buildPolygons(
    List<GisFeatureModel> features,
    Map<String, Map<String, dynamic>> layerStyle,
  ) {
    final out = <Polygon>[];

    for (final f in features) {
      final geom = f.geom;
      if (geom == null) continue;

      final type = geom['type'];
      final coords = geom['coordinates'];

      final style = _featureEffectiveStyle(f, layerStyle);
      final stroke = _parseHex(style['stroke']?.toString(),
          fallback: PwfColors.primaryBlue);
      final fill =
          _parseHex(style['fill']?.toString(), fallback: PwfColors.primaryBlue);
      final weight =
          (style['weight'] is num) ? (style['weight'] as num).toDouble() : 1.2;
      final fillOpacity = (style['fillOpacity'] is num)
          ? (style['fillOpacity'] as num).toDouble().clamp(0.0, 1.0).toDouble()
          : 0.05;
      final layerOpacity = (style['opacity'] is num)
          ? (style['opacity'] as num).toDouble().clamp(0.0, 1.0).toDouble()
          : 1.0;

      if (type == 'Polygon' && coords is List) {
        final rings = coords;
        if (rings.isEmpty) continue;
        final outer = rings[0];
        final pts = _toLatLngList(outer);
        if (pts.length >= 3) {
          out.add(
            Polygon(
              points: pts,
              color: fill.withValues(alpha: fillOpacity * layerOpacity),
              borderColor: stroke.withValues(alpha: layerOpacity),
              borderStrokeWidth: weight,
            ),
          );
        }
      } else if (type == 'MultiPolygon' && coords is List) {
        for (final poly in coords) {
          if (poly is! List || poly.isEmpty) continue;
          final outer = poly[0];
          final pts = _toLatLngList(outer);
          if (pts.length >= 3) {
            out.add(
              Polygon(
                points: pts,
                color: fill.withValues(alpha: fillOpacity * layerOpacity),
                borderColor: stroke.withValues(alpha: layerOpacity),
                borderStrokeWidth: weight,
              ),
            );
          }
        }
      }
    }

    return out;
  }

  List<LatLng> _toLatLngList(dynamic ring) {
    if (ring is! List) return const [];
    final pts = <LatLng>[];
    for (final p in ring) {
      if (p is List && p.length >= 2) {
        final lon = (p[0] as num).toDouble();
        final lat = (p[1] as num).toDouble();
        pts.add(LatLng(lat, lon));
      }
    }
    return pts;
  }

  LatLng? _extractCoordinates(Map<String, dynamic>? geometry) {
    if (geometry == null) return null;
    try {
      final type = geometry['type'];
      final coords = geometry['coordinates'];

      if (type == 'Point' && coords is List && coords.length >= 2) {
        return LatLng(
            (coords[1] as num).toDouble(), (coords[0] as num).toDouble());
      }

      // MultiPoint / Polygon / MultiPolygon: walk down to the first
      // coordinate pair so point-like waqf GIS layers remain visible.
      if (coords is List && coords.isNotEmpty) {
        dynamic cursor = coords;
        while (cursor is List && cursor.isNotEmpty) {
          final first = cursor[0];
          if (first is List &&
              first.length >= 2 &&
              first[0] is num &&
              first[1] is num) {
            return LatLng(
              (first[1] as num).toDouble(),
              (first[0] as num).toDouble(),
            );
          }
          cursor = first;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Color _parseHex(String? hex, {required Color fallback}) {
    if (hex == null || hex.isEmpty) return fallback;
    var v = hex.trim();
    if (v.startsWith('#')) v = v.substring(1);
    if (v.length == 6) v = 'FF$v';
    if (v.length != 8) return fallback;
    try {
      final n = int.parse(v, radix: 16);
      return Color(n);
    } catch (_) {
      return fallback;
    }
  }
}

class _RasterCandidate {
  final String key;
  final String title;
  const _RasterCandidate({required this.key, required this.title});
}

class _PlaceResult {
  final String kind;
  final String nameAr;
  final String? nameEn;
  final LatLng center;
  final GisFeatureModel? feature;
  final String? layerLabel;

  const _PlaceResult({
    required this.kind,
    required this.nameAr,
    required this.nameEn,
    required this.center,
    this.feature,
    this.layerLabel,
  });
}

class _RasterBase {
  final String key;
  final String urlTemplate;
  final String attribution;

  const _RasterBase({
    required this.key,
    required this.urlTemplate,
    required this.attribution,
  });
}

class _IdentifyHit {
  final GisFeatureModel feature;
  final double? distanceMeters;

  const _IdentifyHit({required this.feature, this.distanceMeters});
}

class _SnapResult {
  final LatLng point;
  final GisFeatureModel feature;
  const _SnapResult({required this.point, required this.feature});
}

String? _computeMeasureLabel(List<LatLng> points, MeasureMode mode) {
  if (mode == MeasureMode.distance) {
    if (points.length < 2) return null;
    final d = ll.Distance();
    double meters = 0;
    for (var i = 1; i < points.length; i++) {
      meters += d(points[i - 1], points[i]);
    }
    return meters >= 1000
        ? 'المسافة: ${(meters / 1000).toStringAsFixed(2)} كم'
        : 'المسافة: ${meters.toStringAsFixed(1)} م';
  }

  if (points.length < 3) return null;
  final sqm = _approxPolygonAreaSqm(points);
  final dunums = sqm / 1000.0;
  return dunums >= 1
      ? 'المساحة: ${dunums.toStringAsFixed(2)} دونم'
      : 'المساحة: ${sqm.toStringAsFixed(1)} م²';
}

double _approxPolygonAreaSqm(List<LatLng> pts) {
  if (pts.length < 3) return 0;
  final avgLat =
      pts.map((e) => e.latitude).reduce((a, b) => a + b) / pts.length;
  const metersPerDegLat = 111320.0;
  final metersPerDegLng = 111320.0 * math.cos(avgLat * math.pi / 180.0);
  double area = 0;
  for (var i = 0; i < pts.length; i++) {
    final j = (i + 1) % pts.length;
    final xi = pts[i].longitude * metersPerDegLng;
    final yi = pts[i].latitude * metersPerDegLat;
    final xj = pts[j].longitude * metersPerDegLng;
    final yj = pts[j].latitude * metersPerDegLat;
    area += xi * yj - xj * yi;
  }
  return area.abs() / 2.0;
}

class _GisErrorChip extends StatelessWidget {
  final String error;
  const _GisErrorChip({required this.error});

  @override
  Widget build(BuildContext context) {
    if (error.trim().isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: 16,
      left: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFB22222).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 16, color: Colors.white),
              const SizedBox(width: 6),
              SizedBox(
                width: 280,
                child: Text(
                  error,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _WorkspaceInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasized;
  final bool highlighted;

  const _WorkspaceInfoChip({
    required this.icon,
    required this.label,
    this.emphasized = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlighted
        ? PwfColors.royalRed.withValues(alpha: 0.08)
        : (emphasized
            ? PwfColors.primaryBlue.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.08));
    final border = highlighted
        ? PwfColors.royalRed.withValues(alpha: 0.18)
        : (emphasized
            ? PwfColors.primaryBlue.withValues(alpha: 0.18)
            : PwfColors.outline.withValues(alpha: 0.8));
    final fg = highlighted ? PwfColors.royalRed : PwfColors.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: emphasized || highlighted ? FontWeight.w800 : FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedWaqfCard extends ConsumerWidget {
  final WaqfModel waqf;
  const _SelectedWaqfCard({required this.waqf});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxWidth = math.min(MediaQuery.of(context).size.width - 32, 380.0);

    return Positioned(
      left: 16,
      bottom: 92,
      child: SafeArea(
        top: false,
        right: false,
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PwfColors.outline),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                waqf.name?.trim().isNotEmpty == true
                                    ? waqf.name!.trim()
                                    : 'أصل وقفي',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: PwfColors.onSurface,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F8FC),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: PwfColors.outline),
                                ),
                                child: Text(
                                  'pwf_key: ${waqf.pwfKey}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: PwfColors.onSurface
                                        .withValues(alpha: 0.82),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => ref
                                .read(mapNotifierProvider.notifier)
                                .clearSelection(),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.close,
                                  color: PwfColors.onSurface, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.go('/waqf/${waqf.id}'),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('فتح التفاصيل'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PwfColors.royalRed,
                            side: const BorderSide(color: PwfColors.outline),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            final coords = _extractCoordinates(waqf.geometry);
                            if (coords == null) return;
                            Clipboard.setData(ClipboardData(
                              text:
                                  '${coords.latitude.toStringAsFixed(6)}, ${coords.longitude.toStringAsFixed(6)}',
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('تم نسخ الإحداثيات')),
                            );
                          },
                          icon:
                              const Icon(Icons.content_copy_outlined, size: 18),
                          label: const Text('نسخ الإحداثيات'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PwfColors.primaryBlue,
                            side: const BorderSide(color: PwfColors.outline),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedFeatureCard extends ConsumerWidget {
  final GisFeatureModel feature;
  const _SelectedFeatureCard({required this.feature});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxWidth = math.min(MediaQuery.of(context).size.width - 32, 380.0);
    final title = (feature.titleAr?.trim().isNotEmpty == true)
        ? feature.titleAr!.trim()
        : (feature.titleEn?.trim().isNotEmpty == true
            ? feature.titleEn!.trim()
            : 'معلم محدد');

    return Positioned(
      left: 16,
      bottom: 92,
      child: SafeArea(
        top: false,
        right: false,
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PwfColors.outline),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 14,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: PwfColors.onSurface,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F8FC),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: PwfColors.outline),
                                ),
                                child: Text(
                                  'الطبقة: ${feature.layerNameAr ?? feature.layerKey}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: PwfColors.onSurface
                                        .withValues(alpha: 0.82),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => ref
                                .read(mapNotifierProvider.notifier)
                                .clearSelection(),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.close,
                                  color: PwfColors.onSurface, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _SelectedFeaturePopupProps(feature: feature),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            final coords = _extractCoordinates(
                                feature.centroid ?? feature.geom);
                            if (coords == null) return;
                            Clipboard.setData(ClipboardData(
                              text:
                                  '${coords.latitude.toStringAsFixed(6)}, ${coords.longitude.toStringAsFixed(6)}',
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('تم نسخ الإحداثيات')),
                            );
                          },
                          icon:
                              const Icon(Icons.content_copy_outlined, size: 18),
                          label: const Text('نسخ الإحداثيات'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PwfColors.primaryBlue,
                            side: const BorderSide(color: PwfColors.outline),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            final entries = feature.allDetailEntries;
                            showDialog<void>(
                              context: context,
                              builder: (ctx) => Directionality(
                                textDirection: TextDirection.rtl,
                                child: AlertDialog(
                                  title: Text(feature.displayTitle),
                                  content: SizedBox(
                                    width: 520,
                                    child: entries.isEmpty
                                        ? const Text('لا توجد خصائص متاحة لهذا العنصر.')
                                        : ListView.separated(
                                            shrinkWrap: true,
                                            itemCount: entries.length,
                                            separatorBuilder: (_, __) =>
                                                const Divider(height: 1),
                                            itemBuilder: (context, index) {
                                              final entry = entries[index];
                                              return ListTile(
                                                dense: true,
                                                contentPadding: EdgeInsets.zero,
                                                title: Text(
                                                  entry.key,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                subtitle: Text(entry.value),
                                              );
                                            },
                                          ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('إغلاق'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.notes_outlined, size: 18),
                          label: const Text('عرض كل الحقول'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PwfColors.royalRed,
                            side: const BorderSide(color: PwfColors.outline),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedFeaturePopupProps extends ConsumerWidget {
  const _SelectedFeaturePopupProps({required this.feature});

  final GisFeatureModel feature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<MapLayerAdminConfig>>(
      future: ref.read(mapLayerManagerRepositoryProvider).listLayerConfigs(),
      builder: (context, snapshot) {
        final config = _findSelectedFeatureConfig(snapshot.data, feature.layerKey);
        final enabled = config?.popupEnabled ?? true;
        if (!enabled) {
          return const _SmallInfoBox(
            text: 'تم تعطيل بطاقة التفاصيل المختصرة لهذه الطبقة من إعدادات المدير.',
          );
        }

        final entries = config?.configuredEntries(
              feature.props,
              fallbackLimit: 6,
            ) ??
            feature.previewEntries;

        if (entries.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PwfColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تفاصيل مختصرة',
                style: TextStyle(
                  color: PwfColors.royalRed,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              ...entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 112,
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            color: PwfColors.onSurface.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            color: PwfColors.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

MapLayerAdminConfig? _findSelectedFeatureConfig(
  List<MapLayerAdminConfig>? configs,
  String layerKey,
) {
  if (configs == null) return null;
  final normalized = layerKey.trim().toLowerCase();
  for (final config in configs) {
    if (config.layerKey.trim().toLowerCase() == normalized) return config;
  }
  return null;
}

class _SmallInfoBox extends StatelessWidget {
  const _SmallInfoBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: PwfColors.onSurface.withValues(alpha: 0.66),
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

// ------------------------------ UI Helpers ------------------------------

class _BasemapThumb extends StatelessWidget {
  const _BasemapThumb({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFF8FAFC),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.map_outlined, color: PwfColors.primaryBlue, size: 24),
              SizedBox(height: 6),
              Text(
                'معاينة الخريطة',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: PwfColors.primaryBlue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClusterPointMarker extends StatelessWidget {
  const _ClusterPointMarker({
    required this.count,
    required this.color,
    required this.selected,
  });

  final int count;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final label = count > 999 ? '999+' : count.toString();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? PwfColors.royalRed : Colors.white,
          width: selected ? 3 : 2.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: selected ? 0.32 : 0.22),
            blurRadius: selected ? 12 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          shape: BoxShape.circle,
        ),
        child: Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            color: PwfColors.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _BoundaryLabelChip extends StatelessWidget {
  const _BoundaryLabelChip({
    required this.label,
    required this.emphasized,
  });

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final accent = emphasized ? PwfColors.royalRed : PwfColors.primaryBlue;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent.withValues(alpha: 0.62),
            width: emphasized ? 1.25 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 7,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w900,
            fontSize: emphasized ? 12.4 : 11.1,
            height: 1.05,
          ),
        ),
      ),
    );
  }
}

class _ParcelNumberMarker extends StatelessWidget {
  const _ParcelNumberMarker({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: selected ? 0.98 : 0.90),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? PwfColors.royalRed : PwfColors.primaryBlue,
            width: selected ? 1.8 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.22 : 0.13),
              blurRadius: selected ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? PwfColors.royalRed : PwfColors.primaryBlue,
            fontWeight: FontWeight.w900,
            fontSize: selected ? 12.5 : 11.2,
            height: 1.05,
          ),
        ),
      ),
    );
  }
}

class _LabeledPointMarker extends StatelessWidget {
  const _LabeledPointMarker({
    required this.label,
    required this.color,
    required this.opacity,
    required this.selected,
    required this.icon,
    required this.markerSize,
    required this.labelTextColor,
    required this.labelHaloColor,
    required this.labelFontSize,
  });

  final String label;
  final Color color;
  final double opacity;
  final bool selected;
  final IconData icon;
  final double markerSize;
  final Color labelTextColor;
  final Color labelHaloColor;
  final double labelFontSize;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsetsDirectional.only(start: 7, end: 5),
        decoration: BoxDecoration(
          color: labelHaloColor.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? PwfColors.royalRed : color.withValues(alpha: 0.75),
            width: selected ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: selected ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: markerSize.clamp(18.0, 30.0).toDouble(),
              height: markerSize.clamp(18.0, 30.0).toDouble(),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.95 * opacity),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.4),
              ),
              child: Icon(
                icon,
                size: (markerSize * 0.45).clamp(10.0, 16.0).toDouble(),
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: labelTextColor,
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernExplorerTabBar extends StatelessWidget {
  const _ModernExplorerTabBar({
    required this.activeTab,
    required this.onChanged,
  });

  final _ModernExplorerTab activeTab;
  final ValueChanged<_ModernExplorerTab> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab({
      required _ModernExplorerTab value,
      required IconData icon,
      required String label,
    }) {
      final selected = activeTab == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? PwfColors.primaryBlue.withValues(alpha: 0.10)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? PwfColors.primaryBlue.withValues(alpha: 0.45)
                    : PwfColors.outline.withValues(alpha: 0.85),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? PwfColors.primaryBlue : PwfColors.onSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? PwfColors.primaryBlue : PwfColors.onSurface,
                    fontSize: 11.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      decoration: BoxDecoration(
        color: PwfColors.surface,
        border: Border(
          bottom: BorderSide(color: PwfColors.outline.withValues(alpha: 0.85)),
        ),
      ),
      child: Row(
        children: [
          tab(
            value: _ModernExplorerTab.layers,
            icon: Icons.layers_outlined,
            label: 'الطبقات',
          ),
          const SizedBox(width: 7),
          tab(
            value: _ModernExplorerTab.search,
            icon: Icons.search_rounded,
            label: 'البحث',
          ),
        ],
      ),
    );
  }
}

class _ModernExplorerHeader extends StatelessWidget {
  const _ModernExplorerHeader({
    required this.onClose,
    required this.defaults,
  });

  final VoidCallback onClose;
  final List<String> defaults;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
      decoration: BoxDecoration(
        color: PwfColors.surface,
        border: Border(
          bottom: BorderSide(color: PwfColors.royalRed.withValues(alpha: 0.18)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: PwfColors.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.explore_outlined,
                  color: PwfColors.primaryBlue,
                  size: 17,
                ),
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'المستكشف الحديث',
                  style: TextStyle(
                    color: PwfColors.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'إغلاق',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            defaults.isEmpty
                ? 'قائمة تشغيل الطبقات العملية الأولى للمستخدمين.'
                : "الافتراضي: ${defaults.join('، ')}",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: PwfColors.onSurface.withValues(alpha: 0.66),
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}


class _ExplorerLayerVisualOverride {
  const _ExplorerLayerVisualOverride({
    required this.strokeWidth,
    required this.strokeColor,
    required this.fillColor,
    required this.fillOpacity,
  });

  final double strokeWidth;
  final Color strokeColor;
  final Color fillColor;
  final double fillOpacity;

  _ExplorerLayerVisualOverride copyWith({
    double? strokeWidth,
    Color? strokeColor,
    Color? fillColor,
    double? fillOpacity,
  }) {
    return _ExplorerLayerVisualOverride(
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeColor: strokeColor ?? this.strokeColor,
      fillColor: fillColor ?? this.fillColor,
      fillOpacity: fillOpacity ?? this.fillOpacity,
    );
  }
}

class _ExplorerLayerMoreSlider extends StatelessWidget {
  const _ExplorerLayerMoreSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: PwfColors.onSurface.withValues(alpha: 0.72),
                  fontSize: 11.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: const TextStyle(
                color: PwfColors.primaryBlue,
                fontSize: 10.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ExplorerColorPickerRow extends StatelessWidget {
  const _ExplorerColorPickerRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  static const List<Color> _palette = [
    Color(0xFF1D4ED8),
    Color(0xFFB22222),
    Color(0xFFC9A227),
    Color(0xFF0F766E),
    Color(0xFF6B7280),
    Color(0xFF7C3AED),
    Color(0xFFEA580C),
    Color(0xFF111827),
  ];

  final String label;
  final Color value;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: PwfColors.onSurface.withValues(alpha: 0.72),
            fontSize: 11.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _palette.map((color) {
            final selected = (color.r - value.r).abs() < 0.001 &&
                (color.g - value.g).abs() < 0.001 &&
                (color.b - value.b).abs() < 0.001;
            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onChanged(color),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? PwfColors.primaryGold : Colors.white,
                    width: selected ? 3 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class _ModernExplorerAdvancedFilters extends StatelessWidget {
  const _ModernExplorerAdvancedFilters({
    required this.governorate,
    required this.governorates,
    required this.governorateLabels,
    required this.locality,
    required this.localities,
    required this.localityLabels,
    required this.featureType,
    required this.featureTypes,
    required this.loading,
    required this.error,
    required this.onGovernorateChanged,
    required this.onLocalityChanged,
    required this.onFeatureTypeChanged,
  });

  final String? governorate;
  final List<String> governorates;
  final Map<String, String> governorateLabels;
  final String? locality;
  final List<String> localities;
  final Map<String, String> localityLabels;
  final String? featureType;
  final List<String> featureTypes;
  final bool loading;
  final String? error;
  final ValueChanged<String?> onGovernorateChanged;
  final ValueChanged<String?> onLocalityChanged;
  final ValueChanged<String?> onFeatureTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: PwfColors.primaryBlue.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.tune_rounded, size: 16, color: PwfColors.primaryBlue),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'فلاتر متقدمة',
                  style: TextStyle(
                    color: PwfColors.primaryBlue,
                    fontSize: 12.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          _ModernExplorerDropdown(
            label: 'اختر المحافظات',
            value: governorate,
            values: governorates,
            labels: governorateLabels,
            allLabel: 'كل المحافظات',
            onChanged: onGovernorateChanged,
          ),
          const SizedBox(height: 6),
          _ModernExplorerDropdown(
            label: 'اختر الهيئة المحلية',
            value: locality,
            values: localities,
            labels: localityLabels,
            allLabel: 'كل الهيئات المحلية',
            onChanged: onLocalityChanged,
          ),
          const SizedBox(height: 6),
          _ModernExplorerDropdown(
            label: 'اختر الطبقة',
            value: featureType,
            values: featureTypes,
            labels: _modernExplorerFeatureTypeLabels,
            allLabel: 'كل الطبقات',
            onChanged: onFeatureTypeChanged,
          ),
          const SizedBox(height: 5),
          Text(
            loading
                ? 'جارٍ تجهيز المحافظات من gis.governorates_boundary والهيئات المحلية من gis.lgus_boundary...'
                : (error != null
                    ? 'تعذر تجهيز قوائم GIS السيادية؛ يمكن متابعة تشغيل الطبقات يدويًا.'
                    : 'مصدر المحافظات والهيئات المحلية من جداول GIS، ثم تُفلتر طبقات الوقف النقطية حسب الاختيار.'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: (error != null ? PwfColors.royalRed : PwfColors.onSurface)
                  .withValues(alpha: 0.58),
              fontSize: 9.7,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernExplorerDropdown extends StatelessWidget {
  const _ModernExplorerDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.allLabel,
    required this.onChanged,
    this.labels = const {},
  });

  static const String _allValue = '__PWF_ALL__';

  final String label;
  final String? value;
  final List<String> values;
  final String allLabel;
  final Map<String, String> labels;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = value != null && values.contains(value) ? value : null;
    final selectedLabel = effectiveValue == null
        ? allLabel
        : (labels[effectiveValue] ?? effectiveValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            color: PwfColors.onSurface.withValues(alpha: 0.62),
            fontSize: 9.6,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        DropdownButtonFormField<String>(
          value: effectiveValue ?? _allValue,
          isExpanded: true,
          menuMaxHeight: 280,
          icon: const Icon(Icons.arrow_drop_down, size: 17, color: PwfColors.onSurface),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: PwfColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: PwfColors.primaryBlue, width: 1.2),
            ),
          ),
          style: const TextStyle(
            color: PwfColors.onSurface,
            fontSize: 10.6,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
          items: [
            DropdownMenuItem<String>(
              value: _allValue,
              child: _dropdownItemText(allLabel, selected: effectiveValue == null),
            ),
            ...values.map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: _dropdownItemText(
                  labels[item] ?? item,
                  selected: effectiveValue == item,
                ),
              ),
            ),
          ],
          onChanged: (selected) {
            onChanged(selected == null || selected == _allValue ? null : selected);
          },
        ),
      ],
    );
  }

  Widget _dropdownItemText(String text, {required bool selected}) {
    return Row(
      children: [
        Icon(
          selected ? Icons.check_circle : Icons.circle_outlined,
          size: 13,
          color: selected
              ? PwfColors.primaryBlue
              : PwfColors.onSurface.withValues(alpha: 0.35),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: PwfColors.onSurface,
              fontSize: 10.6,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}


class _ModernExplorerRuntimeStatus extends StatelessWidget {
  const _ModernExplorerRuntimeStatus({
    required this.mapState,
    required this.audience,
    required this.scoped,
  });

  final MapState mapState;
  final MapToolAudience audience;
  final bool scoped;

  @override
  Widget build(BuildContext context) {
    final bboxReady = mapState.viewport != null;
    final clusterOn = mapState.zoom < 13.4;
    final denseAllowed =
        audience.canUseManagerTools && scoped && mapState.zoom >= 15.0;
    final runtime = mapState.runtimeInfo;
    final queryLayerCount = runtime.queryLayerKeys.length;
    final requestedLayerCount = runtime.requestedLayerKeys.length;
    final blockedLayerCount = runtime.blockedLayerKeys.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: PwfColors.surfaceVariant.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: PwfColors.outline.withValues(alpha: 0.92)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.speed_rounded, size: 16, color: PwfColors.royalRed),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'حالة التحميل الذكي',
                  style: TextStyle(
                    color: PwfColors.royalRed,
                    fontSize: 12.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              _ModernExplorerBadge(label: 'زوم ${mapState.zoom.toStringAsFixed(1)}'),
              _ModernExplorerBadge(label: bboxReady ? 'BBOX جاهز' : 'BBOX غير جاهز'),
              _ModernExplorerBadge(label: '$requestedLayerCount طبقة مطلوبة'),
              _ModernExplorerBadge(label: '$queryLayerCount طبقة محمّلة فعليًا'),
              _ModernExplorerBadge(label: '${runtime.featureCount} عنصر فعلي'),
              if (runtime.usingNaturalBlocksOverview)
                const _ModernExplorerBadge(label: 'Overview للأحواض'),
              if (runtime.servedFromCache)
                const _ModernExplorerBadge(label: 'Cache'),
              if (runtime.simplifyMeters > 0)
                _ModernExplorerBadge(
                  label: 'تبسيط ${runtime.simplifyMeters.toStringAsFixed(0)}م',
                ),
              if (clusterOn) const _ModernExplorerBadge(label: 'Cluster نشط'),
              _ModernExplorerBadge(
                label: denseAllowed ? 'التسوية مسموحة' : 'التسوية محمية',
              ),
              if (blockedLayerCount > 0)
                _ModernExplorerBadge(label: '$blockedLayerCount طبقة محجوبة'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            runtime.hasBlockedLayers
                ? runtime.blockedReasons.first
                : 'تُحمّل الخريطة حسب حدود الشاشة والزووم والاختيارات الحالية. الطبقات الثقيلة تبقى محمية حتى تضييق النطاق.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: PwfColors.onSurface.withValues(alpha: 0.58),
              fontSize: 9.6,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernExplorerSectionCard extends StatelessWidget {
  const _ModernExplorerSectionCard({
    required this.section,
    required this.mapState,
    required this.layerCounts,
    required this.showBaseMap,
    required this.resolveLayer,
    required this.gateForSpec,
    required this.onChanged,
    required this.onMore,
  });

  final _ModernExplorerSectionSpec section;
  final MapState mapState;
  final Map<String, int> layerCounts;
  final bool showBaseMap;
  final GisLayerModel? Function(_ModernExplorerLayerSpec spec) resolveLayer;
  final _ModernExplorerLayerGate Function(_ModernExplorerLayerSpec spec) gateForSpec;
  final void Function(_ModernExplorerLayerSpec spec, bool active) onChanged;
  final ValueChanged<GisLayerModel> onMore;

  @override
  Widget build(BuildContext context) {
    final entries = section.items.asMap().entries.toList(growable: false);
    final displayEntries = section.title.contains('الطبقات الأساسية')
        ? entries.reversed.toList(growable: false)
        : entries;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(6, 0, 6, 7),
          leading: const Icon(Icons.layers_outlined, color: PwfColors.royalRed, size: 18),
          title: Text(
            section.title,
            style: const TextStyle(
              color: PwfColors.onSurface,
              fontSize: 12.4,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            section.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: PwfColors.onSurface.withValues(alpha: 0.58),
              fontSize: 10.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            ...displayEntries.map((entry) {
              final index = entry.key;
              final spec = entry.value;
              final layer = resolveLayer(spec);
              final catalogAvailable = spec.isBaseMap || layer != null;
              final gate = gateForSpec(spec);
              final available = catalogAvailable && gate.allowed;
              final active = available &&
                  (spec.isBaseMap
                      ? showBaseMap
                      : layer != null && mapState.activeLayers.contains(layer.key));
              return _ModernExplorerLayerTile(
                spec: spec,
                layerKey: layer?.key,
                featureCount: layer == null ? null : layerCounts[layer.key],
                orderLabel: 'ترتيب ${index + 1} من الأسفل',
                active: active,
                available: available,
                unavailableReason: !catalogAvailable
                    ? 'غير متاحة من كتالوج الطبقات الحالي'
                    : gate.reason,
                onChanged: available ? (value) => onChanged(spec, value) : null,
                onMore: available && layer != null ? () => onMore(layer) : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ModernExplorerLayerTile extends StatelessWidget {
  const _ModernExplorerLayerTile({
    required this.spec,
    required this.layerKey,
    required this.featureCount,
    required this.orderLabel,
    required this.active,
    required this.available,
    required this.unavailableReason,
    required this.onChanged,
    required this.onMore,
  });

  final _ModernExplorerLayerSpec spec;
  final String? layerKey;
  final int? featureCount;
  final String orderLabel;
  final bool active;
  final bool available;
  final String? unavailableReason;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final color = available
        ? (active ? PwfColors.primaryBlue : PwfColors.onSurface)
        : PwfColors.onSurface.withValues(alpha: 0.34);
    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: active ? PwfColors.primaryBlue.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? PwfColors.primaryGold.withValues(alpha: 0.48)
              : PwfColors.outline.withValues(alpha: 0.88),
        ),
      ),
      child: Row(
        children: [
          Icon(spec.icon, size: 17, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spec.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 11.4,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (spec.defaultOn)
                      const _ModernExplorerBadge(label: 'افتراضي'),
                    if (spec.managerOnly)
                      const _ModernExplorerBadge(label: 'مدير'),
                    if (spec.minZoom != null)
                      _ModernExplorerBadge(label: 'زوم ${spec.minZoom!.toStringAsFixed(0)}'),
                    if (active && featureCount != null)
                      _ModernExplorerBadge(label: '$featureCount'),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  available
                      ? (spec.showLabelHint
                          ? '$orderLabel • ${spec.subtitle} • ${layerKey ?? 'الخلفية'}'
                          : '$orderLabel • ${spec.subtitle}')
                      : (unavailableReason ?? 'غير متاحة حاليًا'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: PwfColors.onSurface.withValues(alpha: available ? 0.58 : 0.36),
                    fontSize: 9.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: available ? onMore : null,
            icon: const Icon(Icons.more_horiz_rounded, size: 14),
            label: const Text('المزيد'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              minimumSize: const Size(0, 26),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 9.4, fontWeight: FontWeight.w900),
              foregroundColor: PwfColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 3),
          Transform.scale(
            scale: 0.78,
            child: Switch.adaptive(
              value: active,
              activeThumbColor: PwfColors.primaryGold,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernExplorerBadge extends StatelessWidget {
  const _ModernExplorerBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: PwfColors.primaryGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: PwfColors.primaryGold,
          fontSize: 8.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ModernExplorerActions extends StatelessWidget {
  const _ModernExplorerActions({
    required this.onTurnOffAll,
    required this.onDefaults,
  });

  final Future<void> Function() onTurnOffAll;
  final Future<void> Function() onDefaults;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: PwfColors.outline.withValues(alpha: 0.95))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () { onTurnOffAll(); },
              icon: const Icon(Icons.visibility_off_outlined, size: 15),
              label: const Text('إيقاف الجميع'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                textStyle: const TextStyle(fontSize: 10.8, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () { onDefaults(); },
              icon: const Icon(Icons.restart_alt_rounded, size: 15),
              label: const Text('تشغيل الافتراضي'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PwfColors.royalRed,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                textStyle: const TextStyle(fontSize: 10.8, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderModernExplorerButton extends StatelessWidget {
  const _HeaderModernExplorerButton({
    required this.visible,
    required this.onTap,
  });

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: visible ? 'إغلاق المستكشف الحديث' : 'فتح المستكشف الحديث',
      child: Material(
        color: visible ? PwfColors.primaryBlue : Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: visible
                    ? PwfColors.primaryBlue
                    : PwfColors.outline.withValues(alpha: 0.95),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.explore_outlined,
                  size: 18,
                  color: visible ? Colors.white : PwfColors.primaryBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  'المستكشف الحديث',
                  style: TextStyle(
                    color: visible ? Colors.white : PwfColors.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderToolboxButton extends StatelessWidget {
  const _HeaderToolboxButton({
    required this.ref,
    required this.visible,
    required this.onTap,
  });

  final WidgetRef ref;
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: visible ? 'إغلاق صندوق الأدوات' : 'فتح صندوق الأدوات',
      child: Material(
        color: visible ? PwfColors.royalRed : Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: visible
                    ? PwfColors.royalRed
                    : PwfColors.outline.withValues(alpha: 0.95),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  visible ? Icons.close_rounded : Icons.tune_rounded,
                  size: 19,
                  color: visible ? Colors.white : PwfColors.royalRed,
                ),
                const SizedBox(width: 7),
                Text(
                  visible ? 'إغلاق' : 'الأدوات',
                  style: TextStyle(
                    color: visible ? Colors.white : PwfColors.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSearchBox extends StatelessWidget {
  const _HeaderSearchBox({
    required this.controller,
    required this.loading,
    required this.onChanged,
    required this.onClear,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onChanged;
  final VoidCallback onClear;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: PwfColors.outline),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            const Icon(Icons.search, size: 18, color: PwfColors.royalRed),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onChanged: (_) => onChanged(),
                onSubmitted: (_) => onSearch(),
                decoration: const InputDecoration(
                  hintText: 'ابحث في الطبقات المفتوحة...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
            if (controller.text.isNotEmpty)
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 16, color: PwfColors.onSurface),
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4, start: 2),
              child: SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: loading ? null : onSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PwfColors.royalRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 30),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('بحث', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderWorkspaceStrip extends StatelessWidget {
  const _HeaderWorkspaceStrip({
    required this.mapState,
    required this.toolboxVisible,
    required this.selectionLabel,
    required this.onFocusPalestine,
    required this.onClearSelection,
  });

  final MapState mapState;
  final bool toolboxVisible;
  final String? selectionLabel;
  final VoidCallback onFocusPalestine;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectionLabel != null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HeaderChip(
            icon: Icons.map_outlined,
            label: 'الخريطة الحديثة',
            color: PwfColors.primaryBlue,
          ),
          const SizedBox(width: 6),
          _HeaderChip(
            icon: Icons.layers_outlined,
            label: '${mapState.activeLayers.length} مفعلة',
            color: PwfColors.success,
          ),
          const SizedBox(width: 6),
          _HeaderChip(
            icon: toolboxVisible ? Icons.tune : Icons.tune_outlined,
            label: toolboxVisible ? 'الأدوات مفتوحة' : 'الأدوات مغلقة',
            color: PwfColors.royalRed,
          ),
          const SizedBox(width: 6),
          _HeaderChip(
            icon: Icons.public,
            label: 'فلسطين',
            color: PwfColors.primaryGold,
            onTap: onFocusPalestine,
          ),
          if (hasSelection) ...[
            const SizedBox(width: 6),
            _HeaderChip(
              icon: Icons.close_rounded,
              label: selectionLabel!,
              color: PwfColors.royalRed,
              onTap: onClearSelection,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: chip,
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 42,
          height: 42,
        ),
      ),
    );

    // Paint icon over the tappable surface (keeps ripple clean)
    final stack = Stack(
      alignment: Alignment.center,
      children: [
        child,
        Icon(icon, size: 20, color: const Color(0xFFB22222)),
      ],
    );

    if (tooltip == null || tooltip!.trim().isEmpty) return stack;
    return Tooltip(message: tooltip!, child: stack);
  }
}

class _CompassButton extends StatelessWidget {
  const _CompassButton({
    required this.rotationRad,
    required this.onReset,
  });

  /// Map rotation in radians (flutter_map v6 camera.rotation)
  final double rotationRad;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    // Needle rotates opposite to map rotation to keep pointing north.
    final needleAngle = -rotationRad;

    return Tooltip(
      message: 'إعادة الشمال',
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onReset,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ring
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFB22222).withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                  ),
                ),
                // Needle (north)
                Transform.rotate(
                  angle: needleAngle,
                  child: const Icon(
                    Icons.navigation,
                    size: 20,
                    color: Color(0xFFB22222),
                  ),
                ),
                // Center dot
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB22222),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _ReviewMapCommandBanner extends StatelessWidget {
  const _ReviewMapCommandBanner({
    required this.command,
    required this.onFocus,
    required this.onBackToReview,
  });

  final PwfExplorerReviewMapCommand command;
  final VoidCallback onFocus;
  final VoidCallback onBackToReview;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: Card(
        elevation: 8,
        color: Colors.white.withValues(alpha: 0.96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.manage_search_outlined, color: PwfColors.royalRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تشغيل مراجعة داخل خريطة المستكشف',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: PwfColors.primaryBlue,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                command.labelAr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'record=${command.recordId.isEmpty ? 'n/a' : command.recordId}; command=${command.cameraCommand}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                command.governanceLine,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF0F766E),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onFocus,
                    icon: const Icon(Icons.center_focus_strong_outlined),
                    label: const Text('تركيز الخريطة'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onBackToReview,
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('عودة للمراجعة'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewEvidenceMarker extends StatelessWidget {
  const _ReviewEvidenceMarker({
    required this.label,
    required this.icon,
    required this.tone,
  });

  final String label;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tone, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: tone),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: tone,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
