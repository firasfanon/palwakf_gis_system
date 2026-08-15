import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../../core/constants/colors.dart';
import '../../../providers/map_provider.dart';
import '../../../providers/map_ui_providers.dart';
import '../../../providers/toolbox_providers.dart';

class DirectionsToolPanel extends ConsumerWidget {
  const DirectionsToolPanel({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = ref.watch(directionsStartProvider);
    final end = ref.watch(directionsEndProvider);
    final pickTarget = ref.watch(directionsPickTargetProvider);
    final lastTap = ref.watch(lastTapLatLngProvider);

    final distanceKm = (start != null && end != null)
        ? const Distance().as(LengthUnit.Kilometer, start, end)
        : null;

    String formatPoint(LatLng? p) {
      if (p == null) return 'غير محددة';
      return '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
    }

    void clearAll() {
      ref.read(directionsStartProvider.notifier).state = null;
      ref.read(directionsEndProvider.notifier).state = null;
      ref.read(directionsPickTargetProvider.notifier).state = null;
    }

    void openPick(String target) {
      ref.read(drawEditingProvider.notifier).state = false;
      ref.read(drawShapeTypeProvider.notifier).state = null;
      ref.read(drawPointsProvider.notifier).state = const [];
      ref.read(measureEditingProvider.notifier).state = false;
      ref.read(measureModeProvider.notifier).state = null;
      ref.read(measurePointsProvider.notifier).state = const [];
      ref.read(measureResultLabelProvider.notifier).state = null;
      ref.read(directionsPickTargetProvider.notifier).state = target;
    }

    void useCenterFor(String target) {
      final c = ref.read(mapControllerProvider).camera.center;
      if (target == 'start') {
        ref.read(directionsStartProvider.notifier).state = c;
      } else {
        ref.read(directionsEndProvider.notifier).state = c;
      }
      ref.read(directionsPickTargetProvider.notifier).state = null;
    }

    void useLastTapFor(String target) {
      if (lastTap == null) return;
      if (target == 'start') {
        ref.read(directionsStartProvider.notifier).state = lastTap;
      } else {
        ref.read(directionsEndProvider.notifier).state = lastTap;
      }
      ref.read(directionsPickTargetProvider.notifier).state = null;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _Header(title: 'الاتجاهات والملاحة', onClose: onClose),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle('المسار المباشر A → B'),
              const SizedBox(height: 10),
              Text(
                pickTarget == null
                    ? 'حدد نقطة البداية ونقطة الوصول من الخريطة أو من مركز العرض الحالي، وسيظهر المسار المباشر بينهما.'
                    : 'وضع الالتقاط نشط الآن: ${pickTarget == 'start' ? 'انقر على الخريطة لتحديد A' : 'انقر على الخريطة لتحديد B'}',
                style: TextStyle(
                  color: PwfColors.onSurface.withValues(alpha: 0.72),
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _PointBox(
                title: 'A — نقطة البداية',
                value: formatPoint(start),
                active: pickTarget == 'start',
                onPick: () => openPick('start'),
                onUseCenter: () => useCenterFor('start'),
                onUseLastTap:
                    lastTap == null ? null : () => useLastTapFor('start'),
                onClear: start == null
                    ? null
                    : () =>
                        ref.read(directionsStartProvider.notifier).state = null,
              ),
              const SizedBox(height: 10),
              _PointBox(
                title: 'B — نقطة الوصول',
                value: formatPoint(end),
                active: pickTarget == 'end',
                onPick: () => openPick('end'),
                onUseCenter: () => useCenterFor('end'),
                onUseLastTap:
                    lastTap == null ? null : () => useLastTapFor('end'),
                onClear: end == null
                    ? null
                    : () =>
                        ref.read(directionsEndProvider.notifier).state = null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: (start != null && end != null)
                            ? () {
                                ref
                                    .read(directionsStartProvider.notifier)
                                    .state = end;
                                ref.read(directionsEndProvider.notifier).state =
                                    start;
                              }
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PwfColors.onSurface,
                          side: const BorderSide(color: PwfColors.outline),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('تبديل A/B',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: clearAll,
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
              if (distanceKm != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
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
                        'نتيجة المسار الحالي',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: PwfColors.primaryBlue),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        distanceKm >= 1
                            ? 'المسافة التقريبية: ${distanceKm.toStringAsFixed(2)} كم'
                            : 'المسافة التقريبية: ${(distanceKm * 1000).toStringAsFixed(0)} م',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: (start != null && end != null)
                            ? () {
                                final map = ref.read(mapControllerProvider);
                                final mid = LatLng(
                                  (start.latitude + end.latitude) / 2,
                                  (start.longitude + end.longitude) / 2,
                                );
                                map.move(
                                    mid,
                                    map.camera.zoom < 13
                                        ? 13
                                        : map.camera.zoom);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PwfColors.royalRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.alt_route),
                        label: const Text('اعرض المسار',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(directionsPickTargetProvider.notifier)
                              .state = null;
                          ref.read(activeToolsSubPanelProvider.notifier).state =
                              null;
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PwfColors.onSurface,
                          side: const BorderSide(color: PwfColors.outline),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('خروج',
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
  Widget build(BuildContext context) => Row(
        children: [
          const Icon(Icons.alt_route, color: PwfColors.royalRed, size: 18),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: PwfColors.royalRed)),
        ],
      );
}

class _PointBox extends StatelessWidget {
  const _PointBox({
    required this.title,
    required this.value,
    required this.active,
    required this.onPick,
    required this.onUseCenter,
    required this.onUseLastTap,
    required this.onClear,
  });

  final String title;
  final String value;
  final bool active;
  final VoidCallback onPick;
  final VoidCallback onUseCenter;
  final VoidCallback? onUseLastTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active
                  ? PwfColors.royalRed.withValues(alpha: 0.35)
                  : PwfColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: PwfColors.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniBtn(
                    label: 'اختر من الخريطة',
                    icon: Icons.location_on_outlined,
                    primary: active,
                    onTap: onPick),
                _MiniBtn(
                    label: 'استخدم المركز',
                    icon: Icons.my_location,
                    onTap: onUseCenter),
                _MiniBtn(
                    label: 'آخر نقرة',
                    icon: Icons.touch_app,
                    onTap: onUseLastTap),
                _MiniBtn(
                    label: 'مسح', icon: Icons.delete_outline, onTap: onClear),
              ],
            ),
          ],
        ),
      );
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.primary = false});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: primary
              ? PwfColors.royalRed.withValues(alpha: 0.08)
              : Colors.white,
          foregroundColor: PwfColors.onSurface,
          side: BorderSide(
              color: primary
                  ? PwfColors.royalRed.withValues(alpha: 0.25)
                  : PwfColors.outline),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon,
            size: 16,
            color: primary
                ? PwfColors.royalRed
                : PwfColors.onSurface.withValues(alpha: 0.72)),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      );
}
