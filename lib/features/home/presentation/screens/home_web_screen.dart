import 'package:flutter/material.dart';

import '../../../widgets/web/web_container.dart';

import '../widgets/home_hero_section.dart';
import '../widgets/home_stats_section.dart';
import '../widgets/home_news_section.dart';
import '../widgets/home_services_section.dart';

class HomeWebScreen extends StatelessWidget {
  const HomeWebScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ملاحظة: الهيدر/الفوتر يتم حقنهما عبر ShellRoute (WebPageScaffold)
    // لذلك هذه الشاشة تعرض المحتوى فقط.
    return SingleChildScrollView(
      child: Column(
        children: [
          HomeHeroSection(),
          const SizedBox(height: 24),
          WebContainer(child: const HomeStatsSection()),
          const SizedBox(height: 24),
          WebContainer(child: const HomeNewsSection()),
          const SizedBox(height: 24),
          WebContainer(child: const HomeServicesSection()),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
