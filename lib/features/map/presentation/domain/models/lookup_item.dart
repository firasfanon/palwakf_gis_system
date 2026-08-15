class LookupItem {
  final String id;
  final String labelAr;
  final String? labelEn;
  final String? parentId;

  const LookupItem({
    required this.id,
    required this.labelAr,
    this.labelEn,
    this.parentId,
  });

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    String pickId() {
      final candidates = [
        json['code'],
        json['id'],
        json['key'],
        json['slug'],
        json['name_en'],
        json['name_ar'],
        json['name'],
      ];
      for (final c in candidates) {
        if (c == null) continue;
        final s = c.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return '';
    }

    String pickAr(String fallback) {
      final candidates = [
        json['name_ar'],
        json['label_ar'],
        json['title_ar'],
        json['name'],
      ];
      for (final c in candidates) {
        if (c == null) continue;
        final s = c.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return fallback;
    }

    String? pickEn() {
      final candidates = [
        json['name_en'],
        json['label_en'],
        json['title_en'],
      ];
      for (final c in candidates) {
        if (c == null) continue;
        final s = c.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return null;
    }

    String? pickParent() {
      final candidates = [
        json['governorate_code'],
        json['governorate'],
        json['gov_code'],
        json['parent_id'],
      ];
      for (final c in candidates) {
        if (c == null) continue;
        final s = c.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return null;
    }

    final id = pickId();
    return LookupItem(
      id: id,
      labelAr: pickAr(id),
      labelEn: pickEn(),
      parentId: pickParent(),
    );
  }
}
