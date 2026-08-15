import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/historical_crud_admin_repository.dart';
import '../../domain/models/historical_admin_relation_crud_row.dart';
import '../../domain/models/historical_admin_spatial_link_row.dart';
import '../../domain/models/historical_admin_unit_row.dart';
import '../../domain/models/historical_manual_predecessor_map_row.dart';
import '../../domain/models/historical_period_row.dart';
import '../../domain/models/historical_topology_queue_row.dart';

final historicalPeriodsCrudProvider =
    FutureProvider<List<HistoricalPeriodRow>>((ref) async {
  return ref.watch(historicalCrudAdminRepositoryProvider).fetchPeriods();
});

final historicalAdminUnitsCrudProvider =
    FutureProvider<List<HistoricalAdminUnitRow>>((ref) async {
  return ref.watch(historicalCrudAdminRepositoryProvider).fetchUnits();
});

final historicalRelationsCrudProvider =
    FutureProvider<List<HistoricalAdminRelationCrudRow>>((ref) async {
  return ref
      .watch(historicalCrudAdminRepositoryProvider)
      .fetchRelationTableRows();
});

final historicalQueueCrudProvider =
    FutureProvider<List<HistoricalTopologyQueueRow>>((ref) async {
  return ref.watch(historicalCrudAdminRepositoryProvider).fetchQueueTableRows();
});

final historicalManualMappingsCrudProvider =
    FutureProvider<List<HistoricalManualPredecessorMapRow>>((ref) async {
  return ref.watch(historicalCrudAdminRepositoryProvider).fetchManualMappings();
});

final historicalSpatialLinksCrudProvider =
    FutureProvider<List<HistoricalAdminSpatialLinkRow>>((ref) async {
  return ref
      .watch(historicalCrudAdminRepositoryProvider)
      .fetchSpatialLinkTableRows();
});
