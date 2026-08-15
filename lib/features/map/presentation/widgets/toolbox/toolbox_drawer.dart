// lib/features/map/presentation/widgets/toolbox/toolbox_drawer.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/theme.dart';
import '../../providers/map_provider.dart';
import '../../providers/map_ui_providers.dart';
import '../../providers/toolbox_providers.dart';

import 'tool_sections/import_section.dart';
import 'tool_sections/layers_section.dart';
import 'tool_sections/map_tools_section.dart';
import 'tool_sections/settings_section.dart';

class ToolboxDrawer extends ConsumerWidget {
  const ToolboxDrawer({super.key});

  static const double expandedWidth = 320;
  static const double collapsedWidth = 54;

  static double widthFor(
    BuildContext context, {
    required bool expanded,
  }) {
    if (!expanded) return collapsedWidth;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final safeMax = math.min(expandedWidth, math.max(268.0, screenWidth));

    if (screenWidth < 520) {
      return safeMax;
    }
    if (screenWidth < 880) {
      return math.min(304.0, safeMax);
    }
    return expandedWidth;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: PwfTheme.lightTheme,
      child: Builder(
        builder: (context) {
          final isExpanded = ref.watch(toolboxExpandedProvider);
          final activeSection = ref.watch(activeToolSectionProvider);
          final audience = ref.watch(mapToolAudienceProvider);
          final drawerWidth = widthFor(context, expanded: isExpanded);
          final effectiveSection = activeSection != null &&
                  !audience.canAccessSection(activeSection)
              ? null
              : activeSection;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: ClipRRect(
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(18),
                bottomStart: Radius.circular(18),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: drawerWidth,
                decoration: BoxDecoration(
                  color: PwfColors.surface,
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(18),
                    bottomStart: Radius.circular(18),
                  ),
                  border: Border.all(
                    color: PwfColors.outline.withValues(alpha: 0.95),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(-2, 0),
                    ),
                  ],
                ),
                child: isExpanded
                    ? _ExpandedDrawer(activeSection: effectiveSection)
                    : const _CollapsedDrawer(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CollapsedDrawer extends ConsumerWidget {
  const _CollapsedDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeToolSectionProvider);
    final audience = ref.watch(mapToolAudienceProvider);

    return Column(
      children: [
        const SizedBox(height: 7),
        Container(
          width: 26,
          height: 4,
          decoration: BoxDecoration(
            color: PwfColors.onSurface.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 6),
        _SideRailButton(
          icon: Icons.layers_outlined,
          tooltip: 'الطبقات',
          isActive: active == ToolSection.layers,
          onTap: () => _activate(ref, ToolSection.layers),
        ),
        _SideRailButton(
          icon: Icons.tune_rounded,
          tooltip: 'الأدوات',
          isActive: active == ToolSection.tools,
          onTap: () => _activate(ref, ToolSection.tools),
        ),
        if (audience.canAccessSection(ToolSection.import))
          _SideRailButton(
            icon: Icons.upload_file_outlined,
            tooltip: 'الاستيراد',
            isActive: active == ToolSection.import,
            onTap: () => _activate(ref, ToolSection.import),
          ),
        _SideRailButton(
          icon: Icons.settings_outlined,
          tooltip: 'الإعدادات',
          isActive: active == ToolSection.settings,
          onTap: () => _activate(ref, ToolSection.settings),
        ),
        const Spacer(),
        Container(
          margin: const EdgeInsets.only(bottom: 5),
          width: 34,
          height: 1,
          color: PwfColors.outline.withValues(alpha: 0.8),
        ),
        _SideRailButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'توسيع',
          isActive: false,
          onTap: () => ref.read(toolboxExpandedProvider.notifier).state = true,
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  void _activate(WidgetRef ref, ToolSection section) {
    ref.read(toolboxExpandedProvider.notifier).state = true;
    ref.read(activeToolSectionProvider.notifier).state = section;
  }
}

class _ExpandedDrawer extends ConsumerWidget {
  const _ExpandedDrawer({required this.activeSection});

  final ToolSection? activeSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _DrawerHeader(activeSection: activeSection),
        _PrimaryActionsRow(activeSection: activeSection),
        const _ToolboxStatusStrip(),
        Expanded(
          child: activeSection == null
              ? const _DrawerHome()
              : _buildActiveSection(activeSection!),
        ),
      ],
    );
  }

  Widget _buildActiveSection(ToolSection section) {
    switch (section) {
      case ToolSection.search:
        return const _DrawerHome();
      case ToolSection.layers:
        return const LayersSection();
      case ToolSection.tools:
        return const MapToolsSection();
      case ToolSection.import:
        return const ImportSection();
      case ToolSection.settings:
        return const SettingsSection();
    }
  }
}

class _DrawerHeader extends ConsumerWidget {
  const _DrawerHeader({required this.activeSection});

  final ToolSection? activeSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = switch (activeSection) {
      ToolSection.search => 'تم نقل البحث إلى تبويب مستقل داخل المستكشف الحديث',
      ToolSection.layers => 'إدارة الطبقات والتصنيفات والشفافية من مكان واحد',
      ToolSection.tools => 'قياس ورسم وإحداثيات ومقارنة ومشاركة',
      ToolSection.import => 'رفع ملفات داعمة عند الحاجة التشغيلية',
      ToolSection.settings => 'ضبط العرض والخريطة الأساسية وسلوك الواجهة',
      null => 'لوحة تحكم موحدة للطبقات وأدوات الخريطة دون تغيير الطبقات عند الفتح',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
      decoration: BoxDecoration(
        color: PwfColors.surface,
        border: Border(
          bottom: BorderSide(
            color: PwfColors.royalRed.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: PwfColors.royalRed.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.dashboard_customize_outlined,
              color: PwfColors.royalRed,
              size: 16,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'صندوق أدوات الخريطة',
                  style: TextStyle(
                    color: PwfColors.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: PwfColors.onSurface.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'تصغير',
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            onPressed: () {
              ref.read(toolboxExpandedProvider.notifier).state = false;
              ref.read(activeToolSectionProvider.notifier).state = null;
            },
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: PwfColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionsRow extends ConsumerWidget {
  const _PrimaryActionsRow({required this.activeSection});

  final ToolSection? activeSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audience = ref.watch(mapToolAudienceProvider);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: PwfColors.surfaceVariant.withValues(alpha: 0.45),
        border: Border(
          bottom: BorderSide(color: PwfColors.outline.withValues(alpha: 0.80)),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _SectionChip(
            title: 'الرئيسية',
            icon: Icons.home_outlined,
            isActive: activeSection == null,
            onTap: () => ref.read(activeToolSectionProvider.notifier).state = null,
          ),
          const SizedBox(width: 5),
          _SectionChip(
            title: 'الطبقات',
            icon: Icons.layers_outlined,
            isActive: activeSection == ToolSection.layers,
            onTap: () => ref.read(activeToolSectionProvider.notifier).state = ToolSection.layers,
          ),
          const SizedBox(width: 5),
          _SectionChip(
            title: 'الأدوات',
            icon: Icons.tune_rounded,
            isActive: activeSection == ToolSection.tools,
            onTap: () => ref.read(activeToolSectionProvider.notifier).state = ToolSection.tools,
          ),
          const SizedBox(width: 5),
          if (audience.canAccessSection(ToolSection.import)) ...[
            _SectionChip(
              title: 'استيراد',
              icon: Icons.upload_file_outlined,
              isActive: activeSection == ToolSection.import,
              onTap: () => ref.read(activeToolSectionProvider.notifier).state = ToolSection.import,
            ),
            const SizedBox(width: 5),
          ],
          _SectionChip(
            title: 'إعدادات',
            icon: Icons.settings_outlined,
            isActive: activeSection == ToolSection.settings,
            onTap: () => ref.read(activeToolSectionProvider.notifier).state = ToolSection.settings,
          ),
        ],
      ),
    );
  }
}

class _ToolboxStatusStrip extends ConsumerWidget {
  const _ToolboxStatusStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapNotifierProvider);
    final activeSection = ref.watch(activeToolSectionProvider);
    final audience = ref.watch(mapToolAudienceProvider);
    final compareEnabled = ref.watch(compareEnabledProvider);

    final activeCount = mapState.activeLayers.length;
    final totalCount = mapState.gisLayers.length;
    final featureCount = mapState.gisFeatures.length;

    String sectionLabel(ToolSection? section) {
      switch (section) {
        case ToolSection.search:
          return 'البحث';
        case ToolSection.layers:
          return 'الطبقات';
        case ToolSection.tools:
          return 'الأدوات';
        case ToolSection.import:
          return 'الاستيراد';
        case ToolSection.settings:
          return 'الإعدادات';
        case null:
          return 'الرئيسية';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: PwfColors.outline.withValues(alpha: 0.85)),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _StatusPill(
            icon: Icons.grid_view_rounded,
            label: sectionLabel(activeSection),
            color: PwfColors.royalRed,
          ),
          _StatusPill(
            icon: Icons.admin_panel_settings_outlined,
            label: audience.labelAr,
            color: audience.canUseManagerTools
                ? PwfColors.royalRed
                : (audience.canUseEmployeeTools
                    ? PwfColors.primaryBlue
                    : PwfColors.primaryGold),
          ),
          _StatusPill(
            icon: Icons.visibility_outlined,
            label: '$activeCount مفعلة',
            color: PwfColors.success,
          ),
          _StatusPill(
            icon: Icons.layers_outlined,
            label: '$totalCount طبقة',
            color: PwfColors.primaryBlue,
          ),
          _StatusPill(
            icon: Icons.map_outlined,
            label: '$featureCount عنصر',
            color: PwfColors.primaryGold,
          ),
          if (compareEnabled)
            const _StatusPill(
              icon: Icons.compare_arrows_outlined,
              label: 'المقارنة نشطة',
              color: PwfColors.royalRed,
            ),
        ],
      ),
    );
  }
}

class _SectionIntroCard extends StatelessWidget {
  const _SectionIntroCard({required this.section});

  final ToolSection section;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (section) {
      case ToolSection.search:
        icon = Icons.search_rounded;
        color = PwfColors.primaryBlue;
        title = 'البحث الموجّه';
        subtitle = 'ابدأ من مصدر البيانات، ثم أكمل الحقول التابعة له قبل تنفيذ البحث.';
        break;
      case ToolSection.layers:
        icon = Icons.layers_outlined;
        color = PwfColors.primaryGold;
        title = 'إدارة الطبقات';
        subtitle = 'فعّل الطبقات المطلوبة فقط وحافظ على وضوح الخريطة الحديثة.';
        break;
      case ToolSection.tools:
        icon = Icons.tune_rounded;
        color = PwfColors.royalRed;
        title = 'أدوات الخريطة';
        subtitle = 'استخدم القياس والرسم والإحداثيات عند الحاجة التشغيلية فقط.';
        break;
      case ToolSection.import:
        icon = Icons.upload_file_outlined;
        color = PwfColors.info;
        title = 'الاستيراد';
        subtitle = 'ارفع البيانات المساندة بحذر ومن خلال المسار المعتمد فقط.';
        break;
      case ToolSection.settings:
        icon = Icons.settings_outlined;
        color = const Color(0xFF64748B);
        title = 'الإعدادات';
        subtitle = 'اضبط السلوك العام للواجهة والخرائط الأساسية بصورة مركزية.';
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PwfColors.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: PwfColors.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                    height: 1.45,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerHome extends ConsumerStatefulWidget {
  const _DrawerHome();

  @override
  ConsumerState<_DrawerHome> createState() => _DrawerHomeState();
}

class _DrawerHomeState extends ConsumerState<_DrawerHome> {
  bool _layersExpanded = false;
  bool _toolsExpanded = false;
  bool _opsExpanded = false;

  void _openCartographicReading(BuildContext context) {
    final mapState = ref.read(mapNotifierProvider);
    final activeKeys = mapState.activeLayers;
    final layerNamesByKey = {
      for (final layer in mapState.gisLayers) layer.key: layer.nameAr,
    };
    final visibleNames = activeKeys
        .map((key) => layerNamesByKey[key] ?? key)
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false);

    final query = <String, String>{
      'source': 'map_toolbox',
      'from': 'toolbox_drawer',
      'zoom': mapState.zoom.toStringAsFixed(2),
      'active_count': activeKeys.length.toString(),
      'feature_count': mapState.gisFeatures.length.toString(),
      'total_layer_count': mapState.gisLayers.length.toString(),
      if (activeKeys.isNotEmpty) 'visible_layer_keys': activeKeys.join(','),
      if (visibleNames.isNotEmpty) 'visible_layer_names': visibleNames.join(','),
      if ((mapState.temporarySearchReferenceLayerKey ?? '').trim().isNotEmpty)
        'temporary_reference_layer': mapState.temporarySearchReferenceLayerKey!,
      if ((mapState.temporarySearchReferenceLayerLabel ?? '').trim().isNotEmpty)
        'temporary_reference_label': mapState.temporarySearchReferenceLayerLabel!,
      if ((mapState.settlementScopeLguCode ?? '').trim().isNotEmpty)
        'settlement_scope_lgu_code': mapState.settlementScopeLguCode!,
      if ((mapState.settlementScopeLguName ?? '').trim().isNotEmpty)
        'settlement_scope_lgu_name': mapState.settlementScopeLguName!,
    };

    context.go(Uri(path: '/admin/explorer-suite/cartography', queryParameters: query).toString());
  }

  @override
  Widget build(BuildContext context) {
    final audience = ref.watch(mapToolAudienceProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      children: [
        _AudienceBanner(audience: audience),
        const SizedBox(height: 7),
        _AccordionSection(
          title: 'الطبقات والعرض',
          icon: Icons.layers_outlined,
          accent: PwfColors.primaryGold,
          expanded: _layersExpanded,
          onToggle: () => setState(() => _layersExpanded = !_layersExpanded),
          child: Column(
            children: [
              _DrawerMenuCard(
                icon: Icons.layers_outlined,
                title: 'الطبقات',
                subtitle: 'فعّل الطبقات الضرورية فقط وراجع الشفافية والتصنيفات.',
                color: PwfColors.primaryGold,
                onTap: () => ref.read(activeToolSectionProvider.notifier).state = ToolSection.layers,
              ),
              const SizedBox(height: 6),
              const _ChecklistHint(
                items: [
                  'الافتراضي: حدود فلسطين فقط.',
                  'تجنّب تشغيل طبقات كثيرة معًا.',
                  'استخدم اللوحة الموسعة عند الحاجة فقط.',
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        _AccordionSection(
          title: 'أدوات الخريطة',
          icon: Icons.tune_rounded,
          accent: PwfColors.royalRed,
          expanded: _toolsExpanded,
          onToggle: () => setState(() => _toolsExpanded = !_toolsExpanded),
          child: Column(
            children: [
              _DrawerMenuCard(
                icon: Icons.tune_rounded,
                title: 'الأدوات التشغيلية',
                subtitle: 'القياس والرسم والإحداثيات والمقارنة بحسب الحاجة.',
                color: PwfColors.royalRed,
                onTap: () => ref.read(activeToolSectionProvider.notifier).state = ToolSection.tools,
              ),
              const SizedBox(height: 6),
              const _ChecklistHint(
                items: [
                  'استخدم القياس والرسم عند الحاجة العملية فقط.',
                  'لا تُفعّل المقارنة إلا مع طبقات مناسبة.',
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        _DrawerMenuCard(
          icon: Icons.menu_book_outlined,
          title: 'قراءة الخريطة والكارتوغرافيا',
          subtitle: 'افتح لوحة قراءة الخريطة بسياق الطبقات الظاهرة والزوم الحالي دون تغيير الطبقات.',
          color: PwfColors.primaryBlue,
          onTap: () => _openCartographicReading(context),
        ),
        const SizedBox(height: 7),
        _AccordionSection(
          title: audience.canUseManagerTools ? 'الاستيراد والإعدادات' : 'الإعدادات',
          icon: Icons.settings_outlined,
          accent: const Color(0xFF64748B),
          expanded: _opsExpanded,
          onToggle: () => setState(() => _opsExpanded = !_opsExpanded),
          child: Column(
            children: [
              if (audience.canAccessSection(ToolSection.import)) ...[
                _DrawerMenuCard(
                  icon: Icons.upload_file_outlined,
                  title: 'الاستيراد',
                  subtitle: 'رفع ملفات مكانية مساندة عبر المسار المعتمد.',
                  color: PwfColors.info,
                  onTap: () => ref.read(activeToolSectionProvider.notifier).state = ToolSection.import,
                ),
                const SizedBox(height: 6),
              ],
              _DrawerMenuCard(
                icon: Icons.settings_outlined,
                title: 'الإعدادات',
                subtitle: 'ضبط السلوك العام للواجهة والخريطة الأساسية.',
                color: const Color(0xFF64748B),
                onTap: () => ref.read(activeToolSectionProvider.notifier).state = ToolSection.settings,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AudienceBanner extends StatelessWidget {
  const _AudienceBanner({required this.audience});

  final MapToolAudience audience;

  @override
  Widget build(BuildContext context) {
    final color = audience.canUseManagerTools
        ? PwfColors.royalRed
        : (audience.canUseEmployeeTools
            ? PwfColors.primaryBlue
            : PwfColors.primaryGold);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.admin_panel_settings_outlined,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نمط الأدوات: ${audience.labelAr}',
                  style: const TextStyle(
                    color: PwfColors.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  audience.descriptionAr,
                  style: TextStyle(
                    color: PwfColors.onSurface.withValues(alpha: 0.72),
                    fontSize: 10.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
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

class _OverviewBanner extends StatelessWidget {
  const _OverviewBanner({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PwfColors.primaryBlue.withValues(alpha: 0.08),
            PwfColors.royalRed.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.grid_view_rounded, color: PwfColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PwfColors.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: PwfColors.onSurface.withValues(alpha: 0.74),
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    fontSize: 11,
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

class _AccordionSection extends StatelessWidget {
  const _AccordionSection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: PwfColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: accent, size: 15),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: PwfColors.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Icon(
                      expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: PwfColors.onSurface.withValues(alpha: 0.70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _ChecklistHint extends StatelessWidget {
  const _ChecklistHint({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PwfColors.outline.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: PwfColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: PwfColors.onSurface.withValues(alpha: 0.74),
                      fontSize: 11.8,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (item != items.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = isActive ? Colors.white : PwfColors.onSurface;
    final bg = isActive ? PwfColors.royalRed : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive
                ? PwfColors.royalRed
                : PwfColors.outline.withValues(alpha: 0.9),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: PwfColors.royalRed.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideRailButton extends StatelessWidget {
  const _SideRailButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isActive,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Material(
          color: isActive
              ? PwfColors.royalRed.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                icon,
                color: isActive
                    ? PwfColors.royalRed
                    : PwfColors.onSurface.withValues(alpha: 0.72),
                size: 19,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerMenuCard extends StatelessWidget {
  const _DrawerMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PwfColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PwfColors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: PwfColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: PwfColors.onSurface.withValues(alpha: 0.72),
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: PwfColors.onSurface.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: PwfColors.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'تم تنظيم صندوق الأدوات كمركز تحكم للطبقات والأدوات والإعدادات فقط؛ أما البحث فقد نُقل إلى تبويب مستقل داخل المستكشف الحديث، دون تغيير الطبقات عند فتح الصندوق.',
        style: TextStyle(
          color: PwfColors.onSurface.withValues(alpha: 0.72),
          fontSize: 12,
          height: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
