import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/constants/colors.dart';
import '../../../providers/map_ui_providers.dart';

class DrawToolPanel extends ConsumerWidget {
  const DrawToolPanel({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shape = ref.watch(drawShapeTypeProvider);
    final editing = ref.watch(drawEditingProvider);
    final points = ref.watch(drawPointsProvider);
    final summary = ref.watch(drawSummaryLabelProvider);

    void selectShape(String nextShape) {
      final current = ref.read(drawShapeTypeProvider);
      if (current == nextShape) return;
      ref.read(drawShapeTypeProvider.notifier).state = nextShape;
      ref.read(drawPointsProvider.notifier).state = const [];
      ref.read(drawEditingProvider.notifier).state = false;
    }

    void exitDrawMode() {
      ref.read(drawEditingProvider.notifier).state = false;
      ref.read(drawShapeTypeProvider.notifier).state = null;
      ref.read(drawPointsProvider.notifier).state = const [];
      onClose();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _Header(title: 'أدوات الرسم', onClose: onClose),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardTitle('نوع الرسم'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ToolBtn(
                      label: 'نقطة',
                      icon: Icons.place_outlined,
                      active: shape == 'point',
                      onTap: () => selectShape('point')),
                  _ToolBtn(
                      label: 'خط',
                      icon: Icons.timeline,
                      active: shape == 'line',
                      onTap: () => selectShape('line')),
                  _ToolBtn(
                      label: 'مضلع',
                      icon: Icons.pentagon_outlined,
                      active: shape == 'polygon',
                      onTap: () => selectShape('polygon')),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PwfColors.outline),
                ),
                child: Text(
                  shape == null
                      ? 'اختر نوع الرسم أولًا، ثم اضغط "ابدأ الرسم" وبعدها انقر على الخريطة لإضافة النقاط.'
                      : editing
                          ? 'الرسم نشط الآن. انقر على الخريطة لإضافة نقاط جديدة. يمكنك الإنهاء مؤقتًا مع إبقاء الشكل ظاهرًا.'
                          : 'تم اختيار ${_shapeLabel(shape)}. ${points.isEmpty ? 'اضغط "ابدأ الرسم" لبدء الالتقاط.' : 'يمكنك الاستئناف أو مسح الشكل الحالي.'}',
                  style: TextStyle(
                      color: PwfColors.onSurface.withValues(alpha: 0.72),
                      height: 1.5,
                      fontWeight: FontWeight.w700),
                ),
              ),
              if (summary != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PwfColors.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: PwfColors.primaryBlue.withValues(alpha: 0.18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ملخص الرسم',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: PwfColors.primaryBlue),
                      ),
                      const SizedBox(height: 6),
                      Text(summary,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        'عدد النقاط: ${points.length}',
                        style: TextStyle(
                            color: PwfColors.onSurface.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: shape == null
                            ? null
                            : () {
                                ref.read(measureModeProvider.notifier).state =
                                    null;
                                ref
                                    .read(measureEditingProvider.notifier)
                                    .state = false;
                                ref.read(measurePointsProvider.notifier).state =
                                    const [];
                                ref
                                    .read(measureResultLabelProvider.notifier)
                                    .state = null;
                                ref
                                    .read(directionsPickTargetProvider.notifier)
                                    .state = null;
                                ref.read(drawEditingProvider.notifier).state =
                                    true;
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PwfColors.royalRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(editing
                            ? Icons.play_circle_fill
                            : Icons.play_arrow),
                        label: Text(editing ? 'الرسم نشط' : 'ابدأ الرسم',
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: shape == null
                            ? null
                            : editing
                                ? () => ref
                                    .read(drawEditingProvider.notifier)
                                    .state = false
                                : points.isNotEmpty
                                    ? () => ref
                                        .read(drawEditingProvider.notifier)
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
                        label: Text(editing ? 'إنهاء' : 'استئناف',
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
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
                                ref.read(drawPointsProvider.notifier).state =
                                    next;
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
                        onPressed: points.isEmpty
                            ? null
                            : () {
                                ref.read(drawPointsProvider.notifier).state =
                                    const [];
                                ref.read(drawEditingProvider.notifier).state =
                                    false;
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PwfColors.onSurface,
                          side: const BorderSide(color: PwfColors.outline),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('مسح',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 46,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: points.isEmpty || shape == null
                      ? null
                      : () async {
                          final payload = _toGeoJson(shape, points);
                          await Clipboard.setData(
                              ClipboardData(text: jsonEncode(payload)));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('تم نسخ الرسم بصيغة GeoJSON')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PwfColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.copy_all),
                  label: const Text('نسخ / تصدير GeoJSON',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: exitDrawMode,
                  style: TextButton.styleFrom(
                      foregroundColor:
                          PwfColors.onSurface.withValues(alpha: 0.78)),
                  icon: const Icon(Icons.close),
                  label: const Text('خروج من وضع الرسم',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _shapeLabel(String? shape) {
  switch (shape) {
    case 'point':
      return 'رسم النقاط';
    case 'line':
      return 'رسم الخط';
    case 'polygon':
      return 'رسم المضلع';
    default:
      return 'الرسم';
  }
}

Map<String, dynamic> _toGeoJson(String shape, List<dynamic> points) {
  List<List<double>> coords() => [
        for (final p in points) [p.longitude as double, p.latitude as double],
      ];

  switch (shape) {
    case 'point':
      return {
        'type': 'FeatureCollection',
        'features': [
          for (final p in points)
            {
              'type': 'Feature',
              'geometry': {
                'type': 'Point',
                'coordinates': [p.longitude, p.latitude],
              },
              'properties': {},
            },
        ],
      };
    case 'line':
      return {
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': coords(),
        },
        'properties': {},
      };
    case 'polygon':
      final ring = coords();
      if (ring.isNotEmpty) {
        ring.add(List<double>.from(ring.first));
      }
      return {
        'type': 'Feature',
        'geometry': {
          'type': 'Polygon',
          'coordinates': [ring],
        },
        'properties': {},
      };
    default:
      return {'type': 'FeatureCollection', 'features': []};
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
        child: Row(
          children: [
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900))),
            IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white)),
          ],
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PwfColors.outline),
        ),
        child: child,
      );
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: PwfColors.onSurface),
      );
}

class _ToolBtn extends StatelessWidget {
  const _ToolBtn(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? PwfColors.primaryBlue.withValues(alpha: 0.10)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: active ? PwfColors.primaryBlue : PwfColors.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18,
                  color: active ? PwfColors.primaryBlue : PwfColors.onSurface),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: active ? PwfColors.primaryBlue : PwfColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
}
