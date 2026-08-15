// ============================================
// 14. INVESTMENT SERVICES PAGE
// ============================================

// lib/features/investment/presentation/pages/investment_services_page.dart
import 'package:flutter/material.dart';

class InvestmentServicesPage extends StatelessWidget {
  const InvestmentServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خدمات الاستثمار الوقفي'),
      ),
      body: const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Text('صفحة خدمات الاستثمار الوقفي'),
        ),
      ),
    );
  }
}
