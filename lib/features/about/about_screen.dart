import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'حول مستكشف الوقف',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 8),
              Text(
                'منصة وطنية تساعد على توثيق وإدارة واستكشاف الأوقاف الفلسطينية عبر واجهة ويب تفاعلية مرتبطة بقاعدة بيانات وطبقات GIS.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),

              _SectionCard(
                title: 'الرؤية',
                child: Text(
                  'تعزيز الشفافية وحماية الوقف وتيسير الوصول للمعلومات، وربط البيانات الوقفية بالسياق التاريخي والجغرافي لخدمة التنمية والاستدامة.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'الرسالة',
                child: Text(
                  'تقديم نظام حديث لإدارة محتوى الوقف (أخبار/إعلانات/وثائق)، وربطه مع الخرائط والطبقات التاريخية والأرشفة، مع صلاحيات إدارية واضحة.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),

              _SectionCard(
                title: 'المكونات الرئيسية',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bullet('واجهة عامة RTL مع هيدر/فوتر موحدين.'),
                    _Bullet('وحدة محتوى (أخبار/إعلانات) مع تفاصيل + بحث + Pagination.'),
                    _Bullet('لوحة تحكم إدارية (مستخدمين/إعدادات/محتوى).'),
                    _Bullet('تكامل Supabase + Postgres/PostGIS + خرائط flutter_map (قيد التوسع).'),
                    _Bullet('وحدة تاريخ (فترات/وحدات إدارية) للربط مع المحتوى وGIS.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _SectionCard(
                title: 'الهوية البصرية',
                child: Text(
                  'اعتماد ألوان الأزرق والذهبي كأساس، مع الأحمر الملكي (#B22222) للتنبيهات والإجراءات الحساسة.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 8),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
