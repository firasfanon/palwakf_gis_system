import '../../../../core/enums/enums.dart';
import '../../../../data/models/admin_user.dart';

/// A lightweight view model for Admin Users management.
///
/// - [platformAdminRole] comes from public.user_system_roles (system_key=platformAdmin)
/// - [platformAdminPermissions] comes from public.user_system_permissions
class AdminUserGrants {
  final AdminUser user;
  final UserRole? platformAdminRole;
  final Set<Permission> platformAdminPermissions;

  const AdminUserGrants({
    required this.user,
    required this.platformAdminRole,
    required this.platformAdminPermissions,
  });
}
