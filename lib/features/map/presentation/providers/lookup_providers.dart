// lib/features/map/presentation/providers/lookup_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/lookup_repository.dart';
import '../../domain/models/lookup_item.dart';

final governoratesLookupProvider =
    FutureProvider<List<LookupItem>>((ref) async {
  return ref.watch(lookupRepositoryProvider).fetchGovernorates();
});

final lgusLookupProvider = FutureProvider.family<List<LookupItem>, String?>(
    (ref, governorateCode) async {
  final all = await ref.watch(lookupRepositoryProvider).fetchLgus();
  if (governorateCode == null || governorateCode.trim().isEmpty) return all;
  final filtered = all
      .where((i) =>
          (i.parentCode ?? '').toLowerCase() == governorateCode.toLowerCase())
      .toList();
  return filtered.isEmpty ? all : filtered;
});

final communitiesLookupProvider =
    FutureProvider.family<List<LookupItem>, String?>((ref, lguCode) async {
  final all = await ref.watch(lookupRepositoryProvider).fetchCommunities();
  if (lguCode == null || lguCode.trim().isEmpty) return all;
  final filtered = all
      .where((i) => (i.parentCode ?? '').toLowerCase() == lguCode.toLowerCase())
      .toList();
  return filtered.isEmpty ? all : filtered;
});

final naturalCommunitiesLookupProvider =
    FutureProvider.family<List<LookupItem>, LookupItem?>((ref, governorate) async {
  if (governorate == null) return const [];
  final code = governorate.code.trim();
  final name = governorate.bestLabel.trim();
  if (code.isEmpty && name.isEmpty) return const [];

  return ref.watch(lookupRepositoryProvider).fetchCommunitiesByGovernorate(
        code,
        governorateName: name,
      );
});
