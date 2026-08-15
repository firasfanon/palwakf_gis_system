import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';

class ExplorerSuitePage extends StatelessWidget {
  const ExplorerSuitePage({super.key, this.embeddedInAdmin = false});

  final bool embeddedInAdmin;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            embeddedInAdmin ? const Color(0xFF0B1220) : PwfColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1180;
              final medium = constraints.maxWidth >= 760;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  wide ? 24 : 16,
                  20,
                  wide ? 24 : 16,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExplorerHero(
                      embeddedInAdmin: embeddedInAdmin,
                      onOpenModernMap: () => context.go(
                        embeddedInAdmin
                            ? '/admin/mustakshif/review-map?source=explorer_suite'
                            : '/map',
                      ),
                      onOpenSmartExplorer: () => context.go(
                        '/admin/explorer-suite/smart?source=explorer_suite',
                      ),
                      onOpenUnifiedOperations: () => context.go(
                        '/admin/explorer-suite/operations?source=explorer_suite',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ExplorerPagesGrid(
                      columns: wide ? 4 : (medium ? 2 : 1),
                      embeddedInAdmin: embeddedInAdmin,
                    ),
                    const SizedBox(height: 16),
                    _SharedToolsSection(
                      embeddedInAdmin: embeddedInAdmin,
                      columns: wide ? 3 : (medium ? 2 : 1),
                    ),
                    const SizedBox(height: 16),
                    _NextExecutionPanel(embeddedInAdmin: embeddedInAdmin),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ExplorerHero extends StatelessWidget {
  const _ExplorerHero({
    required this.embeddedInAdmin,
    required this.onOpenModernMap,
    required this.onOpenSmartExplorer,
    required this.onOpenUnifiedOperations,
  });

  final bool embeddedInAdmin;
  final VoidCallback onOpenModernMap;
  final VoidCallback onOpenSmartExplorer;
  final VoidCallback onOpenUnifiedOperations;

  @override
  Widget build(BuildContext context) {
    const titleColor = Colors.white;
    final bodyColor = Colors.white.withValues(alpha: 0.76);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1220), Color(0xFF1E3A8A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PwfColors.primaryGold.withValues(alpha: 0.22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final stack = c.maxWidth < 760;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroChip(label: 'Mustakshif Explorer Suite'),
                  _HeroChip(label: '4 Maps'),
                  _HeroChip(label: 'Smart Explorer'),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'صفحات مستكشف الوقف والتاريخ المكاني',
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w900,
                  fontSize: stack ? 24 : 32,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'بوابة موحدة للوصول إلى الخريطة الحديثة، التطور التاريخي المكاني، أصول الوقف عبر التاريخ، التقسيمات الإدارية التاريخية، وطبقة المستكشف الذكي للتحليل والتدقيق.',
                style: TextStyle(
                  color: bodyColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _PrimaryAction(
                    label: 'فتح الخريطة الحديثة',
                    icon: Icons.map_outlined,
                    onTap: onOpenModernMap,
                  ),
                  _SecondaryAction(
                    label: 'المستكشف الذكي',
                    icon: Icons.psychology_alt_outlined,
                    onTap: onOpenSmartExplorer,
                  ),
                  _SecondaryAction(
                    label: 'مركز خدمات المستكشف',
                    icon: Icons.task_alt_outlined,
                    onTap: onOpenUnifiedOperations,
                  ),
                ],
              ),
            ],
          );

          final badge = Container(
            width: stack ? double.infinity : 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroMetric(value: '05', label: 'خرائط/مسارات تشغيلية'),
                SizedBox(height: 12),
                _HeroMetric(value: '01', label: 'طبقة ذكاء وتحليل'),
                SizedBox(height: 12),
                _HeroMetric(value: 'RBAC', label: 'حوكمة وصلاحيات'),
              ],
            ),
          );

          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 16), badge],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: text),
              const SizedBox(width: 20),
              badge,
            ],
          );
        },
      ),
    );
  }
}

class _ExplorerPagesGrid extends StatelessWidget {
  const _ExplorerPagesGrid({
    required this.columns,
    required this.embeddedInAdmin,
  });

