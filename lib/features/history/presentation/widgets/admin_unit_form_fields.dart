// lib/features/history/presentation/widgets/admin_unit_form_fields.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/history_admin_models.dart';
import '../state/admin_unit_form_notifier.dart';

class AdminUnitFormFields extends ConsumerWidget {
  const AdminUnitFormFields({
    super.key,
    required this.state,
    required this.notifier,
  });

  final AdminUnitFormState state;
  final AdminUnitFormNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = state.unit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<HistoricalAdminLevel>(
          value: unit.level,
          decoration: const InputDecoration(
            labelText: 'المستوى الإداري',
          ),
          items: HistoricalAdminLevel.values
              .map(
                (e) => DropdownMenuItem(
              value: e,
              child: Text(_levelLabel(e)),
            ),
          )
              .toList(),
          onChanged: (value) {
            if (value != null) notifier.updateLevel(value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: TextEditingController(text: unit.code ?? ''),
          decoration: const InputDecoration(
            labelText: 'الكود (اختياري)',
          ),
          onChanged: notifier.updateCode,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: TextEditingController(text: unit.nameAr),
          decoration: const InputDecoration(
            labelText: 'اسم الوحدة (عربي)',
          ),
          onChanged: notifier.updateNameAr,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: TextEditingController(text: unit.nameEn ?? ''),
          decoration: const InputDecoration(
            labelText: 'اسم الوحدة (إنجليزي)',
          ),
          onChanged: notifier.updateNameEn,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(
                  text: unit.areaKm2?.toString() ?? '',
                ),
                decoration: const InputDecoration(
                  labelText: 'المساحة (كم²)',
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                onChanged: notifier.updateAreaKm2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: TextEditingController(
                  text: unit.population?.toString() ?? '',
                ),
                decoration: const InputDecoration(
                  labelText: 'السكان (تاريخياً)',
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: false),
                onChanged: notifier.updatePopulation,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.error != null) ...[
          Text(
            state.error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  String _levelLabel(HistoricalAdminLevel level) {
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
        return 'تجمع/خربة';
      case HistoricalAdminLevel.quarter:
        return 'حي/حارة';
      case HistoricalAdminLevel.camp:
        return 'مخيم';
    }
  }
}
