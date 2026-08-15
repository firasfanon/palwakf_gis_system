import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../history_explorer/domain/models/waqf_asset_model.dart';
import '../../../map/data/repositories/map_feedback_repository.dart';
import '../../../map/domain/models/gis_feature_model.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../../../map/presentation/providers/map_ui_providers.dart';
import '../../../map/presentation/providers/toolbox_providers.dart';
import '../../../tasks_system/data/repositories/audit_task_repository.dart';
import '../../domain/models/smart_explorer_result.dart';
import 'smart_explorer_providers.dart';

final smartExplorerBridgeSnapshotProvider =
    Provider<SmartExplorerBridgeSnapshot>((ref) {
  final smartState = ref.watch(smartExplorerControllerProvider);
  final mapState = ref.watch(mapNotifierProvider);
  final identify = ref.watch(identifyResultProvider);
  final lastTap = ref.watch(lastTapLatLngProvider);
  final gotoMarker = ref.watch(gotoMarkerProvider);
  final selectionPoints = ref.watch(selectionBoxPointsProvider);
  final audience = ref.watch(mapToolAudienceProvider);

  return SmartExplorerBridgeSnapshot.fromState(
    selectedResult: smartState.selectedResult,
    filteredResultsCount: smartState.filteredResults.length,
    reviewQueueCount: smartState.reviewQueue.length,
    mapState: mapState,
    identify: identify,
    lastTap: lastTap,
    gotoMarker: gotoMarker,
    selectionPoints: selectionPoints,
    audience: audience,
    recommendedLayerKeys: _recommendedLayerKeys(
      selectedResult: smartState.selectedResult,
      generatedLayerKeys:
          smartState.layerRecommendations?.topRecommendations.map((item) => item.layerKey),
      availableLayers: mapState.gisLayers,
    ),
  );
});

final smartExplorerBridgeServiceProvider = Provider<SmartExplorerBridgeService>(
  (ref) => SmartExplorerBridgeService(ref),
);

class SmartExplorerBridgeService {
  SmartExplorerBridgeService(this._ref);

  final Ref _ref;

  SmartExplorerBridgeSnapshot get snapshot =>
      _ref.read(smartExplorerBridgeSnapshotProvider);

  Future<SmartExplorerBridgeActionResult> prepareSelectedResultForMap() async {
    final snap = snapshot;
    final result = snap.selectedResult;
    if (result == null) {
      return const SmartExplorerBridgeActionResult(
        ok: false,
        messageAr: 'لا توجد نتيجة ذكية محددة لتجهيزها على الخريطة.',
      );
    }

    _ref.read(activeToolSectionProvider.notifier).state = ToolSection.tools;
    _ref.read(activeToolsSubPanelProvider.notifier).state =
        ToolsSubPanel.realInteractions;

    final target = snap.targetPoint;
    if (target != null) {
      _ref.read(gotoMarkerProvider.notifier).state = target;
      _ref.read(lastTapLatLngProvider.notifier).state = target;
      _ref.read(realMapInteractionModeProvider.notifier).state =
          ExplorerRealMapInteractionMode.identify;
      return SmartExplorerBridgeActionResult(
        ok: true,
        messageAr:
            'تم تجهيز ${result.titleAr} على الخريطة وإعداد وضع التعريف عند الإحداثية.',
      );
    }

    _ref.read(realMapInteractionModeProvider.notifier).state =
        ExplorerRealMapInteractionMode.selectionBox;
    return const SmartExplorerBridgeActionResult(
      ok: true,
      messageAr:
          'النتيجة بلا إحداثية موثوقة؛ تم فتح أدوات التفاعل لاختيار نطاق تدقيق يدوي.',
    );
  }

  Future<SmartExplorerBridgeActionResult> activateRecommendedLayers() async {
    final snap = snapshot;
    if (snap.matchingRecommendedLayerKeys.isEmpty) {
      return const SmartExplorerBridgeActionResult(
        ok: false,
        messageAr: 'لا توجد طبقات موصى بها وموجودة في كتالوج الخريطة الحالي.',
      );
    }

    return SmartExplorerBridgeActionResult(
      ok: true,
      messageAr:
          'تم تجهيز ${snap.matchingRecommendedLayerKeys.length} توصية طبقة للقراءة فقط. التفعيل يبقى من واجهة الخريطة ولا يغيّر المستكشف الذكي activeLayers.',
    );
  }

