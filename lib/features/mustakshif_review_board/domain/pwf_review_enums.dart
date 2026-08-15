enum PwfReviewQueue {
  f1,
  f2,
  f3,
  f4;

  String get code => switch (this) {
        PwfReviewQueue.f1 => 'F1',
        PwfReviewQueue.f2 => 'F2',
        PwfReviewQueue.f3 => 'F3',
        PwfReviewQueue.f4 => 'F4',
      };

  String get labelAr => switch (this) {
        PwfReviewQueue.f1 => 'F1 — إدخال مصادر وتوقيع مزدوج',
        PwfReviewQueue.f2 => 'F2 — استثناءات مكانية',
        PwfReviewQueue.f3 => 'F3 — إصلاح هندسي/إعادة تصدير',
        PwfReviewQueue.f4 => 'F4 — بحث تاريخي يدوي',
      };

  static PwfReviewQueue fromCode(String code) {
    return PwfReviewQueue.values.firstWhere(
      (queue) => queue.code == code,
      orElse: () => PwfReviewQueue.f4,
    );
  }
}

enum PwfReviewDecision {
  none,
  approveCandidate,
  rejectCandidate,
  needsMoreEvidence,
  needsGeometryRepair,
  manualResearch;

  String get code => switch (this) {
        PwfReviewDecision.none => 'none',
        PwfReviewDecision.approveCandidate => 'approve_candidate',
        PwfReviewDecision.rejectCandidate => 'reject_candidate',
        PwfReviewDecision.needsMoreEvidence => 'needs_more_evidence',
        PwfReviewDecision.needsGeometryRepair => 'needs_geometry_repair',
        PwfReviewDecision.manualResearch => 'manual_research',
      };

  String get labelAr => switch (this) {
        PwfReviewDecision.none => 'لم يصدر قرار',
        PwfReviewDecision.approveCandidate => 'قبول المرشح كمراجعة داخلية',
        PwfReviewDecision.rejectCandidate => 'رفض المرشح',
        PwfReviewDecision.needsMoreEvidence => 'يحتاج مصدرًا إضافيًا',
        PwfReviewDecision.needsGeometryRepair => 'يحتاج إصلاحًا هندسيًا',
        PwfReviewDecision.manualResearch => 'بحث يدوي',
      };

  static PwfReviewDecision fromCode(String? code) {
    if (code == null || code.isEmpty) return PwfReviewDecision.none;
    return PwfReviewDecision.values.firstWhere(
      (decision) => decision.code == code,
      orElse: () => PwfReviewDecision.none,
    );
  }
}

enum PwfLocatorStatus {
  missing,
  draft,
  submitted,
  verified,
  rejected;

  String get code => switch (this) {
        PwfLocatorStatus.missing => 'locator_required',
        PwfLocatorStatus.draft => 'locator_draft',
        PwfLocatorStatus.submitted => 'locator_submitted',
        PwfLocatorStatus.verified => 'locator_verified',
        PwfLocatorStatus.rejected => 'locator_rejected',
      };

  String get labelAr => switch (this) {
        PwfLocatorStatus.missing => 'مطلوب إدخال مصدر',
        PwfLocatorStatus.draft => 'مسودة مصدر',
        PwfLocatorStatus.submitted => 'مصدر مدخل بانتظار التحقق',
        PwfLocatorStatus.verified => 'مصدر متحقق',
        PwfLocatorStatus.rejected => 'مصدر مرفوض',
      };

  static PwfLocatorStatus fromCode(String code) {
    return PwfLocatorStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => PwfLocatorStatus.missing,
    );
  }
}
