import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/enums/mustakshif_content_type.dart';
import '../state/content_paged_providers.dart';
import '../utils/seo_controller.dart';
import '../widgets/content_list_view.dart';
import '../widgets/content_states.dart';
import '../widgets/historical_period_filter.dart';

class MustakshifContentScreen extends ConsumerStatefulWidget {
  const MustakshifContentScreen({
    super.key,
    required this.initialType,
    this.historicalPeriodId,
  });

  final MustakshifContentType initialType;
  final int? historicalPeriodId;

  @override
  ConsumerState<MustakshifContentScreen> createState() => _MustakshifContentScreenState();
}

class _MustakshifContentScreenState extends ConsumerState<MustakshifContentScreen> {
  late MustakshifContentType _type;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void didUpdateWidget(covariant MustakshifContentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialType != widget.initialType) {
      setState(() {
        _type = widget.initialType;
      });
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  
  void _setPeriod(int? periodId) {
    final qp = <String, String>{
      'tab': _type == MustakshifContentType.news ? 'news' : 'announcements',
    };

    if (periodId != null) {
      qp['periodId'] = periodId.toString();
    }

    context.go(Uri(path: '/mustakshif/content', queryParameters: qp).toString());
  }

void _setType(MustakshifContentType t) {
    if (t == _type) return;

    setState(() => _type = t);

    final qp = <String, String>{
      'tab': t == MustakshifContentType.news ? 'news' : 'announcements',
    };

    if (widget.historicalPeriodId != null) {
      qp['periodId'] = widget.historicalPeriodId!.toString();
    }

    context.go(Uri(path: '/mustakshif/content', queryParameters: qp).toString());
  }

  int _compareAnnouncements(dynamic a, dynamic b) {
    final aPinned = (a.isPinned == true) ? 1 : 0;
    final bPinned = (b.isPinned == true) ? 1 : 0;
    if (aPinned != bPinned) return bPinned.compareTo(aPinned);

    final aPr = (a.priority as int?) ?? 0;
    final bPr = (b.priority as int?) ?? 0;
    if (aPr != bPr) return bPr.compareTo(aPr);

    final aDate = a.publishDate as DateTime?;
    final bDate = b.publishDate as DateTime?;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  }

  @override
  Widget build(BuildContext context) {
    final args = ContentPagedArgs(
      type: _type,
      historicalPeriodId: widget.historicalPeriodId,
      pageSize: 10,
    );

    final state = ref.watch(mustakshifContentPagedProvider(args));
    final controller = ref.read(mustakshifContentPagedProvider(args).notifier);

    final title = _type == MustakshifContentType.news ? 'الأخبار' : 'الإعلانات';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeoController.setTitle('$title | مستكشف الوقف');
      SeoController.setDescription('آخر $title على مستكشف الوقف');
    });

    // ملاحظة: الهيدر/الفوتر يتم حقنهما عبر ShellRoute (WebPageScaffold)
    // لذلك هذه الشاشة تعرض المحتوى فقط بدون AppBar.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'تحديث',
                onPressed: controller.refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ContentSegmentedTabs(
            value: _type,
            onChanged: (v) {
              _searchController.clear();
              controller.setSearchQuery('');
              _setType(v);
            },
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;

              final search = _SearchField(
                controller: _searchController,
                hintText: _type == MustakshifContentType.news
                    ? 'ابحث في الأخبار...'
                    : 'ابحث في الإعلانات...',
                onChanged: controller.setSearchQuery,
                onClear: () {
                  _searchController.clear();
                  controller.setSearchQuery('');
                },
              );

              final filter = HistoricalPeriodFilter(
                value: widget.historicalPeriodId,
                onChanged: (v) => _setPeriod(v),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: search),
                    const SizedBox(width: 12),
                    SizedBox(width: 360, child: filter),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  const SizedBox(height: 12),
                  filter,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _ContentBodyPaged(
              type: _type,
              state: state,
              onRefresh: controller.refresh,
              onLoadMore: controller.loadMore,
              compareAnnouncements: _compareAnnouncements,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentBodyPaged extends StatelessWidget {
  const _ContentBodyPaged({
    required this.type,
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.compareAnnouncements,
  });

  final MustakshifContentType type;
  final ContentPagedState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final int Function(dynamic a, dynamic b) compareAnnouncements;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingInitial) {
      return const ContentLoadingState();
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return ContentErrorState(
        message: state.errorMessage!,
        onRetry: () => onRefresh(),
      );
    }

    final isSearch = state.searchQuery.trim().isNotEmpty;

    if (state.items.isEmpty) {
  final msg = isSearch
      ? 'لا توجد نتائج مطابقة ضمن العناصر المحمّلة.'
      : (type == MustakshifContentType.news ? 'لا توجد أخبار حاليًا.' : 'لا توجد إعلانات حاليًا.');

  if (isSearch && state.hasMore) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ContentEmptyState(message: msg),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onLoadMore,
              icon: const Icon(Icons.expand_more),
              label: const Text('متابعة التحميل للبحث', textDirection: TextDirection.rtl),
            ),
          ],
        ),
      ),
    );
  }

  return ContentEmptyState(message: msg);
}

    final sorted = type == MustakshifContentType.announcements
        ? (List.of(state.items)..sort(compareAnnouncements))
        : state.items;

    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= (n.metrics.maxScrollExtent - 220)) {
                if (!state.isLoadingMore && state.hasMore) {
                  onLoadMore();
                }
              }
              return false;
            },
            child: ContentListView(
              items: sorted,
              showTypeBadge: true,
              onTapItem: (item) => context.go('/mustakshif/content/${item.type.name}/${item.id}'),
            ),
          ),
        ),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          )
        else if (state.hasMore)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more),
                label: const Text('تحميل المزيد', textDirection: TextDirection.rtl),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;

        return TextField(
          controller: controller,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            hintText: hintText,
            hintTextDirection: TextDirection.rtl,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: !hasText
                ? null
                : IconButton(
                    tooltip: 'مسح',
                    onPressed: onClear,
                    icon: const Icon(Icons.close),
                  ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: onChanged,
        );
      },
    );
  }
}

class _ContentSegmentedTabs extends StatelessWidget {
  const _ContentSegmentedTabs({
    required this.value,
    required this.onChanged,
  });

  final MustakshifContentType value;
  final ValueChanged<MustakshifContentType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MustakshifContentType>(
      segments: const [
        ButtonSegment(
          value: MustakshifContentType.news,
          label: Text('أخبار', textDirection: TextDirection.rtl),
          icon: Icon(Icons.newspaper_rounded),
        ),
        ButtonSegment(
          value: MustakshifContentType.announcements,
          label: Text('إعلانات', textDirection: TextDirection.rtl),
          icon: Icon(Icons.campaign_rounded),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
    );
  }
}
