import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

/// Wraps all admin pages with:
/// - RTL direction
/// - Admin theme (inputs/buttons/cards)
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: AdminTheme.light(base),
        child: child,
      ),
    );
  }
}
