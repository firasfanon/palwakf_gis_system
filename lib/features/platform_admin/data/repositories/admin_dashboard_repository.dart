import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';

final adminDashboardRepositoryProvider =
    Provider<AdminDashboardRepository>((ref) {
  return AdminDashboardRepository(ref.watch(supabaseClientProvider));
});

class AdminDashboardRepository {
  final SupabaseClient _client;
  AdminDashboardRepository(this._client);

  Future<AdminDashboardCounts> loadCounts() async {
    // Simple counts to avoid compatibility issues with CountOption.
    final users = await _client
        .from('admin_users')
        .select('id,is_active,is_superuser,role');
    final layers = await _client
        .schema('gis')
        .from('gis_layers')
        .select('id,is_public,is_active');

    final usersList =
        (users as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
    final layersList = (layers as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();

    final usersTotal = usersList.length;
    final usersActive =
        usersList.where((u) => (u['is_active'] as bool?) == true).length;
    final usersSuper = usersList.where((u) {
      final isSuper = (u['is_superuser'] as bool?) == true;
      final role = (u['role'] ?? '').toString().toLowerCase();
      return isSuper || role == 'super_admin';
    }).length;

    final layersTotal = layersList.length;
    final layersPublic =
        layersList.where((l) => (l['is_public'] as bool?) == true).length;
    final layersActive =
        layersList.where((l) => (l['is_active'] as bool?) == true).length;
    final layersPublicActive = layersList.where((l) {
      return (l['is_public'] as bool?) == true &&
          (l['is_active'] as bool?) == true;
    }).length;

    return AdminDashboardCounts(
      usersTotal: usersTotal,
      usersActive: usersActive,
      usersSuper: usersSuper,
      layersTotal: layersTotal,
      layersPublic: layersPublic,
      layersActive: layersActive,
      layersPublicActive: layersPublicActive,
    );
  }
}

class AdminDashboardCounts {
  final int usersTotal;
  final int usersActive;
  final int usersSuper;

  final int layersTotal;
  final int layersPublic;
  final int layersActive;
  final int layersPublicActive;

  const AdminDashboardCounts({
    required this.usersTotal,
    required this.usersActive,
    required this.usersSuper,
    required this.layersTotal,
    required this.layersPublic,
    required this.layersActive,
    required this.layersPublicActive,
  });
}
