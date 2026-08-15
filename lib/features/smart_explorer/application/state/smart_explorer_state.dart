import '../../../map/data/repositories/map_feedback_repository.dart';
import '../../domain/models/smart_explorer_decision_board.dart';
import '../../domain/models/smart_explorer_document_analysis.dart';
import '../../domain/models/smart_explorer_filter.dart';
import '../../domain/models/smart_explorer_gazetteer_entry.dart';
import '../../domain/models/smart_explorer_evidence_matrix.dart';
import '../../domain/models/smart_explorer_field_checklist.dart';
import '../../domain/models/smart_explorer_gap_signal.dart';
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

class SmartExplorerState {
  const SmartExplorerState({
    this.query = '',
    this.isLoading = false,
    this.errorMessage,
    this.results = const <SmartExplorerResult>[],
    this.filters = SmartExplorerFilters.empty,
    this.selectedResultId,
    this.generatedHypothesis,
    this.recentAuditRequests = const <ExplorerGapAuditRequest>[],
    this.isLoadingAuditRequests = false,
    this.isCreatingBatchRequests = false,
    this.actionMessage,
    this.actionErrorMessage,
    this.reportText,
    this.documentDraft = '',
    this.documentAnalysis,
    this.isAnalyzingDocument = false,
    this.routePlan,
    this.investigationReportText,
    this.gazetteerEntries = const <SmartExplorerGazetteerEntry>[],
    this.evidenceMatrix,
    this.readinessAssessments = const <SmartExplorerReadinessAssessment>[],
    this.exportText,
    this.decisionBoard,
    this.fieldChecklist,
    this.riskRegister,
    this.qaScenarios = const <SmartExplorerQaScenario>[],
    this.handoffPacketText,
    this.workspaceSnapshotText,
    this.workPackages,
    this.layerRecommendations,
    this.validationProtocol,
    this.knowledgeCards,
    this.executiveBriefText,
    this.investigationSession,
    this.hypothesisComparison,
    this.dataLineage,
    this.closureGate,
    this.finalIntegrationMemoText,
    this.actionPlan,
    this.stakeholderMatrix,
    this.decisionLog,
    this.exportBundle,
    this.qualityScorecard,
    this.reviewWorkflow,
    this.assumptionLedger,
    this.crossSystemBridgePlan,
    this.expectedOutcomes,
    this.sourceAcquisitionPlan,
    this.confidenceZones,
    this.temporalAdminTrace,
    this.auditPlaybook,
    this.releaseReadiness,
    this.runtimeDiagnostics,
  });

  final String query;
  final bool isLoading;
  final String? errorMessage;
  final List<SmartExplorerResult> results;
  final SmartExplorerFilters filters;
  final String? selectedResultId;
  final SmartExplorerHypothesis? generatedHypothesis;
  final List<ExplorerGapAuditRequest> recentAuditRequests;
  final bool isLoadingAuditRequests;
  final bool isCreatingBatchRequests;
  final String? actionMessage;
  final String? actionErrorMessage;
  final String? reportText;
  final String documentDraft;
  final SmartExplorerDocumentAnalysis? documentAnalysis;
  final bool isAnalyzingDocument;
  final SmartExplorerRoutePlan? routePlan;
  final String? investigationReportText;
  final List<SmartExplorerGazetteerEntry> gazetteerEntries;
  final SmartExplorerEvidenceMatrix? evidenceMatrix;
  final List<SmartExplorerReadinessAssessment> readinessAssessments;
  final String? exportText;
  final SmartExplorerDecisionBoard? decisionBoard;
  final SmartExplorerFieldChecklist? fieldChecklist;
  final SmartExplorerRiskRegister? riskRegister;
  final List<SmartExplorerQaScenario> qaScenarios;
  final String? handoffPacketText;
  final String? workspaceSnapshotText;
  final SmartExplorerWorkPackageSet? workPackages;
  final SmartExplorerLayerRecommendationSet? layerRecommendations;
  final SmartExplorerValidationProtocol? validationProtocol;
  final SmartExplorerKnowledgeCardSet? knowledgeCards;
  final String? executiveBriefText;
  final SmartExplorerInvestigationSession? investigationSession;
  final SmartExplorerHypothesisComparison? hypothesisComparison;
  final SmartExplorerDataLineage? dataLineage;
  final SmartExplorerClosureGate? closureGate;
  final String? finalIntegrationMemoText;
  final SmartExplorerActionPlan? actionPlan;
  final SmartExplorerStakeholderMatrix? stakeholderMatrix;
  final SmartExplorerDecisionLog? decisionLog;
  final SmartExplorerExportBundle? exportBundle;
  final SmartExplorerQualityScorecard? qualityScorecard;
  final SmartExplorerReviewWorkflow? reviewWorkflow;
  final SmartExplorerAssumptionLedger? assumptionLedger;
  final SmartExplorerCrossSystemBridgePlan? crossSystemBridgePlan;
  final SmartExplorerExpectedOutcomes? expectedOutcomes;
  final SmartExplorerSourceAcquisitionPlan? sourceAcquisitionPlan;
  final SmartExplorerConfidenceZoneSet? confidenceZones;
  final SmartExplorerTemporalAdminTrace? temporalAdminTrace;
  final SmartExplorerAuditPlaybook? auditPlaybook;
  final SmartExplorerReleaseReadiness? releaseReadiness;
  final SmartExplorerRuntimeDiagnostics? runtimeDiagnostics;