  SmartExplorerBridgeActionResult prepareCrossMapLink(
    SmartExplorerCrossMapLink link,
  ) {
    final snap = snapshot;
    final result = snap.selectedResult;
    if (link.requiresSelectedResult && result == null) {
      return const SmartExplorerBridgeActionResult(
        ok: false,
        messageAr: 'اختر نتيجة ذكية قبل فتح الرابط العميق.',
      );
    }

    final target = snap.targetPoint;
    if (link.prefersSpatialTarget && target != null) {
      _ref.read(gotoMarkerProvider.notifier).state = target;
      _ref.read(lastTapLatLngProvider.notifier).state = target;
    }

    if (link.id == 'modern_map') {
      _ref.read(activeToolSectionProvider.notifier).state = ToolSection.tools;
      _ref.read(activeToolsSubPanelProvider.notifier).state =
          ToolsSubPanel.realInteractions;
      _ref.read(realMapInteractionModeProvider.notifier).state =
          target == null
              ? ExplorerRealMapInteractionMode.selectionBox
              : ExplorerRealMapInteractionMode.identify;
    }

    return SmartExplorerBridgeActionResult(
      ok: true,
      messageAr: 'تم تجهيز الرابط العميق: ${link.titleAr}',
    );
  }

  SmartExplorerBridgeActionResult prepareAuditContext({
    double halfSizeDegrees = 0.006,
  }) {
    final snap = snapshot;
    if (snap.selectedResult == null) {
      return const SmartExplorerBridgeActionResult(
        ok: false,
        messageAr: 'لا توجد نتيجة ذكية لتحويلها إلى حزمة تدقيق.',
      );
    }

    _ref.read(activeToolSectionProvider.notifier).state = ToolSection.tools;
    _ref.read(activeToolsSubPanelProvider.notifier).state =
        ToolsSubPanel.realInteractions;

    final target = snap.targetPoint;
    if (target != null) {
      _ref.read(gotoMarkerProvider.notifier).state = target;
      _ref.read(lastTapLatLngProvider.notifier).state = target;
      _ref.read(selectionBoxPointsProvider.notifier).state = <LatLng>[
        LatLng(target.latitude - halfSizeDegrees, target.longitude - halfSizeDegrees),
        LatLng(target.latitude + halfSizeDegrees, target.longitude + halfSizeDegrees),
      ];
      _ref.read(realMapInteractionModeProvider.notifier).state =
          ExplorerRealMapInteractionMode.selectionBox;
      return const SmartExplorerBridgeActionResult(
        ok: true,
        messageAr: 'تم تجهيز سياق التدقيق مع BBOX أولي حول النتيجة.',
      );
    }

    _ref.read(realMapInteractionModeProvider.notifier).state =
        ExplorerRealMapInteractionMode.selectionBox;
    return const SmartExplorerBridgeActionResult(
      ok: true,
      messageAr: 'تم تجهيز سياق التدقيق، ويحتاج تحديد نطاق يدوي على الخريطة.',
    );
  }

  SmartExplorerBridgeActionResult prepareSelectionBoxFromTarget({
    double halfSizeDegrees = 0.006,
  }) {
    final snap = snapshot;
    final target = snap.targetPoint;
    if (target == null) {
      return const SmartExplorerBridgeActionResult(
        ok: false,
        messageAr: 'لا توجد إحداثية هدف لإنشاء نطاق تلقائي.',
      );
    }

    final p1 = LatLng(
      target.latitude - halfSizeDegrees,
      target.longitude - halfSizeDegrees,
    );
    final p2 = LatLng(
      target.latitude + halfSizeDegrees,
      target.longitude + halfSizeDegrees,
    );
    _ref.read(selectionBoxPointsProvider.notifier).state = <LatLng>[p1, p2];
    _ref.read(activeToolSectionProvider.notifier).state = ToolSection.tools;
    _ref.read(activeToolsSubPanelProvider.notifier).state =
        ToolsSubPanel.realInteractions;
    _ref.read(realMapInteractionModeProvider.notifier).state =
        ExplorerRealMapInteractionMode.selectionBox;

    return const SmartExplorerBridgeActionResult(
      ok: true,
      messageAr: 'تم تجهيز نطاق BBOX أولي حول نتيجة المستكشف الذكي.',
    );
  }

