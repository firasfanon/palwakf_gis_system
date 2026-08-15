import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/history_styles_admin_repository.dart';
import '../../domain/models/historical_style_admin_rows.dart';

final historicalStyleProfilesProvider =
    FutureProvider<List<HistoricalStyleProfileRow>>((ref) async {
  return ref.watch(historyStylesAdminRepositoryProvider).fetchProfiles();
});

final historicalStyleLevelsProvider =
    FutureProvider<List<HistoricalAdminLevelOptionRow>>((ref) async {
  return ref.watch(historyStylesAdminRepositoryProvider).fetchLevels();
});

final historicalStylePeriodsProvider =
    FutureProvider<List<HistoricalPeriodStyleOptionRow>>((ref) async {
  return ref.watch(historyStylesAdminRepositoryProvider).fetchPeriods();
});

final historicalLevelStyleDefaultsProvider =
    FutureProvider<List<HistoricalLevelStyleDefaultRow>>((ref) async {
  return ref.watch(historyStylesAdminRepositoryProvider).fetchLevelDefaults();
});

final historicalPeriodLevelStyleOverridesProvider =
    FutureProvider<List<HistoricalPeriodLevelStyleOverrideRow>>((ref) async {
  return ref.watch(historyStylesAdminRepositoryProvider).fetchPeriodLevelOverrides();
});

final historicalFeatureStyleOverridesProvider =
    FutureProvider<List<HistoricalFeatureStyleOverrideRow>>((ref) async {
  return ref.watch(historyStylesAdminRepositoryProvider).fetchFeatureOverrides();
});
