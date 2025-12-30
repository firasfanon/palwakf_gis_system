import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums/mustakshif_content_type.dart';
import '../state/content_details_providers.dart';
import '../widgets/safe_content_body.dart';
import '../utils/seo_controller.dart';
import '../widgets/content_card.dart';

class MustakshifContentDetailsScreen extends ConsumerWidget {
  const MustakshifContentDetailsScreen({
    super.key,
    required this.type,
    required this.id,
  });

  final MustakshifContentType type;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItem = ref.watch(
      mustakshifContentByIdProvider(ContentDetailsArgs(type: type, id: id)),
    );

    // ملاحظة: الهيدر/الفوتر يتم حقنهما عبر ShellRoute (WebPageScaffold)
    // لذلك هذه الشاشة تعرض المحتوى فقط بدون AppBar.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'رجوع',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  type == MustakshifContentType.news ? 'تفاصيل الخبر' : 'تفاصيل الإعلان',
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'تحديث',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.invalidate(
                  mustakshifContentByIdProvider(ContentDetailsArgs(type: type, id: id)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: asyncItem.when(
        data: (item) {
          if (item == null) {
            return const _NotFoundState();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final t = (item.title ?? '').trim();
            final base = type == MustakshifContentType.news ? 'الأخبار' : 'الإعلانات';
            final title = t.isEmpty ? 'تفاصيل $base' : '$t | مستكشف الوقف';
            final desc = (item.excerpt ?? item.content).trim();
            final shortDesc = desc.length > 180 ? '${desc.substring(0, 180)}…' : desc;
            SeoController.setOpenGraph(
              title: title,
              description: shortDesc.isEmpty ? null : shortDesc,
              url: '/mustakshif/content/${item.type.name}/${item.id}',
            );
          });

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Summary card (re-uses the same visual language as list)
              ContentCard(item: item, onTap: null, showTypeBadge: true),
              const SizedBox(height: 10),
              SafeContentBody(text: item.content),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _DetailsErrorState(
          error: e,
          onRetry: () => ref.invalidate(
            mustakshifContentByIdProvider(ContentDetailsArgs(type: type, id: id)),
          ),
        ),
      ),
          ),
        ],
      ),
    );
  }
}

class _DetailsErrorState extends StatelessWidget {
  const _DetailsErrorState({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'تعذر تحميل التفاصيل',
              textDirection: TextDirection.rtl,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textDirection: TextDirection.rtl,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة', textDirection: TextDirection.rtl),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFoundState extends StatelessWidget {
  const _NotFoundState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'المحتوى غير موجود',
              textDirection: TextDirection.rtl,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'قد يكون تم حذف الخبر/الإعلان أو أن الرابط غير صحيح.',
              textDirection: TextDirection.rtl,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('رجوع', textDirection: TextDirection.rtl),
            ),
          ],
        ),
      ),
    );
  }
}