  Future<SmartExplorerBridgeAuditWorkflowResult> createRealAuditWorkflow({
    bool createTask = false,
    bool autoAcceptBeforeTask = true,
  }) async {
    final snap = snapshot;
    if (snap.selectedResult == null) {
      return const SmartExplorerBridgeAuditWorkflowResult(
        ok: false,
        messageAr: 'لا توجد نتيجة ذكية محددة لإنشاء طلب تدقيق فعلي.',
      );
    }

    try {
      final feedbackRepo = _ref.read(mapFeedbackRepositoryProvider);
      var request = await feedbackRepo.createExplorerGapAuditRequest(
        snap.toExplorerGapAuditSubmission(),
      );

      AuditTask? task;
      Object? taskError;
      if (createTask) {
        try {
          if (autoAcceptBeforeTask && request.status != 'accepted') {
            request = await feedbackRepo.reviewExplorerGapAuditRequest(
              requestId: request.id,
              newStatus: 'accepted',
              reviewerNote:
                  'قبول آلي من Bridge Batch M لإنشاء مهمة تدقيق تشغيلية. يحتاج الاعتماد النهائي إلى مراجعة بشرية.',
            );
          }

          task = await _ref.read(auditTaskRepositoryProvider).createFromExplorerGap(
                requestId: request.id,
                title: 'مهمة تدقيق ذكي: ${snap.auditTitleAr}',
                description: snap.auditDescriptionAr,
                priority: snap.auditPriorityCode,
              );
        } catch (error) {
          taskError = error;
        }
      }

      if (createTask && task == null) {
        return SmartExplorerBridgeAuditWorkflowResult(
          ok: false,
          request: request,
          taskError: taskError,
          messageAr:
              'تم إنشاء طلب التدقيق رقم ${request.id}، لكن تعذر إنشاء مهمة التدقيق: ${taskError ?? 'خطأ غير معروف'}',
        );
      }

      return SmartExplorerBridgeAuditWorkflowResult(
        ok: true,
        request: request,
        task: task,
        messageAr: task == null
            ? 'تم إنشاء طلب تدقيق فعلي رقم ${request.id}.'
            : 'تم إنشاء طلب تدقيق فعلي ومهمة تدقيق: ${task.title}',
      );
    } catch (error) {
      return SmartExplorerBridgeAuditWorkflowResult(
        ok: false,
        messageAr:
            'تعذر إنشاء مسار التدقيق الفعلي. تحقق من تطبيق SQL/RPC/RBAC الخاص بـ Batch M: $error',
      );
    }
  }
}

class SmartExplorerBridgeActionResult {
  const SmartExplorerBridgeActionResult({
    required this.ok,
    required this.messageAr,
  });

  final bool ok;
  final String messageAr;
}

class SmartExplorerBridgeAuditWorkflowResult {
  const SmartExplorerBridgeAuditWorkflowResult({
    required this.ok,
    required this.messageAr,
    this.request,
    this.task,
    this.taskError,
  });

  final bool ok;
  final String messageAr;
  final ExplorerGapAuditRequest? request;
  final AuditTask? task;
  final Object? taskError;

  String get summaryAr {
    final parts = <String>[messageAr];
    if (request != null) {
      parts.add('طلب: ${request!.id} / ${request!.displayStatus}');
    }
    if (task != null) {
      parts.add('مهمة: ${task!.id} / ${task!.displayStatus}');
    }
    return parts.join(' • ');
  }
}

class SmartExplorerCrossMapLink {
  const SmartExplorerCrossMapLink({
    required this.id,
    required this.titleAr,
    required this.descriptionAr,
    required this.route,
    this.requiresSelectedResult = true,
    this.prefersSpatialTarget = true,
  });

  final String id;
  final String titleAr;
  final String descriptionAr;
  final String route;
  final bool requiresSelectedResult;
  final bool prefersSpatialTarget;
}

class SmartExplorerBridgeSnapshot {
  const SmartExplorerBridgeSnapshot({
    required this.selectedResult,
    required this.filteredResultsCount,
    required this.reviewQueueCount,
    required this.targetPoint,
    required this.runtimeInfo,
    required this.activeLayerKeys,
    required this.availableLayerKeys,
    required this.recommendedLayerKeys,
    required this.matchingRecommendedLayerKeys,
    required this.blockedLayerKeys,
    required this.selectionPoints,
    required this.selectedFeaturesInBox,
    required this.identifyFeatureTitle,
    required this.lastTap,
    required this.gotoMarker,
    required this.audience,
  });

  final SmartExplorerResult? selectedResult;
  final int filteredResultsCount;
  final int reviewQueueCount;
  final LatLng? targetPoint;
  final MapRuntimeInfo runtimeInfo;
  final List<String> activeLayerKeys;
  final List<String> availableLayerKeys;
  final List<String> recommendedLayerKeys;
  final List<String> matchingRecommendedLayerKeys;
  final List<String> blockedLayerKeys;
  final List<LatLng> selectionPoints;
  final List<GisFeatureModel> selectedFeaturesInBox;
  final String? identifyFeatureTitle;
  final LatLng? lastTap;
  final LatLng? gotoMarker;
  final MapToolAudience audience;

