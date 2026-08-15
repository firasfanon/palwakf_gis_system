import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';

class ExplorerUnifiedOperationalClosurePage extends StatelessWidget {
  const ExplorerUnifiedOperationalClosurePage({
    super.key,
    this.embeddedInAdmin = false,
    this.runtimeContext = const <String, String>{},
  });

  final bool embeddedInAdmin;
  final Map<String, String> runtimeContext;

  @override
  Widget build(BuildContext context) {
    final background = embeddedInAdmin ? const Color(0xFF0B1220) : PwfColors.background;
    final titleColor = embeddedInAdmin ? Colors.white : PwfColors.primaryBlue;
    final bodyColor = embeddedInAdmin
        ? Colors.white.withValues(alpha: 0.74)
        : const Color(0xFF475569);
    final groups = _ExplorerServiceGroup.groups;

    final content = ColoredBox(
      color: background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final wide = maxWidth >= 1180;
            final medium = maxWidth >= 780;
            final columns = wide ? 3 : (medium ? 2 : 1);
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 20, wide ? 24 : 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ServiceCenterHero(
                    runtimeContext: runtimeContext,
                    onOpenExplorer: () => context.go('/admin/explorer-suite'),
                    onOpenMap: () => context.go('/admin/mustakshif/review-map?source=service_center'),
                    onOpenReview: () => context.go('/admin/mustakshif/review-board?source=service_center'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'مركز خدمات المستكشف حسب طبيعة الاستخدام',
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تم ترتيب المستكشف كرحلات عمل وخدمات إنتاجية. ابدأ من الرحلة التي تصف ما تريد إنجازه، ثم انتقل للأداة المناسبة. كل خدمة توضّح المدخلات، الإجراء، والنتيجة المتوقعة حتى لا تبقى الأزرار مجرد مسميات تقنية.',
                    style: TextStyle(color: bodyColor, height: 1.6),
                  ),
                  const SizedBox(height: 14),
                  _BrowserUatResultPanel(embeddedInAdmin: embeddedInAdmin),
                  const SizedBox(height: 14),
                  _WorkflowQuickStartSection(embeddedInAdmin: embeddedInAdmin),
                  const SizedBox(height: 18),
                  Text(
                    'الخدمات التفصيلية حسب الاختصاص',
                    style: TextStyle(color: titleColor, fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'استخدم الخدمات التفصيلية عندما تعرف الإجراء المطلوب. أدوات الإدارة والتشخيص مطوية افتراضيًا لأنها ليست جزءًا من العمل اليومي للمستخدم التشغيلي.',
                    style: TextStyle(color: bodyColor, height: 1.6),
                  ),
                  const SizedBox(height: 14),
                  for (final group in groups) ...[
                    if (group.isAdvanced)
                      _AdvancedServicesExpansion(
                        group: group,
                        columns: columns,
                        embeddedInAdmin: embeddedInAdmin,
                      )
                    else
                      _ServiceGroupSection(
                        group: group,
                        columns: columns,
                        embeddedInAdmin: embeddedInAdmin,
                      ),
                    const SizedBox(height: 16),
                  ],
                  _GuardAndOutcomePanel(embeddedInAdmin: embeddedInAdmin),
                  const SizedBox(height: 16),
                  _AnalyzeIntakePanel(embeddedInAdmin: embeddedInAdmin),
                ],
              ),
            );
          },
        ),
      ),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: embeddedInAdmin
          ? content
          : Scaffold(
              backgroundColor: background,
              body: content,
            ),
    );
  }
}

class _ServiceCenterHero extends StatelessWidget {
  const _ServiceCenterHero({
    required this.runtimeContext,
    required this.onOpenExplorer,
    required this.onOpenMap,
    required this.onOpenReview,
  });

  final Map<String, String> runtimeContext;
  final VoidCallback onOpenExplorer;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenReview;

