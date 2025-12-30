// lib/features/lands/presentation/widgets/land_form_fields.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/waqf_land.dart';
import '../state/land_form_notifier.dart';

class LandFormFields extends ConsumerWidget {
  final LandFormState state;
  final LandFormNotifier notifier;

  const LandFormFields({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final land = state.land;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ====== القسم 1: البيانات الأساسية ======
        _buildSectionTitle('البيانات الأساسية'),

        TextFormField(
          initialValue: land.pwfCode ?? '',
          decoration: const InputDecoration(
            labelText: 'كود PWF',
          ),
          onChanged: notifier.updatePwfCode,
        ),
        const SizedBox(height: 12),

        TextFormField(
          initialValue: land.nameAr ?? '',
          decoration: const InputDecoration(
            labelText: 'اسم الوقف (عربي)',
          ),
          onChanged: notifier.updateNameAr,
        ),
        const SizedBox(height: 12),

        TextFormField(
          initialValue: land.nameEn ?? '',
          decoration: const InputDecoration(
            labelText: 'اسم الوقف (إنجليزي)',
          ),
          onChanged: notifier.updateNameEn,
        ),
        const SizedBox(height: 16),

        // ====== القسم 2: الموقع ======
        _buildSectionTitle('الموقع'),

        TextFormField(
          initialValue: land.governorate ?? '',
          decoration: const InputDecoration(
            labelText: 'المحافظة',
          ),
          onChanged: notifier.updateGovernorate,
        ),
        const SizedBox(height: 12),

        TextFormField(
          initialValue: land.city ?? '',
          decoration: const InputDecoration(
            labelText: 'المدينة / البلدة',
          ),
          onChanged: notifier.updateCity,
        ),
        const SizedBox(height: 12),

        TextFormField(
          initialValue: land.areaDunum?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'المساحة (دونم)',
          ),
          keyboardType: TextInputType.number,
          onChanged: notifier.updateAreaDunum,
        ),
        const SizedBox(height: 16),

        // ====== القسم 3: التصنيف والحالة ======
        _buildSectionTitle('التصنيف والحالة'),

        DropdownButtonFormField<LandClassification>(
          value: land.classification,
          decoration: const InputDecoration(
            labelText: 'تصنيف الأرض',
          ),
          items: LandClassification.values
              .map(
                (e) => DropdownMenuItem(
              value: e,
              child: Text(_classificationLabel(e)),
            ),
          )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              notifier.updateClassification(value);
            }
          },
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<LandStatus>(
          value: land.status,
          decoration: const InputDecoration(
            labelText: 'حالة الأرض',
          ),
          items: LandStatus.values
              .map(
                (e) => DropdownMenuItem(
              value: e,
              child: Text(_statusLabel(e)),
            ),
          )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              notifier.updateStatus(value);
            }
          },
        ),
        const SizedBox(height: 16),

        // ====== القسم 4: الإحداثيات ======
        _buildSectionTitle('الإحداثيات'),

        TextFormField(
          initialValue: land.lat?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'خط العرض (Latitude)',
          ),
          keyboardType: TextInputType.number,
          onChanged: notifier.updateLat,
        ),
        const SizedBox(height: 12),

        TextFormField(
          initialValue: land.lng?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'خط الطول (Longitude)',
          ),
          keyboardType: TextInputType.number,
          onChanged: notifier.updateLng,
        ),
        const SizedBox(height: 16),

        // ====== القسم 5: ملاحظات ======
        _buildSectionTitle('ملاحظات'),

        TextFormField(
          initialValue: land.notes ?? '',
          decoration: const InputDecoration(
            labelText: 'ملاحظات إضافية',
          ),
          maxLines: 4,
          onChanged: notifier.updateNotes,
        ),
      ],
    );
  }

  // ====== Helpers ======

  String _classificationLabel(LandClassification value) {
    switch (value) {
      case LandClassification.mosque:
        return 'مسجد';
      case LandClassification.investment:
        return 'استثماري';
      case LandClassification.agricultural:
        return 'زراعي';
      case LandClassification.residential:
        return 'سكني';
      case LandClassification.commercial:
        return 'تجاري';
      case LandClassification.building:
        return 'بناء / عقار';
      case LandClassification.other:
        return 'أخرى';
    }
  }

  String _statusLabel(LandStatus value) {
    switch (value) {
      case LandStatus.active:
        return 'ساري';
      case LandStatus.leased:
        return 'مؤجَّر';
      case LandStatus.suspended:
        return 'موقوف مؤقتًا';
      case LandStatus.inactive:
        return 'غير مُفعَّل';
      case LandStatus.underDispute:
        return 'تحت النزاع';
      case LandStatus.other:
        return 'أخرى';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
