import 'pwf_review_enums.dart';
import 'pwf_source_locator.dart';

class PwfReviewRecord {
  const PwfReviewRecord({
    required this.id,
    required this.placeNameAr,
    required this.currentCandidateAr,
    required this.queue,
    required this.reviewStatus,
    required this.distanceMeters,
    required this.locatorStatus,
    required this.periodLabelAr,
    required this.adminDivisionAr,
    required this.candidateType,
    required this.confidenceScore,
    required this.geometryStatus,
    required this.warningLabel,
    this.sourceLocator,
    this.reviewerOneDecision = PwfReviewDecision.none,
    this.reviewerTwoDecision = PwfReviewDecision.none,
    this.reviewerOneNote = '',
    this.reviewerTwoNote = '',
    this.updatedAt,
    this.historicalLat,
    this.historicalLon,
    this.candidateLat,
    this.candidateLon,
    this.bboxSouth,
    this.bboxWest,
    this.bboxNorth,
    this.bboxEast,
    this.mapAdapterStatus = 'seed_or_placeholder',
  });

  final String id;
  final String placeNameAr;
  final String currentCandidateAr;
  final PwfReviewQueue queue;
  final String reviewStatus;
  final double? distanceMeters;
  final PwfLocatorStatus locatorStatus;
  final String periodLabelAr;
  final String adminDivisionAr;
  final String candidateType;
  final int confidenceScore;
  final String geometryStatus;
  final String warningLabel;
  final PwfSourceLocator? sourceLocator;
  final PwfReviewDecision reviewerOneDecision;
  final PwfReviewDecision reviewerTwoDecision;
  final String reviewerOneNote;
  final String reviewerTwoNote;
  final DateTime? updatedAt;
  final double? historicalLat;
  final double? historicalLon;
  final double? candidateLat;
  final double? candidateLon;
  final double? bboxSouth;
  final double? bboxWest;
  final double? bboxNorth;
  final double? bboxEast;
  final String mapAdapterStatus;

  bool get hasLocator => sourceLocator?.isComplete ?? false;

  bool get hasHistoricalPoint => historicalLat != null && historicalLon != null;

  bool get hasCandidateCentroid => candidateLat != null && candidateLon != null;

  bool get hasMapBbox {
    return bboxSouth != null && bboxWest != null && bboxNorth != null && bboxEast != null;
  }

  bool get hasMapEvidence => hasHistoricalPoint || hasCandidateCentroid || hasMapBbox;

  String get coordinateEvidenceStatusAr {
    if (hasHistoricalPoint && hasCandidateCentroid && hasMapBbox) {
      return 'جاهز لمحول خريطة أولي';
    }
    if (hasHistoricalPoint && hasCandidateCentroid) {
      return 'نقاط متوفرة بلا bbox';
    }
    if (hasHistoricalPoint) return 'نقطة تاريخية فقط';
    if (hasCandidateCentroid) return 'centroid مرشح فقط';
    return 'لا توجد إحداثيات تشغيلية';
  }

  String get historicalPointLabel {
    if (!hasHistoricalPoint) return 'غير متوفر';
    return '${historicalLat!.toStringAsFixed(5)}, ${historicalLon!.toStringAsFixed(5)}';
  }

  String get candidatePointLabel {
    if (!hasCandidateCentroid) return 'غير متوفر';
    return '${candidateLat!.toStringAsFixed(5)}, ${candidateLon!.toStringAsFixed(5)}';
  }

  String get mapAdapterReadinessCode {
    if (hasHistoricalPoint && hasCandidateCentroid && hasMapBbox) {
      return 'ready_full_evidence';
    }
    if (hasHistoricalPoint && hasCandidateCentroid) {
      return 'ready_points_only';
    }
    if (hasHistoricalPoint || hasCandidateCentroid) {
      return 'partial_point_evidence';
    }
    if (requiresGeometryRepair) return 'blocked_geometry_repair';
    if (requiresManualResearch) return 'blocked_manual_research';
    return 'blocked_no_map_evidence';
  }

