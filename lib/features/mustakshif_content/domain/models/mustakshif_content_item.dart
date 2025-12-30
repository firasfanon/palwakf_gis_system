import '../enums/mustakshif_content_type.dart';
import '../enums/mustakshif_publish_status.dart';

class MustakshifContentItem {
  const MustakshifContentItem({
    required this.type,
    required this.id,
    required this.title,
    required this.content,
    this.excerpt,
    required this.status,
    this.publishDate,
    this.historicalPeriodId,
    required this.metadata,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    // Announcements-only (nullable for news)
    this.isPinned,
    this.priority,
    this.expireAt,
  });

  final MustakshifContentType type;

  final String id;
  final String title;
  final String content;
  final String? excerpt;

  final MustakshifPublishStatus status;
  final DateTime? publishDate;

  final int? historicalPeriodId;
  final Map<String, dynamic> metadata;

  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Announcements-only
  final bool? isPinned;
  final int? priority;
  final DateTime? expireAt;

  bool get isDeleted => deletedAt != null;

  MustakshifContentItem copyWith({
    String? title,
    String? content,
    String? excerpt,
    MustakshifPublishStatus? status,
    DateTime? publishDate,
    int? historicalPeriodId,
    Map<String, dynamic>? metadata,
    bool? isPinned,
    int? priority,
    DateTime? expireAt,
    DateTime? deletedAt,
  }) {
    return MustakshifContentItem(
      type: type,
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      excerpt: excerpt ?? this.excerpt,
      status: status ?? this.status,
      publishDate: publishDate ?? this.publishDate,
      historicalPeriodId: historicalPeriodId ?? this.historicalPeriodId,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isPinned: isPinned ?? this.isPinned,
      priority: priority ?? this.priority,
      expireAt: expireAt ?? this.expireAt,
    );
  }

  static MustakshifContentItem fromMap(
    MustakshifContentType type,
    Map<String, dynamic> map,
  ) {
    DateTime? _dt(String? v) => v == null ? null : DateTime.parse(v);
    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }
    return MustakshifContentItem(
      type: type,
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      content: (map['content'] ?? '').toString(),
      excerpt: map['excerpt']?.toString(),
      status: mustakshifPublishStatusFromValue(map['status']?.toString()),
      publishDate: _dt(map['publish_date']?.toString()),
      historicalPeriodId: _toInt(map['historical_period_id']),
      metadata: (map['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      createdBy: map['created_by']?.toString(),
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
      deletedAt: _dt(map['deleted_at']?.toString()),
      isPinned: map['is_pinned'] as bool?,
      priority: map['priority'] as int?,
      expireAt: _dt(map['expire_at']?.toString()),
    );
  }

  Map<String, dynamic> toUpsertMap() {
    // NOTE: Do not set created_at/updated_at from client; DB triggers handle them.
    final map = <String, dynamic>{
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'status': status.value,
      'publish_date': publishDate?.toUtc().toIso8601String(),
      'historical_period_id': historicalPeriodId,
      'metadata': metadata,
    };

    // Include announcements-only fields only when type is announcements.
    if (type == MustakshifContentType.announcements) {
      map['is_pinned'] = isPinned ?? false;
      map['priority'] = priority ?? 0;
      map['expire_at'] = expireAt?.toUtc().toIso8601String();
    }

    return map;
  }
}
