import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/pages/login_page.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    final target = (from != null && from.trim().isNotEmpty)
        ? Uri.decodeComponent(from)
        : '/admin/dashboard';

    return const LoginPage();
  }
}
