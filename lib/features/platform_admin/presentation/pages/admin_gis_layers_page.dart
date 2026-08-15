// lib/features/platform_admin/presentation/pages/admin_gis_layers_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/enums/enums.dart' as rbac;
import '../../../../core/services/map_layers_refresh_bus.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/admin_gis_layers_repository.dart';
import '../../domain/models/admin_gis_layer_row.dart';
import '../providers/admin_layers_providers.dart';

enum _LayersFilter {
  all,
  publicOnly,
  internalOnly,
  activeOnly,
  inactiveOnly,
}

enum _LayerEditorResult { saved, reset }

class AdminGisLayersPage extends ConsumerStatefulWidget {
  const AdminGisLayersPage({super.key});

  @override
  ConsumerState<AdminGisLayersPage> createState() => _AdminGisLayersPageState();
}

class _AdminGisLayersPageState extends ConsumerState<AdminGisLayersPage> {
  final _search = TextEditingController();
  _LayersFilter _filter = _LayersFilter.all;
  LayerCategory? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _canManageLayers() {
    final auth = ref.watch(authNotifierProvider);
    final access = auth.access;
    final roleRaw = (auth.user?.role ?? '').toString().toLowerCase();
    final roleFallback = {
      'super_admin',
      'superadmin',
      'superuser',
      'admin',
    }.contains(roleRaw);

    if (access == null) return roleFallback;
    if (access.isSuperuser) return true;
    return roleFallback ||
        access.can(
            rbac.SystemKey.platformAdmin, rbac.Permission.manageMapLayers) ||
        access.hasRoleAtLeast(
            rbac.SystemKey.platformAdmin, rbac.UserRole.admin);
  }

