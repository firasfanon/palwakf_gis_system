import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/pwf_card.dart';
import '../../application/state/history_explorer_state.dart';
import '../../domain/enums/history_explorer_mode.dart';
import '../../domain/enums/history_period_kind.dart';

class HistoryExplorerStoryCards extends StatelessWidget {
  const HistoryExplorerStoryCards({super.key, required this.state});

  final HistoryExplorerState state;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StoryCard(
          width: 390,
          color: _periodAccent(state),
          icon: Icons.menu_book_outlined,
          title: 'كيف تقرأ هذه الصفحة؟',
          body: _readingBody(state),
          bullets: _readingBullets(state),
        ),
        _StoryCard(
          width: 390,
          color: PwfColors.primaryGold,
          icon: Icons.north_east_outlined,
          title: 'الخطوة التالية المقترحة',
          body: _nextStepBody(state),
          bullets: _nextStepBullets(state),
        ),
      ],
    );
  }

  Color _periodAccent(HistoryExplorerState state) {
    switch (state.selectedPeriodKind) {
      case HistoryPeriodKind.descriptive:
        return PwfColors.primaryBlue;
      case HistoryPeriodKind.reference:
        return PwfColors.warning;
      case HistoryPeriodKind.drawable:
        return PwfColors.success;
      case HistoryPeriodKind.unknown:
        return PwfColors.royalRed;
    }
  }

  String _readingBody(HistoryExplorerState state) {
    final summary = state.periodMeta?.summaryAr ?? state.selectedPeriod?.summaryAr;
    if (summary?.trim().isNotEmpty == true) return summary!;
    switch (state.mode) {
      case HistoryExplorerMode.historical:
        return 'ابدأ من الفترة ثم اختر عنصرًا تاريخيًا واضحًا من الخريطة أو اللوحة الجانبية.';
      case HistoryExplorerMode.modern:
        return 'ابدأ من المرجع الحديث ثم استخدم السلالة لفهم صلته بالجذر التاريخي.';
      case HistoryExplorerMode.waqf:
        return 'ابدأ من الأصل الوقفي الحديث ثم اقرأ الخريطة باعتبارها مسارًا عكسيًا نحو الجذر التاريخي.';
    }
  }

  List<String> _readingBullets(HistoryExplorerState state) {
    return [
      'الأزرق يعبّر غالبًا عن الكيان التاريخي الأصلي.',
      'الذهبي يعبّر عن المرجع الحديث أو القراءة التفسيرية.',
      'الأحمر يبرز الأصل الوقفي أو نهاية المسار.',
      if (state.boundariesOnly) 'وضع الحدود فقط مفعّل حاليًا.',
    ];
  }

  String _nextStepBody(HistoryExplorerState state) {
    if (state.selectedPeriod == null) {
      return 'اختر فترة أولًا ثم حدّد مستوى إداري مناسب قبل اختيار عنصر من الخريطة.';
    }
    if (state.selectedPeriodKind == HistoryPeriodKind.descriptive) {
      return 'هذه فترة وصفية، لذا الأفضل قراءتها كبوابة فهم ثم الانتقال إلى فترة تشغيلية قريبة.';
    }
    if (state.selectedPeriodKind == HistoryPeriodKind.reference) {
      return 'هذه فترة مرجعية؛ استخدمها للمقارنة ثم انتقل إلى فترة تشغيلية لرؤية الامتداد المكاني.';
    }
    if (state.selectedFeature == null && state.selectedModernContext == null && state.selectedWaqfAsset == null) {
      return 'الفترة الحالية قابلة للرسم؛ الخطوة التالية الآن هي اختيار عنصر واضح من الخريطة.';
    }
    return 'بعد تحديد العنصر، اقرأ السلالة أولًا ثم فعّل المرجع الحديث أو الأصل الوقفي عند الحاجة.';
  }

  List<String> _nextStepBullets(HistoryExplorerState state) {
    switch (state.mode) {
      case HistoryExplorerMode.historical:
        return const ['اختر عنصرًا تاريخيًا.', 'افتح لوحة السلالة.'];
      case HistoryExplorerMode.modern:
        return const ['اختر تجمعًا أو محافظة.', 'اقرأ الجذر التاريخي المقابل.'];
      case HistoryExplorerMode.waqf:
        return const ['اختر أصلًا وقفيًا.', 'اصعد إلى الجذر التاريخي عبر السلالة.'];
    }
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.width,
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
    required this.bullets,
  });

  final double width;
  final Color color;
  final IconData icon;
  final String title;
  final String body;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: PwfCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.8),
            ),
            if (bullets.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...bullets.take(2).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(Icons.check_circle_outline, size: 17, color: color),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