  @override
  Widget build(BuildContext context) {
    final source = runtimeContext['source'] ?? 'direct';
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
        border: Border.all(color: PwfColors.primaryGold.withValues(alpha: 0.25)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final stack = c.maxWidth < 760;
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroChip(label: 'Service Center'),
                  _HeroChip(label: 'Grouped Tools'),
                  _HeroChip(label: 'Practical Outcomes'),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'مركز خدمات مستكشف الوقف',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: stack ? 24 : 32,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'واجهة تشغيلية مرتبة حسب طبيعة العمل: البحث والملاحة، قراءة الخريطة، التحقق المكاني، ذكاء الوثائق، المراجعة والتكليف، والإدارة والتشخيص. لا توجد أداة بلا مهمة واضحة أو نتيجة قابلة للفحص.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroButton(
                    label: 'بوابة المستكشف',
                    icon: Icons.travel_explore_outlined,
                    onTap: onOpenExplorer,
                  ),
                  _HeroButton(
                    label: 'خريطة العمل',
                    icon: Icons.map_outlined,
                    onTap: onOpenMap,
                  ),
                  _HeroButton(
                    label: 'لوحة المراجعة',
                    icon: Icons.fact_check_outlined,
                    onTap: onOpenReview,
                  ),
                ],
              ),
            ],
          );
          final badge = Container(
            width: stack ? double.infinity : 290,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeroMetric(value: '06', label: 'مجموعات خدمات'),
                const SizedBox(height: 12),
                const _HeroMetric(value: '18', label: 'أداة/خدمة تشغيلية'),
                const SizedBox(height: 12),
                _HeroMetric(value: source, label: 'مصدر الفتح'),
              ],
            ),
          );
          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [summary, const SizedBox(height: 16), badge],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: summary),
              const SizedBox(width: 20),
              badge,
            ],
          );
        },
      ),
    );
  }
}


class _BrowserUatResultPanel extends StatelessWidget {
  const _BrowserUatResultPanel({required this.embeddedInAdmin});

  final bool embeddedInAdmin;

