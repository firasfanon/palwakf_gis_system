import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../mustakshif_content/domain/enums/mustakshif_content_type.dart';
import '../../../mustakshif_content/presentation/state/content_list_providers.dart';
import '../../../mustakshif_content/presentation/widgets/content_card.dart';

enum HomeNewsSource { ministry, mustakshif }

class HomeNewsSourceNotifier extends StateNotifier<HomeNewsSource> {
  HomeNewsSourceNotifier() : super(HomeNewsSource.ministry);

  void setSource(HomeNewsSource source) => state = source;
}

final homeNewsSourceProvider =
StateNotifierProvider<HomeNewsSourceNotifier, HomeNewsSource>(
      (ref) => HomeNewsSourceNotifier(),
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
              const _MustakshifLatest(),
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
            ref.read(homeNewsSourceProvider.notifier).setSource(set.first);
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
    // Placeholder until ministry news table is wired.
    const latestNews = [
      'خبر وزارة (تجريبي): تحديث خدمات الأوقاف الإلكترونية',
      'خبر وزارة (تجريبي): إعلان لقاء توعوي حول إدارة الوقف',
      'خبر وزارة (تجريبي): نشر تعميم جديد',
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

class _MustakshifLatest extends ConsumerWidget {
  const _MustakshifLatest();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(
      mustakshifContentListProvider(
        const ContentListArgs(type: MustakshifContentType.news, adminMode: false),
      ),
    );

    final annAsync = ref.watch(
      mustakshifContentListProvider(
        const ContentListArgs(
          type: MustakshifContentType.announcements,
          adminMode: false,
        ),
      ),
    );

    return newsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(
        'خطأ في تحميل أخبار المستكشف: $e',
        textDirection: TextDirection.rtl,
      ),
      data: (news) {
        return annAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(
            'خطأ في تحميل إعلانات المستكشف: $e',
            textDirection: TextDirection.rtl,
          ),
          data: (anns) {
            // دمج سريع: نأخذ آخر 3 من كل نوع (تقدر تغيرها لاحقًا)
            final merged = <dynamic>[
              ...anns.take(3),
              ...news.take(3),
            ];

            if (merged.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('لا يوجد محتوى منشور حاليًا', textDirection: TextDirection.rtl),
              );
            }

            return Column(
              children: merged
                  .map(
                    (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ContentCard(item: item, showTypeBadge: true),
                ),
              )
                  .toList(),
            );
          },
        );
      },
    );
  }
}
