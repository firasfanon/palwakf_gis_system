/// Semantic classification for Mustakshif map layers.
///
/// This enum is intentionally independent from rendering/activation state.
/// It describes the knowledge role of the layer, not whether the layer is active.
enum MustakshifMapLayerPurpose {
  reference,
  cadastral,
  thematic,
  historical,
  verification,
  operational,
  analysis,
}

extension MustakshifMapLayerPurposeX on MustakshifMapLayerPurpose {
  String get key {
    switch (this) {
      case MustakshifMapLayerPurpose.reference:
        return 'reference';
      case MustakshifMapLayerPurpose.cadastral:
        return 'cadastral';
      case MustakshifMapLayerPurpose.thematic:
        return 'thematic';
      case MustakshifMapLayerPurpose.historical:
        return 'historical';
      case MustakshifMapLayerPurpose.verification:
        return 'verification';
      case MustakshifMapLayerPurpose.operational:
        return 'operational';
      case MustakshifMapLayerPurpose.analysis:
        return 'analysis';
    }
  }

  String get labelAr {
    switch (this) {
      case MustakshifMapLayerPurpose.reference:
        return 'مرجعية';
      case MustakshifMapLayerPurpose.cadastral:
        return 'كادسترائية / تسوية';
      case MustakshifMapLayerPurpose.thematic:
        return 'موضوعية';
      case MustakshifMapLayerPurpose.historical:
        return 'تاريخية';
      case MustakshifMapLayerPurpose.verification:
        return 'تحقق وأدلة';
      case MustakshifMapLayerPurpose.operational:
        return 'تشغيلية';
      case MustakshifMapLayerPurpose.analysis:
        return 'تحليلية';
    }
  }

  static MustakshifMapLayerPurpose fromKey(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    for (final value in MustakshifMapLayerPurpose.values) {
      if (value.key == normalized) return value;
    }
    return MustakshifMapLayerPurpose.reference;
  }
}

enum MustakshifLayerLegalWeight {
  official,
  reference,
  operational,
  analytical,
  unverified,
  unknown,
}

extension MustakshifLayerLegalWeightX on MustakshifLayerLegalWeight {
  String get key {
    switch (this) {
      case MustakshifLayerLegalWeight.official:
        return 'official';
      case MustakshifLayerLegalWeight.reference:
        return 'reference';
      case MustakshifLayerLegalWeight.operational:
        return 'operational';
      case MustakshifLayerLegalWeight.analytical:
        return 'analytical';
      case MustakshifLayerLegalWeight.unverified:
        return 'unverified';
      case MustakshifLayerLegalWeight.unknown:
        return 'unknown';
    }
  }

  String get labelAr {
    switch (this) {
      case MustakshifLayerLegalWeight.official:
        return 'رسمي';
      case MustakshifLayerLegalWeight.reference:
        return 'مرجعي';
      case MustakshifLayerLegalWeight.operational:
        return 'تشغيلي';
      case MustakshifLayerLegalWeight.analytical:
        return 'تحليلي';
      case MustakshifLayerLegalWeight.unverified:
        return 'غير محقق';
      case MustakshifLayerLegalWeight.unknown:
        return 'غير محدد';
    }
  }

  bool get requiresReview => this == MustakshifLayerLegalWeight.analytical || this == MustakshifLayerLegalWeight.unverified || this == MustakshifLayerLegalWeight.unknown;

  static MustakshifLayerLegalWeight fromKey(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    for (final value in MustakshifLayerLegalWeight.values) {
      if (value.key == normalized) return value;
    }
    return MustakshifLayerLegalWeight.unknown;
  }
}

enum MustakshifLayerAccuracyLevel {
  high,
  medium,
  low,
  unknown,
}

extension MustakshifLayerAccuracyLevelX on MustakshifLayerAccuracyLevel {
  String get key {
    switch (this) {
      case MustakshifLayerAccuracyLevel.high:
        return 'high';
      case MustakshifLayerAccuracyLevel.medium:
        return 'medium';
      case MustakshifLayerAccuracyLevel.low:
        return 'low';
      case MustakshifLayerAccuracyLevel.unknown:
        return 'unknown';
    }
  }

  String get labelAr {
    switch (this) {
      case MustakshifLayerAccuracyLevel.high:
        return 'عالية';
      case MustakshifLayerAccuracyLevel.medium:
        return 'متوسطة';
      case MustakshifLayerAccuracyLevel.low:
        return 'منخفضة';
      case MustakshifLayerAccuracyLevel.unknown:
        return 'غير محددة';
    }
  }

  static MustakshifLayerAccuracyLevel fromKey(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    for (final value in MustakshifLayerAccuracyLevel.values) {
      if (value.key == normalized) return value;
    }
    return MustakshifLayerAccuracyLevel.unknown;
  }
}
