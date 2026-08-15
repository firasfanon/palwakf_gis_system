import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../map/data/repositories/map_feedback_repository.dart';
import '../../domain/models/smart_explorer_decision_board.dart';
import '../../domain/models/smart_explorer_document_analysis.dart';
import '../../domain/models/smart_explorer_evidence_matrix.dart';
import '../../domain/models/smart_explorer_field_checklist.dart';
import '../../domain/models/smart_explorer_gazetteer_entry.dart';
import '../../domain/models/smart_explorer_filter.dart';
import '../../domain/models/smart_explorer_hypothesis.dart';
import '../../domain/models/smart_explorer_qa_scenario.dart';
import '../../domain/models/smart_explorer_result.dart';
import '../../domain/models/smart_explorer_readiness.dart';
import '../../domain/models/smart_explorer_risk_register.dart';
import '../../domain/models/smart_explorer_knowledge_card.dart';
import '../../domain/models/smart_explorer_layer_recommendation.dart';
import '../../domain/models/smart_explorer_validation_protocol.dart';
import '../../domain/models/smart_explorer_work_package.dart';
import '../../domain/models/smart_explorer_route_plan.dart';
import '../../domain/models/smart_explorer_investigation_session.dart';
import '../../domain/models/smart_explorer_hypothesis_comparison.dart';
import '../../domain/models/smart_explorer_data_lineage.dart';
import '../../domain/models/smart_explorer_closure_gate.dart';
import '../../domain/models/smart_explorer_action_plan.dart';
import '../../domain/models/smart_explorer_stakeholder_matrix.dart';
import '../../domain/models/smart_explorer_decision_log.dart';
import '../../domain/models/smart_explorer_export_bundle.dart';
import '../../domain/models/smart_explorer_quality_scorecard.dart';
import '../../domain/models/smart_explorer_review_workflow.dart';
import '../../domain/models/smart_explorer_assumption_ledger.dart';
import '../../domain/models/smart_explorer_cross_system_bridge.dart';
import '../../domain/models/smart_explorer_expected_outcomes.dart';
import '../../domain/models/smart_explorer_source_acquisition_plan.dart';
import '../../domain/models/smart_explorer_confidence_zone.dart';
import '../../domain/models/smart_explorer_temporal_admin_trace.dart';
import '../../domain/models/smart_explorer_audit_playbook.dart';
import '../../domain/models/smart_explorer_release_readiness.dart';
import '../../domain/models/smart_explorer_runtime_diagnostics.dart';
import '../providers/smart_explorer_repository_provider.dart';
import '../state/smart_explorer_state.dart';

class SmartExplorerController extends Notifier<SmartExplorerState> {
  Timer? _debounce;

