// lib/features/platform_admin/data/repositories/admin_users_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/enums/enums.dart' as rbac;
import '../../../../core/services/supabase_service.dart';
import '../../../../data/models/admin_user.dart';

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  return AdminUsersRepository(ref.watch(supabaseClientProvider));
});

class AdminUsersRepository {
  final SupabaseClient _client;
  AdminUsersRepository(this._client);

  Future<List<AdminUser>> fetchAdminUsers({
    String? query,
    int limit = 200,
    int offset = 0,
  }) async {
    final res = await _client.rpc('rpc_admin_users_list', params: {
      'p_query': (query?.trim().isNotEmpty == true) ? query!.trim() : null,
      'p_limit': limit,
      'p_offset': offset,
    });

    return (res as List)
        .map((e) => AdminUser.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<Map<String, String>> fetchSystemRoles({
    required rbac.SystemKey systemKey,
    required List<String> userIds,
  }) async {
    if (userIds.isEmpty) return const <String, String>{};

    final res = await _client.rpc('rpc_system_roles_by_users', params: {
      'p_system_key': systemKey.name,
      'p_user_ids': userIds,
    });

    final out = <String, String>{};
    for (final row in (res as List)) {
      final m = (row as Map).cast<String, dynamic>();
      final uid = (m['user_id'] ?? '').toString();
      final role = (m['role'] ?? '').toString();
      if (uid.isNotEmpty && role.isNotEmpty) out[uid] = role;
    }
    return out;
  }

  rbac.Permission? _parsePermission(String key) {
    final k = key.trim();
    for (final p in rbac.Permission.values) {
      if (p.name == k) return p;
    }
    return null;
  }

  Future<Map<String, Set<rbac.Permission>>> fetchSystemPermissions({
    required rbac.SystemKey systemKey,
    required List<String> userIds,
  }) async {
    if (userIds.isEmpty) return const <String, Set<rbac.Permission>>{};

    final res = await _client.rpc('rpc_system_permissions_by_users', params: {
      'p_system_key': systemKey.name,
      'p_user_ids': userIds,
    });

    final out = <String, Set<rbac.Permission>>{};
    for (final row in (res as List)) {
      final m = (row as Map).cast<String, dynamic>();
      final uid = (m['user_id'] ?? '').toString();
      final pk = (m['permission_key'] ?? '').toString();
      final perm = _parsePermission(pk);
      if (uid.isEmpty || perm == null) continue;
      out.putIfAbsent(uid, () => <rbac.Permission>{}).add(perm);
    }
    return out;
  }

  Future<void> setAdminUserFlags({
    required String userId,
    bool? isActive,
    bool? isSuperuser,
    String? role,
  }) async {
    await _client.rpc('rpc_admin_user_set_flags', params: {
      'p_user_id': userId,
      'p_is_active': isActive,
      'p_is_superuser': isSuperuser,
      'p_role': role,
    });
  }

  Future<void> upsertSystemRole({
    required String userId,
    required rbac.SystemKey systemKey,
    required String role,
  }) async {
    await _client.rpc('rpc_upsert_system_role', params: {
      'p_user_id': userId,
      'p_system_key': systemKey.name,
      'p_role': role,
    });
  }

  Future<void> setSystemPermission({
    required String userId,
    required rbac.SystemKey systemKey,
    required rbac.Permission permission,
    required bool enabled,
  }) async {
    await _client.rpc('rpc_set_system_permission', params: {
      'p_user_id': userId,
      'p_system_key': systemKey.name,
      'p_permission_key': permission.name,
      'p_enabled': enabled,
    });
  }
}
