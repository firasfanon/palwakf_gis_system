// lib/features/platform_admin/presentation/providers/admin_users_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/enums.dart' as rbac;
import '../../../../data/models/admin_user.dart';
import '../../data/repositories/admin_users_repository.dart';

class AdminUserRowView {
  final AdminUser user;
  final String? platformAdminRole;
  final Set<rbac.Permission> platformAdminPermissions;

  const AdminUserRowView({
    required this.user,
    required this.platformAdminRole,
    required this.platformAdminPermissions,
  });
}

final adminUsersQueryProvider = StateProvider<String>((ref) => '');

final adminUsersRowsProvider =
    FutureProvider<List<AdminUserRowView>>((ref) async {
  final query = ref.watch(adminUsersQueryProvider);
  final repo = ref.watch(adminUsersRepositoryProvider);

  final users = await repo.fetchAdminUsers(query: query);
  final ids = users.map((u) => u.id).where((e) => e.isNotEmpty).toList();

  final roles = await repo.fetchSystemRoles(
    systemKey: rbac.SystemKey.platformAdmin,
    userIds: ids,
  );

  final perms = await repo.fetchSystemPermissions(
    systemKey: rbac.SystemKey.platformAdmin,
    userIds: ids,
  );

  return users
      .map(
        (u) => AdminUserRowView(
          user: u,
          platformAdminRole: roles[u.id],
          platformAdminPermissions: perms[u.id] ?? const <rbac.Permission>{},
        ),
      )
      .toList();
});
