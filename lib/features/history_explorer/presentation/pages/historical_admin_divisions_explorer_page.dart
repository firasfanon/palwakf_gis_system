import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../application/providers/history_explorer_providers.dart';
import '../../application/state/history_explorer_state.dart';
import '../../domain/enums/history_explorer_mode.dart';
import '../../domain/models/history_overlay_feature.dart';
import '../panels/explorer_sidebar.dart';
import '../panels/lineage_sidebar.dart';
import '../widgets/explorer_suite_contract_panel.dart';
import '../widgets/history_explorer_data_gaps_panel.dart';
import '../widgets/history_map_canvas.dart';
import '../widgets/history_timeline_strip.dart';

class HistoricalAdminDivisionsExplorerPage extends ConsumerStatefulWidget {
  const HistoricalAdminDivisionsExplorerPage({super.key, this.embeddedInAdmin = false});

  final bool embeddedInAdmin;

  @override
  ConsumerState<HistoricalAdminDivisionsExplorerPage> createState() =>
      _HistoricalAdminDivisionsExplorerPageState();
}

class _HistoricalAdminDivisionsExplorerPageState
    extends ConsumerState<HistoricalAdminDivisionsExplorerPage> {
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final controller = ref.read(historyExplorerControllerProvider.notifier);
      final current = ref.read(historyExplorerControllerProvider);
      if (current.mode != HistoryExplorerMode.historical) {
        await controller.selectMode(HistoryExplorerMode.historical);
      }
      final latest = ref.read(historyExplorerControllerProvider);
      if (!latest.showModernContext) controller.toggleModernContext();
      if (!latest.showLineage) controller.toggleLineage();
      if (!latest.showLabels) controller.toggleLabels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyExplorerControllerProvider);
    final controller = ref.read(historyExplorerControllerProvider.notifier);

    final body = LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1280;
        final medium = constraints.maxWidth >= 940;
        final map = HistoryMapCanvas(
          state: state,
          onFeatureSelected: controller.selectFeature,
          onModernContextSelected: controller.inspectModernContext,
          onWaqfAssetSelected: controller.inspectWaqfAsset,
        );
        final explorer = ExplorerSidebar(
          state: state,
          onPeriodSelected: controller.selectPeriod,
          onFeatureSelected: controller.selectFeature,
          onModernContextSelected: controller.selectModernContext,
          onWaqfAssetSelected: controller.selectWaqfAsset,
        );
        final lineage = LineageSidebar(state: state);
        final timeline = HistoryTimelineStrip(
          periods: state.periods,
          selectedPeriodNo: state.selectedPeriodNo,
          onPeriodSelected: controller.selectPeriod,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          children: [
            _HistoricalAdminHeader(
              state: state,
              embeddedInAdmin: widget.embeddedInAdmin,
              onRefresh: controller.refreshCurrentMode,
            ),
            const SizedBox(height: 12),
            const ExplorerSuiteContractPanel(),
            const SizedBox(height: 12),
            _HistoricalAdminControls(
              state: state,
              onPeriodSelected: controller.selectPeriod,
              onLevelSelected: controller.selectLevel,
              onSearchChanged: controller.setSearchQuery,
              onToggleModernContext: controller.toggleModernContext,
              onToggleLineage: controller.toggleLineage,
              onToggleLabels: controller.toggleLabels,
              onToggleBoundariesOnly: controller.toggleBoundariesOnly,
            ),
            const SizedBox(height: 12),
            _HistoricalAdminMetrics(state: state),
            const SizedBox(height: 12),
            _HistoricalAdminGapsAndActions(
              state: state,
              onRefresh: controller.refreshCurrentMode,
            ),
            const SizedBox(height: 12),
            if (state.errorMessage != null) ...[
              _ErrorBanner(message: state.errorMessage!),
              const SizedBox(height: 12),
            ],
            if (wide)
              SizedBox(
                height: 760,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 330, child: explorer),
                    const SizedBox(width: 14),
                    Expanded(child: map),
                    const SizedBox(width: 14),
                    SizedBox(width: 330, child: lineage),
                  ],
                ),
              )
            else if (medium)
              SizedBox(
                height: 1040,
                child: Column(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 300, child: explorer),
                          const SizedBox(width: 14),
                          Expanded(child: map),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(height: 320, child: lineage),
                  ],
                ),
              )
            else ...[
              SizedBox(height: 520, child: map),
              const SizedBox(height: 14),
              SizedBox(height: 520, child: explorer),
              const SizedBox(height: 14),
              SizedBox(height: 440, child: lineage),
            ],
            const SizedBox(height: 14),
            timeline,
            const SizedBox(height: 14),
            HistoryExplorerDataGapsPanel(state: state),
          ],
        );
      },
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          title: const Text('مستكشف التقسيمات الإدارية التاريخية'),
          backgroundColor: Colors.transparent,
          foregroundColor: PwfColors.primaryBlue,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            TextButton.icon(
              onPressed: () => context.go('/history'),
              icon: const Icon(Icons.history_edu_outlined),
              label: const Text('مستكشف التاريخ'),
            ),
            TextButton.icon(
              onPressed: () => context.go('/map'),
              icon: const Icon(Icons.map_outlined),
              label: const Text('المستكشف الحديث'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(child: body),
      ),
    );
  }
}

