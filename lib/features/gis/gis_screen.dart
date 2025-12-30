import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:mustakshif_alwaqf/features/history/application/history_providers.dart';
import 'package:mustakshif_alwaqf/features/history/application/history_state_providers.dart';
import 'package:mustakshif_alwaqf/features/history/presentation/widgets/historical_layers_panel.dart';
import 'package:mustakshif_alwaqf/features/history/presentation/widgets/historical_time_slider.dart';

class GisScreen extends ConsumerWidget {
  const GisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriodId = ref.watch(selectedHistoricalPeriodIdProvider);
    final visibleLayerIds =
    ref.watch(visibleHistoricalLayerIdsProvider);

    return Scaffold(
      body: Row(
        children: [
          // الخريطة
          Expanded(
            flex: 3,
            child: _WaqfBaseMap(
              selectedPeriodId: selectedPeriodId,
              visibleLayerIds: visibleLayerIds,
            ),
          ),
          const SizedBox(width: 8),
          // الجانب الأيمن: التايم لاين + لوحة الطبقات
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: HistoricalTimeSlider(
                      onPeriodSelected: (period) {
                        ref
                            .read(
                          selectedHistoricalPeriodIdProvider.notifier,
                        )
                            .state = period.id;
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: HistoricalLayersPanel(
                    periodId: selectedPeriodId,
                    visibleLayerIds: visibleLayerIds,
                    onVisibleLayerIdsChanged: (newSet) {
                      ref
                          .read(
                        visibleHistoricalLayerIdsProvider.notifier,
                      )
                          .state = newSet;
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaqfBaseMap extends ConsumerWidget {
  const _WaqfBaseMap({
    super.key,
    required this.selectedPeriodId,
    required this.visibleLayerIds,
  });

  final int? selectedPeriodId;
  final Set<int> visibleLayerIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapController = MapController();

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        center: const LatLng(31.95, 35.23),
        zoom: 8,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'mustakshif_alwaqf',
        ),
        if (selectedPeriodId != null)
          _HistoricalLayersOverlay(
            mapController: mapController,
            periodId: selectedPeriodId!,
            visibleLayerIds: visibleLayerIds,
          ),
      ],
    );
  }
}

class _HistoricalLayersOverlay extends ConsumerWidget {
  const _HistoricalLayersOverlay({
    super.key,
    required this.mapController,
    required this.periodId,
    required this.visibleLayerIds,
  });

  final MapController mapController;
  final int periodId;
  final Set<int> visibleLayerIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layersAsync =
    ref.watch(historicalLayersByPeriodProvider(periodId));

    return layersAsync.when(
      data: (layers) {
        final visible = layers
            .where((layer) => visibleLayerIds.contains(layer.id))
            .toList();

        if (visible.isEmpty) {
          return const SizedBox.shrink();
        }

        // حالياً نعرض فقط عدّاد بسيط لعدد الطبقات الظاهرة
        return Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'عدد الطبقات التاريخية الظاهرة: ${visible.length}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
