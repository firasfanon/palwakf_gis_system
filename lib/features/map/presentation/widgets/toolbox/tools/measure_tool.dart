import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../../../core/constants/colors.dart';
import '../../../providers/map_ui_providers.dart';

class MeasureToolPanel extends ConsumerStatefulWidget {
  const MeasureToolPanel({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  ConsumerState<MeasureToolPanel> createState() => _MeasureToolPanelState();
}

class _MeasureToolPanelState extends ConsumerState<MeasureToolPanel> {
  MeasureMode _type = MeasureMode.distance;

  String? _labelFor(List<LatLng> points, MeasureMode mode) {
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
    final avgLat =
        points.map((e) => e.latitude).reduce((a, b) => a + b) / points.length;
    const metersPerDegLat = 111320.0;
    final metersPerDegLng = 111320.0 * math.cos(avgLat * math.pi / 180.0);
    double area = 0;
    for (var i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      final xi = points[i].longitude * metersPerDegLng;
      final yi = points[i].latitude * metersPerDegLat;
      final xj = points[j].longitude * metersPerDegLng;
      final yj = points[j].latitude * metersPerDegLat;
      area += xi * yj - xj * yi;
    }
    final sqm = area.abs() / 2.0;
    final dunums = sqm / 1000.0;
    return dunums >= 1
        ? 'المساحة: ${dunums.toStringAsFixed(2)} دونم'
        : 'المساحة: ${sqm.toStringAsFixed(1)} م²';
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(measureModeProvider);
    final editing = ref.watch(measureEditingProvider);
    final result = ref.watch(measureResultLabelProvider);
    final points = ref.watch(measurePointsProvider);
    final measuring = mode != null;
    final activeType = mode ?? _type;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _Header(title: 'القياس', onClose: widget.onClose),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardTitle('نوع القياس'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SegBtn(
                      label: 'المسافة',
                      icon: Icons.straighten,
                      active: activeType == MeasureMode.distance,
                      onTap: () => setState(() => _type = MeasureMode.distance),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SegBtn(
                      label: 'المساحة',
                      icon: Icons.square_foot,
                      active: activeType == MeasureMode.area,
                      onTap: () => setState(() => _type = MeasureMode.area),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PwfColors.outline),
                ),
                child: Text(
                  !measuring
                      ? 'اختر نوع القياس ثم اضغط "ابدأ القياس". بعد ذلك انقر على الخريطة لإضافة النقاط.'
                      : editing
                          ? 'القياس نشط الآن. ${activeType == MeasureMode.distance ? "أضف نقطتين أو أكثر لحساب المسافة، ثم اضغط إنهاء عند الاكتمال." : "أضف 3 نقاط أو أكثر لحساب المساحة، ثم اضغط إنهاء لإغلاق المضلع."}'
                          : 'تم إيقاف الالتقاط. يمكنك استئناف القياس أو مسح النتائج أو الخروج من الوضع.',
                  style: TextStyle(
                    color: PwfColors.onSurface.withValues(alpha: 0.72),
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (result != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PwfColors.royalRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: PwfColors.royalRed.withValues(alpha: 0.22)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        editing ? 'النتيجة الحالية' : 'النتيجة النهائية',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: PwfColors.royalRed),
                      ),
                      const SizedBox(height: 6),
                      Text(result,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                        'عدد النقاط: ${points.length}',
                        style: TextStyle(
                            color: PwfColors.onSurface.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(drawEditingProvider.notifier).state = false;
                          ref.read(drawShapeTypeProvider.notifier).state = null;
                          ref.read(drawPointsProvider.notifier).state =
                              const [];
                          ref
                              .read(directionsPickTargetProvider.notifier)
                              .state = null;
                          ref.read(measurePointsProvider.notifier).state =
                              const [];
                          ref.read(measureResultLabelProvider.notifier).state =
                              null;
                          ref.read(measureModeProvider.notifier).state = _type;
                          ref.read(measureEditingProvider.notifier).state =
                              true;
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PwfColors.royalRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(measuring ? Icons.replay : Icons.play_arrow),
                        label: Text(
                          measuring ? 'إعادة البدء' : 'ابدأ القياس',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: measuring && editing
                            ? () => ref
                                .read(measureEditingProvider.notifier)
                                .state = false
                            : measuring && !editing
                                ? () => ref
                                    .read(measureEditingProvider.notifier)
                                    .state = true
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF64748B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(editing
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline),
                        label: Text(
                          editing ? 'إنهاء' : 'استئناف',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: points.isEmpty
                            ? null
                            : () {
                                final next = [...points]..removeLast();
                                ref.read(measurePointsProvider.notifier).state =
                                    next;
                                final activeMode =
                                    ref.read(measureModeProvider) ?? _type;
                                ref
                                    .read(measureResultLabelProvider.notifier)
                                    .state = _labelFor(next, activeMode);
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PwfColors.onSurface,
                          side: const BorderSide(color: PwfColors.outline),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.undo),
                        label: const Text('تراجع',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: points.isEmpty && !measuring
                            ? null
                            : () {
                                ref.read(measurePointsProvider.notifier).state =
                                    const [];
                                ref
                                    .read(measureResultLabelProvider.notifier)
                                    .state = null;
                                ref
                                    .read(measureEditingProvider.notifier)
                                    .state = false;
                                ref.read(measureModeProvider.notifier).state =
                                    null;
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PwfColors.onSurface,
                          side: const BorderSide(color: PwfColors.outline),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('مسح / خروج',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onClose});
  final String title;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            color: PwfColors.royalRed, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900))),
          IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.white)),
        ]),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PwfColors.outline),
        ),
        child: child,
      );
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Row(children: [
        const Icon(Icons.straighten, color: PwfColors.royalRed, size: 18),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: PwfColors.royalRed)),
      ]);
}

class _SegBtn extends StatelessWidget {
  const _SegBtn(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: active
              ? PwfColors.royalRed.withValues(alpha: 0.10)
              : Colors.white,
          foregroundColor: PwfColors.onSurface,
          side: BorderSide(
              color: active
                  ? PwfColors.royalRed.withValues(alpha: 0.35)
                  : PwfColors.outline),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        icon: Icon(icon,
            size: 18,
            color: active
                ? PwfColors.royalRed
                : PwfColors.onSurface.withValues(alpha: 0.7)),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      );
}