  final int columns;
  final bool embeddedInAdmin;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _ExplorerPageItem(
        title: 'الخريطة الحديثة',
        subtitle:
            'الخريطة التشغيلية العامة: طبقات خفيفة افتراضيًا، تحميل حسب التكبير والحدود، وبحث وفلاتر حسب الصلاحيات.',
        route: '/map',
        icon: Icons.public_outlined,
        accent: PwfColors.primaryBlue,
        status: 'جاهزة للتطوير التشغيلي',
      ),
      _ExplorerPageItem(
        title: 'قراءة الخريطة والكارتوغرافيا',
        subtitle:
            'نموذج معرفي لقراءة الخريطة: مصدر الطبقة، مستوى الدقة، الوزن القانوني، Legend ديناميكي، وتحذيرات الاعتماد دون تغيير activeLayers.',
        route: '/admin/explorer-suite/cartography',
        icon: Icons.menu_book_outlined,
        accent: PwfColors.primaryGold,
        status: 'Cartographic Reading',
      ),
      _ExplorerPageItem(
        title: 'التطور التاريخي المكاني',
        subtitle:
            'استعراض التحولات الهندسية والمكانية عبر الفترات التاريخية مع خط زمني وطبقات مقارنة.',
        route: '/history?mode=historical',
        icon: Icons.timeline_outlined,
        accent: PwfColors.warning,
        status: 'History Explorer',
      ),
      _ExplorerPageItem(
        title: 'أصول الوقف عبر التاريخ',
        subtitle:
            'قراءة الأصل الوقفي العيني والوقف المرجعي والقطع المرتبطة دون إسقاط الأصول التي لا تملك هندسة.',
        route: '/history?mode=waqf',
        icon: Icons.domain_outlined,
        accent: PwfColors.royalRed,
        status: 'Waqf Assets Centered',
      ),
      _ExplorerPageItem(
        title: 'التقسيمات الإدارية التاريخية',
        subtitle:
            'صفحة مستقلة للسياق الإداري السابق للتقسيم الحديث: عثماني، انتدابي، أردني/مصري، احتلال، سلطة، وحديث.',
        route: '/history/admin-divisions',
        icon: Icons.account_tree_outlined,
        accent: PwfColors.success,
        status: 'Historical Admin Alignment',
      ),
      _ExplorerPageItem(
        title: 'المستكشف الذكي داخل المستكشف',
        subtitle:
            'تشغيل مدمج داخل Mustakshif Explorer: تحليل فجوات البيانات، اقتراح الربط، OCR/RAG، التحقق المكاني، ولوحة المراجعة دون تغيير activeLayers.',
        route: '/admin/explorer-suite/smart',
        icon: Icons.psychology_alt_outlined,
        accent: PwfColors.primaryGold,
        status: 'Embedded Runtime',
      ),
      _ExplorerPageItem(
        title: 'مركز خدمات المستكشف',
        subtitle:
            'واجهة مرتبة تجمع أدوات المستكشف حسب طبيعة الاستخدام، وتوضح وظيفة كل أداة والنتيجة المتوقعة منها.',
        route: '/admin/explorer-suite/operations',
        icon: Icons.task_alt_outlined,
        accent: PwfColors.success,
        status: 'Service Center',
      ),
      _ExplorerPageItem(
        title: 'مراجعة المستكشف داخل الخريطة',
        subtitle:
            'تشغيل سجلات Review Board فعليًا داخل خريطة المستكشف بأوامر كاميرا فقط: fit_bbox أو focus point، دون تشغيل طبقات أو تعديل activeLayers.',
        route: '/admin/mustakshif/review-board',
        icon: Icons.manage_search_outlined,
        accent: PwfColors.royalRed,
        status: 'Runtime Review Bridge',
      ),
    ];

    return _SectionShell(
      title: 'صفحات المستكشف',
      subtitle: 'كل صفحة لها خريطتها وأدواتها، مع أدوات مشتركة وحوكمة واحدة.',
      embeddedInAdmin: embeddedInAdmin,
      child: _ResponsiveCardGrid(
        columns: columns,
        itemCount: pages.length,
        itemBuilder: (context, index) {
          final item = pages[index];
          return _ExplorerPageCard(
            item: item,
            embeddedInAdmin: embeddedInAdmin,
            onTap: () => context.go(item.route),
          );
        },
      ),
    );
  }
}

class _SharedToolsSection extends StatelessWidget {
  const _SharedToolsSection({
    required this.embeddedInAdmin,
    required this.columns,
  });

  final bool embeddedInAdmin;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _ToolItem(
        title: 'تحميل ذكي للطبقات',
        body:
            'لا تحميل كامل للطبقات الثقيلة؛ يعتمد السلوك على مستوى التكبير، حدود الشاشة، واختيار المستخدم.',
        icon: Icons.speed_outlined,
      ),
      const _ToolItem(
        title: 'بحث وسيط واحد',
        body:
            'البحث يدعم الاسم، الرقم الوطني، الوقف المرجعي، المحافظة، الهيئة المحلية، والتجمع عند توفر البيانات.',
        icon: Icons.manage_search_outlined,
      ),
      const _ToolItem(
        title: 'تدقيق وفجوات',
        body:
            'أي نقص في الهندسة أو الربط ينتقل إلى مراجعة أو مهمة تدقيق بدل التعديل المباشر على مصدر الحقيقة.',
        icon: Icons.fact_check_outlined,
      ),
      const _ToolItem(
        title: 'فتح متبادل بين الخرائط',
        body:
            'نتيجة البحث أو الفرضية الذكية يمكن فتحها على الخريطة الحديثة أو التاريخية أو صفحة التقسيمات.',
        icon: Icons.open_in_new_outlined,
      ),
      const _ToolItem(
        title: 'حماية المصدر السيادي',
        body:
            'awqaf_system يبقى مصدر الحقيقة للأصول والوقف المرجعي، وMustakshif يقرأ ويحلل ولا يعيد تعريفها.',
        icon: Icons.verified_user_outlined,
      ),
      const _ToolItem(
        title: 'RTL وهوية موحدة',
        body:
            'واجهة عربية RTL بهوية أزرق/ذهبي مع الأحمر الملكي، وقابلة للتوسعة لاحقًا لـ i18n.',
        icon: Icons.palette_outlined,
      ),
    ];

    return _SectionShell(
      title: 'الأدوات المشتركة بين الخرائط',
      subtitle: 'هذه القواعد يجب أن تبقى موحدة حتى لو اختلفت أدوات كل صفحة.',
      embeddedInAdmin: embeddedInAdmin,
      child: _ResponsiveCardGrid(
        columns: columns,
        itemCount: items.length,
        itemBuilder: (context, index) => _ToolCard(
          item: items[index],
          embeddedInAdmin: embeddedInAdmin,
        ),
      ),
    );
  }
}

