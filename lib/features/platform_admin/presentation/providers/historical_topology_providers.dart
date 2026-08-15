import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/historical_topology_admin_repository.dart';
import '../../domain/models/historical_admin_relation_review_row.dart';
import '../../domain/models/historical_admin_review_metric.dart';
import '../../domain/models/historical_admin_spatial_link_review_row.dart';
import '../../domain/models/historical_gap_summary_item.dart';
import '../../domain/models/historical_topology_queue_row.dart';

final historicalTopologySummaryProvider =
    FutureProvider<List<HistoricalAdminReviewMetric>>((ref) async {
  return ref.watch(historicalTopologyAdminRepositoryProvider).fetchSummary();
});

final historicalTopologyGapSummaryProvider =
    FutureProvider<List<HistoricalGapSummaryItem>>((ref) async {
  return ref.watch(historicalTopologyAdminRepositoryProvider).fetchGapSummary();
});

final historicalTopologyRelationsProvider =
    FutureProvider<List<HistoricalAdminRelationReviewRow>>((ref) async {
  return ref.watch(historicalTopologyAdminRepositoryProvider).fetchRelations();
});

final historicalTopologySpatialLinksProvider =
    FutureProvider<List<HistoricalAdminSpatialLinkReviewRow>>((ref) async {
  return ref
      .watch(historicalTopologyAdminRepositoryProvider)
      .fetchSpatialLinks();
});

final historicalTopologyQueueProvider =
    FutureProvider<List<HistoricalTopologyQueueRow>>((ref) async {
  return ref.watch(historicalTopologyAdminRepositoryProvider).fetchQueueRows();
});

final historicalTopologyAppliedEventsProvider =
    FutureProvider<List<HistoricalTopologyQueueRow>>((ref) async {
  return ref
      .watch(historicalTopologyAdminRepositoryProvider)
      .fetchAppliedEvents();
});
