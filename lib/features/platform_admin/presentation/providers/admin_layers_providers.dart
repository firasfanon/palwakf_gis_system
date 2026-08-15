// lib/features/platform_admin/presentation/providers/admin_layers_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/admin_gis_layers_repository.dart';
import '../../domain/models/admin_gis_layer_row.dart';

final adminGisLayersProvider =
    FutureProvider<List<AdminGisLayerRow>>((ref) async {
  return ref.watch(adminGisLayersRepositoryProvider).fetchAll();
});
