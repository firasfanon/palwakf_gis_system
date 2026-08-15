import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';

class ExplorerSuiteContractPanel extends StatelessWidget {
  const ExplorerSuiteContractPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PwfColors.primaryBlue.withValues(alpha: 0.10)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PwfColors.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.hub_outlined, color: PwfColors.primaryBlue),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'عقد حزمة المستكشفات',
                      style: TextStyle(
                        color: PwfColors.primaryBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'ثلاث واجهات مستكشف تعمل فوق محرك خريطة وأدوات مشتركة، مع سياق خاص لكل واجهة.',
                      style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ExplorerRouteCard(
                title: 'المستكشف الحديث',
                subtitle: 'الطبقات الحديثة، BBOX/Zoom، الهيئات المحلية، البلاغات وIdentify.',
                icon: Icons.map_outlined,
                color: PwfColors.primaryBlue,
                path: '/map',
              ),
              _ExplorerRouteCard(
                title: 'مستكشف التاريخ',
                subtitle: 'الفترات التاريخية، الطبقات، السلالة، المقارنة مع الحديث والوقف.',
                icon: Icons.history_edu_outlined,
                color: PwfColors.warning,
                path: '/history',
              ),
              _ExplorerRouteCard(
                title: 'التقسيمات الإدارية التاريخية',
                subtitle: 'ولاية/سنجق/قضاء/ناحية/قرية وربطها بالتقسيم الحديث.',
                icon: Icons.account_tree_outlined,
                color: PwfColors.royalRed,
                path: '/history/admin-divisions',
              ),
              _ExplorerRouteCard(
                title: 'مستكشف الوقف',
                subtitle: 'الأصول الوقفية، الوقف الأم، الربط المكاني والتاريخي وفجوات الأصل.',
                icon: Icons.domain_outlined,
                color: PwfColors.success,
                path: '/admin/waqf',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _ContractChip(label: 'Shared Map Runtime', icon: Icons.memory_outlined),
              _ContractChip(label: 'Layer Manager', icon: Icons.layers_outlined),
              _ContractChip(label: 'Feedback Workflow', icon: Icons.feedback_outlined),
              _ContractChip(label: 'Audit Tasks', icon: Icons.task_alt_outlined),
              _ContractChip(label: 'RBAC', icon: Icons.shield_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExplorerRouteCard extends StatelessWidget {
  const _ExplorerRouteCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.path,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String path;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.go(path),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF475569), height: 1.35, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractChip extends StatelessWidget {
  const _ContractChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PwfColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: PwfColors.primaryBlue, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: PwfColors.primaryBlue, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
