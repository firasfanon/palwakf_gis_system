
class EndowmentReference {
  final String id;
  final String nationalId;
  final String nameAr;
  final String? nameEn;
  final String? type;
  final String? subType;
  final String? category;
  final String? endowerId;
  final String? endowerName;
  final String? governorateName;
  final String? cityName;
  final String? fullAddress;
  final double? totalArea;
  final String? status;
  final String? purpose;
  final String? conditions;
  final String? historicalNotes;
  final String? legalNotes;
  final double? latitude;
  final double? longitude;

  const EndowmentReference({
    required this.id,
    required this.nationalId,
    required this.nameAr,
    this.nameEn,
    this.type,
    this.subType,
    this.category,
    this.endowerId,
    this.endowerName,
    this.governorateName,
    this.cityName,
    this.fullAddress,
    this.totalArea,
    this.status,
    this.purpose,
    this.conditions,
    this.historicalNotes,
    this.legalNotes,
    this.latitude,
    this.longitude,
  });

  String get displayName {
    final ar = nameAr.trim();
    if (ar.isNotEmpty) return ar;
    final en = (nameEn ?? '').trim();
    if (en.isNotEmpty) return en;
    return nationalId;
  }

  String get locationLabel {
    final parts = <String>[if ((cityName ?? '').trim().isNotEmpty) cityName!.trim(), if ((governorateName ?? '').trim().isNotEmpty) governorateName!.trim()];
    if (parts.isEmpty) return fullAddress?.trim().isNotEmpty == true ? fullAddress!.trim() : '—';
    return parts.join(' / ');
  }
}
