import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/pwf_review_record.dart';
import 'pwf_status_chip.dart';

class PwfStandaloneMapAdapterPanel extends StatelessWidget {
  const PwfStandaloneMapAdapterPanel({super.key, required this.record});

  final PwfReviewRecord? record;

  @override
  Widget build(BuildContext context) {
    final selected = record;
    if (selected == null) {
      return const Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('اختر سجلًا لعرض تجهيز محول الخريطة.'),
        ),
      );
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.map_outlined),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Map Adapter Preparation — ${selected.id}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                PwfStatusChip(label: selected.mapAdapterReadinessLabelAr, compact: true),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'هذه واجهة تحضيرية فقط. لا ترسم طبقات فعلية، لا تغيّر activeLayers، ولا تعتمد حدودًا سيادية. الهدف تجهيز payload واضح لدمجه لاحقًا مع flutter_map/PostGIS.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _EvidenceTile(label: 'النقطة التاريخية', value: selected.historicalPointLabel),
                _EvidenceTile(label: 'centroid المرشح', value: selected.candidatePointLabel),
                _EvidenceTile(label: 'سياسة الكاميرا', value: selected.mapCameraIntentLabelAr),
                _EvidenceTile(label: 'سياسة الطبقات', value: 'navigation_only / no_layer_toggle'),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: selected.hasHistoricalPoint ? () => _showAction(context, 'focus_historical_point') : null,
                  icon: const Icon(Icons.my_location_outlined),
                  label: const Text('تركيز على النقطة التاريخية'),
                ),
                OutlinedButton.icon(
                  onPressed: selected.hasCandidateCentroid ? () => _showAction(context, 'focus_candidate_centroid') : null,
                  icon: const Icon(Icons.location_searching_outlined),
                  label: const Text('تركيز على المرشح الحالي'),
                ),
                OutlinedButton.icon(
                  onPressed: selected.hasMapBbox ? () => _showAction(context, 'fit_bbox') : null,
                  icon: const Icon(Icons.fit_screen_outlined),
                  label: const Text('fitBounds على bbox'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _copyPayload(context, selected.mapAdapterPayloadPreview),
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('نسخ payload'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SelectableText(selected.mapAdapterPayloadPreview),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showAction(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('إجراء تحضيري فقط: $action — لا يوجد تحريك فعلي للخريطة في v0.48.')),
    );
  }

  static Future<void> _copyPayload(BuildContext context, String payload) async {
    await Clipboard.setData(ClipboardData(text: payload));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ payload محول الخريطة.')),
      );
    }
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
