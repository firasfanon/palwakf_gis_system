// lib/features/platform_admin/presentation/pages/admin_map_layer_manager_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/colors.dart';
import '../../../map/data/repositories/map_layer_manager_repository.dart';
import '../providers/map_layer_manager_admin_providers.dart';

class AdminMapLayerManagerPage extends ConsumerStatefulWidget {
  const AdminMapLayerManagerPage({super.key});

  @override
  ConsumerState<AdminMapLayerManagerPage> createState() =>
      _AdminMapLayerManagerPageState();
}

class _AdminMapLayerManagerPageState
    extends ConsumerState<AdminMapLayerManagerPage> {
  final TextEditingController _searchController = TextEditingController();
  String _category = 'all';
  bool _checkingAll = false;
  final Set<String> _savingLayers = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateLayer(MapLayerManagerUpdate update) async {
    setState(() => _savingLayers.add(update.layerKey));
    try {
      await ref.read(mapLayerManagerRepositoryProvider).updateLayerConfig(update);
      ref.invalidate(adminMapLayerConfigsProvider);
      ref.invalidate(adminMapLayerIntegrityProvider);
      ref.invalidate(adminMapLayerRolePreviewProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ إعدادات الطبقة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حفظ الطبقة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingLayers.remove(update.layerKey));
    }
  }

  Future<void> _runIntegrity({String? layerKey}) async {
    if (layerKey == null) setState(() => _checkingAll = true);
    try {
      final rows = await ref
          .read(mapLayerManagerRepositoryProvider)
          .checkLayerIntegrity(layerKey: layerKey, persist: true);
      ref.invalidate(adminMapLayerIntegrityProvider);
      ref.invalidate(adminMapLayerRolePreviewProvider);
      if (!mounted) return;
      if (layerKey != null && rows.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (_) => _IntegrityDialog(result: rows.first),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم فحص ${rows.length} طبقة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تنفيذ فحص السلامة: $e')),
        );
      }
    } finally {
      if (mounted && layerKey == null) setState(() => _checkingAll = false);
    }
  }

  Future<void> _showLayerHistory(MapLayerAdminConfig layer) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _LayerHistoryDialog(layer: layer),
    );
    if (!mounted) return;
    ref.invalidate(adminMapLayerConfigsProvider);
    ref.invalidate(adminMapLayerIntegrityProvider);
    ref.invalidate(adminMapLayerRolePreviewProvider);
  }


  @override
  Widget build(BuildContext context) {
    final layersAsync = ref.watch(adminMapLayerConfigsProvider);
    final integrityAsync = ref.watch(adminMapLayerIntegrityProvider);
    final rolePreviewAsync = ref.watch(adminMapLayerRolePreviewProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: layersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _AdminErrorCard(error: e.toString()),
            data: (layers) {
              final integrityMap = integrityAsync.maybeWhen(
                data: (rows) => {
                  for (final row in rows) row.layerKey: row,
                },
                orElse: () => <String, MapLayerIntegrityResult>{},
              );
              final categories = <String>{
                'all',
                ...layers.map((e) => e.category).where((e) => e.isNotEmpty),
              }.toList()
                ..sort();

              final query = _searchController.text.trim().toLowerCase();
              final filtered = layers.where((layer) {
                final matchesCategory =
                    _category == 'all' || layer.category == _category;
                final matchesQuery = query.isEmpty ||
                    layer.layerKey.toLowerCase().contains(query) ||
                    layer.displayName.toLowerCase().contains(query) ||
                    (layer.nameEn ?? '').toLowerCase().contains(query);
                return matchesCategory && matchesQuery;
              }).toList();

              final critical = integrityMap.values
                  .where((e) => e.severity == 'critical')
                  .length;
              final warnings =
                  integrityMap.values.where((e) => e.severity == 'warning').length;
              final heavy =
                  layers.where((e) => e.layerWeight == 'heavy').length;

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminMapLayerConfigsProvider);
                  ref.invalidate(adminMapLayerIntegrityProvider);
      ref.invalidate(adminMapLayerRolePreviewProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        checkingAll: _checkingAll,
                        onRefresh: () {
                          ref.invalidate(adminMapLayerConfigsProvider);
                          ref.invalidate(adminMapLayerIntegrityProvider);
      ref.invalidate(adminMapLayerRolePreviewProvider);
                        },
                        onCheckAll: _checkingAll ? null : () => _runIntegrity(),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _MetricCard(
                            title: 'إجمالي الطبقات',
                            value: '${layers.length}',
                            icon: Icons.layers,
                          ),
                          _MetricCard(
                            title: 'طبقات ثقيلة',
                            value: '$heavy',
                            icon: Icons.storage,
                          ),
                          _MetricCard(
                            title: 'تحذيرات',
                            value: '$warnings',
                            icon: Icons.warning_amber,
                          ),
                          _MetricCard(
                            title: 'حرجة',
                            value: '$critical',
                            icon: Icons.report_problem_outlined,
                            highlight: critical > 0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _RolePreviewSection(previewAsync: rolePreviewAsync),
                      const SizedBox(height: 16),
                      _FilterBar(
                        controller: _searchController,
                        category: _category,
                        categories: categories,
                        onChanged: () => setState(() {}),
                        onCategoryChanged: (value) =>
                            setState(() => _category = value ?? 'all'),
                      ),
                      const SizedBox(height: 16),
                      _InfoBanner(
                        text:
                            'هذه الصفحة تستخدم نفس Repository/RPC الخاص بإدارة الطبقات في الخريطة. '
                            'أي تعديل هنا ينعكس على Runtime الخريطة دون إنشاء مسار إدارة منفصل.',
                      ),
                      const SizedBox(height: 16),
                      if (filtered.isEmpty)
                        const _EmptyCard()
                      else
                        ...filtered.map(
                          (layer) => _LayerDashboardCard(
                            key: ValueKey(layer.layerKey),
                            layer: layer,
                            integrity: integrityMap[layer.layerKey],
                            saving: _savingLayers.contains(layer.layerKey),
                            onToggleActive: (v) => _updateLayer(
                              MapLayerManagerUpdate(
                                layerKey: layer.layerKey,
                                isActive: v,
                              ),
                            ),
                            onTogglePublic: (v) => _updateLayer(
                              MapLayerManagerUpdate(
                                layerKey: layer.layerKey,
                                isPublic: v,
                              ),
                            ),
                            onToggleVisiblePublic: (v) => _updateLayer(
                              MapLayerManagerUpdate(
                                layerKey: layer.layerKey,
                                visiblePublic: v,
                              ),
                            ),
                            onToggleVisibleEmployee: (v) => _updateLayer(
                              MapLayerManagerUpdate(
                                layerKey: layer.layerKey,
                                visibleEmployee: v,
                              ),
                            ),
                            onToggleVisibleManager: (v) => _updateLayer(
                              MapLayerManagerUpdate(
                                layerKey: layer.layerKey,
                                visibleManager: v,
                              ),
                            ),
                            onToggleBbox: (v) => _updateLayer(
                              MapLayerManagerUpdate(
                                layerKey: layer.layerKey,
                                bboxRequired: v,
                              ),
                            ),
                            onSetWeight: (weight) => _updateLayer(
                              MapLayerManagerUpdate(
                                layerKey: layer.layerKey,
                                layerWeight: weight,
                                bboxRequired: weight != 'light' ? true : layer.bboxRequired,
                                maxFeaturesPerRequest: weight == 'heavy'
                                    ? 800
                                    : weight == 'medium'
                                        ? 2500
                                        : 5000,
                              ),
                            ),
                            onSetExport: (policy) => _updateLayer(
                              MapLayerManagerUpdate(
                                layerKey: layer.layerKey,
                                exportPolicy: policy,
                              ),
                            ),
                            onCheck: () => _runIntegrity(layerKey: layer.layerKey),
                            onHistory: () => _showLayerHistory(layer),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RolePreviewSection extends StatelessWidget {
  final AsyncValue<List<MapLayerRolePreview>> previewAsync;

  const _RolePreviewSection({required this.previewAsync});

  @override
  Widget build(BuildContext context) {
    return previewAsync.when(
      loading: () => const _InfoBanner(text: 'جارٍ تجهيز معاينة الأدوار...'),
      error: (e, _) => _InfoBanner(text: 'تعذر تحميل معاينة الأدوار: $e'),
      data: (items) {
        if (items.isEmpty) {
          return const _InfoBanner(text: 'لا توجد بيانات معاينة للأدوار بعد.');
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PwfColors.primaryGold.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'معاينة الطبقات حسب الدور',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: items.map((item) {
                  final risky = item.roleKey == 'public' && item.heavyVisibleLayers > 0;
                  return Container(
                    width: 250,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1220),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (risky ? PwfColors.royalRed : Colors.white)
                            .withValues(alpha: risky ? 0.40 : 0.10),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.roleLabelAr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _InlineFact(label: 'الظاهرة', value: '${item.visibleLayers}/${item.totalLayers}'),
                        _InlineFact(label: 'المفعلة', value: '${item.activeVisibleLayers}'),
                        _InlineFact(label: 'الثقيلة', value: '${item.heavyVisibleLayers}'),
                        _InlineFact(label: 'قابلة للتصدير', value: '${item.exportableLayers}'),
                        const SizedBox(height: 6),
                        Text(
                          item.riskLabelAr,
                          style: TextStyle(
                            color: risky ? PwfColors.royalRed : Colors.white70,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LayerHistoryDialog extends ConsumerStatefulWidget {
  final MapLayerAdminConfig layer;

  const _LayerHistoryDialog({required this.layer});

  @override
  ConsumerState<_LayerHistoryDialog> createState() => _LayerHistoryDialogState();
}

class _LayerHistoryDialogState extends ConsumerState<_LayerHistoryDialog> {
  late Future<List<MapLayerSettingRevision>> _future;
  bool _rollingBack = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MapLayerSettingRevision>> _load() {
    return ref.read(mapLayerManagerRepositoryProvider).listSettingRevisions(
          layerKey: widget.layer.layerKey,
          limit: 40,
        );
  }

  Future<void> _rollback(MapLayerSettingRevision revision) async {
    setState(() => _rollingBack = true);
    try {
      await ref.read(mapLayerManagerRepositoryProvider).rollbackSettingRevision(
            revisionId: revision.id,
            layerKey: widget.layer.layerKey,
            note: 'استرجاع من لوحة إدارة الطبقات - revision ${revision.revisionNo}',
          );
      ref.invalidate(adminMapLayerConfigsProvider);
      ref.invalidate(adminMapLayerIntegrityProvider);
      ref.invalidate(adminMapLayerRolePreviewProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم استرجاع إعدادات الطبقة')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الاسترجاع: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _rollingBack = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text(
          'سجل إعدادات ${widget.layer.displayName}',
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 720,
          child: FutureBuilder<List<MapLayerSettingRevision>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'تعذر تحميل السجل: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white70),
                );
              }
              final rows = snapshot.data ?? const <MapLayerSettingRevision>[];
              if (rows.isEmpty) {
                return const Text(
                  'لا توجد نسخ محفوظة بعد. سيتم إنشاء السجل تلقائيًا عند أول تعديل جديد بعد تطبيق SQL.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                );
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 460),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'نسخة ${row.revisionNo} - ${row.actionLabelAr}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${row.changedAt ?? ''}\n${row.summaryAr}${row.note == null ? '' : '\n${row.note}'}',
                        style: const TextStyle(color: Colors.white70, height: 1.5),
                      ),
                      trailing: OutlinedButton.icon(
                        onPressed: _rollingBack ? null : () => _rollback(row),
                        icon: const Icon(Icons.restore),
                        label: const Text('استرجاع'),
                        style: _buttonStyle(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: _rollingBack ? null : () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool checkingAll;
  final VoidCallback onRefresh;
  final VoidCallback? onCheckAll;

  const _Header({
    required this.checkingAll,
    required this.onRefresh,
    required this.onCheckAll,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      children: [
        const SizedBox(
          width: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إدارة طبقات الخريطة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'إعدادات التشغيل، الصلاحيات، الأداء، وفحص سلامة الطبقات من داخل لوحة التحكم.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
              style: _buttonStyle(),
            ),
            ElevatedButton.icon(
              onPressed: onCheckAll,
              icon: checkingAll
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fact_check_outlined),
              label: const Text('فحص السلامة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PwfColors.primaryGold,
                foregroundColor: const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TextEditingController controller;
  final String category;
  final List<String> categories;
  final VoidCallback onChanged;
  final ValueChanged<String?> onCategoryChanged;

  const _FilterBar({
    required this.controller,
    required this.category,
    required this.categories,
    required this.onChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 360,
          child: TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'بحث في الطبقات',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.10)),
              ),
            ),
          ),
        ),
        Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: categories.contains(category) ? category : 'all',
              dropdownColor: const Color(0xFF111827),
              iconEnabledColor: Colors.white70,
              style: const TextStyle(color: Colors.white),
              items: categories
                  .map(
                    (cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat == 'all' ? 'كل التصنيفات' : cat),
                    ),
                  )
                  .toList(),
              onChanged: onCategoryChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _LayerDashboardCard extends StatelessWidget {
  final MapLayerAdminConfig layer;
  final MapLayerIntegrityResult? integrity;
  final bool saving;
  final ValueChanged<bool> onToggleActive;
  final ValueChanged<bool> onTogglePublic;
  final ValueChanged<bool> onToggleVisiblePublic;
  final ValueChanged<bool> onToggleVisibleEmployee;
  final ValueChanged<bool> onToggleVisibleManager;
  final ValueChanged<bool> onToggleBbox;
  final ValueChanged<String> onSetWeight;
  final ValueChanged<String> onSetExport;
  final VoidCallback onCheck;
  final VoidCallback onHistory;

  const _LayerDashboardCard({
    super.key,
    required this.layer,
    required this.integrity,
    required this.saving,
    required this.onToggleActive,
    required this.onTogglePublic,
    required this.onToggleVisiblePublic,
    required this.onToggleVisibleEmployee,
    required this.onToggleVisibleManager,
    required this.onToggleBbox,
    required this.onSetWeight,
    required this.onSetExport,
    required this.onCheck,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = switch (integrity?.severity) {
      'critical' => PwfColors.royalRed,
      'warning' => Colors.orangeAccent,
      _ => Colors.greenAccent,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      layer.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        layer.layerKey,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(
                    label: layer.categoryLabelAr,
                    icon: Icons.category_outlined,
                  ),
                  _StatusChip(
                    label: integrity?.severityLabelAr ?? 'لم يُفحص',
                    icon: Icons.health_and_safety_outlined,
                    color: severityColor,
                  ),
                  if (saving)
                    const _StatusChip(
                      label: 'حفظ...',
                      icon: Icons.sync,
                      color: PwfColors.primaryGold,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SwitchPill(
                label: 'مفعّلة',
                value: layer.isActive,
                onChanged: saving ? null : onToggleActive,
              ),
              _SwitchPill(
                label: 'عامة',
                value: layer.isPublic,
                onChanged: saving ? null : onTogglePublic,
              ),
              _SwitchPill(
                label: 'للجمهور',
                value: layer.visiblePublic,
                onChanged: saving ? null : onToggleVisiblePublic,
              ),
              _SwitchPill(
                label: 'للموظف',
                value: layer.visibleEmployee,
                onChanged: saving ? null : onToggleVisibleEmployee,
              ),
              _SwitchPill(
                label: 'للمدير',
                value: layer.visibleManager,
                onChanged: saving ? null : onToggleVisibleManager,
              ),
              _SwitchPill(
                label: 'BBOX مطلوب',
                value: layer.bboxRequired,
                onChanged: saving ? null : onToggleBbox,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MiniDropdown(
                label: 'وزن الطبقة',
                value: layer.layerWeight,
                values: const {
                  'light': 'خفيفة',
                  'medium': 'متوسطة',
                  'heavy': 'ثقيلة',
                },
                onChanged: saving ? null : onSetWeight,
              ),
              _MiniDropdown(
                label: 'التصدير',
                value: layer.exportPolicy,
                values: const {
                  'none': 'ممنوع',
                  'summary': 'ملخص',
                  'visible': 'المعروض فقط',
                  'manager_only': 'المدير فقط',
                },
                onChanged: saving ? null : onSetExport,
              ),
              _StatusChip(
                label: 'Zoom ${layer.minZoom.toStringAsFixed(0)} - ${layer.maxZoom.toStringAsFixed(0)}',
                icon: Icons.zoom_in_map,
              ),
              _StatusChip(
                label: 'حد الطلب ${layer.maxFeaturesPerRequest}',
                icon: Icons.format_list_numbered,
              ),
              OutlinedButton.icon(
                onPressed: saving ? null : onCheck,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('فحص الطبقة'),
                style: _buttonStyle(),
              ),
              OutlinedButton.icon(
                onPressed: saving ? null : onHistory,
                icon: const Icon(Icons.history),
                label: const Text("السجل والاسترجاع"),
                style: _buttonStyle(),
              ),
            ],
          ),
          if (integrity != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: severityColor.withValues(alpha: 0.35)),
              ),
              child: Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _InlineFact(label: 'العناصر', value: '${integrity!.featureCount}'),
                  _InlineFact(label: 'بلا هندسة', value: '${integrity!.nullGeomCount}'),
                  _InlineFact(label: 'غير صالحة', value: '${integrity!.invalidGeomCount}'),
                  _InlineFact(label: 'SRID', value: '${integrity!.sridMismatchCount}'),
                  Text(
                    integrity!.issueSummaryAr,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IntegrityDialog extends StatelessWidget {
  final MapLayerIntegrityResult result;
  const _IntegrityDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text(
          'نتيجة فحص ${result.displayName}',
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 520,
          child: Text(
            'الحالة: ${result.severityLabelAr}\n'
            'العناصر: ${result.featureCount}\n'
            'بلا هندسة: ${result.nullGeomCount}\n'
            'هندسة غير صالحة: ${result.invalidGeomCount}\n'
            'SRID غير 4326: ${result.sridMismatchCount}\n\n'
            '${result.issueSummaryAr}',
            style: const TextStyle(color: Colors.white70, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool highlight;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? PwfColors.royalRed : PwfColors.primaryGold;
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> values;
  final ValueChanged<String>? onChanged;

  const _MiniDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = values.containsKey(value) ? value : values.keys.first;
    return Container(
      width: 190,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isDense: true,
          dropdownColor: const Color(0xFF111827),
          iconEnabledColor: Colors.white70,
          style: const TextStyle(color: Colors.white),
          items: values.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text('$label: ${e.value}'),
                ),
              )
              .toList(),
          onChanged: onChanged == null ? null : (v) => onChanged!(v ?? selected),
        ),
      ),
    );
  }
}

class _SwitchPill extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchPill({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: PwfColors.primaryGold,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _StatusChip({
    required this.label,
    required this.icon,
    this.color = PwfColors.primaryGold,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: color.withValues(alpha: 0.14),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: const TextStyle(color: Colors.white70)),
    );
  }
}

class _InlineFact extends StatelessWidget {
  final String label;
  final String value;
  const _InlineFact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PwfColors.primaryBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.22)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, height: 1.5)),
    );
  }
}

class _AdminErrorCard extends StatelessWidget {
  final String error;
  const _AdminErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PwfColors.royalRed.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PwfColors.royalRed.withValues(alpha: 0.35)),
        ),
        child: Text(error, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('لا توجد طبقات مطابقة.', style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}

ButtonStyle _buttonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: Colors.white70,
    side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
  );
}
