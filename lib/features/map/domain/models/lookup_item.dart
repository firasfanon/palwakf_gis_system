// lib/features/map/domain/models/lookup_item.dart

/// Generic lookup item used for dropdowns (governorates / LGUs / communities).
///
/// Designed to be resilient to varying DB column names.
class LookupItem {
  final String code;
  final String labelAr;
  final String? labelEn;

  /// Optional parent link (e.g. lgu.governorate_code, community.lgu_code).
  final String? parentCode;

  const LookupItem({
    required this.code,
    required this.labelAr,
    this.labelEn,
    this.parentCode,
  });

  String get bestLabel => labelAr.isNotEmpty ? labelAr : (labelEn ?? code);

  static String _pickString(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    // GIS lookup tables often expose a generic row id/gid beside the real
    // sovereign code. Prefer administrative numbers first so dropdowns do not
    // pass a geometry-row id to map focus/search RPCs.
    final code = _pickString(json, const [
      'code',
      'governorate_no',
      'gov_no',
      'lgusb_no',
      'lgu_no',
      'lgus_code',
      'lgus_xcode',
      'community_no',
      'community_code',
      'locality_code',
      'municipality_code',
      'lgu_code',
      'governorate_code',
      'gov_code',
      'local_body_code',
      'key',
      'slug',
      'id',
      'gid',
      'name', // last resort
    ]);

    final labelAr = _pickString(json, const [
      'name_ar',
      'ar_name',
      'label_ar',
      'title_ar',
      'governorate_name_ar',
      'gov_name_ar',
      'governorate',
      'governoraten',
      'lgusn',
      'lgun',
      'community_name_ar',
      'communityn',
      'locality_name_ar',
      'municipality_name_ar',
      'lgu_name_ar',
      'local_body_name_ar',
      'locality_name',
      'municipality_name',
      'lgu_name',
      'name',
    ]);

    final labelEnRaw = _pickString(json, const [
      'name_en',
      'en_name',
      'label_en',
      'title_en',
      'governorate_name_en',
      'community_name_en',
      'locality_name_en',
      'municipality_name_en',
      'lgu_name_en',
    ]);

    final parent = _pickString(json, const [
      'parent_code',
      'governorate_no',
      'gov_no',
      'governorate_code',
      'gov_code',
      'governorate',
      'governorate_name_ar',
      'lgusb_no',
      'lgu_no',
      'lgu_code',
      'municipality_code',
      'community_parent',
    ]);

    return LookupItem(
      code: code.isNotEmpty ? code : labelAr,
      labelAr: labelAr.isNotEmpty
          ? labelAr
          : (labelEnRaw.isNotEmpty ? labelEnRaw : code),
      labelEn: labelEnRaw.isEmpty ? null : labelEnRaw,
      parentCode: parent.isEmpty ? null : parent,
    );
  }
}
