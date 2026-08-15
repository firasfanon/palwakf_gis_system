import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/colors.dart';
import '../../../map/data/repositories/map_layer_manager_repository.dart';

class AdminMapRuntimeLayersPage extends ConsumerStatefulWidget {
  const AdminMapRuntimeLayersPage({super.key});

  @override
  ConsumerState<AdminMapRuntimeLayersPage> createState() =>
      _AdminMapRuntimeLayersPageState();
}

class _AdminMapRuntimeLayersPageState
    extends ConsumerState<AdminMapRuntimeLayersPage> {
  Future<List<MapRuntimeLayerGovernanceConfig>>? _future;
  final Set<String> _savingLayerKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future =
        ref.read(mapLayerManagerRepositoryProvider).listRuntimeLayerAllowlist();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _saveLayer(
    MapRuntimeLayerGovernanceConfig layer,
    _RuntimeLayerDraft draft,
  ) async {
    setState(() => _savingLayerKeys.add(layer.layerKey));
    try {
      await ref
          .read(mapLayerManagerRepositoryProvider)
          .saveRuntimeLayerAdminSettings(
            MapLayerManagerUpdate(
              layerKey: layer.layerKey,
              minZoom: draft.minZoom,
              maxZoom: draft.maxZoom,
              isActive: draft.enabled,
              isPublic: true,
              strokeColor: draft.strokeColor,
              fillColor: draft.fillColor,
              strokeWidth: draft.strokeWidth,
              labelsEnabled: draft.labelsEnabled,
              labelMinZoom: draft.labelMinZoom,
              labelHaloColor: draft.labelBackgroundColor,
              labelTextColor: draft.labelTextColor,
              pointShape: draft.badgeShape,
            ),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ ${layer.displayName}')),
      );
      setState(_reload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ ${layer.displayName}: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingLayerKeys.remove(layer.layerKey));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: FutureBuilder<List<MapRuntimeLayerGovernanceConfig>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _RuntimeErrorCard(error: snapshot.error.toString());
            }

            final layers =
                snapshot.data ?? const <MapRuntimeLayerGovernanceConfig>[];

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: _RuntimeHeader(
                      totalCount: layers.length,
                      onRefresh: _refresh,
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(child: _GovernanceBanner()),
                ),
                if (layers.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'لا توجد طبقات Runtime مسموحة في مصدر الحوكمة.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList.builder(
                      itemCount: layers.length,
                      itemBuilder: (context, index) {
                        final layer = layers[index];
                        final saving = _savingLayerKeys.contains(layer.layerKey);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RuntimeLayerTile(
                            key: ValueKey(
                              '${layer.layerKey}-${layer.minZoom}-${layer.maxZoom}',
                            ),
                            layer: layer,
                            saving: saving,
                            onSave: (draft) => _saveLayer(layer, draft),
                          ),
                        );
                      },
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RuntimeLayerDraft {
  final double minZoom;
  final double maxZoom;
  final bool enabled;
  final String strokeColor;
  final String fillColor;
  final double strokeWidth;
  final bool labelsEnabled;
  final double labelMinZoom;
  final String labelTextColor;
  final String labelBackgroundColor;
  final String badgeShape;

  const _RuntimeLayerDraft({
    required this.minZoom,
    required this.maxZoom,
    required this.enabled,
    required this.strokeColor,
    required this.fillColor,
    required this.strokeWidth,
    required this.labelsEnabled,
    required this.labelMinZoom,
    required this.labelTextColor,
    required this.labelBackgroundColor,
    required this.badgeShape,
  });

  factory _RuntimeLayerDraft.fromGovernance(
    MapRuntimeLayerGovernanceConfig layer,
  ) {
    return _RuntimeLayerDraft(
      minZoom:
          layer.minZoom <= 0 ? 7.5 : layer.minZoom.clamp(0.0, 22.0).toDouble(),
      maxZoom:
          layer.maxZoom <= 0 ? 22.0 : layer.maxZoom.clamp(0.0, 22.0).toDouble(),
      enabled: layer.isRuntimeAllowed && layer.isAdminVisible,
      strokeColor: _validHexOr(layer.strokeColor, '#1E3A8A'),
      fillColor: _validHexOr(layer.fillColor, '#DBEAFE'),
      strokeWidth: layer.strokeWidth <= 0
          ? 1.2
          : layer.strokeWidth.clamp(0.5, 6.0).toDouble(),
      labelsEnabled: layer.labelsEnabled,
      labelMinZoom: layer.labelMinZoom <= 0
          ? 12.0
          : layer.labelMinZoom.clamp(0.0, 22.0).toDouble(),
      labelTextColor: _validHexOr(layer.labelTextColor, '#111827'),
      labelBackgroundColor: _validHexOr(layer.labelHaloColor, '#FFFFFF'),
      badgeShape: _validShapeOr(layer.pointShape, 'square'),
    );
  }

  _RuntimeLayerDraft copyWith({
    double? minZoom,
    double? maxZoom,
    bool? enabled,
    String? strokeColor,
    String? fillColor,
    double? strokeWidth,
    bool? labelsEnabled,
    double? labelMinZoom,
    String? labelTextColor,
    String? labelBackgroundColor,
    String? badgeShape,
  }) {
    return _RuntimeLayerDraft(
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      enabled: enabled ?? this.enabled,
      strokeColor: strokeColor ?? this.strokeColor,
      fillColor: fillColor ?? this.fillColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      labelsEnabled: labelsEnabled ?? this.labelsEnabled,
      labelMinZoom: labelMinZoom ?? this.labelMinZoom,
      labelTextColor: labelTextColor ?? this.labelTextColor,
      labelBackgroundColor: labelBackgroundColor ?? this.labelBackgroundColor,
      badgeShape: badgeShape ?? this.badgeShape,
    );
  }
}

class _RuntimeHeader extends StatelessWidget {
  final int totalCount;
  final Future<void> Function() onRefresh;

  const _RuntimeHeader({
    required this.totalCount,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const SizedBox(
          width: 440,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'طبقات الشاشة الرئيسية',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'قائمة مدمجة من مصدر الحوكمة. افتح الطبقة المطلوبة فقط للتعديل.',
                style: TextStyle(color: Colors.white70, height: 1.45),
              ),
            ],
          ),
        ),
        _MetricCard(label: 'طبقات Runtime', value: '$totalCount'),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('تحديث'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _GovernanceBanner extends StatelessWidget {
  const _GovernanceBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: PwfColors.primaryBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.22)),
      ),
      child: const Text(
        'المصدر الحاكم: gis.v_layer_governance_final_v1. لا تظهر هنا أي طبقة خارج allowlist.',
        style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 13),
      ),
    );
  }
}

