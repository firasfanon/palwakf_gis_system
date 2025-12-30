import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/admin/domain/user_account.dart';

// ✅ Current User Notifier (Riverpod 2.x)
class CurrentUserNotifier extends Notifier<UserAccount?> {
  @override
  UserAccount? build() {
    return null;
  }

  void setUser(UserAccount? user) {
    state = user;
  }

  void logout() {
    state = null;
  }
}

// ✅ Current User Provider
final currentUserProvider = NotifierProvider<CurrentUserNotifier, UserAccount?>(() {
  return CurrentUserNotifier();
});

// Permission checking functions
bool hasPermission(UserAccount? user, String permission) {
  if (user == null) return false;

  switch (user.role) {
    case UserRole.superuser:
      return true;
    case UserRole.admin:
      return permission != 'delete_system';
    case UserRole.user:
      return permission == 'view' || permission == 'edit_own';
    case UserRole.viewer:
      return permission == 'view';
    default:
      return false;
  }
}

// Role checking
bool hasRole(UserAccount? user, UserRole role) {
  return user?.role == role;
}

// Admin check
bool isAdmin(UserAccount? user) {
  return user?.role == UserRole.admin || user?.role == UserRole.superuser;
}

// Superuser check
bool isSuperuser(UserAccount? user) {
  return user?.role == UserRole.superuser;
}