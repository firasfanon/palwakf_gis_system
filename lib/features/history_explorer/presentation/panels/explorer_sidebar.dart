import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/pwf_card.dart';
import '../../application/state/history_explorer_state.dart';
import '../../domain/enums/history_explorer_mode.dart';
import '../../domain/models/history_modern_context.dart';
import '../../domain/models/history_overlay_feature.dart';
import '../../domain/models/history_period_item.dart';
import '../../domain/models/history_waqf_asset_link.dart';
import '../widgets/waqf_reference_preview_card.dart';

class ExplorerSidebar extends StatelessWidget {
  const ExplorerSidebar({
    super.key,
    required this.state,
    required this.onPeriodSelected,
    required this.onFeatureSelected,
    required this.onModernContextSelected,
    required this.onWaqfAssetSelected,
  });

  final HistoryExplorerState state;
  final ValueChanged<int> onPeriodSelected;
  final ValueChanged<String?> onFeatureSelected;
  final ValueChanged<String?> onModernContextSelected;
  final ValueChanged<String?> onWaqfAssetSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'دليل الاستكشاف',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _modeDescription(state.mode),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoBadge(label: 'الفترة: ${state.selectedPeriodNo ?? '—'}', color: PwfColors.primaryBlue),
                  _InfoBadge(label: 'المستوى: ${state.selectedLevelKey ?? '—'}', color: PwfColors.success),
                  _InfoBadge(label: 'نتائج الخريطة: ${state.filteredFeatures.length}', color: PwfColors.warning),
                  if (state.mode == HistoryExplorerMode.modern)
                    _InfoBadge(label: 'وحدات حديثة: ${state.modernSearchResults.length}', color: PwfColors.success),
                  if (state.mode == HistoryExplorerMode.waqf)
                    _InfoBadge(label: 'أصول وقفية: ${state.waqfSearchResults.length}', color: PwfColors.royalRed),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              if (state.selectedPeriod != null) ...[
                _SelectedPeriodCard(period: state.selectedPeriod!, state: state),
                const SizedBox(height: 12),
                _RecommendedActionsCard(state: state),
                const SizedBox(height: 12),
              ],
              _PeriodsListCard(
                periods: state.periods,
                selectedPeriodNo: state.selectedPeriodNo,
                onPeriodSelected: onPeriodSelected,
              ),
              const SizedBox(height: 12),
              _buildBody(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (state.mode) {
      case HistoryExplorerMode.modern:
        return _buildModernBody(context);
      case HistoryExplorerMode.waqf:
        return _buildWaqfBody(context);
      case HistoryExplorerMode.historical:
        return _buildHistoricalBody(context);
    }
  }