  bool get hasQuery => query.trim().isNotEmpty;
  bool get hasResults => results.isNotEmpty;
  bool get hasFilteredResults => filteredResults.isNotEmpty;
  bool get hasDocumentAnalysis => documentAnalysis != null;
  bool get hasRoutePlan => routePlan != null && !routePlan!.isEmpty;
  bool get hasInvestigationReport =>
      investigationReportText != null && investigationReportText!.trim().isNotEmpty;
  bool get hasGazetteerEntries => gazetteerEntries.isNotEmpty;
  bool get hasEvidenceMatrix => evidenceMatrix != null && evidenceMatrix!.hasLinks;
  bool get hasReadinessAssessments => readinessAssessments.isNotEmpty;
  bool get hasExportText => exportText != null && exportText!.trim().isNotEmpty;
  bool get hasDecisionBoard => decisionBoard != null && !decisionBoard!.isEmpty;
  bool get hasFieldChecklist => fieldChecklist != null && !fieldChecklist!.isEmpty;
  bool get hasRiskRegister => riskRegister != null && !riskRegister!.isEmpty;
  bool get hasQaScenarios => qaScenarios.isNotEmpty;
  bool get hasHandoffPacket =>
      handoffPacketText != null && handoffPacketText!.trim().isNotEmpty;
  bool get hasWorkspaceSnapshot =>
      workspaceSnapshotText != null && workspaceSnapshotText!.trim().isNotEmpty;
  bool get hasWorkPackages => workPackages != null && !workPackages!.isEmpty;
  bool get hasLayerRecommendations =>
      layerRecommendations != null && !layerRecommendations!.isEmpty;
  bool get hasValidationProtocol =>
      validationProtocol != null && !validationProtocol!.isEmpty;
  bool get hasKnowledgeCards => knowledgeCards != null && !knowledgeCards!.isEmpty;
  bool get hasExecutiveBrief =>
      executiveBriefText != null && executiveBriefText!.trim().isNotEmpty;
  bool get hasInvestigationSession =>
      investigationSession != null && !investigationSession!.isEmpty;
  bool get hasHypothesisComparison =>
      hypothesisComparison != null && !hypothesisComparison!.isEmpty;
  bool get hasDataLineage => dataLineage != null && !dataLineage!.isEmpty;
  bool get hasClosureGate => closureGate != null && !closureGate!.isEmpty;
  bool get hasFinalIntegrationMemo =>
      finalIntegrationMemoText != null && finalIntegrationMemoText!.trim().isNotEmpty;
  bool get hasActionPlan => actionPlan != null && !actionPlan!.isEmpty;
  bool get hasStakeholderMatrix =>
      stakeholderMatrix != null && !stakeholderMatrix!.isEmpty;
  bool get hasDecisionLog => decisionLog != null && !decisionLog!.isEmpty;
  bool get hasExportBundle => exportBundle != null && !exportBundle!.isEmpty;
  bool get hasQualityScorecard =>
      qualityScorecard != null && !qualityScorecard!.isEmpty;
  bool get hasReviewWorkflow => reviewWorkflow != null && !reviewWorkflow!.isEmpty;
  bool get hasAssumptionLedger =>
      assumptionLedger != null && !assumptionLedger!.isEmpty;
  bool get hasCrossSystemBridgePlan =>
      crossSystemBridgePlan != null && !crossSystemBridgePlan!.isEmpty;
  bool get hasExpectedOutcomes =>
      expectedOutcomes != null && !expectedOutcomes!.isEmpty;
  bool get hasSourceAcquisitionPlan =>
      sourceAcquisitionPlan != null && !sourceAcquisitionPlan!.isEmpty;
  bool get hasConfidenceZones =>
      confidenceZones != null && !confidenceZones!.isEmpty;
  bool get hasTemporalAdminTrace =>
      temporalAdminTrace != null && !temporalAdminTrace!.isEmpty;
  bool get hasAuditPlaybook =>
      auditPlaybook != null && !auditPlaybook!.isEmpty;
  bool get hasReleaseReadiness =>
      releaseReadiness != null && !releaseReadiness!.isEmpty;
  bool get hasRuntimeDiagnostics =>
      runtimeDiagnostics != null && !runtimeDiagnostics!.isEmpty;

