// lib/features/admin/domain/permissions.dart

enum Permission {
  manageUsers,
  manageHome,
  manageSite,
  manageMapLayers,
  manageLandsCrud,
  viewReports,
  manageNews,
  manageMosques,
  manageServices,
  manageMustakshifContent, // NEW
}

extension PermissionExtension on Permission {
  String get displayName {
    switch (this) {
      case Permission.manageUsers:
        return 'إدارة المستخدمين';
      case Permission.manageHome:
        return 'إدارة الصفحة الرئيسية';
      case Permission.manageSite:
        return 'إدارة إعدادات الموقع';
      case Permission.manageMapLayers:
        return 'إدارة طبقات الخريطة';
      case Permission.manageLandsCrud:
        return 'إدارة الأراضي والأوقاف';
      case Permission.viewReports:
        return 'عرض التقارير';
      case Permission.manageNews:
        return 'إدارة الأخبار';
      case Permission.manageMosques:
        return 'إدارة المساجد';
      case Permission.manageServices:
        return 'إدارة الخدمات';
      case Permission.manageMustakshifContent:
        return 'إدارة أخبار وإعلانات المستكشف';
    }
  }

  String get description {
    switch (this) {
      case Permission.manageUsers:
        return 'إضافة وتعديل وحذف المستخدمين';
      case Permission.manageHome:
        return 'تعديل محتوى الصفحة الرئيسية';
      case Permission.manageSite:
        return 'تعديل إعدادات الموقع العامة';
      case Permission.manageMapLayers:
        return 'إضافة وتعديل طبقات الخريطة';
      case Permission.manageLandsCrud:
        return 'إدارة بيانات الأراضي الوقفية';
      case Permission.viewReports:
        return 'عرض التقارير والإحصائيات';
      case Permission.manageNews:
        return 'نشر وتعديل الأخبار';
      case Permission.manageMosques:
        return 'إدارة بيانات المساجد';
      case Permission.manageServices:
        return 'إدارة الخدمات المقدمة';
      case Permission.manageMustakshifContent:
        return 'إدارة أخبار وإعلانات المستكشف';
    }
  }
}