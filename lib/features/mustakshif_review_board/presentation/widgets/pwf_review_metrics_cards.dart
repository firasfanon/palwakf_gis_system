import 'package:flutter/material.dart';

import '../pwf_review_board_providers.dart';

class PwfReviewMetricsCards extends StatelessWidget {
  const PwfReviewMetricsCards({super.key, required this.state});

  final PwfReviewBoardState state;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricItem('إجمالي السجلات', state.records.length.toString(), Icons.inventory_2_outlined),
      _MetricItem('بعد الفلترة', state.filteredRecords.length.toString(), Icons.filter_alt_outlined),
      _MetricItem('مصادر مدخلة', state.locatorReadyCount.toString(), Icons.source_outlined),
      _MetricItem('توقيع مزدوج', state.dualDecisionCount.toString(), Icons.verified_user_outlined),
      _MetricItem('قرارات متطابقة', state.alignedDecisionCount.toString(), Icons.check_circle_outline),
      _MetricItem('جاهز داخليًا', state.decisionPackageReadyCount.toString(), Icons.assignment_turned_in_outlined),
      _MetricItem('استثناءات مكانية', state.spatialRiskCount.toString(), Icons.map_outlined),
      _MetricItem('إصلاح هندسي', state.geometryRepairCount.toString(), Icons.architecture_outlined),
      _MetricItem('بحث يدوي', state.manualResearchCount.toString(), Icons.manage_search_outlined),
      _MetricItem('مسودات محلية', state.localDraftCount.toString(), Icons.save_outlined),
      _MetricItem('محجوبة', state.blockedCount.toString(), Icons.block_outlined),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: metrics.map((metric) => _MetricCard(item: metric)).toList(),
    );
  }
}

class _MetricItem {
  const _MetricItem(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 138,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(item.icon, size: 15),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
