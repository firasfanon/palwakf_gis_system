// lib/features/history/domain/repositories/history_admin_repository.dart


import '../domain/models/history_admin_models.dart';

/// واجهة مجردة لمستودع التقسيمات الإدارية التاريخية
abstract class IHistoryAdminRepository {
  Future<List<HistoricalAdminUnit>> getAdminUnitsByPeriod({
    required int periodId,
    required HistoricalAdminLevel level,
    int? parentId,
  });

  Future<HistoricalAdminUnit?> getAdminUnitById(int id);

  Future<List<LandAdminHistoryEntry>> getLandAdminHistory(int landId);
}
