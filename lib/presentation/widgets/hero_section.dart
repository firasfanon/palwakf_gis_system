import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF123A7A), Color(0xFF0A2E52)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: ui.TextDirection.rtl,
        children: [
          const Text(
              'اكتشف الأوقاف الفلسطينية\nعبر الخرائط التفاعلية والتشريعات القانونية',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold
              )
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0A3D62), // royalBlue
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: (){},
              child: const Text('استكشف الخريطة'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37), // gold
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: (){},
              child: const Text('تصفح التشريعات'),
            ),
          ]),
        ],
      ),
    );
  }
}