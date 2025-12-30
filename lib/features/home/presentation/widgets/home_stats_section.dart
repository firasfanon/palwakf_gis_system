import 'package:flutter/material.dart';

/// قسم الإحصاءات السريعة في الرئيسية
class HomeStatsSection extends StatelessWidget {
  const HomeStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0D47A1);
    const Color accent = Color(0xFFFFC107);

    final stats = <_HomeStatItem>[
      const _HomeStatItem(
        icon: Icons.layers_outlined,
        label: 'عدد الأراضي الوقفية',
        value: '1,250+',
      ),
      const _HomeStatItem(
        icon: Icons.map_outlined,
        label: 'المحافظات المغطاة',
        value: '16',
      ),
      const _HomeStatItem(
        icon: Icons.bolt_outlined,
        label: 'مشاريع استثمارية/وقف شمسي',
        value: '38',
      ),
      const _HomeStatItem(
        icon: Icons.update,
        label: 'آخر تحديث للبيانات',
        value: '2025-11-01',
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'لمحة إحصائية سريعة',
            style: TextStyle(
              color: primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: stats
                .map(
                  (s) => SizedBox(
                width: 260,
                child: _StatCard(
                  item: s,
                  primary: primary,
                  accent: accent,
                ),
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HomeStatItem {
  final IconData icon;
  final String label;
  final String value;

  const _HomeStatItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _StatCard extends StatelessWidget {
  final _HomeStatItem item;
  final Color primary;
  final Color accent;

  const _StatCard({
    required this.item,
    required this.primary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    color: primary.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: TextStyle(
                    color: accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
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
