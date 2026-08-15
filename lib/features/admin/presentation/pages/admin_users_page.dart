import 'package:flutter/material.dart';

import '../widgets/admin_scaffold.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminScaffold(
      title: 'المستخدمون',
      activeRoute: '/admin/users',
      child: Center(
        child: Text(
          'صفحة المستخدمين (Placeholder) — سيتم ربطها لاحقًا بـ admin_users + RBAC.',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
