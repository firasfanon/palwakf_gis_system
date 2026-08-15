import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/colors.dart';

class AdminHistoryMapPage extends StatefulWidget {
  final Map<String, String> query;
  const AdminHistoryMapPage({super.key, required this.query});

  @override
  State<AdminHistoryMapPage> createState() => _AdminHistoryMapPageState();
}

class _AdminHistoryMapPageState extends State<AdminHistoryMapPage> {
  final MapController _mapController = MapController();
  Future<_HistoryRuntime>? _runtimeFuture;
  bool _didFitBounds = false;
  String? _selectedLevelKey;
  String? _selectedSourceId;
  String? _hoveredSourceId;

  @override
  void initState() {
    super.initState();
    _runtimeFuture = _loadRuntime();
  }

  @override
  void didUpdateWidget(covariant AdminHistoryMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query.toString() != widget.query.toString()) {
      _didFitBounds = false;
      _selectedLevelKey = null;
      _selectedSourceId = null;
      _hoveredSourceId = null;
      _runtimeFuture = _loadRuntime();
    }
  }

  int? _extractFirstInt(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final match = RegExp(r'(\d+)').firstMatch(value);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  int? get _periodNo {
    return _extractFirstInt(widget.query['period_no']) ??
        _extractFirstInt(widget.query['period_id']) ??
        _extractFirstInt(widget.query['period']) ??
        _extractFirstInt(widget.query['hist_period_no']) ??
        (widget.query['table'] == 'historical_periods' ? _extractFirstInt(widget.query['id']) : null);
  }

  String? _asCleanString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String _overlayArabicLevel(String? level) {
    switch ((level ?? '').toLowerCase().trim()) {
      case 'welaya':
        return 'ولاية';
      case 'sonjoq':
        return 'سنجق';
      case 'lewa':
        return 'لواء';
      case 'kada':
      case 'qada':
        return 'قضاء';
      case 'westbank_gaza':
        return 'الضفة/غزة';
      case 'governorate':
        return 'محافظة';
      case 'community':
        return 'تجمع';
      case 'lgu':
        return 'هيئة محلية';
      default:
        return 'وحدة';
    }
  }

  String _familyArabicLabel(String? familyKey) {
    switch ((familyKey ?? '').trim()) {
      case 'descriptive':
        return 'وصفية';
      case 'legacy':
        return 'تاريخية تشغيلية';
      case 'modern':
        return 'حديثة تشغيلية';
      default:
        return familyKey?.trim().isNotEmpty == true ? familyKey! : '—';
    }
  }

  String _chainArabicLabel(String? chainKey) {
    switch ((chainKey ?? '').trim()) {
      case 'legacy_chain':
        return 'السلسلة التاريخية القديمة';
      case 'modern_wbg_chain':
        return 'السلسلة الحديثة';
      default:
        return chainKey?.trim().isNotEmpty == true ? chainKey! : '—';
    }
  }

  String _periodKindArabicLabel(String? kind) {
    switch ((kind ?? '').trim()) {
      case 'descriptive':
        return 'وصفية';
      case 'reference':
        return 'مرجعية';
      case 'drawable':
        return 'قابلة للرسم';
      default:
        return '—';
    }
  }

  String _modernFilterArabicLabel(String? filterKey) {
    switch ((filterKey ?? '').trim()) {
      case 'westbank_only':
        return 'الضفة الغربية';
      case 'gaza_only':
        return 'قطاع غزة';
      case 'westbank_and_gaza':
        return 'الضفة الغربية وقطاع غزة';
      case 'all_modern':
        return 'كامل النطاق الحديث';
      default:
        return '—';
    }
  }

  bool _isNumericLikeLabel(String value) {
    return RegExp(r'^[0-9٠-٩\-\s_./()]+$').hasMatch(value.trim());
  }

  Map<String, dynamic> _rowProps(Map<String, dynamic> row) {
    final props = <String, dynamic>{...row};
    final nested = row['properties'];
    if (nested is Map) {
      props.addAll(nested.cast<String, dynamic>());
    }
    return props;
  }

  String _overlayLabelText(Map<String, dynamic> row) {
    final props = _rowProps(row);
    const preferredKeys = <String>[
      'label_ar',
      'display_name',
      'name_ar',
      'community_name_ar',
      'locality_name_ar',
      'municipality_name_ar',
      'admin_name_ar',
      'arabic_name',
      'title_ar',
      'label_en',
      'name_en',
      'community_name',
      'locality_name',
      'municipality_name',
      'admin_name',
      'name',
      'title',
      'label',
    ];

    for (final key in preferredKeys) {
      final value = _asCleanString(props[key]);
      if (value == null) continue;
      if (_isNumericLikeLabel(value)) continue;
      return value;
    }

    final level = _overlayArabicLevel(_asCleanString(props['level_key'] ?? props['level']));
    final adminNo = _asCleanString(props['admin_no'] ?? props['source_id']);
    return adminNo != null ? '$level $adminNo' : level;
  }

  Map<String, dynamic>? _readGeomJson(Map<String, dynamic> row) {
    final value = row['geom_json'];
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  String _rowKey(Map<String, dynamic> row) {
    final props = _rowProps(row);
    final period = _asCleanString(props['period_no'] ?? props['period_id'] ?? props['period']) ?? '';
    final sourceTable = _asCleanString(props['source_table']) ?? '';
    final sourceId = _asCleanString(props['source_id'] ?? props['id']) ?? '';
    if (sourceTable.isNotEmpty && sourceId.isNotEmpty) {
      return '$period|$sourceTable|$sourceId';
    }
    return '$period|${jsonEncode(row['geom_json']).hashCode}';
  }

  Future<_HistoryPeriodMeta?> _loadPeriodMeta(
    SupabaseClient client,
    int periodNo,
  ) async {
    final raw = await client.rpc(
      'rpc_historical_period_meta_v1',
      params: {'p_period_no': periodNo},
    );

    final rows = (raw as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);

    if (rows.isEmpty) return null;

    final row = rows.first;
    return _HistoryPeriodMeta(
      periodNo: (row['period_no'] as num?)?.toInt() ?? periodNo,
      periodLabelAr: _asCleanString(row['period_label_ar']) ?? '—',
      familyKey: _asCleanString(row['family_key']),
      familyLabelAr: _asCleanString(row['family_label_ar']) ?? _familyArabicLabel(_asCleanString(row['family_key'])),
      chainKey: _asCleanString(row['chain_key']),
      chainLabelAr: _asCleanString(row['chain_label_ar']) ?? _chainArabicLabel(_asCleanString(row['chain_key'])),
      defaultLevelKey: _asCleanString(row['default_level_key']),
      defaultLevelLabelAr: _overlayArabicLevel(_asCleanString(row['default_level_key'])),
      scopeLabelAr: _asCleanString(row['scope_label_ar']),
      modernFilterKey: _asCleanString(row['modern_filter_key']),
      modernFilterLabelAr: _modernFilterArabicLabel(_asCleanString(row['modern_filter_key'])),
    );
  }

  Future<List<_HistoryLevelOption>> _loadAvailableLevels(
    SupabaseClient client,
    int periodNo,
  ) async {
    final raw = await client.rpc(
      'rpc_historical_period_levels_v1',
      params: {'p_period_no': periodNo},
    );

    final rows = (raw as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);

    return rows
        .map((row) => _HistoryLevelOption(
              levelKey: (row['level_key'] ?? '').toString(),
              labelAr: _overlayArabicLevel(row['level_key']?.toString()),
              levelOrder: (row['level_order'] as num?)?.toInt() ?? 999,
              isDefault: row['is_default'] == true,
              rowsCount: (row['rows_count'] as num?)?.toInt() ?? 0,
            ))
        .where((e) => e.levelKey.isNotEmpty)
        .toList()
      ..sort((a, b) => a.levelOrder.compareTo(b.levelOrder));
  }

  Future<_HistoryRuntime> _loadRuntime() async {
    final periodNo = _periodNo;
    if (periodNo == null) {
      return _HistoryRuntime.empty(message: 'لم يتم تمرير رقم الفترة إلى الخريطة.');
    }

    final client = Supabase.instance.client;
    _HistoryPeriodMeta? periodMeta;
    List<_HistoryLevelOption> availableLevels = const [];

    try {
      periodMeta = await _loadPeriodMeta(client, periodNo);
    } catch (_) {
      periodMeta = null;
    }

    try {
      availableLevels = await _loadAvailableLevels(client, periodNo);
    } catch (_) {
      availableLevels = const [];
    }

    String? resolvedLevelKey = _selectedLevelKey;
    if (availableLevels.isNotEmpty) {
      final levelKeys = availableLevels.map((e) => e.levelKey).toSet();
      if (resolvedLevelKey == null || !levelKeys.contains(resolvedLevelKey)) {
        resolvedLevelKey = availableLevels.firstWhere(
          (e) => e.isDefault,
          orElse: () => availableLevels.first,
        ).levelKey;
      }
    }

    try {
      final params = <String, dynamic>{'p_period_no': periodNo};
      if (resolvedLevelKey != null && resolvedLevelKey.isNotEmpty) {
        params['p_level_key'] = resolvedLevelKey;
      }

      final raw = await client.rpc('rpc_historical_period_overlay_v4', params: params);
      final rows = (raw as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(growable: false);

      if (rows.isEmpty) {
        return _HistoryRuntime(
          periodNo: periodNo,
          periodMeta: periodMeta,
          selectedLevelKey: resolvedLevelKey,
          availableLevels: availableLevels,
          bundle: _OverlayBundle.empty(
            message: availableLevels.isEmpty
                ? 'لا توجد مستويات مكانية متاحة لهذه الفترة حاليًا.'
                : 'لا توجد عناصر هندسية للمستوى المختار في هذه الفترة.',
            periodNo: periodNo,
          ),
        );
      }

      final features = <_RenderedFeature>[];
      final boundsPoints = <LatLng>[];
      final levels = <String>{};
      final sampleNames = <String>[];
      final seen = <String>{};

      for (final row in rows) {
        final key = _rowKey(row);
        if (!seen.add(key)) continue;

        final level = _asCleanString(row['level_key'] ?? row['level']);
        if (level != null) levels.add(level);

        final label = _overlayLabelText(row);
        if (label.isNotEmpty && sampleNames.length < 8) {
          sampleNames.add(label);
        }

        final geom = _readGeomJson(row);
        if (geom == null) continue;

        final styleMap = row['style_json'] is Map
            ? Map<String, dynamic>.from(row['style_json'] as Map)
            : row['style_json'] is String && (row['style_json'] as String).trim().isNotEmpty
                ? Map<String, dynamic>.from(jsonDecode(row['style_json'] as String) as Map)
                : const <String, dynamic>{};

        final parsed = _GeoOverlayParser.fromGeoJson(
          geom,
          sourceId: _asCleanString(row['source_id']) ?? key,
          label: label,
          levelKey: level,
          baseStyle: _ResolvedVisualStyle.fromJson(styleMap),
        );

        features.add(parsed);
        boundsPoints.addAll(parsed.boundsPoints);
      }

      final bounds = boundsPoints.isEmpty ? null : LatLngBounds.fromPoints(boundsPoints);
      return _HistoryRuntime(
        periodNo: periodNo,
        periodMeta: periodMeta,
        selectedLevelKey: resolvedLevelKey,
        availableLevels: availableLevels,
        bundle: _OverlayBundle(
          periodNo: periodNo,
          rowCount: rows.length,
          features: features,
          levels: levels.toList()..sort(),
          sampleNames: sampleNames,
          bounds: bounds,
          message: features.isEmpty ? 'لا توجد عناصر مرسومة.' : null,
        ),
      );
    } catch (e) {
      return _HistoryRuntime(
        periodNo: periodNo,
        periodMeta: periodMeta,
        selectedLevelKey: resolvedLevelKey,
        availableLevels: availableLevels,
        bundle: _OverlayBundle.empty(
          message: 'تعذر تحميل overlay للفترة: $e',
          periodNo: periodNo,
        ),
      );
    }
  }

  void _fitToBundle(_OverlayBundle bundle) {
    if (_didFitBounds) return;
    final bounds = bundle.bounds;
    if (bounds == null || !mounted) return;
    scheduleMicrotask(() {
      if (!mounted) return;
      try {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(32),
          ),
        );
        _didFitBounds = true;
      } catch (_) {}
    });
  }

  void _changeLevel(String? levelKey) {
    if (levelKey == null || levelKey == _selectedLevelKey) return;
    setState(() {
      _selectedLevelKey = levelKey;
      _selectedSourceId = null;
      _hoveredSourceId = null;
      _didFitBounds = false;
      _runtimeFuture = _loadRuntime();
    });
  }

  void _handleMapTap(LatLng point, _OverlayBundle bundle) {
    final hit = _hitTestFeature(point, bundle.features);
    if (!mounted) return;
    setState(() {
      _selectedSourceId = hit == null ? null : (_selectedSourceId == hit.sourceId ? null : hit.sourceId);
    });
  }

  void _handleMapHover(LatLng point, _OverlayBundle bundle) {
    final hit = _hitTestFeature(point, bundle.features);
    final next = hit?.sourceId;
    if (_hoveredSourceId == next || !mounted) return;
    setState(() => _hoveredSourceId = next);
  }

  _RenderedFeature? _hitTestFeature(LatLng point, List<_RenderedFeature> features) {
    for (final feature in features.reversed) {
      for (final shape in feature.polygonShapes) {
        if (_pointInPolygon(point, shape)) return feature;
      }
    }
    return null;
  }

  bool _pointInPolygon(LatLng point, _PolygonShape shape) {
    if (!_pointInRing(point, shape.outer)) return false;
    for (final hole in shape.holes) {
      if (_pointInRing(point, hole)) return false;
    }
    return true;
  }

  bool _pointInRing(LatLng point, List<LatLng> ring) {
    if (ring.length < 3) return false;
    var inside = false;
    final x = point.longitude;
    final y = point.latitude;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i].longitude;
      final yi = ring[i].latitude;
      final xj = ring[j].longitude;
      final yj = ring[j].latitude;
      final intersects = ((yi > y) != (yj > y)) &&
          (x < ((xj - xi) * (y - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) + xi));
      if (intersects) inside = !inside;
    }
    return inside;
  }

  List<Polygon> _buildPolygons(_OverlayBundle bundle) {
    final polygons = <Polygon>[];
    for (final feature in bundle.features) {
      final style = feature.effectiveStyle(
        isHovered: _hoveredSourceId == feature.sourceId,
        isSelected: _selectedSourceId == feature.sourceId,
      );
      if (!style.visible) continue;
      for (final shape in feature.polygonShapes) {
        polygons.add(
          Polygon(
            points: shape.outer,
            holePointsList: shape.holes,
            color: style.fillColor.withValues(alpha: style.fillOpacity),
            borderColor: style.strokeColor.withValues(alpha: style.strokeOpacity),
            borderStrokeWidth: style.strokeWidth,
          ),
        );
      }
    }
    return polygons;
  }

  List<Polyline> _buildPolylines(_OverlayBundle bundle) {
    final lines = <Polyline>[];
    for (final feature in bundle.features) {
      final style = feature.effectiveStyle(
        isHovered: _hoveredSourceId == feature.sourceId,
        isSelected: _selectedSourceId == feature.sourceId,
      );
      if (!style.visible) continue;
      for (final line in feature.lineShapes) {
        lines.add(
          Polyline(
            points: line,
            color: style.strokeColor.withValues(alpha: style.strokeOpacity),
            strokeWidth: style.strokeWidth,
          ),
        );
      }
    }
    return lines;
  }

  List<Marker> _buildMarkers(_OverlayBundle bundle) {
    final markers = <Marker>[];
    for (final feature in bundle.features) {
      final point = feature.labelPoint;
      if (point == null) continue;
      final style = feature.effectiveStyle(
        isHovered: _hoveredSourceId == feature.sourceId,
        isSelected: _selectedSourceId == feature.sourceId,
      );
      if (!style.showLabel) continue;
      markers.add(
        Marker(
          point: point,
          width: 180,
          height: 34,
          child: IgnorePointer(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: _selectedSourceId == feature.sourceId ? 0.74 : 0.62),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: style.strokeColor.withValues(alpha: 0.8),
                  width: _selectedSourceId == feature.sourceId ? 1.6 : 1.0,
                ),
              ),
              child: Text(
                feature.label.isEmpty ? 'عنصر تاريخي' : feature.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: style.labelColor,
                  fontSize: style.labelSize,
                  fontWeight: style.labelWeight,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  Widget _buildSidebar(AsyncSnapshot<_HistoryRuntime> snapshot) {
    final runtime = snapshot.data ?? _HistoryRuntime.empty(periodNo: _periodNo);
    final bundle = runtime.bundle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'العودة',
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'لوحة الخريطة التاريخية',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PanelCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          runtime.periodMeta?.periodLabelAr ?? 'الفترة التاريخية',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'المرجع السيادي', value: 'hist.period_registry'),
                        _InfoRow(label: 'رقم الفترة', value: runtime.periodNo?.toString() ?? '—'),
                        _InfoRow(label: 'العائلة التاريخية', value: runtime.periodMeta?.familyLabelAr ?? '—'),
                        _InfoRow(label: 'السلسلة الإدارية', value: runtime.periodMeta?.chainLabelAr ?? '—'),
                        _InfoRow(label: 'النطاق المرحلي', value: runtime.periodMeta?.scopeLabelAr ?? runtime.periodMeta?.modernFilterLabelAr ?? '—'),
                        _InfoRow(label: 'المستوى الافتراضي', value: runtime.periodMeta?.defaultLevelLabelAr ?? '—'),
                        _InfoRow(label: 'المستوى النشط', value: runtime.activeLevelLabel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PanelCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'المستوى الإداري',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const _InlineStatus(label: 'جارٍ تحميل المستويات المتاحة...')
                        else if (runtime.availableLevels.isEmpty)
                          Text(
                            'لا توجد مستويات مكانية متاحة لهذه الفترة حاليًا.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.78), height: 1.6),
                          )
                        else ...[
                          DropdownButtonFormField<String>(
                            value: runtime.selectedLevelKey,
                            dropdownColor: const Color(0xFF111827),
                            decoration: InputDecoration(
                              labelText: 'المستوى النشط',
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.04),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: PwfColors.gold),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            items: runtime.availableLevels
                                .map(
                                  (level) => DropdownMenuItem<String>(
                                    value: level.levelKey,
                                    child: Text(
                                      '${level.labelAr} (${level.rowsCount})${level.isDefault ? ' • افتراضي' : ''}',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _changeLevel,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'المستويات المتاحة فعليًا: ${runtime.availableLevels.map((e) => '${e.labelAr} (${e.rowsCount})').join(' • ')}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.6),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PanelCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'التراكب المكاني المخصص',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const _InlineStatus(label: 'جارٍ تحميل الطبقة المخصصة...')
                        else ...[
                          _InfoRow(label: 'عدد الصفوف المرجعة', value: '${bundle.rowCount}'),
                          _InfoRow(label: 'عدد العناصر الفريدة', value: '${bundle.features.length}'),
                          _InfoRow(label: 'الأشكال المرسومة', value: '${bundle.polygonCount + bundle.polylineCount}'),
                          _InfoRow(label: 'الملصقات', value: '${bundle.markerCount}'),
                          _InfoRow(label: 'أمثلة من العناصر/الأسماء', value: bundle.sampleNames.isEmpty ? '—' : bundle.sampleNames.join(' ، ')),
                          if (bundle.message != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Text(
                                bundle.message!,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.82), height: 1.6),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PanelCard(
                    child: Text(
                      'تستهلك هذه الصفحة الآن public.rpc_historical_period_meta_v1 و public.rpc_historical_period_levels_v1 و public.rpc_historical_period_overlay_v4. كما يتم تطبيق style_json مباشرة على المضلعات والملصقات، مع hit-testing مباشر على جسم المضلع للتحديد والـ hover.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.go('/map'),
          icon: const Icon(Icons.open_in_new),
          label: const Text('فتح الخريطة العامة'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 360,
                child: FutureBuilder<_HistoryRuntime>(
                  future: _runtimeFuture,
                  builder: (context, snapshot) => _buildSidebar(snapshot),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FutureBuilder<_HistoryRuntime>(
                  future: _runtimeFuture,
                  builder: (context, snapshot) {
                    final runtime = snapshot.data ?? _HistoryRuntime.empty(periodNo: _periodNo);
                    final bundle = runtime.bundle;
                    _fitToBundle(bundle);
                    final polygons = _buildPolygons(bundle);
                    final polylines = _buildPolylines(bundle);
                    final markers = _buildMarkers(bundle);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: const LatLng(31.95, 35.2),
                              initialZoom: 7.9,
                              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                              onTap: (_, point) => _handleMapTap(point, bundle),
                              onPointerHover: (event, point) => _handleMapHover(point, bundle),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                                userAgentPackageName: 'palwakf.kimi',
                              ),
                              Opacity(
                                opacity: 0.65,
                                child: TileLayer(
                                  urlTemplate: 'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                                  userAgentPackageName: 'palwakf.kimi',
                                ),
                              ),
                              if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
                              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                              if (markers.isNotEmpty) MarkerLayer(markers: markers),
                            ],
                          ),
                          Positioned(
                            left: 16,
                            top: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.56),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                'الفترة: ${bundle.periodNo ?? _periodNo ?? '—'} • Shapes: ${bundle.polygonCount + bundle.polylineCount} • Labels: ${bundle.markerCount}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryPeriodMeta {
  final int periodNo;
  final String periodLabelAr;
  final String? familyKey;
  final String familyLabelAr;
  final String? chainKey;
  final String chainLabelAr;
  final String? defaultLevelKey;
  final String defaultLevelLabelAr;
  final String? scopeLabelAr;
  final String? modernFilterKey;
  final String modernFilterLabelAr;

  const _HistoryPeriodMeta({
    required this.periodNo,
    required this.periodLabelAr,
    required this.familyKey,
    required this.familyLabelAr,
    required this.chainKey,
    required this.chainLabelAr,
    required this.defaultLevelKey,
    required this.defaultLevelLabelAr,
    required this.scopeLabelAr,
    required this.modernFilterKey,
    required this.modernFilterLabelAr,
  });
}

class _HistoryLevelOption {
  final String levelKey;
  final String labelAr;
  final int levelOrder;
  final bool isDefault;
  final int rowsCount;

  const _HistoryLevelOption({
    required this.levelKey,
    required this.labelAr,
    required this.levelOrder,
    required this.isDefault,
    required this.rowsCount,
  });
}

class _HistoryRuntime {
  final int? periodNo;
  final _HistoryPeriodMeta? periodMeta;
  final String? selectedLevelKey;
  final List<_HistoryLevelOption> availableLevels;
  final _OverlayBundle bundle;

  const _HistoryRuntime({
    required this.periodNo,
    required this.periodMeta,
    required this.selectedLevelKey,
    required this.availableLevels,
    required this.bundle,
  });

  _HistoryRuntime.empty({String? message, this.periodNo})
      : periodMeta = null,
        selectedLevelKey = null,
        availableLevels = const [],
        bundle = _OverlayBundle.empty(message: message, periodNo: periodNo);

  String get activeLevelLabel {
    String? levelKey = selectedLevelKey;
    if (levelKey == null && bundle.levels.isNotEmpty) {
      levelKey = bundle.levels.first;
    }
    if (levelKey == null) return '—';
    for (final level in availableLevels) {
      if (level.levelKey == levelKey) return level.labelAr;
    }
    return _HistoryRuntime._fallbackLevelLabel(levelKey);
  }

  static String _fallbackLevelLabel(String levelKey) {
    switch (levelKey) {
      case 'welaya':
        return 'ولاية';
      case 'sonjoq':
        return 'سنجق';
      case 'lewa':
        return 'لواء';
      case 'kada':
      case 'qada':
        return 'قضاء';
      case 'westbank_gaza':
        return 'الضفة/غزة';
      case 'governorate':
        return 'محافظة';
      case 'community':
        return 'تجمع';
      case 'lgu':
        return 'هيئة محلية';
      default:
        return levelKey;
    }
  }
}

class _OverlayBundle {
  final int? periodNo;
  final int rowCount;
  final List<_RenderedFeature> features;
  final List<String> levels;
  final List<String> sampleNames;
  final LatLngBounds? bounds;
  final String? message;

  const _OverlayBundle({
    required this.periodNo,
    required this.rowCount,
    required this.features,
    required this.levels,
    required this.sampleNames,
    required this.bounds,
    required this.message,
  });

  const _OverlayBundle.empty({this.message, this.periodNo})
      : rowCount = 0,
        features = const [],
        levels = const [],
        sampleNames = const [],
        bounds = null;

  int get polygonCount => features.fold<int>(0, (sum, f) => sum + f.polygonShapes.length);
  int get polylineCount => features.fold<int>(0, (sum, f) => sum + f.lineShapes.length);
  int get markerCount => features.where((f) => f.labelPoint != null && f.baseStyle.showLabel).length;
}

class _RenderedFeature {
  final String sourceId;
  final String label;
  final String? levelKey;
  final List<_PolygonShape> polygonShapes;
  final List<List<LatLng>> lineShapes;
  final LatLng? labelPoint;
  final List<LatLng> boundsPoints;
  final _ResolvedVisualStyle baseStyle;

  const _RenderedFeature({
    required this.sourceId,
    required this.label,
    required this.levelKey,
    required this.polygonShapes,
    required this.lineShapes,
    required this.labelPoint,
    required this.boundsPoints,
    required this.baseStyle,
  });

  _ResolvedVisualStyle effectiveStyle({required bool isHovered, required bool isSelected}) {
    var style = baseStyle;
    if (isHovered) style = style.merge(baseStyle.hoverState);
    if (isSelected) style = style.merge(baseStyle.selectedState);
    return style;
  }
}

class _PolygonShape {
  final List<LatLng> outer;
  final List<List<LatLng>> holes;

  const _PolygonShape({required this.outer, required this.holes});
}

class _GeoOverlayParser {
  static _RenderedFeature fromGeoJson(
    Map<String, dynamic> geom, {
    required String sourceId,
    required String label,
    required String? levelKey,
    required _ResolvedVisualStyle baseStyle,
  }) {
    final polygonShapes = <_PolygonShape>[];
    final lineShapes = <List<LatLng>>[];
    final boundsPoints = <LatLng>[];
    LatLng? labelPoint;

    final type = (geom['type'] ?? '').toString();
    final coordinates = geom['coordinates'];

    switch (type) {
      case 'Polygon':
        final rings = _parsePolygonRings(coordinates);
        if (rings.isNotEmpty) {
          polygonShapes.add(_PolygonShape(outer: rings.first, holes: rings.length > 1 ? rings.sublist(1) : const []));
          for (final ring in rings) {
            boundsPoints.addAll(ring);
          }
          labelPoint = _centroid(rings.first);
        }
        break;
      case 'MultiPolygon':
        if (coordinates is List) {
          for (final poly in coordinates) {
            final rings = _parsePolygonRings(poly);
            if (rings.isEmpty) continue;
            polygonShapes.add(_PolygonShape(outer: rings.first, holes: rings.length > 1 ? rings.sublist(1) : const []));
            for (final ring in rings) {
              boundsPoints.addAll(ring);
            }
          }
          if (boundsPoints.isNotEmpty) labelPoint = _centroid(boundsPoints);
        }
        break;
      case 'LineString':
        final line = _parseLine(coordinates);
        if (line.isNotEmpty) {
          lineShapes.add(line);
          boundsPoints.addAll(line);
          labelPoint = _centroid(line);
        }
        break;
      case 'MultiLineString':
        if (coordinates is List) {
          for (final lineCoords in coordinates) {
            final line = _parseLine(lineCoords);
            if (line.isEmpty) continue;
            lineShapes.add(line);
            boundsPoints.addAll(line);
          }
          if (boundsPoints.isNotEmpty) labelPoint = _centroid(boundsPoints);
        }
        break;
      case 'Point':
        final point = _parsePoint(coordinates);
        if (point != null) {
          boundsPoints.add(point);
          labelPoint = point;
        }
        break;
    }

    return _RenderedFeature(
      sourceId: sourceId,
      label: label,
      levelKey: levelKey,
      polygonShapes: polygonShapes,
      lineShapes: lineShapes,
      labelPoint: labelPoint,
      boundsPoints: boundsPoints,
      baseStyle: baseStyle,
    );
  }

  static List<List<LatLng>> _parsePolygonRings(dynamic coordinates) {
    if (coordinates is! List) return const [];
    final rings = <List<LatLng>>[];
    for (final ring in coordinates) {
      final parsed = _parseLine(ring);
      if (parsed.isNotEmpty) rings.add(parsed);
    }
    return rings;
  }

  static List<LatLng> _parseLine(dynamic coordinates) {
    if (coordinates is! List) return const [];
    final points = <LatLng>[];
    for (final item in coordinates) {
      final point = _parsePoint(item);
      if (point != null) points.add(point);
    }
    return points;
  }

  static LatLng? _parsePoint(dynamic coordinates) {
    if (coordinates is! List || coordinates.length < 2) return null;
    final lon = (coordinates[0] as num?)?.toDouble();
    final lat = (coordinates[1] as num?)?.toDouble();
    if (lon == null || lat == null) return null;
    return LatLng(lat, lon);
  }

  static LatLng? _centroid(List<LatLng> points) {
    if (points.isEmpty) return null;
    double lat = 0;
    double lng = 0;
    for (final point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }
}

class _ResolvedVisualStyle {
  final bool visible;
  final Color fillColor;
  final double fillOpacity;
  final Color strokeColor;
  final double strokeWidth;
  final double strokeOpacity;
  final bool showLabel;
  final Color labelColor;
  final double labelSize;
  final FontWeight labelWeight;
  final int labelMinZoom;
  final int labelMaxZoom;
  final int zIndex;
  final _ResolvedVisualStyle? hoverState;
  final _ResolvedVisualStyle? selectedState;

  const _ResolvedVisualStyle({
    required this.visible,
    required this.fillColor,
    required this.fillOpacity,
    required this.strokeColor,
    required this.strokeWidth,
    required this.strokeOpacity,
    required this.showLabel,
    required this.labelColor,
    required this.labelSize,
    required this.labelWeight,
    required this.labelMinZoom,
    required this.labelMaxZoom,
    required this.zIndex,
    required this.hoverState,
    required this.selectedState,
  });

  factory _ResolvedVisualStyle.fromJson(Map<String, dynamic> json) {
    final states = json['states'] is Map ? Map<String, dynamic>.from(json['states'] as Map) : const <String, dynamic>{};
    return _ResolvedVisualStyle(
      visible: _asBool(json['visible'], true),
      fillColor: _asColor(json['fillColor'], PwfColors.gold),
      fillOpacity: _asDouble(json['fillOpacity'], 0.22),
      strokeColor: _asColor(json['strokeColor'], PwfColors.primaryBlue),
      strokeWidth: _asDouble(json['strokeWidth'], 1.8),
      strokeOpacity: _asDouble(json['strokeOpacity'], 0.95),
      showLabel: _asBool(json['showLabel'], true),
      labelColor: _asColor(json['labelColor'], Colors.white),
      labelSize: _asDouble(json['labelSize'], 11),
      labelWeight: _asFontWeight(json['labelWeight'], FontWeight.w700),
      labelMinZoom: _asInt(json['labelMinZoom'], 0),
      labelMaxZoom: _asInt(json['labelMaxZoom'], 24),
      zIndex: _asInt(json['zIndex'], 0),
      hoverState: states['hover'] is Map ? _ResolvedVisualStyle.fromDelta(Map<String, dynamic>.from(states['hover'] as Map)) : null,
      selectedState: states['selected'] is Map ? _ResolvedVisualStyle.fromDelta(Map<String, dynamic>.from(states['selected'] as Map)) : null,
    );
  }

  factory _ResolvedVisualStyle.fromDelta(Map<String, dynamic> json) {
    return _ResolvedVisualStyle(
      visible: _asBool(json['visible'], true),
      fillColor: _asColor(json['fillColor'], Colors.transparent),
      fillOpacity: _asDouble(json['fillOpacity'], double.nan),
      strokeColor: _asColor(json['strokeColor'], Colors.transparent),
      strokeWidth: _asDouble(json['strokeWidth'], double.nan),
      strokeOpacity: _asDouble(json['strokeOpacity'], double.nan),
      showLabel: _asBool(json['showLabel'], true),
      labelColor: _asColor(json['labelColor'], Colors.transparent),
      labelSize: _asDouble(json['labelSize'], double.nan),
      labelWeight: _asFontWeight(json['labelWeight'], FontWeight.normal),
      labelMinZoom: _asInt(json['labelMinZoom'], -1),
      labelMaxZoom: _asInt(json['labelMaxZoom'], -1),
      zIndex: _asInt(json['zIndex'], -1),
      hoverState: null,
      selectedState: null,
    );
  }

  _ResolvedVisualStyle merge(_ResolvedVisualStyle? other) {
    if (other == null) return this;
    return _ResolvedVisualStyle(
      visible: other.visible,
      fillColor: other.fillColor == Colors.transparent ? fillColor : other.fillColor,
      fillOpacity: other.fillOpacity.isNaN ? fillOpacity : other.fillOpacity,
      strokeColor: other.strokeColor == Colors.transparent ? strokeColor : other.strokeColor,
      strokeWidth: other.strokeWidth.isNaN ? strokeWidth : other.strokeWidth,
      strokeOpacity: other.strokeOpacity.isNaN ? strokeOpacity : other.strokeOpacity,
      showLabel: other.showLabel,
      labelColor: other.labelColor == Colors.transparent ? labelColor : other.labelColor,
      labelSize: other.labelSize.isNaN ? labelSize : other.labelSize,
      labelWeight: other.labelWeight == FontWeight.normal ? labelWeight : other.labelWeight,
      labelMinZoom: other.labelMinZoom < 0 ? labelMinZoom : other.labelMinZoom,
      labelMaxZoom: other.labelMaxZoom < 0 ? labelMaxZoom : other.labelMaxZoom,
      zIndex: other.zIndex < 0 ? zIndex : other.zIndex,
      hoverState: hoverState,
      selectedState: selectedState,
    );
  }

  static bool _asBool(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;
    return fallback;
  }

  static double _asDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static Color _asColor(dynamic value, Color fallback) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return fallback;
    final hex = text.replaceAll('#', '').trim();
    if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    return fallback;
  }

  static FontWeight _asFontWeight(dynamic value, FontWeight fallback) {
    if (value is int) return _fromNumericWeight(value);
    final text = value?.toString().trim().toLowerCase();
    if (text == null || text.isEmpty) return fallback;
    if (text.startsWith('w')) {
      return _fromNumericWeight(int.tryParse(text.substring(1)) ?? 400);
    }
    return _fromNumericWeight(int.tryParse(text) ?? 400);
  }

  static FontWeight _fromNumericWeight(int weight) {
    if (weight >= 800) return FontWeight.w800;
    if (weight >= 700) return FontWeight.w700;
    if (weight >= 600) return FontWeight.w600;
    if (weight >= 500) return FontWeight.w500;
    if (weight >= 400) return FontWeight.w400;
    return FontWeight.w400;
  }
}

class _PanelCard extends StatelessWidget {
  final Widget child;
  const _PanelCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          const SizedBox(height: 4),
          SelectableText(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InlineStatus extends StatelessWidget {
  final String label;
  const _InlineStatus({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
        ),
      ],
    );
  }
}