  String get mapAdapterReadinessLabelAr => switch (mapAdapterReadinessCode) {
        'ready_full_evidence' => 'جاهز لمعاينة خريطة كاملة',
        'ready_points_only' => 'جاهز لمعاينة نقاط فقط',
        'partial_point_evidence' => 'أدلة مكانية جزئية',
        'blocked_geometry_repair' => 'محجوب: إصلاح هندسي',
        'blocked_manual_research' => 'محجوب: بحث يدوي',
        _ => 'محجوب: لا توجد أدلة خريطة',
      };

  String get mapCameraIntentCode {
    if (hasMapBbox) return 'fit_bbox';
    if (hasHistoricalPoint && hasCandidateCentroid) return 'fit_two_points';
    if (hasHistoricalPoint) return 'focus_historical_point';
    if (hasCandidateCentroid) return 'focus_candidate_centroid';
    return 'show_placeholder_only';
  }

  String get mapCameraIntentLabelAr => switch (mapCameraIntentCode) {
        'fit_bbox' => 'ملاءمة الخريطة على bbox',
        'fit_two_points' => 'ملاءمة الخريطة على النقطتين',
        'focus_historical_point' => 'تركيز على النقطة التاريخية',
        'focus_candidate_centroid' => 'تركيز على centroid المرشح',
        _ => 'عرض placeholder فقط',
      };

  String get mapAdapterPayloadPreview {
    return '{'
        '"record_id":"$id",'
        '"layer_policy":"do_not_toggle_layers",'
        '"camera_policy":"$mapCameraIntentCode",'
        '"historical_point":"$historicalPointLabel",'
        '"candidate_point":"$candidatePointLabel",'
        '"bbox_available":$hasMapBbox,'
        '"governance":"review_only_not_final"'
        '}';
  }


  bool get hasDualDecision {
    return reviewerOneDecision != PwfReviewDecision.none &&
        reviewerTwoDecision != PwfReviewDecision.none;
  }

  bool get isDecisionAligned {
    return hasDualDecision && reviewerOneDecision == reviewerTwoDecision;
  }

  bool get isInternalDecisionPackageReady {
    return hasLocator &&
        hasDualDecision &&
        isDecisionAligned &&
        reviewerOneDecision == PwfReviewDecision.approveCandidate;
  }

  bool get requiresGeometryRepair {
    final normalized = '$reviewStatus $geometryStatus ${queue.code}'.toLowerCase();
    return queue == PwfReviewQueue.f3 ||
        normalized.contains('geometry') ||
        normalized.contains('centroid') ||
        normalized.contains('proxy');
  }

  bool get requiresSpatialReview {
    final distance = distanceMeters;
    final normalized = '$reviewStatus $geometryStatus'.toLowerCase();
    return queue == PwfReviewQueue.f2 ||
        normalized.contains('spatial') ||
        normalized.contains('boundary') ||
        normalized.contains('خارج') ||
        (distance != null && distance >= 3000);
  }

  bool get requiresManualResearch {
    return queue == PwfReviewQueue.f4 || reviewStatus.toLowerCase().contains('manual');
  }

  String get queueCode => queue.code;

