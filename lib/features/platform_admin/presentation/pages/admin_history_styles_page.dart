import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/colors.dart';
import '../widgets/history_style_editor.dart';
import '../../data/repositories/history_styles_admin_repository.dart';
import '../../domain/models/historical_style_admin_rows.dart';
import '../providers/history_styles_admin_providers.dart';

class AdminHistoryStylesPage extends ConsumerStatefulWidget {
  const AdminHistoryStylesPage({super.key});

  @override
  ConsumerState<AdminHistoryStylesPage> createState() =>
      _AdminHistoryStylesPageState();
}

class _AdminHistoryStylesPageState extends ConsumerState<AdminHistoryStylesPage>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF0B1220);
  static const _card = Color(0xFF111827);

  late final TabController _tabController;
  late final TextEditingController _searchController;
  bool _activeOnly = false;
  bool _systemProfilesOnly = false;
  String _profileScopeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _searchController = TextEditingController();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(historicalStyleProfilesProvider);
    ref.invalidate(historicalStyleLevelsProvider);
    ref.invalidate(historicalStylePeriodsProvider);
    ref.invalidate(historicalLevelStyleDefaultsProvider);
    ref.invalidate(historicalPeriodLevelStyleOverridesProvider);
    ref.invalidate(historicalFeatureStyleOverridesProvider);
  }

  Future<void> _confirmDelete({
    required String title,
    required Future<void> Function() onDelete,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('هل أنت متأكد من الحذف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await onDelete();
      _refreshAll();
    }
  }

  Future<void> _showProfileDialog({
    HistoricalStyleProfileRow? row,
    bool duplicate = false,
  }) async {
    final repo = ref.read(historyStylesAdminRepositoryProvider);
    final seed = row;
    final keyCtrl = TextEditingController(
      text: duplicate && seed != null ? '${seed.profileKey}_copy' : seed?.profileKey ?? '',
    );
    final nameArCtrl = TextEditingController(
      text: duplicate && seed != null ? '${seed.profileNameAr} - نسخة' : seed?.profileNameAr ?? '',
    );
    final nameEnCtrl = TextEditingController(text: seed?.profileNameEn ?? '');
    final notesCtrl = TextEditingController(text: seed?.notes ?? '');

    var styleScope = seed?.styleScope ?? 'level';
    var isSystem = duplicate ? false : (seed?.isSystem ?? false);
    var isActive = seed?.isActive ?? true;
    var styleJson = Map<String, dynamic>.from(seed?.styleJson ?? const {});
    var editorSeed = 0;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(duplicate ? 'نسخ ملف نمط' : (row == null ? 'إضافة ملف نمط' : 'تعديل ملف نمط')),
          content: SizedBox(
            width: 880,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(keyCtrl, 'profile_key *'),
                  _field(nameArCtrl, 'الاسم العربي *'),
                  _field(nameEnCtrl, 'الاسم الإنجليزي'),
                  DropdownButtonFormField<String>(
                    value: styleScope,
                    decoration: _inputDecoration('نطاق النمط *'),
                    items: const [
                      DropdownMenuItem(value: 'level', child: Text('مستوى')),
                      DropdownMenuItem(value: 'period', child: Text('فترة')),
                      DropdownMenuItem(value: 'feature', child: Text('عنصر')),
                      DropdownMenuItem(value: 'global', child: Text('عام')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => styleScope = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  HistoryStyleEditor(
                    key: ValueKey('profile-editor-$editorSeed'),
                    initialValue: styleJson,
                    title: 'Symbology / Style Inspector',
                    onChanged: (value) => styleJson = value,
                  ),
                  const SizedBox(height: 12),
                  _field(notesCtrl, 'ملاحظات', maxLines: 3),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isSystem,
                    onChanged: (v) => setState(() => isSystem = v),
                    title: const Text('ملف نظامي'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    onChanged: (v) => setState(() => isActive = v),
                    title: const Text('فعّال'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                await repo.saveProfile(
                  originalProfileKey: duplicate ? null : row?.profileKey,
                  profileKey: keyCtrl.text.trim(),
                  profileNameAr: nameArCtrl.text.trim(),
                  profileNameEn: nameEnCtrl.text.trim().isEmpty
                      ? null
                      : nameEnCtrl.text.trim(),
                  styleScope: styleScope,
                  styleJson: styleJson,
                  isSystem: isSystem,
                  isActive: isActive,
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(context);
                _refreshAll();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLevelDefaultDialog({
    HistoricalLevelStyleDefaultRow? row,
  }) async {
    final repo = ref.read(historyStylesAdminRepositoryProvider);
    final levels = await ref.read(historicalStyleLevelsProvider.future);
    final profiles = await ref.read(historicalStyleProfilesProvider.future);

    String? levelKey = row?.levelKey ?? (levels.isNotEmpty ? levels.first.levelKey : null);
    String? profileKey = row?.profileKey;
    final notesCtrl = TextEditingController(text: row?.notes ?? '');
    var styleJson = Map<String, dynamic>.from(row?.overrideStyleJson ?? const {});
    var isActive = row?.isActive ?? true;
    var editorSeed = 0;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(row == null ? 'إضافة افتراضي مستوى' : 'تعديل افتراضي مستوى'),
          content: SizedBox(
            width: 900,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: levelKey,
                    decoration: _inputDecoration('المستوى *'),
                    items: levels.map((e) => DropdownMenuItem(value: e.levelKey, child: Text(e.levelNameAr))).toList(),
                    onChanged: row != null ? null : (value) => setState(() => levelKey = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: profileKey,
                          decoration: _inputDecoration('ملف النمط'),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('بدون profile')),
                            ...profiles.map((e) => DropdownMenuItem<String?>(value: e.profileKey, child: Text('${e.profileNameAr} • ${e.profileKey}'))),
                          ],
                          onChanged: (value) => setState(() => profileKey = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: profileKey == null
                            ? null
                            : () {
                                final selected = profiles.where((e) => e.profileKey == profileKey).toList();
                                if (selected.isEmpty) return;
                                setState(() {
                                  styleJson = Map<String, dynamic>.from(selected.first.styleJson);
                                  editorSeed++;
                                });
                              },
                        icon: const Icon(Icons.content_paste_go_outlined),
                        label: const Text('تحميل profile'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  HistoryStyleEditor(
                    key: ValueKey('level-editor-$editorSeed'),
                    initialValue: styleJson,
                    title: 'Level Default Inspector',
                    onChanged: (value) => styleJson = value,
                  ),
                  const SizedBox(height: 12),
                  _field(notesCtrl, 'ملاحظات', maxLines: 3),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    onChanged: (v) => setState(() => isActive = v),
                    title: const Text('فعّال'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                if (levelKey == null) return;
                await repo.saveLevelDefault(
                  levelKey: levelKey!,
                  profileKey: profileKey,
                  overrideStyleJson: styleJson,
                  isActive: isActive,
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(context);
                _refreshAll();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPeriodOverrideDialog({
    HistoricalPeriodLevelStyleOverrideRow? row,
  }) async {
    final repo = ref.read(historyStylesAdminRepositoryProvider);
    final periods = await ref.read(historicalStylePeriodsProvider.future);
    final levels = await ref.read(historicalStyleLevelsProvider.future);
    final profiles = await ref.read(historicalStyleProfilesProvider.future);

    int? periodNo = row?.periodNo ?? (periods.isNotEmpty ? periods.first.periodNo : null);
    String? levelKey = row?.levelKey ?? (levels.isNotEmpty ? levels.first.levelKey : null);
    String? profileKey = row?.profileKey;
    final notesCtrl = TextEditingController(text: row?.notes ?? '');
    var styleJson = Map<String, dynamic>.from(row?.overrideStyleJson ?? const {});
    var isActive = row?.isActive ?? true;
    var editorSeed = 0;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(row == null ? 'إضافة Override فترة/مستوى' : 'تعديل Override فترة/مستوى'),
          content: SizedBox(
            width: 960,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: periodNo,
                    decoration: _inputDecoration('الفترة *'),
                    items: periods.map((e) => DropdownMenuItem(value: e.periodNo, child: Text('${e.periodNo} • ${e.titleAr}'))).toList(),
                    onChanged: row != null ? null : (value) => setState(() => periodNo = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: levelKey,
                    decoration: _inputDecoration('المستوى *'),
                    items: levels.map((e) => DropdownMenuItem(value: e.levelKey, child: Text(e.levelNameAr))).toList(),
                    onChanged: row != null ? null : (value) => setState(() => levelKey = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: profileKey,
                          decoration: _inputDecoration('ملف النمط'),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('بدون profile')),
                            ...profiles.map((e) => DropdownMenuItem<String?>(value: e.profileKey, child: Text('${e.profileNameAr} • ${e.profileKey}'))),
                          ],
                          onChanged: (value) => setState(() => profileKey = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: profileKey == null
                            ? null
                            : () {
                                final selected = profiles.where((e) => e.profileKey == profileKey).toList();
                                if (selected.isEmpty) return;
                                setState(() {
                                  styleJson = Map<String, dynamic>.from(selected.first.styleJson);
                                  editorSeed++;
                                });
                              },
                        icon: const Icon(Icons.layers_clear_outlined),
                        label: const Text('تحميل profile'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  HistoryStyleEditor(
                    key: ValueKey('period-editor-$editorSeed'),
                    initialValue: styleJson,
                    title: 'Period / Level Override Inspector',
                    onChanged: (value) => styleJson = value,
                  ),
                  const SizedBox(height: 12),
                  _field(notesCtrl, 'ملاحظات', maxLines: 3),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    onChanged: (v) => setState(() => isActive = v),
                    title: const Text('فعّال'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                if (periodNo == null || levelKey == null) return;
                await repo.savePeriodLevelOverride(
                  periodNo: periodNo!,
                  levelKey: levelKey!,
                  profileKey: profileKey,
                  overrideStyleJson: styleJson,
                  isActive: isActive,
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(context);
                _refreshAll();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFeatureOverrideDialog({
    HistoricalFeatureStyleOverrideRow? row,
  }) async {
    final repo = ref.read(historyStylesAdminRepositoryProvider);
    final periods = await ref.read(historicalStylePeriodsProvider.future);
    final levels = await ref.read(historicalStyleLevelsProvider.future);
    final profiles = await ref.read(historicalStyleProfilesProvider.future);

    int? periodNo = row?.periodNo;
    String? levelKey = row?.levelKey ?? (levels.isNotEmpty ? levels.first.levelKey : null);
    String? profileKey = row?.profileKey;
    final tableCtrl = TextEditingController(text: row?.sourceTable ?? '');
    final sourceIdCtrl = TextEditingController(text: row?.sourceId ?? '');
    final notesCtrl = TextEditingController(text: row?.notes ?? '');
    var styleJson = Map<String, dynamic>.from(row?.overrideStyleJson ?? const {});
    var isActive = row?.isActive ?? true;
    var editorSeed = 0;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(row == null ? 'إضافة Override عنصر' : 'تعديل Override عنصر'),
          content: SizedBox(
            width: 980,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int?>(
                    value: periodNo,
                    decoration: _inputDecoration('الفترة (اختياري)'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('بدون فترة محددة')),
                      ...periods.map((e) => DropdownMenuItem<int?>(value: e.periodNo, child: Text('${e.periodNo} • ${e.titleAr}'))),
                    ],
                    onChanged: (value) => setState(() => periodNo = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: levelKey,
                    decoration: _inputDecoration('المستوى *'),
                    items: levels.map((e) => DropdownMenuItem(value: e.levelKey, child: Text(e.levelNameAr))).toList(),
                    onChanged: (value) => setState(() => levelKey = value),
                  ),
                  const SizedBox(height: 12),
                  _field(tableCtrl, 'source_table *'),
                  _field(sourceIdCtrl, 'source_id *'),
                  DropdownButtonFormField<String?>(
                    value: profileKey,
                    decoration: _inputDecoration('ملف النمط'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('بدون profile')),
                      ...profiles.map((e) => DropdownMenuItem<String?>(value: e.profileKey, child: Text('${e.profileNameAr} • ${e.profileKey}'))),
                    ],
                    onChanged: (value) => setState(() => profileKey = value),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: profileKey == null
                          ? null
                          : () {
                              final selected = profiles.where((e) => e.profileKey == profileKey).toList();
                              if (selected.isEmpty) return;
                              setState(() {
                                styleJson = Map<String, dynamic>.from(selected.first.styleJson);
                                editorSeed++;
                              });
                            },
                      icon: const Icon(Icons.auto_fix_high_outlined),
                      label: const Text('تحميل profile'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  HistoryStyleEditor(
                    key: ValueKey('feature-editor-$editorSeed'),
                    initialValue: styleJson,
                    title: 'Feature Override Inspector',
                    onChanged: (value) => styleJson = value,
                  ),
                  const SizedBox(height: 12),
                  _field(notesCtrl, 'ملاحظات', maxLines: 3),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    onChanged: (v) => setState(() => isActive = v),
                    title: const Text('فعّال'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                if (levelKey == null || tableCtrl.text.trim().isEmpty || sourceIdCtrl.text.trim().isEmpty) {
                  return;
                }
                await repo.saveFeatureOverride(
                  id: row?.id,
                  periodNo: periodNo,
                  levelKey: levelKey!,
                  sourceTable: tableCtrl.text.trim(),
                  sourceId: sourceIdCtrl.text.trim(),
                  profileKey: profileKey,
                  overrideStyleJson: styleJson,
                  isActive: isActive,
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(context);
                _refreshAll();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إدارة أنماط الطبقات التاريخية',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _refreshAll,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث الكل'),
                ),
                FilledButton.icon(
                  onPressed: _showCreateDialogForCurrentTab,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'هذه الشاشة تعمل فوق hist.style_profiles و hist.level_style_defaults و hist.period_level_style_overrides و hist.feature_style_overrides، وتغذي style_json داخل rpc_historical_period_overlay_v4.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            _buildToolbar(),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: PwfColors.primaryGold,
              unselectedLabelColor: Colors.white70,
              dividerColor: Colors.white12,
              tabs: const [
                Tab(text: 'ملفات الأنماط'),
                Tab(text: 'افتراضيات المستويات'),
                Tab(text: 'Overrides فترة/مستوى'),
                Tab(text: 'Overrides عنصر'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProfilesTab(),
                  _buildLevelDefaultsTab(),
                  _buildPeriodOverridesTab(),
                  _buildFeatureOverridesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialogForCurrentTab() {
    switch (_tabController.index) {
      case 0:
        _showProfileDialog();
        break;
      case 1:
        _showLevelDefaultDialog();
        break;
      case 2:
        _showPeriodOverrideDialog();
        break;
      case 3:
        _showFeatureOverrideDialog();
        break;
    }
  }

  String get _searchQuery => _searchController.text.trim().toLowerCase();

  bool _matchesSearch(List<String?> fields) {
    if (_searchQuery.isEmpty) return true;
    for (final field in fields) {
      final value = (field ?? '').toLowerCase();
      if (value.contains(_searchQuery)) return true;
    }
    return false;
  }

  String _scopeLabel(String scope) {
    switch (scope) {
      case 'level':
        return 'مستوى';
      case 'period':
        return 'فترة';
      case 'feature':
        return 'عنصر';
      case 'global':
        return 'عام';
      default:
        return scope;
    }
  }

  String _activeLabel(bool value) => value ? 'فعّال' : 'غير فعّال';

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'دفعة أدوات الأنماط الحالية تركّز على Inspector مرئي، قوالب جاهزة، فلترة سريعة، وقراءة أوضح لسلسلة الوراثة بين Profile ← Level ← Period ← Feature.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.78), height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('بحث سريع في المفتاح/الاسم/الملاحظات').copyWith(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => _searchController.clear(),
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilterChip(
                selected: _activeOnly,
                onSelected: (value) => setState(() => _activeOnly = value),
                label: const Text('الفعّال فقط'),
              ),
              const SizedBox(width: 8),
              if (_tabController.index == 0)
                FilterChip(
                  selected: _systemProfilesOnly,
                  onSelected: (value) => setState(() => _systemProfilesOnly = value),
                  label: const Text('النظامية فقط'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusBadge('الترتيب: Profile'),
              _statusBadge('ثم افتراضي المستوى'),
              _statusBadge('ثم Override فترة/مستوى'),
              _statusBadge('ثم Override عنصر'),
            ],
          ),
          if (_tabController.index == 0) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('كل النطاقات'),
                  selected: _profileScopeFilter == 'all',
                  onSelected: (_) => setState(() => _profileScopeFilter = 'all'),
                ),
                for (final scope in const ['level', 'period', 'feature', 'global'])
                  ChoiceChip(
                    label: Text(_scopeLabel(scope)),
                    selected: _profileScopeFilter == scope,
                    onSelected: (_) => setState(() => _profileScopeFilter = scope),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _statusBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.84), fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildProfilesTab() {
    final profilesAsync = ref.watch(historicalStyleProfilesProvider);
    return profilesAsync.when(
      data: (rows) {
        final filtered = rows.where((row) {
          if (_activeOnly && !row.isActive) return false;
          if (_systemProfilesOnly && !row.isSystem) return false;
          if (_profileScopeFilter != 'all' && row.styleScope != _profileScopeFilter) return false;
          return _matchesSearch([row.profileKey, row.profileNameAr, row.profileNameEn, row.notes, row.styleScope]);
        }).toList();
        return _AsyncListWrapper(
          child: filtered.isEmpty
              ? _emptyState('لا توجد ملفات أنماط مطابقة للفلاتر الحالية.')
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final row = filtered[index];
                    return _StyleCard(
                      title: row.profileNameAr,
                      subtitle: row.profileKey,
                      badges: [
                        _scopeLabel(row.styleScope),
                        if (row.isSystem) 'نظامي',
                        _activeLabel(row.isActive),
                      ],
                      preview: row.styleJson,
                      notes: row.notes,
                      onEdit: () => _showProfileDialog(row: row),
                      onDuplicate: () => _showProfileDialog(row: row, duplicate: true),
                      onDelete: row.isSystem
                          ? null
                          : () => _confirmDelete(
                                title: 'حذف ملف النمط ${row.profileNameAr}',
                                onDelete: () => ref
                                    .read(historyStylesAdminRepositoryProvider)
                                    .deleteProfile(row.profileKey),
                              ),
                    );
                  },
                ),
        );
      },
      loading: _loading,
      error: _error,
    );
  }

  Widget _buildLevelDefaultsTab() {
    final defaultsAsync = ref.watch(historicalLevelStyleDefaultsProvider);
    return defaultsAsync.when(
      data: (rows) {
        final filtered = rows.where((row) {
          if (_activeOnly && !row.isActive) return false;
          return _matchesSearch([row.levelKey, row.levelNameAr, row.profileKey, row.profileNameAr, row.notes]);
        }).toList();
        return _AsyncListWrapper(
          child: filtered.isEmpty
              ? _emptyState('لا توجد افتراضيات مستويات مطابقة للفلاتر الحالية.')
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final row = filtered[index];
                    return _StyleCard(
                      title: row.levelNameAr,
                      subtitle: row.levelKey,
                      badges: [
                        row.profileNameAr ?? 'بدون profile',
                        _activeLabel(row.isActive),
                      ],
                      preview: row.overrideStyleJson,
                      notes: row.notes,
                      onEdit: () => _showLevelDefaultDialog(row: row),
                      onDelete: null,
                    );
                  },
                ),
        );
      },
      loading: _loading,
      error: _error,
    );
  }

  Widget _buildPeriodOverridesTab() {
    final rowsAsync = ref.watch(historicalPeriodLevelStyleOverridesProvider);
    return rowsAsync.when(
      data: (rows) {
        final filtered = rows.where((row) {
          if (_activeOnly && !row.isActive) return false;
          return _matchesSearch([row.periodTitleAr, row.levelKey, row.levelNameAr, row.profileKey, row.profileNameAr, row.notes, row.periodNo.toString()]);
        }).toList();
        return _AsyncListWrapper(
          child: filtered.isEmpty
              ? _emptyState('لا توجد Overrides فترة/مستوى مطابقة للفلاتر الحالية.')
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final row = filtered[index];
                    return _StyleCard(
                      title: row.periodTitleAr,
                      subtitle: '${row.levelNameAr} • period_no=${row.periodNo}',
                      badges: [
                        row.levelKey,
                        row.profileNameAr ?? 'بدون profile',
                        _activeLabel(row.isActive),
                      ],
                      preview: row.overrideStyleJson,
                      notes: row.notes,
                      onEdit: () => _showPeriodOverrideDialog(row: row),
                      onDelete: () => _confirmDelete(
                        title: 'حذف override للفترة ${row.periodNo}',
                        onDelete: () => ref
                            .read(historyStylesAdminRepositoryProvider)
                            .deletePeriodLevelOverride(
                              periodNo: row.periodNo,
                              levelKey: row.levelKey,
                            ),
                      ),
                    );
                  },
                ),
        );
      },
      loading: _loading,
      error: _error,
    );
  }

  Widget _buildFeatureOverridesTab() {
    final rowsAsync = ref.watch(historicalFeatureStyleOverridesProvider);
    return rowsAsync.when(
      data: (rows) {
        final filtered = rows.where((row) {
          if (_activeOnly && !row.isActive) return false;
          return _matchesSearch([row.periodTitleAr, row.levelKey, row.levelNameAr, row.sourceTable, row.sourceId, row.profileKey, row.profileNameAr, row.notes, row.periodNo?.toString()]);
        }).toList();
        return _AsyncListWrapper(
          child: filtered.isEmpty
              ? _emptyState('لا توجد Overrides عناصر مطابقة للفلاتر الحالية.')
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final row = filtered[index];
                    return _StyleCard(
                      title: row.periodTitleAr ?? 'Override عام',
                      subtitle: '${row.levelNameAr} • ${row.sourceTable} • ${row.sourceId}',
                      badges: [
                        if (row.periodNo != null) 'period_no=${row.periodNo}',
                        row.profileNameAr ?? 'بدون profile',
                        _activeLabel(row.isActive),
                      ],
                      preview: row.overrideStyleJson,
                      notes: row.notes,
                      onEdit: () => _showFeatureOverrideDialog(row: row),
                      onDelete: () => _confirmDelete(
                        title: 'حذف override للعنصر ${row.sourceId}',
                        onDelete: () => ref
                            .read(historyStylesAdminRepositoryProvider)
                            .deleteFeatureOverride(row.id),
                      ),
                    );
                  },
                ),
        );
      },
      loading: _loading,
      error: _error,
    );
  }

  Widget _loading() => const Center(child: CircularProgressIndicator());

  Widget _error(Object error, StackTrace _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            error.toString(),
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: _inputDecoration(label),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Map<String, dynamic> _parseJsonObject(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
    throw const FormatException('JSON must be an object');
  }
}

class _AsyncListWrapper extends StatelessWidget {
  final Widget child;
  const _AsyncListWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _StyleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> badges;
  final Map<String, dynamic> preview;
  final String? notes;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  const _StyleCard({
    required this.title,
    required this.subtitle,
    required this.badges,
    required this.preview,
    this.notes,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = _colorFromHex(preview['fillColor']?.toString());
    final strokeColor = _colorFromHex(preview['strokeColor']?.toString());
    final labelColor = _colorFromHex(preview['labelColor']?.toString());
    final fillOpacity = _toDouble(preview['fillOpacity']) ?? 0.16;
    final strokeWidth = _toDouble(preview['strokeWidth']) ?? 1.6;
    final labelSize = _toDouble(preview['labelSize']) ?? 12;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                ),
              if (onDuplicate != null)
                IconButton(
                  onPressed: onDuplicate,
                  icon: const Icon(Icons.content_copy_outlined, color: Colors.white70),
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: badges
                .where((e) => e.trim().isNotEmpty)
                .map(
                  (e) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: PwfColors.primaryBlue.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: PwfColors.primaryBlue.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      e,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SwatchRow(
                        label: 'Fill',
                        color: fillColor.withValues(alpha: fillOpacity),
                        value: '${preview['fillColor'] ?? '—'} • ${fillOpacity.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _SwatchRow(
                        label: 'Stroke',
                        color: strokeColor,
                        value: '${preview['strokeColor'] ?? '—'} • ${strokeWidth.toStringAsFixed(1)}',
                      ),
                      const SizedBox(height: 8),
                      _SwatchRow(
                        label: 'Label',
                        color: labelColor,
                        value: '${preview['labelColor'] ?? '—'} • ${labelSize.toStringAsFixed(0)}px',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _MiniStylePreview(
                  fillColor: fillColor.withValues(alpha: fillOpacity),
                  strokeColor: strokeColor,
                  labelColor: labelColor,
                ),
              ],
            ),
          ),
          if (notes != null && notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              notes!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Color _colorFromHex(String? input) {
    if (input == null || input.trim().isEmpty) return const Color(0xFF1D4ED8);
    var hex = input.trim().replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final intValue = int.tryParse(hex, radix: 16);
    if (intValue == null) return const Color(0xFF1D4ED8);
    return Color(intValue);
  }
}

class _SwatchRow extends StatelessWidget {
  final String label;
  final Color color;
  final String value;

  const _SwatchRow({
    required this.label,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
          ),
        ),
      ],
    );
  }
}

class _MiniStylePreview extends StatelessWidget {
  final Color fillColor;
  final Color strokeColor;
  final Color labelColor;

  const _MiniStylePreview({
    required this.fillColor,
    required this.strokeColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 110,
              height: 54,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: strokeColor, width: 2),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'اسم العنصر',
                style: TextStyle(
                  color: labelColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
