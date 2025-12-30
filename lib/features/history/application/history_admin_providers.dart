// lib/features/history/application/history_admin_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../domain/models/history_admin_models.dart';
import '../domain/repositories/history_admin_repository.dart';

/// Repository للتقسيمات الإدارية التاريخية
final historyAdminRepositoryProvider =
Provider<IHistoryAdminRepository>((ref) {
  // يتم override في main داخل ProviderScope
  throw UnimplementedError(
    'historyAdminRepositoryProvider must be overridden with a concrete implementation',
  );
});

/// الفلتر: الفترة التاريخية المختارة (id رقمي)
final adminCrudFilterPeriodIdProvider = StateProvider<int?>(
      (ref) => null,
);

/// الفلتر: المستوى الإداري (لواء / قضاء / محافظة / مدينة / قرية)
final adminCrudFilterLevelProvider = StateProvider<HistoricalAdminLevel?>(
      (ref) => null,
);

/// الفلتر: الأب (لوحدة تابعة لوحدة أعلى)
final adminCrudFilterParentIdProvider = StateProvider<int?>(
      (ref) => null,
);

/// قائمة الوحدات الإدارية حسب الفلاتر الحالية
final adminUnitsCrudListProvider =
FutureProvider.autoDispose<List<HistoricalAdminUnit>>((ref) async {
  final repo = ref.watch(historyAdminRepositoryProvider);

  final periodId = ref.watch(adminCrudFilterPeriodIdProvider);
  final level = ref.watch(adminCrudFilterLevelProvider);
  final parentId = ref.watch(adminCrudFilterParentIdProvider);

  if (periodId == null || level == null) {
    return <HistoricalAdminUnit>[];
  }

  return repo.getAdminUnitsByPeriod(
    periodId: periodId,
    level: level,
    parentId: parentId,
  );
});

/// وحدة إدارية واحدة بالـ id
final adminUnitByIdProvider =
FutureProvider.family<HistoricalAdminUnit?, int>((ref, id) async {
  final repo = ref.watch(historyAdminRepositoryProvider);
  return repo.getAdminUnitById(id);
});

/// السجل التاريخي الإداري لأرض معينة
final landAdminHistoryProvider =
FutureProvider.family<List<LandAdminHistoryEntry>, int>(
        (ref, landId) async {
      final repo = ref.watch(historyAdminRepositoryProvider);
      return repo.getLandAdminHistory(landId);
    });