  String get distanceLabel {
    final value = distanceMeters;
    if (value == null) return 'غير متوفر';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)} كم';
    return '${value.toStringAsFixed(0)} م';
  }

  String get distanceRiskCode {
    final value = distanceMeters;
    if (value == null) return requiresGeometryRepair ? 'geometry_missing' : 'unknown_distance';
    if (value <= 1000) return 'low_distance';
    if (value <= 3000) return 'medium_distance';
    if (value <= 10000) return 'high_distance';
    return 'critical_distance';
  }

  String get distanceRiskLabelAr => switch (distanceRiskCode) {
        'low_distance' => 'مخاطر مكانية منخفضة',
        'medium_distance' => 'مخاطر مكانية متوسطة',
        'high_distance' => 'مخاطر مكانية عالية',
        'critical_distance' => 'تعارض مكاني حاد',
        'geometry_missing' => 'هندسة مفقودة',
        _ => 'مسافة غير متوفرة',
      };

  String get operationalGateCode {
    if (!hasLocator) return 'blocked_source_locator_required';
    if (!hasDualDecision) return 'blocked_dual_signoff_required';
    if (!isDecisionAligned) return 'blocked_reviewer_disagreement';
    if (reviewerOneDecision != PwfReviewDecision.approveCandidate) {
      return 'not_exportable_negative_or_pending_decision';
    }
    return 'internal_decision_package_ready';
  }

  String get operationalGateStatus => switch (operationalGateCode) {
        'blocked_source_locator_required' => 'محجوب: مصدر مطلوب',
        'blocked_dual_signoff_required' => 'محجوب: توقيعان مطلوبان',
        'blocked_reviewer_disagreement' => 'محجوب: تعارض قرارات المراجعين',
        'not_exportable_negative_or_pending_decision' => 'غير قابل للتصدير: القرار ليس قبولًا',
        'internal_decision_package_ready' => 'جاهز لحزمة قرار داخلية فقط، لا تصدير سيادي',
        _ => 'محجوب حوكمياً',
      };

  String get mapEvidenceSummary {
    final source = hasLocator ? 'مصدر مدخل' : 'مصدر مفقود';
    final decision = hasDualDecision ? 'توقيع مزدوج' : 'توقيع غير مكتمل';
    return '$distanceRiskLabelAr — $source — $decision';
  }

  PwfReviewRecord copyWith({
    String? id,
    String? placeNameAr,
    String? currentCandidateAr,
    PwfReviewQueue? queue,
    String? reviewStatus,
    double? distanceMeters,
    PwfLocatorStatus? locatorStatus,
    String? periodLabelAr,
    String? adminDivisionAr,
    String? candidateType,
    int? confidenceScore,
    String? geometryStatus,
    String? warningLabel,
    PwfSourceLocator? sourceLocator,
    PwfReviewDecision? reviewerOneDecision,
    PwfReviewDecision? reviewerTwoDecision,
    String? reviewerOneNote,
    String? reviewerTwoNote,
    DateTime? updatedAt,
    double? historicalLat,
    double? historicalLon,
    double? candidateLat,
    double? candidateLon,
    double? bboxSouth,
    double? bboxWest,
    double? bboxNorth,
    double? bboxEast,
    String? mapAdapterStatus,
  }) {
    return PwfReviewRecord(
      id: id ?? this.id,
      placeNameAr: placeNameAr ?? this.placeNameAr,
      currentCandidateAr: currentCandidateAr ?? this.currentCandidateAr,
      queue: queue ?? this.queue,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      locatorStatus: locatorStatus ?? this.locatorStatus,
      periodLabelAr: periodLabelAr ?? this.periodLabelAr,
      adminDivisionAr: adminDivisionAr ?? this.adminDivisionAr,
      candidateType: candidateType ?? this.candidateType,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      geometryStatus: geometryStatus ?? this.geometryStatus,
      warningLabel: warningLabel ?? this.warningLabel,
      sourceLocator: sourceLocator ?? this.sourceLocator,
      reviewerOneDecision: reviewerOneDecision ?? this.reviewerOneDecision,
      reviewerTwoDecision: reviewerTwoDecision ?? this.reviewerTwoDecision,
      reviewerOneNote: reviewerOneNote ?? this.reviewerOneNote,
      reviewerTwoNote: reviewerTwoNote ?? this.reviewerTwoNote,
      updatedAt: updatedAt ?? this.updatedAt,
      historicalLat: historicalLat ?? this.historicalLat,
      historicalLon: historicalLon ?? this.historicalLon,
      candidateLat: candidateLat ?? this.candidateLat,
      candidateLon: candidateLon ?? this.candidateLon,
      bboxSouth: bboxSouth ?? this.bboxSouth,
      bboxWest: bboxWest ?? this.bboxWest,
      bboxNorth: bboxNorth ?? this.bboxNorth,
      bboxEast: bboxEast ?? this.bboxEast,
      mapAdapterStatus: mapAdapterStatus ?? this.mapAdapterStatus,
    );
  }
}