class _NextExecutionPanel extends StatelessWidget {
  const _NextExecutionPanel({required this.embeddedInAdmin});

  final bool embeddedInAdmin;

  @override
  Widget build(BuildContext context) {
    final bg = embeddedInAdmin ? const Color(0xFF111827) : Colors.white;
    final titleColor = embeddedInAdmin ? Colors.white : PwfColors.primaryBlue;
    final bodyColor = embeddedInAdmin
        ? Colors.white.withValues(alpha: 0.72)
        : PwfColors.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: embeddedInAdmin
              ? Colors.white.withValues(alpha: 0.08)
              : PwfColors.primaryBlue.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'طريقة الاستخدام المقترحة',
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'يعتمد التشغيل القادم على استخدام مركز الخدمات بدل التنقل بين أزرار متفرقة. يبدأ المستخدم من تحديد نوع المهمة: بحث، قراءة خريطة، تحقق مكاني، ذكاء وثائق، مراجعة، أو إدارة وتشخيص.',
            style: TextStyle(color: bodyColor, height: 1.7, fontSize: 13),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PlanChip(label: 'Modern Map Performance'),
              _PlanChip(label: 'Historical Admin Divisions'),
              _PlanChip(label: 'Smart Explorer Bridge'),
              _PlanChip(label: 'Audit Tasks Closure'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.embeddedInAdmin,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool embeddedInAdmin;

  @override
  Widget build(BuildContext context) {
    final titleColor = embeddedInAdmin ? Colors.white : PwfColors.primaryBlue;
    final subtitleColor = embeddedInAdmin
        ? Colors.white.withValues(alpha: 0.68)
        : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(color: subtitleColor, height: 1.5),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _ResponsiveCardGrid extends StatelessWidget {
  const _ResponsiveCardGrid({
    required this.columns,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int columns;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 12.0;
        final width = (c.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: List.generate(
            itemCount,
            (index) => SizedBox(
              width: columns == 1 ? double.infinity : width,
              child: itemBuilder(context, index),
            ),
          ),
        );
      },
    );
  }
}

class _ExplorerPageCard extends StatelessWidget {
  const _ExplorerPageCard({
    required this.item,
    required this.embeddedInAdmin,
    required this.onTap,
  });

  final _ExplorerPageItem item;
  final bool embeddedInAdmin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = embeddedInAdmin ? const Color(0xFF111827) : Colors.white;
    final titleColor = embeddedInAdmin ? Colors.white : const Color(0xFF111827);
    final bodyColor = embeddedInAdmin
        ? Colors.white.withValues(alpha: 0.70)
        : const Color(0xFF475569);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 236,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: item.accent.withValues(alpha: 0.18)),
          boxShadow: embeddedInAdmin
              ? const []
              : const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: item.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                item.subtitle,
                style: TextStyle(color: bodyColor, height: 1.55, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatusPill(label: item.status, color: item.accent),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_left, color: item.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.item, required this.embeddedInAdmin});

  final _ToolItem item;
  final bool embeddedInAdmin;

  @override
  Widget build(BuildContext context) {
    final bg = embeddedInAdmin ? const Color(0xFF111827) : Colors.white;
    final titleColor = embeddedInAdmin ? Colors.white : PwfColors.primaryBlue;
    final bodyColor = embeddedInAdmin
        ? Colors.white.withValues(alpha: 0.70)
        : const Color(0xFF475569);

    return Container(
      height: 158,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: embeddedInAdmin
              ? Colors.white.withValues(alpha: 0.08)
              : PwfColors.primaryBlue.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: PwfColors.primaryGold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    item.body,
                    style: TextStyle(
                      color: bodyColor,
                      height: 1.55,
                      fontSize: 13,
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

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: PwfColors.primaryGold,
        foregroundColor: const Color(0xFF111827),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: PwfColors.primaryGold,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: PwfColors.primaryGold.withValues(alpha: 0.12),
      side: BorderSide(color: PwfColors.primaryGold.withValues(alpha: 0.18)),
      labelStyle: const TextStyle(
        color: PwfColors.primaryGold,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    );
  }
}

class _ExplorerPageItem {
  const _ExplorerPageItem({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.accent,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final Color accent;
  final String status;
}

class _ToolItem {
  const _ToolItem({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}
