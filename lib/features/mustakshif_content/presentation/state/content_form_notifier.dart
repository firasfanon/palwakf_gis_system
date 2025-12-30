import 'package:flutter_riverpod/legacy.dart';

import '../../data/mustakshif_content_repository.dart';
import '../../domain/enums/mustakshif_content_type.dart';
import '../../domain/enums/mustakshif_publish_status.dart';
import '../../domain/models/mustakshif_content_item.dart';

class ContentFormState {
  const ContentFormState({
    this.isSaving = false,
    this.error,
    this.savedItem,
  });

  final bool isSaving;
  final String? error;
  final MustakshifContentItem? savedItem;

  ContentFormState copyWith({
    bool? isSaving,
    String? error,
    MustakshifContentItem? savedItem,
  }) {
    return ContentFormState(
      isSaving: isSaving ?? this.isSaving,
      error: error,
      savedItem: savedItem ?? this.savedItem,
    );
  }
}

class ContentFormNotifier extends StateNotifier<ContentFormState> {
  ContentFormNotifier(this._repo) : super(const ContentFormState());

  final MustakshifContentRepository _repo;

  Future<MustakshifContentItem?> save({
    required MustakshifContentType type,
    required String idOrEmpty,
    required String title,
    required String content,
    String? excerpt,
    required MustakshifPublishStatus status,
    DateTime? publishDate,
    int? historicalPeriodId,
    bool? isPinned,
    int? priority,
    DateTime? expireAt,
  }) async {
    try {
      state = state.copyWith(isSaving: true, error: null, savedItem: null);

      final now = DateTime.now().toUtc();
      final draft = MustakshifContentItem(
        type: type,
        id: idOrEmpty,
        title: title.trim(),
        content: content.trim(),
        excerpt: excerpt?.trim().isEmpty == true ? null : excerpt?.trim(),
        status: status,
        publishDate: publishDate,
        historicalPeriodId: historicalPeriodId,
        metadata: const {},
        createdBy: null,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        isPinned: type == MustakshifContentType.announcements ? (isPinned ?? false) : null,
        priority: type == MustakshifContentType.announcements ? (priority ?? 0) : null,
        expireAt: type == MustakshifContentType.announcements ? expireAt : null,
      );

      final saved = await _repo.upsert(item: draft);
      state = state.copyWith(isSaving: false, savedItem: saved);
      return saved;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }

  Future<bool> delete({
    required MustakshifContentType type,
    required String id,
  }) async {
    try {
      state = state.copyWith(isSaving: true, error: null);
      await _repo.softDelete(type: type, id: id);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}
