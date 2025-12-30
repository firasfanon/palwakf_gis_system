// lib/app/security/access_guard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Widget لحماية الصفحات بناءً على الأدوار والصلاحيات
class AccessGuard extends ConsumerWidget {
  const AccessGuard({
    super.key,
    required this.child,
    this.requiredRole,
    this.requiredPermission,
  });

  final Widget child;
  final String? requiredRole; // ✅ String بدلاً من UserRole
  final String? requiredPermission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: استبدل هذا بنظام المصادقة الفعلي
    // يمكنك استخدام:
    // final currentUser = ref.watch(currentUserProvider);
    // final hasAccess = checkUserAccess(currentUser, requiredRole, requiredPermission);

    // مؤقتاً: السماح بالوصول للجميع أثناء التطوير
    final hasAccess = true;

    if (!hasAccess) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'ليس لديك صلاحية للوصول إلى هذه الصفحة',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('العودة للصفحة الرئيسية'),
              ),
            ],
          ),
        ),
      );
    }

    return child;
  }
}

/// Helper function للتحقق من الصلاحيات
bool hasPermission(dynamic user, String permission) {
  // TODO: استبدل هذا بمنطق التحقق من الصلاحيات الفعلي
  return true;
}

/// Provider مؤقت للمستخدم الحالي
final currentUserProvider = Provider<dynamic>((ref) {
  // TODO: استبدل هذا بـ Provider الفعلي
  return null;
});