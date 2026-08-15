import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: Row(
          children: [
            Expanded(child: child),
            _AdminSidebar(currentPath: GoRouterState.of(context).uri.path),
          ],
        ),
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final String currentPath;
  const _AdminSidebar({required this.currentPath});

  bool _isActive(String path) => currentPath == path;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border(
            left: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: PwfColors.primaryBlue.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.admin_panel_settings, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'لوحة التحكم',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _NavItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            active: _isActive('/admin/dashboard'),
            onTap: () => context.go('/admin/dashboard'),
          ),
          _NavItem(
            icon: Icons.people_alt,
            label: 'المستخدمون',
            active: _isActive('/admin/users'),
            onTap: () => context.go('/admin/users'),
          ),
          _NavItem(
            icon: Icons.layers,
            label: 'طبقات GIS',
            active: _isActive('/admin/gis-layers'),
            onTap: () => context.go('/admin/gis-layers'),
          ),
          const Spacer(),
          _NavItem(
            icon: Icons.map,
            label: 'العودة للمستكشف',
            active: false,
            onTap: () => context.go('/map'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? PwfColors.primaryBlue.withValues(alpha: 0.18)
        : Colors.transparent;
    final border = active
        ? PwfColors.primaryBlue.withValues(alpha: 0.60)
        : Colors.white.withValues(alpha: 0.08);
    final fg = active ? PwfColors.primaryGold : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: ListTile(
        leading: Icon(icon, color: fg),
        title: Text(label,
            style: TextStyle(
                color: fg,
                fontWeight: active ? FontWeight.bold : FontWeight.w500)),
        trailing: const Icon(Icons.chevron_left, color: Colors.white54),
        onTap: onTap,
        dense: true,
      ),
    );
  }
}
