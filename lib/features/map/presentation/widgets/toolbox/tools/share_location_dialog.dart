import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../../core/constants/colors.dart';
import '../../../providers/map_provider.dart';
import '../../../providers/map_ui_providers.dart';

class ShareLocationPanel extends ConsumerStatefulWidget {
  const ShareLocationPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<ShareLocationPanel> createState() => _ShareLocationPanelState();
}

enum _ShareTarget { center, marker, route }

class _ShareLocationPanelState extends ConsumerState<ShareLocationPanel> {
  _ShareTarget? _target;
  String? _lastCopied;

  @override
  Widget build(BuildContext context) {
    final mapController = ref.read(mapControllerProvider);
    final center = mapController.camera.center;
    final zoom = mapController.camera.zoom;
    final gotoMarker = ref.watch(gotoMarkerProvider);
    final lastTap = ref.watch(lastTapLatLngProvider);
    final routeStart = ref.watch(directionsStartProvider);
    final routeEnd = ref.watch(directionsEndProvider);
    final mapState = ref.watch(mapNotifierProvider);

    final markerPoint = gotoMarker ?? lastTap;
    final hasRoute = routeStart != null && routeEnd != null;
    final fallbackTarget = hasRoute
        ? _ShareTarget.route
        : (markerPoint != null ? _ShareTarget.marker : _ShareTarget.center);
    final activeTarget = _resolveTarget(
      requested: _target,
      hasMarker: markerPoint != null,
      hasRoute: hasRoute,
      fallback: fallbackTarget,
    );

    final payload = _buildPayload(
      target: activeTarget,
      center: center,
      zoom: zoom,
      markerPoint: markerPoint,
      routeStart: routeStart,
      routeEnd: routeEnd,
      selectedFeatureTitle: _selectedFeatureTitle(mapState),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _PanelHeader(
          title: 'مشاركة الموقع',
          subtitle:
              'انسخ رابطًا أو إحداثيات حسب مركز الخريطة أو النقطة المحددة أو المسار الحالي.',
          icon: Icons.share_location_outlined,
          onClose: widget.onClose,
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          active: activeTarget,
          hasMarker: markerPoint != null,
          hasRoute: hasRoute,
          onSelect: (target) => setState(() => _target = target),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PwfColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: payload.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(payload.icon, color: payload.accent, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payload.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: PwfColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          payload.subtitle,
                          style: TextStyle(
                            color: PwfColors.onSurface.withValues(alpha: 0.68),
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: payload.chips
                    .map((chip) => _InfoChip(label: chip))
                    .toList(),
              ),
              if (payload.note != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PwfColors.outline),
                  ),
                  child: Text(
                    payload.note!,
                    style: TextStyle(
                      color: PwfColors.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _Box(
                title: 'رابط المشاركة',
                child: SelectableText(
                  payload.link,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.55,
                      color: PwfColors.onSurface),
                ),
              ),
              const SizedBox(height: 10),
              _Box(
                title: activeTarget == _ShareTarget.route
                    ? 'بيانات المسار'
                    : 'الإحداثيات',
                child: SelectableText(
                  payload.coordinatesText,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.55,
                      color: PwfColors.onSurface),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PrimaryBtn(
                      label: _lastCopied == 'link'
                          ? 'تم نسخ الرابط'
                          : 'نسخ الرابط',
                      icon: _lastCopied == 'link'
                          ? Icons.check
                          : Icons.copy_outlined,
                      onTap: () =>
                          _copy('link', payload.link, 'تم نسخ رابط المشاركة'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SecondaryBtn(
                      label: _lastCopied == 'coords'
                          ? 'تم نسخ الإحداثيات'
                          : 'نسخ الإحداثيات',
                      icon: _lastCopied == 'coords'
                          ? Icons.check
                          : Icons.gps_fixed,
                      onTap: () => _copy(
                          'coords', payload.coordinatesText, 'تم نسخ البيانات'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SecondaryBtn(
                      label: _lastCopied == 'summary'
                          ? 'تم نسخ الملخص'
                          : 'نسخ الملخص',
                      icon: _lastCopied == 'summary'
                          ? Icons.check
                          : Icons.short_text,
                      onTap: () => _copy('summary', payload.summaryText,
                          'تم نسخ ملخص المشاركة'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SecondaryBtn(
                      label: 'إغلاق',
                      icon: Icons.close,
                      onTap: widget.onClose,
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

  _ShareTarget _resolveTarget({
    required _ShareTarget? requested,
    required bool hasMarker,
    required bool hasRoute,
    required _ShareTarget fallback,
  }) {
    if (requested == null) return fallback;
    if (requested == _ShareTarget.marker && !hasMarker) return fallback;
    if (requested == _ShareTarget.route && !hasRoute) return fallback;
    return requested;
  }

  String? _selectedFeatureTitle(MapState state) {
    final feature = state.selectedFeature;
    if (feature != null) {
      return feature.titleAr ?? feature.titleEn ?? feature.layerKey;
    }
    final waqf = state.selectedWaqf;
    if (waqf != null) {
      return waqf.name ?? waqf.pwfKey;
    }
    return null;
  }

  _SharePayload _buildPayload({
    required _ShareTarget target,
    required LatLng center,
    required double zoom,
    required LatLng? markerPoint,
    required LatLng? routeStart,
    required LatLng? routeEnd,
    required String? selectedFeatureTitle,
  }) {
    switch (target) {
      case _ShareTarget.route:
        final start = routeStart!;
        final end = routeEnd!;
        final mid = LatLng(
          (start.latitude + end.latitude) / 2,
          (start.longitude + end.longitude) / 2,
        );
        final distanceKm =
            const Distance().as(LengthUnit.Kilometer, start, end);
        final link = _buildLink(
          center: mid,
          zoom: zoom,
          extras: {
            'aLat': start.latitude.toStringAsFixed(6),
            'aLng': start.longitude.toStringAsFixed(6),
            'bLat': end.latitude.toStringAsFixed(6),
            'bLng': end.longitude.toStringAsFixed(6),
            'mode': 'route',
          },
        );
        final coords =
            'A: ${start.latitude.toStringAsFixed(6)}, ${start.longitude.toStringAsFixed(6)}\n'
            'B: ${end.latitude.toStringAsFixed(6)}, ${end.longitude.toStringAsFixed(6)}\n'
            'DistanceKm: ${distanceKm.toStringAsFixed(2)}';
        return _SharePayload(
          title: 'مشاركة المسار الحالي',
          subtitle: 'يركّز الرابط على منتصف المسار ويضم بيانات A وB الحالية.',
          icon: Icons.alt_route,
          accent: PwfColors.success,
          chips: [
            'A ${start.latitude.toStringAsFixed(4)}, ${start.longitude.toStringAsFixed(4)}',
            'B ${end.latitude.toStringAsFixed(4)}, ${end.longitude.toStringAsFixed(4)}',
            distanceKm >= 1
                ? 'المسافة ${distanceKm.toStringAsFixed(2)} كم'
                : 'المسافة ${(distanceKm * 1000).toStringAsFixed(0)} م',
          ],
          note:
              'هذا هو المسار المباشر الحالي داخل الأداة، وليس routing شبكيًا فعليًا.',
          link: link,
          coordinatesText: coords,
          summaryText: 'مشاركة مسار مباشر بين نقطتين\n$coords',
        );
      case _ShareTarget.marker:
        final point = markerPoint!;
        final source = selectedFeatureTitle != null
            ? 'العنصر المحدد: $selectedFeatureTitle'
            : (ref.read(gotoMarkerProvider) != null
                ? 'علامة الإحداثيات الحالية'
                : 'آخر نقرة على الخريطة');
        final link = _buildLink(
          center: point,
          zoom: zoom,
          extras: {
            'markerLat': point.latitude.toStringAsFixed(6),
            'markerLng': point.longitude.toStringAsFixed(6),
            'mode': 'marker',
          },
        );
        final coords =
            '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
        return _SharePayload(
          title: 'مشاركة النقطة المحددة',
          subtitle:
              'ينقل الرابط المستلم مباشرة إلى النقطة الحالية على الخريطة.',
          icon: Icons.location_on,
          accent: PwfColors.royalRed,
          chips: [
            'Lat ${point.latitude.toStringAsFixed(5)}',
            'Lng ${point.longitude.toStringAsFixed(5)}',
            source,
          ],
          note: selectedFeatureTitle == null
              ? null
              : 'تم ربط المشاركة بالعنصر المحدد حاليًا على الخريطة.',
          link: link,
          coordinatesText: coords,
          summaryText: 'مشاركة نقطة محددة\n$source\n$coords',
        );
      case _ShareTarget.center:
        final link = _buildLink(
            center: center, zoom: zoom, extras: const {'mode': 'center'});
        final coords =
            '${center.latitude.toStringAsFixed(6)}, ${center.longitude.toStringAsFixed(6)}';
        return _SharePayload(
          title: 'مشاركة مركز الخريطة',
          subtitle:
              'أنسب خيار لمشاركة نفس المشهد الحالي ومستوى التكبير الحالي.',
          icon: Icons.center_focus_strong,
          accent: PwfColors.primaryBlue,
          chips: [
            'Lat ${center.latitude.toStringAsFixed(5)}',
            'Lng ${center.longitude.toStringAsFixed(5)}',
            'Zoom ${zoom.toStringAsFixed(1)}',
          ],
          note:
              'هذا الخيار يركز على مركز العرض الحالي دون ربطه بعلامة أو مسار.',
          link: link,
          coordinatesText: coords,
          summaryText:
              'مشاركة مركز الخريطة\n$coords\nZoom ${zoom.toStringAsFixed(1)}',
        );
    }
  }

  String _buildLink({
    required LatLng center,
    required double zoom,
    Map<String, String> extras = const {},
  }) {
    final base = _mapBaseUrl();
    final params = <String, String>{
      'lat': center.latitude.toStringAsFixed(6),
      'lng': center.longitude.toStringAsFixed(6),
      'z': zoom.toStringAsFixed(2),
      ...extras,
    };
    final query = params.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$base?$query';
  }

  String _mapBaseUrl() {
    final base = Uri.base;
    if (base.hasAuthority) {
      return '${base.scheme}://${base.authority}/#/map';
    }
    return '/#/map';
  }

  void _copy(String key, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _lastCopied = key);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SharePayload {
  const _SharePayload({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.chips,
    required this.link,
    required this.coordinatesText,
    required this.summaryText,
    this.note,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<String> chips;
  final String? note;
  final String link;
  final String coordinatesText;
  final String summaryText;
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.active,
    required this.hasMarker,
    required this.hasRoute,
    required this.onSelect,
  });

  final _ShareTarget active;
  final bool hasMarker;
  final bool hasRoute;
  final ValueChanged<_ShareTarget> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختر ما تريد مشاركته',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: PwfColors.royalRed),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TargetChip(
                label: 'مركز الخريطة',
                icon: Icons.center_focus_strong,
                selected: active == _ShareTarget.center,
                enabled: true,
                onTap: () => onSelect(_ShareTarget.center),
              ),
              _TargetChip(
                label: 'النقطة المحددة',
                icon: Icons.location_on_outlined,
                selected: active == _ShareTarget.marker,
                enabled: hasMarker,
                onTap: hasMarker ? () => onSelect(_ShareTarget.marker) : null,
              ),
              _TargetChip(
                label: 'المسار A/B',
                icon: Icons.alt_route,
                selected: active == _ShareTarget.route,
                enabled: hasRoute,
                onTap: hasRoute ? () => onSelect(_ShareTarget.route) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = !enabled
        ? PwfColors.onSurface.withValues(alpha: 0.38)
        : (selected ? PwfColors.royalRed : PwfColors.onSurface);
    final bg = !enabled
        ? Colors.white
        : (selected
            ? PwfColors.royalRed.withValues(alpha: 0.10)
            : Colors.white);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? PwfColors.royalRed : PwfColors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(fontWeight: FontWeight.w800, color: fg)),
          ],
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PwfColors.royalRed.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: PwfColors.royalRed),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: PwfColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: PwfColors.onSurface.withValues(alpha: 0.66),
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: PwfColors.onSurface)),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: PwfColors.royalRed,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn(
      {required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: PwfColors.royalRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  const _SecondaryBtn(
      {required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: PwfColors.onSurface,
          side: const BorderSide(color: PwfColors.outline),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}
