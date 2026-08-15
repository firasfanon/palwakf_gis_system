import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/pwf_card.dart';
import '../../application/state/history_explorer_state.dart';
import '../../domain/enums/history_explorer_mode.dart';
import '../../domain/enums/history_period_kind.dart';

class HistoryExplorerOverviewStrip extends StatelessWidget {
  const HistoryExplorerOverviewStrip({super.key, required this.state});

  final HistoryExplorerState state;

  @override
  Widget build(BuildContext context) {
    return PwfCard(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _MiniStatusCard(
            emphasized: state.mode == HistoryExplorerMode.historical,
            title: 'النمط',
            value: _modeLabel(state.mode),
            subtitle: _selectionSummary(state),
            color: _modeColor(state.mode),
            icon: _modeIcon(state.mode),
          ),
          _MiniStatusCard(
            emphasized: state.selectedPeriod != null,
            title: 'الفترة',
            value: state.selectedPeriod == null
                ? 'اختر فترة'
                : '${state.selectedPeriod!.periodNo} — ${state.selectedPeriod!.titleAr}',
            subtitle: _periodSubtitle(state),
            color: _periodColor(state.selectedPeriodKind),
            icon: Icons.timeline_outlined,
          ),
          _MiniStatusCard(
            emphasized: state.selectedFeature != null || state.selectedModernContext != null || state.selectedWaqfAsset != null,
            title: 'القراءة الحالية',
            value: _readinessTitle(state),
            subtitle: _readinessSubtitle(state),
            color: _readinessColor(state),
            icon: Icons.fact_check_outlined,
          ),
        ],
      ),
    );
  }

  String _modeLabel(HistoryExplorerMode mode) {
    switch (mode) {
      case HistoryExplorerMode.historical:
        return 'من التاريخ';
      case HistoryExplorerMode.modern:
        return 'من الحديث';
      case HistoryExplorerMode.waqf:
        return 'من الوقف';
    }
  }

  IconData _modeIcon(HistoryExplorerMode mode) {
    switch (mode) {
      case HistoryExplorerMode.historical:
        return Icons.history_edu_outlined;
      case HistoryExplorerMode.modern:
        return Icons.account_tree_outlined;
      case HistoryExplorerMode.waqf:
        return Icons.domain_outlined;
    }
  }

  Color _modeColor(HistoryExplorerMode mode) {
    switch (mode) {
      case HistoryExplorerMode.historical:
        return PwfColors.primaryBlue;
      case HistoryExplorerMode.modern:
        return PwfColors.warning;
      case HistoryExplorerMode.waqf:
        return PwfColors.royalRed;
    }
  }

  String _selectionSummary(HistoryExplorerState state) {
    if (state.selectedWaqfAsset != null || state.selectedWaqfAssetId != null) return 'أصل وقفي محدد';
    if (state.selectedModernContext != null || state.selectedModernContextCode != null) return 'مرجع حديث محدد';
    if (state.selectedFeature != null || state.selectedFeatureId != null) return 'كيان تاريخي محدد';
    return 'لا يوجد عنصر محدد بعد';
  }

  String _periodSubtitle(HistoryExplorerState state) {
    switch (state.selectedPeriodKind) {
      case HistoryPeriodKind.descriptive:
        return 'فترة وصفية للفهم العام';
      case HistoryPeriodKind.reference:
        return 'فترة مرجعية للمقارنة';
      case HistoryPeriodKind.drawable:
        return 'فترة تشغيلية قابلة للرسم';
      case HistoryPeriodKind.unknown:
        return 'لم يُحدد النوع بعد';
    }
  }

  Color _periodColor(HistoryPeriodKind kind) {
    switch (kind) {
      case HistoryPeriodKind.descriptive:
        return PwfColors.primaryBlue;
      case HistoryPeriodKind.reference:
        return PwfColors.warning;
      case HistoryPeriodKind.drawable:
        return PwfColors.success;
      case HistoryPeriodKind.unknown:
        return PwfColors.royalRed;
    }
  }

  String _readinessTitle(HistoryExplorerState state) {
    if (state.errorMessage != null || state.contextErrorMessage != null) return 'تحتاج مراجعة';
    if (state.isLoading || state.isResolvingContext) return 'جارٍ التحميل';
    if (state.selectedFeature != null ||
        state.selectedModernContext != null ||
        state.selectedWaqfAsset != null ||
        state.selectedFeatureId != null ||
        state.selectedModernContextCode != null ||
        state.selectedWaqfAssetId != null) {
      return 'جاهزة للتحليل';
    }
    return 'جاهزة للاستكشاف';
  }

  String _readinessSubtitle(HistoryExplorerState state) {
    if (state.errorMessage != null || state.contextErrorMessage != null) {
      return 'راجع التنبيهات أو لوحة السلالة.';
    }
    if (state.selectedFeature != null ||
        state.selectedModernContext != null ||
        state.selectedWaqfAsset != null ||
        state.selectedFeatureId != null ||
        state.selectedModernContextCode != null ||
        state.selectedWaqfAssetId != null) {
      return state.resolvedContext.hasAnyData
          ? (state.resolvedContext.isSovereign ? 'الربط الحالي سيادي.' : 'الربط الحالي مرحلي.')
          : 'جارٍ تثبيت الربط أو لا توجد نتائج إضافية حتى الآن.';
    }
    return 'ابدأ بالفترة ثم اختر عنصرًا من الخريطة.';
  }

  Color _readinessColor(HistoryExplorerState state) {
    if (state.errorMessage != null || state.contextErrorMessage != null) return PwfColors.royalRed;
    if (state.isLoading || state.isResolvingContext) return PwfColors.warning;
    if (state.selectedFeature != null ||
        state.selectedModernContext != null ||
        state.selectedWaqfAsset != null ||
        state.selectedFeatureId != null ||
        state.selectedModernContextCode != null ||
        state.selectedWaqfAssetId != null) {
      return PwfColors.success;
    }
    return PwfColors.primaryGold;
  }
}

class _MiniStatusCard extends StatelessWidget {
  const _MiniStatusCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.emphasized,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final titleColor = emphasized ? Colors.white.withValues(alpha: 0.88) : PwfColors.onSurface.withValues(alpha: 0.66);
    final valueColor = emphasized ? Colors.white : PwfColors.onSurface;
    final subtitleColor = emphasized ? Colors.white.withValues(alpha: 0.82) : PwfColors.onSurface.withValues(alpha: 0.74);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: emphasized ? color.withValues(alpha: 0.18) : PwfColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: emphasized ? color.withValues(alpha: 0.46) : PwfColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: valueColor,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5, color: subtitleColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
