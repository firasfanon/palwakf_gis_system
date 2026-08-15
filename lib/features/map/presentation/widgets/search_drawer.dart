// lib/features/map/presentation/widgets/search_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import 'toolbox/tool_sections/search_section.dart';
import 'toolbox/tool_sections/map_tools_section.dart';
import 'toolbox/tool_sections/import_section.dart';
import 'toolbox/tool_sections/settings_section.dart';
import 'toolbox/tool_sections/layers_section.dart';

final toolboxExpandedProvider = StateProvider<bool>((ref) => true);
final activeToolSectionProvider =
    StateProvider<ToolSection?>((ref) => ToolSection.search);

enum ToolSection { search, layers, tools, import, settings }

class ToolboxDrawer extends ConsumerWidget {
  const ToolboxDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(toolboxExpandedProvider);
    final activeSection = ref.watch(activeToolSectionProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: isExpanded ? 380 : 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: isExpanded
            ? _buildExpandedPanel(ref, activeSection)
            : _buildCollapsedPanel(ref),
      ),
    );
  }

  Widget _buildCollapsedPanel(WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildToolButton(
          icon: Icons.search,
          tooltip: 'البحث العقاري',
          isActive: ref.watch(activeToolSectionProvider) == ToolSection.search,
          onTap: () => _toggleSection(ref, ToolSection.search),
        ),
        _buildToolButton(
          icon: Icons.layers,
          tooltip: 'الطبقات',
          isActive: ref.watch(activeToolSectionProvider) == ToolSection.layers,
          onTap: () => _toggleSection(ref, ToolSection.layers),
        ),
        _buildToolButton(
          icon: Icons.construction,
          tooltip: 'أدوات الخريطة',
          isActive: ref.watch(activeToolSectionProvider) == ToolSection.tools,
          onTap: () => _toggleSection(ref, ToolSection.tools),
        ),
        _buildToolButton(
          icon: Icons.upload_file,
          tooltip: 'استيراد البيانات',
          isActive: ref.watch(activeToolSectionProvider) == ToolSection.import,
          onTap: () => _toggleSection(ref, ToolSection.import),
        ),
        _buildToolButton(
          icon: Icons.settings,
          tooltip: 'الإعدادات',
          isActive:
              ref.watch(activeToolSectionProvider) == ToolSection.settings,
          onTap: () => _toggleSection(ref, ToolSection.settings),
        ),
        const Spacer(),
        _buildToolButton(
          icon: Icons.chevron_right,
          tooltip: 'إغلاق',
          onTap: () => ref.read(toolboxExpandedProvider.notifier).state = true,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildExpandedPanel(WidgetRef ref, ToolSection? activeSection) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: PwfColors.primaryBlue,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.construction, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'صندوق الأدوات',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  ref.read(toolboxExpandedProvider.notifier).state = false;
                  ref.read(activeToolSectionProvider.notifier).state = null;
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: activeSection == null
              ? _buildMainMenu(ref)
              : _buildActiveSection(activeSection),
        ),
      ],
    );
  }

  Widget _buildMainMenu(WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMenuCard(
          icon: Icons.search,
          title: 'البحث العقاري الوقفي',
          subtitle: 'بحث بالمفتاح PWF أو الحوض/القطعة',
          color: PwfColors.primaryBlue,
          onTap: () => ref.read(activeToolSectionProvider.notifier).state =
              ToolSection.search,
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          icon: Icons.layers,
          title: 'الطبقات',
          subtitle: 'إدارة طبقات الخريطة والخريطة الأساس',
          color: PwfColors.primaryGold,
          onTap: () => ref.read(activeToolSectionProvider.notifier).state =
              ToolSection.layers,
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          icon: Icons.construction,
          title: 'أدوات الخريطة',
          subtitle: 'قياس، رسم، إحداثيات، مشاركة',
          color: PwfColors.success,
          onTap: () => ref.read(activeToolSectionProvider.notifier).state =
              ToolSection.tools,
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          icon: Icons.upload_file,
          title: 'استيراد البيانات',
          subtitle: 'KML، KMZ، Shapefile، Excel، CSV',
          color: PwfColors.royalRed,
          onTap: () => ref.read(activeToolSectionProvider.notifier).state =
              ToolSection.import,
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          icon: Icons.settings,
          title: 'الإعدادات',
          subtitle: 'الوضع الليلي، اللغة، الخريطة الأساس',
          color: Colors.grey.shade700,
          onTap: () => ref.read(activeToolSectionProvider.notifier).state =
              ToolSection.settings,
        ),
      ],
    );
  }

  Widget _buildActiveSection(ToolSection section) {
    switch (section) {
      case ToolSection.search:
        return const SearchSection();
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

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive
            ? PwfColors.primaryBlue.withValues(alpha: 0.1)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: isActive ? PwfColors.primaryBlue : Colors.grey.shade700,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSection(WidgetRef ref, ToolSection section) {
    ref.read(toolboxExpandedProvider.notifier).state = true;
    ref.read(activeToolSectionProvider.notifier).state = section;
  }
}
