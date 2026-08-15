import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../domain/enums/mustakshif_map_layer_semantics.dart';
import '../../domain/models/mustakshif_layer_cartography.dart';
import 'pwf_dynamic_map_legend.dart';
import 'pwf_map_quality_badge.dart';

class PwfMapReadingPanel extends StatelessWidget {
  const PwfMapReadingPanel({
    super.key,
    required this.title,
    required this.currentZoom,
    required this.visibleLayers,
    this.selectedWaqfAssetLabel,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final double currentZoom;
  final List<MustakshifLayerCartography> visibleLayers;
  final String? selectedWaqfAssetLabel;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required double currentZoom,
    required List<MustakshifLayerCartography> visibleLayers,
    String? selectedWaqfAssetLabel,
    String? subtitle,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.86,
        child: PwfMapReadingPanel(
          title: title,
          subtitle: subtitle,
          currentZoom: currentZoom,
          visibleLayers: visibleLayers,
          selectedWaqfAssetLabel: selectedWaqfAssetLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewCount = visibleLayers.where((layer) => layer.requiresSourceReview).length;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF4F7FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: PwfColors.primaryBlue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.map_outlined, color: PwfColors.primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: PwfColors.primaryBlue,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if (subtitle != null && subtitle!.trim().isNotEmpty)
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: PwfColors.primaryBlue.withValues(alpha: 0.72),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                children: [
                  _MapReadingSummaryCard(
                    currentZoom: currentZoom,
                    visibleLayerCount: visibleLayers.length,
                    reviewCount: reviewCount,
                    selectedWaqfAssetLabel: selectedWaqfAssetLabel,
                  ),
                  const SizedBox(height: 12),
                  PwfDynamicMapLegend(layers: visibleLayers),
                  const SizedBox(height: 12),
                  const _MapReadingMethodCard(),
                  const SizedBox(height: 12),
                  _LayerMetadataList(layers: visibleLayers),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapReadingSummaryCard extends StatelessWidget {
  const _MapReadingSummaryCard({
    required this.currentZoom,
    required this.visibleLayerCount,
    required this.reviewCount,
    required this.selectedWaqfAssetLabel,
  });

  final double currentZoom;
  final int visibleLayerCount;
  final int reviewCount;
  final String? selectedWaqfAssetLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص القراءة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: PwfColors.primaryBlue,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PwfMapQualityBadge(label: 'الزوم: ${currentZoom.toStringAsFixed(2)}'),
              PwfMapQualityBadge(label: 'الطبقات الظاهرة: $visibleLayerCount'),
              PwfMapQualityBadge(label: 'تحتاج مراجعة: $reviewCount', warning: reviewCount > 0),
              if (selectedWaqfAssetLabel != null && selectedWaqfAssetLabel!.trim().isNotEmpty)
                PwfMapQualityBadge(label: 'الأصل: $selectedWaqfAssetLabel'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapReadingMethodCard extends StatelessWidget {
  const _MapReadingMethodCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PwfColors.royalRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PwfColors.royalRed.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: PwfColors.royalRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تنبيه منهجي',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: PwfColors.royalRed,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'هذه الخريطة أداة قراءة وتحليل ومراجعة. لا تُعد النتيجة سندًا قانونيًا نهائيًا إلا بعد مطابقة المصدر الرسمي والوثائق المعتمدة وإجراءات الاعتماد داخل النظام السيادي المختص.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PwfColors.royalRed,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _LayerMetadataList extends StatelessWidget {
  const _LayerMetadataList({required this.layers});

  final List<MustakshifLayerCartography> layers;

  @override
  Widget build(BuildContext context) {
    final ordered = [...layers]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    if (ordered.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'بطاقات الطبقات',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: PwfColors.primaryBlue,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        for (final layer in ordered) ...[
          _LayerMetadataCard(layer: layer),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _LayerMetadataCard extends StatelessWidget {
  const _LayerMetadataCard({required this.layer});

  final MustakshifLayerCartography layer;

  @override
  Widget build(BuildContext context) {
    final color = layer.requiresSourceReview ? PwfColors.royalRed : PwfColors.primaryBlue;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  layer.layerNameAr,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: PwfColors.primaryBlue,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              PwfMapQualityBadge.legalWeight(layer.legalWeight, compact: true),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PwfMapQualityBadge(label: 'الغرض: ${layer.purpose.labelAr}', compact: true),
              PwfMapQualityBadge(label: 'الهندسة: ${layer.geometryType}', compact: true),
              PwfMapQualityBadge.accuracy(layer.accuracyLevel, compact: true),
              PwfMapQualityBadge(label: 'المصدر: ${layer.readableSourceAr}', warning: layer.sourceName == null, compact: true),
            ],
          ),
          if (layer.notes != null && layer.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              layer.notes!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}
