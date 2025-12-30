import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../history/application/history_providers.dart';
import '../../../history/domain/models/history_models.dart';

class HistoricalPeriodFilter extends ConsumerWidget {
  const HistoricalPeriodFilter({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync = ref.watch(historicalPeriodsProvider);

    return periodsAsync.when(
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.error),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'تعذّر تحميل الفترات التاريخية',
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (periods) {
        final items = <DropdownMenuItem<int?>>[
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('كل الفترات', textDirection: TextDirection.rtl),
          ),
          ...periods.map(
            (p) => DropdownMenuItem<int?>(
              value: p.id,
              child: Text(
                _label(p),
                textDirection: TextDirection.rtl,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ];

        return DropdownButtonFormField<int?>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(
            labelText: 'الفترة التاريخية (اختياري)',
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }

  static String _label(HistoricalPeriod p) {
    final sy = p.startYear;
    final ey = p.endYear;
    if (sy != null && ey != null) return '${p.titleAr} ($sy–$ey)';
    if (sy != null) return '${p.titleAr} (من $sy)';
    if (ey != null) return '${p.titleAr} (حتى $ey)';
    return p.titleAr;
  }
}
