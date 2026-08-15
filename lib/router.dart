// lib/router.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './features/auth/presentation/pages/login_page.dart';
import './features/auth/presentation/providers/auth_provider.dart' as app_auth;
import './features/home/presentation/pages/home_page.dart';
import './features/explorer_suite/presentation/pages/explorer_suite_page.dart';
import './features/explorer_suite/presentation/pages/explorer_cartographic_reading_page.dart';
import './features/explorer_suite/presentation/pages/explorer_unified_operational_closure_page.dart';
import './features/history_explorer/presentation/pages/history_explorer_page.dart';
import './features/history_explorer/presentation/pages/historical_admin_divisions_explorer_page.dart';
import './features/map/presentation/pages/map_page.dart';
import './features/waqf/presentation/pages/waqf_details_page.dart';
import './features/investment/presentation/pages/investment_services_page.dart';

import './core/enums/enums.dart' as rbac;

import './features/platform_admin/presentation/pages/admin_dashboard_page.dart';
import './features/platform_admin/presentation/pages/admin_explorer_gap_audits_page.dart';
import './features/platform_admin/presentation/pages/admin_gis_layers_page.dart';
import './features/platform_admin/presentation/pages/admin_map_layer_manager_page.dart';
import './features/platform_admin/presentation/pages/admin_map_runtime_layers_page.dart';
import './features/platform_admin/presentation/pages/admin_audit_tasks_page.dart';
import './features/platform_admin/presentation/pages/admin_users_page.dart';
import './features/platform_admin/presentation/pages/forbidden_page.dart';
import './features/platform_admin/presentation/pages/historical_topology_admin_page.dart';
import './features/platform_admin/presentation/pages/historical_crud_admin_page.dart';
import './features/platform_admin/presentation/pages/admin_history_map_page.dart';
import './features/platform_admin/presentation/pages/admin_history_styles_page.dart';
import './features/platform_admin/presentation/pages/admin_waqf_reference_page.dart';
import './features/platform_admin/presentation/widgets/admin_shell.dart';
import './features/smart_explorer/presentation/pages/admin_smart_explorer_page.dart';
import './features/mustakshif_review_board/presentation/pwf_mustakshif_review_board_page.dart';


String _redirectToEmbeddedSmartExplorerWithSource(
  GoRouterState state,
  String source,
) {
  final uri = state.uri;
  final query = <String, String>{
    ...uri.queryParameters,
    'source': source,
  };
  return uri.replace(
    path: '/admin/explorer-suite/smart',
    queryParameters: query,
  ).toString();
}


String _redirectToEmbeddedCartographyWithSource(
  GoRouterState state,
  String source,
) {
  final uri = state.uri;
  final query = <String, String>{
    ...uri.queryParameters,
    'source': uri.queryParameters['source'] ?? source,
  };
  return uri.replace(
    path: '/admin/explorer-suite/cartography',
    queryParameters: query,
  ).toString();
}



