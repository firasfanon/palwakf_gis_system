import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../domain/enums/mustakshif_map_layer_semantics.dart';
import '../../domain/models/mustakshif_layer_cartography.dart';
import 'pwf_map_quality_badge.dart';

class PwfDynamicMapLegend extends StatelessWidget {
  const PwfDynamicMapLegend({
    super.key,
    required this.layers,
    this.title = 'مفتاح الخريطة',
    this.maxHeight = 360,
  });

  final List<MustakshifLayerCartography> layers;
  final String title;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final visibleLayers = [...layers]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  const Icon(Icons.layers_outlined, color: PwfColors.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: PwfColors.primaryBlue,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  Text(
                    '${visibleLayers.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: PwfColors.primaryBlue,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (visibleLayers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text('لا توجد طبقات ظاهرة ضمن مستوى الزوم الحالي.'),
              )
            else
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.all(10),
                  shrinkWrap: true,
                  itemCount: visibleLayers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _LegendLayerTile(layer: visibleLayers[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendLayerTile extends StatelessWidget {
  const _LegendLayerTile({required this.layer});

  final MustakshifLayerCartography layer;

  @override
  Widget build(BuildContext context) {
    final requiresReview = layer.requiresSourceReview;
    final color = requiresReview ? PwfColors.royalRed : PwfColors.primaryBlue;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        layer.layerNameAr,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: PwfColors.primaryBlue,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    PwfMapQualityBadge.legalWeight(layer.legalWeight, compact: true),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    PwfMapQualityBadge(label: layer.purpose.labelAr, compact: true),
                    PwfMapQualityBadge.accuracy(layer.accuracyLevel, compact: true),
                    PwfMapQualityBadge(label: layer.geometryType, compact: true),
                  ],
                ),
                if (layer.warningAr != null && layer.warningAr!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    layer.warningAr!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PwfColors.royalRed,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