  bool get hasSelectedResult => selectedResult != null;
  bool get canOpenOnMap => selectedResult != null;
  bool get hasTargetPoint => targetPoint != null;
  bool get hasSelectionBox => selectionPoints.length >= 2;
  bool get hasRecommendedLayerMatches => matchingRecommendedLayerKeys.isNotEmpty;

  List<SmartExplorerCrossMapLink> get crossMapLinks => const [
        SmartExplorerCrossMapLink(
          id: 'modern_map',
          titleAr: 'الخريطة الحديثة',
          descriptionAr: 'فتح النتيجة ضمن أدوات التفاعل الحقيقي والطبقات الحديثة.',
          route: '/map',
        ),
        SmartExplorerCrossMapLink(
          id: 'historical_spatial',
          titleAr: 'التطور التاريخي المكاني',
          descriptionAr: 'فتح سياق النتيجة ضمن خريطة التطور التاريخي.',
          route: '/history?mode=historical',
        ),
        SmartExplorerCrossMapLink(
          id: 'waqf_history',
          titleAr: 'الأصول الوقفية عبر التاريخ',
          descriptionAr: 'فتح سياق الأصل/الوقف الأم في الخريطة التاريخية الوقفية.',
          route: '/history?mode=waqf',
        ),
        SmartExplorerCrossMapLink(
          id: 'historical_admin',
          titleAr: 'التقسيمات الإدارية التاريخية',
          descriptionAr: 'فتح سياق التقسيمات الإدارية السابقة واللاحقة.',
          route: '/history/admin-divisions',
        ),
      ];

  String get auditPriorityAr =>
      selectedResult?.reviewPriorityLabelAr ?? 'غير محددة';

  String get auditDomainAr {
    final result = selectedResult;
    if (result == null) return 'غير محدد';
    if (result.missingAdministrativeContext) return 'التقسيمات الإدارية';
    if (!result.hasAnySpatialReference) return 'التمثيل المكاني للأصل';
    if (!result.hasLinkedParcels) return 'القطع/الأحواض المرتبطة';
    if (result.missingReferenceContext) return 'المرجع الوقفي';
    return 'مراجعة مستكشف عامة';
  }

  String get auditSourceType => 'smart_explorer_bridge_handoff';

  String get auditTitleAr {
    final result = selectedResult;
    if (result == null) return 'حزمة تدقيق مستكشف ذكي غير محددة';
    final code = result.assetCode.trim().isEmpty ? result.id : result.assetCode;
    return 'تدقيق مستكشف ذكي: ${result.titleAr} ($code)';
  }

  String get auditDescriptionAr {
    final result = selectedResult;
    if (result == null) return 'لا توجد نتيجة محددة.';
    final lines = <String>[
      result.compactAuditSummary,
      '',
      'مجال التدقيق: $auditDomainAr',
      'أولوية التدقيق: $auditPriorityAr',
      'إحداثية الهدف: $targetLabelAr',
      'نطاق BBOX: $selectionBboxLabelAr',
      'الطبقات المقترحة: ${matchingRecommendedLayerKeys.join(', ')}',
      'المعالم المحملة داخل النطاق: ${selectedFeaturesInBox.length}',
    ];
    return lines.join('\n');
  }

  String get crossMapRoutesSummaryAr =>
      crossMapLinks.map((link) => '${link.titleAr}: ${link.route}').join(' • ');

  String get bridgeDeepLinkSummaryAr {
    if (selectedResult == null) return 'لا توجد نتيجة محددة للربط العميق.';
    final spatial = targetPoint == null
        ? 'بدون إحداثية مباشرة'
        : 'مع هدف: $targetLabelAr';
    return '$spatial • مجال التدقيق: $auditDomainAr • أولوية: $auditPriorityAr';
  }

  String get bridgeStatusAr {
    if (selectedResult == null) return 'اختر نتيجة ذكية لتفعيل الجسر.';
    if (targetPoint != null && matchingRecommendedLayerKeys.isNotEmpty) {
      return 'جاهز للفتح على الخريطة مع توصيات طبقات للقراءة فقط.';
    }
    if (targetPoint != null) return 'جاهز للفتح على الخريطة.';
    if (matchingRecommendedLayerKeys.isNotEmpty) {
      return 'توجد توصيات طبقات للقراءة فقط؛ التفعيل يتم من واجهة الخريطة.';
    }
    return 'جسر مراجعة فقط؛ يحتاج اختيار نطاق أو استكمال توصيات طبقات.';
  }

