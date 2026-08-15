import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';

class AdminScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final String activeRoute;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.activeRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: PwfColors.primaryBlue,
          foregroundColor: Colors.white,
          title: Text(title),
        ),
        body: Row(
          children: [
            _AdminSidebar(activeRoute: activeRoute),
            Expanded(
              child: Container(
                color: const Color(0xFF0B1220),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final String activeRoute;
  const _AdminSidebar({required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF111827),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.dashboard, color: Colors.white70),
                SizedBox(width: 10),
                Text('لوحة التحكم',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          _NavTile(
            title: 'Dashboard',
            icon: Icons.grid_view_rounded,
            route: '/admin/dashboard',
            activeRoute: activeRoute,
          ),
          _NavTile(
            title: 'الطبقات (GIS)',
            icon: Icons.layers_outlined,
            route: '/admin/gis-layers',
            activeRoute: activeRoute,
          ),
          _NavTile(
            title: 'المستخدمون',
            icon: Icons.people_alt_outlined,
            route: '/admin/users',
            activeRoute: activeRoute,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
              ),
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.public),
              label: const Text('الموقع العام'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String route;
  final String activeRoute;

  const _NavTile({
    required this.title,
    required this.icon,
    required this.route,
    required this.activeRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activeRoute == route;
    return ListTile(
      leading:
          Icon(icon, color: isActive ? PwfColors.primaryGold : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? PwfColors.primaryGold : Colors.white,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () => context.go(route),
      dense: true,
      selected: isActive,
      selectedTileColor: PwfColors.primaryBlue.withValues(alpha: 0.12),
    );
  }
}
