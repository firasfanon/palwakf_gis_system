import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/history_providers.dart';
import '../../application/history_state_providers.dart';
import '../../domain/models/history_models.dart';

/// ويدجت شريط الزمن للفترات التاريخية
class HistoricalTimeSlider extends ConsumerWidget {
  const HistoricalTimeSlider({
    super.key,
    this.onPeriodSelected,
  });

  /// يتم استدعاؤه عند اختيار فترة تاريخية من الشريط
  final ValueChanged<HistoricalPeriod>? onPeriodSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync = ref.watch(historicalPeriodsProvider);
    final selectedId = ref.watch(selectedHistoricalPeriodIdProvider);

    return periodsAsync.when(
      data: (periods) {
        if (periods.isEmpty) {
          return const SizedBox.shrink();
        }

        final currentId = selectedId ?? periods.first.id;

        return SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, index) {
              final period = periods[index];

              return _PeriodChip(
                period: period,
                isSelected: period.id == currentId,
                onTap: () {
                  ref
                      .read(selectedHistoricalPeriodIdProvider.notifier)
                      .state = period.id;
                  onPeriodSelected?.call(period);
                },
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: periods.length,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
      const Center(child: Text('خطأ في تحميل الفترات التاريخية')),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.period,
    required this.isSelected,
    required this.onTap,
  });

  final HistoricalPeriod period;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              period.titleAr,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (period.startYear != null && period.endYear != null)
              Text(
                '${period.startYear} - ${period.endYear}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