  String get targetLabelAr {
    final point = targetPoint;
    if (point == null) return 'لا توجد إحداثية هدف';
    return '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
  }

  String get selectionBboxLabelAr {
    if (selectionPoints.length < 2) return 'لا يوجد نطاق محدد';
    final box = _bboxFromPoints(selectionPoints);
    return 'W: ${box.west.toStringAsFixed(5)}, S: ${box.south.toStringAsFixed(5)}, E: ${box.east.toStringAsFixed(5)}, N: ${box.north.toStringAsFixed(5)}';
  }

  String get runtimeSummaryAr {
    final info = runtimeInfo;
    final loaded = info.featureCount;
    final active = activeLayerKeys.length;
    final queried = info.queryLayerKeys.length;
    final blocked = blockedLayerKeys.length;
    return 'نشطة: $active • محملة/مستعلَمة: $queried • محجوبة: $blocked • عناصر: $loaded';
  }

  String toReportText() {
    final result = selectedResult;
    final buffer = StringBuffer()
      ..writeln('Smart Explorer ↔ Explorer Services Bridge')
      ..writeln('التاريخ: ${DateTime.now().toIso8601String()}')
      ..writeln('الحالة: $bridgeStatusAr')
      ..writeln('الجمهور/الصلاحية الواجهية: ${audience.labelAr}')
      ..writeln()
      ..writeln('1) نتيجة المستكشف الذكي')
      ..writeln('العنوان: ${result?.titleAr ?? 'غير محدد'}')
      ..writeln('رمز الأصل: ${result?.assetCode ?? '-'}')
      ..writeln('الوقف الأم: ${result?.endowmentName ?? '-'}')
      ..writeln('المحافظة: ${result?.governorate ?? '-'}')
      ..writeln('التجمع: ${result?.community ?? '-'}')
      ..writeln('الثقة: ${result?.confidenceScore ?? 0}%')
      ..writeln()
      ..writeln('2) حالة الخريطة')
      ..writeln(runtimeSummaryAr)
      ..writeln('إحداثية الهدف: $targetLabelAr')
      ..writeln('نطاق التحديد: $selectionBboxLabelAr')
      ..writeln('آخر Identify: ${identifyFeatureTitle ?? '-'}')
      ..writeln()
      ..writeln('3) الطبقات')
      ..writeln('نشطة: ${activeLayerKeys.join(', ')}')
      ..writeln('موصى بها: ${recommendedLayerKeys.join(', ')}')
      ..writeln('مطابقة وموجودة: ${matchingRecommendedLayerKeys.join(', ')}')
      ..writeln('محجوبة: ${blockedLayerKeys.join(', ')}')
      ..writeln()
      ..writeln('4) نطاق الاختيار')
      ..writeln('المعالم المحملة داخل النطاق: ${selectedFeaturesInBox.length}');
    for (final feature in selectedFeaturesInBox.take(20)) {
      buffer.writeln('- ${feature.displayTitle} (${feature.layerKey})');
    }
    if (selectedFeaturesInBox.length > 20) {
      buffer.writeln('... تم اختصار القائمة.');
    }
    buffer
      ..writeln()
      ..writeln('ملاحظة: هذا الجسر يقرأ/يجهز/يصدر فقط، ولا يعتمد أي تعديل سيادي مباشر.');
    return buffer.toString();
  }

  String toCsv() {
    final result = selectedResult;
    String esc(String value) => '"${value.replaceAll('"', '""')}"';
    final rows = <List<String>>[
      <String>['field', 'value'],
      <String>['status', bridgeStatusAr],
      <String>['asset_title', result?.titleAr ?? ''],
      <String>['asset_code', result?.assetCode ?? ''],
      <String>['confidence_score', '${result?.confidenceScore ?? 0}'],
      <String>['target', targetLabelAr],
      <String>['runtime', runtimeSummaryAr],
      <String>['selection_bbox', selectionBboxLabelAr],
      <String>['active_layers', activeLayerKeys.join('|')],
      <String>['recommended_layers', recommendedLayerKeys.join('|')],
      <String>['matching_recommended_layers', matchingRecommendedLayerKeys.join('|')],
      <String>['blocked_layers', blockedLayerKeys.join('|')],
      <String>['selected_features_count', '${selectedFeaturesInBox.length}'],
    ];
    return rows.map((row) => row.map(esc).join(',')).join('\n');
  }

