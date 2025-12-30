// lib/features/lands/presentation/state/land_form_providers.dart

import 'package:flutter_riverpod/legacy.dart';

import '../../domain/models/waqf_land.dart';
import '../../domain/repositories/lands_repository.dart';
import '../../data/lands_providers.dart';
import 'land_form_notifier.dart';

/// نموذج أرض جديدة
final landFormNotifierProvider =
StateNotifierProvider.autoDispose<LandFormNotifier, LandFormState>(
      (ref) {
    final repo = ref.watch(landsRepositoryProvider);

    final initial = WaqfLand(
      id: null,
      pwfCode: '',
      nameAr: '',
      nameEn: null,
      governorate: null,
      city: null,
      areaDunum: null,
      classification: LandClassification.other,
      status: LandStatus.active,
      lat: null,
      lng: null,
      notes: null,
      metadata: null,
      createdAt: null,
      updatedAt: null,
    );

    return LandFormNotifier(repo as ILandsRepository, initial);
  },
);

/// نموذج لتحرير أرض موجودة
final landFormNotifierByExistingProvider =
StateNotifierProvider.autoDispose
    .family<LandFormNotifier, LandFormState, WaqfLand>(
      (ref, land) {
    final repo = ref.watch(landsRepositoryProvider);
    return LandFormNotifier(repo as ILandsRepository, land);
  },
);
