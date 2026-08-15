// lib/features/map/presentation/widgets/layers_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/enums.dart';
import '../../domain/models/gis_layer_model.dart';
import '../providers/map_provider.dart';

class LayersPanel extends ConsumerStatefulWidget {
  const LayersPanel({super.key});

  @override
  ConsumerState<LayersPanel> createState() => _LayersPanelState();
}

class _LayersPanelState extends ConsumerState<LayersPanel> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _activeOnly = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapNotifierProvider);
    final filteredLayers = _filterLayers(
      mapState.gisLayers,
      query: _query,
      activeOnly: _activeOnly,
      activeKeys: mapState.activeLayers.toSet(),
    );
    final grouped = _groupByCategory(filteredLayers);
    final activeCount = mapState.activeLayers.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: 330,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PwfColors.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LayersHeader(
              activeCount: activeCount,
              totalCount: mapState.gisLayers.length,
              filteredCount: filteredLayers.length,
              onRefresh: () =>
                  ref.read(mapNotifierProvider.notifier).bootstrapGis(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _SearchAndFilterBar(
                controller: _searchCtrl,
                query: _query,
                activeOnly: _activeOnly,
                onChanged: (value) => setState(() => _query = value),
                onClear: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
                onToggleActiveOnly: () =>
                    setState(() => _activeOnly = !_activeOnly),
                onReset: () {
                  _searchCtrl.clear();
                  setState(() {
                    _query = '';
                    _activeOnly = false;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            if (mapState.gisLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (mapState.gisError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _ErrorNotice(message: mapState.gisError!),
              )
            else if (filteredLayers.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: _EmptyNotice(
                  hasQuery: _query.trim().isNotEmpty || _activeOnly,
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  children: [
                    for (final entry in grouped.entries)
                      _LayerCategoryCard(
                        category: entry.key,
                        layers: entry.value,
                        activeCount: entry.value
                            .where((layer) =>
                                mapState.activeLayers.contains(layer.key))
                            .length,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<GisLayerModel> _filterLayers(
    List<GisLayerModel> layers, {
    required String query,
    required bool activeOnly,
    required Set<String> activeKeys,
  }) {
    final normalized = query.trim().toLowerCase();

    return layers.where((layer) {
      if (activeOnly && !activeKeys.contains(layer.key)) {
        return false;
      }
      if (normalized.isEmpty) return true;
      final haystack = [
        layer.nameAr,
        layer.nameEn ?? '',
        layer.key,
        layer.category.arLabel,
      ].join(' ').toLowerCase();
      return haystack.contains(normalized);
    }).toList(growable: false);
  }

  Map<LayerCategory, List<GisLayerModel>> _groupByCategory(
      List<GisLayerModel> layers) {
    final ordered = <LayerCategory>[
      LayerCategory.waqf,
      LayerCategory.core,
      LayerCategory.gis,
      LayerCategory.historical,
    ];

    final out = <LayerCategory, List<GisLayerModel>>{};
    for (final category in ordered) {
      out[category] = [];
    }
    for (final layer in layers) {
      out.putIfAbsent(layer.category, () => []).add(layer);
    }
    out.removeWhere((_, value) => value.isEmpty);
    for (final list in out.values) {
      list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    }
    return out;
  }
}

class _LayersHeader extends StatelessWidget {
  const _LayersHeader({
    required this.activeCount,
    required this.totalCount,
    required this.filteredCount,
    required this.onRefresh,
  });

  final int activeCount;
  final int totalCount;
  final int filteredCount;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: PwfColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(
            color: PwfColors.primaryBlue.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: PwfColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.layers_outlined,
                  color: PwfColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'إدارة الطبقات',
                  style: TextStyle(
                    color: PwfColors.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, color: PwfColors.royalRed),
                tooltip: 'تحديث الطبقات',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                icon: Icons.visibility_outlined,
                label: 'المفعلة: $activeCount',
                color: PwfColors.success,
              ),
              _SummaryChip(
                icon: Icons.dashboard_outlined,
                label: 'الإجمالي: $totalCount',
                color: PwfColors.primaryBlue,
              ),
              _SummaryChip(
                icon: Icons.filter_alt_outlined,
                label: 'النتائج: $filteredCount',
                color: PwfColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'الوضع الابتدائي: حدود فلسطين فقط، ثم تُفعّل بقية الطبقات تدريجيًا حسب الحاجة.',
            style: TextStyle(
              color: PwfColors.onSurface.withValues(alpha: 0.66),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.controller,
    required this.query,
    required this.activeOnly,
    required this.onChanged,
    required this.onClear,
    required this.onToggleActiveOnly,
    required this.onReset,
  });

  final TextEditingController controller;
  final String query;
  final bool activeOnly;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onToggleActiveOnly;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PwfColors.outline),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.search, color: PwfColors.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    hintText: 'ابحث باسم الطبقة أو الكود أو الفئة...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (query.trim().isNotEmpty)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'مسح',
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                selected: activeOnly,
                onSelected: (_) => onToggleActiveOnly(),
                selectedColor: PwfColors.primaryGold.withValues(alpha: 0.18),
                label: const Text('المفعلة فقط'),
                avatar: const Icon(Icons.visibility_outlined, size: 18),
                side: BorderSide(color: PwfColors.outline.withValues(alpha: 0.9)),
              ),
              if (query.trim().isNotEmpty || activeOnly)
                ActionChip(
                  onPressed: onReset,
                  avatar: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('إعادة ضبط الفلاتر'),
                  side: BorderSide(
                    color: PwfColors.primaryBlue.withValues(alpha: 0.18),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LayerCategoryCard extends ConsumerWidget {
  const _LayerCategoryCard({
    required this.category,
    required this.layers,
    required this.activeCount,
  });

  final LayerCategory category;
  final List<GisLayerModel> layers;
  final int activeCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: activeCount > 0,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: _colorForCategory(category).withValues(alpha: 0.12),
            child: Icon(
              _iconForCategory(category),
              color: _colorForCategory(category),
              size: 18,
            ),
          ),
          title: Text(
            category.arLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: PwfColors.onSurface,
              fontSize: 14.5,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                _categoryDescription(category),
                style: TextStyle(
                  color: PwfColors.onSurface.withValues(alpha: 0.64),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$activeCount / ${layers.length} مفعّلة',
                style: TextStyle(
                  color: PwfColors.onSurface.withValues(alpha: 0.64),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          children: [
            for (final layer in layers)
              _LayerTile(
                layer: layer,
                isActive:
                    ref.watch(mapNotifierProvider).activeLayers.contains(layer.key),
              ),
          ],
        ),
      ),
    );
  }

  String _categoryDescription(LayerCategory category) {
    switch (category) {
      case LayerCategory.historical:
        return 'طبقات تاريخية ومراجع مقارنة، وتبقى معطلة افتراضيًا هنا.';
      case LayerCategory.waqf:
        return 'طبقات الأصول والمراجع الوقفية المرتبطة بمرحلة العرض الحديثة.';
      case LayerCategory.core:
        return 'الحدود والمرجعيات الأساسية التي تبني عليها الصفحة الحديثة.';
      case LayerCategory.gis:
        return 'طبقات تشغيل GIS الحديثة ومصادر البحث المكانية المساندة.';
    }
  }
}

class _LayerTile extends ConsumerWidget {
  const _LayerTile({
    required this.layer,
    required this.isActive,
  });

  final GisLayerModel layer;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opacity = ref.watch(mapNotifierProvider).layerOpacity[layer.key] ??
        layer.defaultOpacity;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? PwfColors.primaryBlue.withValues(alpha: 0.28)
              : PwfColors.outline,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Switch.adaptive(
                value: isActive,
                activeColor: PwfColors.primaryBlue,
                onChanged: (_) {
                  ref.read(mapNotifierProvider.notifier).toggleLayer(layer.key);
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      layer.nameAr,
                      style: const TextStyle(
                        color: PwfColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if ((layer.key.trim().toLowerCase() == 'natural_blocks_full') ||
                        ((layer.nameEn ?? '').trim().isNotEmpty)) ...[
                      const SizedBox(height: 2),
                      Text(
                        layer.key.trim().toLowerCase() == 'natural_blocks_full'
                            ? 'Natural Blocks Full'
                            : layer.nameEn!.trim(),
                        style: TextStyle(
                          color: PwfColors.onSurface.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniMeta(
                          icon: Icons.category_outlined,
                          label: layer.category.arLabel,
                        ),
                        _MiniMeta(
                          icon: Icons.opacity_outlined,
                          label: 'شفافية ${(opacity * 100).round()}%',
                        ),
                        if (layer.key.trim().toLowerCase() == 'natural_blocks_full')
                          const _MiniMeta(
                            icon: Icons.verified_outlined,
                            label: 'natural_blocks_full',
                          ),
                        if (layer.canCompareVisually)
                          const _MiniMeta(
                            icon: Icons.compare_arrows_outlined,
                            label: 'قابلة للمقارنة',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.opacity, size: 16, color: PwfColors.primaryBlue),
              const SizedBox(width: 8),
              const Text(
                'الشفافية',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          Slider(
            value: opacity,
            min: 0.1,
            max: 1.0,
            onChanged: isActive
                ? (v) => ref
                    .read(mapNotifierProvider.notifier)
                    .setLayerOpacity(layer.key, v)
                : null,
            activeColor: PwfColors.primaryBlue,
            inactiveColor: PwfColors.primaryBlue.withValues(alpha: 0.18),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: PwfColors.surfaceVariant.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: PwfColors.onSurface.withValues(alpha: 0.66)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: PwfColors.onSurface.withValues(alpha: 0.76),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PwfColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PwfColors.error.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: PwfColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: PwfColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotice extends StatelessWidget {
  const _EmptyNotice({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.layers_clear_outlined, color: PwfColors.onSurface),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasQuery
                  ? 'لا توجد طبقات تطابق عوامل التصفية الحالية.'
                  : 'لا توجد طبقات متاحة حاليًا.',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: PwfColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _colorForCategory(LayerCategory category) {
  switch (category) {
    case LayerCategory.waqf:
      return PwfColors.primaryGold;
    case LayerCategory.core:
      return PwfColors.primaryBlue;
    case LayerCategory.gis:
      return PwfColors.success;
    case LayerCategory.historical:
      return PwfColors.royalRed;
  }
}

IconData _iconForCategory(LayerCategory category) {
  switch (category) {
    case LayerCategory.waqf:
      return Icons.account_balance_outlined;
    case LayerCategory.core:
      return Icons.map_outlined;
    case LayerCategory.gis:
      return Icons.layers_outlined;
    case LayerCategory.historical:
      return Icons.history_edu_outlined;
  }
}
