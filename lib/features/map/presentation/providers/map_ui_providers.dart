// lib/features/map/presentation/providers/map_ui_providers.dart
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../domain/models/gis_feature_model.dart';

final isDarkModeProvider = StateProvider<bool>((ref) => false);
final showCoordinatesProvider = StateProvider<bool>((ref) => true);
final baseMapProvider = StateProvider<String>((ref) => 'satellite');
final showBaseMapProvider = StateProvider<bool>((ref) => true);
final activeToolProvider = StateProvider<String?>((ref) => null);
final snapEnabledProvider = StateProvider<bool>((ref) => false);
final lastTapLatLngProvider = StateProvider<LatLng?>((ref) => null);
final snapPointProvider = StateProvider<LatLng?>((ref) => null);
final gotoMarkerProvider = StateProvider<LatLng?>((ref) => null);


class MapIdentifyResult {
  final LatLng point;
  final GisFeatureModel? feature;
  final double? distanceMeters;
  final String source;
  final String? relation;
  final double? score;
  final int candidatesCount;
  final bool isLoading;
  final String? message;

  const MapIdentifyResult({
    required this.point,
    this.feature,
    this.distanceMeters,
    this.source = 'local',
    this.relation,
    this.score,
    this.candidatesCount = 0,
    this.isLoading = false,
    this.message,
  });
}

class MapReportDraft {
  final LatLng point;
  final GisFeatureModel? feature;
  final DateTime createdAt;

  const MapReportDraft({
    required this.point,
    this.feature,
    required this.createdAt,
  });
}

final identifyResultProvider = StateProvider<MapIdentifyResult?>((ref) => null);
final mapReportDraftProvider = StateProvider<MapReportDraft?>((ref) => null);

enum ExplorerRealMapInteractionMode {
  identify,
  coordinatePicker,
  selectionBox,
}

extension ExplorerRealMapInteractionModeX on ExplorerRealMapInteractionMode {
  String get labelAr => switch (this) {
        ExplorerRealMapInteractionMode.identify => 'تعريف عنصر',
        ExplorerRealMapInteractionMode.coordinatePicker => 'التقاط إحداثية',
        ExplorerRealMapInteractionMode.selectionBox => 'تحديد نطاق',
      };
}

final realMapInteractionModeProvider =
    StateProvider<ExplorerRealMapInteractionMode?>((ref) => null);
final selectionBoxPointsProvider = StateProvider<List<LatLng>>((ref) => const []);

enum MeasureMode { distance, area }

final measureModeProvider = StateProvider<MeasureMode?>((ref) => null);
final measureEditingProvider = StateProvider<bool>((ref) => false);
final measurePointsProvider = StateProvider<List<LatLng>>((ref) => const []);
final measureResultLabelProvider = StateProvider<String?>((ref) => null);

final drawShapeTypeProvider = StateProvider<String?>((ref) => null);
final drawEditingProvider = StateProvider<bool>((ref) => false);
final drawPointsProvider = StateProvider<List<LatLng>>((ref) => const []);

final drawSummaryLabelProvider = Provider<String?>((ref) {
  final shape = ref.watch(drawShapeTypeProvider);
  final points = ref.watch(drawPointsProvider);
  if (shape == null || points.isEmpty) return null;

  switch (shape) {
    case 'point':
      final last = points.last;
      return 'النقاط: ${points.length} • آخر نقطة ${last.latitude.toStringAsFixed(5)}, ${last.longitude.toStringAsFixed(5)}';
    case 'line':
      if (points.length < 2) return 'أضف نقطة ثانية لقياس طول الخط';
      final d = ll.Distance();
      double meters = 0;
      for (var i = 1; i < points.length; i++) {
        meters += d(points[i - 1], points[i]);
      }
      return meters >= 1000
          ? 'طول الخط: ${(meters / 1000).toStringAsFixed(2)} كم'
          : 'طول الخط: ${meters.toStringAsFixed(1)} م';
    case 'polygon':
      if (points.length < 3) return 'أضف 3 نقاط أو أكثر لإغلاق المضلع';
      final perimeter = _computeLineMeters(points, closeLoop: true);
      final areaSqm = _approxPolygonAreaSqm(points);
      final areaText = areaSqm >= 1000
          ? '${(areaSqm / 1000).toStringAsFixed(2)} دونم'
          : '${areaSqm.toStringAsFixed(1)} م²';
      final perimeterText = perimeter >= 1000
          ? '${(perimeter / 1000).toStringAsFixed(2)} كم'
          : '${perimeter.toStringAsFixed(1)} م';
      return 'المساحة: $areaText • المحيط: $perimeterText';
    default:
      return null;
  }
});

final directionsStartProvider = StateProvider<LatLng?>((ref) => null);
final directionsEndProvider = StateProvider<LatLng?>((ref) => null);
final directionsPickTargetProvider = StateProvider<String?>((ref) => null);

final compareEnabledProvider = StateProvider<bool>((ref) => false);
final compareSwipePositionProvider = StateProvider<double>((ref) => 0.5);
final compareLeftSourceProvider =
    StateProvider<String?>((ref) => 'base:standard');
final compareRightSourceProvider =
    StateProvider<String?>((ref) => 'base:satellite');

double _computeLineMeters(List<LatLng> points, {bool closeLoop = false}) {
  if (points.length < 2) return 0;
  final d = ll.Distance();
  double meters = 0;
  for (var i = 1; i < points.length; i++) {
    meters += d(points[i - 1], points[i]);
  }
  if (closeLoop && points.length > 2) {
    meters += d(points.last, points.first);
  }
  return meters;
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
