import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../map/data/repositories/gis_repository.dart';
import '../../../map/domain/models/gis_layer_model.dart';

final adminGisLayersProvider =
    FutureProvider.autoDispose<List<GisLayerModel>>((ref) async {
  final repo = ref.watch(gisRepositoryProvider);
  // Admin view: show all layers (active/inactive + public/internal) if RLS permits.
  return repo.fetchLayers(activeOnly: false, publicOnly: false);
});
