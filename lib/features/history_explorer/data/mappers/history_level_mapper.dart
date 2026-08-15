import '../../domain/models/history_level_item.dart';

class HistoryLevelMapper {
  static HistoryLevelItem fromRow(Map<String, dynamic> row) {
    final levelKey = (row['level_key'] ?? '').toString().trim();
    return HistoryLevelItem(
      levelKey: levelKey,
      labelAr: _arabicLevelLabel(levelKey),
      labelEn: levelKey,
      isDefault: row['is_default'] == true,
      displayOrder: (row['level_order'] as num?)?.toInt() ?? 999,
      rowsCount: (row['rows_count'] as num?)?.toInt() ?? 0,
    );
  }

  static String _arabicLevelLabel(String level) {
    switch (level.toLowerCase()) {
      case 'welaya':
        return 'ولاية';
      case 'sonjoq':
        return 'سنجق';
      case 'lewa':
        return 'لواء';
      case 'kada':
      case 'qada':
        return 'قضاء';
      case 'westbank_gaza':
        return 'الضفة/غزة';
      case 'governorate':
        return 'محافظة';
      case 'community':
        return 'تجمع';
      case 'lgu':
        return 'هيئة محلية';
      default:
        return level;
    }
  }
}
