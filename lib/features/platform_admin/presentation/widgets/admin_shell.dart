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
          textDirection: TextDirection.ltr,
          children: [
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: child,
              ),
            ),
            _Sidebar(currentPath: GoRouterState.of(context).uri.path),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatefulWidget {
  final String currentPath;
  const _Sidebar({required this.currentPath});

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  bool _showDeveloperMetadata = false;

  static const _groups = [
    _AdminNavGroup(
      title: 'المنصة',
      icon: Icons.admin_panel_settings_outlined,
      items: [
        _AdminNavSpec(
          icon: Icons.dashboard,
          label: 'لوحة المتابعة',
          path: '/admin/dashboard',
          pageName: 'AdminDashboardPage',
        ),
        _AdminNavSpec(
          icon: Icons.people,
          label: 'إدارة المستخدمين',
          path: '/admin/users',
          pageName: 'AdminUsersPage',
        ),
      ],
    ),
    _AdminNavGroup(
      title: 'المستكشف',
      icon: Icons.travel_explore_outlined,
      items: [
        _AdminNavSpec(
          icon: Icons.travel_explore_outlined,
          label: 'صفحات المستكشف',
          path: '/admin/explorer-suite',
          pageName: 'ExplorerSuiteAdminPage',
        ),
        _AdminNavSpec(
          icon: Icons.psychology_alt_outlined,
          label: 'المستكشف الذكي داخل المستكشف',
          path: '/admin/explorer-suite/smart',
          pageName: 'EmbeddedSmartExplorerPage',
        ),
        _AdminNavSpec(
          icon: Icons.menu_book_outlined,
          label: 'قراءة الخريطة والكارتوغرافيا',
          path: '/admin/explorer-suite/cartography',
          pageName: 'ExplorerCartographicReadingPage',
        ),
        _AdminNavSpec(
          icon: Icons.task_alt_outlined,
          label: 'مركز خدمات المستكشف',
          path: '/admin/explorer-suite/operations',
          pageName: 'ExplorerUnifiedOperationalClosurePage',
        ),
        _AdminNavSpec(
          icon: Icons.fact_check_outlined,
          label: 'مراجعة فجوات المستكشف',
          path: '/admin/explorer-gap-audits',
          pageName: 'ExplorerGapAuditsAdminPage',
        ),
        _AdminNavSpec(
          icon: Icons.manage_search_outlined,
          label: 'لوحة مراجعة المستكشف',
          path: '/admin/mustakshif/review-board',
          pageName: 'MustakshifReviewBoardPage',
        ),
        _AdminNavSpec(
          icon: Icons.map_outlined,
          label: 'خريطة مراجعة المستكشف',
          path: '/admin/mustakshif/review-map',
          pageName: 'MustakshifReviewMapPage',
        ),
        _AdminNavSpec(
          icon: Icons.task_alt,
          label: 'مهام التدقيق',
          path: '/admin/audit-tasks',
          pageName: 'AuditTasksAdminPage',
        ),
      ],
    ),
    _AdminNavGroup(
      title: 'الخريطة و GIS',
      icon: Icons.layers_outlined,
      items: [
        _AdminNavSpec(
          icon: Icons.layers,
          label: 'إدارة طبقات GIS',
          path: '/admin/gis-layers',
          pageName: 'GisLayersAdminPage',
        ),
        _AdminNavSpec(
          icon: Icons.tune,
          label: 'إعدادات طبقات الخريطة',
          path: '/admin/map-layer-manager',
          pageName: 'MapLayerManagerPage',
        ),
        _AdminNavSpec(
          icon: Icons.map_outlined,
          label: 'طبقات الشاشة الرئيسية',
          path: '/admin/map-runtime-layers',
          pageName: 'MapRuntimeLayersAdminPage',
        ),
      ],
    ),
    _AdminNavGroup(
      title: 'المستكشف الذكي',
      icon: Icons.psychology_alt_outlined,
      items: [
        _AdminNavSpec(
          icon: Icons.psychology_alt_outlined,
          label: 'المستكشف الذكي',
          path: '/admin/explorer-suite/smart',
          pageName: 'EmbeddedSmartExplorerPage',
        ),
      ],
    ),
    _AdminNavGroup(
      title: 'التاريخ والتقسيمات',
      icon: Icons.account_tree_outlined,
      items: [
        _AdminNavSpec(
          icon: Icons.account_tree,
          label: 'العلاقات التاريخية',
          path: '/admin/history-topology',
          pageName: 'AdminHistoryTopologyPage',
        ),
        _AdminNavSpec(
          icon: Icons.route_outlined,
          label: 'التقسيمات التاريخية',
          path: '/admin/historical-admin-divisions',
          pageName: 'HistoricalAdminDivisionsAdminPage',
        ),
        _AdminNavSpec(
          icon: Icons.edit_note,
          label: 'CRUD الجداول التاريخية',
          path: '/admin/history-crud',
          pageName: 'HistoryCrudAdminPage',
        ),
        _AdminNavSpec(
          icon: Icons.palette_outlined,
          label: 'أنماط الطبقات التاريخية',
          path: '/admin/history-styles',
          pageName: 'HistoryStylesAdminPage',
        ),
        _AdminNavSpec(
          icon: Icons.map_outlined,
          label: 'الخريطة التاريخية',
          path: '/admin/history-map',
          pageName: 'HistoryMapPage',
        ),
      ],
    ),
    _AdminNavGroup(
      title: 'الوقف',
      icon: Icons.domain_outlined,
      items: [
        _AdminNavSpec(
          icon: Icons.domain_outlined,
          label: 'مرجع الوقف',
          path: '/admin/waqf',
          pageName: 'AdminWaqfPage',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: PwfColors.primaryBlue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: PwfColors.primaryGold,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'لوحة التحكم',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DeveloperSection(
            showDeveloperMetadata: _showDeveloperMetadata,
            onChanged: (value) {
              setState(() => _showDeveloperMetadata = value);
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final group in _groups)
                  _NavGroupTile(
                    group: group,
                    currentPath: widget.currentPath,
                    showDeveloperMetadata: _showDeveloperMetadata,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'PalWakf • Standalone',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeveloperSection extends StatelessWidget {
  final bool showDeveloperMetadata;
  final ValueChanged<bool> onChanged;

  const _DeveloperSection({
    required this.showDeveloperMetadata,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ExpansionTile(
        initiallyExpanded: showDeveloperMetadata,
        iconColor: PwfColors.primaryGold,
        collapsedIconColor: Colors.white54,
        leading: const Icon(
          Icons.code_outlined,
          color: PwfColors.primaryGold,
          size: 20,
        ),
        title: const Text(
          'المطور',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: showDeveloperMetadata,
            activeThumbColor: PwfColors.primaryGold,
            onChanged: onChanged,
            title: const Text(
              'إظهار أسماء الصفحات ومساراتها',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            subtitle: Text(
              'يعرض Page وRoute تحت عناصر السايدبار لتسهيل التطوير.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavGroupTile extends StatelessWidget {
  final _AdminNavGroup group;
  final String currentPath;
  final bool showDeveloperMetadata;

  const _NavGroupTile({
    required this.group,
    required this.currentPath,
    required this.showDeveloperMetadata,
  });

  @override
  Widget build(BuildContext context) {
    final isGroupActive = group.items.any((item) => item.matches(currentPath));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isGroupActive
            ? PwfColors.primaryBlue.withValues(alpha: 0.12)
            : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGroupActive
              ? PwfColors.primaryBlue.withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: isGroupActive,
        iconColor: PwfColors.primaryGold,
        collapsedIconColor: Colors.white54,
        leading: Icon(
          group.icon,
          color: isGroupActive ? PwfColors.primaryGold : Colors.white70,
          size: 20,
        ),
        title: Text(
          group.title,
          style: TextStyle(
            color: isGroupActive ? PwfColors.primaryGold : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        children: [
          for (final item in group.items)
            _NavItem(
              spec: item,
              currentPath: currentPath,
              showDeveloperMetadata: showDeveloperMetadata,
            ),
        ],
      ),
    );
  }
}

class _AdminNavGroup {
  final String title;
  final IconData icon;
  final List<_AdminNavSpec> items;

  const _AdminNavGroup({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class _AdminNavSpec {
  final IconData icon;
  final String label;
  final String path;
  final String pageName;

  const _AdminNavSpec({
    required this.icon,
    required this.label,
    required this.path,
    required this.pageName,
  });

  bool matches(String currentPath) {
    return currentPath == path || currentPath.startsWith('$path/');
  }
}

class _NavItem extends StatelessWidget {
  final _AdminNavSpec spec;
  final String currentPath;
  final bool showDeveloperMetadata;

  const _NavItem({
    required this.spec,
    required this.currentPath,
    required this.showDeveloperMetadata,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = spec.matches(currentPath);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive
            ? PwfColors.primaryBlue.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? PwfColors.primaryBlue
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          spec.icon,
          color: isActive ? PwfColors.primaryGold : Colors.white70,
        ),
        title: Text(
          spec.label,
          style: TextStyle(
            color: isActive ? PwfColors.primaryGold : Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
        subtitle: showDeveloperMetadata
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Page: ${spec.pageName}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 10.5,
                      ),
                    ),
                    Text(
                      'Route: ${spec.path}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              )
            : null,
        trailing: const Icon(Icons.chevron_left, color: Colors.white54),
        onTap: () => context.go(spec.path),
      ),
    );
  }
}
