// lib/core/constants/enums.dart
import 'package:flutter/material.dart';

enum SystemKey {
  palWakf,
  waqfExplorer,
  investmentPortal,
}

enum PlatformRole {
  public,
  viewer,
  researcher,
  editor,
  admin,
  superuser,
}

enum PermissionKey {
  viewPublicMap,
  viewSensitiveData,
  viewDocuments,
  createInquiry,
  editWaqf,
  manageUsers,
  manageLayers,
  auditLogs,
  exportData,
  importData,
}

enum WaqfType {
  land('أرض وقفية', 'Waqf Land'),
  building('عقار وقفي', 'Waqf Property'),
  agricultural('أرض زراعية وقفية', 'Agricultural Waqf'),
  mixed('وقف مشترك', 'Mixed Waqf');

  final String arLabel;
  final String enLabel;
  const WaqfType(this.arLabel, this.enLabel);
}

enum WaqfStatus {
  active('نشط', 'Active', Color(0xFF059669)),
  leased('مؤجر', 'Leased', Color(0xFF2563EB)),
  investment('استثمار', 'Investment', Color(0xFFD97706)),
  disputed('متنازع', 'Disputed', Color(0xFFB22222)),
  inactive('غير نشط', 'Inactive', Color(0xFF6B7280));

  final String arLabel;
  final String enLabel;
  final Color color;
  const WaqfStatus(this.arLabel, this.enLabel, this.color);
}

enum LayerCategory {
  waqf('الأوقاف', 'Waqf'),
  core('أساسية', 'Core'),
  gis('GIS', 'GIS'),
  historical('تاريخية', 'Historical');

  final String arLabel;
  final String enLabel;
  const LayerCategory(this.arLabel, this.enLabel);
}
