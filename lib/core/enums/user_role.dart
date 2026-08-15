/// RBAC role per system.
///
/// Must stay aligned with DB values in user_system_roles.role.
enum UserRole {
  viewer,
  user,
  admin,
  superuser,
}