  String toAuditHandoffText() {
    final result = selectedResult;
    final buffer = StringBuffer()
      ..writeln('Bridge Batch L — Audit & Cross-Map Deep Link Handoff')
      ..writeln('التاريخ: ${DateTime.now().toIso8601String()}')
      ..writeln('نوع المصدر المقترح: $auditSourceType')
      ..writeln('العنوان المقترح: $auditTitleAr')
      ..writeln('مجال التدقيق: $auditDomainAr')
      ..writeln('الأولوية: $auditPriorityAr')
      ..writeln()
      ..writeln('1) النتيجة الذكية')
      ..writeln('العنوان: ${result?.titleAr ?? '-'}')
      ..writeln('رمز الأصل: ${result?.assetCode ?? '-'}')
      ..writeln('الوقف الأم: ${result?.endowmentName ?? '-'}')
      ..writeln('المحافظة: ${result?.governorate ?? '-'}')
      ..writeln('التجمع: ${result?.community ?? '-'}')
      ..writeln('الثقة: ${result?.confidenceScore ?? 0}%')
      ..writeln('إجراء مقترح: ${result?.recommendedActionAr ?? '-'}')
      ..writeln()
      ..writeln('2) روابط الخرائط')
      ..writeln(crossMapLinks.map((link) => '- ${link.titleAr}: ${link.route}').join('\n'))
      ..writeln()
      ..writeln('3) سياق الخريطة')
      ..writeln(runtimeSummaryAr)
      ..writeln('إحداثية الهدف: $targetLabelAr')
      ..writeln('BBOX: $selectionBboxLabelAr')
      ..writeln('آخر Identify: ${identifyFeatureTitle ?? '-'}')
      ..writeln('طبقات مقترحة مطابقة: ${matchingRecommendedLayerKeys.join(', ')}')
      ..writeln('طبقات محجوبة: ${blockedLayerKeys.join(', ')}')
      ..writeln()
      ..writeln('4) وصف المهمة المقترح')
      ..writeln(auditDescriptionAr)
      ..writeln()
      ..writeln('ملاحظة حوكمة: هذه حزمة توريث/تدقيق فقط، وليست إنشاء مهمة سيادية حتى يعتمد SQL/RBAC.');
    return buffer.toString();
  }

  String toAuditHandoffCsv() {
    String esc(String value) => '"${value.replaceAll('"', '""')}"';
    final result = selectedResult;
    final rows = <List<String>>[
      <String>['field', 'value'],
      <String>['source_type', auditSourceType],
      <String>['title', auditTitleAr],
      <String>['domain', auditDomainAr],
      <String>['priority', auditPriorityAr],
      <String>['asset_id', result?.id ?? ''],
      <String>['asset_title', result?.titleAr ?? ''],
      <String>['asset_code', result?.assetCode ?? ''],
      <String>['confidence_score', '${result?.confidenceScore ?? 0}'],
      <String>['target', targetLabelAr],
      <String>['selection_bbox', selectionBboxLabelAr],
      <String>['matching_layers', matchingRecommendedLayerKeys.join('|')],
      <String>['selected_features_count', '${selectedFeaturesInBox.length}'],
      <String>['modern_map_route', '/map'],
      <String>['historical_map_route', '/history?mode=historical'],
      <String>['waqf_history_route', '/history?mode=waqf'],
      <String>['historical_admin_route', '/history/admin-divisions'],
      <String>['gap_audits_route', '/admin/explorer-gap-audits'],
      <String>['audit_tasks_route', '/admin/audit-tasks'],
    ];
    return rows.map((row) => row.map(esc).join(',')).join('\n');
  }


  String get auditPriorityCode {
    final score = selectedResult?.reviewScore ?? 0;
    if (score >= 72) return 'urgent';
    if (score >= 45) return 'high';
    if (score > 0) return 'normal';
    return 'low';
  }

  String get auditSeverityCode {
    final score = selectedResult?.reviewScore ?? 0;
    if (score >= 45) return 'high';
    if (score > 0) return 'medium';
    return 'low';
  }

  String get explorerModeCode {
    if (auditDomainAr.contains('الإدارية')) return 'historical_admin';
    if (auditDomainAr.contains('القطع') || auditDomainAr.contains('المكاني')) {
      return 'modern';
    }
    if (auditDomainAr.contains('المرجع')) return 'waqf_history';
    return 'smart_bridge';
  }

