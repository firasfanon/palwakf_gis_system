// lib/features/history/application/history_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/history_repository.dart';
import '../domain/models/history_models.dart';

/// مزود الـ Repository الخاص بالتاريخ
final historyRepositoryProvider = Provider<IHistoryRepository>((ref) {
  final client = Supabase.instance.client;
  return SupabaseHistoryRepository(client);
});

/// كل الفترات التاريخية
final historicalPeriodsProvider =
FutureProvider<List<HistoricalPeriod>>((ref) async {
  final repo = ref.watch(historyRepositoryProvider);
  return repo.getPeriods();
});

/// الطبقات الفعّالة لفترة معيّنة
final historicalLayersByPeriodProvider =
FutureProvider.family<List<HistoricalLayer>, int>((ref, periodId) async {
  final repo = ref.watch(historyRepositoryProvider);
  return repo.getActiveLayersByPeriod(periodId);
});

/// اللقطات/الصور التاريخية لفترة معيّنة
final historicalSnapshotsByPeriodProvider =
FutureProvider.family<List<HistoricalMapSnapshot>, int>(
      (ref, periodId) async {
    final repo = ref.watch(historyRepositoryProvider);
    return repo.getSnapshotsByPeriod(periodId);
  },
);
