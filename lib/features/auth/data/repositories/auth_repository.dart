import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/admin_user.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../../presentation/providers/supabase_providers.dart';
import '../../../../core/access/access_repository.dart';
import '../../../../core/access/access_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final accessRepo = AccessRepository(supabaseService);
  return AuthRepository(supabaseService, accessRepo);
});

class AuthSession {
  final AdminUser user;
  final AccessProfile? access;
  const AuthSession({required this.user, required this.access});
}

class AuthRepository {
  final SupabaseService _supabase;
  final AccessRepository _accessRepo;

  AuthRepository(this._supabase, this._accessRepo);

  Stream<AuthSession?> get authStateChanges {
    return _supabase.authStateChanges.asyncMap((authState) async {
      final session = authState.session;
      if (session == null) return null;

      final userId = session.user.id;

      // admin_users is the single identity source
      final row = await _supabase.client
          .from('admin_users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (row == null) {
        await _supabase.client.auth.signOut();
        throw Exception('هذا الحساب غير مُسجّل ضمن admin_users.');
      }

      final adminUser = AdminUser.fromJson(Map<String, dynamic>.from(row));
      if (!adminUser.isActive) {
        await _supabase.client.auth.signOut();
        throw Exception('هذا الحساب غير نشط. يرجى التواصل مع المسؤول');
      }

      final access = await _accessRepo.load(userId);
      return AuthSession(user: adminUser, access: access);
    });
  }

  Future<AuthSession> signIn(String email, String password) async {
    final response = await _supabase.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('فشل تسجيل الدخول');
    }

    final row = await _supabase.client
        .from('admin_users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) {
      await _supabase.client.auth.signOut();
      throw Exception('هذا الحساب غير مُسجّل ضمن admin_users.');
    }

    final adminUser = AdminUser.fromJson(Map<String, dynamic>.from(row));
    if (!adminUser.isActive) {
      await _supabase.client.auth.signOut();
      throw Exception('هذا الحساب غير نشط. يرجى التواصل مع المسؤول');
    }

    final access = await _accessRepo.load(user.id);
    return AuthSession(user: adminUser, access: access);
  }

  Future<void> signOut() async {
    await _supabase.client.auth.signOut();
    _accessRepo.clearCache();
  }
}
