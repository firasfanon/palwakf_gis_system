import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../history/application/history_providers.dart';
import '../../../history/domain/models/history_models.dart';

/// Admin-only picker: attach a content item to a historical period (optional).
class HistoricalPeriodPicker extends ConsumerWidget {
  const HistoricalPeriodPicker({
    super.key,
    required this.selectedPeriodId,
    required this.onChanged,
  });

  /// Selected period id as string (query params / form state).
  final String? selectedPeriodId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncPeriods = ref.watch(historicalPeriodsProvider);

    return asyncPeriods.when(
      data: (periods) {
        if (periods.isEmpty) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Text(
                'لا توجد فترات تاريخية بعد. أضف فترات في جدول historical_periods ثم ستظهر هنا.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          );
        }

        final normalized = (selectedPeriodId ?? '').trim();
        final selected = normalized.isEmpty ? null : normalized;

        final items = <DropdownMenuItem<String?>>[
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('بدون ربط', textDirection: TextDirection.rtl),
          ),
          ...periods.map((p) {
            final label = _periodLabel(p);
            return DropdownMenuItem<String?>(
              value: p.id.toString(),
              child: Text(label, textDirection: TextDirection.rtl),
            );
          }),
        ];

        return Directionality(
          textDirection: TextDirection.rtl,
          child: DropdownButtonFormField<String?>(
            value: selected,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: 'ربط بفترة تاريخية (اختياري)',
              labelStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) {
        return const SizedBox.shrink();
      },
    );
  }

  static String _periodLabel(HistoricalPeriod p) {
    final base = (p.titleAr).trim().isEmpty ? 'فترة #${p.id}' : p.titleAr.trim();
    if (!p.hasRange) return base;
    final start = p.startYear?.toString();
    final end = p.endYear?.toString();
    final range = [start, end].whereType<String>().join(' - ');
    return range.isEmpty ? base : '$base ($range)';
  }
}
