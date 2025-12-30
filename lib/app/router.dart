// lib/app/router.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/about/about_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/home_config/presentation/admin_home_config_screen.dart';
import '../features/admin/users/presentation/admin_users_screen.dart';
import '../features/admin/presentation/widgets/admin_shell.dart';
import '../features/authentication/login_screen.dart';
import '../features/contact/contact_screen.dart';
import '../features/gis/gis_screen.dart';
import '../features/history/domain/models/history_admin_models.dart';
import '../features/history/presentation/screens/history_admin_unit_edit_screen.dart';
import '../features/history/presentation/screens/history_admin_units_list_screen.dart';
import '../features/lands/presentation/screens/land_details_screen.dart';
import '../features/lands/presentation/screens/land_edit_screen.dart';
import '../features/lands/presentation/screens/lands_list_screen.dart';
import '../features/legislation/legislation_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/presentation/screens/home_web_screen.dart';
import '../presentation/screens/admin/general_settings_screen.dart';
import 'security/access_guard.dart';

// Web shell (Header + Footer) for public routes.
import '../features/widgets/web/web_page_scaffold.dart';

// Mustakshif content
import '../features/mustakshif_content/domain/enums/mustakshif_content_type.dart';
import '../features/mustakshif_content/presentation/screens/admin_mustakshif_content_edit_screen.dart';
import '../features/mustakshif_content/presentation/screens/admin_mustakshif_content_list_screen.dart';
import '../features/mustakshif_content/presentation/screens/mustakshif_content_details_screen.dart';
import '../features/mustakshif_content/presentation/screens/mustakshif_content_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'خطأ في التوجيه:\n${state.error}',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
      ),
    ),
  ),
  routes: [
    /// ✅ Public routes are wrapped with a ShellRoute on Web only.
    /// This guarantees Header + Footer for every public page, including new ones.
    ShellRoute(
      builder: (context, state, child) {
        if (!kIsWeb) return child;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: WebPageScaffold(
            scrollable: false,
            padding: EdgeInsets.zero,
            child: child,
          ),
        );
      },
      routes: [
        // ✅ Route واحد فقط للجذر "/" (بدون تكرار)
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => kIsWeb ? const HomeWebScreen() : const HomeScreen(),
        ),

        GoRoute(
          path: '/gis',
          name: 'gis',
          builder: (context, state) => const GisScreen(),
        ),
        GoRoute(
          path: '/map',
          name: 'map',
          builder: (context, state) => const GisScreen(),
        ),

        GoRoute(
          path: '/legislation',
          name: 'legislation',
          builder: (context, state) => const LegislationScreen(),
        ),
        GoRoute(
          path: '/about',
          name: 'about',
          builder: (context, state) => const AboutScreen(),
        ),
        GoRoute(
          path: '/contact',
          name: 'contact',
          builder: (context, state) => const ContactScreen(),
        ),

        // Public Mustakshif content
        GoRoute(
          path: '/mustakshif/news',
          name: 'mustakshif-news',
          redirect: (_, __) => '/mustakshif/content?tab=news',
        ),
        GoRoute(
          path: '/mustakshif/announcements',
          name: 'mustakshif-announcements',
          redirect: (_, __) => '/mustakshif/content?tab=announcements',
        ),

        GoRoute(
          path: '/mustakshif/content',
          name: 'mustakshif-content',
          builder: (context, state) {
            final tab = state.uri.queryParameters['tab'] ?? 'news';
            final periodIdStr = state.uri.queryParameters['periodId'];
            final periodId = int.tryParse(periodIdStr ?? '');
            final initialType = tab == 'announcements'
                ? MustakshifContentType.announcements
                : MustakshifContentType.news;

            return MustakshifContentScreen(
              initialType: initialType,
              historicalPeriodId: periodId,
            );
          },
        ),

        GoRoute(
          path: '/mustakshif/content/:type/:id',
          name: 'mustakshif-content-details',
          builder: (context, state) {
            final typeStr = state.pathParameters['type'] ?? 'news';
            final type = typeStr == 'announcements'
                ? MustakshifContentType.announcements
                : MustakshifContentType.news;
            final id = state.pathParameters['id'] ?? '';

            return MustakshifContentDetailsScreen(type: type, id: id);
          },
        ),
      ],
    ),

    // Auth routes (outside Shell)
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),

    // Admin routes (RTL + Admin theme)
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/admin',
          name: 'admin-dashboard',
          builder: (context, state) => AccessGuard(
            requiredRole: 'admin',
            child: const AdminDashboardScreen(),
          ),
        ),
    
        GoRoute(
          path: '/admin/users',
          name: 'admin-users',
          builder: (context, state) => AccessGuard(
            requiredPermission: 'manageUsers',
            child: const AdminUsersScreen(),
          ),
        ),
    
        GoRoute(
          path: '/admin/home-config',
          name: 'admin-home-config',
          builder: (context, state) => AccessGuard(
            requiredPermission: 'manageHome',
            child: const AdminHomeConfigScreen(),
          ),
        ),
    
        GoRoute(
          path: '/admin/lands',
          name: 'admin-lands',
          builder: (context, state) => AccessGuard(
            requiredPermission: 'manageLandsCrud',
            child: const LandsListScreen(),
          ),
        ),
    
        GoRoute(
          path: '/admin/lands/new',
          name: 'admin-land-new',
          builder: (context, state) => AccessGuard(
            requiredPermission: 'manageLandsCrud',
            child: LandEditScreen.newLand(),
          ),
        ),
    
        GoRoute(
          path: '/admin/lands/:id',
          name: 'admin-land-details',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return AccessGuard(
              requiredPermission: 'manageLandsCrud',
              child: LandDetailsScreen(id: id),
            );
          },
        ),
    
        GoRoute(
          path: '/admin/lands/:id/edit',
          name: 'admin-land-edit',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return AccessGuard(
              requiredPermission: 'manageLandsCrud',
              child: LandEditScreen.edit(id: id),
            );
          },
        ),
    
        GoRoute(
          path: '/admin/history-admin-units',
          name: 'admin-history-admin-units',
          builder: (context, state) => AccessGuard(
            requiredPermission: 'manageMapLayers',
            child: const HistoryAdminUnitsListScreen(),
          ),
        ),
    
        GoRoute(
          path: '/admin/history-admin-units/new',
          name: 'admin-history-admin-unit-new',
          builder: (context, state) {
            final extra = state.extra
            as ({int? periodId, HistoricalAdminLevel? level})?;
            final periodId = extra?.periodId;
            final level = extra?.level;
    
            if (periodId == null || level == null) {
              return AccessGuard(
                requiredPermission: 'manageMapLayers',
                child: const Scaffold(
                  body: Center(
                    child: Text(
                      'يجب اختيار فترة ومستوى لإنشاء وحدة جديدة',
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),
              );
            }
    
            return AccessGuard(
              requiredPermission: 'manageMapLayers',
              child: HistoryAdminUnitEditScreen.newUnit(
                periodId: periodId,
                level: level,
              ),
            );
          },
        ),
    
        GoRoute(
          path: '/admin/history-admin-units/:id/edit',
          name: 'admin-history-admin-unit-edit',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return AccessGuard(
              requiredPermission: 'manageMapLayers',
              child: HistoryAdminUnitEditScreen.edit(id: id),
            );
          },
        ),
    
        // Admin Mustakshif content
        GoRoute(
          path: '/admin/mustakshif/news',
          name: 'admin-mustakshif-news',
          builder: (context, state) => AccessGuard(
            requiredPermission: 'manageMustakshifContent',
            child: const AdminMustakshifContentListScreen(
              type: MustakshifContentType.news,
            ),
          ),
        ),
        GoRoute(
          path: '/admin/mustakshif/announcements',
          name: 'admin-mustakshif-announcements',
          builder: (context, state) => AccessGuard(
            requiredPermission: 'manageMustakshifContent',
            child: const AdminMustakshifContentListScreen(
              type: MustakshifContentType.announcements,
            ),
          ),
        ),
        GoRoute(
          path: '/admin/mustakshif/:type/new',
          name: 'admin-mustakshif-new',
          builder: (context, state) {
            final type = state.pathParameters['type'] == 'announcements'
                ? MustakshifContentType.announcements
                : MustakshifContentType.news;
    
            return AccessGuard(
              requiredPermission: 'manageMustakshifContent',
              child: AdminMustakshifContentEditScreen(type: type),
            );
          },
        ),
        GoRoute(
          path: '/admin/mustakshif/:type/:id/edit',
          name: 'admin-mustakshif-edit',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            final type = state.pathParameters['type'] == 'announcements'
                ? MustakshifContentType.announcements
                : MustakshifContentType.news;
    
            return AccessGuard(
              requiredPermission: 'manageMustakshifContent',
              child: AdminMustakshifContentEditScreen(type: type, id: id),
            );
          },
        ),
    
        GoRoute(
          path: '/admin/settings',
          name: 'admin-settings',
          builder: (context, state) => AccessGuard(
            requiredPermission: 'manageSite',
            child: const GeneralSettingsScreen(),
          ),
        ),
    
        // Backward/alternate route used by the admin dashboard UI.
        // Keep this alias to avoid GoException: no routes for location.
        GoRoute(
          path: '/admin/site-settings',
          name: 'admin-site-settings',
          redirect: (_, __) => '/admin/settings',
        ),
    
      ],
    ),
  ],
);