  Widget _buildHistoricalBody(BuildContext context) {
    if (state.selectedPeriod == null) {
      return const _SectionCard(
        title: 'اختر فترة',
        child: Text('ابدأ باختيار فترة تاريخية من الأعلى أو من الشريط الزمني لعرض المحتوى أو الطبقات المكانية المتاحة.'),
      );
    }

    if (!state.canDrawOverlay) {
      final period = state.selectedPeriod!;
      return _SectionCard(
        title: 'محتوى الفترة',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoBadge(label: period.periodKind.labelAr, color: _badgeColor(period.periodKind.name)),
            const SizedBox(height: 10),
            Text(
              period.summaryAr?.trim().isNotEmpty == true
                  ? period.summaryAr!
                  : 'هذه الفترة تُعرض كبطاقة تفسيرية/مرجعية في هذه المرحلة ولا تملك طبقة تشغيلية مباشرة.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
            ),
            if (period.scopeLabelAr?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _InfoLine(label: 'النطاق', value: period.scopeLabelAr!),
            ],
            if (period.defaultLevelKey?.trim().isNotEmpty == true)
              _InfoLine(label: 'المستوى الافتراضي', value: period.defaultLevelKey!),
          ],
        ),
      );
    }

    final features = state.filteredFeatures;
    return Column(
      children: [
        _SectionCard(
          title: 'المستوى والعرض الحالي',
          child: Column(
            children: [
              _InfoLine(label: 'المستوى المختار', value: state.selectedLevelKey ?? '—'),
              _InfoLine(label: 'عدد الصفوف المتاحة', value: '${state.overlayFeatures.length}'),
              _InfoLine(label: 'النتائج بعد البحث', value: '${features.length}'),
              _InfoLine(label: 'إظهار التسميات', value: state.showLabels ? 'نعم' : 'لا'),
              _InfoLine(label: 'الحدود فقط', value: state.boundariesOnly ? 'نعم' : 'لا'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'العناصر المكانية',
          trailing: Text('${features.length}', style: const TextStyle(fontWeight: FontWeight.w800)),
          child: features.isEmpty
              ? const Text('لا توجد عناصر مطابقة للفلاتر الحالية.')
              : Column(
                  children: features
                      .take(80)
                      .map(
                        (feature) => _FeatureTile(
                          feature: feature,
                          selected: state.selectedFeatureId == feature.sourceId,
                          onTap: () => onFeatureSelected(state.selectedFeatureId == feature.sourceId ? null : feature.sourceId),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }

  Widget _buildModernBody(BuildContext context) {
    final items = state.modernSearchResults;
    return Column(
      children: [
        _SectionCard(
          title: 'الوحدات الحديثة',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر تجمعًا حديثًا أو ابحث عنه من الأعلى، وسيُبنى منه مرجع إداري حديث ثم محاولة صعود إلى السجل التاريخي.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
              ),
              const SizedBox(height: 10),
              _InfoLine(label: 'عدد النتائج', value: '${items.length}'),
              _InfoLine(label: 'البحث الحالي', value: state.searchQuery.trim().isEmpty ? 'بدون فلترة' : state.searchQuery),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'التجمعات/الوحدات الحديثة',
          trailing: Text('${items.length}', style: const TextStyle(fontWeight: FontWeight.w800)),
          child: items.isEmpty
              ? const Text('لا توجد وحدات حديثة مطابقة للبحث الحالي.')
              : Column(
                  children: items
                      .take(80)
                      .map(
                        (item) => _ModernContextTile(
                          item: item,
                          selected: state.selectedModernContextCode == item.communityCode,
                          onTap: () => onModernContextSelected(
                            state.selectedModernContextCode == item.communityCode ? null : item.communityCode,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }

  Widget _buildWaqfBody(BuildContext context) {
    final items = state.waqfSearchResults;
    final selectedAsset = state.selectedWaqfAsset;
    return Column(
      children: [
        _SectionCard(
          title: 'الأصول الوقفية الحديثة',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ابدأ من أصل وقفي حديث أو PWF أو قطعة، ثم دع الصفحة تحاول بناء مرجعه الإداري الحديث ومنه السلسلة التاريخية.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
              ),
              const SizedBox(height: 10),
              _InfoLine(label: 'عدد النتائج', value: '${items.length}'),
              _InfoLine(label: 'البحث الحالي', value: state.searchQuery.trim().isEmpty ? 'بدون فلترة' : state.searchQuery),
              if (selectedAsset != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoBadge(label: 'المحدد: ${selectedAsset.displayLabel}', color: PwfColors.royalRed),
                    if ((selectedAsset.endowerName ?? '').trim().isNotEmpty)
                      _InfoBadge(label: 'الواقف: ${selectedAsset.endowerName}', color: PwfColors.primaryBlue),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (selectedAsset != null) ...[
          const SizedBox(height: 12),
          WaqfReferencePreviewCard(
            asset: selectedAsset,
            title: 'المرجع الوقفي المحدد',
            compact: true,
          ),
        ],
        const SizedBox(height: 12),
        _SectionCard(
          title: 'نتائج البحث الوقفي',
          trailing: Text('${items.length}', style: const TextStyle(fontWeight: FontWeight.w800)),
          child: items.isEmpty
              ? const Text('لا توجد أصول وقفية مطابقة للبحث الحالي.')
              : Column(
                  children: items
                      .take(80)
                      .map(
                        (item) => _WaqfAssetTile(
                          item: item,
                          selected: state.selectedWaqfAssetId == item.id,
                          onTap: () => onWaqfAssetSelected(state.selectedWaqfAssetId == item.id ? null : item.id),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }

  String _modeDescription(HistoryExplorerMode mode) {
    switch (mode) {
      case HistoryExplorerMode.historical:
        return 'يعرض هذا الوضع الكيان التاريخي الأصلي للفترة المختارة مع إبقاء المرجع الحديث والوقفـي كطبقات تفسيرية قابلة للتوسعة.';
      case HistoryExplorerMode.modern:
        return 'هذا الوضع أصبح فعّالًا: يبدأ من التجمع أو المرجع الإداري الحديث ثم يحاول العودة عبر origin_community_code إلى السجل التاريخي.';
      case HistoryExplorerMode.waqf:
        return 'هذا الوضع أصبح فعّالًا: يبدأ من الأصل الوقفي الحديث ثم يحاول مطابقة مرجعه الحديث ومنه الصعود إلى الجذر التاريخي.';
    }
  }

  Color _badgeColor(String rawKind) {
    switch (rawKind) {
      case 'descriptive':
        return PwfColors.primaryBlue;
      case 'reference':
        return PwfColors.warning;
      case 'drawable':
        return PwfColors.success;
      default:
        return PwfColors.royalRed;
    }
  }
}

class _SelectedPeriodCard extends StatelessWidget {
  const _SelectedPeriodCard({required this.period, required this.state});

  final HistoryPeriodItem period;
  final HistoryExplorerState state;

  @override
  Widget build(BuildContext context) {
    final color = _kindColor(period.periodKind.name);
    return _SectionCard(
      title: 'الفترة المختارة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${period.periodNo} — ${period.titleAr}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          if (period.rangeLabelAr?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              period.rangeLabelAr!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PwfColors.onSurface.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoBadge(label: period.periodKind.labelAr, color: color),
              _InfoBadge(label: period.hasOverlay ? 'لها overlay' : 'بدون overlay', color: period.hasOverlay ? PwfColors.success : PwfColors.warning),
              if (period.defaultLevelKey?.trim().isNotEmpty == true)
                _InfoBadge(label: 'الافتراضي: ${period.defaultLevelKey}', color: PwfColors.primaryBlue),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            period.summaryAr?.trim().isNotEmpty == true
                ? period.summaryAr!
                : 'هذه الفترة ما زالت بانتظار إثراء وصفي/مرجعي إضافي داخل metadata.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
          ),
          if (state.selectedFeature != null) ...[
            const SizedBox(height: 10),
            _InfoLine(label: 'العنصر المحدد حاليًا', value: state.selectedFeature!.displayLabel),
          ],
          if (state.selectedModernContext != null) ...[
            const SizedBox(height: 10),
            _InfoLine(label: 'المرجع الحديث المحدد', value: state.selectedModernContext!.communityLabel),
          ],
          if (state.selectedWaqfAsset != null) ...[
            const SizedBox(height: 10),
            _InfoLine(label: 'الأصل الوقفي المحدد', value: state.selectedWaqfAsset!.name ?? state.selectedWaqfAsset!.pwfKey),
          ],
        ],
      ),
    );
  }

  Color _kindColor(String rawKind) {
    switch (rawKind) {
      case 'descriptive':
        return PwfColors.primaryBlue;
      case 'reference':
        return PwfColors.warning;
      case 'drawable':
        return PwfColors.success;
      default:
        return PwfColors.royalRed;
    }
  }
}

class _PeriodsListCard extends StatelessWidget {
  const _PeriodsListCard({
    required this.periods,
    required this.selectedPeriodNo,
    required this.onPeriodSelected,
  });

  final List<HistoryPeriodItem> periods;
  final int? selectedPeriodNo;
  final ValueChanged<int> onPeriodSelected;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'الفترات التاريخية',
      child: Column(
        children: periods
            .map(
              (period) => ListTile(
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                selected: period.periodNo == selectedPeriodNo,
                selectedTileColor: PwfColors.primaryBlue.withValues(alpha: 0.08),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: _kindColor(period).withValues(alpha: 0.12),
                  child: Text(
                    '${period.periodNo}',
                    style: TextStyle(
                      color: _kindColor(period),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                title: Text(period.titleAr, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${period.periodKind.labelAr}${period.rangeLabelAr?.trim().isNotEmpty == true ? ' • ${period.rangeLabelAr}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => onPeriodSelected(period.periodNo),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Color _kindColor(HistoryPeriodItem period) {
    switch (period.periodKind.name) {
      case 'descriptive':
        return PwfColors.primaryBlue;
      case 'reference':
        return PwfColors.warning;
      case 'drawable':
        return PwfColors.success;
      default:
        return PwfColors.royalRed;
    }
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.feature,
    required this.selected,
    required this.onTap,
  });

  final HistoryOverlayFeature feature;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      selected: selected,
      selectedTileColor: PwfColors.gold.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        feature.displayLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${feature.levelKey ?? '—'} • ${feature.sourceTable ?? 'overlay'}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        tooltip: 'تحديد',
        onPressed: onTap,
        icon: const Icon(Icons.center_focus_strong),
      ),
      onTap: onTap,
    );
  }
}

class _ModernContextTile extends StatelessWidget {
  const _ModernContextTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final HistoryModernContext item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      selected: selected,
      selectedTileColor: PwfColors.success.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(item.communityLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        [if ((item.lguLabel ?? '').trim().isNotEmpty) item.lguLabel, if ((item.governorateLabel ?? '').trim().isNotEmpty) item.governorateLabel]
            .whereType<String>()
            .join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(onPressed: onTap, icon: const Icon(Icons.account_tree_outlined)),
      onTap: onTap,
    );
  }
}

class _WaqfAssetTile extends StatelessWidget {
  const _WaqfAssetTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final HistoryWaqfAssetLink item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      item.community,
      item.municipality,
      item.governorate,
    ].whereType<String>().where((e) => e.trim().isNotEmpty).join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? PwfColors.royalRed.withValues(alpha: 0.08) : PwfColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? PwfColors.royalRed.withValues(alpha: 0.40) : PwfColors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(onPressed: onTap, icon: const Icon(Icons.real_estate_agent_outlined)),
            ],
          ),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoBadge(label: item.pwfKey, color: PwfColors.royalRed),
              if ((item.typeLabel ?? '').trim().isNotEmpty)
                _InfoBadge(label: item.typeLabel!, color: PwfColors.primaryBlue),
              if ((item.statusLabel ?? '').trim().isNotEmpty)
                _InfoBadge(label: item.statusLabel!, color: PwfColors.warning),
              if ((item.endowerName ?? '').trim().isNotEmpty)
                _InfoBadge(label: item.endowerName!, color: PwfColors.success),
            ],
          ),
          if ((item.purpose ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.purpose!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (selected)
                const _InfoBadge(label: 'محدد داخل المستكشف', color: PwfColors.royalRed),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.go('/waqf/${item.pwfKey.isNotEmpty ? item.pwfKey : item.id}'),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('فتح المرجع'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return PwfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PwfColors.onSurface.withValues(alpha: 0.64),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}


class _RecommendedActionsCard extends StatelessWidget {
  const _RecommendedActionsCard({required this.state});

  final HistoryExplorerState state;

  @override
  Widget build(BuildContext context) {
    final steps = _stepsForState(state);
    return _SectionCard(
      title: 'الخطوة المقترحة التالية',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'استخدم هذه الإرشادات السريعة للوصول من القراءة التاريخية إلى الفهم الإداري والوقفـي بصورة أوضح.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
          ),
          const SizedBox(height: 10),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.arrow_circle_left_outlined, size: 18, color: PwfColors.primaryBlue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _stepsForState(HistoryExplorerState state) {
    switch (state.mode) {
      case HistoryExplorerMode.historical:
        if (!state.canDrawOverlay) {
          return const [
            'اقرأ بطاقة الفترة أولًا لفهم ما إذا كانت وصفية أو مرجعية.',
            'انتقل عبر الشريط الزمني إلى فترة تشغيلية إن كنت تحتاج طبقة مكانية قابلة للرسم.',
            'استخدم وضع "من الحديث" أو "من الوقف" عندما تريد الهبوط إلى الواقع الإداري الحديث أو الأصل الوقفي.',
          ];
        }
        return const [
          'اختر عنصرًا من الخريطة أو القائمة لفتح مساره في لوحة السلالة.',
          'فعّل "إظهار المرجع الحديث" لتفهم أين يندرج هذا الكيان اليوم.',
          'فعّل "إظهار الأصول الوقفية" للانتقال من الكيان التاريخي إلى الأصل الوقفي النهائي.',
        ];
      case HistoryExplorerMode.modern:
        return const [
          'ابحث عن المحافظة أو التجمع الحديث المطلوب من الحقل العلوي.',
          'اختر المرجع الحديث من القائمة ثم راقب كيف تصعد الصفحة إلى الجذر التاريخي.',
          'إن ظهرت النتيجة كـ fallback مرن فاعتبرها مرحلة استدلال أولية إلى حين اكتمال RPC السيادي.',
        ];
      case HistoryExplorerMode.waqf:
        return const [
          'ابحث باسم الأصل الوقفي أو PWF أو قطعة حديثة.',
          'اختر الأصل المطلوب من القائمة ثم تتبع مرجعه الحديث وجذره التاريخي من لوحة السلالة.',
          'استخدم الخريطة لتأكيد ما إذا كان العرض الحالي تفسيريًا بنقطة مرساة أم مرتبطًا بهندسة فعلية.',
        ];
    }
  }
}