  ExplorerGapAuditSubmission toExplorerGapAuditSubmission() {
    final result = selectedResult;
    final target = targetPoint;
    final context = <String, dynamic>{
      'source_type': auditSourceType,
      'bridge_batch': 'M_real_audit_creation_review_workflow',
      'asset_id': result?.id,
      'asset_title_ar': result?.titleAr,
      'asset_code': result?.assetCode,
      'endowment_name': result?.endowmentName,
      'governorate': result?.governorate,
      'community': result?.community,
      'lgu': result?.lgu,
      'confidence_score': result?.confidenceScore,
      'review_score': result?.reviewScore,
      'target_lat': target?.latitude,
      'target_lng': target?.longitude,
      'selection_bbox': selectionBboxLabelAr,
      'matching_recommended_layers': matchingRecommendedLayerKeys,
      'active_layers': activeLayerKeys,
      'blocked_layers': blockedLayerKeys,
      'runtime_summary_ar': runtimeSummaryAr,
      'cross_map_routes': {
        for (final link in crossMapLinks) link.id: link.route,
      },
    };

    return ExplorerGapAuditSubmission(
      domain: auditDomainAr,
      severity: auditSeverityCode,
      title: auditTitleAr,
      detail: auditDescriptionAr,
      recommendedAction: result?.recommendedActionAr ?? 'فتح مسار مراجعة من جسر المستكشف الذكي.',
      sample: <String>[
        if (result != null) ...result.evidenceLines,
        if (target != null) 'إحداثية الهدف: $targetLabelAr',
        if (hasSelectionBox) 'BBOX: $selectionBboxLabelAr',
        if (matchingRecommendedLayerKeys.isNotEmpty)
          'طبقات مقترحة: ${matchingRecommendedLayerKeys.join(', ')}',
        if (selectedFeaturesInBox.isNotEmpty)
          'معالم داخل النطاق: ${selectedFeaturesInBox.take(8).map((e) => e.displayTitle).join(' | ')}',
      ],
      explorerMode: explorerModeCode,
      priority: auditPriorityCode,
      reporterNote:
          'أُنشئ من جسر خدمات المستكشف الذكي. لا يعتمد أي تعديل سيادي مباشر.',
      context: context,
    );
  }

  static SmartExplorerBridgeSnapshot fromState({
    required SmartExplorerResult? selectedResult,
    required int filteredResultsCount,
    required int reviewQueueCount,
    required MapState mapState,
    required MapIdentifyResult? identify,
    required LatLng? lastTap,
    required LatLng? gotoMarker,
    required List<LatLng> selectionPoints,
    required MapToolAudience audience,
    required List<String> recommendedLayerKeys,
  }) {
    final availableLayerKeys = mapState.gisLayers
        .where((layer) => layer.isActive && layer.isPublic)
        .map((layer) => layer.key)
        .toList(growable: false);
    final availableSet = availableLayerKeys.toSet();
    final matching = recommendedLayerKeys
        .where(availableSet.contains)
        .toList(growable: false);
    final target = _targetPointFromResult(selectedResult);
    final selectedInBox = _featuresInsideSelection(
      features: mapState.gisFeatures,
      selectionPoints: selectionPoints,
    );

    return SmartExplorerBridgeSnapshot(
      selectedResult: selectedResult,
      filteredResultsCount: filteredResultsCount,
      reviewQueueCount: reviewQueueCount,
      targetPoint: target,
      runtimeInfo: mapState.runtimeInfo,
      activeLayerKeys: mapState.activeLayers,
      availableLayerKeys: availableLayerKeys,
      recommendedLayerKeys: recommendedLayerKeys,
      matchingRecommendedLayerKeys: matching,
      blockedLayerKeys: mapState.runtimeInfo.blockedLayerKeys,
      selectionPoints: selectionPoints,
      selectedFeaturesInBox: selectedInBox,
      identifyFeatureTitle: identify?.feature?.displayTitle,
      lastTap: lastTap,
      gotoMarker: gotoMarker,
      audience: audience,
    );
  }
}