  @override
  Widget build(BuildContext context) {
    final bg = embeddedInAdmin ? const Color(0xFF111827) : Colors.white;
    final titleColor = embeddedInAdmin ? Colors.white : PwfColors.primaryBlue;
    final bodyColor = embeddedInAdmin
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF475569);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PwfColors.success.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: PwfColors.success.withValues(alpha: 0.13),
            child: const Icon(Icons.check_circle_outline, color: PwfColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نتيجة Browser UAT الحالية', style: TextStyle(color: titleColor, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  'تم استقبال نتيجة التشغيل بعد إصلاح مشكلة Render/hit-test، والهدف الآن تثبيت تجربة الاستخدام لا إضافة أدوات جديدة. إن ظهر خطأ تشغيل لاحقًا يعالج كـ P0 موضعي، أما تحسين النصوص والترتيب فيبقى ضمن هذه الصفحة فقط.',
                  style: TextStyle(color: bodyColor, height: 1.55),
                ),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TinyPill(label: 'Render P0: مغلق', color: PwfColors.success),
                    _TinyPill(label: 'Workflow Copy: محسّن', color: PwfColors.primaryGold),
                    _TinyPill(label: 'No new tools', color: PwfColors.primaryBlue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowQuickStartSection extends StatelessWidget {
  const _WorkflowQuickStartSection({required this.embeddedInAdmin});

  final bool embeddedInAdmin;

  @override
  Widget build(BuildContext context) {
    final bg = embeddedInAdmin ? const Color(0xFF111827) : Colors.white;
    final titleColor = embeddedInAdmin ? Colors.white : PwfColors.primaryBlue;
    final bodyColor = embeddedInAdmin
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF475569);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PwfColors.primaryGold.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: PwfColors.primaryGold.withValues(alpha: 0.15),
                child: const Icon(Icons.alt_route_outlined, color: PwfColors.primaryGold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('اختر رحلة العمل أولًا', style: TextStyle(color: titleColor, fontWeight: FontWeight.w900, fontSize: 17)),
                    const SizedBox(height: 6),
                    Text(
                      'هذه البطاقات تختصر الطريق للمستخدم. بدل السؤال: ما اسم الأداة؟ يصبح السؤال: ما المهمة التي أريد إنجازها؟ كل رحلة تفتح المسار التشغيلي الأقرب وتوضح الناتج العملي.',
                      style: TextStyle(color: bodyColor, height: 1.55),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width;
              final columns = maxWidth >= 1080 ? 3 : (maxWidth >= 720 ? 2 : 1);
              const gap = 12.0;
              final itemWidth = (maxWidth - (gap * (columns - 1))) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in _WorkflowItem.items)
                    SizedBox(
                      width: columns == 1 ? double.infinity : itemWidth,
                      child: _WorkflowQuickStartCard(item: item, embeddedInAdmin: embeddedInAdmin),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WorkflowQuickStartCard extends StatelessWidget {
  const _WorkflowQuickStartCard({required this.item, required this.embeddedInAdmin});

  final _WorkflowItem item;
  final bool embeddedInAdmin;

  @override
  Widget build(BuildContext context) {
    final bg = embeddedInAdmin ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC);
    final titleColor = embeddedInAdmin ? Colors.white : const Color(0xFF111827);
    final bodyColor = embeddedInAdmin
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF475569);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: item.color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: item.color.withValues(alpha: 0.13),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: TextStyle(color: titleColor, fontWeight: FontWeight.w900, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(item.audience, style: TextStyle(color: item.color, fontWeight: FontWeight.w800, fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.description, style: TextStyle(color: bodyColor, height: 1.45, fontSize: 12.5)),
          const SizedBox(height: 8),
          _ServiceField(label: 'النتيجة', value: item.expectedResult, color: bodyColor),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go(item.route),
              icon: const Icon(Icons.play_arrow_outlined, size: 18),
              label: Text(item.actionLabel),
              style: FilledButton.styleFrom(
                backgroundColor: item.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowItem {
  const _WorkflowItem({
    required this.title,
    required this.audience,
    required this.description,
    required this.expectedResult,
    required this.route,
    required this.actionLabel,
    required this.icon,
    required this.color,
  });

  final String title;
  final String audience;
  final String description;
  final String expectedResult;
  final String route;
  final String actionLabel;
  final IconData icon;
  final Color color;

  static const items = [
    _WorkflowItem(
      title: 'أبحث عن موقع أو وقف',
      audience: 'مستخدم تشغيلي',
      description: 'ابدأ هنا للوصول إلى محافظة، هيئة محلية، موقع، حوض، أو قطعة. البحث هنا ملاحة واختيار، وليس تشغيلًا للطبقات.',
      expectedResult: 'زوم أو انتقال إلى هدف واضح، أو قائمة اختيارات عند تشابه الأسماء.',
      route: '/admin/mustakshif/review-map?source=workflow_center&journey=search_and_navigate',
      actionLabel: 'افتح خريطة العمل',
      icon: Icons.manage_search_outlined,
      color: PwfColors.primaryBlue,
    ),
    _WorkflowItem(
      title: 'أفهم الطبقات الظاهرة',
      audience: 'مستخدم الخريطة',
      description: 'استخدم قراءة الخريطة لمعرفة معنى الطبقات، مصدرها، دقتها، وهل هي مؤشر أو دليل أو مرجع مساحي.',
      expectedResult: 'شرح للطبقات وحدود الاعتماد عليها قبل اتخاذ قرار.',
      route: '/admin/explorer-suite/cartography?source=workflow_center&journey=read_map',
      actionLabel: 'افتح قراءة الخريطة',
      icon: Icons.menu_book_outlined,
      color: PwfColors.primaryGold,
    ),
    _WorkflowItem(
      title: 'أتحقق من نقطة أو حدود',
      audience: 'مساح أو مراجع مكاني',
      description: 'ابدأ هنا لمطابقة نقطة، حدود، PDF، أو DWG مع التسوية والمرفقات مع بقاء النتيجة قابلة للمراجعة.',
      expectedResult: 'مرشح ربط أو تقرير تعارض يحال إلى لوحة المراجعة عند الحاجة.',
      route: '/admin/explorer-suite/smart?source=workflow_center&action=spatial_verification',
      actionLabel: 'ابدأ التحقق المكاني',
      icon: Icons.fact_check_outlined,
      color: PwfColors.success,
    ),
    _WorkflowItem(
      title: 'أحلل وثيقة أو صورة',
      audience: 'موظف الوثائق',
      description: 'استخدم ذكاء الوثائق لاستخراج أسماء وتواريخ ومواقع وأرقام من وثيقة أو صورة أو PDF كمؤشرات أولية.',
      expectedResult: 'حقول ومؤشرات ثقة لا تعتمد سياديًا قبل مراجعة بشرية.',
      route: '/admin/explorer-suite/smart?source=workflow_center&action=document_intelligence',
      actionLabel: 'ابدأ ذكاء الوثائق',
      icon: Icons.document_scanner_outlined,
      color: PwfColors.warning,
    ),
    _WorkflowItem(
      title: 'أراجع نتيجة وأتخذ إجراء',
      audience: 'مراجع أو صاحب صلاحية',
      description: 'كل نتيجة تحليل أو تحقق يجب أن تمر هنا عند الحاجة لقرار، تكليف، قبول، رفض، أو طلب استكمال.',
      expectedResult: 'سجل مراجعة أو مهمة تدقيق أو قرار قابل للتتبع.',
      route: '/admin/mustakshif/review-board?source=workflow_center&journey=review_decision',
      actionLabel: 'افتح لوحة المراجعة',
      icon: Icons.assignment_turned_in_outlined,
      color: PwfColors.royalRed,
    ),
    _WorkflowItem(
      title: 'أدير أو أشخص مشكلة',
      audience: 'مشرف أو مطور',
      description: 'هذه رحلة متقدمة للتحليل، المسارات، الطبقات، ونتائج flutter analyze. لا تستخدمها في العمل اليومي العادي.',
      expectedResult: 'قرار آمن: إصلاح P0، تأجيل warning، ضبط إداري، أو rollback.',
      route: '/admin/explorer-suite/operations?source=workflow_center&journey=developer_admin',
      actionLabel: 'افتح أدوات الإدارة',
      icon: Icons.admin_panel_settings_outlined,
      color: PwfColors.primaryBlue,
    ),
  ];
}

class _AdvancedServicesExpansion extends StatelessWidget {
  const _AdvancedServicesExpansion({
    required this.group,
    required this.columns,
    required this.embeddedInAdmin,
  });

  final _ExplorerServiceGroup group;
  final int columns;
  final bool embeddedInAdmin;

  @override
  Widget build(BuildContext context) {
    final bg = embeddedInAdmin ? const Color(0xFF111827) : Colors.white;
    final titleColor = embeddedInAdmin ? Colors.white : PwfColors.primaryBlue;
    final bodyColor = embeddedInAdmin
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF475569);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.15)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: group.color.withValues(alpha: 0.13),
            child: Icon(group.icon, color: group.color),
          ),
          title: Text(group.title, style: TextStyle(color: titleColor, fontWeight: FontWeight.w900, fontSize: 16)),
          subtitle: Text(
            '${group.description} هذا القسم مطوي افتراضيًا لأنه مخصص للمشرف أو المطور، وليس للمستخدم التشغيلي اليومي.',
            style: TextStyle(color: bodyColor, height: 1.45, fontSize: 12.6),
          ),
          iconColor: PwfColors.primaryGold,
          collapsedIconColor: PwfColors.primaryGold,
          children: [
            _ServiceGroupSection(
              group: group,
              columns: columns,
              embeddedInAdmin: embeddedInAdmin,
              showHeader: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceGroupSection extends StatelessWidget {
  const _ServiceGroupSection({
    required this.group,
    required this.columns,
    required this.embeddedInAdmin,
    this.showHeader = true,
  });

  final _ExplorerServiceGroup group;
  final int columns;
  final bool embeddedInAdmin;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final bg = embeddedInAdmin ? const Color(0xFF111827) : Colors.white;
    final titleColor = embeddedInAdmin ? Colors.white : PwfColors.primaryBlue;
    final bodyColor = embeddedInAdmin
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF475569);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: group.color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: group.color.withValues(alpha: 0.13),
                  child: Icon(group.icon, color: group.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.title, style: TextStyle(color: titleColor, fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(group.description, style: TextStyle(color: bodyColor, height: 1.55, fontSize: 12.8)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          LayoutBuilder(
            builder: (context, c) {
              const gap = 12.0;
              final width = (c.maxWidth - (gap * (columns - 1))) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final service in group.services)
                    SizedBox(
                      width: columns == 1 ? double.infinity : width,
                      child: _ExplorerServiceCard(
                        service: service,
                        embeddedInAdmin: embeddedInAdmin,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ExplorerServiceCard extends StatelessWidget {
  const _ExplorerServiceCard({required this.service, required this.embeddedInAdmin});

  final _ExplorerService service;
  final bool embeddedInAdmin;

  @override
  Widget build(BuildContext context) {
    final bg = embeddedInAdmin ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC);
    final titleColor = embeddedInAdmin ? Colors.white : const Color(0xFF111827);
    final bodyColor = embeddedInAdmin
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF475569);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: service.color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: service.color.withValues(alpha: 0.13),
                child: Icon(service.icon, color: service.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  service.title,
                  style: TextStyle(color: titleColor, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _TinyPill(label: service.level, color: service.color),
              _TinyPill(label: service.outputType, color: PwfColors.primaryGold),
            ],
          ),
          const SizedBox(height: 12),
          _ServiceField(label: 'متى تستخدم؟', value: service.whenToUse, color: bodyColor),
          const SizedBox(height: 9),
          _ServiceField(label: 'المهمة', value: service.task, color: bodyColor),
          const SizedBox(height: 9),
          _ServiceField(label: 'النتيجة المتوقعة', value: service.expectedResult, color: bodyColor),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go(service.route),
              icon: const Icon(Icons.open_in_new_outlined, size: 18),
              label: Text(service.actionLabel),
              style: FilledButton.styleFrom(
                backgroundColor: service.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceField extends StatelessWidget {
  const _ServiceField({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: PwfColors.primaryGold, fontWeight: FontWeight.w900, fontSize: 11.5)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: color, height: 1.45, fontSize: 12.4)),
      ],
    );
  }
}

class _GuardAndOutcomePanel extends StatelessWidget {
  const _GuardAndOutcomePanel({required this.embeddedInAdmin});

  final bool embeddedInAdmin;

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      embeddedInAdmin: embeddedInAdmin,
      icon: Icons.rule_folder_outlined,
      title: 'قاعدة الجدوى الإنتاجية',
      body:
          'أي أداة لا تنتج واحدة من هذه النتائج تعد مؤجلة: انتقال/زوم واضح، قراءة خريطة مفهومة، مرشح ربط، سجل مراجعة، مهمة تدقيق، تقرير قابل للتصدير، أو قرار قبول/رفض. لا يتم اعتبار التحليل أو الذكاء الاصطناعي مصدرًا سياديًا للحقيقة.',
    );
  }
}

class _AnalyzeIntakePanel extends StatelessWidget {
  const _AnalyzeIntakePanel({required this.embeddedInAdmin});

  final bool embeddedInAdmin;

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      embeddedInAdmin: embeddedInAdmin,
      icon: Icons.bug_report_outlined,
      title: 'ضبط التعقيد ومنع تضخم analyzer',
      body:
          'لا يتم تنظيف كل التحذيرات دفعة واحدة. عند وصول تقرير تحليل جديد يعالج P0 أولًا فقط، ثم P1 المرتبط بالملفات المعدلة. أي ارتفاع في عدد issues يعد regression ويعاد إلى آخر baseline مستقر.',
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.embeddedInAdmin,
    required this.icon,
    required this.title,
    required this.body,
  });

  final bool embeddedInAdmin;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final bg = embeddedInAdmin ? const Color(0xFF111827) : Colors.white;
    final titleColor = embeddedInAdmin ? Colors.white : PwfColors.primaryBlue;
    final bodyColor = embeddedInAdmin
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF475569);
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: PwfColors.primaryGold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: titleColor, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(body, style: TextStyle(color: bodyColor, height: 1.65)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplorerServiceGroup {
  const _ExplorerServiceGroup({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.services,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<_ExplorerService> services;

  bool get isAdvanced => title == 'الإدارة والتشخيص والتطوير';

  static const groups = [
    _ExplorerServiceGroup(
      title: 'البحث والملاحة على الخريطة',
      description: 'خدمات وظيفتها الوصول إلى الهدف الصحيح على الخريطة، لا تشغيل الطبقات ولا تعديلها.',
      icon: Icons.manage_search_outlined,
      color: PwfColors.primaryBlue,
      services: [
        _ExplorerService(
          title: 'البحث المكاني في الخريطة',
          whenToUse: 'عندما يعرف المستخدم اسم محافظة، تجمع، هيئة محلية، حوض، موقع، أو رقم قطعة ويريد الوصول إليها بسرعة.',
          task: 'ينفذ انتقالًا أو تقريبًا أو عرض خيارات عند وجود نتائج متشابهة.',
          expectedResult: 'الخريطة تنتقل للهدف، أو تعرض قائمة اختيارات واضحة عند الالتباس.',
          route: '/admin/mustakshif/review-map?source=service_center&service=map_search',
          actionLabel: 'فتح البحث على الخريطة',
          icon: Icons.search_outlined,
          color: PwfColors.primaryBlue,
          level: 'تشغيلي',
          outputType: 'زوم/انتقال',
        ),
        _ExplorerService(
          title: 'خريطة مراجعة المستكشف',
          whenToUse: 'عند الحاجة لمراجعة موقع سجل أو دليل أو فرضية مكانية داخل الخريطة.',
          task: 'يفتح خريطة المراجعة مع سياق المستكشف ولوحة الأدوات.',
          expectedResult: 'عرض موقع المراجعة أو سياق الخريطة دون تغيير activeLayers من خارج الخريطة.',
          route: '/admin/mustakshif/review-map?source=service_center&service=review_map',
          actionLabel: 'فتح خريطة المراجعة',
          icon: Icons.map_outlined,
          color: PwfColors.primaryBlue,
          level: 'تشغيلي',
          outputType: 'خريطة',
        ),
        _ExplorerService(
          title: 'قراءة النتائج المتشابهة',
          whenToUse: 'عند ظهور أكثر من مكان بالاسم نفسه مثل مدينة/محافظة/موقع مشابه.',
          task: 'يحول الالتباس إلى اختيار صريح من المستخدم بدل التخمين.',
          expectedResult: 'قائمة نتائج مفهومة ثم انتقال للهدف المختار فقط.',
          route: '/admin/mustakshif/review-map?source=service_center&service=ambiguous_results',
          actionLabel: 'اختبار نتائج البحث',
          icon: Icons.rule_outlined,
          color: PwfColors.primaryBlue,
          level: 'QA',
          outputType: 'اختيار واضح',
        ),
      ],
    ),
    _ExplorerServiceGroup(
      title: 'قراءة الخريطة والكارتوغرافيا',
      description: 'خدمات تساعد المستخدم على فهم معنى الطبقات، دقتها، مصدرها، وحدود الاعتماد عليها.',
      icon: Icons.menu_book_outlined,
      color: PwfColors.primaryGold,
      services: [
        _ExplorerService(
          title: 'قراءة الخريطة الحالية',
          whenToUse: 'عندما تظهر عدة طبقات ولا يعرف المستخدم ماذا تعني أو ما وزنها القانوني.',
          task: 'يعرض Legend ديناميكيًا وسياق الزوم والطبقات المرئية والتنبيهات الكارتوغرافية.',
          expectedResult: 'فهم واضح للطبقة: مصدرها، دقتها، وظيفتها، وهل تصلح كدليل أم كمؤشر فقط.',
          route: '/admin/explorer-suite/cartography?source=service_center&service=cartographic_reading',
          actionLabel: 'فتح قراءة الخريطة',
          icon: Icons.menu_book_outlined,
          color: PwfColors.primaryGold,
          level: 'إرشادي/تشغيلي',
          outputType: 'تفسير طبقات',
        ),
        _ExplorerService(
          title: 'تحذير جودة الطبقة',
          whenToUse: 'عند استخدام طبقة تاريخية أو تقريبية أو OCR أو طبقة غير مساحية.',
          task: 'يفصل بين طبقة مرجعية، طبقة تحليلية، طبقة مساحية، وطبقة غير صالحة كحقيقة سيادية.',
          expectedResult: 'منع سوء استخدام الخريطة كمستند قانوني عندما تكون مجرد مؤشر مكاني.',
          route: '/admin/explorer-suite/cartography?source=service_center&service=layer_quality',
          actionLabel: 'عرض جودة الطبقات',
          icon: Icons.verified_outlined,
          color: PwfColors.primaryGold,
          level: 'حوكمة',
          outputType: 'تنبيه اعتماد',
        ),
      ],
    ),
    _ExplorerServiceGroup(
      title: 'التحقق المكاني والمساحي',
      description: 'خدمات لمقارنة النقاط والحدود والمخططات مع التسوية والمرفقات، مع إبقاء القرار النهائي للمراجعة البشرية.',
      icon: Icons.fact_check_outlined,
      color: PwfColors.success,
      services: [
        _ExplorerService(
          title: 'مطابقة نقطة مع قطعة تسوية',
          whenToUse: 'عند وجود مسجد، مقام، مقبرة، أو أصل نقطي بلا مخطط مساحة وتريد معرفة القطعة التي يقع عليها.',
          task: 'يأخذ النقطة ويقارنها مع حدود قطع التسوية أو نطاق الهيئة المحلية.',
          expectedResult: 'مرشح قطعة أو أكثر مع درجة ثقة وملاحظة مراجعة، لا تحديث سيادي مباشر.',
          route: '/admin/explorer-suite/smart?source=service_center&action=spatial_verification&service=point_to_settlement',
          actionLabel: 'بدء مطابقة نقطة',
          icon: Icons.location_searching_outlined,
          color: PwfColors.success,
          level: 'تشغيلي/SV',
          outputType: 'مرشح ربط',
        ),
        _ExplorerService(
          title: 'مقارنة حدود مع مخطط PDF/DWG',
          whenToUse: 'عند توفر مخطط ورقي أو PDF أو DWG وتريد فحص تداخل أو صحة حدود مع الجوار.',
          task: 'يجهز الملف للمراجعة والتحويل والتحقق، ثم يرسل النتيجة إلى لوحة المراجعة.',
          expectedResult: 'تقرير تعارض/تطابق وحدود تحتاج مراجعة، وليس تعديلًا مباشرًا في طبقة التسوية.',
          route: '/admin/explorer-suite/smart?source=service_center&action=spatial_verification&service=survey_plan_compare',
          actionLabel: 'بدء فحص مخطط',
          icon: Icons.polyline_outlined,
          color: PwfColors.success,
          level: 'تشغيلي/SV',
          outputType: 'تقرير تحقق',
        ),
        _ExplorerService(
          title: 'توليد مخطط مساحة تحليلي',
          whenToUse: 'عندما تحتاج ملخصًا هندسيًا للأصل/القطعة لغرض مراجعة داخلية.',
          task: 'يجمع سياق القطعة والحدود والطبقات المرجعية في مخرج قابل للمراجعة.',
          expectedResult: 'مخطط/ملخص تحليلي يساعد القرار ولا يحل محل مخطط مساحي رسمي.',
          route: '/admin/explorer-suite/smart?source=service_center&action=spatial_verification&service=survey_summary',
          actionLabel: 'تجهيز مخطط تحليلي',
          icon: Icons.architecture_outlined,
          color: PwfColors.success,
          level: 'تحليلي',
          outputType: 'ملخص مساحة',
        ),
      ],
    ),
    _ExplorerServiceGroup(
      title: 'ذكاء الوثائق والمعرفة',
      description: 'خدمات OCR/LLM/RAG لا تنتج حقيقة سيادية، بل تستخرج مؤشرات وأدلة قابلة للمراجعة.',
      icon: Icons.psychology_alt_outlined,
      color: PwfColors.warning,
      services: [
        _ExplorerService(
          title: 'استخراج بيانات من وثيقة',
          whenToUse: 'عند رفع وثيقة وقف، مخطط، كتاب، صورة، أو ملف يحتاج قراءة أولية.',
          task: 'يشغل OCR/تحليل بنيوي لاستخراج أسماء، تواريخ، مواقع، أرقام، وأطراف.',
          expectedResult: 'حقول مستخرجة ومؤشرات ثقة تُرسل للمراجعة البشرية قبل الربط.',
          route: '/admin/explorer-suite/smart?source=service_center&action=document_intelligence&service=ocr_intake',
          actionLabel: 'بدء ذكاء الوثائق',
          icon: Icons.document_scanner_outlined,
          color: PwfColors.warning,
          level: 'AI Sandbox',
          outputType: 'حقول مستخرجة',
        ),
        _ExplorerService(
          title: 'تحليل معرفي RAG',
          whenToUse: 'عند الحاجة لمقارنة محتوى الوثيقة مع معرفة المشروع أو أدلة سابقة.',
          task: 'يبني إجابة مدعومة بمصادر داخلية/مرفقات ويحدد الفجوات.',
          expectedResult: 'ملخص استدلالي مع مصادر، لا قرار نهائي ولا تعديل مباشر.',
          route: '/admin/explorer-suite/smart?source=service_center&action=document_intelligence&service=rag_review',
          actionLabel: 'فتح تحليل RAG',
          icon: Icons.hub_outlined,
          color: PwfColors.warning,
          level: 'AI Review',
          outputType: 'ملخص مدعوم',
        ),
      ],
    ),
    _ExplorerServiceGroup(
      title: 'المراجعة والتكليف والقرارات',
      description: 'خدمات تحول نتائج التحليل إلى عمل مؤسسي: سجل مراجعة، مرفق، تكليف، قرار قبول أو رفض.',
      icon: Icons.assignment_turned_in_outlined,
      color: PwfColors.royalRed,
      services: [
        _ExplorerService(
          title: 'لوحة مراجعة الأدلة',
          whenToUse: 'عندما تنتج الخريطة أو الذكاء أو التحقق المكاني فرضية تحتاج قرارًا بشريًا.',
          task: 'تعرض السجل، الأدلة، الحالة، والقرار أو الملاحظة.',
          expectedResult: 'قرار مراجعة موثق: قبول، رفض، يحتاج استكمال، أو تحويل لمهمة.',
          route: '/admin/mustakshif/review-board?source=service_center&service=evidence_review',
          actionLabel: 'فتح لوحة المراجعة',
          icon: Icons.fact_check_outlined,
          color: PwfColors.royalRed,
          level: 'مراجعة',
          outputType: 'قرار بشري',
        ),
        _ExplorerService(
          title: 'مراجعة فجوات المستكشف',
          whenToUse: 'عند وجود نقص في ربط الأصل، الهندسة، المصدر، أو الصلاحية.',
          task: 'يسجل الفجوة ويصنفها ويجهزها للتكليف أو الإغلاق.',
          expectedResult: 'سجل Gap قابل للمتابعة بدل ترك الملاحظة داخل الخريطة فقط.',
          route: '/admin/explorer-gap-audits?source=service_center&service=gap_review',
          actionLabel: 'فتح فجوات المستكشف',
          icon: Icons.report_problem_outlined,
          color: PwfColors.royalRed,
          level: 'تدقيق',
          outputType: 'Gap Record',
        ),
        _ExplorerService(
          title: 'مهام التدقيق',
          whenToUse: 'عندما تحتاج الفجوة أو المراجعة إلى متابعة من موظف أو وحدة.',
          task: 'تحويل الملاحظة إلى مهمة قابلة للتتبع.',
          expectedResult: 'مهمة واضحة لها حالة ومسؤولية وسياق.',
          route: '/admin/audit-tasks?source=service_center&service=audit_task',
          actionLabel: 'فتح مهام التدقيق',
          icon: Icons.task_alt_outlined,
          color: PwfColors.royalRed,
          level: 'تكليف',
          outputType: 'Task',
        ),
      ],
    ),
    _ExplorerServiceGroup(
      title: 'الإدارة والتشخيص والتطوير',
      description: 'خدمات موجهة للمشرف والمطور، وليست للمستخدم التشغيلي اليومي.',
      icon: Icons.admin_panel_settings_outlined,
      color: PwfColors.primaryBlue,
      services: [
        _ExplorerService(
          title: 'إدارة طبقات GIS',
          whenToUse: 'عند الحاجة لضبط بيانات الطبقات أو مفاتيحها أو ظهورها الإداري.',
          task: 'مراجعة تعريف الطبقات وإعداداتها من جهة الإدارة.',
          expectedResult: 'طبقة مضبوطة إداريًا دون ربطها مباشرة بسلوك البحث.',
          route: '/admin/gis-layers?source=service_center&service=gis_admin',
          actionLabel: 'فتح إدارة GIS',
          icon: Icons.layers_outlined,
          color: PwfColors.primaryBlue,
          level: 'إدارة',
          outputType: 'إعداد طبقات',
        ),
        _ExplorerService(
          title: 'Analyzer Gate',
          whenToUse: 'بعد أي دمج أو خطأ تحليل محلي.',
          task: 'فرز P0/P1 ومنع تنظيف واسع غير آمن.',
          expectedResult: 'قرار واضح: إصلاح مانع، أو تأجيل warning، أو rollback.',
          route: '/admin/explorer-suite/operations?source=service_center&service=analyzer_gate',
          actionLabel: 'فتح بوابة التحليل',
          icon: Icons.bug_report_outlined,
          color: PwfColors.primaryBlue,
          level: 'حوكمة',
          outputType: 'قرار أمان',
        ),
        _ExplorerService(
          title: 'سجل المسارات للمطور',
          whenToUse: 'عندما يريد المطور معرفة الصفحة والمسار دون البحث داخل الكود.',
          task: 'يعرض المسارات من السايدبار وخيار إظهار أسماء الصفحات.',
          expectedResult: 'تقليل الضياع أثناء التطوير والاختبار.',
          route: '/admin/explorer-suite?source=service_center&service=developer_registry',
          actionLabel: 'فتح بوابة المسارات',
          icon: Icons.route_outlined,
          color: PwfColors.primaryBlue,
          level: 'Developer',
          outputType: 'Route Registry',
        ),
      ],
    ),
  ];
}

class _ExplorerService {
  const _ExplorerService({
    required this.title,
    required this.whenToUse,
    required this.task,
    required this.expectedResult,
    required this.route,
    required this.actionLabel,
    required this.icon,
    required this.color,
    required this.level,
    required this.outputType,
  });

  final String title;
  final String whenToUse;
  final String task;
  final String expectedResult;
  final String route;
  final String actionLabel;
  final IconData icon;
  final Color color;
  final String level;
  final String outputType;
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: PwfColors.primaryGold,
        foregroundColor: const Color(0xFF111827),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.68), fontSize: 12)),
      ],
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11),
      ),
    );
  }
}
