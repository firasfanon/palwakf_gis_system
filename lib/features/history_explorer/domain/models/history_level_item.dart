class HistoryLevelItem {
  final String levelKey;
  final String labelAr;
  final String labelEn;
  final bool isDefault;
  final int displayOrder;
  final int rowsCount;

  const HistoryLevelItem({
    required this.levelKey,
    required this.labelAr,
    required this.labelEn,
    required this.isDefault,
    required this.displayOrder,
    required this.rowsCount,
  });

  String get displayLabel {
    final ar = labelAr.trim();
    if (ar.isNotEmpty) return ar;
    final en = labelEn.trim();
    if (en.isNotEmpty) return en;
    return levelKey;
  }
}