  List<SmartExplorerResult> get filteredResults {
    final list = results.where(filters.allows).toList(growable: false);
    return list;
  }

  List<SmartExplorerResult> get reviewQueue {
    final queue = filteredResults
        .where((item) => item.needsReview)
        .toList(growable: false);
    return queue..sort((a, b) => b.reviewScore.compareTo(a.reviewScore));
  }

  int get totalSignals => results.fold<int>(
        0,
        (sum, item) => sum + item.gapSignals.length,
      );

  int get filteredSignals => filteredResults.fold<int>(
        0,
        (sum, item) => sum + item.gapSignals.length,
      );

  int get criticalSignals => results.fold<int>(
        0,
        (sum, item) =>
            sum + item.severityCount(SmartExplorerSignalSeverity.critical),
      );

  int get highSignals => results.fold<int>(
        0,
        (sum, item) =>
            sum +
            item.gapSignals
                .where((signal) => signal.isHigh || signal.isCritical)
                .length,
      );

  int get assetsWithoutGeometry =>
      results.where((item) => !item.hasAnySpatialReference).length;

  int get assetsWithoutParcels =>
      results.where((item) => !item.hasLinkedParcels).length;

  int get missingEndowmentCount =>
      results.where((item) => item.endowmentName.trim().isEmpty).length;

  int get lowConfidenceCount =>
      results.where((item) => item.confidenceScore < 65).length;

  int get openAuditRequests => recentAuditRequests
      .where((item) => item.status == 'new' || item.status == 'triaged')
      .length;

  double get averageConfidence {
    if (filteredResults.isEmpty) return 0;
    final sum = filteredResults.fold<int>(
      0,
      (value, result) => value + result.confidenceScore,
    );
    return sum / filteredResults.length;
  }

  SmartExplorerResult? get selectedResult {
    final id = selectedResultId;
    if (id == null || id.isEmpty) return filteredResults.firstOrNull;
    for (final item in filteredResults) {
      if (item.id == id) return item;
    }
    return filteredResults.firstOrNull;
  }