String _redirectToExplorerOperationsWithSource(
  GoRouterState state,
  String source,
) {
  final uri = state.uri;
  final query = <String, String>{
    ...uri.queryParameters,
    'source': uri.queryParameters['source'] ?? source,
  };
  return uri.replace(
    path: '/admin/explorer-suite/operations',
    queryParameters: query,
  ).toString();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh =
      GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(app_auth.authNotifierProvider);
      final loggedIn = authState.user != null;
      final access = authState.access;
      final path = state.uri.path;

      final isLogin = path == '/login';
      final isAdmin = path.startsWith('/admin');
      final isAdminLogin = path == '/admin/login';

      final roleRaw = (authState.user?.role ?? '').toString().toLowerCase();
      final roleFallback = {
        'super_admin',
        'superadmin',
        'superuser',
        'admin',
      }.contains(roleRaw);

      final canEnterAdmin = (access?.hasRoleAtLeast(
                  rbac.SystemKey.platformAdmin, rbac.UserRole.viewer) ??
              false) ||
          (access?.isSuperuser ?? false) ||
          roleFallback;

      if (loggedIn && isLogin) {
        return canEnterAdmin ? '/admin/dashboard' : '/map';
      }

      if (isAdmin) {
        if (!loggedIn) {
          final from = Uri.encodeComponent(state.uri.toString());
          return '/admin/login?from=$from';
        }

        if (isAdminLogin) {
          return canEnterAdmin ? '/admin/dashboard' : '/forbidden';
        }

        if (!canEnterAdmin) return '/forbidden';
      }

      final protected = <String>{'/investment'};
      if (!loggedIn && protected.contains(path)) return '/login';

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(path: '/explorer', builder: (context, state) => const ExplorerSuitePage()),
      GoRoute(
        path: '/explorer/smart',
        redirect: (context, state) =>
            _redirectToEmbeddedSmartExplorerWithSource(
              state,
              'public_explorer_smart_alias',
            ),
      ),
      GoRoute(
        path: '/explorer/operations',
        redirect: (context, state) =>
            _redirectToExplorerOperationsWithSource(
              state,
              'public_explorer_operations_alias',
            ),
      ),
      GoRoute(
        path: '/explorer/cartography',
        redirect: (context, state) =>
            _redirectToEmbeddedCartographyWithSource(
              state,
              'public_cartography_alias',
            ),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => MapPage.fromQuery(
          queryParameters: state.uri.queryParameters,
        ),
      ),
      GoRoute(path: '/history', builder: (context, state) => const HistoryExplorerPage()),
      GoRoute(
        path: '/history/admin-divisions',
        builder: (context, state) => const HistoricalAdminDivisionsExplorerPage(),
      ),
      GoRoute(
        path: '/map/:id',
        builder: (context, state) => MapPage.fromQuery(
          initialWaqfId: state.pathParameters['id'],
          queryParameters: state.uri.queryParameters,
        ),
      ),
      GoRoute(
        path: '/waqf/:id',
        builder: (context, state) =>
            WaqfDetailsPage(waqfId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/investment',
        builder: (context, state) => const InvestmentServicesPage(),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => const ForbiddenPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: '/admin/explorer-suite',
            builder: (context, state) =>
                const ExplorerSuitePage(embeddedInAdmin: true),
          ),
          GoRoute(
            path: '/admin/explorer-suite/smart',
            builder: (context, state) =>
                const AdminSmartExplorerPage(embeddedInExplorer: true),
          ),
          GoRoute(
            path: '/admin/explorer-suite/operations',
            builder: (context, state) => ExplorerUnifiedOperationalClosurePage(
              embeddedInAdmin: true,
              runtimeContext: state.uri.queryParameters,
            ),
          ),
          GoRoute(
            path: '/admin/explorer-suite/cartography',
            builder: (context, state) => ExplorerCartographicReadingPage(
              embeddedInAdmin: true,
              runtimeContext: state.uri.queryParameters,
            ),
          ),
          GoRoute(
            path: '/admin/gis-layers',
            builder: (context, state) => const AdminGisLayersPage(),
          ),
          GoRoute(
            path: '/admin/map-layer-manager',
            builder: (context, state) => const AdminMapLayerManagerPage(),
          ),
          GoRoute(
            path: '/admin/map-runtime-layers',
            builder: (context, state) => const AdminMapRuntimeLayersPage(),
          ),
          GoRoute(
            path: '/admin/smart-explorer',
            redirect: (context, state) =>
                _redirectToEmbeddedSmartExplorerWithSource(
                  state,
                  'admin_smart_explorer_alias',
                ),
          ),
          GoRoute(
            path: '/admin/mustakshif/review-board',
            builder: (context, state) => PwfMustakshifReviewBoardPage(
              embeddedInAdmin: true,
              initialRecordId: state.uri.queryParameters['record_id'],
            ),
          ),
          GoRoute(
            path: '/admin/mustakshif/review-map',
            builder: (context, state) => MapPage.fromQuery(
              queryParameters: state.uri.queryParameters,
              embeddedInAdmin: true,
            ),
          ),
          GoRoute(
            path: '/admin/explorer-gap-audits',
            builder: (context, state) => const AdminExplorerGapAuditsPage(),
          ),
          GoRoute(
            path: '/admin/audit-tasks',
            builder: (context, state) => const AdminAuditTasksPage(),
          ),
          // Backward/alternate aliases for audit task dashboard links.
          // Keep the canonical route as /admin/audit-tasks.
          GoRoute(
            path: '/admin/tasks',
            redirect: (context, state) => '/admin/audit-tasks',
          ),
          GoRoute(
            path: '/admin/audit-task-requests',
            redirect: (context, state) => '/admin/audit-tasks',
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminUsersPage(),
          ),
          GoRoute(
            path: '/admin/history-topology',
            builder: (context, state) => const HistoricalTopologyAdminPage(),
          ),
          GoRoute(
            path: '/admin/history-crud',
            builder: (context, state) => const HistoricalCrudAdminPage(),
          ),
          GoRoute(
            path: '/admin/history-map',
            builder: (context, state) =>
                AdminHistoryMapPage(query: state.uri.queryParameters),
          ),
          GoRoute(
            path: '/admin/historical-admin-divisions',
            builder: (context, state) => const HistoricalAdminDivisionsExplorerPage(embeddedInAdmin: true),
          ),
          GoRoute(
            path: '/admin/history-styles',
            builder: (context, state) => const AdminHistoryStylesPage(),
          ),
          GoRoute(
            path: '/admin/waqf',
            builder: (context, state) => const AdminWaqfReferencePage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(error: state.error),
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class ErrorPage extends StatelessWidget {
  final Exception? error;
  const ErrorPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Error: ${error?.toString() ?? "Unknown error"}'),
      ),
    );
  }
}