class _HistoricalAdminHeader extends StatelessWidget {
  const _HistoricalAdminHeader({
    required this.state,
    required this.embeddedInAdmin,
    required this.onRefresh,
  });

  final HistoryExplorerState state;
  final bool embeddedInAdmin;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final period = state.selectedPeriod;
    final periodTitle = period?.titleAr.trim().isNotEmpty == true
        ? period!.titleAr.trim()
        : 'لم تُحدد فترة';
    final level = state.selectedLevelLabel ?? 'كل المستويات المتاحة';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PwfColors.primaryBlue,
            PwfColors.primaryBlue.withValues(alpha: 0.88),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.account_tree_outlined, color: PwfColors.primaryGold, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مستكشف التقسيمات الإدارية التاريخية',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 21),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'صفحة تابعة لمستكشف التاريخ لتتبع السلالات الإدارية السابقة للتقسيم الحديث ومقارنتها بالمرجع الحالي.',
                      style: TextStyle(color: Colors.white70, height: 1.45, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'تحديث',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderChip(icon: Icons.calendar_month_outlined, label: 'الفترة: $periodTitle'),
              _HeaderChip(icon: Icons.layers_outlined, label: 'المستوى: $level'),
              _HeaderChip(icon: Icons.compare_arrows_outlined, label: state.showModernContext ? 'المقارنة الحديثة مفعلة' : 'المقارنة الحديثة متوقفة'),
              _HeaderChip(icon: Icons.account_tree_outlined, label: state.showLineage ? 'السلالة مفعلة' : 'السلالة متوقفة'),
              if (embeddedInAdmin) const _HeaderChip(icon: Icons.admin_panel_settings_outlined, label: 'ضمن Dashboard'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoricalAdminControls extends StatelessWidget {
  const _HistoricalAdminControls({
    required this.state,
    required this.onPeriodSelected,
    required this.onLevelSelected,
    required this.onSearchChanged,
    required this.onToggleModernContext,
    required this.onToggleLineage,
    required this.onToggleLabels,
    required this.onToggleBoundariesOnly,
  });

  final HistoryExplorerState state;
  final ValueChanged<int> onPeriodSelected;
  final ValueChanged<String?> onLevelSelected;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleModernContext;
  final VoidCallback onToggleLineage;
  final VoidCallback onToggleLabels;
  final VoidCallback onToggleBoundariesOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أدوات التقسيم الإداري التاريخي',
            style: TextStyle(color: PwfColors.primaryBlue, fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<int>(
                  value: state.selectedPeriodNo,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'الفترة التاريخية',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: state.periods
                      .map(
                        (period) => DropdownMenuItem<int>(
                          value: period.periodNo,
                          child: Text(
                            period.titleAr.trim().isNotEmpty ? period.titleAr : 'فترة ${period.periodNo}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) onPeriodSelected(value);
                  },
                ),
              ),
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String>(
                  value: state.selectedLevelKey,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'المستوى الإداري',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: state.levels
                      .map(
                        (level) => DropdownMenuItem<String>(
                          value: level.levelKey,
                          child: Text(level.displayLabel, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: onLevelSelected,
                ),
              ),
              SizedBox(
                width: 280,
                child: TextFormField(
                  initialValue: state.searchQuery,
                  decoration: const InputDecoration(
                    labelText: 'بحث باسم تاريخي أو رمز',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              _ToggleChip(
                label: 'الحديث',
                icon: Icons.map_outlined,
                active: state.showModernContext,
                onTap: onToggleModernContext,
              ),
              _ToggleChip(
                label: 'السلالة',
                icon: Icons.account_tree_outlined,
                active: state.showLineage,
                onTap: onToggleLineage,
              ),
              _ToggleChip(
                label: 'التسميات',
                icon: Icons.label_outline,
                active: state.showLabels,
                onTap: onToggleLabels,
              ),
              _ToggleChip(
                label: 'حدود فقط',
                icon: Icons.crop_square_outlined,
                active: state.boundariesOnly,
                onTap: onToggleBoundariesOnly,
              ),
            ],
          ),
          if (state.isSearchDebouncing || (state.runtimeMessage ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              state.isSearchDebouncing ? 'جاري تجهيز البحث...' : state.runtimeMessage ?? '',
              style: const TextStyle(color: PwfColors.warning, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoricalAdminMetrics extends StatelessWidget {
  const _HistoricalAdminMetrics({required this.state});

  final HistoryExplorerState state;

  @override
  Widget build(BuildContext context) {
    final features = state.filteredFeatures;
    final chainCount = features.where((f) => (f.chainKey ?? '').trim().isNotEmpty).length;
    final parentCount = features.where((f) => (f.parentSourceId ?? '').trim().isNotEmpty).length;
    final spatialCount = features.where((f) => f.geomJson != null || f.centroidJson != null).length;
    final levelBuckets = <String>{};
    for (final feature in features) {
      final key = (feature.levelKey ?? '').trim();
      if (key.isNotEmpty) levelBuckets.add(key);
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MetricCard(label: 'العناصر الظاهرة', value: '${features.length}', icon: Icons.account_tree_outlined, color: PwfColors.primaryBlue),
        _MetricCard(label: 'بسلالة', value: '$chainCount', icon: Icons.schema_outlined, color: PwfColors.success),
        _MetricCard(label: 'بأصل إداري أعلى', value: '$parentCount', icon: Icons.call_split_outlined, color: PwfColors.warning),
        _MetricCard(label: 'بتمثيل مكاني', value: '$spatialCount', icon: Icons.place_outlined, color: PwfColors.royalRed),
        _MetricCard(label: 'مستويات ظاهرة', value: '${levelBuckets.length}', icon: Icons.layers_outlined, color: PwfColors.primaryGold),
      ],
    );
  }
}

class _HistoricalAdminGapsAndActions extends StatelessWidget {
  const _HistoricalAdminGapsAndActions({required this.state, required this.onRefresh});

  final HistoryExplorerState state;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final gaps = _HistoricalAdminGap.analyze(state);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PwfColors.royalRed.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule_folder_outlined, color: PwfColors.royalRed),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'محاذاة التقسيمات التاريخية مع الحديث والوقف',
                  style: TextStyle(color: PwfColors.primaryBlue, fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث'),
              ),
              TextButton.icon(
                onPressed: () => _copySummary(context, state, gaps),
                icon: const Icon(Icons.copy_outlined),
                label: const Text('نسخ ملخص'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionPill(
                label: 'فتح مستكشف التاريخ',
                icon: Icons.history_edu_outlined,
                onTap: () => context.go('/history'),
              ),
              _ActionPill(
                label: 'فتح المستكشف الحديث',
                icon: Icons.map_outlined,
                onTap: () => context.go('/map'),
              ),
              _ActionPill(
                label: 'مراجعة الفجوات',
                icon: Icons.fact_check_outlined,
                onTap: () => context.go('/admin/explorer-gap-audits'),
              ),
              _ActionPill(
                label: 'المستكشف الذكي',
                icon: Icons.psychology_alt_outlined,
                onTap: () => context.go('/admin/smart-explorer'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (gaps.isEmpty)
            const Text(
              'لا توجد فجوات واضحة ضمن العناصر الظاهرة حاليًا. استمر بتوسيع الفترات والمستويات للمراجعة.',
              style: TextStyle(color: PwfColors.success, fontWeight: FontWeight.w800),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: gaps
                  .map(
                    (gap) => Container(
                      width: 330,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: gap.color.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: gap.color.withValues(alpha: 0.18)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(gap.icon, color: gap.color, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  gap.title,
                                  style: TextStyle(color: gap.color, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            gap.detail,
                            style: const TextStyle(color: Color(0xFF475569), height: 1.35, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  static Future<void> _copySummary(
    BuildContext context,
    HistoryExplorerState state,
    List<_HistoricalAdminGap> gaps,
  ) async {
    final period = state.selectedPeriod?.titleAr ?? state.selectedPeriodNo?.toString() ?? 'غير محدد';
    final level = state.selectedLevelLabel ?? state.selectedLevelKey ?? 'غير محدد';
    final lines = <String>[
      'ملخص مستكشف التقسيمات الإدارية التاريخية',
      'الفترة: $period',
      'المستوى: $level',
      'العناصر الظاهرة: ${state.filteredFeatures.length}',
      'الفجوات: ${gaps.length}',
      for (final gap in gaps) '- ${gap.title}: ${gap.detail}',
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ ملخص التقسيمات الإدارية التاريخية')),
      );
    }
  }
}

class _HistoricalAdminGap {
  const _HistoricalAdminGap({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;

  static List<_HistoricalAdminGap> analyze(HistoryExplorerState state) {
    final features = state.filteredFeatures;
    final gaps = <_HistoricalAdminGap>[];
    if (state.selectedPeriodNo == null) {
      gaps.add(const _HistoricalAdminGap(
        title: 'فترة غير محددة',
        detail: 'يجب اختيار فترة تاريخية قبل تحليل السلالة الإدارية.',
        icon: Icons.calendar_month_outlined,
        color: PwfColors.warning,
      ));
    }
    if (state.selectedLevelKey == null || state.selectedLevelKey!.trim().isEmpty) {
      gaps.add(const _HistoricalAdminGap(
        title: 'مستوى إداري غير محدد',
        detail: 'اختر مستوى مثل ولاية/قضاء/ناحية/قرية بحسب الفترة المتاحة.',
        icon: Icons.layers_outlined,
        color: PwfColors.warning,
      ));
    }
    if (features.isEmpty && state.selectedPeriodNo != null) {
      gaps.add(const _HistoricalAdminGap(
        title: 'لا توجد عناصر ظاهرة',
        detail: 'الفترة أو المستوى المختار لا يعرض عناصر مكانية حاليًا، أو يحتاج مصدر بيانات تاريخي.',
        icon: Icons.visibility_off_outlined,
        color: PwfColors.royalRed,
      ));
    }
    final noChain = features.where((f) => (f.chainKey ?? '').trim().isEmpty).length;
    if (noChain > 0) {
      gaps.add(_HistoricalAdminGap(
        title: 'عناصر بلا مفتاح سلالة',
        detail: '$noChain عنصرًا لا يملك chainKey، وهذا يضعف الربط بين التقسيم التاريخي والحديث.',
        icon: Icons.account_tree_outlined,
        color: PwfColors.royalRed,
      ));
    }
    final noParent = features.where((f) => (f.parentSourceId ?? '').trim().isEmpty).length;
    if (features.length > 1 && noParent > 0) {
      gaps.add(_HistoricalAdminGap(
        title: 'عناصر بلا أصل إداري أعلى',
        detail: '$noParent عنصرًا لا يملك parentSourceId، لذلك قد لا تظهر علاقات ولاية/قضاء/ناحية بشكل مكتمل.',
        icon: Icons.call_split_outlined,
        color: PwfColors.warning,
      ));
    }
    final noSpatial = features.where((f) => f.geomJson == null && f.centroidJson == null).length;
    if (noSpatial > 0) {
      gaps.add(_HistoricalAdminGap(
        title: 'عناصر بلا تمثيل مكاني',
        detail: '$noSpatial عنصرًا لا يملك هندسة أو مركزًا، ويحتاج ربطًا أو تقديرًا مكانيًا لاحقًا.',
        icon: Icons.place_outlined,
        color: PwfColors.warning,
      ));
    }
    final noLabel = features.where((f) => f.displayLabel.trim().isEmpty).length;
    if (noLabel > 0) {
      gaps.add(_HistoricalAdminGap(
        title: 'تسميات ناقصة',
        detail: '$noLabel عنصرًا يحتاج تسمية عربية/إنجليزية واضحة للعرض والبحث.',
        icon: Icons.label_off_outlined,
        color: PwfColors.royalRed,
      ));
    }
    if (!state.showModernContext) {
      gaps.add(const _HistoricalAdminGap(
        title: 'المقارنة الحديثة غير مفعلة',
        detail: 'فعّل المرجع الحديث لاختبار انتقال التقسيم التاريخي إلى المحافظة/الهيئة/التجمع الحالي.',
        icon: Icons.compare_arrows_outlined,
        color: PwfColors.primaryBlue,
      ));
    }
    return gaps;
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: PwfColors.primaryGold, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? PwfColors.primaryBlue : const Color(0xFF64748B);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: active ? 0.10 : 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: active ? 0.28 : 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 17)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: PwfColors.primaryBlue),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: PwfColors.royalRed.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PwfColors.royalRed.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: PwfColors.royalRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: PwfColors.royalRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
