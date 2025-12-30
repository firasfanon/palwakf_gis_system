// lib/features/lands/presentation/screens/land_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/lands_providers.dart';
import '../../domain/models/waqf_land.dart';
import '../widgets/land_admin_history_tab.dart';

class LandDetailsScreen extends ConsumerWidget {
  const LandDetailsScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final landAsync = ref.watch(landByIdProvider(id));
    const canManage = true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الأرض'),
        actions: [
          if (canManage)
            IconButton(
              onPressed: () {
                context.go('/admin/lands/$id/edit');
              },
              icon: const Icon(Icons.edit),
              tooltip: 'تعديل',
            ),
        ],
      ),
      body: landAsync.when(
        data: (land) {
          if (land == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لم يتم العثور على الأرض'),
                ],
              ),
            );
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'البيانات الأساسية'),
                    Tab(text: 'التقسيمات الإدارية التاريخية'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _LandBasicDetailsView(land: land),
                      LandAdminHistoryTab(landId: land.id!),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('خطأ في تحميل التفاصيل: $e'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(landByIdProvider(id));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandBasicDetailsView extends StatelessWidget {
  const _LandBasicDetailsView({required this.land});

  final WaqfLand land;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DetailCard(
          title: 'المعلومات الأساسية',
          children: [
            _DetailRow(label: 'رمز PWF', value: land.pwfCode),
            _DetailRow(label: 'الاسم بالعربية', value: land.nameAr),
            if (land.nameEn != null)
              _DetailRow(label: 'الاسم بالإنجليزية', value: land.nameEn!),
            _DetailRow(
              label: 'التصنيف',
              value: _getClassificationLabel(land.classification),
            ),
            _DetailRow(
              label: 'الحالة',
              value: _getStatusLabel(land.status),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _DetailCard(
          title: 'الموقع',
          children: [
            if (land.city != null)
              _DetailRow(label: 'المدينة', value: land.city!),
          ],
        ),
        if (land.notes != null) ...[
          const SizedBox(height: 16),
          _DetailCard(
            title: 'ملاحظات',
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(land.notes!),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _getClassificationLabel(LandClassification classification) {
    switch (classification) {
      case LandClassification.mosque:
        return 'مسجد';
      case LandClassification.residential:
        return 'سكني';
      case LandClassification.agricultural:
        return 'زراعي';
      case LandClassification.commercial:
        return 'تجاري';
      case LandClassification.investment:
        return 'استثماري';
      case LandClassification.other:
        return 'أخرى';
      case LandClassification.building:
        return 'مبنى / بناء';
      default:
        return 'أخرى';
    }
  }

  String _getStatusLabel(LandStatus status) {
    switch (status) {
      case LandStatus.active:
        return 'نشط';
      case LandStatus.underDispute:
        return 'متنازع عليه';
      case LandStatus.leased:
        return 'مؤجر';
      case LandStatus.suspended:
        return 'معلق';
      case LandStatus.other:
        return 'أخرى';
      case LandStatus.inactive:
        return 'غير فعّال';
      default:
        return 'أخرى';
    }
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}