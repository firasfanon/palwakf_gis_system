// lib/features/platform_admin/presentation/pages/admin_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_dashboard_providers.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final email = auth.user?.email ?? '';
    final countsAsync = ref.watch(adminDashboardCountsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'لوحة المتابعة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const Spacer(),
                    if (email.isNotEmpty)
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          email,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65)),
                        ),
                      ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'تسجيل الخروج',
                      icon: const Icon(Icons.logout, color: Colors.white70),
                      onPressed: () =>
                          ref.read(authNotifierProvider.notifier).signOut(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                countsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: LinearProgressIndicator(minHeight: 4),
                  ),
                  error: (e, _) => _ErrorCard(error: e.toString()),
                  data: (c) {
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _KpiCard(
                            title: 'المستخدمون',
                            value: '${c.usersTotal}',
                            icon: Icons.people),
                        _KpiCard(
                            title: 'المستخدمون النشطون',
                            value: '${c.usersActive}',
                            icon: Icons.verified_user),
                        _KpiCard(
                            title: 'المشرفون الأعلى',
                            value: '${c.usersSuper}',
                            icon: Icons.shield),
                        _KpiCard(
                            title: 'طبقات GIS',
                            value: '${c.layersTotal}',
                            icon: Icons.layers),
                        _KpiCard(
                            title: 'عام + مفعّل',
                            value: '${c.layersPublicActive}',
                            icon: Icons.public),
                        const _KpiCard(
                            title: 'حالة GIS', value: 'متصل', icon: Icons.map),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ActionButton(
                      label: 'صفحات المستكشف',
                      icon: Icons.travel_explore_outlined,
                      onTap: () => context.go('/admin/explorer-suite'),
                    ),
                    _ActionButton(
                      label: 'إدارة الطبقات',
                      icon: Icons.layers,
                      onTap: () => context.go('/admin/gis-layers'),
                    ),
                    _ActionButton(
                      label: 'إعدادات طبقات الخريطة',
                      icon: Icons.tune,
                      onTap: () => context.go('/admin/map-layer-manager'),
                    ),
                    _ActionButton(
                      label: 'طبقات الشاشة الرئيسية',
                      icon: Icons.map_outlined,
                      onTap: () => context.go('/admin/map-runtime-layers'),
                    ),
                    _ActionButton(
                      label: 'المستكشف الذكي',
                      icon: Icons.psychology_alt_outlined,
                      onTap: () => context.go('/admin/smart-explorer'),
                    ),
                    _ActionButton(
                      label: 'مراجعة فجوات المستكشف',
                      icon: Icons.fact_check_outlined,
                      onTap: () => context.go('/admin/explorer-gap-audits'),
                    ),
                    _ActionButton(
                      label: 'مهام التدقيق',
                      icon: Icons.task_alt,
                      onTap: () => context.go('/admin/audit-tasks'),
                    ),
                    _ActionButton(
                      label: 'إدارة المستخدمين',
                      icon: Icons.people,
                      onTap: () => context.go('/admin/users'),
                    ),
                    _ActionButton(
                      label: 'العلاقات التاريخية',
                      icon: Icons.account_tree,
                      onTap: () => context.go('/admin/history-topology'),
                    ),
                    _ActionButton(
                      label: 'التقسيمات الإدارية التاريخية',
                      icon: Icons.route_outlined,
                      onTap: () => context.go('/admin/historical-admin-divisions'),
                    ),
                    _ActionButton(
                      label: 'CRUD الجداول التاريخية',
                      icon: Icons.edit_note,
                      onTap: () => context.go('/admin/history-crud'),
                    ),
                    _ActionButton(
                      label: 'الخريطة التاريخية',
                      icon: Icons.map_outlined,
                      onTap: () => context.go('/admin/history-map'),
                    ),
                    _ActionButton(
                      label: 'مرجع الوقف',
                      icon: Icons.domain_outlined,
                      onTap: () => context.go('/admin/waqf'),
                    ),
                    _ActionButton(
                      label: 'فتح الخريطة',
                      icon: Icons.map,
                      onTap: () => context.go('/map'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const Text(
                    'من هنا يمكنك التحكم في الطبقات التي تظهر للعامة عبر صفحة "إدارة طبقات GIS".\n'
                    'ملاحظة: إذا لم تظهر كل الطبقات في الإدارة، فقد تحتاج سياسة RLS تسمح للمشرف الأعلى بقراءة وتعديل gis.gis_layers.',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _KpiCard(
      {required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: PwfColors.primaryBlue.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: PwfColors.primaryGold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            Icon(icon, color: PwfColors.primaryGold, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.error_outline, color: PwfColors.royalRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'تعذر تحميل مؤشرات لوحة المتابعة: $error',
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
