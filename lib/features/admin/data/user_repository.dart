// lib/features/admin/data/user_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/user_account.dart';
import '../domain/permissions.dart';

class UserRepository {
  UserRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _table = 'user_accounts';

  Future<List<UserAccount>> fetchUsers() async {
    final response = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);

    final rows = response as List<dynamic>;
    return rows
        .map((row) => _convertToUserAccount(row as Map<String, dynamic>))
        .toList();
  }

  Future<UserAccount?> getUserById(String id) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return _convertToUserAccount(response as Map<String, dynamic>);
  }

  Future<void> createUser(UserAccount user) async {
    final payload = _convertFromUserAccount(user)
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');

    await _client.from(_table).insert(payload);
  }

  Future<void> updateUser(UserAccount user) async {
    final payload = _convertFromUserAccount(user)
      ..remove('created_at')
      ..remove('updated_at');

    await _client.from(_table).update(payload).eq('id', user.id);
  }

  Future<void> deleteUser(String userId) async {
    await _client.from(_table).delete().eq('id', userId);
  }

  // Helper methods
  UserAccount _convertToUserAccount(Map<String, dynamic> json) {
    // تحويل permissions من List إلى List<Permission>
    final permissionsList = (json['permissions'] as List<dynamic>?)
        ?.map((e) {
      final permStr = e.toString();
      // ابحث عن القيمة، وإذا لم توجد استخدم أول قيمة متاحة
      try {
        return Permission.values.firstWhere(
              (p) => p.toString().split('.').last == permStr,
        );
      } catch (_) {
        return Permission.values.first;
      }
    })
        .toList() ??
        <Permission>[];

    return UserAccount(
      id: json['id'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
            (e) => e.toString().split('.').last == (json['role'] as String),
        orElse: () => UserRole.viewer,
      ),
      permissions: permissionsList,
    );
  }

  Map<String, dynamic> _convertFromUserAccount(UserAccount user) {
    return {
      'id': user.id,
      'email': user.email,
      'role': user.role.toString().split('.').last,
      'permissions': user.permissions
          .map((p) => p.toString().split('.').last)
          .toList(),
    };
  }
}