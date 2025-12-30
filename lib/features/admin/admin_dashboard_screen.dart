import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('لوحة التحكم')),
        body: Row(
          children: [
            _SideNav(),
            const VerticalDivider(width: 1),
            const Expanded(child: Center(child: Text('اختر قسم الإدارة من القائمة الجانبية.'))),
          ],
        ),
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF0A3D62).withValues(alpha: .06),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _item(context, Icons.group, 'إدارة المستخدمين', '/admin/users'),
          _item(context, Icons.home, 'إدارة الصفحة الرئيسة', '/admin/home-config'),
          _item(context, Icons.settings, 'إدارة الموقع', '/admin/site-settings'),
          _item(context, Icons.newspaper_outlined, 'أخبار المستكشف', '/admin/mustakshif/news'),
          _item(context, Icons.campaign_outlined, 'إعلانات المستكشف', '/admin/mustakshif/announcements'),

        ],
      ),
    );
  }

  Widget _item(BuildContext ctx, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0A3D62)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
      onTap: () => ctx.go(route),
    );
  }
}
