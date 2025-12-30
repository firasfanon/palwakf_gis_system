import 'package:flutter/material.dart';

/// قسم الخدمات الإلكترونية / الروابط المهمة
class HomeServicesSection extends StatelessWidget {
  const HomeServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF0D47A1);

    final services = [
      _ServiceItem(
        icon: Icons.map_outlined,
        title: 'الخريطة التفاعلية للأوقاف',
        subtitle: 'استعراض الأراضي الوقفية على خريطة GIS تفاعلية.',
      ),
      _ServiceItem(
        icon: Icons.article_outlined,
        title: 'سجل الأراضي الوقفية',
        subtitle: 'بحث متقدم في بيانات قطع الأراضي والوثائق.',
      ),
      _ServiceItem(
        icon: Icons.gavel_outlined,
        title: 'متابعة القضايا الوقفية',
        subtitle: 'استعراض القضايا والإجراءات القانونية المرتبطة بالأوقاف.',
      ),
      _ServiceItem(
        icon: Icons.solar_power_outlined,
        title: 'مشروع جسور الاستدامة',
        subtitle: 'متابعة مشاريع الوقف الشمسي وترشيد استهلاك الطاقة.',
      ),
      _ServiceItem(
        icon: Icons.account_balance_outlined,
        title: 'خدمات الوزارة الإلكترونية',
        subtitle: 'روابط مباشرة للخدمات الإلكترونية الرسمية.',
      ),
      _ServiceItem(
        icon: Icons.contact_support_outlined,
        title: 'دعم واستفسارات',
        subtitle: 'نموذج للتواصل مع مديريات الأوقاف.',
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الخدمات الإلكترونية والروابط المهمة',
            style: TextStyle(
              color: primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount =
              constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 3.2,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final s = services[index];
                  return _ServiceCard(item: s, primary: primary);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceItem {
  final IconData icon;
  final String title;
  final String subtitle;

  _ServiceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _ServiceCard extends StatelessWidget {
  final _ServiceItem item;
  final Color primary;

  const _ServiceCard({
    required this.item,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: اربط كل خدمة بالراوتر المناسب عند تجهيز المسارات
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.95),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