  List<AdminGisLayerRow> _applyFilters(List<AdminGisLayerRow> all) {
    final q = _search.text.trim().toLowerCase();
    return all.where((l) {
      if (_category != null && l.category != _category) return false;

      switch (_filter) {
        case _LayersFilter.publicOnly:
          if (!l.isPublic) return false;
          break;
        case _LayersFilter.internalOnly:
          if (l.isPublic) return false;
          break;
        case _LayersFilter.activeOnly:
          if (!l.isActive) return false;
          break;
        case _LayersFilter.inactiveOnly:
          if (l.isActive) return false;
          break;
        case _LayersFilter.all:
          break;
      }

      if (q.isEmpty) return true;
      final hay = '${l.nameAr} ${l.nameEn ?? ''} ${l.key}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  Future<void> _confirmAndRun({
    required String title,
    required String body,
    required Future<void> Function() action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('متابعة')),
        ],
      ),
    );
    if (ok != true) return;
    await action();
  }

  void _bumpPublicMapRefresh() {
    ref.read(mapLayersRefreshTickProvider.notifier).state++;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم طلب تحديث الخريطة العامة')),
    );
  }

  String _friendlyAdminError(Object e) {
    final raw = e.toString();
    if (raw.contains('42501') || raw.contains('permission denied')) {
      return 'صلاحيات الحفظ غير متاحة على gis.gis_layers. طبّق grants/RLS الخاصة بالإدارة أولًا.';
    }
    return raw;
  }

  Map<LayerCategory, int> _countByCategory(List<AdminGisLayerRow> all) {
    final out = <LayerCategory, int>{
      for (final c in LayerCategory.values) c: 0,
    };
    for (final l in all) {
      out[l.category] = (out[l.category] ?? 0) + 1;
    }
    return out;
  }

  Future<void> _openLayerEditor(
    AdminGisLayerRow layer,
    AdminGisLayersRepository repo,
  ) async {
    final nameAr = TextEditingController(text: layer.nameAr);
    final nameEn = TextEditingController(text: layer.nameEn ?? '');
    var category = layer.category;
    var defaultOpacity = layer.defaultOpacity;
    var compareEnabled = layer.compareEnabled;
    var saving = false;

    final result = await showDialog<_LayerEditorResult>(
      context: context,
      barrierDismissible: !saving,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            Future<void> save() async {
              setLocalState(() => saving = true);
              try {
                await repo.updateLayerSettings(
                  layer: layer,
                  nameAr: nameAr.text,
                  nameEn: nameEn.text,
                  category: category,
                  defaultOpacity: defaultOpacity,
                  compareEnabled: compareEnabled,
                );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop(_LayerEditorResult.saved);
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('تعذر حفظ الطبقة: ${_friendlyAdminError(e)}')),
                );
                if (ctx.mounted) setLocalState(() => saving = false);
              }
            }

            Future<void> resetStyle() async {
              setLocalState(() => saving = true);
              try {
                await repo.resetLayerStyleDefaults(layer: layer);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop(_LayerEditorResult.reset);
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('تعذر إعادة الضبط: ${_friendlyAdminError(e)}')),
                );
                if (ctx.mounted) setLocalState(() => saving = false);
              }
            }

            final canCompareToggle =
                layer.isRasterLike && category != LayerCategory.core;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: const Color(0xFF0F172A),
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
                titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                title: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تحرير طبقة GIS',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            layer.key,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 760,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EditorSectionTitle(title: 'الهوية والتصنيف'),
                        const SizedBox(height: 10),
                        Row(
                          textDirection: TextDirection.ltr,
                          children: [
                            Expanded(
                              child: _AdminTextField(
                                controller: nameEn,
                                label: 'الاسم الإنجليزي',
                                enabled: !saving,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.left,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _AdminTextField(
                                controller: nameAr,
                                label: 'الاسم العربي',
                                enabled: !saving,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _AdminDropdown<LayerCategory>(
                          label: 'الفئة',
                          value: category,
                          items: LayerCategory.values
                              .map((c) => DropdownMenuItem(
                                  value: c, child: Text(c.arLabel)))
                              .toList(),
                          onChanged: saving
                              ? null
                              : (v) {
                                  if (v != null) {
                                    setLocalState(() {
                                      category = v;
                                      if (category == LayerCategory.core &&
                                          compareEnabled) {
                                        compareEnabled = false;
                                      }
                                    });
                                  }
                                },
                        ),
                        const SizedBox(height: 18),
                        _EditorSectionTitle(title: 'خصائص العرض الافتراضية'),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.opacity,
                                      color: PwfColors.primaryBlue, size: 18),
                                  const SizedBox(width: 8),
                                  const Text('الشفافية الافتراضية',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800)),
                                  const Spacer(),
                                  Text(
                                    '${(defaultOpacity * 100).round()}%',
                                    style: const TextStyle(
                                        color: PwfColors.primaryGold,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                              Slider(
                                value: defaultOpacity,
                                min: 0.1,
                                max: 1.0,
                                divisions: 9,
                                activeColor: PwfColors.primaryBlue,
                                inactiveColor: PwfColors.primaryBlue
                                    .withValues(alpha: 0.20),
                                onChanged: saving
                                    ? null
                                    : (v) =>
                                        setLocalState(() => defaultOpacity = v),
                              ),
                              const SizedBox(height: 4),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('السماح بالمقارنة البصرية',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                                subtitle: Text(
                                  canCompareToggle
                                      ? 'تظهر هذه الطبقة في أدوات المقارنة داخل الخريطة.'
                                      : 'يتطلب ذلك طبقة Raster من نوع XYZ وخارج فئة الأساسية.',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.62),
                                      height: 1.4),
                                ),
                                value:
                                    canCompareToggle ? compareEnabled : false,
                                onChanged: (!saving && canCompareToggle)
                                    ? (v) =>
                                        setLocalState(() => compareEnabled = v)
                                    : null,
                                activeColor: PwfColors.primaryBlue,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _EditorSectionTitle(title: 'معلومات المصدر'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _ReadOnlyStat(
                                label: 'نوع الطبقة',
                                value: layer.layerType.isEmpty
                                    ? 'غير محدد'
                                    : layer.layerType),
                            _ReadOnlyStat(
                                label: 'المصدر', value: layer.bestSourceLabel),
                            _ReadOnlyStat(
                                label: 'الترتيب',
                                value: '${layer.displayOrder}'),
                            _ReadOnlyStat(
                                label: 'الحالة الحالية',
                                value:
                                    "${layer.isActive ? 'مفعلة' : 'غير مفعلة'} • ${layer.isPublic ? 'عامة' : 'داخلية'}"),
                          ],
                        ),
                        if (layer.urlTemplate.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: SelectableText(
                              layer.urlTemplate,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                actions: [
                  TextButton(
                    onPressed: saving ? null : resetStyle,
                    child: const Text('إعادة القيم الافتراضية'),
                  ),
                  TextButton(
                    onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton.icon(
                    onPressed: saving ? null : save,
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: Text(saving ? 'جاري الحفظ...' : 'حفظ التعديلات'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameAr.dispose();
    nameEn.dispose();

    if (!mounted || result == null) return;
    ref.invalidate(adminGisLayersProvider);
    _bumpPublicMapRefresh();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == _LayerEditorResult.saved
              ? 'تم حفظ إعدادات الطبقة'
              : 'تمت إعادة ضبط القيم الافتراضية',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = _canManageLayers();
    final asyncLayers = ref.watch(adminGisLayersProvider);
    final repo = ref.watch(adminGisLayersRepositoryProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'إدارة طبقات GIS',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _bumpPublicMapRefresh,
                    icon:
                        const Icon(Icons.public, color: PwfColors.primaryGold),
                    label: const Text('تحديث الخريطة العامة',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'تحديث',
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: () => ref.invalidate(adminGisLayersProvider),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoBanner(canEdit: canEdit),
              const SizedBox(height: 12),

              // Filters
              Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'بحث بالاسم/المفتاح...',
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5)),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF111827),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.10)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.10)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color:
                                  PwfColors.primaryBlue.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _FilterDropdown(
                    value: _filter,
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                  const SizedBox(width: 10),
                  _CategoryDropdown(
                    value: _category,
                    onChanged: (v) => setState(() => _category = v),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bulk actions
              asyncLayers.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (all) {
                  if (!canEdit) return const SizedBox.shrink();
                  final visible = _applyFilters(all);
                  return _BulkBar(
                    count: visible.length,
                    onActivateAll: () => _confirmAndRun(
                      title: 'تفعيل الطبقات',
                      body:
                          'سيتم تفعيل ${visible.length} طبقة (حسب الفلاتر الحالية).',
                      action: () async {
                        await repo.bulkSetFlags(
                            layers: visible, isActive: true);
                        ref.invalidate(adminGisLayersProvider);
                        _bumpPublicMapRefresh();
                      },
                    ),
                    onDeactivateAll: () => _confirmAndRun(
                      title: 'إيقاف الطبقات',
                      body:
                          'سيتم إيقاف ${visible.length} طبقة (حسب الفلاتر الحالية).',
                      action: () async {
                        await repo.bulkSetFlags(
                            layers: visible, isActive: false);
                        ref.invalidate(adminGisLayersProvider);
                        _bumpPublicMapRefresh();
                      },
                    ),
                    onMakePublic: () => _confirmAndRun(
                      title: 'جعل الطبقات عامة',
                      body:
                          'سيتم جعل ${visible.length} طبقة عامة (Public=true).',
                      action: () async {
                        await repo.bulkSetFlags(
                            layers: visible, isPublic: true);
                        ref.invalidate(adminGisLayersProvider);
                        _bumpPublicMapRefresh();
                      },
                    ),
                    onMakeInternal: () => _confirmAndRun(
                      title: 'جعل الطبقات داخلية',
                      body:
                          'سيتم جعل ${visible.length} طبقة داخلية (Public=false).',
                      action: () async {
                        await repo.bulkSetFlags(
                            layers: visible, isPublic: false);
                        ref.invalidate(adminGisLayersProvider);
                        _bumpPublicMapRefresh();
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              Expanded(
                child: asyncLayers.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorBox(error: e.toString()),
                  data: (layers) {
                    if (layers.isEmpty) {
                      return const _ErrorBox(
                        error:
                            'لا توجد طبقات أو أن RLS يمنع قراءتها.\nتأكد من: Supabase API Exposed schemas تتضمن gis، وأن لديك سياسة SELECT تسمح للـ super_admin بقراءة gis.gis_layers.',
                      );
                    }

                    final visible = _applyFilters(layers);
                    final counts = _countByCategory(layers);

                    Future<void> doSync() async {
                      try {
                        final inserted = await repo.syncLayersFromSchema();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'تمت المزامنة من DB: تمت إضافة $inserted طبقات جديدة')),
                        );
                        ref.invalidate(adminGisLayersProvider);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sync: ${e.toString()}')),
                        );
                      }
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Text(
                                      'المعروض: ${visible.length} / الإجمالي: ${layers.length}',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.7)),
                                    ),
                                    const Spacer(),
                                    if (canEdit)
                                      OutlinedButton.icon(
                                        onPressed: doSync,
                                        icon: const Icon(Icons.sync,
                                            color: Colors.white70, size: 18),
                                        label: const Text('Sync من DB',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                              color: Colors.white
                                                  .withValues(alpha: 0.12)),
                                          backgroundColor: Colors.black
                                              .withValues(alpha: 0.12),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: visible.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, i) {
                                    final l = visible[i];

                                    // Determine move bounds within the SAME category (global, not search-filtered)
                                    final group = layers
                                        .where((x) => x.category == l.category)
                                        .toList()
                                      ..sort((a, b) {
                                        final c = a.displayOrder
                                            .compareTo(b.displayOrder);
                                        if (c != 0) return c;
                                        return a.key.compareTo(b.key);
                                      });

                                    int idx = -1;
                                    if (l.id != null && l.id!.isNotEmpty) {
                                      idx =
                                          group.indexWhere((x) => x.id == l.id);
                                    }
                                    if (idx < 0) {
                                      idx = group.indexWhere((x) =>
                                          x.key == l.key &&
                                          x.unitId == l.unitId);
                                    }

                                    final canUp = canEdit &&
                                        idx > 0 &&
                                        (l.id?.isNotEmpty ?? false);
                                    final canDown = canEdit &&
                                        idx >= 0 &&
                                        idx < (group.length - 1) &&
                                        (l.id?.isNotEmpty ?? false);

                                    Future<void> move(int dir) async {
                                      final id = l.id;
                                      if (id == null || id.isEmpty) return;
                                      try {
                                        await repo.moveLayer(
                                            layerId: id, dir: dir);
                                        ref.invalidate(adminGisLayersProvider);
                                        _bumpPublicMapRefresh();
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'تعذر تحريك الطبقة: ${e.toString()}')),
                                        );
                                      }
                                    }

                                    return _LayerTile(
                                      layer: l,
                                      canEdit: canEdit,
                                      canMoveUp: canUp,
                                      canMoveDown: canDown,
                                      onMoveUp: canUp ? () => move(-1) : null,
                                      onMoveDown:
                                          canDown ? () => move(1) : null,
                                      onEdit: canEdit
                                          ? () => _openLayerEditor(l, repo)
                                          : null,
                                      onTogglePublic: (v) async {
                                        await repo.setFlags(
                                            layer: l, isPublic: v);
                                        ref.invalidate(adminGisLayersProvider);
                                        _bumpPublicMapRefresh();
                                      },
                                      onToggleActive: (v) async {
                                        await repo.setFlags(
                                            layer: l, isActive: v);
                                        ref.invalidate(adminGisLayersProvider);
                                        _bumpPublicMapRefresh();
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        _CategoriesSidebar(
                          total: layers.length,
                          counts: counts,
                          selected: _category,
                          onSelect: (c) => setState(() => _category = c),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriesSidebar extends StatelessWidget {
  final int total;
  final Map<LayerCategory, int> counts;
  final LayerCategory? selected;
  final ValueChanged<LayerCategory?> onSelect;

  const _CategoriesSidebar({
    required this.total,
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    Widget item(
        {required String label,
        required int count,
        required bool active,
        required VoidCallback onTap}) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? PwfColors.primaryBlue.withValues(alpha: 0.18)
                : const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: active
                    ? PwfColors.primaryBlue
                    : Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: active ? PwfColors.primaryGold : Colors.white,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('الفئات',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          item(
            label: 'كل الفئات',
            count: total,
            active: selected == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(height: 10),
          ...LayerCategory.values.map((c) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: item(
                label: c.arLabel,
                count: counts[c] ?? 0,
                active: selected == c,
                onTap: () => onSelect(c),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final bool canEdit;
  const _InfoBanner({required this.canEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: PwfColors.primaryGold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              canEdit
                  ? 'تحكم بالطبقات عبر التفعيل والظهور العام والترتيب، وافتح تحرير الطبقة لضبط الشفافية الافتراضية وقابلية المقارنة والتصنيف.'
                  : 'لا تملك صلاحية تعديل الطبقات. تأكد من RBAC (platformAdmin/manageMapLayers).',
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final _LayersFilter value;
  final ValueChanged<_LayersFilter> onChanged;
  const _FilterDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_LayersFilter>(
          value: value,
          dropdownColor: const Color(0xFF111827),
          iconEnabledColor: Colors.white70,
          style: const TextStyle(color: Colors.white),
          items: const [
            DropdownMenuItem(value: _LayersFilter.all, child: Text('الكل')),
            DropdownMenuItem(
                value: _LayersFilter.publicOnly, child: Text('العامة فقط')),
            DropdownMenuItem(
                value: _LayersFilter.internalOnly, child: Text('الداخلية فقط')),
            DropdownMenuItem(
                value: _LayersFilter.activeOnly, child: Text('المفعلة فقط')),
            DropdownMenuItem(
                value: _LayersFilter.inactiveOnly,
                child: Text('غير المفعلة فقط')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final LayerCategory? value;
  final ValueChanged<LayerCategory?> onChanged;
  const _CategoryDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LayerCategory?>(
          value: value,
          dropdownColor: const Color(0xFF111827),
          iconEnabledColor: Colors.white70,
          style: const TextStyle(color: Colors.white),
          items: [
            const DropdownMenuItem(value: null, child: Text('كل الفئات')),
            ...LayerCategory.values.map(
              (c) => DropdownMenuItem(value: c, child: Text(c.arLabel)),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _BulkBar extends StatelessWidget {
  final int count;
  final VoidCallback onActivateAll;
  final VoidCallback onDeactivateAll;
  final VoidCallback onMakePublic;
  final VoidCallback onMakeInternal;

  const _BulkBar({
    required this.count,
    required this.onActivateAll,
    required this.onDeactivateAll,
    required this.onMakePublic,
    required this.onMakeInternal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Text('إجراءات جماعية (المعروض: $count)',
              style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          _MiniBtn(
              label: 'تفعيل الكل',
              icon: Icons.toggle_on,
              onPressed: count == 0 ? null : onActivateAll),
          const SizedBox(width: 8),
          _MiniBtn(
              label: 'إيقاف الكل',
              icon: Icons.toggle_off,
              onPressed: count == 0 ? null : onDeactivateAll),
          const SizedBox(width: 8),
          _MiniBtn(
              label: 'جعل عام',
              icon: Icons.public,
              onPressed: count == 0 ? null : onMakePublic),
          const SizedBox(width: 8),
          _MiniBtn(
              label: 'جعل داخلي',
              icon: Icons.lock,
              onPressed: count == 0 ? null : onMakeInternal),
        ],
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _MiniBtn(
      {required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: Colors.white70),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        backgroundColor: Colors.black.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _LayerTile extends StatelessWidget {
  final AdminGisLayerRow layer;
  final bool canEdit;
  final ValueChanged<bool> onTogglePublic;
  final ValueChanged<bool> onToggleActive;

  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onEdit;

  const _LayerTile({
    required this.layer,
    required this.canEdit,
    required this.onTogglePublic,
    required this.onToggleActive,
    required this.canMoveUp,
    required this.canMoveDown,
    this.onMoveUp,
    this.onMoveDown,
    this.onEdit,
  });

  String _fmtUpdatedAt(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final updated = _fmtUpdatedAt(layer.updatedAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(layer.nameAr,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    if ((layer.nameEn ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        layer.nameEn!.trim(),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            layer.key,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.48),
                                fontSize: 12),
                          ),
                        ),
                        if (updated.isNotEmpty)
                          Text(
                            'آخر تحديث: $updated',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(isActive: layer.isActive),
                  const SizedBox(height: 8),
                  _PublicChip(isPublic: layer.isPublic),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TinyMeta(label: 'الفئة: ${layer.category.arLabel}'),
              _TinyMeta(label: 'الترتيب: ${layer.displayOrder}'),
              _TinyMeta(
                  label: 'الشفافية: ${(layer.defaultOpacity * 100).round()}%'),
              if (layer.compareEnabled)
                const _TinyMeta(label: 'قابلة للمقارنة', highlight: true),
              _TinyMeta(label: layer.bestSourceLabel),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                tooltip: 'أعلى',
                onPressed: canMoveUp ? onMoveUp : null,
                icon: Icon(Icons.arrow_upward,
                    color: canMoveUp ? Colors.white : Colors.white24),
              ),
              IconButton(
                tooltip: 'أسفل',
                onPressed: canMoveDown ? onMoveDown : null,
                icon: Icon(Icons.arrow_downward,
                    color: canMoveDown ? Colors.white : Colors.white24),
              ),
              if (canEdit) ...[
                const SizedBox(width: 4),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.tune, size: 18, color: Colors.white70),
                  label: const Text('تحرير',
                      style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    backgroundColor: Colors.black.withValues(alpha: 0.12),
                  ),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  const Text('مفعلة',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(width: 8),
                  Switch(
                    value: layer.isActive,
                    onChanged: canEdit ? onToggleActive : null,
                    activeColor: PwfColors.primaryBlue,
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Row(
                children: [
                  const Text('عامة',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(width: 8),
                  Switch(
                    value: layer.isPublic,
                    onChanged: canEdit ? onTogglePublic : null,
                    activeColor: PwfColors.primaryBlue,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TinyMeta extends StatelessWidget {
  final String label;
  final bool highlight;
  const _TinyMeta({required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? PwfColors.primaryBlue.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlight
              ? PwfColors.primaryBlue.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlight
              ? PwfColors.primaryGold
              : Colors.white.withValues(alpha: 0.86),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final bg = isActive
        ? Colors.green.withValues(alpha: 0.18)
        : Colors.grey.withValues(alpha: 0.18);
    final fg = isActive ? Colors.greenAccent : Colors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(isActive ? 'مفعل' : 'غير مفعل',
          style: TextStyle(color: fg, fontSize: 12)),
    );
  }
}

class _PublicChip extends StatelessWidget {
  final bool isPublic;
  const _PublicChip({required this.isPublic});

  @override
  Widget build(BuildContext context) {
    final bg = isPublic
        ? PwfColors.primaryBlue.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.08);
    final fg = isPublic ? PwfColors.primaryGold : Colors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(isPublic ? 'عام' : 'داخلي',
          style: TextStyle(color: fg, fontSize: 12)),
    );
  }
}

class _EditorSectionTitle extends StatelessWidget {
  final String title;
  const _EditorSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    );
  }
}

class _AdminTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final TextDirection? textDirection;
  final TextAlign? textAlign;
  const _AdminTextField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.textDirection,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      textDirection: textDirection,
      textAlign: textAlign ?? TextAlign.start,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: PwfColors.primaryBlue.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}

class _AdminDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  const _AdminDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF111827),
          iconEnabledColor: Colors.white70,
          style: const TextStyle(color: Colors.white),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ReadOnlyStat extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.56), fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String error;
  const _ErrorBox({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Text(error,
          style: const TextStyle(color: Colors.white70, height: 1.4)),
    );
  }
}
