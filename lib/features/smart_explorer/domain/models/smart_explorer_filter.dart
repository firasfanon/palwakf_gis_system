import 'smart_explorer_gap_signal.dart';
import 'smart_explorer_result.dart';

/// Local UI filters for Smart Explorer results.
///
/// These filters do not change the source query or write anything to sovereign
/// data. They only help reviewers triage the read-only result set.
class SmartExplorerFilters {
  const SmartExplorerFilters({
    this.severity = SmartExplorerSeverityFilter.all,
    this.onlyNeedsReview = false,
    this.onlyWithoutSpatialReference = false,
    this.onlyWithoutLinkedParcels = false,
    this.onlyMissingEndowment = false,
    this.minConfidence = 0,
  });

  final SmartExplorerSeverityFilter severity;
  final bool onlyNeedsReview;
  final bool onlyWithoutSpatialReference;
  final bool onlyWithoutLinkedParcels;
  final bool onlyMissingEndowment;
  final int minConfidence;

  static const SmartExplorerFilters empty = SmartExplorerFilters();

  bool get hasActiveFilters => activeCount > 0;

  int get activeCount {
    var count = 0;
    if (severity != SmartExplorerSeverityFilter.all) count++;
    if (onlyNeedsReview) count++;
    if (onlyWithoutSpatialReference) count++;
    if (onlyWithoutLinkedParcels) count++;
    if (onlyMissingEndowment) count++;
    if (minConfidence > 0) count++;
    return count;
  }

  bool allows(SmartExplorerResult result) {
    if (onlyNeedsReview && !result.needsReview) return false;
    if (onlyWithoutSpatialReference && result.hasAnySpatialReference) {
      return false;
    }
    if (onlyWithoutLinkedParcels && result.hasLinkedParcels) return false;
    if (onlyMissingEndowment && result.endowmentName.trim().isNotEmpty) {
      return false;
    }
    if (result.confidenceScore < minConfidence) return false;
    return _allowsSeverity(result);
  }

  bool _allowsSeverity(SmartExplorerResult result) {
    switch (severity) {
      case SmartExplorerSeverityFilter.all:
        return true;
      case SmartExplorerSeverityFilter.critical:
        return result.hasSeverity(SmartExplorerSignalSeverity.critical);
      case SmartExplorerSeverityFilter.highAndCritical:
        return result.hasSeverity(SmartExplorerSignalSeverity.critical) ||
            result.hasSeverity(SmartExplorerSignalSeverity.high);
      case SmartExplorerSeverityFilter.mediumAndAbove:
        return result.hasSeverity(SmartExplorerSignalSeverity.critical) ||
            result.hasSeverity(SmartExplorerSignalSeverity.high) ||
            result.hasSeverity(SmartExplorerSignalSeverity.medium);
      case SmartExplorerSeverityFilter.lowOnly:
        return result.gapSignals.isNotEmpty &&
            result.gapSignals.every(
              (signal) => signal.severity == SmartExplorerSignalSeverity.low,
            );
    }
  }

  SmartExplorerFilters copyWith({
    SmartExplorerSeverityFilter? severity,
    bool? onlyNeedsReview,
    bool? onlyWithoutSpatialReference,
    bool? onlyWithoutLinkedParcels,
    bool? onlyMissingEndowment,
    int? minConfidence,
  }) {
    return SmartExplorerFilters(
      severity: severity ?? this.severity,
      onlyNeedsReview: onlyNeedsReview ?? this.onlyNeedsReview,
      onlyWithoutSpatialReference:
          onlyWithoutSpatialReference ?? this.onlyWithoutSpatialReference,
      onlyWithoutLinkedParcels:
          onlyWithoutLinkedParcels ?? this.onlyWithoutLinkedParcels,
      onlyMissingEndowment: onlyMissingEndowment ?? this.onlyMissingEndowment,
      minConfidence: minConfidence ?? this.minConfidence,
    );
  }
}

enum SmartExplorerSeverityFilter {
  all,
  critical,
  highAndCritical,
  mediumAndAbove,
  lowOnly,
}

extension SmartExplorerSeverityFilterX on SmartExplorerSeverityFilter {
  String get labelAr {
    switch (this) {
      case SmartExplorerSeverityFilter.all:
        return 'كل الإشارات';
      case SmartExplorerSeverityFilter.critical:
        return 'حرجة فقط';
      case SmartExplorerSeverityFilter.highAndCritical:
        return 'عالية/حرجة';
      case SmartExplorerSeverityFilter.mediumAndAbove:
        return 'متوسطة فأعلى';
      case SmartExplorerSeverityFilter.lowOnly:
        return 'منخفضة فقط';
    }
  }
}
