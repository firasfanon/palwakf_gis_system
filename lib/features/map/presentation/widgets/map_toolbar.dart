// lib/features/map/presentation/widgets/map_toolbar.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class MapToolbar extends StatelessWidget {
  const MapToolbar({
    super.key,
    this.onLayers,
    this.onBasemap,
    this.onMeasure,
    this.onDraw,
    this.onLocate,
    this.onCompare,
    this.onShare,
    this.onExport,
  });

  final VoidCallback? onLayers;
  final VoidCallback? onBasemap;
  final VoidCallback? onMeasure;
  final VoidCallback? onDraw;
  final VoidCallback? onLocate;
  final VoidCallback? onCompare;
  final VoidCallback? onShare;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PwfColors.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _ToolbarHeader(),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ToolbarActionChip(
                  icon: Icons.layers_outlined,
                  label: 'الطبقات',
                  onTap: onLayers,
                ),
                _ToolbarActionChip(
                  icon: Icons.map_outlined,
                  label: 'الخريطة الأساس',
                  onTap: onBasemap,
                ),
                _ToolbarActionChip(
                  icon: Icons.straighten,
                  label: 'القياس',
                  onTap: onMeasure,
                ),
                _ToolbarActionChip(
                  icon: Icons.edit_outlined,
                  label: 'الرسم',
                  onTap: onDraw,
                ),
                _ToolbarActionChip(
                  icon: Icons.my_location_outlined,
                  label: 'الموقع',
                  onTap: onLocate,
                ),
                _ToolbarActionChip(
                  icon: Icons.compare_arrows_outlined,
                  label: 'المقارنة',
                  onTap: onCompare,
                ),
                _ToolbarActionChip(
                  icon: Icons.share_outlined,
                  label: 'المشاركة',
                  onTap: onShare,
                ),
                _ToolbarActionChip(
                  icon: Icons.download_outlined,
                  label: 'التصدير',
                  onTap: onExport,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarHeader extends StatelessWidget {
  const _ToolbarHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: PwfColors.primaryBlue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.space_dashboard_outlined,
            color: PwfColors.primaryBlue,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'شريط الأدوات',
            style: TextStyle(
              color: PwfColors.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolbarActionChip extends StatelessWidget {
  const _ToolbarActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: enabled
          ? PwfColors.surfaceVariant.withValues(alpha: 0.80)
          : PwfColors.surfaceVariant.withValues(alpha: 0.50),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: PwfColors.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: enabled
                    ? PwfColors.primaryBlue
                    : PwfColors.onSurface.withValues(alpha: 0.40),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: enabled
                      ? PwfColors.onSurface
                      : PwfColors.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
