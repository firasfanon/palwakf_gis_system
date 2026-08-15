import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/history_explorer_remote_datasource.dart';
import '../../data/datasources/waqf_asset_remote_data_source.dart';
import '../../data/repositories/history_explorer_repository_impl.dart';
import '../../data/repositories/waqf_asset_repository_impl.dart';
import '../../domain/repositories/history_explorer_repository.dart';
import '../../domain/repositories/history_lineage_repository.dart';
import '../controllers/history_explorer_controller.dart';
import '../../data/repositories/history_lineage_repository_impl.dart';
import '../../../waqf/application/providers/waqf_reference_providers.dart';
import '../state/history_explorer_state.dart';

final historyExplorerRemoteDataSourceProvider = Provider<HistoryExplorerRemoteDataSource>((ref) {
  return HistoryExplorerRemoteDataSource();
});

final historyExplorerRepositoryProvider = Provider<HistoryExplorerRepository>((ref) {
  return HistoryExplorerRepositoryImpl(ref.watch(historyExplorerRemoteDataSourceProvider));
});

final historyLineageRepositoryProvider = Provider<HistoryLineageRepository>((ref) {
  return HistoryLineageRepositoryImpl(ref.watch(historyExplorerRemoteDataSourceProvider));
});

final waqfAssetRemoteDataSourceProvider = Provider<WaqfAssetRemoteDataSource>((ref) {
  return WaqfAssetRemoteDataSource();
});

final waqfAssetRepositoryProvider = Provider<WaqfAssetRepositoryImpl>((ref) {
  return WaqfAssetRepositoryImpl(ref.watch(waqfAssetRemoteDataSourceProvider));
});

final historyExplorerControllerProvider = StateNotifierProvider<HistoryExplorerController, HistoryExplorerState>((ref) {
  return HistoryExplorerController(
    ref.watch(historyExplorerRepositoryProvider),
    ref.watch(historyLineageRepositoryProvider),
    ref.watch(waqfReferenceRepositoryProvider),
    ref.watch(waqfAssetRepositoryProvider),
  );
});
