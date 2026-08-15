
class EndowerReference {
  final String id;
  final String nationalId;
  final String nameAr;
  final String? nameEn;
  final String? gender;
  final String? status;
  final String? nationality;
  final String? city;
  final String? governorate;
  final int? endowmentCount;
  final String? familyHistory;

  const EndowerReference({
    required this.id,
    required this.nationalId,
    required this.nameAr,
    this.nameEn,
    this.gender,
    this.status,
    this.nationality,
    this.city,
    this.governorate,
    this.endowmentCount,
    this.familyHistory,
  });

  String get displayName {
    final ar = nameAr.trim();
    if (ar.isNotEmpty) return ar;
    final en = (nameEn ?? '').trim();
    if (en.isNotEmpty) return en;
    return nationalId;
  }
}
