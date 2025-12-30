// lib/features/lands/presentation/screens/lands_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../admin/domain/user_account.dart';
import '../../../../app/security/access_control.dart';
import '../../data/lands_providers.dart';
import '../../domain/models/waqf_land.dart';

class LandsListScreen extends ConsumerWidget {
  const LandsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final landsAsync = ref.watch(landsListProvider);
    final canManage = hasPermission(
      ref.watch(currentUserProvider),
      'manageLandsCrud',
    );
    final search = ref.watch(landsSearchQueryProvider) ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأراضي الوقفية'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: search),
                    decoration: const InputDecoration(
                      labelText: 'بحث (كود PWF / اسم / مدينة)',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (value) {
                      ref.read(landsSearchQueryProvider.notifier).state =
                      value.trim().isEmpty ? null : value.trim();
                    },
                  ),
                ),
                if (canManage) ...[
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      context.go('/admin/lands/new');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('أرض جديدة'),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: landsAsync.when(
              data: (lands) {
                if (lands.isEmpty) {
                  return const Center(
                    child: Text('لا توجد أراضٍ مسجلة حتى الآن'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final land = lands[index];
                    return _LandListTile(
                      land: land,
                      onTap: () {
                        context.go('/admin/lands/${land.id}');
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemCount: lands.length,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Text('خطأ في تحميل قائمة الأراضي: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandListTile extends StatelessWidget {
  const _LandListTile({
    required this.land,
    required this.onTap,
  });

  final WaqfLand land;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (land.governorate != null) land.governorate,
      if (land.city != null) land.city,
      if (land.areaDunum != null) '${land.areaDunum} دونم',
    ].whereType<String>().join(' - ');

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(
            land.pwfCode.isNotEmpty
                ? land.pwfCode.characters.take(2).toString()
                : '?',
          ),
        ),
        title: Text(land.nameAr),
        subtitle: Text(subtitle),
        trailing: Text(
          landStatusToDb(land.status),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
