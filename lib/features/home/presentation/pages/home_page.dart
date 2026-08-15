// lib/features/home/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/pwf_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _heroImage = 'assets/images/home/hero.jpg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isAuthed = authState.user != null;

    return Scaffold(
      backgroundColor: PwfColors.background,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          slivers: [
            _TopNavBar(
              isAuthed: isAuthed,
              onOpenMap: () => context.go('/map'),
              onOpenExplorer: () => context.go('/explorer'),
              onLogin: () => context.go('/login'),
              onAdmin: () =>
                  context.go(isAuthed ? '/admin/dashboard' : '/login'),
              onToggleTheme: () {},
            ),
            SliverToBoxAdapter(
              child: _HeroSection(
                imagePath: _heroImage,
                onOpenMap: () => context.go('/map'),
                onLearnMore: () => context.go('/explorer'),
              ),
            ),
            SliverToBoxAdapter(
              child: _Section(
                badge: 'لماذا نحن؟',
                title: 'لماذا تختار منصتنا؟',
                subtitle:
                    'الأسباب الرئيسية التي تجعل بوابة فلسطين الجغرافية خيارًا عمليًا لاستكشاف البيانات الجغرافية والعقارية.',
                child: _WhyGrid(),
              ),
            ),
            SliverToBoxAdapter(
              child: _Section(
                badge: 'مشاريعنا',
                title: 'المشاريع وحالات الاستخدام',
                subtitle:
                    'أمثلة على تطبيقات عملية وكيف يمكن للمنصة دعم متخذي القرار في مختلف القطاعات.',
                child: _ProjectsGrid(
                  onOpenMap: () => context.go('/map'),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _StatsBand()),
            SliverToBoxAdapter(
              child: _CTASection(
                isAuthed: isAuthed,
                onOpenMap: () => context.go('/map'),
                onOpenExplorer: () => context.go('/explorer'),
                onLogin: () => context.go('/login'),
              ),
            ),
            SliverToBoxAdapter(child: _Footer()),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ Top Nav ------------------------------ */

class _TopNavBar extends StatelessWidget {
  const _TopNavBar({
    required this.isAuthed,
    required this.onOpenMap,
    required this.onOpenExplorer,
    required this.onLogin,
    required this.onAdmin,
    required this.onToggleTheme,
  });

  final bool isAuthed;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenExplorer;
  final VoidCallback onLogin;
  final VoidCallback onAdmin;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      toolbarHeight: 74,
      elevation: 0,
      backgroundColor: PwfColors.surface,
      surfaceTintColor: PwfColors.surface,
      titleSpacing: 16,
      title: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 1060;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _Brand(),
                  const SizedBox(width: 18),
                  if (wide) ...[
                    _NavItem(label: 'الرئيسية', onTap: () {}),
                    _NavItem(label: 'المستكشف', onTap: onOpenExplorer),
                    _NavItem(label: 'من نحن', onTap: () {}),
                    _NavItem(label: 'الخدمات', onTap: () {}),
                    _NavItem(label: 'المشاريع', onTap: () {}),
                    _NavItem(label: 'الأسئلة الشائعة', onTap: () {}),
                    _NavItem(label: 'اتصل بنا', onTap: () {}),
                  ],
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: onToggleTheme,
                    tooltip: 'الوضع الليلي',
                    icon: const Icon(Icons.dark_mode_outlined,
                        color: PwfColors.onSurface),
                  ),
                  const SizedBox(width: 6),
                  PwfButton(
                    label: 'استكشف الخريطة',
                    icon: Icons.map_outlined,
                    onPressed: onOpenMap,
                  ),
                  const SizedBox(width: 10),
                  if (!isAuthed)
                    OutlinedButton(
                      onPressed: onLogin,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: PwfColors.onSurface.withValues(alpha: 0.14)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      child: const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: PwfColors.onSurface),
                      ),
                    )
                  else
                    OutlinedButton(
                      onPressed: onAdmin,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: PwfColors.onSurface.withValues(alpha: 0.14)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      child: const Text(
                        'لوحة التحكم',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: PwfColors.onSurface),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: PwfColors.royalRed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.public, color: Colors.white),
        ),
        const SizedBox(width: 10),
        const Text(
          'بوابة فلسطين الجغرافية',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: PwfColors.onSurface,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: PwfColors.onSurface.withValues(alpha: 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

/* ------------------------------ HERO ------------------------------ */

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.imagePath,
    required this.onOpenMap,
    required this.onLearnMore,
  });

  final String imagePath;
  final VoidCallback onOpenMap;
  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final heroH = w >= 1100 ? 560.0 : (w >= 720 ? 520.0 : 480.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            SizedBox(
              height: heroH,
              width: double.infinity,
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.62),
                      Colors.black.withValues(alpha: 0.25),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'البوابة الجغرافية لفلسطين',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'خرائط تفاعلية دقيقة بين يديك للوصول السهل إلى المعلومات العقارية والجغرافية.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.7,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            PwfButton(
                              label: 'افتح الخريطة',
                              icon: Icons.map_outlined,
                              onPressed: onOpenMap,
                            ),
                            OutlinedButton.icon(
                              onPressed: onLearnMore,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color:
                                        Colors.white.withValues(alpha: 0.35)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999)),
                              ),
                              icon: const Icon(Icons.info_outline,
                                  color: Colors.white),
                              label: const Text(
                                'تعرّف على الخدمات',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextButton.icon(
                          onPressed: onLearnMore,
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: Colors.white70),
                          label: const Text(
                            'اكتشف المزيد',
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ Section Wrapper ------------------------------ */

class _Section extends StatelessWidget {
  const _Section({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String badge;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: PwfColors.royalRed.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: PwfColors.royalRed.withValues(alpha: 0.25)),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: PwfColors.royalRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: PwfColors.onSurface,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.8,
                color: PwfColors.onSurface.withValues(alpha: 0.70),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ WHY GRID ------------------------------ */

class _WhyGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w >= 1100 ? 4 : (w >= 720 ? 2 : 1);

        const items = [
          _WhyItem(Icons.layers_outlined, 'طبقات متعددة',
              'مجموعة واسعة من الطبقات الجغرافية لمختلف الاستخدامات.'),
          _WhyItem(Icons.search_outlined, 'البحث العقاري',
              'استعلامات دقيقة للوصول السريع إلى القطع والأحواض والمناطق.'),
          _WhyItem(Icons.dashboard_outlined, 'سهولة الاستخدام',
              'واجهة بسيطة وتجربة متناسقة على جميع الأجهزة والمتصفحات.'),
          _WhyItem(Icons.flash_on_outlined, 'السرعة الفائقة',
              'تحميل سريع للخرائط والبيانات مع أداء ممتاز حتى على الأجهزة المحمولة.'),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: cols == 1 ? 1.9 : 1.35,
          ),
          itemBuilder: (context, i) => _WhyCard(data: items[i]),
        );
      },
    );
  }
}

