// lib/features/lands/presentation/state/land_form_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // حسب طلبك لــ StateNotifier
import 'package:flutter/foundation.dart';


import '../../domain/models/waqf_land.dart';
import '../../domain/repositories/lands_repository.dart';

@immutable
class LandFormState {
  final WaqfLand land;
  final bool isSaving;
  final bool isDeleting;
  final bool saveSuccess;
  final String? error;

  const LandFormState({
    required this.land,
    this.isSaving = false,
    this.isDeleting = false,
    this.saveSuccess = false,
    this.error,
  });

  LandFormState copyWith({
    WaqfLand? land,
    bool? isSaving,
    bool? isDeleting,
    bool? saveSuccess,
    String? error,
    bool clearError = false,
  }) {
    return LandFormState(
      land: land ?? this.land,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LandFormNotifier extends StateNotifier<LandFormState> {
  LandFormNotifier(this._repo, WaqfLand initial)
      : super(LandFormState(land: initial));

  final ILandsRepository _repo;

  // --- field updaters (مطابقة للأسماء في LandFormFields) ---

  void updatePwfCode(String value) {
    state = state.copyWith(
      land: state.land.copyWith(pwfCode: value),
      clearError: true,
    );
  }

  void updateNameAr(String value) {
    state = state.copyWith(
      land: state.land.copyWith(nameAr: value),
      clearError: true,
    );
  }

  void updateNameEn(String value) {
    state = state.copyWith(
      land: state.land.copyWith(nameEn: value),
      clearError: true,
    );
  }

  void updateGovernorate(String? value) {
    state = state.copyWith(
      land: state.land.copyWith(governorate: value),
      clearError: true,
    );
  }

  void updateCity(String? value) {
    state = state.copyWith(
      land: state.land.copyWith(city: value),
      clearError: true,
    );
  }

  void updateAreaDunum(String value) {
    final trimmed = value.trim();
    final parsed = trimmed.isEmpty ? null : double.tryParse(trimmed);
    state = state.copyWith(
      land: state.land.copyWith(areaDunum: parsed),
      clearError: true,
    );
  }

  void updateClassification(LandClassification value) {
    state = state.copyWith(
      land: state.land.copyWith(classification: value),
      clearError: true,
    );
  }

  void updateStatus(LandStatus value) {
    state = state.copyWith(
      land: state.land.copyWith(status: value),
      clearError: true,
    );
  }

  void updateLat(String value) {
    final trimmed = value.trim();
    final parsed = trimmed.isEmpty ? null : double.tryParse(trimmed);
    state = state.copyWith(
      land: state.land.copyWith(lat: parsed),
      clearError: true,
    );
  }

  void updateLng(String value) {
    final trimmed = value.trim();
    final parsed = trimmed.isEmpty ? null : double.tryParse(trimmed);
    state = state.copyWith(
      land: state.land.copyWith(lng: parsed),
      clearError: true,
    );
  }

  void updateNotes(String value) {
    state = state.copyWith(
      land: state.land.copyWith(notes: value),
      clearError: true,
    );
  }

  // --- save / delete ---

  Future<void> save() async {
    if (state.land.pwfCode.trim().isEmpty ||
        state.land.nameAr.trim().isEmpty) {
      state = state.copyWith(
        error: 'الرجاء تعبئة رمز PWF والاسم بالعربية',
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
      WaqfLand saved;
      if (state.land.id == null) {
        saved = await _repo.createLand(state.land);
      } else {
        saved = await _repo.updateLand(state.land);
      }

      state = state.copyWith(
        land: saved,
        isSaving: false,
        saveSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        saveSuccess: false,
        error: e.toString(),
      );
    }
  }

  Future<void> delete() async {
    if (state.land.id == null) return;

    state = state.copyWith(
      isDeleting: true,
      clearError: true,
      saveSuccess: false,
    );

    try {
      await _repo.deleteLand(state.land.id!.toString());
      state = state.copyWith(
        isDeleting: false,
        saveSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isDeleting: false,
        saveSuccess: false,
        error: e.toString(),
      );
    }
  }
}
