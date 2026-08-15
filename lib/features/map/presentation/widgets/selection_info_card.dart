import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/colors.dart';
import '../../domain/models/gis_feature_model.dart';
import '../../domain/models/waqf_model.dart';
import '../providers/map_provider.dart';

class SelectedWaqfInfoCard extends ConsumerWidget {
  const SelectedWaqfInfoCard({super.key, required this.waqf});

  final WaqfModel waqf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = _extractCoordinates(waqf.geometry);
    return Positioned(
      left: 16,
      right: 16,
      bottom: 92,
      child: Align(
        alignment: Alignment.bottomRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: waqf.status.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.account_balance,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              waqf.name ?? waqf.pwfKey,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              waqf.name == null ? 'أصل وقفي' : waqf.pwfKey,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    PwfColors.onSurface.withValues(alpha: 0.68),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'إغلاق',
                        onPressed: () => ref
                            .read(mapNotifierProvider.notifier)
                            .clearSelection(),
                        icon: Icon(Icons.close,
                            color: PwfColors.onSurface.withValues(alpha: 0.72)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                          label: waqf.type.arLabel,
                          icon: Icons.category_outlined),
                      _InfoChip(
                          label: waqf.status.arLabel,
                          icon: Icons.flag_outlined),
                      if (waqf.area != null)
                        _InfoChip(
                            label: '${waqf.area!.toStringAsFixed(1)} م²',
                            icon: Icons.square_foot),
                    ],
                  ),
                  if ((waqf.governorate ??
                          waqf.municipality ??
                          waqf.community) !=
                      null) ...[
                    const SizedBox(height: 10),
                    Text(
                      [waqf.governorate, waqf.municipality, waqf.community]
                          .whereType<String>()
                          .where((e) => e.trim().isNotEmpty)
                          .join(' • '),
                      style: TextStyle(
                        color: PwfColors.onSurface.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.my_location_outlined,
                          label: 'تمركز',
                          onTap: center == null
                              ? null
                              : () => _focusOn(context, ref, center),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.content_copy_outlined,
                          label: 'نسخ الإحداثيات',
                          onTap: center == null
                              ? null
                              : () => _copyCoords(context, center),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.open_in_new_outlined,
                          label: 'فتح التفاصيل',
                          onTap: () => context.go('/waqf/${waqf.id}'),
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
    );
  }
}

class SelectedFeatureInfoCard extends ConsumerWidget {
  const SelectedFeatureInfoCard({
    super.key,
    required this.feature,
    required this.layerName,
  });

  final GisFeatureModel feature;
  final String layerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = _extractCoordinates(feature.centroid ?? feature.geom);
    final preview = feature.previewEntries;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 92,
      child: Align(
        alignment: Alignment.bottomRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: PwfColors.primaryGold.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: PwfColors.primaryBlue, width: 2),
                        ),
                        child: const Icon(Icons.layers_outlined,
                            color: Colors.black87),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              layerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    PwfColors.onSurface.withValues(alpha: 0.68),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'إغلاق',
                        onPressed: () => ref
                            .read(mapNotifierProvider.notifier)
                            .clearSelection(),
                        icon: Icon(Icons.close,
                            color: PwfColors.onSurface.withValues(alpha: 0.72)),
                      ),
                    ],
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in preview)
                          _InfoChip(
                              label: '${item.key}: ${item.value}',
                              icon: Icons.info_outline,
                              compact: true),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.my_location_outlined,
                          label: 'تمركز',
                          onTap: center == null
                              ? null
                              : () => _focusOn(context, ref, center),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.content_copy_outlined,
                          label: 'نسخ الإحداثيات',
                          onTap: center == null
                              ? null
                              : () => _copyCoords(context, center),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.article_outlined,
                          label: 'عرض الخصائص',
                          onTap: () =>
                              _showPropsDialog(context, feature, layerName),
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
    );
  }

  void _showPropsDialog(
      BuildContext context, GisFeatureModel feature, String layerName) {
    final props = feature.detailEntries;
    showDialog<void>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(feature.displayTitle),
              const SizedBox(height: 4),
              Text(
                layerName,
                style: TextStyle(
                    fontSize: 12,
                    color: PwfColors.onSurface.withValues(alpha: 0.68)),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: props.isEmpty
                ? const Text('لا توجد خصائص متاحة لهذا العنصر.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: props.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = props[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.key,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(item.value),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق')),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.97),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: PwfColors.outline),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.22),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {required this.label, required this.icon, this.compact = false});

  final String label;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12, vertical: compact ? 7 : 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 15, color: PwfColors.primaryBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11.5 : 12,
              fontWeight: FontWeight.w700,
              color: PwfColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: PwfColors.royalRed,
        side: const BorderSide(color: PwfColors.outline),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }
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
      final first = coords[0];
      if (first is List && first.isNotEmpty) {
        final p = first[0];
        if (p is List && p.length >= 2) {
          return LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble());
        }
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<void> _copyCoords(BuildContext context, LatLng point) async {
  await Clipboard.setData(
    ClipboardData(
      text:
          '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
    ),
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('تم نسخ الإحداثيات')),
  );
}

void _focusOn(BuildContext context, WidgetRef ref, LatLng point) {
  ref.read(mapControllerProvider).move(point, 15);
}
