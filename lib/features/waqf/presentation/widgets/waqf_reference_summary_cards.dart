
import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/pwf_card.dart';
import '../../domain/models/endower_reference.dart';
import '../../domain/models/endowment_reference.dart';

class WaqfReferenceSummaryCard extends StatelessWidget {
  const WaqfReferenceSummaryCard({super.key, required this.endowment});

  final EndowmentReference endowment;

  @override
  Widget build(BuildContext context) {
    return PwfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(endowment.displayName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: endowment.nationalId, color: PwfColors.royalRed),
              if ((endowment.type ?? '').trim().isNotEmpty) _Chip(label: endowment.type!, color: PwfColors.primaryBlue),
              if ((endowment.status ?? '').trim().isNotEmpty) _Chip(label: endowment.status!, color: PwfColors.warning),
            ],
          ),
          const SizedBox(height: 14),
          _Row(label: 'الواقف', value: endowment.endowerName ?? '—'),
          _Row(label: 'الموقع', value: endowment.locationLabel),
          _Row(label: 'الفئة', value: endowment.category ?? '—'),
          _Row(label: 'النوع الفرعي', value: endowment.subType ?? '—'),
          if (endowment.totalArea != null) _Row(label: 'المساحة', value: '${endowment.totalArea!.toStringAsFixed(2)} م²'),
          if ((endowment.purpose ?? '').trim().isNotEmpty) _Row(label: 'الغرض', value: endowment.purpose!),
          if ((endowment.conditions ?? '').trim().isNotEmpty) _Row(label: 'شروط موجزة', value: endowment.conditions!),
        ],
      ),
    );
  }
}

class EndowerSummaryCard extends StatelessWidget {
  const EndowerSummaryCard({super.key, required this.endower});

  final EndowerReference endower;

  @override
  Widget build(BuildContext context) {
    return PwfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ملخص الواقف', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(endower.displayName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _Row(label: 'الهوية', value: endower.nationalId.isEmpty ? '—' : endower.nationalId),
          _Row(label: 'الجنس', value: endower.gender ?? '—'),
          _Row(label: 'الحالة', value: endower.status ?? '—'),
          _Row(label: 'الموقع', value: [endower.city, endower.governorate].whereType<String>().where((e) => e.trim().isNotEmpty).join(' / ').isEmpty ? '—' : [endower.city, endower.governorate].whereType<String>().where((e) => e.trim().isNotEmpty).join(' / ')),
          if (endower.endowmentCount != null) _Row(label: 'عدد الأوقاف', value: '${endower.endowmentCount}'),
          if ((endower.familyHistory ?? '').trim().isNotEmpty) _Row(label: 'ملاحظات', value: endower.familyHistory!),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: PwfColors.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}