class _WhyItem {
  const _WhyItem(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

class _WhyCard extends StatelessWidget {
  const _WhyCard({required this.data});
  final _WhyItem data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: PwfColors.royalRed.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(data.icon, color: PwfColors.royalRed),
            ),
          ),
          const Spacer(),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.8,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ PROJECTS ------------------------------ */

class _ProjectsGrid extends StatelessWidget {
  const _ProjectsGrid({required this.onOpenMap});
  final VoidCallback onOpenMap;

  static const _projUrban = 'assets/images/home/proj_urban.jpg';
  static const _projInteractive = 'assets/images/home/proj_interactive.jpg';
  static const _projInfra = 'assets/images/home/proj_infra.jpg';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w >= 1100 ? 3 : (w >= 820 ? 2 : 1);

        const items = [
          _ProjectItem(_projInfra, 'تقييم البنية التحتية',
              'مؤشرات مكانية لتحديد أولويات الصيانة والتطوير والاستثمار.'),
          _ProjectItem(_projInteractive, 'الخرائط التفاعلية',
              'عرض وتحليل البيانات المكانية بمرونة داخل واجهة واحدة.'),
          _ProjectItem(_projUrban, 'التخطيط الحضري المستدام',
              'تحليل شبكات الطرق والخدمات لرفع الكفاءة الحضرية.'),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: cols == 1 ? 1.05 : 0.95,
          ),
          itemBuilder: (context, i) => _ProjectCard(
            data: items[i],
            onOpenMap: onOpenMap,
          ),
        );
      },
    );
  }
}

