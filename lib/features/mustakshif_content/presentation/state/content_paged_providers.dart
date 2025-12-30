import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/enums/mustakshif_content_type.dart';
import '../../domain/models/mustakshif_content_item.dart';
import 'content_list_providers.dart';

class ContentPagedArgs {
  const ContentPagedArgs({
    required this.type,
    this.historicalPeriodId,
    this.pageSize = 10,
  });

  final MustakshifContentType type;
  final int? historicalPeriodId;
  final int pageSize;

  @override
  bool operator ==(Object other) =>
      other is ContentPagedArgs &&
      other.type == type &&
      other.historicalPeriodId == historicalPeriodId &&
      other.pageSize == pageSize;

  @override
  int get hashCode => Object.hash(type, historicalPeriodId, pageSize);
}

class ContentPagedState {
  const ContentPagedState({
    required this.items,
    required this.isLoadingInitial,
    required this.isLoadingMore,
    required this.hasMore,
    required this.searchQuery,
    this.errorMessage,
  });

  final List<MustakshifContentItem> items;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMore;
  final String searchQuery;
  final String? errorMessage;

  ContentPagedState copyWith({
    List<MustakshifContentItem>? items,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMore,
    String? searchQuery,
    String? errorMessage,
  }) {
    return ContentPagedState(
      items: items ?? this.items,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }

  static ContentPagedState initial() => const ContentPagedState(
        items: <MustakshifContentItem>[],
        isLoadingInitial: true,
        isLoadingMore: false,
        hasMore: true,
        searchQuery: '',
        errorMessage: null,
      );
}

class ContentPagedController extends StateNotifier<ContentPagedState> {
  ContentPagedController(this.ref, this.args) : super(ContentPagedState.initial()) {
    _loadInitial();
  }

  final Ref ref;
  final ContentPagedArgs args;

  static const Duration _debounceDuration = Duration(milliseconds: 350);

  int _offset = 0;
  bool _disposed = false;
  Timer? _debounce;

  Future<void> refresh() async {
    _offset = 0;
    state = ContentPagedState.initial();
    await _loadInitial();
  }

  void setSearchQuery(String q) {
    final normalized = q.trim();
    if (normalized == state.searchQuery) return;

    // Debounce inside controller for safety (UI also debounces).
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () async {
      if (_disposed) return;
      _offset = 0;
      state = ContentPagedState.initial().copyWith(
        isLoadingInitial: true,
        searchQuery: normalized,
      );
      await _loadInitial();
    });
  }

  Future<void> loadMore() async {
    if (state.isLoadingInitial || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    try {
      final repo = ref.read(mustakshifContentRepositoryProvider);
      final fetched = await repo.fetchList(
        type: args.type,
        adminMode: false,
        historicalPeriodId: args.historicalPeriodId,
        limit: args.pageSize,
        offset: _offset,
      );

      final filtered = _applyLocalSearch(fetched, state.searchQuery);

      final nextItems = [...state.items, ...filtered];
      final hasMore = fetched.length >= args.pageSize;

      _offset += fetched.length;

      if (_disposed) return;
      state = state.copyWith(
        items: nextItems,
        isLoadingMore: false,
        hasMore: hasMore,
      );
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _loadInitial() async {
    state = state.copyWith(isLoadingInitial: true, errorMessage: null);

    try {
      final repo = ref.read(mustakshifContentRepositoryProvider);

      final fetched = await repo.fetchList(
        type: args.type,
        adminMode: false,
        historicalPeriodId: args.historicalPeriodId,
        limit: args.pageSize,
        offset: 0,
      );

      final filtered = _applyLocalSearch(fetched, state.searchQuery);

      _offset = fetched.length;
      final hasMore = fetched.length >= args.pageSize;

      if (_disposed) return;
      state = state.copyWith(
        items: filtered,
        isLoadingInitial: false,
        hasMore: hasMore,
      );
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        isLoadingInitial: false,
        errorMessage: e.toString(),
      );
    }
  }

  List<MustakshifContentItem> _applyLocalSearch(List<MustakshifContentItem> list, String q) {
    final query = q.trim();
    if (query.isEmpty) return list;

    final lower = query.toLowerCase();
    return list.where((item) {
      final title = (item.title ?? '').toLowerCase();
      final excerpt = (item.excerpt ?? '').toLowerCase();
      final content = (item.content ?? '').toLowerCase();
      return title.contains(lower) || excerpt.contains(lower) || content.contains(lower);
    }).toList();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}

final mustakshifContentPagedProvider =
    StateNotifierProvider.autoDispose.family<ContentPagedController, ContentPagedState, ContentPagedArgs>(
  (ref, args) => ContentPagedController(ref, args),
);
