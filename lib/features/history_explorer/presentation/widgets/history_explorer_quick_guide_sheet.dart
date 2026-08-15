import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/pwf_card.dart';

Future<void> showHistoryExplorerQuickGuide(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ListView(
                children: const [
                  _GuideHero(),
                  SizedBox(height: 12),
                  _GuideSection(
                    title: 'كيف أبدأ؟',
                    items: [
                      'اختر نمط الاستكشاف: من التاريخ أو من الحديث أو من الوقف.',
                      'حدّد الفترة التاريخية ثم المستوى الإداري إن كنت تعمل من التاريخ.',
                      'استخدم البحث للعثور على كيان تاريخي أو مرجع حديث أو أصل وقفي.',
                    ],
                  ),
                  SizedBox(height: 12),
                  _GuideSection(
                    title: 'كيف أقرأ الخريطة؟',
                    items: [
                      'الأشكال/الحدود الأساسية تمثل الكيان التاريخي الأصلي للفترة المختارة.',
                      'العناصر الحديثة تظهر كمرجع تفسيري ولا يجب قراءتها ككيانات أصيلة لنفس الزمن التاريخي.',
                      'الأصول الوقفية تظهر كنهاية أو نقطة انطلاق للمسار الوقفي الإداري.',
                    ],
                  ),
                  SizedBox(height: 12),
                  _GuideSection(
                    title: 'ما الفرق بين أنواع الفترات؟',
                    items: [
                      'الفترة الوصفية: شرح وسياق تاريخي أكثر من كونها طبقة تشغيلية.',
                      'الفترة المرجعية: مفيدة للفهم والمقارنة ولكنها ليست Overlay تشغيليًا كاملًا.',
                      'الفترة التشغيلية: تملك عناصر مكانية قابلة للرسم والتفاعل.',
                    ],
                  ),
                  SizedBox(height: 12),
                  _GuideSection(
                    title: 'كيف أقرأ السلالة؟',
                    items: [
                      'لوحة السلالة على اليسار تعرض منهج الحل الحالي: RPC سيادي أو Fallback مرن.',
                      'ابدأ من العقدة الأساسية ثم اقرأ الامتدادات الحديثة فالأصول الوقفية المرتبطة.',
                      'في حال كانت بعض البيانات ناقصة، ستظهر ملاحظات توضح أن الربط الحالي تفسيري أو مرحلي.',
                    ],
                  ),
                  SizedBox(height: 12),
                  _GuideSection(
                    title: 'ماذا أفعل إذا لم تظهر طبقة؟',
                    items: [
                      'قد تكون الفترة وصفية أو مرجعية بلا Overlay تشغيلي.',
                      'قد يكون المستوى الإداري المختار لا يملك عناصر للفترة الحالية.',
                      'قد تكون الفلاتر أخفت جميع النتائج أو أن بيانات الربط ما زالت قيد الإثراء.',
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _GuideHero extends StatelessWidget {
  const _GuideHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PwfColors.primaryBlue.withValues(alpha: 0.96),
            const Color(0xFF0B1220),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'دليل الاستخدام السريع',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'هذه الصفحة لا تعرض طبقات تاريخية فقط، بل تساعدك على تتبّع الأصل التاريخي والسلسلة الإدارية والمرجع الحديث وصولًا إلى الأصل الوقفي الحديث.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.8,
                ),
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return PwfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: PwfColors.primaryBlue,
                ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.check_circle_outline, size: 18, color: PwfColors.success),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