class _ProjectItem {
  const _ProjectItem(this.image, this.title, this.body);
  final String image;
  final String title;
  final String body;
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.data, required this.onOpenMap});
  final _ProjectItem data;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PwfColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PwfColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(data.image, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: PwfColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.body,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.8,
                    color: PwfColors.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: onOpenMap,
                    icon: const Icon(Icons.arrow_back,
                        size: 16, color: PwfColors.royalRed),
                    label: const Text(
                      'اعرف المزيد',
                      style: TextStyle(
                          color: PwfColors.royalRed,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ STATS BAND ------------------------------ */

class _StatsBand extends StatelessWidget {
  static const _bg = 'assets/images/home/stats_bg.jpg';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Image.asset(_bg, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: PwfColors.royalRed.withValues(alpha: 0.85)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: LayoutBuilder(
                builder: (context, c) {
                  final cols =
                      c.maxWidth >= 920 ? 4 : (c.maxWidth >= 620 ? 2 : 1);

                  const items = [
                    _StatItem('24/7', 'وصول متاح دائمًا'),
                    _StatItem('+1,000,000', 'معلم بارز'),
                    _StatItem('+500', 'مدينة وقرية'),
                    _StatItem('+60', 'دراسة مكانية متخصصة'),
                  ];

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 10,
                      childAspectRatio: cols == 1 ? 5.5 : 3.6,
                    ),
                    itemBuilder: (context, i) => _StatBox(items[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  const _StatItem(this.value, this.label);
  final String value;
  final String label;
}

class _StatBox extends StatelessWidget {
  const _StatBox(this.item);
  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ CTA + FOOTER ------------------------------ */

class _CTASection extends StatelessWidget {
  const _CTASection({
    required this.isAuthed,
    required this.onOpenMap,
    required this.onOpenExplorer,
    required this.onLogin,
  });

  final bool isAuthed;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenExplorer;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: PwfColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PwfColors.outline),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final stacked = c.maxWidth < 760;

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'هل أنت جاهز لاستكشاف فلسطين؟',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: PwfColors.onSurface),
                ),
                const SizedBox(height: 10),
                Text(
                  'ابدأ رحلتك مع الخرائط التفاعلية والبيانات العقارية الدقيقة الآن.',
                  style: TextStyle(
                      color: PwfColors.onSurface.withValues(alpha: 0.72),
                      height: 1.6,
                      fontWeight: FontWeight.w600),
                ),
              ],
            );

            final actions = Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                PwfButton(
                  label: 'افتح الخريطة',
                  icon: Icons.map_outlined,
                  onPressed: onOpenMap,
                ),
                OutlinedButton(
                  onPressed: isAuthed ? onOpenExplorer : onLogin,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: PwfColors.onSurface.withValues(alpha: 0.14)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  child: Text(
                    isAuthed ? 'افتح المستكشف' : 'تسجيل الدخول',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: PwfColors.onSurface),
                  ),
                ),
              ],
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  content,
                  const SizedBox(height: 16),
                  Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: actions),
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: content),
                const SizedBox(width: 18),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: PwfColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PwfColors.outline),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final stacked = c.maxWidth < 760;

            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('روابط سريعة',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                _FooterLink('من نحن'),
                _FooterLink('الخدمات'),
                _FooterLink('المشاريع'),
                _FooterLink('الأسئلة الشائعة'),
                _FooterLink('الخريطة'),
              ],
            );

            final mid = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('قانوني وتواصل',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                _FooterLink('سياسة الخصوصية'),
                _FooterLink('الشروط والأحكام'),
                _FooterLink('اتصل بنا'),
                const SizedBox(height: 10),
                Text(
                  'info@geo.gov.ps',
                  style: TextStyle(
                      color: PwfColors.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700),
                ),
              ],
            );

            final right = Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: PwfColors.royalRed,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.public, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GeoPST — منصة خرائط تفاعلية رائدة في فلسطين، تقدم تجربة سلسة للوصول إلى بيانات عقارية وجغرافية غنية.',
                    style: TextStyle(
                        color: PwfColors.onSurface.withValues(alpha: 0.72),
                        height: 1.6),
                  ),
                ),
              ],
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  right,
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: left),
                      const SizedBox(width: 14),
                      Expanded(child: mid),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      '© GeoPST 2026 جميع الحقوق محفوظة.',
                      style: TextStyle(
                          color: PwfColors.onSurface.withValues(alpha: 0.60),
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: right),
                    const SizedBox(width: 18),
                    SizedBox(width: 220, child: left),
                    const SizedBox(width: 18),
                    SizedBox(width: 220, child: mid),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '© GeoPST 2026 جميع الحقوق محفوظة.',
                  style: TextStyle(
                      color: PwfColors.onSurface.withValues(alpha: 0.60),
                      fontWeight: FontWeight.w700),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
            color: PwfColors.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
