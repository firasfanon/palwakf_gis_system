import '../../domain/models/waqf_asset_model.dart';
import '../datasources/waqf_asset_remote_data_source.dart';

class WaqfAssetRepositoryImpl {
  WaqfAssetRepositoryImpl(this._remote);

  final WaqfAssetRemoteDataSource _remote;

  Future<List<WaqfAssetModel>> searchByNameOrNationalCode({
    String? query,
    int limit = 40,
    String? endowmentName,
  }) async {
    final rows = await _remote.searchAssets(
      query: query,
      limit: limit,
      endowmentName: endowmentName,
    );
    return _dedupe(rows.map(WaqfAssetModel.fromRow));
  }

  Future<WaqfAssetModel?> getAssetDetails({
    required String waqfAssetId,
    String? nationalAssetCode,
  }) async {
    final row = await _remote.fetchAssetDetails(
      waqfAssetId: waqfAssetId,
      nationalAssetCode: nationalAssetCode,
    );
    if (row == null) return null;
    return WaqfAssetModel.fromRow(row);
  }

  Future<List<Map<String, dynamic>>> getLinkedParcels({
    required String waqfAssetId,
    String? nationalAssetCode,
  }) {
    return _remote.fetchLinkedParcels(
      waqfAssetId: waqfAssetId,
      nationalAssetCode: nationalAssetCode,
    );
  }

  Future<List<WaqfAssetModel>> filterByEndowment({
    required String endowmentName,
    int limit = 40,
    String? query,
  }) {
    return searchByNameOrNationalCode(
      query: query,
      limit: limit,
      endowmentName: endowmentName,
    );
  }

  List<WaqfAssetModel> _dedupe(Iterable<WaqfAssetModel> items) {
    final seen = <String>{};
    final out = <WaqfAssetModel>[];
    for (final item in items) {
      final key = item.waqfAssetId.trim().isNotEmpty
          ? item.waqfAssetId.trim()
          : item.nationalAssetCode.trim();
      if (key.isEmpty || !seen.add(key)) continue;
      out.add(item);
    }
    return out;
  }
}
