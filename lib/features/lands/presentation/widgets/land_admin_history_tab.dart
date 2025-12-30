import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mustakshif_alwaqf/features/history/application/history_admin_providers.dart';

class LandAdminHistoryTab extends ConsumerWidget {
  const LandAdminHistoryTab({
    super.key,
    required this.landId,
  });

  final int landId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(landAdminHistoryProvider(landId));

    return historyAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Text('لا يوجد سجل إداري تاريخي لهذه الأرض.'),
          );
        }

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              child: ListTile(
                leading: Text('#${index + 1}'),
                // نستخدم toString لتجنّب الاعتماد على حقول قد لا تكون موحدة بعد
                title: Text(entry.toString()),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Text('خطأ في تحميل السجل: $error'),
      ),
    );
  }
}
