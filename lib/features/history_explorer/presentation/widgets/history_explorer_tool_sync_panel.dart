import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/colors.dart';
import '../../application/state/history_explorer_state.dart';
import '../../domain/enums/history_explorer_mode.dart';

class HistoryExplorerToolSyncPanel extends StatelessWidget {
  const HistoryExplorerToolSyncPanel({
    super.key,
    required this.state,
    required this.onModeChanged,
    required this.onToggleModernContext,
    required this.onToggleWaqfAssets,
    required this.onToggleParcels,
    required this.onToggleLineage,
    required this.onToggleLabels,
    required this.onToggleBoundariesOnly,
    required this.onRefresh,
  });

  final HistoryExplorerState state;
  final ValueChanged<HistoryExplorerMode> onModeChanged;
  final VoidCallback onToggleModernContext;
  final VoidCallback onToggleWaqfAssets;
  final VoidCallback onToggleParcels;
  final VoidCallback onToggleLineage;
  final VoidCallback onToggleLabels;
  final VoidCallback onToggleBoundariesOnly;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final modeColor = _modeColor(state.mode);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: modeColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: modeColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.sync_alt_outlined, color: modeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تزامن أدوات المستكشفات',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: PwfColors.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              _StatusPill(
                label: state.isSearchDebouncing ? 'debounce' : 'جاهز',
                color: state.isSearchDebouncing ? PwfColors.warning : PwfColors.success,
              ),
              const SizedBox(width: 8),
              _StatusPill(label: '#${state.runtimeRequestToken}', color: PwfColors.primaryBlue),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'هذه اللوحة تجعل المستكشف الحديث، مستكشف التاريخ، ومستكشف الوقف يعملون بنفس قواعد الأدوات: بحث محكوم، تحديد، سياق، طبقات مساعدة، تصدير ملخص، وحماية من الطلبات القديمة.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.7,
                  color: PwfColors.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                ),
          ),
          if ((state.runtimeMessage ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _InlineNotice(message: state.runtimeMessage!),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ModeSyncChip(
                label: 'التاريخ',
                active: state.mode == HistoryExplorerMode.historical,
                count: state.filteredFeatures.length,
                icon: Icons.history_edu_outlined,
                color: PwfColors.primaryBlue,
                onTap: () => onModeChanged(HistoryExplorerMode.historical),
              ),
              _ModeSyncChip(
                label: 'الحديث',
                active: state.mode == HistoryExplorerMode.modern,
                count: state.modernSearchResults.length,
                icon: Icons.account_tree_outlined,
                color: PwfColors.warning,
                onTap: () => onModeChanged(HistoryExplorerMode.modern),
              ),
              _ModeSyncChip(
                label: 'الوقف',
                active: state.mode == HistoryExplorerMode.waqf,
                count: state.waqfSearchResults.length,
                icon: Icons.domain_outlined,
                color: PwfColors.royalRed,
                onTap: () => onModeChanged(HistoryExplorerMode.waqf),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final cards = [
                _CapabilityCard(
                  title: 'بحث محكوم',
                  subtitle: state.isSearchDebouncing ? 'بانتظار توقف الكتابة' : 'آخر طلب فعّال فقط',
                  icon: Icons.manage_search_outlined,
                  color: PwfColors.primaryBlue,
                  enabled: true,
                  value: state.searchQuery.trim().isEmpty ? 'بدون بحث' : state.searchQuery.trim(),
                ),
                _CapabilityCard(
                  title: 'السلالة والسياق',
                  subtitle: state.resolvedContext.hasAnyData ? 'سياق جاهز' : 'بانتظار تحديد عنصر',
                  icon: Icons.device_hub_outlined,
                  color: PwfColors.success,
                  enabled: state.showLineage,
                  value: state.showLineage ? 'مفعلة' : 'مخفية',
                  onTap: onToggleLineage,
                ),
                _CapabilityCard(
                  title: 'التسميات',
                  subtitle: 'تطبق على العناصر الظاهرة',
                  icon: Icons.label_outline,
                  color: PwfColors.warning,
                  enabled: state.showLabels,
                  value: state.showLabels ? 'ظاهرة' : 'مخفية',
                  onTap: onToggleLabels,
                ),
                _CapabilityCard(
                  title: 'الحدود فقط',
                  subtitle: 'تقليل ازدحام الخريطة',
                  icon: Icons.border_outer_outlined,
                  color: PwfColors.primaryGold,
                  enabled: state.boundariesOnly,
                  value: state.boundariesOnly ? 'مفعل' : 'كامل',
                  onTap: onToggleBoundariesOnly,
                ),
                _CapabilityCard(
                  title: 'مرجع حديث',
                  subtitle: 'طبقة سياق للمقارنة',
                  icon: Icons.location_city_outlined,
                  color: PwfColors.success,
                  enabled: state.showModernContext,
                  value: state.showModernContext ? '${state.modernSearchResults.length}' : 'مغلق',
                  onTap: onToggleModernContext,
                ),
                _CapabilityCard(
                  title: 'الأصول الوقفية',
                  subtitle: 'Anchors + روابط الوقف',
                  icon: Icons.real_estate_agent_outlined,
                  color: PwfColors.royalRed,
                  enabled: state.showWaqfAssets,
                  value: state.showWaqfAssets ? '${state.waqfSearchResults.length}' : 'مغلق',
                  onTap: onToggleWaqfAssets,
                ),
                _CapabilityCard(
                  title: 'القطع المرتبطة',
                  subtitle: 'لا تظهر إلا عند الحاجة',
                  icon: Icons.grid_view_outlined,
                  color: PwfColors.info,
                  enabled: state.showParcels,
                  value: state.showParcels ? '${state.linkedParcels.length}' : 'محمية',
                  onTap: onToggleParcels,
                ),
                _CapabilityCard(
                  title: 'تحديث',
                  subtitle: 'إعادة تحميل الوضع الحالي',
                  icon: Icons.refresh_outlined,
                  color: PwfColors.primaryBlue,
                  enabled: !state.isLoading,
                  value: state.isLoading ? 'تحميل' : 'جاهز',
                  onTap: onRefresh,
                ),
              ];
              if (compact) {
                return Column(
                  children: cards.map((card) => Padding(padding: const EdgeInsets.only(bottom: 8), child: card)).toList(),
                );
              }
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: cards.map((card) => SizedBox(width: 210, child: card)).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _copyRuntimeSummary(context),
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('نسخ ملخص التشغيل'),
              ),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.sync_outlined),
                label: const Text('تحديث الوضع الحالي'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyRuntimeSummary(BuildContext context) {
    final lines = <String>[
      'PalWakf History Explorer Runtime Summary',
      'mode=${state.mode.name}',
      'period=${state.selectedPeriodNo ?? '-'}',
      'level=${state.selectedLevelKey ?? '-'}',
      'query=${state.searchQuery.trim().isEmpty ? '-' : state.searchQuery.trim()}',
      'historical_features=${state.filteredFeatures.length}/${state.overlayFeatures.length}',
      'modern_results=${state.modernSearchResults.length}',
      'waqf_results=${state.waqfSearchResults.length}',
      'show_modern=${state.showModernContext}',
      'show_waqf=${state.showWaqfAssets}',
      'show_parcels=${state.showParcels}',
      'show_lineage=${state.showLineage}',
      'show_labels=${state.showLabels}',
      'boundaries_only=${state.boundariesOnly}',
      'request_token=${state.runtimeRequestToken}',
      'debouncing=${state.isSearchDebouncing}',
    ];
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ ملخص تشغيل المستكشف.')),
    );
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
}

class _ModeSyncChip extends StatelessWidget {
  const _ModeSyncChip({
    required this.label,
    required this.active,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool active;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.12) : PwfColors.surfaceVariant,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? color.withValues(alpha: 0.42) : PwfColors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
            const SizedBox(width: 6),
            _StatusPill(label: '$count', color: color),
          ],
        ),
      ),
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.value,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.08) : PwfColors.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: enabled ? color.withValues(alpha: 0.26) : PwfColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                _StatusPill(label: value, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: PwfColors.onSurface.withValues(alpha: 0.66),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PwfColors.primaryBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: PwfColors.primaryBlue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PwfColors.primaryBlue,
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
