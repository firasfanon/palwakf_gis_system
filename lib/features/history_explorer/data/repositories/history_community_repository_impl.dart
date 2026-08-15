import '../../domain/models/history_community_model.dart';
import '../datasources/history_community_remote_data_source.dart';

class HistoryCommunityRepositoryImpl {
  HistoryCommunityRepositoryImpl(this._remote);

  final HistoryCommunityRemoteDataSource _remote;

  Future<List<HistoryCommunityModel>> searchCommunities({
    String? query,
    String? governorateCode,
    int limit = 120,
  }) async {
    final rows = await _remote.searchCommunities(
      query: query,
      governorateCode: governorateCode,
      limit: limit,
    );
    return rows
        .map(HistoryCommunityModel.fromRow)
        .where((item) => item.code.trim().isNotEmpty)
        .toList(growable: false);
  }
}
