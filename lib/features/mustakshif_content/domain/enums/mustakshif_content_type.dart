enum MustakshifContentType {
  news,
  announcements;

  String get tableName {
    switch (this) {
      case MustakshifContentType.news:
        return 'mustakshif_news';
      case MustakshifContentType.announcements:
        return 'mustakshif_announcements';

    }
  }

  String get labelAr {
    switch (this) {
      case MustakshifContentType.news:
        return 'أخبار المستكشف';
      case MustakshifContentType.announcements:
        return 'إعلانات المستكشف';
    }
  }
}