  @override
  SmartExplorerState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(loadRecentAuditRequests);
    return const SmartExplorerState();
  }

  Future<void> loadRecentAuditRequests() async {
    state = state.copyWith(
      isLoadingAuditRequests: true,
      actionErrorMessage: null,
    );
    try {
      final requests = await ref
          .read(smartExplorerRepositoryProvider)
          .listRecentAuditRequests(limit: 10);
      state = state.copyWith(
        isLoadingAuditRequests: false,
        recentAuditRequests: requests,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingAuditRequests: false,
        actionErrorMessage: 'تعذر تحميل آخر طلبات التدقيق: $error',
      );
    }
  }

  void setQuery(String value) {
    state = state.copyWith(
      query: value,
      errorMessage: null,
      actionMessage: null,
      actionErrorMessage: null,
      reportText: null,
    );
    _debounce?.cancel();

    final query = value.trim();
    if (query.length < 2) {
      state = state.copyWith(
        results: const <SmartExplorerResult>[],
        selectedResultId: null,
        generatedHypothesis: null,
      );
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 420),
      () => search(query),
    );
  }

  Future<void> search([String? overrideQuery]) async {
    final query = (overrideQuery ?? state.query).trim();
    if (query.isEmpty) {
      state = state.copyWith(
        results: const <SmartExplorerResult>[],
        selectedResultId: null,
        generatedHypothesis: null,
        errorMessage: null,
        reportText: null,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      actionMessage: null,
      actionErrorMessage: null,
      reportText: null,
      query: query,
    );

    try {
      final results = await ref
          .read(smartExplorerRepositoryProvider)
          .search(query: query);
      state = state.copyWith(
        isLoading: false,
        results: results,
        selectedResultId: results.isNotEmpty ? results.first.id : null,
        generatedHypothesis: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر تشغيل البحث الذكي: $error',
      );
    }
  }

  void selectResult(String id) {
    state = state.copyWith(selectedResultId: id);
  }

  void setSeverityFilter(SmartExplorerSeverityFilter severity) {
    state = state.copyWith(
      filters: state.filters.copyWith(severity: severity),
      selectedResultId: null,
      reportText: null,
    );
  }

  void setMinConfidence(int value) {
    state = state.copyWith(
      filters: state.filters.copyWith(minConfidence: value),
      selectedResultId: null,
      reportText: null,
    );
  }

  void toggleOnlyNeedsReview(bool value) {
    state = state.copyWith(
      filters: state.filters.copyWith(onlyNeedsReview: value),
      selectedResultId: null,
      reportText: null,
    );
  }

  void toggleOnlyWithoutSpatialReference(bool value) {
    state = state.copyWith(
      filters: state.filters.copyWith(onlyWithoutSpatialReference: value),
      selectedResultId: null,
      reportText: null,
    );
  }

  void toggleOnlyWithoutLinkedParcels(bool value) {
    state = state.copyWith(
      filters: state.filters.copyWith(onlyWithoutLinkedParcels: value),
      selectedResultId: null,
      reportText: null,
    );
  }

  void toggleOnlyMissingEndowment(bool value) {
    state = state.copyWith(
      filters: state.filters.copyWith(onlyMissingEndowment: value),
      selectedResultId: null,
      reportText: null,
    );
  }

  void clearFilters() {
    state = state.copyWith(
      filters: SmartExplorerFilters.empty,
      selectedResultId: state.results.isNotEmpty ? state.results.first.id : null,
      reportText: null,
    );
  }

  SmartExplorerHypothesis generateLocalHypothesis(SmartExplorerResult result) {
    final evidence = result.evidenceLines;

    final hypothesis = SmartExplorerHypothesis(
      id: 'hyp-${DateTime.now().millisecondsSinceEpoch}',
      titleAr: 'فرضية تدقيق: ${result.titleAr}',
      summaryAr: result.gapSignals.isEmpty
          ? 'لا توجد فجوات ظاهرة في القواعد الأولية، ويمكن استخدام النتيجة كنقطة انتقال للتحليل المكاني/التاريخي.'
          : 'توجد إشارات تحتاج مراجعة قبل اعتماد الربط المكاني أو التاريخي للأصل.',
      confidence: result.confidenceScore / 100,
      evidence: evidence,
      status: result.gapSignals.isEmpty
          ? SmartExplorerHypothesisStatus.draft
          : SmartExplorerHypothesisStatus.needsReview,
      intent: _intentForResult(result),
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      generatedHypothesis: hypothesis,
      actionMessage: 'تم إنشاء فرضية محلية للمراجعة، ولم يتم تعديل أي سجل سيادي.',
      actionErrorMessage: null,
    );
    return hypothesis;
  }

  Future<ExplorerGapAuditRequest?> createAuditRequest(
    SmartExplorerResult result,
  ) async {
    state = state.copyWith(
      isLoadingAuditRequests: true,
      actionMessage: null,
      actionErrorMessage: null,
    );

    try {
      final request = await ref
          .read(smartExplorerRepositoryProvider)
          .createAuditRequestFromResult(result);
      final requests = <ExplorerGapAuditRequest>[
        request,
        ...state.recentAuditRequests.where((item) => item.id != request.id),
      ];
      state = state.copyWith(
        isLoadingAuditRequests: false,
        recentAuditRequests: requests.take(10).toList(growable: false),
        actionMessage: 'تم إنشاء طلب تدقيق ذكي رقم ${request.id}.',
      );
      return request;
    } catch (error) {
      state = state.copyWith(
        isLoadingAuditRequests: false,
        actionErrorMessage: 'تعذر إنشاء طلب التدقيق: $error',
      );
      return null;
    }
  }

  Future<List<ExplorerGapAuditRequest>> createAuditRequestsForReviewQueue() async {
    final queue = state.reviewQueue;
    if (queue.isEmpty) {
      state = state.copyWith(
        actionErrorMessage: 'لا توجد نتائج ضمن قائمة المراجعة الحالية.',
      );
      return const <ExplorerGapAuditRequest>[];
    }

    state = state.copyWith(
      isCreatingBatchRequests: true,
      actionMessage: null,
      actionErrorMessage: null,
    );

    try {
      final created = await ref
          .read(smartExplorerRepositoryProvider)
          .createAuditRequestsFromResults(queue, limit: 5);
      final requests = <ExplorerGapAuditRequest>[
        ...created,
        ...state.recentAuditRequests
            .where((item) => !created.any((request) => request.id == item.id)),
      ];
      state = state.copyWith(
        isCreatingBatchRequests: false,
        recentAuditRequests: requests.take(10).toList(growable: false),
        actionMessage:
            'تم إنشاء ${created.length} طلب تدقيق من أعلى قائمة المراجعة الحالية.',
      );
      return created;
    } catch (error) {
      state = state.copyWith(
        isCreatingBatchRequests: false,
        actionErrorMessage: 'تعذر إنشاء طلبات التدقيق الجماعية: $error',
      );
      return const <ExplorerGapAuditRequest>[];
    }
  }

  String generateCurrentReport() {
    final report = ref
        .read(smartExplorerRepositoryProvider)
        .buildTextReport(state.filteredResults);
    state = state.copyWith(
      reportText: report,
      actionMessage: 'تم توليد تقرير نصي للنطاق الحالي.',
      actionErrorMessage: null,
    );
    return report;
  }

  void clearReport() {
    state = state.copyWith(reportText: null);
  }

  void setDocumentDraft(String value) {
    state = state.copyWith(
      documentDraft: value,
      actionMessage: null,
      actionErrorMessage: null,
    );
  }

  SmartExplorerDocumentAnalysis analyzeDocumentDraft() {
    state = state.copyWith(
      isAnalyzingDocument: true,
      actionMessage: null,
      actionErrorMessage: null,
    );

    final analysis = ref
        .read(smartExplorerRepositoryProvider)
        .analyzeDocumentText(state.documentDraft);

    state = state.copyWith(
      isAnalyzingDocument: false,
      documentAnalysis: analysis,
      actionMessage: analysis.hasEvidence
          ? 'تم تحليل النص واستخراج ${analysis.evidenceCount} قرينة غير سيادية.'
          : 'تم التحليل، لكن النص لا يحتوي قرائن كافية بعد.',
    );
    return analysis;
  }

  void clearDocumentAnalysis() {
    state = state.copyWith(
      documentAnalysis: null,
      actionMessage: null,
      actionErrorMessage: null,
    );
  }

  SmartExplorerRoutePlan generateRoutePlan() {
    final plan = ref
        .read(smartExplorerRepositoryProvider)
        .buildRoutePlan(state.filteredResults);
    state = state.copyWith(
      routePlan: plan,
      actionMessage: plan.isEmpty
          ? 'لا توجد نتائج كافية لبناء مسار تدقيق.'
          : 'تم بناء مسار تدقيق مقترح من ${plan.totalStops} نقاط.',
      actionErrorMessage: null,
    );
    return plan;
  }

  void clearRoutePlan() {
    state = state.copyWith(routePlan: null);
  }

  String generateInvestigationReport() {
    final report = ref.read(smartExplorerRepositoryProvider).buildInvestigationReport(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          routePlan: state.routePlan,
          gazetteerEntries: state.gazetteerEntries,
          evidenceMatrix: state.evidenceMatrix,
          readinessAssessments: state.readinessAssessments,
        );
    state = state.copyWith(
      investigationReportText: report,
      actionMessage: 'تم توليد تقرير تحقيق مكاني/تاريخي موحد.',
      actionErrorMessage: null,
    );
    return report;
  }

  void clearInvestigationReport() {
    state = state.copyWith(investigationReportText: null);
  }

  List<SmartExplorerGazetteerEntry> generateGazetteerDraft() {
    final entries = ref.read(smartExplorerRepositoryProvider).buildGazetteerDraft(
          documentAnalysis: state.documentAnalysis,
          results: state.filteredResults,
        );
    state = state.copyWith(
      gazetteerEntries: entries,
      actionMessage: entries.isEmpty
          ? 'لم تتوفر مسميات كافية لبناء قاموس مسودة.'
          : 'تم بناء قاموس مسميات مسودة من ${entries.length} مدخلًا.',
      actionErrorMessage: null,
    );
    return entries;
  }

  void clearGazetteerDraft() {
    state = state.copyWith(gazetteerEntries: const <SmartExplorerGazetteerEntry>[]);
  }

  SmartExplorerEvidenceMatrix generateEvidenceMatrix() {
    final matrix = ref.read(smartExplorerRepositoryProvider).buildEvidenceMatrix(
          documentAnalysis: state.documentAnalysis,
          results: state.filteredResults,
        );
    state = state.copyWith(
      evidenceMatrix: matrix,
      actionMessage: matrix.hasLinks
          ? 'تم بناء مصفوفة أدلة من ${matrix.links.length} رابطًا.'
          : 'لا توجد روابط كافية بين الوثيقة والنتائج الحالية.',
      actionErrorMessage: null,
    );
    return matrix;
  }

  void clearEvidenceMatrix() {
    state = state.copyWith(evidenceMatrix: null);
  }

  List<SmartExplorerReadinessAssessment> generateReadinessAssessments() {
    final assessments = ref
        .read(smartExplorerRepositoryProvider)
        .assessReadiness(state.filteredResults);
    state = state.copyWith(
      readinessAssessments: assessments,
      actionMessage: assessments.isEmpty
          ? 'لا توجد نتائج لتقييم الجاهزية.'
          : 'تم تقييم جاهزية ${assessments.length} نتيجة ضمن النطاق الحالي.',
      actionErrorMessage: null,
    );
    return assessments;
  }

  void clearReadinessAssessments() {
    state = state.copyWith(
      readinessAssessments: const <SmartExplorerReadinessAssessment>[],
    );
  }

  String generateReviewQueueCsv() {
    final csv = ref
        .read(smartExplorerRepositoryProvider)
        .buildReviewQueueCsv(state.filteredResults);
    state = state.copyWith(
      exportText: csv,
      actionMessage: 'تم توليد CSV لقائمة المراجعة الحالية.',
      actionErrorMessage: null,
    );
    return csv;
  }

  String generateGazetteerCsv() {
    final csv = ref
        .read(smartExplorerRepositoryProvider)
        .buildGazetteerCsv(state.gazetteerEntries);
    state = state.copyWith(
      exportText: csv,
      actionMessage: 'تم توليد CSV لقاموس المسميات المسودة.',
      actionErrorMessage: null,
    );
    return csv;
  }

  void clearExportText() {
    state = state.copyWith(exportText: null);
  }

  String loadSampleDocument() {
    final sample = ref.read(smartExplorerRepositoryProvider).sampleDocumentText();
    state = state.copyWith(
      documentDraft: sample,
      documentAnalysis: null,
      actionMessage: 'تم إدراج نص وثيقة تجريبي للتدريب على التحليل.',
      actionErrorMessage: null,
    );
    return sample;
  }

  SmartExplorerDecisionBoard generateDecisionBoard() {
    final board = ref.read(smartExplorerRepositoryProvider).buildDecisionBoard(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          readinessAssessments: state.readinessAssessments,
          routePlan: state.routePlan,
        );
    state = state.copyWith(
      decisionBoard: board,
      actionMessage: board.isEmpty
          ? 'لا توجد قرارات تشغيلية مقترحة ضمن النطاق الحالي.'
          : 'تم توليد لوحة قرار تضم ${board.items.length} بندًا.',
      actionErrorMessage: null,
    );
    return board;
  }

  void clearDecisionBoard() {
    state = state.copyWith(decisionBoard: null);
  }

  String generateWorkspaceSnapshot() {
    final snapshot = ref.read(smartExplorerRepositoryProvider).buildWorkspaceSnapshot(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          readinessAssessments: state.readinessAssessments,
          routePlan: state.routePlan,
          decisionBoard: state.decisionBoard,
        );
    state = state.copyWith(
      workspaceSnapshotText: snapshot,
      actionMessage: 'تم توليد لقطة عمل قابلة للنسخ والتوريث.',
      actionErrorMessage: null,
    );
    return snapshot;
  }

  void clearWorkspaceSnapshot() {
    state = state.copyWith(workspaceSnapshotText: null);
  }

  SmartExplorerFieldChecklist generateFieldChecklist() {
    final checklist = ref.read(smartExplorerRepositoryProvider).buildFieldChecklist(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          readinessAssessments: state.readinessAssessments,
        );
    state = state.copyWith(
      fieldChecklist: checklist,
      actionMessage: checklist.isEmpty
          ? 'لا توجد بنود تدقيق ميداني ضمن النطاق الحالي.'
          : 'تم توليد قائمة تدقيق تضم ${checklist.totalItems} بندًا.',
      actionErrorMessage: null,
    );
    return checklist;
  }

  void clearFieldChecklist() {
    state = state.copyWith(fieldChecklist: null);
  }

  SmartExplorerRiskRegister generateRiskRegister() {
    final register = ref.read(smartExplorerRepositoryProvider).buildRiskRegister(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          readinessAssessments: state.readinessAssessments,
        );
    state = state.copyWith(
      riskRegister: register,
      actionMessage: register.isEmpty
          ? 'لا توجد مخاطر تشغيلية ظاهرة ضمن النطاق الحالي.'
          : 'تم توليد سجل مخاطر بتقييم عام: ${register.overallLabelAr}.',
      actionErrorMessage: null,
    );
    return register;
  }

  void clearRiskRegister() {
    state = state.copyWith(riskRegister: null);
  }

  List<SmartExplorerQaScenario> generateQaScenarios() {
    final scenarios = ref.read(smartExplorerRepositoryProvider).buildQaScenarios(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          riskRegister: state.riskRegister,
        );
    state = state.copyWith(
      qaScenarios: scenarios,
      actionMessage: scenarios.isEmpty
          ? 'لا توجد سيناريوهات اختبار إضافية ضمن النطاق الحالي.'
          : 'تم توليد ${scenarios.length} سيناريو اختبار للمستكشف الذكي.',
      actionErrorMessage: null,
    );
    return scenarios;
  }

  void clearQaScenarios() {
    state = state.copyWith(qaScenarios: const <SmartExplorerQaScenario>[]);
  }

  String generateHandoffPacket() {
    final packet = ref.read(smartExplorerRepositoryProvider).buildHandoffPacket(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          readinessAssessments: state.readinessAssessments,
          routePlan: state.routePlan,
          decisionBoard: state.decisionBoard,
          fieldChecklist: state.fieldChecklist,
          riskRegister: state.riskRegister,
          qaScenarios: state.qaScenarios,
          workPackages: state.workPackages,
          layerRecommendations: state.layerRecommendations,
          validationProtocol: state.validationProtocol,
          knowledgeCards: state.knowledgeCards,
        );
    state = state.copyWith(
      handoffPacketText: packet,
      actionMessage: 'تم توليد حزمة توريث تشغيلية للمستكشف الذكي.',
      actionErrorMessage: null,
    );
    return packet;
  }

  void clearHandoffPacket() {
    state = state.copyWith(handoffPacketText: null);
  }

  SmartExplorerWorkPackageSet generateWorkPackages() {
    final packages = ref.read(smartExplorerRepositoryProvider).buildWorkPackages(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          readinessAssessments: state.readinessAssessments,
          riskRegister: state.riskRegister,
        );
    state = state.copyWith(
      workPackages: packages,
      actionMessage: packages.isEmpty
          ? 'لا توجد حزم عمل ضمن النطاق الحالي.'
          : 'تم توليد ${packages.totalPackages} حزمة عمل تشغيلية.',
      actionErrorMessage: null,
    );
    return packages;
  }

  void clearWorkPackages() {
    state = state.copyWith(workPackages: null);
  }

  SmartExplorerLayerRecommendationSet generateLayerRecommendations() {
    final recommendations = ref
        .read(smartExplorerRepositoryProvider)
        .buildLayerRecommendations(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
        );
    state = state.copyWith(
      layerRecommendations: recommendations,
      actionMessage: recommendations.isEmpty
          ? 'لا توجد طبقات مقترحة ضمن النطاق الحالي.'
          : 'تم توليد ${recommendations.totalRecommendations} توصية طبقات للفحص.',
      actionErrorMessage: null,
    );
    return recommendations;
  }

  void clearLayerRecommendations() {
    state = state.copyWith(layerRecommendations: null);
  }

  SmartExplorerValidationProtocol generateValidationProtocol() {
    final protocol = ref.read(smartExplorerRepositoryProvider).buildValidationProtocol(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          riskRegister: state.riskRegister,
        );
    state = state.copyWith(
      validationProtocol: protocol,
      actionMessage: 'تم توليد بروتوكول تحقق يضم ${protocol.totalGates} بوابات.',
      actionErrorMessage: null,
    );
    return protocol;
  }

  void clearValidationProtocol() {
    state = state.copyWith(validationProtocol: null);
  }

  SmartExplorerKnowledgeCardSet generateKnowledgeCards() {
    final cards = ref.read(smartExplorerRepositoryProvider).buildKnowledgeCards(
          documentAnalysis: state.documentAnalysis,
          results: state.filteredResults,
          evidenceMatrix: state.evidenceMatrix,
        );
    state = state.copyWith(
      knowledgeCards: cards,
      actionMessage: cards.isEmpty
          ? 'لا توجد بطاقات معرفة ضمن النطاق الحالي.'
          : 'تم توليد ${cards.totalCards} بطاقة معرفة للمراجعة.',
      actionErrorMessage: null,
    );
    return cards;
  }

  void clearKnowledgeCards() {
    state = state.copyWith(knowledgeCards: null);
  }

  String generateExecutiveBrief() {
    final brief = ref.read(smartExplorerRepositoryProvider).buildExecutiveBrief(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          riskRegister: state.riskRegister,
          validationProtocol: state.validationProtocol,
          workPackages: state.workPackages,
          layerRecommendations: state.layerRecommendations,
          knowledgeCards: state.knowledgeCards,
        );
    state = state.copyWith(
      executiveBriefText: brief,
      actionMessage: 'تم توليد موجز تنفيذي للمراجعة والتوريث.',
      actionErrorMessage: null,
    );
    return brief;
  }

  void clearExecutiveBrief() {
    state = state.copyWith(executiveBriefText: null);
  }


  SmartExplorerInvestigationSession generateInvestigationSession() {
    final session = ref.read(smartExplorerRepositoryProvider).buildInvestigationSession(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          readinessAssessments: state.readinessAssessments,
          riskRegister: state.riskRegister,
          validationProtocol: state.validationProtocol,
          workPackages: state.workPackages,
        );
    state = state.copyWith(
      investigationSession: session,
      actionMessage: 'تم بناء جلسة تحقيق تشغيلية تضم ${session.totalStages} مراحل.',
      actionErrorMessage: null,
    );
    return session;
  }

  void clearInvestigationSession() {
    state = state.copyWith(investigationSession: null);
  }

  SmartExplorerHypothesisComparison generateHypothesisComparison() {
    final comparison = ref.read(smartExplorerRepositoryProvider).buildHypothesisComparison(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
        );
    state = state.copyWith(
      hypothesisComparison: comparison,
      actionMessage: comparison.isEmpty
          ? 'لا توجد فرضيات كافية للمقارنة.'
          : 'تمت مقارنة ${comparison.totalCandidates} فرضية مكانية/وثائقية.',
      actionErrorMessage: null,
    );
    return comparison;
  }

  void clearHypothesisComparison() {
    state = state.copyWith(hypothesisComparison: null);
  }

  SmartExplorerDataLineage generateDataLineage() {
    final lineage = ref.read(smartExplorerRepositoryProvider).buildDataLineage(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          gazetteerEntries: state.gazetteerEntries,
          evidenceMatrix: state.evidenceMatrix,
          readinessAssessments: state.readinessAssessments,
          knowledgeCards: state.knowledgeCards,
        );
    state = state.copyWith(
      dataLineage: lineage,
      actionMessage: lineage.isEmpty
          ? 'لا يوجد أثر بيانات كافٍ للنطاق الحالي.'
          : 'تم توليد أثر بيانات يضم ${lineage.totalItems} عنصرًا.',
      actionErrorMessage: null,
    );
    return lineage;
  }

  void clearDataLineage() {
    state = state.copyWith(dataLineage: null);
  }

  SmartExplorerClosureGate generateClosureGate() {
    final gate = ref.read(smartExplorerRepositoryProvider).buildClosureGate(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          riskRegister: state.riskRegister,
          validationProtocol: state.validationProtocol,
          workPackages: state.workPackages,
        );
    state = state.copyWith(
      closureGate: gate,
      actionMessage: 'تم توليد بوابة الإغلاق: ${gate.summaryAr}',
      actionErrorMessage: null,
    );
    return gate;
  }

  void clearClosureGate() {
    state = state.copyWith(closureGate: null);
  }

  String generateFinalIntegrationMemo() {
    final memo = ref.read(smartExplorerRepositoryProvider).buildFinalIntegrationMemo(
          query: state.query,
          results: state.filteredResults,
          investigationSession: state.investigationSession,
          hypothesisComparison: state.hypothesisComparison,
          dataLineage: state.dataLineage,
          closureGate: state.closureGate,
          workPackages: state.workPackages,
          validationProtocol: state.validationProtocol,
        );
    state = state.copyWith(
      finalIntegrationMemoText: memo,
      actionMessage: 'تم توليد مذكرة دمج تشغيلية للمستكشف الذكي.',
      actionErrorMessage: null,
    );
    return memo;
  }

  void clearFinalIntegrationMemo() {
    state = state.copyWith(finalIntegrationMemoText: null);
  }


  SmartExplorerActionPlan generateActionPlan() {
    final plan = ref.read(smartExplorerRepositoryProvider).buildActionPlan(
          results: state.filteredResults,
          fieldChecklist: state.fieldChecklist,
          workPackages: state.workPackages,
          validationProtocol: state.validationProtocol,
          closureGate: state.closureGate,
          riskRegister: state.riskRegister,
        );
    state = state.copyWith(
      actionPlan: plan,
      actionMessage: plan.isEmpty
          ? 'لا توجد إجراءات تشغيلية ضمن النطاق الحالي.'
          : 'تم توليد خطة إجراءات تضم ${plan.totalItems} بندًا.',
      actionErrorMessage: null,
    );
    return plan;
  }

  void clearActionPlan() {
    state = state.copyWith(actionPlan: null);
  }

  SmartExplorerStakeholderMatrix generateStakeholderMatrix() {
    final matrix = ref.read(smartExplorerRepositoryProvider).buildStakeholderMatrix(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          riskRegister: state.riskRegister,
          closureGate: state.closureGate,
        );
    state = state.copyWith(
      stakeholderMatrix: matrix,
      actionMessage: 'تم توليد مصفوفة أصحاب علاقة تضم ${matrix.totalItems} أدوار.',
      actionErrorMessage: null,
    );
    return matrix;
  }

  void clearStakeholderMatrix() {
    state = state.copyWith(stakeholderMatrix: null);
  }

  SmartExplorerDecisionLog generateDecisionLog() {
    final log = ref.read(smartExplorerRepositoryProvider).buildDecisionLog(
          results: state.filteredResults,
          decisionBoard: state.decisionBoard,
          closureGate: state.closureGate,
          actionPlan: state.actionPlan,
        );
    state = state.copyWith(
      decisionLog: log,
      actionMessage: log.isEmpty
          ? 'لا توجد قرارات تشغيلية كافية للتسجيل.'
          : 'تم توليد سجل قرارات يضم ${log.totalEntries} بندًا.',
      actionErrorMessage: null,
    );
    return log;
  }

  void clearDecisionLog() {
    state = state.copyWith(decisionLog: null);
  }

  SmartExplorerQualityScorecard generateQualityScorecard() {
    final weakestReadiness = state.readinessAssessments.isEmpty
        ? null
        : (List<SmartExplorerReadinessAssessment>.from(state.readinessAssessments)
          ..sort((a, b) => a.overallScore.compareTo(b.overallScore)))
            .first;
    final card = ref.read(smartExplorerRepositoryProvider).buildQualityScorecard(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          weakestReadiness: weakestReadiness,
          riskRegister: state.riskRegister,
          closureGate: state.closureGate,
        );
    state = state.copyWith(
      qualityScorecard: card,
      actionMessage: 'تم توليد بطاقة جودة بدرجة ${card.overallScore}%.',
      actionErrorMessage: null,
    );
    return card;
  }

  void clearQualityScorecard() {
    state = state.copyWith(qualityScorecard: null);
  }

  SmartExplorerReviewWorkflow generateReviewWorkflow() {
    final workflow = ref.read(smartExplorerRepositoryProvider).buildReviewWorkflow(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          closureGate: state.closureGate,
          actionPlan: state.actionPlan,
        );
    state = state.copyWith(
      reviewWorkflow: workflow,
      actionMessage: workflow.summaryAr,
      actionErrorMessage: null,
    );
    return workflow;
  }

  void clearReviewWorkflow() {
    state = state.copyWith(reviewWorkflow: null);
  }

  SmartExplorerAssumptionLedger generateAssumptionLedger() {
    final ledger = ref.read(smartExplorerRepositoryProvider).buildAssumptionLedger(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          hypothesisComparison: state.hypothesisComparison,
        );
    state = state.copyWith(
      assumptionLedger: ledger,
      actionMessage: ledger.summaryAr,
      actionErrorMessage: null,
    );
    return ledger;
  }

  void clearAssumptionLedger() {
    state = state.copyWith(assumptionLedger: null);
  }

  SmartExplorerCrossSystemBridgePlan generateCrossSystemBridgePlan() {
    final plan = ref.read(smartExplorerRepositoryProvider).buildCrossSystemBridgePlan(
          results: state.filteredResults,
          actionPlan: state.actionPlan,
          closureGate: state.closureGate,
          exportBundle: state.exportBundle,
        );
    state = state.copyWith(
      crossSystemBridgePlan: plan,
      actionMessage: plan.summaryAr,
      actionErrorMessage: null,
    );
    return plan;
  }

  void clearCrossSystemBridgePlan() {
    state = state.copyWith(crossSystemBridgePlan: null);
  }


  SmartExplorerExpectedOutcomes generateExpectedOutcomes() {
    final outcomes = ref.read(smartExplorerRepositoryProvider).buildExpectedOutcomes(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          readinessAssessments: state.readinessAssessments,
          qualityScorecard: state.qualityScorecard,
          closureGate: state.closureGate,
        );
    state = state.copyWith(
      expectedOutcomes: outcomes,
      actionMessage: outcomes.summaryAr,
      actionErrorMessage: null,
    );
    return outcomes;
  }

  void clearExpectedOutcomes() {
    state = state.copyWith(expectedOutcomes: null);
  }

  SmartExplorerSourceAcquisitionPlan generateSourceAcquisitionPlan() {
    final plan = ref.read(smartExplorerRepositoryProvider).buildSourceAcquisitionPlan(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          assumptionLedger: state.assumptionLedger,
        );
    state = state.copyWith(
      sourceAcquisitionPlan: plan,
      actionMessage: plan.summaryAr,
      actionErrorMessage: null,
    );
    return plan;
  }

  void clearSourceAcquisitionPlan() {
    state = state.copyWith(sourceAcquisitionPlan: null);
  }

  SmartExplorerConfidenceZoneSet generateConfidenceZones() {
    final zones = ref.read(smartExplorerRepositoryProvider).buildConfidenceZones(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
        );
    state = state.copyWith(
      confidenceZones: zones,
      actionMessage: zones.summaryAr,
      actionErrorMessage: null,
    );
    return zones;
  }

  void clearConfidenceZones() {
    state = state.copyWith(confidenceZones: null);
  }

  SmartExplorerTemporalAdminTrace generateTemporalAdminTrace() {
    final trace = ref.read(smartExplorerRepositoryProvider).buildTemporalAdminTrace(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          gazetteerEntries: state.gazetteerEntries,
        );
    state = state.copyWith(
      temporalAdminTrace: trace,
      actionMessage: trace.summaryAr,
      actionErrorMessage: null,
    );
    return trace;
  }

  void clearTemporalAdminTrace() {
    state = state.copyWith(temporalAdminTrace: null);
  }

  SmartExplorerAuditPlaybook generateAuditPlaybook() {
    final playbook = ref.read(smartExplorerRepositoryProvider).buildAuditPlaybook(
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          sourcePlan: state.sourceAcquisitionPlan,
          confidenceZones: state.confidenceZones,
          closureGate: state.closureGate,
        );
    state = state.copyWith(
      auditPlaybook: playbook,
      actionMessage: playbook.summaryAr,
      actionErrorMessage: null,
    );
    return playbook;
  }

  void clearAuditPlaybook() {
    state = state.copyWith(auditPlaybook: null);
  }

  SmartExplorerReleaseReadiness generateReleaseReadiness() {
    final readiness = ref.read(smartExplorerRepositoryProvider).buildReleaseReadiness(
          results: state.filteredResults,
          qualityScorecard: state.qualityScorecard,
          closureGate: state.closureGate,
          sourcePlan: state.sourceAcquisitionPlan,
          auditPlaybook: state.auditPlaybook,
        );
    state = state.copyWith(
      releaseReadiness: readiness,
      actionMessage: readiness.summaryAr,
      actionErrorMessage: null,
    );
    return readiness;
  }

  void clearReleaseReadiness() {
    state = state.copyWith(releaseReadiness: null);
  }

  SmartExplorerRuntimeDiagnostics generateRuntimeDiagnostics() {
    final diagnostics = ref
        .read(smartExplorerRepositoryProvider)
        .buildRuntimeDiagnostics(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          sourcePlan: state.sourceAcquisitionPlan,
          auditPlaybook: state.auditPlaybook,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      runtimeDiagnostics: diagnostics,
      actionMessage: diagnostics.summaryAr,
      actionErrorMessage: null,
    );
    return diagnostics;
  }

  void clearRuntimeDiagnostics() {
    state = state.copyWith(runtimeDiagnostics: null);
  }

  String generateStrategicOutcomePack() {
    final text = ref.read(smartExplorerRepositoryProvider).buildStrategicOutcomePack(
          expectedOutcomes: state.expectedOutcomes,
          sourcePlan: state.sourceAcquisitionPlan,
          confidenceZones: state.confidenceZones,
          temporalTrace: state.temporalAdminTrace,
          auditPlaybook: state.auditPlaybook,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد الحزمة الاستراتيجية الموسعة.',
      actionErrorMessage: null,
    );
    return text;
  }


  String generateCurrentBaselineSafeExpansionPack() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildCurrentBaselineSafeExpansionPack(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          reviewWorkflow: state.reviewWorkflow,
          assumptionLedger: state.assumptionLedger,
          sourcePlan: state.sourceAcquisitionPlan,
          confidenceZones: state.confidenceZones,
          temporalTrace: state.temporalAdminTrace,
          auditPlaybook: state.auditPlaybook,
          releaseReadiness: state.releaseReadiness,
          runtimeDiagnostics: state.runtimeDiagnostics,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد حزمة تطوير آمنة فوق baseline الحالي دون استبدال الخريطة أو البحث أو الراوتر.',
      actionErrorMessage: null,
    );
    return text;
  }


  String generateSelfDevelopmentPack() {
    final pack = ref
        .read(smartExplorerRepositoryProvider)
        .buildSelfDevelopmentPack(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          sourcePlan: state.sourceAcquisitionPlan,
          releaseReadiness: state.releaseReadiness,
        );
    final text = pack.toReportText();
    state = state.copyWith(
      exportText: text,
      actionMessage:
          'تم توليد حزمة التطوير الذاتي الآمنة دون تعديل الخريطة أو البحث أو الراوتر.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateLocalAnalyzerContract() {
    final contract = ref
        .read(smartExplorerRepositoryProvider)
        .buildLocalAnalyzerContract(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
        );
    final text = contract.toReportText();
    state = state.copyWith(
      exportText: text,
      actionMessage:
          'تم توليد عقد المحلل المحلي كوثيقة تشغيلية read-only.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateSelfDevelopmentCsv() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildSelfDevelopmentCsv(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          sourcePlan: state.sourceAcquisitionPlan,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد CSV لبنود التطوير الذاتي وفحوص القبول.',
      actionErrorMessage: null,
    );
    return text;
  }


  String generateAutonomousQaPack() {
    final pack = ref
        .read(smartExplorerRepositoryProvider)
        .buildAutonomousQaPack(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          sourcePlan: state.sourceAcquisitionPlan,
          releaseReadiness: state.releaseReadiness,
        );
    final text = pack.toReportText();
    state = state.copyWith(
      exportText: text,
      actionMessage:
          'تم توليد QA ذاتي للمستكشف الذكي: ${pack.readinessLabelAr}.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateAutonomousQaCsv() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildAutonomousQaCsv(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          sourcePlan: state.sourceAcquisitionPlan,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد CSV QA للمستكشف الذكي.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateMergeReadinessRunbook() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildMergeReadinessRunbook(
          query: state.query,
          results: state.filteredResults,
          runtimeDiagnostics: state.runtimeDiagnostics,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage:
          'تم توليد Runbook دمج المستكشف الذكي دون استبدال الخريطة أو الراوتر.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateNamedBaselineManifest() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildNamedBaselineManifestText();
    state = state.copyWith(
      exportText: text,
      actionMessage:
          'تم توليد بيان تسمية baseline للمستكشف الذكي لمنع الخلط مع المستكشف الأصلي.',
      actionErrorMessage: null,
    );
    return text;
  }


  String generateOperationalIntegrationStagePack() {
    final pack = ref
        .read(smartExplorerRepositoryProvider)
        .buildOperationalIntegrationStagePack(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    final text = pack.toReportText();
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد مرحلة الاندماج التشغيلي: ${pack.decisionLabelAr}.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateSmartExplorerUserGuide() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildUserGuideText();
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد دليل استخدام المستكشف الذكي داخل المشروع.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateSmartExplorerQuickStart() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildUserQuickStartText();
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد بطاقة البدء السريع للمستكشف الذكي.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateOperationalAcceptanceChecklist() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildOperationalAcceptanceChecklistText(
          query: state.query,
          results: state.filteredResults,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد Checklist قبول التشغيل للمستكشف الذكي.',
      actionErrorMessage: null,
    );
    return text;
  }


  String generateActualRuntimeWiringStagePack() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildActualRuntimeWiringStageReport(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage:
          'تم توليد ربط runtime فعلي للمستكشف الذكي مع baseline المستكشف الحالي.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateAnalyzerClosureReport() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildAnalyzerClosureReport(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد تقرير إغلاق analyzer المحلي للمستكشف الذكي.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateActualRuntimeWiringCsv() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildActualRuntimeWiringCsv(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد CSV ربط runtime وإغلاق analyzer.',
      actionErrorMessage: null,
    );
    return text;
  }


  String generateIntegratedFinalStageQzReport() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildIntegratedFinalStageQzReport(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage:
          'تم توليد المرحلة النهائية Q→Z للمستكشف الذكي كحزمة اندماج تشغيلية.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateIntegratedFinalStageQzCsv() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildIntegratedFinalStageQzCsv(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد CSV المرحلة النهائية Q→Z للمستكشف الذكي.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateIntegratedFinalUserGuideQz() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildIntegratedFinalUserGuideQzText(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد دليل استخدام Q→Z للمستكشف الذكي.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateIntegratedFinalOperationsManualQz() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildIntegratedFinalOperationsManualQzText(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد دليل تشغيل Q→Z للمستكشف الذكي.',
      actionErrorMessage: null,
    );
    return text;
  }


  String generatePostQzOperationalClosureReport() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildPostQzOperationalClosureReport(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد إغلاق Post-QZ النهائي للمستكشف الذكي.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generatePostQzOperationalClosureCsv() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildPostQzOperationalClosureCsv(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد CSV إغلاق Post-QZ للمستكشف الذكي.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generatePostQzExplorerIntegrationInstructions() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildPostQzExplorerIntegrationInstructionsText(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد تعليمات دمج واختبار Post-QZ للمستكشف الأصلي.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generatePostQzFinalUserGuideAddendum() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildPostQzFinalUserGuideAddendumText(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد ملحق دليل الاستخدام النهائي بعد Q→Z.',
      actionErrorMessage: null,
    );
    return text;
  }


  String generateAiDocumentIntelligenceStageReport() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildAiDocumentIntelligenceStageReport(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد مرحلة ذكاء الوثائق OCR + LLM + RAG + Review Board.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateAiDocumentIntelligenceStageCsv() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildAiDocumentIntelligenceStageCsv(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد CSV ذكاء الوثائق للمستكشف الذكي.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateAiDocumentIntelligenceSqlDraft() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildAiDocumentIntelligenceSqlDraftText(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد SQL draft لمرحلة AI داخل mustakshif وpublic wrappers فقط.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateAiDocumentIntelligenceIntegrationInstructions() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildAiDocumentIntelligenceIntegrationInstructionsText(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد تعليمات دمج واختبار AI-OCR-LLM-RAG للمستكشف الأصلي.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateAiDocumentIntelligenceUserGuideAddendum() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildAiDocumentIntelligenceUserGuideAddendumText(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد ملحق دليل ذكاء الوثائق للمستكشف الذكي.',
      actionErrorMessage: null,
    );
    return text;
  }


  String generateSpatialVerificationStageReport() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildSpatialVerificationStageReport(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد مرحلة التحقق المكاني ومخططات المساحة SV-1→SV-6.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateSpatialVerificationStageCsv() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildSpatialVerificationStageCsv(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد CSV التحقق المكاني للمستكشف الذكي.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateSpatialVerificationSqlDraft() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildSpatialVerificationSqlDraftText(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد SQL draft للتحقق المكاني داخل mustakshif وpublic wrappers فقط.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateSpatialVerificationIntegrationInstructions() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildSpatialVerificationIntegrationInstructionsText(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد تعليمات دمج واختبار التحقق المكاني للمستكشف الأصلي.',
      actionErrorMessage: null,
    );
    return text;
  }

  String generateSpatialVerificationUserGuideAddendum() {
    final text = ref
        .read(smartExplorerRepositoryProvider)
        .buildSpatialVerificationUserGuideAddendumText(
          query: state.query,
          results: state.filteredResults,
          documentAnalysis: state.documentAnalysis,
          evidenceMatrix: state.evidenceMatrix,
          qualityScorecard: state.qualityScorecard,
          runtimeDiagnostics: state.runtimeDiagnostics,
          releaseReadiness: state.releaseReadiness,
        );
    state = state.copyWith(
      exportText: text,
      actionMessage: 'تم توليد ملحق دليل التحقق المكاني ومخططات المساحة.',
      actionErrorMessage: null,
    );
    return text;
  }

  SmartExplorerExportBundle generateExportBundle() {
    final bundle = ref.read(smartExplorerRepositoryProvider).buildExportBundle(
          query: state.query,
          results: state.filteredResults,
          actionPlan: state.actionPlan,
          stakeholderMatrix: state.stakeholderMatrix,
          decisionLog: state.decisionLog,
          closureGate: state.closureGate,
          dataLineage: state.dataLineage,
          finalIntegrationMemoText: state.finalIntegrationMemoText,
          handoffPacketText: state.handoffPacketText,
          executiveBriefText: state.executiveBriefText,
          qualityScorecard: state.qualityScorecard,
          reviewWorkflow: state.reviewWorkflow,
          assumptionLedger: state.assumptionLedger,
          crossSystemBridgePlan: state.crossSystemBridgePlan,
        );
    state = state.copyWith(
      exportBundle: bundle,
      actionMessage: bundle.isEmpty
          ? 'لا توجد مواد كافية لحزمة التسليم.'
          : 'تم توليد حزمة تسليم تضم ${bundle.totalSections} أقسام.',
      actionErrorMessage: null,
    );
    return bundle;
  }

  void clearExportBundle() {
    state = state.copyWith(exportBundle: null);
  }
  SmartExplorerHypothesisIntent _intentForResult(SmartExplorerResult result) {
    if (!result.hasAnySpatialReference) {
      return SmartExplorerHypothesisIntent.spatialLinking;
    }
    if (!result.hasLinkedParcels) {
      return SmartExplorerHypothesisIntent.parcelMatching;
    }
    if (result.endowmentName.trim().isEmpty) {
      return SmartExplorerHypothesisIntent.endowmentReference;
    }
    if (result.missingAdministrativeContext) {
      return SmartExplorerHypothesisIntent.administrativeCompletion;
    }
    return SmartExplorerHypothesisIntent.qualityReview;
  }
}
