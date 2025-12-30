// lib/features/history/presentation/state/admin_unit_form_providers.dart



import 'package:flutter_riverpod/legacy.dart';
import 'package:mustakshif_alwaqf/features/history/data/history_admin_repository.dart';

import '../../application/history_admin_providers.dart';
import '../../domain/models/history_admin_models.dart';
import 'admin_unit_form_notifier.dart';

/// مزوّد لنموذج جديد (نمرر periodId + level من الشاشة)
final adminUnitFormNewProvider = StateNotifierProvider.autoDispose
    .family<AdminUnitFormNotifier, AdminUnitFormState,
    ({int periodId, HistoricalAdminLevel level})>((ref, args) {
  final repo = ref.watch(historyAdminRepositoryProvider);

  final initial = HistoricalAdminUnit(
    id: 0,
    periodId: args.periodId,
    parentId: null,
    level: args.level,
    code: null,
    nameAr: '',
    nameEn: null,
    altNames: null,
    areaKm2: null,
    population: null,
    metadata: null,
    createdAt: null,
    updatedAt: null,
  );

  return AdminUnitFormNotifier(repo as IHistoryAdminRepository, initial);
});

/// مزوّد لتحرير وحدة موجودة
final adminUnitFormExistingProvider = StateNotifierProvider.autoDispose
    .family<AdminUnitFormNotifier, AdminUnitFormState, HistoricalAdminUnit>(
        (ref, unit) {
      final repo = ref.watch(historyAdminRepositoryProvider);
      return AdminUnitFormNotifier(repo as IHistoryAdminRepository, unit);
    });
