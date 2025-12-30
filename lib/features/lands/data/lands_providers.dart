// lib/features/lands/data/lands_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/waqf_land.dart';
import 'lands_repository.dart';

/// مستودع الأراضي (Repository)
final landsRepositoryProvider = Provider<ILandsRepository>((ref) {
  final client = Supabase.instance.client;
  return SupabaseLandsRepository(client);
});

/// نص البحث في قائمة الأراضي
final landsSearchQueryProvider = StateProvider<String?>((ref) => null);

/// مزود قائمة الأراضي (مع فلترة اختيارية بالبحث)
final landsListProvider =
FutureProvider.autoDispose<List<WaqfLand>>((ref) async {
  final repo = ref.watch(landsRepositoryProvider);
  final search = ref.watch(landsSearchQueryProvider);
  return repo.getLands(searchQuery: search);
});

/// مزود أرض واحدة حسب المعرف
final landByIdProvider =
FutureProvider.autoDispose.family<WaqfLand?, int>((ref, id) async {
  final repo = ref.watch(landsRepositoryProvider);
  return repo.getLandById(id);
});
