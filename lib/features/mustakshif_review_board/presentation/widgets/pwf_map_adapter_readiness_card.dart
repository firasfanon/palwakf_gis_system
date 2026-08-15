import 'package:flutter/material.dart';

import '../pwf_review_board_providers.dart';
import 'pwf_status_chip.dart';

class PwfMapAdapterReadinessCard extends StatelessWidget {
  const PwfMapAdapterReadinessCard({super.key, required this.state});

  final PwfReviewBoardState state;

  @override
  Widget build(BuildContext context) {
    final total = state.records.length;
    final withAnyEvidence = state.records.where((record) => record.hasMapEvidence).length;
    final withHistoricalPoint = state.records.where((record) => record.hasHistoricalPoint).length;
    final withCandidateCentroid = state.records.where((record) => record.hasCandidateCentroid).length;
    final withBbox = state.records.where((record) => record.hasMapBbox).length;
    final percentage = total == 0 ? 0 : ((withAnyEvidence / total) * 100).round();

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route_outlined),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'جاهزية ربط الخريطة',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PwfStatusChip(label: '$percentage% evidence-ready', compact: true),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                PwfStatusChip(label: 'إجمالي: $total', compact: true),
                PwfStatusChip(label: 'أي دليل مكاني: $withAnyEvidence', compact: true),
                PwfStatusChip(label: 'نقطة تاريخية: $withHistoricalPoint', compact: true),
                PwfStatusChip(label: 'centroid مرشح: $withCandidateCentroid', compact: true),
                PwfStatusChip(label: 'bbox: $withBbox', compact: true),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'قياس جاهزية بيانات الخريطة فقط؛ لا تشغيل طبقات ولا رسم GIS ولا تعديل activeLayers.',
            ),
          ],
        ),
      ),
    );
  }
}
