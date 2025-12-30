import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HeaderNav extends StatelessWidget {
  const HeaderNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A3D62), // kRoyalBlue
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        textDirection: ui.TextDirection.rtl,
        children: [
          const Icon(Icons.account_balance, color: Color(0xFFD4AF37), size: 28), // kGold
          const SizedBox(width: 8),
          const Text('مستكشف الوقف', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(width: 24),
          Wrap(spacing: 12, children: const [
            _NavItem(label: 'الرئيسية', route: '/'),
            _NavItem(label: 'التاريخ الإداري', route: '/history'),
            _NavItem(label: 'الخريطة التفاعلية', route: '/map'),
            _NavItem(label: 'التشريعات', route: '/laws'),
            _NavItem(label: 'حول المشروع', route: '/about'),
            _NavItem(label: 'تواصل معنا', route: '/contact'),
          ]),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0A3D62), // kRoyalBlue
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.login, size: 18),
            label: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final String route;
  const _NavItem({required this.label, required this.route});

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => context.go(route),
    child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
  );
}