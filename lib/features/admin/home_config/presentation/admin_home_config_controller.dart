// lib/features/admin/home_config/presentation/admin_home_config_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/home_config.dart';
import '../../data/home_config_repository.dart';

/// Admin Home Config Controller using AsyncNotifier (Riverpod 2.x)
class AdminHomeConfigController extends AsyncNotifier<HomeConfig?> {
  HomeConfigRepository get _repo => ref.read(homeConfigRepositoryProvider);

  @override
  Future<HomeConfig?> build() async {
    return await loadConfig();
  }

  Future<HomeConfig?> loadConfig() async {
    state = const AsyncValue.loading();

    try {
      final config = await _repo.fetchConfig();
      state = AsyncValue.data(config);
      return config;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> save(HomeConfig config) async {
    await updateConfig(config);
  }

  Future<void> updateConfig(HomeConfig config) async {
    state = const AsyncValue.loading();

    try {
      await _repo.saveConfig(config);
      state = AsyncValue.data(config);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Repository Provider
final homeConfigRepositoryProvider = Provider<HomeConfigRepository>((ref) {
  return HomeConfigRepository();
});

/// Admin Home Config Provider (Riverpod 2.x)
final adminHomeConfigControllerProvider =
AsyncNotifierProvider<AdminHomeConfigController, HomeConfig?>(() {
  return AdminHomeConfigController();
});