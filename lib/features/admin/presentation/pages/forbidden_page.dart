import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';

class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: PwfColors.royalRed.withValues(alpha: 0.35)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, size: 54, color: PwfColors.royalRed),
                const SizedBox(height: 12),
                const Text(
                  'لا تملك صلاحية للوصول',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'تحقق من صلاحيات RBAC للنظام platformAdmin أو سجّل الدخول بحساب مخوّل.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/admin/login'),
                      icon: const Icon(Icons.login),
                      label: const Text('تسجيل الدخول'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/map'),
                      icon: const Icon(Icons.map),
                      label: const Text('العودة للمستكشف'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
