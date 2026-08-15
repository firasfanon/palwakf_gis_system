import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/pwf_card.dart';
import '../../domain/enums/history_period_kind.dart';
import '../../domain/models/history_period_item.dart';

class HistoryTimelineStrip extends StatelessWidget {
  const HistoryTimelineStrip({
    super.key,
    required this.periods,
    required this.selectedPeriodNo,
    required this.onPeriodSelected,
  });

  final List<HistoryPeriodItem> periods;
  final int? selectedPeriodNo;
  final ValueChanged<int> onPeriodSelected;

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) return const SizedBox.shrink();

    return PwfCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التسلسل الزمني للفترات',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'انتقل بين الفترات لتبديل زاوية القراءة من الوصف إلى المرجع إلى التشغيل.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: PwfColors.onSurface.withValues(alpha: 0.66),
                            height: 1.6,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: PwfColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.12)),
                ),
                child: Text(
                  'إجمالي الفترات: ${periods.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PwfColors.primaryBlue,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: periods
                  .map(
                    (period) => Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: _TimelineChip(
                        period: period,
                        selected: period.periodNo == selectedPeriodNo,
                        onTap: () => onPeriodSelected(period.periodNo),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineChip extends StatelessWidget {
  const _TimelineChip({
    required this.period,
    required this.selected,
    required this.onTap,
  });

  final HistoryPeriodItem period;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _kindColor(period.periodKind);
    final badges = <String>[
      period.periodKind.labelAr,
      if (period.hasOverlay) 'تشغيلية' else 'بدون رسم',
      if (period.defaultLevelKey?.trim().isNotEmpty == true) 'افتراضي: ${period.defaultLevelKey}',
    ];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        constraints: const BoxConstraints(minWidth: 170, maxWidth: 230),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : PwfColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accent : PwfColors.outline,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: accent.withValues(alpha: 0.12),
                  child: Text(
                    '${period.periodNo}',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    period.titleAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: PwfColors.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (period.rangeLabelAr?.trim().isNotEmpty == true)
              Text(
                period.rangeLabelAr!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PwfColors.onSurface.withValues(alpha: 0.68),
                      height: 1.5,
                    ),
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: badges
                  .where((item) => item.trim().isNotEmpty)
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: accent.withValues(alpha: 0.14)),
                      ),
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  Color _kindColor(HistoryPeriodKind kind) {
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
}
