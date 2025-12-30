import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mustakshif_alwaqf/features/history/application/history_providers.dart';
import 'package:mustakshif_alwaqf/features/history/domain/models/history_models.dart';

class HistoricalLayersPanel extends ConsumerWidget {
  const HistoricalLayersPanel({
    super.key,
    required this.periodId,
    required this.visibleLayerIds,
    required this.onVisibleLayerIdsChanged,
  });

  final int? periodId;
  final Set<int> visibleLayerIds;
  final ValueChanged<Set<int>> onVisibleLayerIdsChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (periodId == null) {
      return const Card(
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('اختر حقبة زمنية لعرض طبقاتها.'),
        ),
      );
    }

    final layersAsync =
    ref.watch(historicalLayersByPeriodProvider(periodId!));

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'الطبقات التاريخية',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: layersAsync.when(
                data: (layers) {
                  if (layers.isEmpty) {
                    return const Center(
                      child: Text('لا توجد طبقات لهذه الحقبة.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: layers.length,
                    itemBuilder: (context, index) {
                      final layer = layers[index];
                      final isVisible =
                      visibleLayerIds.contains(layer.id);

                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: isVisible,
                        title: Text('طبقة #${layer.id}'),
                        onChanged: (value) {
                          final newSet =
                          Set<int>.from(visibleLayerIds);
                          if (value == true) {
                            newSet.add(layer.id);
                          } else {
                            newSet.remove(layer.id);
                          }
                          onVisibleLayerIdsChanged(newSet);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text('خطأ في تحميل الطبقات: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
