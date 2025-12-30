enum MustakshifPublishStatus {
  draft,
  published,
  archived,
}

extension MustakshifPublishStatusX on MustakshifPublishStatus {
  /// القيمة المخزنة في قاعدة البيانات (تطابق enum value في Postgres)
  String get value => name;

  /// تسمية عربية للاستخدام في الواجهة
  String get labelAr {
    switch (this) {
      case MustakshifPublishStatus.draft:
        return 'مسودة';
      case MustakshifPublishStatus.published:
        return 'منشور';
      case MustakshifPublishStatus.archived:
        return 'مؤرشف';
    }
  }
}

/// تحويل قيمة DB (String) إلى enum
MustakshifPublishStatus mustakshifPublishStatusFromValue(String? value) {
  switch (value) {
    case 'published':
      return MustakshifPublishStatus.published;
    case 'archived':
      return MustakshifPublishStatus.archived;
    case 'draft':
    default:
      return MustakshifPublishStatus.draft;
  }
}
