import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/colors.dart';
import '../../application/state/history_explorer_state.dart';
import '../../domain/enums/history_explorer_mode.dart';

/// A lightweight investigation workbench for the History Explorer.
///
/// This widget is intentionally UI/runtime-only: it does not load new layers,
/// does not write to sovereign tables, and does not create new SQL contracts.
/// It summarizes the currently loaded historical/modern/waqf context and
/// guides the user through the next safe investigation step.
class HistoryExplorerInvestigationWorkbench extends StatelessWidget {
  const HistoryExplorerInvestigationWorkbench({
    super.key,
    required this.state,
    required this.onModeChanged,
    required this.onPeriodSelected,
    required this.onRefresh,
    required this.onToggleModernContext,
    required this.onToggleWaqfAssets,
    required this.onToggleLineage,
  });

  final HistoryExplorerState state;
  final ValueChanged<HistoryExplorerMode> onModeChanged;
  final ValueChanged<int> onPeriodSelected;
  final VoidCallback onRefresh;
  final VoidCallback onToggleModernContext;
  final VoidCallback onToggleWaqfAssets;
  final VoidCallback onToggleLineage;

  @override
  Widget build(BuildContext context) {
    final selectedPeriod = state.selectedPeriod;
    final selectedIndex = selectedPeriod == null
        ? -1
        : state.periods.indexWhere((item) => item.periodNo == selectedPeriod.periodNo);
    final previousPeriod = selectedIndex > 0 ? state.periods[selectedIndex - 1] : null;
    final nextPeriod = selectedIndex >= 0 && selectedIndex < state.periods.length - 1 ? state.periods[selectedIndex + 1] : null;
    final quality = _InvestigationQuality.fromState(state);
    final focus = _FocusSnapshot.fromState(state);
    final steps = _InvestigationStep.build(state);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PwfColors.primaryBlue.withValues(alpha: 0.98),
            const Color(0xFF12396C),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PwfColors.gold.withValues(alpha: 0.24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: PwfColors.gold.withValues(alpha: 0.28)),
                ),
                child: const Icon(Icons.travel_explore, color: PwfColors.gold, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'منضدة التحقيق التاريخي',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مسار عملي يربط الفترة التاريخية بالسلالة والمرجع الحديث والأصل الوقفي دون تحميل طبقات إضافية.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              _QualityBadge(quality: quality),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DarkMetricPill(
                icon: Icons.history_edu_outlined,
                label: 'الفترة',
                value: selectedPeriod?.titleAr ?? 'غير محددة',
              ),
              _DarkMetricPill(
                icon: Icons.layers_outlined,
                label: 'المستوى',
                value: state.selectedLevelLabel ?? state.selectedLevelKey ?? 'غير محدد',
              ),
              _DarkMetricPill(
                icon: Icons.map_outlined,
                label: 'عناصر تاريخية',
                value: '${state.filteredFeatures.length}',
              ),
              _DarkMetricPill(
                icon: Icons.account_tree_outlined,
                label: 'عقد السلالة',
                value: '${state.resolvedContext.lineageNodes.length}',
              ),
              _DarkMetricPill(
                icon: Icons.place_outlined,
                label: 'مراجع حديثة',
                value: '${state.resolvedContext.modernContexts.length + state.modernSearchResults.length}',
              ),
              _DarkMetricPill(
                icon: Icons.mosque_outlined,
                label: 'أصول وقفية',
                value: '${state.resolvedContext.waqfAssets.length + state.waqfSearchResults.length}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 920;
              final focusCard = _FocusCard(focus: focus, state: state);
              final stepsCard = _StepsCard(steps: steps);
              if (compact) {
                return Column(
                  children: [
                    focusCard,
                    const SizedBox(height: 10),
                    stepsCard,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: focusCard),
                  const SizedBox(width: 10),
                  Expanded(child: stepsCard),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: previousPeriod == null ? null : () => onPeriodSelected(previousPeriod.periodNo),
                icon: const Icon(Icons.chevron_right),
                label: Text(previousPeriod == null ? 'لا توجد فترة سابقة' : 'الفترة السابقة'),
                style: _darkOutlinedStyle(),
              ),
              OutlinedButton.icon(
                onPressed: nextPeriod == null ? null : () => onPeriodSelected(nextPeriod.periodNo),
                icon: const Icon(Icons.chevron_left),
                label: Text(nextPeriod == null ? 'لا توجد فترة لاحقة' : 'الفترة اللاحقة'),
                style: _darkOutlinedStyle(),
              ),
              OutlinedButton.icon(
                onPressed: () => onModeChanged(HistoryExplorerMode.modern),
                icon: const Icon(Icons.location_city_outlined),
                label: const Text('المستكشف الحديث'),
                style: _darkOutlinedStyle(),
              ),
              OutlinedButton.icon(
                onPressed: () => onModeChanged(HistoryExplorerMode.waqf),
                icon: const Icon(Icons.mosque_outlined),
                label: const Text('مستكشف الوقف'),
                style: _darkOutlinedStyle(),
              ),
              OutlinedButton.icon(
                onPressed: onToggleModernContext,
                icon: Icon(state.showModernContext ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                label: Text(state.showModernContext ? 'إخفاء الحديث' : 'إظهار الحديث'),
                style: _darkOutlinedStyle(),
              ),
              OutlinedButton.icon(
                onPressed: onToggleWaqfAssets,
                icon: Icon(state.showWaqfAssets ? Icons.layers_clear_outlined : Icons.layers_outlined),
                label: Text(state.showWaqfAssets ? 'إخفاء الأوقاف' : 'إظهار الأوقاف'),
                style: _darkOutlinedStyle(),
              ),
              OutlinedButton.icon(
                onPressed: onToggleLineage,
                icon: Icon(state.showLineage ? Icons.account_tree : Icons.account_tree_outlined),
                label: Text(state.showLineage ? 'إخفاء السلالة' : 'إظهار السلالة'),
                style: _darkOutlinedStyle(),
              ),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث'),
                style: FilledButton.styleFrom(
                  backgroundColor: PwfColors.gold,
                  foregroundColor: PwfColors.primaryBlue,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _copyInvestigationSummary(context, state, quality, focus, steps),
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('نسخ ملخص التحقيق'),
                style: _darkOutlinedStyle(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static ButtonStyle _darkOutlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    );
  }

  static Future<void> _copyInvestigationSummary(
    BuildContext context,
    HistoryExplorerState state,
    _InvestigationQuality quality,
    _FocusSnapshot focus,
    List<_InvestigationStep> steps,
  ) async {
    final selectedPeriod = state.selectedPeriod;
    final lines = <String>[
      'ملخص التحقيق التاريخي',
      'الوضع: ${_modeLabel(state.mode)}',
      'الفترة: ${selectedPeriod?.titleAr ?? 'غير محددة'}',
      'النطاق الزمني: ${selectedPeriod?.rangeLabelAr ?? 'غير محدد'}',
      'المستوى: ${state.selectedLevelLabel ?? state.selectedLevelKey ?? 'غير محدد'}',
      'التركيز: ${focus.title}',
      'نوع التركيز: ${focus.kind}',
      'درجة نضج الربط: ${quality.score}%',
      'العناصر التاريخية الظاهرة: ${state.filteredFeatures.length}',
      'عقد السلالة: ${state.resolvedContext.lineageNodes.length}',
      'مراجع حديثة: ${state.resolvedContext.modernContexts.length + state.modernSearchResults.length}',
      'أصول وقفية: ${state.resolvedContext.waqfAssets.length + state.waqfSearchResults.length}',
      'الخطوات المقترحة:',
      ...steps.map((step) => '- ${step.title}: ${step.detail}'),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ ملخص التحقيق التاريخي.')),
    );
  }

  static String _modeLabel(HistoryExplorerMode mode) {
    switch (mode) {
      case HistoryExplorerMode.historical:
        return 'تاريخي';
      case HistoryExplorerMode.modern:
        return 'حديث';
      case HistoryExplorerMode.waqf:
        return 'وقف';
    }
  }
}

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.quality});

  final _InvestigationQuality quality;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: quality.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: quality.color.withValues(alpha: 0.36)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${quality.score}%',
            style: TextStyle(color: quality.color, fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            quality.label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontWeight: FontWeight.w800, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _DarkMetricPill extends StatelessWidget {
  const _DarkMetricPill({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: PwfColors.gold),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.66), fontWeight: FontWeight.w800, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.focus, required this.state});

  final _FocusSnapshot focus;
  final HistoryExplorerState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.center_focus_strong_outlined, color: PwfColors.gold),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'بؤرة التحقيق الحالية',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
              _TinyBadge(label: focus.kind),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            focus.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: 6),
          Text(
            focus.subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontWeight: FontWeight.w700, height: 1.55),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _TinyBadge(label: 'سلالة: ${state.resolvedContext.lineageNodes.length}'),
              _TinyBadge(label: 'حديث: ${state.resolvedContext.modernContexts.length}'),
              _TinyBadge(label: 'وقف: ${state.resolvedContext.waqfAssets.length}'),
              if (state.resolvedContext.isSovereign) const _TinyBadge(label: 'ربط سيادي'),
              if (state.contextErrorMessage != null) const _TinyBadge(label: 'يوجد خطأ ربط', warning: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.steps});

  final List<_InvestigationStep> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.route_outlined, color: PwfColors.gold),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'مسار التحقيق المقترح',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: step.done ? PwfColors.success.withValues(alpha: 0.18) : PwfColors.gold.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: step.done ? PwfColors.success.withValues(alpha: 0.44) : PwfColors.gold.withValues(alpha: 0.36),
                        ),
                      ),
                      child: Icon(
                        step.done ? Icons.check : step.icon,
                        color: step.done ? PwfColors.success : PwfColors.gold,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.detail,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.70), fontWeight: FontWeight.w700, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, this.warning = false});

  final String label;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? PwfColors.warning : PwfColors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(color: warning ? PwfColors.warning : Colors.white.withValues(alpha: 0.86), fontWeight: FontWeight.w900, fontSize: 11),
      ),
    );
  }
}