  SmartExplorerState copyWith({
    String? query,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    List<SmartExplorerResult>? results,
    SmartExplorerFilters? filters,
    Object? selectedResultId = _sentinel,
    Object? generatedHypothesis = _sentinel,
    List<ExplorerGapAuditRequest>? recentAuditRequests,
    bool? isLoadingAuditRequests,
    bool? isCreatingBatchRequests,
    Object? actionMessage = _sentinel,
    Object? actionErrorMessage = _sentinel,
    Object? reportText = _sentinel,
    String? documentDraft,
    Object? documentAnalysis = _sentinel,
    bool? isAnalyzingDocument,
    Object? routePlan = _sentinel,
    Object? investigationReportText = _sentinel,
    List<SmartExplorerGazetteerEntry>? gazetteerEntries,
    Object? evidenceMatrix = _sentinel,
    List<SmartExplorerReadinessAssessment>? readinessAssessments,
    Object? exportText = _sentinel,
    Object? decisionBoard = _sentinel,
    Object? fieldChecklist = _sentinel,
    Object? riskRegister = _sentinel,
    List<SmartExplorerQaScenario>? qaScenarios,
    Object? handoffPacketText = _sentinel,
    Object? workspaceSnapshotText = _sentinel,
    Object? workPackages = _sentinel,
    Object? layerRecommendations = _sentinel,
    Object? validationProtocol = _sentinel,
    Object? knowledgeCards = _sentinel,
    Object? executiveBriefText = _sentinel,
    Object? investigationSession = _sentinel,
    Object? hypothesisComparison = _sentinel,
    Object? dataLineage = _sentinel,
    Object? closureGate = _sentinel,
    Object? finalIntegrationMemoText = _sentinel,
    Object? actionPlan = _sentinel,
    Object? stakeholderMatrix = _sentinel,
    Object? decisionLog = _sentinel,
    Object? exportBundle = _sentinel,
    Object? qualityScorecard = _sentinel,
    Object? reviewWorkflow = _sentinel,
    Object? assumptionLedger = _sentinel,
    Object? crossSystemBridgePlan = _sentinel,
    Object? expectedOutcomes = _sentinel,
    Object? sourceAcquisitionPlan = _sentinel,
    Object? confidenceZones = _sentinel,
    Object? temporalAdminTrace = _sentinel,
    Object? auditPlaybook = _sentinel,
    Object? releaseReadiness = _sentinel,
    Object? runtimeDiagnostics = _sentinel,
  }) {
    return SmartExplorerState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      results: results ?? this.results,
      filters: filters ?? this.filters,
      selectedResultId: identical(selectedResultId, _sentinel)
          ? this.selectedResultId
          : selectedResultId as String?,
      generatedHypothesis: identical(generatedHypothesis, _sentinel)
          ? this.generatedHypothesis
          : generatedHypothesis as SmartExplorerHypothesis?,
      recentAuditRequests: recentAuditRequests ?? this.recentAuditRequests,
      isLoadingAuditRequests:
          isLoadingAuditRequests ?? this.isLoadingAuditRequests,
      isCreatingBatchRequests:
          isCreatingBatchRequests ?? this.isCreatingBatchRequests,
      actionMessage: identical(actionMessage, _sentinel)
          ? this.actionMessage
          : actionMessage as String?,
      actionErrorMessage: identical(actionErrorMessage, _sentinel)
          ? this.actionErrorMessage
          : actionErrorMessage as String?,
      reportText:
          identical(reportText, _sentinel) ? this.reportText : reportText as String?,
      documentDraft: documentDraft ?? this.documentDraft,
      documentAnalysis: identical(documentAnalysis, _sentinel)
          ? this.documentAnalysis
          : documentAnalysis as SmartExplorerDocumentAnalysis?,
      isAnalyzingDocument: isAnalyzingDocument ?? this.isAnalyzingDocument,
      routePlan: identical(routePlan, _sentinel)
          ? this.routePlan
          : routePlan as SmartExplorerRoutePlan?,
      investigationReportText: identical(investigationReportText, _sentinel)
          ? this.investigationReportText
          : investigationReportText as String?,
      gazetteerEntries: gazetteerEntries ?? this.gazetteerEntries,
      evidenceMatrix: identical(evidenceMatrix, _sentinel)
          ? this.evidenceMatrix
          : evidenceMatrix as SmartExplorerEvidenceMatrix?,
      readinessAssessments:
          readinessAssessments ?? this.readinessAssessments,
      exportText:
          identical(exportText, _sentinel) ? this.exportText : exportText as String?,
      decisionBoard: identical(decisionBoard, _sentinel)
          ? this.decisionBoard
          : decisionBoard as SmartExplorerDecisionBoard?,
      fieldChecklist: identical(fieldChecklist, _sentinel)
          ? this.fieldChecklist
          : fieldChecklist as SmartExplorerFieldChecklist?,
      riskRegister: identical(riskRegister, _sentinel)
          ? this.riskRegister
          : riskRegister as SmartExplorerRiskRegister?,
      qaScenarios: qaScenarios ?? this.qaScenarios,
      handoffPacketText: identical(handoffPacketText, _sentinel)
          ? this.handoffPacketText
          : handoffPacketText as String?,
      workspaceSnapshotText: identical(workspaceSnapshotText, _sentinel)
          ? this.workspaceSnapshotText
          : workspaceSnapshotText as String?,
      workPackages: identical(workPackages, _sentinel)
          ? this.workPackages
          : workPackages as SmartExplorerWorkPackageSet?,
      layerRecommendations: identical(layerRecommendations, _sentinel)
          ? this.layerRecommendations
          : layerRecommendations as SmartExplorerLayerRecommendationSet?,
      validationProtocol: identical(validationProtocol, _sentinel)
          ? this.validationProtocol
          : validationProtocol as SmartExplorerValidationProtocol?,
      knowledgeCards: identical(knowledgeCards, _sentinel)
          ? this.knowledgeCards
          : knowledgeCards as SmartExplorerKnowledgeCardSet?,
      executiveBriefText: identical(executiveBriefText, _sentinel)
          ? this.executiveBriefText
          : executiveBriefText as String?,
      investigationSession: identical(investigationSession, _sentinel)
          ? this.investigationSession
          : investigationSession as SmartExplorerInvestigationSession?,
      hypothesisComparison: identical(hypothesisComparison, _sentinel)
          ? this.hypothesisComparison
          : hypothesisComparison as SmartExplorerHypothesisComparison?,
      dataLineage: identical(dataLineage, _sentinel)
          ? this.dataLineage
          : dataLineage as SmartExplorerDataLineage?,
      closureGate: identical(closureGate, _sentinel)
          ? this.closureGate
          : closureGate as SmartExplorerClosureGate?,
      finalIntegrationMemoText: identical(finalIntegrationMemoText, _sentinel)
          ? this.finalIntegrationMemoText
          : finalIntegrationMemoText as String?,
      actionPlan: identical(actionPlan, _sentinel)
          ? this.actionPlan
          : actionPlan as SmartExplorerActionPlan?,
      stakeholderMatrix: identical(stakeholderMatrix, _sentinel)
          ? this.stakeholderMatrix
          : stakeholderMatrix as SmartExplorerStakeholderMatrix?,
      decisionLog: identical(decisionLog, _sentinel)
          ? this.decisionLog
          : decisionLog as SmartExplorerDecisionLog?,
      exportBundle: identical(exportBundle, _sentinel)
          ? this.exportBundle
          : exportBundle as SmartExplorerExportBundle?,
      qualityScorecard: identical(qualityScorecard, _sentinel)
          ? this.qualityScorecard
          : qualityScorecard as SmartExplorerQualityScorecard?,
      reviewWorkflow: identical(reviewWorkflow, _sentinel)
          ? this.reviewWorkflow
          : reviewWorkflow as SmartExplorerReviewWorkflow?,
      assumptionLedger: identical(assumptionLedger, _sentinel)
          ? this.assumptionLedger
          : assumptionLedger as SmartExplorerAssumptionLedger?,
      crossSystemBridgePlan: identical(crossSystemBridgePlan, _sentinel)
          ? this.crossSystemBridgePlan
          : crossSystemBridgePlan as SmartExplorerCrossSystemBridgePlan?,
      expectedOutcomes: identical(expectedOutcomes, _sentinel)
          ? this.expectedOutcomes
          : expectedOutcomes as SmartExplorerExpectedOutcomes?,
      sourceAcquisitionPlan: identical(sourceAcquisitionPlan, _sentinel)
          ? this.sourceAcquisitionPlan
          : sourceAcquisitionPlan as SmartExplorerSourceAcquisitionPlan?,
      confidenceZones: identical(confidenceZones, _sentinel)
          ? this.confidenceZones
          : confidenceZones as SmartExplorerConfidenceZoneSet?,
      temporalAdminTrace: identical(temporalAdminTrace, _sentinel)
          ? this.temporalAdminTrace
          : temporalAdminTrace as SmartExplorerTemporalAdminTrace?,
      auditPlaybook: identical(auditPlaybook, _sentinel)
          ? this.auditPlaybook
          : auditPlaybook as SmartExplorerAuditPlaybook?,
      releaseReadiness: identical(releaseReadiness, _sentinel)
          ? this.releaseReadiness
          : releaseReadiness as SmartExplorerReleaseReadiness?,
      runtimeDiagnostics: identical(runtimeDiagnostics, _sentinel)
          ? this.runtimeDiagnostics
          : runtimeDiagnostics as SmartExplorerRuntimeDiagnostics?,
    );
  }

  static const Object _sentinel = Object();
}

extension _SmartExplorerFirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
