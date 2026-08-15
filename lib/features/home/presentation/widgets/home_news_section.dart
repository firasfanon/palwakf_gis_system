import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/home_providers.dart';
import '../../domain/models/home_models.dart';

enum HomeNewsSource { ministry, mustakshif }

final homeNewsSourceProvider = StateProvider<HomeNewsSource>(
  (ref) => HomeNewsSource.ministry,
);

class HomeNewsSection extends ConsumerWidget {
  const HomeNewsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(homeNewsSourceProvider);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(source: source),
            const SizedBox(height: 12),
            if (source == HomeNewsSource.ministry)
              const _MinistryDummy()
            else
              const _LatestHomeNews(),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.source});

  final HomeNewsSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'الأخبار والإعلانات',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        SegmentedButton<HomeNewsSource>(
          segments: const [
            ButtonSegment(
              value: HomeNewsSource.ministry,
              label: Text('الوزارة', textDirection: TextDirection.rtl),
            ),
            ButtonSegment(
              value: HomeNewsSource.mustakshif,
              label: Text('المستكشف', textDirection: TextDirection.rtl),
            ),
          ],
          selected: {source},
          onSelectionChanged: (set) {
            if (set.isEmpty) return;
            ref.read(homeNewsSourceProvider.notifier).state = set.first;
          },
        ),
      ],
    );
  }
}

class _MinistryDummy extends StatelessWidget {
  const _MinistryDummy();

  @override
  Widget build(BuildContext context) {
    const latestNews = [
      'خبر وزارة تجريبي: تحديث خدمات الأوقاف الإلكترونية',
      'خبر وزارة تجريبي: إعلان لقاء توعوي حول إدارة الوقف',
      'خبر وزارة تجريبي: نشر تعميم جديد',
    ];

    return Column(
      children: [
        for (final item in latestNews) ...[
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: Text(item, textDirection: TextDirection.rtl),
            dense: true,
          ),
          const Divider(height: 8),
        ],
      ],
    );
  }
}

class _LatestHomeNews extends ConsumerWidget {
  const _LatestHomeNews();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(latestNewsProvider);
    final annAsync = ref.watch(latestAnnouncementsProvider);

    return newsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(
        'خطأ في تحميل الأخبار: $e',
        textDirection: TextDirection.rtl,
      ),
      data: (news) {
        return annAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(
            'خطأ في تحميل الإعلانات: $e',
            textDirection: TextDirection.rtl,
          ),
          data: (anns) {
            final merged = <NewsItem>[
              ...anns.take(3),
              ...news.take(3),
            ];

            if (merged.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'لا يوجد محتوى منشور حاليًا',
                  textDirection: TextDirection.rtl,
                ),
              );
            }

            return Column(
              children: [
                for (final item in merged) ...[
                  _NewsTile(item: item),
                  const Divider(height: 8),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        item.isAnnouncement ? Icons.campaign_outlined : Icons.article_outlined,
      ),
      title: Text(item.title, textDirection: TextDirection.rtl),
      subtitle: item.summary == null || item.summary!.isEmpty
          ? null
          : Text(item.summary!, textDirection: TextDirection.rtl),
      dense: true,
    );
  }
}