class _InvestigationQuality {
  const _InvestigationQuality({required this.score, required this.label, required this.color});

  final int score;
  final String label;
  final Color color;

  factory _InvestigationQuality.fromState(HistoryExplorerState state) {
    var score = 0;
    if (state.selectedPeriod != null) score += 15;
    if ((state.selectedLevelKey ?? '').trim().isNotEmpty) score += 10;
    if (state.selectedFeature != null || state.selectedModernContext != null || state.selectedWaqfAsset != null || state.selectedWaqfAssetRecord != null) {
      score += 20;
    }
    if (state.resolvedContext.lineageNodes.isNotEmpty) score += 20;
    if (state.resolvedContext.modernContexts.isNotEmpty || state.modernSearchResults.isNotEmpty) score += 15;
    if (state.resolvedContext.waqfAssets.isNotEmpty || state.waqfSearchResults.isNotEmpty || state.selectedWaqfAssetRecord != null) score += 15;
    if (state.resolvedContext.isSovereign) score += 5;
    score = score.clamp(0, 100).toInt();

    if (score >= 75) return _InvestigationQuality(score: score, label: 'ناضج', color: PwfColors.success);
    if (score >= 45) return _InvestigationQuality(score: score, label: 'متوسط', color: PwfColors.gold);
    return _InvestigationQuality(score: score, label: 'أولي', color: PwfColors.warning);
  }
}

