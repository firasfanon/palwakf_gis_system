import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../../../data/models/admin_user.dart';
import '../../../../core/access/access_profile.dart';
import '../../../../core/enums/enums.dart' as rbac;

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthState {
  final AdminUser? user;
  final AccessProfile? access;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.access,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AdminUser? user,
    AccessProfile? access,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      access: access ?? this.access,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _init();
  }

  void _init() {
    _repository.authStateChanges.listen(
      (session) {
        state = state.copyWith(
          user: session?.user,
          access: session?.access,
          isLoading: false,
          error: null,
        );
      },
      onError: (e, _) {
        state = state.copyWith(
          user: null,
          access: null,
          isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''),
        );
      },
    );
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _repository.signIn(email, password);
      state = state.copyWith(
        user: session.user,
        access: session.access,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState();
  }

  /// Permission check against the MUSTAKSHIF system.
  bool can(rbac.Permission permission) {
    final access = state.access;
    if (access == null) return false;
    return access.can(rbac.SystemKey.mustakshif, permission);
  }

  /// Role check against the MUSTAKSHIF system.
  bool hasRoleAtLeast(rbac.UserRole role) {
    final access = state.access;
    if (access == null) return false;
    return access.hasRoleAtLeast(rbac.SystemKey.mustakshif, role);
  }
}