class _Bbox {
  const _Bbox({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  final double west;
  final double south;
  final double east;
  final double north;

  bool contains(LatLng point) {
    return point.longitude >= west &&
        point.longitude <= east &&
        point.latitude >= south &&
        point.latitude <= north;
  }
}

List<String> _recommendedLayerKeys({
  required SmartExplorerResult? selectedResult,
  required Iterable<String>? generatedLayerKeys,
  required List<dynamic> availableLayers,
}) {
  final keys = <String>{};
  if (generatedLayerKeys != null) {
    keys.addAll(generatedLayerKeys.map((item) => item.trim()).where((item) => item.isNotEmpty));
  }

  final result = selectedResult;
  if (result != null) {
    if (!result.hasAnySpatialReference) {
      keys.addAll(_findLayerKeys(
        availableLayers,
        const ['gis_waqf', 'waqf', 'governorate', 'lgu', 'community'],
      ));
    }
    if (!result.hasLinkedParcels) {
      keys.addAll(_findLayerKeys(
        availableLayers,
        const ['natural_blocks_full', 'block', 'parcel', 'taswyeh', 'cadastre'],
      ));
    }
    if (result.missingAdministrativeContext) {
      keys.addAll(_findLayerKeys(
        availableLayers,
        const ['governorate', 'lgu', 'community'],
      ));
    }
  }

  return keys.take(16).toList(growable: false);
}

List<String> _findLayerKeys(List<dynamic> layers, List<String> tokens) {
  final out = <String>[];
  for (final layer in layers) {
    final key = layer.key.toString().trim();
    final nameAr = layer.nameAr.toString().trim();
    final nameEn = (layer.nameEn?.toString() ?? '').trim();
    final haystack = '$key $nameAr $nameEn'.toLowerCase();
    if (tokens.any((token) => haystack.contains(token.toLowerCase()))) {
      out.add(key);
    }
  }
  return out;
}

LatLng? _targetPointFromResult(SmartExplorerResult? result) {
  if (result == null) return null;
  final raw = result.raw;
  if (raw is WaqfAssetModel) {
    if (raw.hasCenter) return LatLng(raw.centerLat!, raw.centerLng!);
    return _pointFromGeoJson(raw.centroidJson) ?? _pointFromGeoJson(raw.geomJson);
  }
  if (raw is Map) {
    final map = raw.cast<String, dynamic>();
    final lat = _readDouble(map, const ['center_lat', 'lat', 'latitude', 'y']);
    final lng = _readDouble(map, const ['center_lng', 'lng', 'longitude', 'x']);
    if (_validLatLng(lat, lng)) return LatLng(lat!, lng!);
    return _pointFromGeoJson(_readMap(map, const [
          'centroid_json',
          'center_json',
          'centroid',
        ])) ??
        _pointFromGeoJson(_readMap(map, const [
          'geom_json',
          'geometry_json',
          'geom',
          'geometry',
        ]));
  }
  return null;
}

List<GisFeatureModel> _featuresInsideSelection({
  required List<GisFeatureModel> features,
  required List<LatLng> selectionPoints,
}) {
  if (selectionPoints.length < 2) return const <GisFeatureModel>[];
  final box = _bboxFromPoints(selectionPoints);
  return features.where((feature) {
    final point = _pointFromGeoJson(feature.centroid) ?? _pointFromGeoJson(feature.geom);
    return point != null && box.contains(point);
  }).toList(growable: false);
}

_Bbox _bboxFromPoints(List<LatLng> points) {
  final a = points[0];
  final b = points[1];
  return _Bbox(
    west: math.min(a.longitude, b.longitude),
    south: math.min(a.latitude, b.latitude),
    east: math.max(a.longitude, b.longitude),
    north: math.max(a.latitude, b.latitude),
  );
}

LatLng? _pointFromGeoJson(Map<String, dynamic>? geo) {
  if (geo == null) return null;
  final type = geo['type']?.toString().toLowerCase();
  final coordinates = geo['coordinates'];
  if (type == 'point' && coordinates is List && coordinates.length >= 2) {
    final lng = _asDouble(coordinates[0]);
    final lat = _asDouble(coordinates[1]);
    if (_validLatLng(lat, lng)) return LatLng(lat!, lng!);
  }
  final first = _firstCoordinatePair(coordinates);
  if (first == null) return null;
  final lng = _asDouble(first[0]);
  final lat = _asDouble(first[1]);
  if (_validLatLng(lat, lng)) return LatLng(lat!, lng!);
  return null;
}

List<dynamic>? _firstCoordinatePair(dynamic value) {
  if (value is! List || value.isEmpty) return null;
  if (value.length >= 2 && value[0] is num && value[1] is num) return value;
  for (final item in value) {
    final result = _firstCoordinatePair(item);
    if (result != null) return result;
  }
  return null;
}

Map<String, dynamic>? _readMap(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is Map) return value.cast<String, dynamic>();
  }
  return null;
}

double? _readDouble(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    final out = _asDouble(value);
    if (out != null && out.isFinite) return out;
  }
  return null;
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool _validLatLng(double? lat, double? lng) {
  return lat != null &&
      lng != null &&
      lat.isFinite &&
      lng.isFinite &&
      lat.abs() <= 90 &&
      lng.abs() <= 180;
}
