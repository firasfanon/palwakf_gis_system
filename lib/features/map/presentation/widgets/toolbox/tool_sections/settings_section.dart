// lib/features/map/presentation/widgets/toolbox/tool_sections/settings_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/constants/colors.dart';
import '../../../providers/map_provider.dart';
import '../../../providers/map_ui_providers.dart';
import 'package:kimi/features/map/presentation/providers/toolbox_providers.dart';

class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapNotifierProvider);

    final rasterLayers = mapState.gisLayers.where((l) {
      final type = (l.style['type'] ?? '').toString();
      return type == 'raster_xyz';
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  ref.read(activeToolSectionProvider.notifier).state = null,
            ),
            const Text(
              'الإعدادات',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('الخريطة الأساس',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        _buildBaseMapOption('الخريطة القياسية (OSM)', 'standard', ref),
        _buildBaseMapOption('الخريطة الداكنة (Carto)', 'dark', ref),
        if (rasterLayers.isNotEmpty) const SizedBox(height: 8),
        ...rasterLayers.map((l) => _buildBaseMapOption(l.nameAr, l.key, ref)),
        const Divider(height: 32),
        const Text('إعدادات العرض',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        SwitchListTile(
          title:
              const Text('الوضع الليلي', style: TextStyle(color: Colors.white)),
          subtitle: const Text('تبديل الخريطة القياسية/الداكنة',
              style: TextStyle(color: Colors.white70)),
          value: ref.watch(isDarkModeProvider),
          onChanged: (v) => ref.read(isDarkModeProvider.notifier).state = v,
          activeColor: PwfColors.primaryBlue,
        ),
        SwitchListTile(
          title: const Text('عرض الإحداثيات',
              style: TextStyle(color: Colors.white)),
          subtitle: const Text('إظهار إحداثيات المؤشر',
              style: TextStyle(color: Colors.white70)),
          value: ref.watch(showCoordinatesProvider),
          onChanged: (v) =>
              ref.read(showCoordinatesProvider.notifier).state = v,
          activeColor: PwfColors.primaryBlue,
        ),
        SwitchListTile(
          title: const Text('التجاذب (Snapping)',
              style: TextStyle(color: Colors.white)),
          subtitle: const Text('التقاط للنقاط والخطوط القريبة',
              style: TextStyle(color: Colors.white70)),
          value: ref.watch(snapEnabledProvider),
          onChanged: (v) => ref.read(snapEnabledProvider.notifier).state = v,
          activeColor: PwfColors.primaryBlue,
        ),
      ],
    );
  }

  Widget _buildBaseMapOption(String title, String value, WidgetRef ref) {
    final current = ref.watch(baseMapProvider);
    final isSelected = current == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? PwfColors.primaryBlue.withValues(alpha: 0.18)
            : const Color(0xFF111827),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isSelected ? PwfColors.primaryBlue : Colors.white12),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        leading: Radio<String>(
          value: value,
          groupValue: current,
          onChanged: (v) => ref.read(baseMapProvider.notifier).state = v!,
          activeColor: PwfColors.primaryGold,
        ),
        onTap: () => ref.read(baseMapProvider.notifier).state = value,
        dense: true,
      ),
    );
  }
}
