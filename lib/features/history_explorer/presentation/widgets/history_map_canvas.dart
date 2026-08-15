import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/colors.dart';
import '../../application/state/history_explorer_state.dart';
import '../../domain/models/history_modern_context.dart';
import '../../domain/models/history_overlay_feature.dart';
import '../../domain/models/history_waqf_asset_link.dart';

class HistoryMapCanvas extends StatefulWidget {
  const HistoryMapCanvas({
    super.key,
    required this.state,
    required this.onFeatureSelected,
    required this.onModernContextSelected,
    required this.onWaqfAssetSelected,
  });

  final HistoryExplorerState state;
  final ValueChanged<String?> onFeatureSelected;
  final ValueChanged<String?> onModernContextSelected;
  final ValueChanged<String?> onWaqfAssetSelected;

  @override
  State<HistoryMapCanvas> createState() => _HistoryMapCanvasState();
}

class _HistoryMapCanvasState extends State<HistoryMapCanvas> {
  final MapController _mapController = MapController();
  bool _didFitBounds = false;
  String? _hoveredSourceId;
  double _currentZoom = 7.9;
  String? _lastSelection;
  String? _lastModernSelection;
  String? _lastWaqfSelection;

  @override
  void didUpdateWidget(covariant HistoryMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedPeriodNo != widget.state.selectedPeriodNo ||
        oldWidget.state.selectedLevelKey != widget.state.selectedLevelKey ||
        oldWidget.state.filteredFeatures.length != widget.state.filteredFeatures.length ||
        oldWidget.state.mode != widget.state.mode ||
        oldWidget.state.resolvedContext.modernContexts.length != widget.state.resolvedContext.modernContexts.length ||
        oldWidget.state.resolvedContext.waqfAssets.length != widget.state.resolvedContext.waqfAssets.length ||
        oldWidget.state.selectedModernContextCode != widget.state.selectedModernContextCode ||
        oldWidget.state.selectedWaqfAssetId != widget.state.selectedWaqfAssetId) {
      _didFitBounds = false;
    }

    if (_lastSelection != widget.state.selectedFeatureId && widget.state.selectedFeature != null) {
      _lastSelection = widget.state.selectedFeatureId;
      final selected = _RenderedFeature.fromDomain(widget.state.selectedFeature!);
      scheduleMicrotask(() => _focusSelected(selected));
    }

    if (_lastModernSelection != widget.state.selectedModernContextCode && widget.state.selectedModernContext != null) {
      _lastModernSelection = widget.state.selectedModernContextCode;
      scheduleMicrotask(() => _focusPoint(_modernPointForSelection()));
    }

