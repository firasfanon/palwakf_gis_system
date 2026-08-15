import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/constants/colors.dart';
import 'package:kimi/core/constants/enums.dart';
import 'package:kimi/features/map/domain/models/gis_layer_model.dart';
import '../../../providers/map_provider.dart';
import '../../../providers/map_ui_providers.dart';
import '../../../providers/toolbox_providers.dart';

class LayersSection extends ConsumerStatefulWidget {
  const LayersSection({super.key});

  @override
  ConsumerState<LayersSection> createState() => _LayersSectionState();
}

class _LayersSectionState extends ConsumerState<LayersSection> {
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
    final state = ref.watch(mapNotifierProvider);
    final notifier = ref.read(mapNotifierProvider.notifier);

    final filteredLayers = _filterLayers(
      state.gisLayers,
      query: _query,
      activeOnly: _activeOnly,
      activeKeys: state.activeLayers.toSet(),
    );
    final grouped = _groupByCategory(filteredLayers);
    final activeCount = state.activeLayers.length;
    final compareEnabled = ref.watch(compareEnabledProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () =>
                  ref.read(activeToolSectionProvider.notifier).state = null,
              icon: const Icon(Icons.arrow_back, color: PwfColors.onSurface),
            ),
            const Spacer(),
            const Text(
              'الطبقات',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            const SizedBox(width: 5),
            IconButton(
              onPressed: () => notifier.bootstrapGis(),
              icon: const Icon(Icons.refresh, color: PwfColors.royalRed),
              tooltip: 'تحديث',
            ),
          ],
        ),
        const SizedBox(height: 5),
        _TopSummaryCard(
          totalCount: state.gisLayers.length,
          visibleCount: activeCount,
          filteredCount: filteredLayers.length,
          categoryCount: grouped.length,
          compareEnabled: compareEnabled,
        ),
        const SizedBox(height: 8),
        _LayerPresetStrip(
          layers: state.gisLayers,
          activeLayerKeys: state.activeLayers,
          onApply: (keys) {
            notifier.setActiveLayers(keys);
          },
          onClear: () {
            notifier.deactivateAllLayers();
          },
        ),
        const SizedBox(height: 8),
        _SearchAndFilterBar(
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
        const SizedBox(height: 5),
        if (state.gisLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        if (!state.gisLoading && state.gisError != null)
          _ErrorNotice(message: state.gisError!),
        if (!state.gisLoading &&
            filteredLayers.isEmpty &&
            state.gisError == null)
          _EmptyNotice(hasQuery: _query.trim().isNotEmpty || _activeOnly),
        if (!state.gisLoading && grouped.isNotEmpty)
          ...grouped.entries.map(
            (entry) => _CategoryPanel(
              category: entry.key,
              layers: entry.value,
              activeCount: entry.value
                  .where((layer) => state.activeLayers.contains(layer.key))
                  .length,
            ),
          ),
      ],
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
      // Admin governance: layers disabled from the management panel are not
      // rendered in the toolbox tab, even if a stale client state still holds
      // them. Public map users should only see active public layers.
      if (!layer.isActive || !layer.isPublic) return false;
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

class _TopSummaryCard extends StatelessWidget {
  const _TopSummaryCard({
    required this.totalCount,
    required this.visibleCount,
    required this.filteredCount,
    required this.categoryCount,
    required this.compareEnabled,
  });

  final int totalCount;
  final int visibleCount;
  final int filteredCount;
  final int categoryCount;
  final bool compareEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: PwfColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PwfColors.primaryBlue.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.layers_outlined,
                  color: PwfColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'لوحة الطبقات',
                  style: TextStyle(
                    color: PwfColors.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              if (compareEnabled)
                const _MetaFlag(
                  label: 'المقارنة مفعلة',
                  color: PwfColors.royalRed,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              _SummaryChip(
                icon: Icons.dashboard_outlined,
                label: 'الإجمالي: $totalCount',
                color: PwfColors.primaryBlue,
              ),
              _SummaryChip(
                icon: Icons.visibility_outlined,
                label: 'المفعلة: $visibleCount',
                color: PwfColors.success,
              ),
              _SummaryChip(
                icon: Icons.filter_alt_outlined,
                label: 'النتائج: $filteredCount',
                color: PwfColors.warning,
              ),
              _SummaryChip(
                icon: Icons.category_outlined,
                label: 'الفئات: $categoryCount',
                color: PwfColors.onSurface,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'الوضع الابتدائي يعرض حدود فلسطين فقط، ثم يمكنك تفعيل باقي الطبقات تدريجيًا حسب الحاجة لتقليل الازدحام على الخريطة.',
            style: TextStyle(
              color: PwfColors.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerPresetStrip extends StatelessWidget {
  const _LayerPresetStrip({
    required this.layers,
    required this.activeLayerKeys,
    required this.onApply,
    required this.onClear,
  });

  final List<GisLayerModel> layers;
  final List<String> activeLayerKeys;
  final ValueChanged<List<String>> onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final lightKeys = _keysForPreset(_LayerPreset.light);
    final waqfKeys = _keysForPreset(_LayerPreset.waqfPoints);
    final naturalKeys = _keysForPreset(_LayerPreset.naturalBlocks);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: PwfColors.royalRed.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.playlist_add_check_circle_outlined,
                  color: PwfColors.royalRed,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'حزم تشغيل سريعة',
                  style: TextStyle(
                    color: PwfColors.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
              ),
              _PresetTinyBadge(label: '${activeLayerKeys.length} مفعلة'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _PresetActionChip(
                label: 'فتح خفيف',
                icon: Icons.rocket_launch_outlined,
                enabled: lightKeys.isNotEmpty,
                color: PwfColors.primaryBlue,
                onTap: () => onApply(lightKeys),
              ),
              _PresetActionChip(
                label: 'تدقيق وقفي',
                icon: Icons.account_balance_outlined,
                enabled: waqfKeys.isNotEmpty,
                color: PwfColors.primaryGold,
                onTap: () => onApply(waqfKeys),
              ),
              _PresetActionChip(
                label: 'الأحواض الطبيعية',
                icon: Icons.layers_outlined,
                enabled: naturalKeys.isNotEmpty,
                color: PwfColors.royalRed,
                onTap: () => onApply(naturalKeys),
              ),
              _PresetActionChip(
                label: 'إيقاف الكل',
                icon: Icons.layers_clear_outlined,
                enabled: activeLayerKeys.isNotEmpty,
                color: PwfColors.onSurface,
                onTap: onClear,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _keysForPreset(_LayerPreset preset) {
    final keys = <String>[];

    bool allowed(GisLayerModel layer) => layer.isActive && layer.isPublic;

    bool match(
      GisLayerModel layer, {
      List<String> keyTokens = const [],
      List<String> arTokens = const [],
      List<String> enTokens = const [],
    }) {
      final key = layer.key.trim().toLowerCase();
      final nameAr = layer.nameAr.trim().toLowerCase();
      final nameEn = (layer.nameEn ?? '').trim().toLowerCase();
      return keyTokens.any(key.contains) ||
          arTokens.any(nameAr.contains) ||
          enTokens.any(nameEn.contains);
    }

    void addMatches({
      List<String> keyTokens = const [],
      List<String> arTokens = const [],
      List<String> enTokens = const [],
      int maxAdd = 99,
    }) {
      var added = 0;
      for (final layer in layers) {
        if (!allowed(layer)) continue;
        if (!match(
          layer,
          keyTokens: keyTokens,
          arTokens: arTokens,
          enTokens: enTokens,
        )) {
          continue;
        }
        if (!keys.contains(layer.key)) {
          keys.add(layer.key);
          added++;
        }
        if (added >= maxAdd) break;
      }
    }

    void addBase() {
      addMatches(
        keyTokens: const ['westbank_gaza', 'west_bank_gaza', 'palestine'],
        arTokens: const ['فلسطين', 'الضفة وغزة', 'الضفة الغربية وغزة'],
        enTokens: const ['palestine', 'west bank and gaza', 'westbank gaza'],
        maxAdd: 1,
      );
      addMatches(
        keyTokens: const ['governorates_boundary', 'v_governorates_core', 'governorate'],
        arTokens: const ['المحافظات'],
        enTokens: const ['governorates', 'governorate boundaries'],
        maxAdd: 1,
      );
      addMatches(
        keyTokens: const ['lgus_boundary', 'v_lgus_core', 'v_lgus_light', 'lgu'],
        arTokens: const ['الهيئات المحلية', 'حدود الهيئات'],
        enTokens: const ['local government', 'lgus', 'lgu boundaries'],
        maxAdd: 1,
      );
    }

    addBase();

    switch (preset) {
      case _LayerPreset.light:
        break;
      case _LayerPreset.waqfPoints:
        addMatches(
          keyTokens: const ['gis_waqf_', 'mosque', 'maqamat', 'cemeteries', 'takaya', 'archaeological'],
          arTokens: const ['المساجد', 'المقامات', 'المقابر', 'التكايا', 'الأثرية'],
          enTokens: const ['mosque', 'maqamat', 'cemeteries', 'takaya', 'archaeological'],
          maxAdd: 12,
        );
        break;
      case _LayerPreset.naturalBlocks:
        addMatches(
          keyTokens: const ['natural_blocks_full'],
          arTokens: const ['الأحواض الطبيعية'],
          enTokens: const ['natural blocks full'],
          maxAdd: 1,
        );
        break;
    }
    return keys;
  }
}

enum _LayerPreset { light, waqfPoints, naturalBlocks }

class _PresetActionChip extends StatelessWidget {
  const _PresetActionChip({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: enabled ? onTap : null,
      avatar: Icon(
        icon,
        size: 15,
        color: enabled ? color : PwfColors.onSurface.withValues(alpha: 0.35),
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: enabled ? PwfColors.onSurface : PwfColors.onSurface.withValues(alpha: 0.42),
        fontWeight: FontWeight.w800,
        fontSize: 11,
      ),
      backgroundColor: color.withValues(alpha: enabled ? 0.08 : 0.03),
      side: BorderSide(color: color.withValues(alpha: enabled ? 0.16 : 0.06)),
    );
  }
}

class _PresetTinyBadge extends StatelessWidget {
  const _PresetTinyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: PwfColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: PwfColors.primaryBlue,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Icon(Icons.search, color: PwfColors.primaryBlue, size: 17),
              const SizedBox(width: 5),
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
                  icon: const Icon(Icons.close, size: 15),
                  tooltip: 'مسح',
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              FilterChip(
                selected: activeOnly,
                onSelected: (_) => onToggleActiveOnly(),
                selectedColor: PwfColors.primaryGold.withValues(alpha: 0.18),
                label: const Text('المفعلة فقط'),
                avatar: const Icon(Icons.visibility_outlined, size: 15),
                side: BorderSide(color: PwfColors.outline.withValues(alpha: 0.9)),
              ),
              if (query.trim().isNotEmpty || activeOnly)
                ActionChip(
                  onPressed: onReset,
                  avatar: const Icon(Icons.restart_alt, size: 15),
                  label: const Text('إعادة ضبط الفلاتر'),
                  side: BorderSide(
                    color: PwfColors.primaryBlue.withValues(alpha: 0.18),
                  ),
                ),
              const _MetaFlag(
                label: 'الافتراضي: حدود فلسطين فقط',
                color: PwfColors.royalRed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryPanel extends ConsumerWidget {
  const _CategoryPanel({
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: _colorForCategory(category).withValues(alpha: 0.12),
            child: Icon(
              _iconForCategory(category),
              color: _colorForCategory(category),
              size: 15,
            ),
          ),
          title: Text(
            category.arLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: PwfColors.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _categoryDescription(category),
              style: TextStyle(
                color: PwfColors.onSurface.withValues(alpha: 0.62),
                fontSize: 10.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$activeCount / ${layers.length}',
                style: TextStyle(
                  color: _colorForCategory(category),
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5,
                ),
              ),
              Text(
                'مفعلة',
                style: TextStyle(
                  color: PwfColors.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          children: [
            const SizedBox(height: 6),
            Divider(height: 1, color: PwfColors.outline.withValues(alpha: 0.95)),
            const SizedBox(height: 6),
            ...layers.map((layer) => _LayerCard(layer: layer)),
          ],
        ),
      ),
    );
  }

  String _categoryDescription(LayerCategory category) {
    switch (category) {
      case LayerCategory.historical:
        return 'طبقات تاريخية وفترات مقارنة ومراجع زمنية.';
      case LayerCategory.waqf:
        return 'أصول وقفية وبيانات ذات صلة بالإدارة الوقفية.';
      case LayerCategory.core:
        return 'حدود ومرجعيات أساسية للخريطة.';
      case LayerCategory.gis:
        return 'طبقات تشغيل GIS العامة والمتقدمة.';
    }
  }
}

class _LayerCard extends ConsumerWidget {
  const _LayerCard({required this.layer});

  final GisLayerModel layer;

  bool get _canCompare {
    return layer.isActive && layer.isPublic && layer.compareEnabled;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapNotifierProvider);
    final notifier = ref.read(mapNotifierProvider.notifier);
    final active = state.activeLayers.contains(layer.key);
    final opacity = state.layerOpacity[layer.key] ?? 1.0;
    final englishName = _englishName(layer);
    final compareLeft = ref.watch(compareLeftSourceProvider);
    final compareRight = ref.watch(compareRightSourceProvider);
    final compareEnabled = ref.watch(compareEnabledProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? PwfColors.primaryGold.withValues(alpha: 0.55)
              : PwfColors.outline,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Switch.adaptive(
                value: active,
                activeColor: PwfColors.primaryGold,
                onChanged: (_) => notifier.toggleLayer(layer.key),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      layer.nameAr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.2,
                        color: PwfColors.onSurface,
                      ),
                    ),
                    if (englishName != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        englishName,
                        style: TextStyle(
                          fontSize: 10.2,
                          color: PwfColors.onSurface.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _StatusChip(active: active),
                        _MetaChip(label: layer.category.arLabel),
                        if (layer.key.trim().toLowerCase() == 'natural_blocks_full')
                          const _MetaChip(
                            label: 'natural_blocks_full',
                            color: PwfColors.royalRed,
                          ),
                        if (_canCompare)
                          const _MetaChip(label: 'قابلة للمقارنة'),
                        if (compareEnabled && compareLeft == layer.key)
                          const _MetaChip(
                            label: 'يسار المقارنة',
                            color: PwfColors.primaryBlue,
                          ),
                        if (compareEnabled && compareRight == layer.key)
                          const _MetaChip(
                            label: 'يمين المقارنة',
                            color: PwfColors.royalRed,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.opacity, size: 15, color: PwfColors.primaryBlue),
              const SizedBox(width: 5),
              const Text(
                'الشفافية',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${(opacity * 100).round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: PwfColors.primaryBlue,
                ),
              ),
            ],
          ),
          Slider(
            value: opacity,
            min: 0.1,
            max: 1.0,
            onChanged: active
                ? (v) => notifier.setLayerOpacity(layer.key, v)
                : null,
            activeColor: PwfColors.primaryBlue,
            inactiveColor: PwfColors.primaryBlue.withValues(alpha: 0.18),
          ),
          if (_canCompare) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(compareLeftSourceProvider.notifier).state =
                          layer.key;
                      ref.read(compareEnabledProvider.notifier).state = true;
                    },
                    icon:
                        const Icon(Icons.keyboard_double_arrow_left, size: 16),
                    label: const Text('ضعها يسارًا'),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(compareRightSourceProvider.notifier).state =
                          layer.key;
                      ref.read(compareEnabledProvider.notifier).state = true;
                    },
                    icon: const Icon(Icons.keyboard_double_arrow_right, size: 16),
                    label: const Text('ضعها يمينًا'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String? _englishName(GisLayerModel layer) {
    if (layer.key.trim().toLowerCase() == 'natural_blocks_full') {
      return 'Natural Blocks Full';
    }
    final name = layer.nameEn?.trim();
    if (name == null || name.isEmpty) return null;
    if (name.toLowerCase() == layer.nameAr.trim().toLowerCase()) return null;
    return name;
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaFlag extends StatelessWidget {
  const _MetaFlag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withValues(alpha: 0.92),
          fontWeight: FontWeight.w800,
          fontSize: 10.2,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? PwfColors.primaryGold.withValues(alpha: 0.12)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'مفعلة' : 'مخفية',
        style: TextStyle(
          color: active
              ? PwfColors.primaryGold
              : PwfColors.onSurface.withValues(alpha: 0.70),
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? PwfColors.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: base.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: base.withValues(alpha: 0.84),
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PwfColors.error.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: PwfColors.error),
          const SizedBox(width: 5),
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
          const SizedBox(width: 5),
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
