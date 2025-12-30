import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF001F3F), // kDeepBlue
      padding: const EdgeInsets.all(24),
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.account_balance, color: Color(0xFFD4AF37), size: 36), // kGold
                      SizedBox(height: 8),
                      Text(
                          'منصة وطنية تفاعلية لاستعراض الأراضي الوقفية في فلسطين وربط التاريخ بالجغرافيا والوقف الشرعي.',
                          style: TextStyle(color: Colors.white70)
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('روابط سريعة', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)), // kGold
                      SizedBox(height: 8),
                      Text('الرئيسية', style: TextStyle(color: Colors.white70)),
                      Text('الخريطة التفاعلية', style: TextStyle(color: Colors.white70)),
                      Text('التاريخ الإداري', style: TextStyle(color: Colors.white70)),
                      Text('التشريعات', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('تواصل معنا', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)), // kGold
                      SizedBox(height: 8),
                      Text('وزارة الأوقاف والشؤون الدينية الفلسطينية – رام الله', style: TextStyle(color: Colors.white70)),
                      Text('الهاتف: +970 2 2944000', style: TextStyle(color: Colors.white70)),
                      Text('البريد: info@waqf.ps', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
                child: Text(
                    '© 2025 وزارة الأوقاف والشؤون الدينية الفلسطينية',
                    style: TextStyle(color: Colors.white54, fontSize: 12)
                )
            ),
          ],
        ),
      ),
    );
  }
}