    if (_lastWaqfSelection != widget.state.selectedWaqfAssetId && widget.state.selectedWaqfAsset != null) {
      _lastWaqfSelection = widget.state.selectedWaqfAssetId;
      scheduleMicrotask(() => _focusPoint(_waqfPointForSelection()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = widget.state.filteredFeatures.map(_RenderedFeature.fromDomain).toList(growable: false)
      ..sort((a, b) => a.baseStyle.zIndex.compareTo(b.baseStyle.zIndex));
    final modernReferences = _buildModernReferences();
    final waqfReferences = _buildWaqfReferences();
    final modernAnchors = _buildModernAnchors(parsed, modernReferences);
    final waqfAnchors = _buildWaqfAnchors(parsed, modernAnchors, waqfReferences);
    final hasAuxiliaryVisuals = modernAnchors.isNotEmpty ||
        waqfAnchors.isNotEmpty ||
        modernReferences.isNotEmpty ||
        waqfReferences.isNotEmpty ||
        widget.state.selectedModernContext != null ||
        widget.state.selectedWaqfAsset != null ||
        // نتائج البحث موجودة — الخريطة يجب أن تظهر حتى قبل اكتمال resolve
        (widget.state.showModernContext && widget.state.modernSearchResults.isNotEmpty) ||
        (widget.state.showWaqfAssets && widget.state.waqfSearchResults.isNotEmpty) ||
        // resolvedContext فيه بيانات (وضع التاريخ بعد اختيار عنصر)
        widget.state.resolvedContext.hasAnyData;
    final bounds = _calculateBounds(parsed, modernAnchors, waqfAnchors, modernReferences, waqfReferences);
    _fitOnce(bounds);

    if (widget.state.isLoading && parsed.isEmpty && !hasAuxiliaryVisuals) {
      return const _MapStatus(message: 'جارٍ تحميل المشهد التاريخي/الحديث...');
    }

    if (!widget.state.canDrawOverlay && !hasAuxiliaryVisuals) {
      if (widget.state.mode.name == 'modern') {
        // إذا يوجد بحث جارٍ أو نتائج — لا نعرض empty state
        if (widget.state.isLoading || widget.state.modernSearchResults.isNotEmpty) {
          // سقط للخريطة الفارغة بدل رسالة الـ empty state
        } else {
          return const _MapEmptyState(
            title: 'مرجع حديث',
            message: 'اختر مجتمعًا أو وحدة حديثة من القائمة لعرض مرساها أو هندستها المرتبطة وربطها بالسلسلة التاريخية على الخريطة.',
          );
        }
      } else if (widget.state.mode.name == 'waqf') {
        if (widget.state.isLoading || widget.state.waqfSearchResults.isNotEmpty) {
          // سقط للخريطة
        } else {
          return const _MapEmptyState(
            title: 'أصل وقفي حديث',
            message: 'اختر أصلًا وقفيًا من القائمة لعرض موضعه أو هندسته المرتبطة وربطه بالسلسلة التاريخية على الخريطة.',
          );
        }
      } else {
        return _MapEmptyState(
          title: widget.state.selectedPeriodKind.labelAr == 'مرجعية' ? 'فترة مرجعية' : 'فترة وصفية',
          message: widget.state.selectedPeriod?.summaryAr?.trim().isNotEmpty == true
              ? widget.state.selectedPeriod!.summaryAr!
              : 'هذه الفترة لا تملك Overlay تشغيليًا في هذه المرحلة، ولذلك تُعرض كبطاقة تفسيرية بدل الرسم على الخريطة.',
        );
      }
    }

    if (widget.state.canDrawOverlay && parsed.isEmpty && !hasAuxiliaryVisuals) {
      return const _MapEmptyState(
        title: 'لا توجد عناصر',
        message: 'لم ترجع الفترة/المستوى الحالي عناصر مكانية قابلة للرسم أو أن الفلاتر الحالية أخفت جميع النتائج.',
      );
    }

    final polygons = _buildPolygons(parsed);
    final polylines = _buildPolylines(parsed);
    final markers = _buildMarkers(parsed);
    final modernReferencePolygons = _buildReferencePolygons(modernReferences);
    final modernReferenceLines = _buildReferencePolylines(modernReferences);
    final modernReferenceMarkers = _buildReferenceMarkers(modernReferences);
    final waqfReferencePolygons = _buildReferencePolygons(waqfReferences);
    final waqfReferenceLines = _buildReferencePolylines(waqfReferences);
    final waqfReferenceMarkers = _buildReferenceMarkers(waqfReferences);
    final modernPolylines = _buildModernConnectionLines(parsed, modernAnchors, modernReferences);
    final modernMarkers = _buildModernMarkers(modernAnchors);
    final waqfPolylines = _buildWaqfConnectionLines(parsed, modernAnchors, waqfAnchors, modernReferences, waqfReferences);
    final waqfMarkers = _buildWaqfMarkers(waqfAnchors);
    final interactionHint = widget.state.resolvedContext.hasAnyData ||
        widget.state.selectedModernContext != null ||
        widget.state.selectedWaqfAsset != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(31.95, 35.2),
              initialZoom: 7.9,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              onTap: (_, point) => _handleTap(point, parsed, modernReferences, waqfReferences),
              onPointerHover: (event, point) => _handleHover(point, parsed, modernReferences, waqfReferences),
              onPositionChanged: (position, hasGesture) {
                final zoom = position.zoom ?? _currentZoom;
                if (_currentZoom != zoom) {
                  setState(() => _currentZoom = zoom);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'palwakf.kimi',
              ),
              Opacity(
                opacity: 0.60,
                child: TileLayer(
                  urlTemplate: 'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'palwakf.kimi',
                ),
              ),
              if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
              if (modernReferencePolygons.isNotEmpty) PolygonLayer(polygons: modernReferencePolygons),
              if (waqfReferencePolygons.isNotEmpty) PolygonLayer(polygons: waqfReferencePolygons),
              if (modernReferenceLines.isNotEmpty) PolylineLayer(polylines: modernReferenceLines),
              if (waqfReferenceLines.isNotEmpty) PolylineLayer(polylines: waqfReferenceLines),
              if (modernPolylines.isNotEmpty) PolylineLayer(polylines: modernPolylines),
              if (waqfPolylines.isNotEmpty) PolylineLayer(polylines: waqfPolylines),
              if (markers.isNotEmpty) MarkerLayer(markers: markers),
              if (modernReferenceMarkers.isNotEmpty) MarkerLayer(markers: modernReferenceMarkers),
              if (waqfReferenceMarkers.isNotEmpty) MarkerLayer(markers: waqfReferenceMarkers),
              if (modernMarkers.isNotEmpty) MarkerLayer(markers: modernMarkers),
              if (waqfMarkers.isNotEmpty) MarkerLayer(markers: waqfMarkers),
            ],
          ),
          Positioned(
            top: 16,
            right: 16,
            child: _LegendOverlay(state: widget.state),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: _CounterOverlay(
              shapeCount: polygons.length + polylines.length + modernReferencePolygons.length + modernReferenceLines.length + waqfReferencePolygons.length + waqfReferenceLines.length + modernPolylines.length + waqfPolylines.length,
              labelCount: markers.length + modernReferenceMarkers.length + waqfReferenceMarkers.length + modernMarkers.length + waqfMarkers.length,
              levelKey: widget.state.selectedLevelKey,
            ),
          ),
          if (interactionHint)
            Positioned(
              bottom: 16,
              right: 16,
              child: _InteractionHintOverlay(state: widget.state),
            ),
        ],
      ),
    );
  }

  void _fitOnce(LatLngBounds? bounds) {
    if (_didFitBounds || bounds == null || !mounted) return;
    scheduleMicrotask(() {
      if (!mounted) return;
      try {
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32)),
        );
        _didFitBounds = true;
      } catch (_) {}
    });
  }

  void _focusSelected(_RenderedFeature feature) {
    if (!mounted || feature.boundsPoints.isEmpty) return;
    try {
      final valid = feature.boundsPoints.where((p) =>
          p.latitude.isFinite && p.longitude.isFinite).toList();
      if (valid.isEmpty) return;
      if (valid.length == 1) {
        _mapController.move(valid.first, _currentZoom < 10 ? 10.5 : _currentZoom);
        return;
      }
      final allSame = valid.every((p) =>
          p.latitude == valid.first.latitude &&
          p.longitude == valid.first.longitude);
      if (allSame) {
        _mapController.move(valid.first, _currentZoom < 10 ? 10.5 : _currentZoom);
        return;
      }
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(valid),
          padding: const EdgeInsets.all(28),
        ),
      );
    } catch (_) {}
  }


  void _focusPoint(LatLng? point) {
    if (!mounted || point == null) return;
    try {
      _mapController.move(point, _currentZoom < 10.5 ? 10.5 : _currentZoom);
    } catch (_) {}
  }

  LatLng? _modernPointForSelection() {
    final selected = widget.state.selectedModernContext;
    if (selected == null) return null;
    if (selected.hasCenter) {
      return _safeLatLng(selected.centerLat, selected.centerLng);
    }
    return _pointFromGeo(selected.centroidJson) ?? _pointFromGeo(selected.geomJson);
  }

  LatLng? _waqfPointForSelection() {
    final selected = widget.state.selectedWaqfAsset;
    if (selected == null) return null;
    if (selected.hasCenter) {
      return _safeLatLng(selected.centerLat, selected.centerLng);
    }
    return _pointFromGeo(selected.centroidJson) ?? _pointFromGeo(selected.geomJson);
  }

  void _handleTap(
    LatLng point,
    List<_RenderedFeature> features,
    List<_ReferenceGeometry> modernReferences,
    List<_ReferenceGeometry> waqfReferences,
  ) {
    final historyHit = _hitTestFeature(point, features);
    if (historyHit != null) {
      widget.onFeatureSelected(widget.state.selectedFeatureId == historyHit.sourceId ? null : historyHit.sourceId);
      return;
    }
    final modernHit = _hitTestReference(point, modernReferences);
    if (modernHit != null) {
      widget.onModernContextSelected(widget.state.selectedModernContextCode == modernHit.id ? null : modernHit.id);
      return;
    }
    final waqfHit = _hitTestReference(point, waqfReferences);
    if (waqfHit != null) {
      widget.onWaqfAssetSelected(widget.state.selectedWaqfAssetId == waqfHit.id ? null : waqfHit.id);
      return;
    }
    widget.onFeatureSelected(null);
  }

  void _handleHover(
    LatLng point,
    List<_RenderedFeature> features,
    List<_ReferenceGeometry> modernReferences,
    List<_ReferenceGeometry> waqfReferences,
  ) {
    final historyHit = _hitTestFeature(point, features);
    final modernHit = historyHit == null ? _hitTestReference(point, modernReferences) : null;
    final waqfHit = historyHit == null && modernHit == null ? _hitTestReference(point, waqfReferences) : null;
    final next = historyHit?.sourceId ?? modernHit?.id ?? waqfHit?.id;
    if (_hoveredSourceId == next) return;
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

  LatLngBounds? _calculateBounds(
    List<_RenderedFeature> features,
    List<_PointAnchor> modernAnchors,
    List<_PointAnchor> waqfAnchors,
    List<_ReferenceGeometry> modernReferences,
    List<_ReferenceGeometry> waqfReferences,
  ) {
    final points = <LatLng>[];
    for (final feature in features) {
      points.addAll(feature.boundsPoints);
    }
    for (final reference in modernReferences) {
      points.addAll(reference.rendered.boundsPoints);
    }
    for (final reference in waqfReferences) {
      points.addAll(reference.rendered.boundsPoints);
    }
    points.addAll(modernAnchors.map((e) => e.point));
    points.addAll(waqfAnchors.map((e) => e.point));
    if (points.isEmpty) return null;
    // فلتر أي نقطة غير صالحة قبل بناء الـ bounds
    final valid = points.where((p) =>
        p.latitude.isFinite && p.longitude.isFinite &&
        p.latitude.abs() <= 90 && p.longitude.abs() <= 180).toList();
    if (valid.isEmpty) return null;
    if (valid.length == 1) {
      // نقطة واحدة — أنشئ bounds صغير حولها بدل fromPoints
      final p = valid.first;
      return LatLngBounds(
        LatLng(p.latitude - 0.05, p.longitude - 0.05),
        LatLng(p.latitude + 0.05, p.longitude + 0.05),
      );
    }
    // تحقق أن النقاط ليست كلها متطابقة
    final allSame = valid.every((p) =>
        p.latitude == valid.first.latitude &&
        p.longitude == valid.first.longitude);
    if (allSame) {
      final p = valid.first;
      return LatLngBounds(
        LatLng(p.latitude - 0.05, p.longitude - 0.05),
        LatLng(p.latitude + 0.05, p.longitude + 0.05),
      );
    }
    return LatLngBounds.fromPoints(valid);
  }

  List<_ReferenceGeometry> _buildModernReferences() {
    final items = _effectiveModernContexts();
    if (items.isEmpty) return const [];
    return items.where((item) => item.hasGeometry || item.hasCentroidGeometry).map((item) {
      final rendered = _GeoOverlayParser.fromGeoJson(
        item.geomJson ?? item.centroidJson,
        sourceId: item.communityCode,
        label: item.communityLabel,
        levelKey: 'modern_reference',
        baseStyle: _ResolvedVisualStyle.reference(
          color: PwfColors.primaryBlue,
          selected: widget.state.selectedModernContextCode == item.communityCode,
        ),
      );
      return _ReferenceGeometry(
        id: item.communityCode,
        label: item.communityLabel,
        subtitle: item.governorateLabel ?? item.lguLabel ?? 'مرجع حديث',
        color: PwfColors.primaryBlue,
        kind: 'modern',
        isSelected: widget.state.selectedModernContextCode == item.communityCode,
        rendered: rendered,
      );
    }).toList(growable: false);
  }

  List<_ReferenceGeometry> _buildWaqfReferences() {
    final items = _effectiveWaqfAssets();
    if (items.isEmpty) return const [];
    return items.where((item) => item.hasGeometry || item.hasCentroidGeometry).map((item) {
      final label = (item.name?.trim().isNotEmpty ?? false) ? item.name!.trim() : item.pwfKey;
      final rendered = _GeoOverlayParser.fromGeoJson(
        item.geomJson ?? item.centroidJson,
        sourceId: item.id,
        label: label,
        levelKey: 'waqf_asset',
        baseStyle: _ResolvedVisualStyle.reference(
          color: PwfColors.royalRed,
          selected: widget.state.selectedWaqfAssetId == item.id,
        ),
      );
      return _ReferenceGeometry(
        id: item.id,
        label: label,
        subtitle: item.community ?? item.municipality ?? 'أصل وقفي',
        color: PwfColors.royalRed,
        kind: 'waqf',
        isSelected: widget.state.selectedWaqfAssetId == item.id,
        rendered: rendered,
      );
    }).toList(growable: false);
  }

  List<_PointAnchor> _buildModernAnchors(List<_RenderedFeature> features, List<_ReferenceGeometry> modernReferences) {
    final contexts = _effectiveModernContexts();
    if (contexts.isEmpty) return const [];
    const palestineFallback = LatLng(31.95, 35.20);
    final LatLng safeFallback = _resolvePrimaryAnchor(features) ?? palestineFallback;
    final anchors = <_PointAnchor>[];
    final geometryIds = modernReferences.map((e) => e.id).toSet();
    for (var i = 0; i < contexts.length; i++) {
      final item = contexts[i];
      if (geometryIds.contains(item.communityCode)) continue;
      final LatLng point;
      if (item.hasCenter) {
        final p = _safeLatLng(item.centerLat, item.centerLng);
        if (p == null) continue;
        point = p;
      } else {
        point = _pointFromGeo(item.centroidJson) ??
            _pointFromGeo(item.geomJson) ??
            _offsetPoint(safeFallback, i, 0.018) ??
            safeFallback;
      }
      anchors.add(
        _PointAnchor(
          id: item.communityCode,
          label: item.communityLabel,
          subtitle: item.governorateLabel ?? item.lguLabel ?? 'مرجع حديث',
          point: point,
          color: PwfColors.primaryBlue,
          isSelected: widget.state.selectedModernContextCode == item.communityCode,
        ),
      );
    }
    return anchors;
  }

  List<_PointAnchor> _buildWaqfAnchors(
    List<_RenderedFeature> features,
    List<_PointAnchor> modernAnchors,
    List<_ReferenceGeometry> waqfReferences,
  ) {
    final assets = _effectiveWaqfAssets();
    if (assets.isEmpty) return const [];
    const palestineFallback = LatLng(31.95, 35.20);
    final LatLng safeFallback = modernAnchors.isNotEmpty
        ? modernAnchors.first.point
        : (_resolvePrimaryAnchor(features) ?? palestineFallback);
    final anchors = <_PointAnchor>[];
    final geometryIds = waqfReferences.map((e) => e.id).toSet();
    for (var i = 0; i < assets.length; i++) {
      final item = assets[i];
      if (geometryIds.contains(item.id)) continue;
      final LatLng point;
      if (item.hasCenter) {
        final p = _safeLatLng(item.centerLat, item.centerLng);
        if (p == null) continue;
        point = p;
      } else {
        point = _pointFromGeo(item.centroidJson) ??
            _pointFromGeo(item.geomJson) ??
            _offsetPoint(safeFallback, i, 0.010) ??
            safeFallback;
      }
      anchors.add(
        _PointAnchor(
          id: item.id,
          label: (item.name?.trim().isNotEmpty ?? false) ? item.name!.trim() : item.pwfKey,
          subtitle: item.community ?? item.municipality ?? 'أصل وقفي',
          point: point,
          color: PwfColors.royalRed,
          isSelected: widget.state.selectedWaqfAssetId == item.id,
        ),
      );
    }
    return anchors;
  }

  List<HistoryModernContext> _effectiveModernContexts() {
    final seen = <String>{};
    final items = <HistoryModernContext>[];

    // 1) المرجع الحديث المحدد أولاً — دائماً بغض النظر عن الـ toggle
    final selected = widget.state.selectedModernContext;
    if (selected != null && seen.add(selected.communityCode)) {
      items.add(selected);
    }

    // 2) نتائج resolvedContext — تظهر دائماً إذا كان هناك عنصر تاريخي محدد
    for (final item in widget.state.resolvedContext.modernContexts) {
      if (seen.add(item.communityCode)) items.add(item);
    }

    // 3) نتائج البحث — فقط إذا كان الـ toggle مفعلاً
    if (widget.state.showModernContext) {
      for (final item in widget.state.modernSearchResults) {
        if (seen.add(item.communityCode)) items.add(item);
      }
    }

    return items;
  }

  List<HistoryWaqfAssetLink> _effectiveWaqfAssets() {
    final seen = <String>{};
    final items = <HistoryWaqfAssetLink>[];

    // 1) الأصل المحدد أولاً — دائماً بغض النظر عن الـ toggle
    final selected = widget.state.selectedWaqfAsset;
    if (selected != null && seen.add(selected.id)) {
      items.add(selected);
    }

    // 2) نتائج resolvedContext — تظهر دائماً إذا كان هناك عنصر أو مرجع محدد
    for (final item in widget.state.resolvedContext.waqfAssets) {
      if (seen.add(item.id)) items.add(item);
    }

    // 3) نتائج البحث — فقط إذا كان الـ toggle مفعلاً
    if (widget.state.showWaqfAssets) {
      for (final item in widget.state.waqfSearchResults) {
        if (seen.add(item.id)) items.add(item);
      }
    }

    return items;
  }

  LatLng? _resolvePrimaryAnchor(List<_RenderedFeature> features) {
    final selected = widget.state.selectedFeatureId;
    if (selected != null) {
      for (final feature in features) {
        if (feature.sourceId == selected) {
          final point = feature.labelPoint ?? (feature.boundsPoints.isNotEmpty ? feature.boundsPoints.first : null);
          if (point != null) return point;
        }
      }
    }
    if (features.isNotEmpty) {
      final point = features.first.labelPoint ?? (features.first.boundsPoints.isNotEmpty ? features.first.boundsPoints.first : null);
      if (point != null) return point;
    }
    final modernPoint = _modernPointForSelection();
    if (modernPoint != null) return modernPoint;
    final waqfPoint = _waqfPointForSelection();
    if (waqfPoint != null) return waqfPoint;
    // لا نُرجع LatLng ثابت هنا — المستدعي مسؤول عن الـ fallback
    return null;
  }

  LatLng? _offsetPoint(LatLng? origin, int index, double radius) {
    if (origin == null) return null;
    if (index == 0) return origin;
    const offsets = <List<double>>[
      [0.8, 0.0],
      [0.5, 0.7],
      [-0.5, 0.7],
      [-0.8, 0.0],
      [-0.5, -0.7],
      [0.5, -0.7],
    ];
    final ring = (index / offsets.length).floor() + 1;
    final pair = offsets[index % offsets.length];
    final scale = radius * ring;
    return _safeLatLng(
      origin.latitude + (pair[0] * scale),
      origin.longitude + (pair[1] * scale),
    );
  }

  List<Polyline> _buildModernConnectionLines(
    List<_RenderedFeature> features,
    List<_PointAnchor> anchors,
    List<_ReferenceGeometry> references,
  ) {
    final targets = <MapEntry<LatLng, bool>>[
      ...references.map((e) => MapEntry(e.anchorPoint, e.isSelected)),
      ...anchors.map((e) => MapEntry(e.point, e.isSelected)),
    ];
    if (targets.isEmpty) return const [];
    final origin = _resolvePrimaryAnchor(features) ?? const LatLng(31.95, 35.20);
    return targets.map((entry) {
      return Polyline(
        points: [origin, entry.key],
        color: PwfColors.primaryBlue.withValues(alpha: entry.value ? 0.92 : 0.70),
        strokeWidth: entry.value ? 3.6 : 2.2,
      );
    }).toList(growable: false);
  }

  List<Polyline> _buildWaqfConnectionLines(
    List<_RenderedFeature> features,
    List<_PointAnchor> modernAnchors,
    List<_PointAnchor> waqfAnchors,
    List<_ReferenceGeometry> modernReferences,
    List<_ReferenceGeometry> waqfReferences,
  ) {
    final targets = <MapEntry<LatLng, bool>>[
      ...waqfReferences.map((e) => MapEntry(e.anchorPoint, e.isSelected)),
      ...waqfAnchors.map((e) => MapEntry(e.point, e.isSelected)),
    ];
    if (targets.isEmpty) return const [];
    final modernOrigin = modernReferences.isNotEmpty
        ? modernReferences.first.anchorPoint
        : (modernAnchors.isNotEmpty
            ? modernAnchors.first.point
            : (_resolvePrimaryAnchor(features) ?? const LatLng(31.95, 35.20)));
    return targets.map((entry) {
      return Polyline(
        points: [modernOrigin, entry.key],
        color: PwfColors.royalRed.withValues(alpha: entry.value ? 0.94 : 0.72),
        strokeWidth: entry.value ? 3.4 : 2.0,
      );
    }).toList(growable: false);
  }

  List<Marker> _buildModernMarkers(List<_PointAnchor> anchors) {
    return anchors.map((anchor) => _buildAnchorMarker(anchor, kind: 'modern')).toList(growable: false);
  }

  List<Marker> _buildWaqfMarkers(List<_PointAnchor> anchors) {
    return anchors.map((anchor) => _buildAnchorMarker(anchor, kind: 'waqf')).toList(growable: false);
  }

  Marker _buildAnchorMarker(_PointAnchor anchor, {required String kind}) {
    final isWaqf = kind == 'waqf';
    final isSelected = anchor.isSelected;
    return Marker(
      point: anchor.point,
      width: isWaqf ? 196 : 186,
      height: isSelected ? 68 : 60,
      child: GestureDetector(
        onTap: () {
          if (isWaqf) {
            widget.onWaqfAssetSelected(anchor.id);
          } else {
            widget.onModernContextSelected(anchor.id);
          }
          _focusPoint(anchor.point);
        },
        child: Align(
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 10, vertical: isSelected ? 8 : 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220).withValues(alpha: isSelected ? 0.90 : (isWaqf ? 0.82 : 0.72)),
              borderRadius: BorderRadius.circular(isSelected ? 16 : 14),
              border: Border.all(color: anchor.color.withValues(alpha: 0.98), width: isSelected ? 2.2 : 1.4),
              boxShadow: [
                BoxShadow(
                  color: anchor.color.withValues(alpha: isSelected ? 0.22 : 0.10),
                  blurRadius: isSelected ? 16 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isWaqf ? Icons.location_on : Icons.account_tree_outlined,
                  size: isSelected ? 18 : 16,
                  color: anchor.color,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anchor.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: isSelected ? 11.5 : 11,
                        ),
                      ),
                      if ((anchor.subtitle ?? '').trim().isNotEmpty)
                        Text(
                          anchor.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white70, fontSize: isSelected ? 10.2 : 10, height: 1.3),
                        ),
                      if (isSelected)
                        Text(
                          isWaqf ? 'محدد الآن على الخريطة' : 'مرجع حديث محدد',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: anchor.color.withValues(alpha: 0.95), fontSize: 9.5, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ReferenceGeometry? _hitTestReference(LatLng point, List<_ReferenceGeometry> references) {
    for (final reference in references.reversed) {
      for (final shape in reference.rendered.polygonShapes) {
        if (_pointInPolygon(point, shape)) return reference;
      }
      final anchor = reference.anchorPoint;
      final deltaLat = (anchor.latitude - point.latitude).abs();
      final deltaLng = (anchor.longitude - point.longitude).abs();
      if (deltaLat < 0.004 && deltaLng < 0.004) return reference;
    }
    return null;
  }

  LatLng? _pointFromGeo(Map<String, dynamic>? geom) {
    if (geom == null) return null;
    return _extractPointFromCoordinates(geom['coordinates']);
  }

  LatLng? _extractPointFromCoordinates(dynamic coordinates) {
    if (coordinates is List) {
      if (coordinates.length >= 2 && coordinates[0] is num && coordinates[1] is num) {
        return _safeLatLng((coordinates[1] as num).toDouble(), (coordinates[0] as num).toDouble());
      }
      for (final item in coordinates) {
        final point = _extractPointFromCoordinates(item);
        if (point != null) return point;
      }
    }
    return null;
  }

  LatLng? _safeLatLng(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (!lat.isFinite || !lng.isFinite) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return LatLng(lat, lng);
  }

  List<Polygon> _buildReferencePolygons(List<_ReferenceGeometry> references) {
    final polygons = <Polygon>[];
    for (final reference in references) {
      for (final shape in reference.rendered.polygonShapes) {
        polygons.add(
          Polygon(
            points: shape.outer,
            holePointsList: shape.holes,
            color: reference.kind == 'waqf'
                ? PwfColors.royalRed.withValues(alpha: widget.state.boundariesOnly ? 0.0 : (reference.isSelected ? 0.18 : 0.10))
                : PwfColors.primaryBlue.withValues(alpha: widget.state.boundariesOnly ? 0.0 : (reference.isSelected ? 0.16 : 0.08)),
            borderColor: reference.color.withValues(alpha: reference.isSelected ? 0.95 : 0.72),
            borderStrokeWidth: reference.isSelected ? 2.6 : 1.6,
          ),
        );
      }
    }
    return polygons;
  }

  List<Polyline> _buildReferencePolylines(List<_ReferenceGeometry> references) {
    final polylines = <Polyline>[];
    for (final reference in references) {
      for (final line in reference.rendered.lineShapes) {
        polylines.add(
          Polyline(
            points: line,
            color: reference.color.withValues(alpha: reference.isSelected ? 0.92 : 0.74),
            strokeWidth: reference.isSelected ? 3.0 : 1.8,
          ),
        );
      }
    }
    return polylines;
  }

  List<Marker> _buildReferenceMarkers(List<_ReferenceGeometry> references) {
    final markers = <Marker>[];
    for (final reference in references) {
      final point = reference.anchorPoint;
      final isPointOnly = reference.rendered.polygonShapes.isEmpty && reference.rendered.lineShapes.isEmpty;
      if (!isPointOnly && !reference.isSelected) continue;
      markers.add(
        Marker(
          point: point,
          width: reference.isSelected ? 204 : 188,
          height: reference.isSelected ? 68 : 60,
          child: GestureDetector(
            onTap: () {
              if (reference.kind == 'waqf') {
                widget.onWaqfAssetSelected(reference.id);
              } else {
                widget.onModernContextSelected(reference.id);
              }
              _focusPoint(reference.anchorPoint);
            },
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: reference.isSelected ? 12 : 10, vertical: reference.isSelected ? 8 : 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1220).withValues(alpha: reference.isSelected ? 0.88 : 0.70),
                  borderRadius: BorderRadius.circular(reference.isSelected ? 16 : 14),
                  border: Border.all(color: reference.color.withValues(alpha: 0.96), width: reference.isSelected ? 2.2 : 1.4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(reference.kind == 'waqf' ? Icons.location_city_outlined : Icons.polyline_outlined, size: reference.isSelected ? 18 : 16, color: reference.color),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(reference.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                          if ((reference.subtitle ?? '').trim().isNotEmpty)
                            Text(reference.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.3)),
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
    return markers;
  }

  List<Polygon> _buildPolygons(List<_RenderedFeature> features) {
    final polygons = <Polygon>[];
    for (final feature in features) {
      final style = feature.effectiveStyle(
        isHovered: _hoveredSourceId == feature.sourceId,
        isSelected: widget.state.selectedFeatureId == feature.sourceId,
      );
      if (!style.visible) continue;
      for (final shape in feature.polygonShapes) {
        polygons.add(
          Polygon(
            points: shape.outer,
            holePointsList: shape.holes,
            color: widget.state.boundariesOnly
                ? Colors.transparent
                : style.fillColor.withValues(alpha: style.fillOpacity),
            borderColor: style.strokeColor.withValues(alpha: style.strokeOpacity),
            borderStrokeWidth: style.strokeWidth,
          ),
        );
      }
    }
    return polygons;
  }

  List<Polyline> _buildPolylines(List<_RenderedFeature> features) {
    final polylines = <Polyline>[];
    for (final feature in features) {
      final style = feature.effectiveStyle(
        isHovered: _hoveredSourceId == feature.sourceId,
        isSelected: widget.state.selectedFeatureId == feature.sourceId,
      );
      if (!style.visible) continue;
      for (final line in feature.lineShapes) {
        polylines.add(
          Polyline(
            points: line,
            color: style.strokeColor.withValues(alpha: style.strokeOpacity),
            strokeWidth: style.strokeWidth,
          ),
        );
      }
    }
    return polylines;
  }

  List<Marker> _buildMarkers(List<_RenderedFeature> features) {
    final markers = <Marker>[];
    for (final feature in features) {
      final point = feature.labelPoint;
      if (point == null) continue;
      final style = feature.effectiveStyle(
        isHovered: _hoveredSourceId == feature.sourceId,
        isSelected: widget.state.selectedFeatureId == feature.sourceId,
      );
      final inZoomRange = _currentZoom >= style.labelMinZoom && _currentZoom <= style.labelMaxZoom;
      if (!style.showLabel || !widget.state.showLabels || !inZoomRange) continue;
      markers.add(
        Marker(
          point: point,
          width: 190,
          height: 36,
          child: IgnorePointer(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: widget.state.selectedFeatureId == feature.sourceId ? 0.74 : 0.60),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: style.strokeColor.withValues(alpha: 0.80),
                  width: widget.state.selectedFeatureId == feature.sourceId ? 1.6 : 1.0,
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
}

class _ReferenceGeometry {
  final String id;
  final String label;
  final String? subtitle;
  final Color color;
  final String kind;
  final bool isSelected;
  final _RenderedFeature rendered;

  const _ReferenceGeometry({
    required this.id,
    required this.label,
    required this.color,
    required this.kind,
    required this.isSelected,
    required this.rendered,
    this.subtitle,
  });

  LatLng get anchorPoint =>
      rendered.labelPoint ??
      (rendered.boundsPoints.isNotEmpty
          ? rendered.boundsPoints.first
          : const LatLng(31.95, 35.20));
}

class _PointAnchor {
  final String id;
  final String label;
  final String? subtitle;
  final LatLng point;
  final Color color;
  final bool isSelected;

  const _PointAnchor({
    required this.id,
    required this.label,
    required this.point,
    required this.color,
    this.subtitle,
    this.isSelected = false,
  });
}

class _CounterOverlay extends StatelessWidget {
  const _CounterOverlay({
    required this.shapeCount,
    required this.labelCount,
    required this.levelKey,
  });

  final int shapeCount;
  final int labelCount;
  final String? levelKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        'المستوى: ${levelKey ?? '—'} • أشكال: $shapeCount • Labels: $labelCount',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _LegendOverlay extends StatelessWidget {
  const _LegendOverlay({required this.state});

  final HistoryExplorerState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Legend', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _LegendItem(color: PwfColors.gold, label: 'الطبقة التاريخية الأصلية'),
          const SizedBox(height: 6),
          _LegendItem(color: PwfColors.primaryBlue, label: state.showModernContext ? 'مراجع حديثة (هندسة أو مرابط) ومسارات ربط' : 'المراجع الحديثة معطلة'),
          const SizedBox(height: 6),
          _LegendItem(color: PwfColors.royalRed, label: state.showWaqfAssets ? 'أصول وقفية مرتبطة (هندسة أو مرابط)' : 'الأصول الوقفية معطلة'),
          const SizedBox(height: 8),
          Text(
            state.showModernContext || state.showWaqfAssets
                ? 'تُعرض المراجع الحديثة والأصول الوقفية بصريًا بهندستها الفعلية عندما تتوفر، وتعود إلى المرابط التفسيرية فقط عند غياب الهندسة، دون الادعاء بأنها حدود تاريخية أصلية.'
                : 'فعّل المراجع الحديثة أو الأصول الوقفية من الشريط العلوي لإظهار الربط البصري على الخريطة.',
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}


class _InteractionHintOverlay extends StatelessWidget {
  const _InteractionHintOverlay({required this.state});

  final HistoryExplorerState state;

  @override
  Widget build(BuildContext context) {
    final selectedModern = state.selectedModernContext;
    final selectedWaqf = state.selectedWaqfAsset;
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'تفاعل الخريطة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'يمكنك الضغط مباشرة على هندسة المرجع الحديث أو الأصل الوقفي، أو على المرابط البديلة عند غياب الهندسة، لتمييزها وإعادة تمركز الخريطة عليها.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.45),
          ),
          if (selectedModern != null) ...[
            const SizedBox(height: 8),
            Text(
              'المرجع الحديث النشط: ${selectedModern.communityLabel}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
          if (selectedWaqf != null) ...[
            const SizedBox(height: 6),
            Text(
              'الأصل الوقفي النشط: ${selectedWaqf.name ?? selectedWaqf.pwfKey}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.28),
            border: Border.all(color: color, width: 1.4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ],
    );
  }
}

class _MapStatus extends StatelessWidget {
  const _MapStatus({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _MapEmptyState extends StatelessWidget {
  const _MapEmptyState({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDescriptive = title.contains('وصفية');
    final isReference = title.contains('مرجعية');
    final accent = isReference ? PwfColors.warning : PwfColors.primaryBlue;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.history_toggle_off_outlined, size: 36, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Text(
                  isReference ? 'لا توجد طبقة تشغيلية لهذه الفترة' : 'هذه قراءة تفسيرية للفترة',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, height: 1.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

  factory _RenderedFeature.fromDomain(HistoryOverlayFeature feature) {
    return _GeoOverlayParser.fromGeoJson(
      feature.geomJson,
      sourceId: feature.sourceId,
      label: feature.displayLabel,
      levelKey: feature.levelKey,
      baseStyle: _ResolvedVisualStyle.fromJson(feature.styleJson),
    );
  }

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
    Map<String, dynamic>? geom, {
    required String sourceId,
    required String label,
    required String? levelKey,
    required _ResolvedVisualStyle baseStyle,
  }) {
    final polygonShapes = <_PolygonShape>[];
    final lineShapes = <List<LatLng>>[];
    final boundsPoints = <LatLng>[];
    LatLng? labelPoint;

    if (geom == null) {
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
    return _safeLatLng(lat, lon);
  }

  static LatLng? _centroid(List<LatLng> points) {
    if (points.isEmpty) return null;
    double lat = 0;
    double lng = 0;
    for (final point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }
    return _safeLatLng(lat / points.length, lng / points.length);
  }

  static LatLng? _safeLatLng(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (!lat.isFinite || !lng.isFinite) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return LatLng(lat, lng);
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

  factory _ResolvedVisualStyle.reference({required Color color, required bool selected}) {
    return _ResolvedVisualStyle(
      visible: true,
      fillColor: color,
      fillOpacity: selected ? 0.18 : 0.10,
      strokeColor: color,
      strokeWidth: selected ? 2.6 : 1.6,
      strokeOpacity: selected ? 0.96 : 0.78,
      showLabel: true,
      labelColor: Colors.white,
      labelSize: selected ? 11.5 : 11,
      labelWeight: FontWeight.w800,
      labelMinZoom: 0,
      labelMaxZoom: 24,
      zIndex: selected ? 60 : 40,
      hoverState: null,
      selectedState: null,
    );
  }

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
    return FontWeight.w400;
  }
}
