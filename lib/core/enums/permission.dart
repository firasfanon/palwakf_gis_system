/// Fine-grained permissions per system.
///
/// Must stay aligned with DB values in user_system_permissions.permission_key.
enum Permission {
  // generic CRUD
  read,
  create,
  update,
  delete,

  // reporting
  viewReports,

  // platform admin
  manageUsers,
  manageHome,
  manageSite,

  // GIS / explorer
  manageMapLayers,
  manageLandsCrud,

  // data IO
  importData,
  exportData,
}
