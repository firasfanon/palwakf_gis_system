import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/history_admin_providers.dart';
import '../../application/history_state_providers.dart';
import '../../application/history_providers.dart';
import '../../domain/models/history_admin_models.dart';
import '../../../history/domain/models/history_models.dart';

class HistoryAdminUnitsListScreen extends ConsumerWidget {
  const HistoryAdminUnitsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // قائمة الفترات التاريخية
    final periodsAsync = ref.watch(historicalPeriodsProvider);

    // فلاتر الـ CRUD (من مزود الإدارة)
    final selectedPeriodId = ref.watch(adminCrudFilterPeriodIdProvider);
    final selectedLevel = ref.watch(adminCrudFilterLevelProvider);

    // قائمة الوحدات الإدارية حسب الفلاتر
    final unitsAsync = ref.watch(adminUnitsCrudListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الوحدات التاريخية'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _FiltersRow(
              periodsAsync: periodsAsync,
              selectedPeriodId: selectedPeriodId,
              selectedLevel: selectedLevel,
              onPeriodChanged: (value) {
                ref
                    .read(adminCrudFilterPeriodIdProvider.notifier)
                    .state = value;
              },
              onLevelChanged: (level) {
                ref
                    .read(adminCrudFilterLevelProvider.notifier)
                    .state = level;
              },
              onClearFilters: () {
                ref
                    .read(adminCrudFilterPeriodIdProvider.notifier)
                    .state = null;
                ref
                    .read(adminCrudFilterLevelProvider.notifier)
                    .state = null;
                ref
                    .read(adminCrudFilterParentIdProvider.notifier)
                    .state = null;
              },
              onCreateNew: () {
                final periodId = ref.read(adminCrudFilterPeriodIdProvider);
                final level = ref.read(adminCrudFilterLevelProvider);

                context.go(
                  '/admin/history-admin-units/new',
                  extra: (periodId: periodId, level: level),
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: unitsAsync.when(
                data: (units) {
                  if (units.isEmpty) {
                    return const Center(
                      child: Text('لا توجد وحدات مطابقة للمرشّحات'),
                    );
                  }

                  return ListView.separated(
                    itemCount: units.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final unit = units[index];
                      return _AdminUnitTile(unit: unit);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stackTrace) => Center(
                  child: Text('حدث خطأ أثناء تحميل الوحدات: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersRow extends StatelessWidget {
  const _FiltersRow({
    required this.periodsAsync,
    required this.selectedPeriodId,
    required this.selectedLevel,
    required this.onPeriodChanged,
    required this.onLevelChanged,
    required this.onClearFilters,
    required this.onCreateNew,
  });

  final AsyncValue<List<HistoricalPeriod>> periodsAsync;
  final int? selectedPeriodId;
  final HistoricalAdminLevel? selectedLevel;
  final ValueChanged<int?> onPeriodChanged;
  final ValueChanged<HistoricalAdminLevel?> onLevelChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // اختيار الفترة التاريخية
        Expanded(
          child: periodsAsync.when(
            data: (periods) {
              return DropdownButtonFormField<int?>(
                value: selectedPeriodId,
                decoration: const InputDecoration(
                  labelText: 'الفترة التاريخية',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('كل الفترات'),
                  ),
                  ...periods.map(
                        (p) => DropdownMenuItem<int?>(
                      value: p.id,
                      child: Text(p.titleAr),
                    ),
                  ),
                ],
                onChanged: onPeriodChanged,
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('خطأ في تحميل الفترات: $error'),
          ),
        ),
        const SizedBox(width: 16),

        // اختيار المستوى الإداري
        Expanded(
          child: DropdownButtonFormField<HistoricalAdminLevel?>(
            value: selectedLevel,
            decoration: const InputDecoration(
              labelText: 'المستوى الإداري',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: <DropdownMenuItem<HistoricalAdminLevel?>>[
              const DropdownMenuItem<HistoricalAdminLevel?>(
                value: null,
                child: Text('كل المستويات'),
              ),
              ...HistoricalAdminLevel.values.map(
                    (lvl) => DropdownMenuItem<HistoricalAdminLevel?>(
                  value: lvl,
                  child: Text(_levelLabel(lvl)),
                ),
              ),
            ],
            onChanged: onLevelChanged,
          ),
        ),
        const SizedBox(width: 16),

        IconButton(
          onPressed: onClearFilters,
          tooltip: 'مسح المرشّحات',
          icon: const Icon(Icons.clear),
        ),
        const SizedBox(width: 8),

        ElevatedButton.icon(
          onPressed: onCreateNew,
          icon: const Icon(Icons.add),
          label: const Text('إضافة وحدة'),
        ),
      ],
    );
  }

  static String _levelLabel(HistoricalAdminLevel level) {
    switch (level) {
      case HistoricalAdminLevel.liwa:
        return 'لواء';
      case HistoricalAdminLevel.qada:
        return 'قضاء';
      case HistoricalAdminLevel.muhafaza:
        return 'محافظة';
      case HistoricalAdminLevel.nahiya:
        return 'ناحية';
      case HistoricalAdminLevel.city:
        return 'مدينة';
      case HistoricalAdminLevel.village:
        return 'قرية';
      case HistoricalAdminLevel.hamlet:
        return 'خربة / تجمع';
      case HistoricalAdminLevel.quarter:
        return 'حارة / حي';
      case HistoricalAdminLevel.camp:
        return 'مخيّم';
    }
  }
}

class _AdminUnitTile extends StatelessWidget {
  const _AdminUnitTile({required this.unit});

  final HistoricalAdminUnit unit;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(unit.nameAr),
      subtitle: Text('${_FiltersRow._levelLabel(unit.level)} • id=${unit.id}'),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () {
          // هنا لاحقاً نربطها بشاشة التعديل الموجودة في الراوتر
          // مثلاً:
          // context.go(
          //   '/admin/history-admin-units/edit/${unit.id}',
          //   extra: unit,
          // );
        },
      ),
    );
  }
}
