import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مستكشف الوقف — الصفحة الرئيسة')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('مرحباً بكم في مستكشف الوقف', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ElevatedButton(onPressed: () => context.go('/map'), child: const Text('الخريطة')),
              ElevatedButton(onPressed: () => context.go('/laws'), child: const Text('التشريعات')),
              ElevatedButton(onPressed: () => context.go('/about'), child: const Text('حول')),
              ElevatedButton(onPressed: () => context.go('/contact'), child: const Text('تواصل معنا')),
              ElevatedButton(onPressed: () => context.go('/admin'), child: const Text('لوحة التحكم')),
            ]),
          ],
        ),
      ),
    );
  }
}
