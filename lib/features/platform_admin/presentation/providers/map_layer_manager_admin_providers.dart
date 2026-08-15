import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../map/data/repositories/map_layer_manager_repository.dart';

final adminMapLayerConfigsProvider =
    FutureProvider.autoDispose<List<MapLayerAdminConfig>>((ref) async {
  return ref.watch(mapLayerManagerRepositoryProvider).listLayerConfigs(
        includeInactive: true,
      );
});

final adminMapLayerIntegrityProvider =
    FutureProvider.autoDispose<List<MapLayerIntegrityResult>>((ref) async {
  return ref.watch(mapLayerManagerRepositoryProvider).checkLayerIntegrity(
        persist: false,
      );
});

final adminMapLayerRolePreviewProvider =
    FutureProvider.autoDispose<List<MapLayerRolePreview>>((ref) async {
  return ref.watch(mapLayerManagerRepositoryProvider).fetchRolePreview();
});