class _FocusSnapshot {
  const _FocusSnapshot({required this.kind, required this.title, required this.subtitle});

  final String kind;
  final String title;
  final String subtitle;

  factory _FocusSnapshot.fromState(HistoryExplorerState state) {
    final waqfRecord = state.selectedWaqfAssetRecord;
    if (waqfRecord != null) {
      return _FocusSnapshot(
        kind: 'أصل وقفي',
        title: waqfRecord.displayLabel,
        subtitle: [
          waqfRecord.nationalAssetCode,
          waqfRecord.endowmentName,
          waqfRecord.currentGovernorate,
          waqfRecord.currentLgu,
        ].where((item) => (item ?? '').trim().isNotEmpty).join(' • '),
      );
    }

    final waqf = state.selectedWaqfAsset;
    if (waqf != null) {
      return _FocusSnapshot(
        kind: 'أصل وقفي',
        title: waqf.displayLabel,
        subtitle: [waqf.pwfKey, waqf.governorate, waqf.municipality, waqf.community].where((item) => (item ?? '').trim().isNotEmpty).join(' • '),
      );
    }

    final modern = state.selectedModernContext;
    if (modern != null) {
      return _FocusSnapshot(
        kind: 'مرجع حديث',
        title: modern.communityLabel,
        subtitle: [modern.governorateLabel, modern.lguLabel, modern.communityCode].where((item) => (item ?? '').trim().isNotEmpty).join(' • '),
      );
    }

    final feature = state.selectedFeature;
    if (feature != null) {
      return _FocusSnapshot(
        kind: 'عنصر تاريخي',
        title: feature.displayLabel,
        subtitle: [feature.periodLabelAr, feature.levelKey, feature.chainKey, feature.entityCode].where((item) => (item ?? '').trim().isNotEmpty).join(' • '),
      );
    }

    final selectedPeriod = state.selectedPeriod;
    return _FocusSnapshot(
      kind: 'استكشاف',
      title: selectedPeriod?.titleAr ?? 'لا توجد بؤرة محددة بعد',
      subtitle: selectedPeriod?.summaryAr ?? 'اختر عنصرًا تاريخيًا أو أصلًا وقفيًا لبدء بناء السلالة والتحقق المكاني.',
    );
  }
}

