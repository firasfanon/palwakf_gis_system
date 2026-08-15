// lib/features/admin/users/data/users_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/user_account.dart';
import '../../domain/permissions.dart';

class UsersRepository {
  final _client = Supabase.instance.client;

  Future<List<UserAccount>> list() async {
    try {
      final res = await _client.from('user_accounts').select();
      return List<Map<String, dynamic>>.from(res)
          .map(UserAccount.fromMap)
          .toList();
    } catch (_) {
      // Demo data for local development when Supabase is unavailable.
      return [
        UserAccount(
          id: 'demo_super',
          email: 'super@waqf.ps',
          fullName: 'Super User',
          role: UserRole.superuser,
          permissions: Permission.values,
        ),
        UserAccount(
          id: 'u1',
          email: 'admin@waqf.ps',
          fullName: 'Site Admin',
          role: UserRole.admin,
          permissions: const [
            Permission.manageUsers,
            Permission.manageHome,
            Permission.manageSite,
            Permission.manageMapLayers,
            Permission.manageLandsCrud,
            Permission.viewReports,
          ],
        ),
      ];
    }
  }

  Future<void> create(UserAccount u) async {
    await _client.from('user_accounts').insert(u.toMap());
  }

  Future<void> update(UserAccount u) async {
    await _client.from('user_accounts').update(u.toMap()).eq('id', u.id);
  }

  Future<void> delete(String id) async {
    await _client.from('user_accounts').delete().eq('id', id);
  }

  static List<Permission> defaultPerms(UserRole role) {
    switch (role) {
      case UserRole.superuser:
        return Permission.values;
      case UserRole.admin:
        return const [
          Permission.manageUsers,
          Permission.manageHome,
          Permission.manageSite,
          Permission.manageMapLayers,
          Permission.manageLandsCrud,
          Permission.viewReports,
        ];
      case UserRole.user:
        return const [Permission.manageLandsCrud, Permission.viewReports];
      case UserRole.viewer:
        return const [Permission.viewReports];
    }
  }
}