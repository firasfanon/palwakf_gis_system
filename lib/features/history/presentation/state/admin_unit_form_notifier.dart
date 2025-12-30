// lib/features/history/presentation/state/admin_unit_form_notifier.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';


import '../../data/history_admin_repository.dart';
import '../../domain/models/history_admin_models.dart';

@immutable
class AdminUnitFormState {
  final HistoricalAdminUnit unit;
  final bool isSaving;
  final bool isDeleting;
  final String? error;
  final bool saveSuccess;

  const AdminUnitFormState({
    required this.unit,
    this.isSaving = false,
    this.isDeleting = false,
    this.error,
    this.saveSuccess = false,
  });

  AdminUnitFormState copyWith({
    HistoricalAdminUnit? unit,
    bool? isSaving,
    bool? isDeleting,
    String? error,
    bool? clearError,
    bool? saveSuccess,
  }) {
    return AdminUnitFormState(
      unit: unit ?? this.unit,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      error: clearError == true ? null : (error ?? this.error),
      saveSuccess: saveSuccess ?? this.saveSuccess,
    );
  }
}

class AdminUnitFormNotifier extends StateNotifier<AdminUnitFormState> {
  AdminUnitFormNotifier(this._repo, HistoricalAdminUnit initial)
      : super(AdminUnitFormState(unit: initial));

  final IHistoryAdminRepository _repo;

  bool get isNew => state.unit.id == 0;

  void updateLevel(HistoricalAdminLevel level) {
    state = state.copyWith(
      unit: state.unit.copyWith(level: level),
      clearError: true,
      saveSuccess: false,
    );
  }

  void updateNameAr(String value) {
    state = state.copyWith(
      unit: state.unit.copyWith(nameAr: value),
      clearError: true,
      saveSuccess: false,
    );
  }

  void updateNameEn(String value) {
    state = state.copyWith(
      unit: state.unit.copyWith(nameEn: value),
      clearError: true,
      saveSuccess: false,
    );
  }

  void updateCode(String value) {
    final normalized = value.trim();
    state = state.copyWith(
      unit: state.unit.copyWith(
        code: normalized.isEmpty ? null : normalized,
      ),
      clearError: true,
      saveSuccess: false,
    );
  }

  void updateParentId(int? parentId) {
    state = state.copyWith(
      unit: state.unit.copyWith(parentId: parentId),
      clearError: true,
      saveSuccess: false,
    );
  }

  void updateAreaKm2(String value) {
    final normalized = value.replaceAll(',', '');
    final parsed = double.tryParse(normalized);
    state = state.copyWith(
      unit: state.unit.copyWith(areaKm2: parsed),
      clearError: true,
      saveSuccess: false,
    );
  }

  void updatePopulation(String value) {
    final normalized = value.replaceAll(',', '');
    final parsed = int.tryParse(normalized);
    state = state.copyWith(
      unit: state.unit.copyWith(population: parsed),
      clearError: true,
      saveSuccess: false,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> save() async {
    if (state.unit.nameAr.trim().isEmpty) {
      state = state.copyWith(
        error: 'الرجاء إدخال اسم الوحدة بالعربية',
        saveSuccess: false,
      );
      return;
    }

    state = state.copyWith(
      isSaving: true,
      clearError: true,
      saveSuccess: false,
    );

    try {
      final unit = state.unit;
      if (isNew) {
        final created = await _repo.createAdminUnit(unit);
        state = state.copyWith(
          unit: created,
          isSaving: false,
          saveSuccess: true,
        );
      } else {
        final updated = await _repo.updateAdminUnit(unit);
        state = state.copyWith(
          unit: updated,
          isSaving: false,
          saveSuccess: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
        saveSuccess: false,
      );
    }
  }

  Future<void> delete() async {
    if (isNew) return;

    state = state.copyWith(
      isDeleting: true,
      clearError: true,
      saveSuccess: false,
    );

    try {
      await _repo.deleteAdminUnit(state.unit.id);
      state = state.copyWith(
        isDeleting: false,
        saveSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isDeleting: false,
        error: e.toString(),
        saveSuccess: false,
      );
    }
  }
}
