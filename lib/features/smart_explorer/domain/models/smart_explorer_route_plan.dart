import 'smart_explorer_result.dart';

/// Local field-review route plan generated from Smart Explorer review queue.
///
/// This is not a navigation service. It is a triage ordering helper until a
/// real routing engine and field workflow are approved.
class SmartExplorerRoutePlan {
  const SmartExplorerRoutePlan({
    required this.stops,
    required this.generatedAt,
    required this.scopeLabelAr,
  });

  final List<SmartExplorerRouteStop> stops;
  final DateTime generatedAt;
  final String scopeLabelAr;

  bool get isEmpty => stops.isEmpty;
  int get totalStops => stops.length;
  int get highPriorityStops => stops.where((item) => item.isHighPriority).length;

  String get summaryAr {
    if (stops.isEmpty) return 'لا توجد نقاط كافية لبناء مسار تدقيق.';
    return 'مسار تدقيق مقترح من $totalStops نقاط، منها $highPriorityStops ذات أولوية عالية/عاجلة.';
  }
}

class SmartExplorerRouteStop {
  const SmartExplorerRouteStop({
    required this.order,
    required this.resultId,
    required this.titleAr,
    required this.assetCode,
    required this.governorate,
    required this.community,
    required this.lgu,
    required this.reasonAr,
    required this.priorityLabelAr,
    required this.reviewScore,
    required this.mapQuery,
  });

  factory SmartExplorerRouteStop.fromResult({
    required int order,
    required SmartExplorerResult result,
  }) {
    return SmartExplorerRouteStop(
      order: order,
      resultId: result.id,
      titleAr: result.titleAr,
      assetCode: result.assetCode,
      governorate: result.governorate,
      community: result.community,
      lgu: result.lgu,
      reasonAr: result.gapSignals.isEmpty
          ? result.recommendedActionAr
          : result.gapSignals.first.recommendedActionAr,
      priorityLabelAr: result.reviewPriorityLabelAr,
      reviewScore: result.reviewScore,
      mapQuery: result.mapQuery,
    );
  }

  final int order;
  final String resultId;
  final String titleAr;
  final String assetCode;
  final String governorate;
  final String community;
  final String lgu;
  final String reasonAr;
  final String priorityLabelAr;
  final int reviewScore;
  final String mapQuery;

  bool get isHighPriority =>
      priorityLabelAr == 'عاجلة' || priorityLabelAr == 'عالية';

  String get locationLabelAr {
    final parts = <String>[
      if (governorate.trim().isNotEmpty) governorate.trim(),
      if (community.trim().isNotEmpty) community.trim(),
      if (lgu.trim().isNotEmpty) lgu.trim(),
    ];
    return parts.isEmpty ? 'موقع إداري غير مكتمل' : parts.join(' / ');
  }
}