class _RuntimeLayerTile extends StatefulWidget {
  final MapRuntimeLayerGovernanceConfig layer;
  final bool saving;
  final ValueChanged<_RuntimeLayerDraft> onSave;

  const _RuntimeLayerTile({
    super.key,
    required this.layer,
    required this.saving,
    required this.onSave,
  });

  @override
  State<_RuntimeLayerTile> createState() => _RuntimeLayerTileState();
}

class _RuntimeLayerTileState extends State<_RuntimeLayerTile> {
  late _RuntimeLayerDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = _RuntimeLayerDraft.fromGovernance(widget.layer);
  }

  @override
  void didUpdateWidget(covariant _RuntimeLayerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layer.layerKey != widget.layer.layerKey ||
        oldWidget.layer.minZoom != widget.layer.minZoom ||
        oldWidget.layer.maxZoom != widget.layer.maxZoom) {
      _draft = _RuntimeLayerDraft.fromGovernance(widget.layer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final layer = widget.layer;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: PwfColors.primaryGold,
          collapsedIconColor: Colors.white70,
          title: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: Text(
                  layer.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _MiniPill(label: layer.layerKey, color: PwfColors.primaryGold),
              _MiniPill(label: layer.layerClass, color: Colors.white70),
              _MiniPill(
                label: '${_draft.minZoom.toStringAsFixed(1)} → ${_draft.maxZoom.toStringAsFixed(1)}',
                color: Colors.white70,
              ),
              if (layer.isHeavyLayer)
                const _MiniPill(label: 'heavy', color: PwfColors.royalRed),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              layer.decisionReason ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          children: [
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _NumberField(
                  title: 'زوم البداية',
                  value: _draft.minZoom,
                  min: 0,
                  max: 22,
                  onChanged: (value) => setState(() {
                    _draft = _draft.copyWith(
                      minZoom: value,
                      maxZoom: _draft.maxZoom < value ? value : _draft.maxZoom,
                    );
                  }),
                ),
                _NumberField(
                  title: 'زوم النهاية',
                  value: _draft.maxZoom,
                  min: 0,
                  max: 22,
                  onChanged: (value) => setState(() {
                    _draft = _draft.copyWith(
                      maxZoom: value,
                      minZoom: _draft.minZoom > value ? value : _draft.minZoom,
                    );
                  }),
                ),
                _NumberField(
                  title: 'سمك الحدود',
                  value: _draft.strokeWidth,
                  min: 0.5,
                  max: 6,
                  onChanged: (value) => setState(() {
                    _draft = _draft.copyWith(strokeWidth: value);
                  }),
                ),
                _NumberField(
                  title: 'زوم النص/الأرقام',
                  value: _draft.labelMinZoom,
                  min: 0,
                  max: 22,
                  onChanged: (value) => setState(() {
                    _draft = _draft.copyWith(labelMinZoom: value);
                  }),
                ),
                _SwitchBox(
                  title: 'متاحة',
                  value: _draft.enabled,
                  onChanged: (value) => setState(() {
                    _draft = _draft.copyWith(enabled: value);
                  }),
                ),
                _SwitchBox(
                  title: 'تسميات',
                  value: _draft.labelsEnabled,
                  onChanged: (value) => setState(() {
                    _draft = _draft.copyWith(labelsEnabled: value);
                  }),
                ),
                _ColorDropdown(
                  title: 'حدود',
                  selected: _draft.strokeColor,
                  onSelected: (value) => setState(() {
                    _draft = _draft.copyWith(strokeColor: value);
                  }),
                ),
                _ColorDropdown(
                  title: 'تعبئة',
                  selected: _draft.fillColor,
                  onSelected: (value) => setState(() {
                    _draft = _draft.copyWith(fillColor: value);
                  }),
                ),
                _ColorDropdown(
                  title: 'خلفية الرقم',
                  selected: _draft.labelBackgroundColor,
                  onSelected: (value) => setState(() {
                    _draft = _draft.copyWith(labelBackgroundColor: value);
                  }),
                ),
                _ColorDropdown(
                  title: 'لون النص',
                  selected: _draft.labelTextColor,
                  onSelected: (value) => setState(() {
                    _draft = _draft.copyWith(labelTextColor: value);
                  }),
                ),
                _ShapeDropdown(
                  selected: _draft.badgeShape,
                  onSelected: (value) => setState(() {
                    _draft = _draft.copyWith(badgeShape: value);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _LayerPreview(layer: layer, draft: _draft),
                FilledButton.icon(
                  onPressed: widget.saving ? null : () => widget.onSave(_draft),
                  icon: widget.saving
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(widget.saving ? 'جارٍ الحفظ...' : 'حفظ'),
                  style: FilledButton.styleFrom(
                    backgroundColor: PwfColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: widget.saving
                      ? null
                      : () => setState(() {
                            _draft = _RuntimeLayerDraft.fromGovernance(layer);
                          }),
                  icon: const Icon(Icons.restore),
                  label: const Text('استعادة'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _NumberField({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value.toStringAsFixed(1));
    return SizedBox(
      width: 130,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: title,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFF0B1220),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        onFieldSubmitted: (raw) {
          final parsed = double.tryParse(raw.trim());
          if (parsed == null) return;
          onChanged(parsed.clamp(min, max).toDouble());
        },
      ),
    );
  }
}

class _SwitchBox extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchBox({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        dense: true,
        value: value,
        activeColor: PwfColors.primaryGold,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _ColorDropdown extends StatelessWidget {
  final String title;
  final String selected;
  final ValueChanged<String> onSelected;

  const _ColorDropdown({
    required this.title,
    required this.selected,
    required this.onSelected,
  });

  static const colors = [
    _ColorChoice('أزرق', '#1E3A8A'),
    _ColorChoice('أزرق فاتح', '#2563EB'),
    _ColorChoice('ذهبي', '#D4AF37'),
    _ColorChoice('أحمر', '#B22222'),
    _ColorChoice('برتقالي', '#EA580C'),
    _ColorChoice('أخضر', '#16A34A'),
    _ColorChoice('تركواز', '#0F766E'),
    _ColorChoice('بنفسجي', '#7C3AED'),
    _ColorChoice('أبيض', '#FFFFFF'),
    _ColorChoice('رمادي', '#E5E7EB'),
    _ColorChoice('أسود', '#111827'),
  ];

  @override
  Widget build(BuildContext context) {
    final safe = _validHexOr(selected, colors.first.hex);
    final value = colors.any((e) => e.hex.toUpperCase() == safe)
        ? safe
        : colors.first.hex;

    return SizedBox(
      width: 150,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        dropdownColor: const Color(0xFF0B1220),
        decoration: InputDecoration(
          labelText: title,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFF0B1220),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        items: [
          for (final color in colors)
            DropdownMenuItem(
              value: color.hex,
              child: Row(
                children: [
                  CircleAvatar(radius: 7, backgroundColor: _hexToColor(color.hex)),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      color.label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
        onChanged: (value) {
          if (value != null) onSelected(value);
        },
      ),
    );
  }
}

class _ShapeDropdown extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _ShapeDropdown({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final shape = _validShapeOr(selected, 'square');
    return SizedBox(
      width: 150,
      child: DropdownButtonFormField<String>(
        value: shape,
        isExpanded: true,
        dropdownColor: const Color(0xFF0B1220),
        decoration: const InputDecoration(
          labelText: 'الشكل',
          labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
          isDense: true,
          filled: true,
          fillColor: Color(0xFF0B1220),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        items: const [
          DropdownMenuItem(
            value: 'circle',
            child: Text('دائرة', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          DropdownMenuItem(
            value: 'square',
            child: Text('مستطيل', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
        onChanged: (value) {
          if (value != null) onSelected(value);
        },
      ),
    );
  }
}

class _LayerPreview extends StatelessWidget {
  final MapRuntimeLayerGovernanceConfig layer;
  final _RuntimeLayerDraft draft;

  const _LayerPreview({required this.layer, required this.draft});

  @override
  Widget build(BuildContext context) {
    final stroke = _hexToColor(draft.strokeColor);
    final fill = _hexToColor(draft.fillColor);
    final labelText = _hexToColor(draft.labelTextColor);
    final labelBg = _hexToColor(draft.labelBackgroundColor);
    final isCircle = _validShapeOr(draft.badgeShape, 'square') == 'circle';

    return Container(
      width: 220,
      height: 72,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: stroke,
            width: draft.strokeWidth.clamp(0.5, 6.0).toDouble(),
          ),
        ),
        child: draft.labelsEnabled
            ? Container(
                width: isCircle ? 38 : null,
                height: isCircle ? 38 : null,
                padding: isCircle
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: labelBg,
                  shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: isCircle ? null : BorderRadius.circular(9),
                  border: Border.all(color: stroke, width: 1),
                ),
                child: Text(
                  '123',
                  style: TextStyle(
                    color: labelText,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              )
            : Text(
                layer.displayName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: stroke,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }
}

class _RuntimeErrorCard extends StatelessWidget {
  final String error;

  const _RuntimeErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 760,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: PwfColors.royalRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PwfColors.royalRed.withValues(alpha: 0.30)),
        ),
        child: Text(
          'تعذر تحميل Allowlist طبقات الشاشة الرئيسية:\n$error',
          style: const TextStyle(color: Colors.white, height: 1.7),
        ),
      ),
    );
  }
}

class _ColorChoice {
  final String label;
  final String hex;

  const _ColorChoice(this.label, this.hex);
}

String _validHexOr(String? value, String fallback) {
  final text = (value ?? '').trim().toUpperCase();
  if (RegExp(r'^#[0-9A-F]{6}$').hasMatch(text)) return text;
  return fallback.toUpperCase();
}

String _validShapeOr(String? value, String fallback) {
  final text = (value ?? '').trim().toLowerCase();
  if (text == 'circle') return 'circle';
  if (text == 'square' || text == 'rectangle' || text == 'rect') {
    return 'square';
  }
  return fallback;
}

Color _hexToColor(String hex) {
  final clean = _validHexOr(hex, '#FFFFFF').replaceFirst('#', '');
  final rgb = int.parse(clean, radix: 16);
  return Color(0xFF000000 | rgb);
}
