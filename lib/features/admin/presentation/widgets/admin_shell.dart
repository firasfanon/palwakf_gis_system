import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final path = GoRouter.of(context).routeInformationProvider.value.uri.path;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: Row(
          children: [
            // Content
            Expanded(
              child: SafeArea(
                child: child,
              ),
            ),

            // Sidebar (RTL on right)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                border: Border(
                    left: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  PwfColors.primaryBlue.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Icon(Icons.admin_panel_settings,
                                color: PwfColors.gold),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('لوحة التحكم',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 2),
                                Text('Standalone — Mustakshif',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (auth.user != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          auth.user!.email,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 16),
                    _NavItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      active: path == '/admin/dashboard',
                      onTap: () => context.go('/admin/dashboard'),
                    ),
                    _NavItem(
                      icon: Icons.layers,
                      title: 'طبقات GIS',
                      active: path == '/admin/gis-layers',
                      onTap: () => context.go('/admin/gis-layers'),
                    ),
                    const Spacer(),
                    _NavItem(
                      icon: Icons.map,
                      title: 'العودة إلى الخريطة',
                      active: path == '/map',
                      onTap: () => context.go('/map'),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.16)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                        ),
                        onPressed: () async {
                          await ref
                              .read(authNotifierProvider.notifier)
                              .signOut();
                          if (context.mounted) context.go('/');
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('تسجيل الخروج'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? PwfColors.primaryBlue.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? PwfColors.primaryBlue : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: active ? PwfColors.gold : Colors.white70),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white70,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            const Icon(Icons.chevron_left, size: 18, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