class _InvestigationStep {
  const _InvestigationStep({required this.title, required this.detail, required this.icon, required this.done});

  final String title;
  final String detail;
  final IconData icon;
  final bool done;

  static List<_InvestigationStep> build(HistoryExplorerState state) {
    final hasFocus = state.selectedFeature != null ||
        state.selectedModernContext != null ||
        state.selectedWaqfAsset != null ||
        state.selectedWaqfAssetRecord != null;
    final hasLineage = state.resolvedContext.lineageNodes.isNotEmpty;
    final hasModern = state.resolvedContext.modernContexts.isNotEmpty || state.modernSearchResults.isNotEmpty;
    final hasWaqf = state.resolvedContext.waqfAssets.isNotEmpty || state.waqfSearchResults.isNotEmpty || state.selectedWaqfAssetRecord != null;
    final hasGapsRisk = state.contextErrorMessage != null ||
        (hasFocus && !hasLineage) ||
        (state.mode == HistoryExplorerMode.waqf && state.linkedParcels.isEmpty);

    return [
      _InvestigationStep(
        title: 'تثبيت الفترة والمستوى',
        detail: state.selectedPeriod == null ? 'ابدأ باختيار فترة تاريخية قابلة للتحليل.' : 'الفترة والمستوى جاهزان للتحقيق.',
        icon: Icons.timeline_outlined,
        done: state.selectedPeriod != null && (state.selectedLevelKey ?? '').trim().isNotEmpty,
      ),
      _InvestigationStep(
        title: 'تحديد بؤرة التحقيق',
        detail: hasFocus ? 'هناك عنصر محدد يمكن بناء السياق عليه.' : 'اختر عنصرًا من الخريطة أو من قائمة النتائج.',
        icon: Icons.center_focus_strong_outlined,
        done: hasFocus,
      ),
      _InvestigationStep(
        title: 'اختبار السلالة التاريخية',
        detail: hasLineage ? 'تم العثور على عقد سلالة يمكن مراجعتها.' : 'فعّل/راجع السلالة لاكتشاف الفراغات بين الفترات.',
        icon: Icons.account_tree_outlined,
        done: hasLineage,
      ),
      _InvestigationStep(
        title: 'مقارنة المرجع الحديث',
        detail: hasModern ? 'هناك مراجع حديثة للمقارنة.' : 'انتقل للمستكشف الحديث أو أظهر المرجع الحديث.',
        icon: Icons.location_city_outlined,
        done: hasModern,
      ),
      _InvestigationStep(
        title: 'ربط الأصل الوقفي',
        detail: hasWaqf ? 'توجد أصول وقفية في سياق التحقيق.' : 'انتقل لمستكشف الوقف أو أظهر الأصول المرتبطة.',
        icon: Icons.mosque_outlined,
        done: hasWaqf,
      ),
      _InvestigationStep(
        title: 'قرار تدقيق',
        detail: hasGapsRisk ? 'توجد مؤشرات تحتاج طلب تدقيق أو مراجعة فجوة.' : 'لا توجد مؤشرات حرجة ظاهرة حاليًا.',
        icon: Icons.fact_check_outlined,
        done: !hasGapsRisk,
      ),
    ];
  }
}
