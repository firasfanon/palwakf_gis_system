import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../map/data/repositories/map_feedback_repository.dart';
import '../../../map/presentation/services/explorer_export_download_service.dart';
import '../../../map/presentation/providers/toolbox_providers.dart';
import '../../application/providers/smart_explorer_bridge_providers.dart';
import '../../application/providers/smart_explorer_providers.dart';
import '../../application/state/smart_explorer_state.dart';
import '../../domain/models/smart_explorer_decision_board.dart';
import '../../domain/models/smart_explorer_document_analysis.dart';
import '../../domain/models/smart_explorer_evidence_matrix.dart';
import '../../domain/models/smart_explorer_field_checklist.dart';
import '../../domain/models/smart_explorer_gazetteer_entry.dart';
import '../../domain/models/smart_explorer_filter.dart';
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

class AdminSmartExplorerPage extends ConsumerStatefulWidget {
  const AdminSmartExplorerPage({
    super.key,
    this.embeddedInExplorer = false,
  });

  final bool embeddedInExplorer;

  @override
  ConsumerState<AdminSmartExplorerPage> createState() =>
      _AdminSmartExplorerPageState();
}

class _AdminSmartExplorerPageState
    extends ConsumerState<AdminSmartExplorerPage> {
  late final TextEditingController _searchController;
  late final TextEditingController _documentController;

  String get _mapBasePath =>
      widget.embeddedInExplorer ? '/admin/mustakshif/review-map' : '/map';

  String get _mapLandingRoute => widget.embeddedInExplorer
      ? Uri(
          path: _mapBasePath,
          queryParameters: const {'source': 'embedded_smart_explorer'},
        ).toString()
      : _mapBasePath;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _documentController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartExplorerControllerProvider);
    final controller = ref.read(smartExplorerControllerProvider.notifier);
    final bridgeSnapshot = ref.watch(smartExplorerBridgeSnapshotProvider);
    final bridgeService = ref.read(smartExplorerBridgeServiceProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _HeaderCard(
                queryController: _searchController,
                isLoading: state.isLoading,
                onChanged: controller.setQuery,
                onSearch: () => controller.search(_searchController.text),
              ),
              if (widget.embeddedInExplorer) ...[
                const SizedBox(height: 12),
                const _EmbeddedExplorerRuntimeBanner(),
                const SizedBox(height: 12),
                _SmartExplorerServiceOrientationPanel(
                  onOpenServices: () => context.go('/admin/explorer-suite/operations?source=embedded_smart_orientation'),
                  onOpenMap: () => context.go('/admin/mustakshif/review-map?source=embedded_smart_orientation'),
                  onOpenReview: () => context.go('/admin/mustakshif/review-board?source=embedded_smart_orientation'),
                ),
              ],
              const SizedBox(height: 16),
              _SummaryStrip(state: state),
              const SizedBox(height: 14),
              _ActionConsole(
                state: state,
                onGenerateReport: controller.generateCurrentReport,
                onClearReport: controller.clearReport,
                onCreateBatchAuditRequests: () async {
                  final created =
                      await controller.createAuditRequestsForReviewQueue();
                  if (!context.mounted || created.isEmpty) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم إنشاء ${created.length} طلب تدقيق من قائمة الأولوية.',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _ExplorerServicesBridgePanel(
                snapshot: bridgeSnapshot,
                onPrepareMap: () async {
                  final result = await bridgeService.prepareSelectedResultForMap();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.messageAr)),
                  );
                  if (result.ok) context.push(_mapLandingRoute);
                },
                onActivateRecommendedLayers: () async {
                  final result = await bridgeService.activateRecommendedLayers();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.messageAr)),
                  );
                },
                onPrepareSelectionBox: () {
                  final result = bridgeService.prepareSelectionBoxFromTarget();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.messageAr)),
                  );
                },
                onCopyReport: () async {
                  await Clipboard.setData(
                    ClipboardData(text: bridgeSnapshot.toReportText()),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ تقرير الجسر.')),
                  );
                },
                onDownloadCsv: () async {
                  final downloaded = await ExplorerExportDownloadService.downloadTextFile(
                    fileName: 'smart_explorer_bridge_${DateTime.now().millisecondsSinceEpoch}.csv',
                    content: bridgeSnapshot.toCsv(),
                    mimeType: 'text/csv;charset=utf-8',
                  );
                  if (!downloaded) {
                    await Clipboard.setData(
                      ClipboardData(text: bridgeSnapshot.toCsv()),
                    );
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        downloaded
                            ? 'تم تنزيل CSV للجسر.'
                            : 'التنزيل غير مدعوم هنا؛ تم نسخ CSV للحافظة.',
                      ),
                    ),
                  );
                },
                onOpenCrossMapLink: (link) async {
                  final result = bridgeService.prepareCrossMapLink(link);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.messageAr)),
                  );
                  if (result.ok) {
                    context.push(_resolveExplorerRuntimeRoute(link.route));
                  }
                },
                onPrepareAuditContext: () {
                  final result = bridgeService.prepareAuditContext();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.messageAr)),
                  );
                },
                onCopyAuditHandoff: () async {
                  await Clipboard.setData(
                    ClipboardData(text: bridgeSnapshot.toAuditHandoffText()),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ حزمة التدقيق.')),
                  );
                },
                onDownloadAuditCsv: () async {
                  final downloaded = await ExplorerExportDownloadService.downloadTextFile(
                    fileName: 'smart_explorer_audit_handoff_${DateTime.now().millisecondsSinceEpoch}.csv',
                    content: bridgeSnapshot.toAuditHandoffCsv(),
                    mimeType: 'text/csv;charset=utf-8',
                  );
                  if (!downloaded) {
                    await Clipboard.setData(
                      ClipboardData(text: bridgeSnapshot.toAuditHandoffCsv()),
                    );
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        downloaded
                            ? 'تم تنزيل CSV لحزمة التدقيق.'
                            : 'التنزيل غير مدعوم هنا؛ تم نسخ CSV التدقيق للحافظة.',
                      ),
                    ),
                  );
                },
                onCreateRealAuditRequest: () async {
                  final result = await bridgeService.createRealAuditWorkflow();
                  await controller.loadRecentAuditRequests();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.summaryAr)),
                  );
                },
                onCreateRealAuditTask: () async {
                  final result = await bridgeService.createRealAuditWorkflow(
                    createTask: true,
                  );
                  await controller.loadRecentAuditRequests();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.summaryAr)),
                  );
                },
                onOpenGapAudits: () => context.push('/admin/explorer-gap-audits'),
                onOpenAuditTasks: () => context.push('/admin/audit-tasks'),
              ),
              const SizedBox(height: 14),
              _UnifiedIntelligencePanel(
                state: state,
                documentController: _documentController,
                onDocumentChanged: controller.setDocumentDraft,
                onLoadSampleDocument: () {
                  final sample = controller.loadSampleDocument();
                  _documentController.text = sample;
                },
                onAnalyzeDocument: controller.analyzeDocumentDraft,
                onClearDocumentAnalysis: controller.clearDocumentAnalysis,
                onGenerateRoutePlan: controller.generateRoutePlan,
                onClearRoutePlan: controller.clearRoutePlan,
                onGenerateInvestigationReport: controller.generateInvestigationReport,
                onClearInvestigationReport: controller.clearInvestigationReport,
                onGenerateGazetteerDraft: controller.generateGazetteerDraft,
                onClearGazetteerDraft: controller.clearGazetteerDraft,
                onGenerateEvidenceMatrix: controller.generateEvidenceMatrix,
                onClearEvidenceMatrix: controller.clearEvidenceMatrix,
                onGenerateReadinessAssessments: controller.generateReadinessAssessments,
                onClearReadinessAssessments: controller.clearReadinessAssessments,
                onGenerateDecisionBoard: controller.generateDecisionBoard,
                onClearDecisionBoard: controller.clearDecisionBoard,
                onGenerateFieldChecklist: controller.generateFieldChecklist,
                onClearFieldChecklist: controller.clearFieldChecklist,
                onGenerateRiskRegister: controller.generateRiskRegister,
                onClearRiskRegister: controller.clearRiskRegister,
                onGenerateQaScenarios: controller.generateQaScenarios,
                onClearQaScenarios: controller.clearQaScenarios,
                onGenerateHandoffPacket: controller.generateHandoffPacket,
                onClearHandoffPacket: controller.clearHandoffPacket,
                onGenerateWorkspaceSnapshot: controller.generateWorkspaceSnapshot,
                onClearWorkspaceSnapshot: controller.clearWorkspaceSnapshot,
                onGenerateWorkPackages: controller.generateWorkPackages,
                onClearWorkPackages: controller.clearWorkPackages,
                onGenerateLayerRecommendations: controller.generateLayerRecommendations,
                onClearLayerRecommendations: controller.clearLayerRecommendations,
                onGenerateValidationProtocol: controller.generateValidationProtocol,
                onClearValidationProtocol: controller.clearValidationProtocol,
                onGenerateKnowledgeCards: controller.generateKnowledgeCards,
                onClearKnowledgeCards: controller.clearKnowledgeCards,
                onGenerateExecutiveBrief: controller.generateExecutiveBrief,
                onClearExecutiveBrief: controller.clearExecutiveBrief,
                onGenerateInvestigationSession: controller.generateInvestigationSession,
                onClearInvestigationSession: controller.clearInvestigationSession,
                onGenerateHypothesisComparison: controller.generateHypothesisComparison,
                onClearHypothesisComparison: controller.clearHypothesisComparison,
                onGenerateDataLineage: controller.generateDataLineage,
                onClearDataLineage: controller.clearDataLineage,
                onGenerateClosureGate: controller.generateClosureGate,
                onClearClosureGate: controller.clearClosureGate,
                onGenerateFinalIntegrationMemo: controller.generateFinalIntegrationMemo,
                onClearFinalIntegrationMemo: controller.clearFinalIntegrationMemo,
                onGenerateActionPlan: controller.generateActionPlan,
                onClearActionPlan: controller.clearActionPlan,
                onGenerateStakeholderMatrix: controller.generateStakeholderMatrix,
                onClearStakeholderMatrix: controller.clearStakeholderMatrix,
                onGenerateDecisionLog: controller.generateDecisionLog,
                onClearDecisionLog: controller.clearDecisionLog,
                onGenerateExportBundle: controller.generateExportBundle,
                onClearExportBundle: controller.clearExportBundle,
                onGenerateQualityScorecard: controller.generateQualityScorecard,
                onClearQualityScorecard: controller.clearQualityScorecard,
                onGenerateReviewWorkflow: controller.generateReviewWorkflow,
                onClearReviewWorkflow: controller.clearReviewWorkflow,
                onGenerateAssumptionLedger: controller.generateAssumptionLedger,
                onClearAssumptionLedger: controller.clearAssumptionLedger,
                onGenerateCrossSystemBridgePlan: controller.generateCrossSystemBridgePlan,
                onClearCrossSystemBridgePlan: controller.clearCrossSystemBridgePlan,
                onGenerateExpectedOutcomes: controller.generateExpectedOutcomes,
                onClearExpectedOutcomes: controller.clearExpectedOutcomes,
                onGenerateSourceAcquisitionPlan: controller.generateSourceAcquisitionPlan,
                onClearSourceAcquisitionPlan: controller.clearSourceAcquisitionPlan,
                onGenerateConfidenceZones: controller.generateConfidenceZones,
                onClearConfidenceZones: controller.clearConfidenceZones,
                onGenerateTemporalAdminTrace: controller.generateTemporalAdminTrace,
                onClearTemporalAdminTrace: controller.clearTemporalAdminTrace,
                onGenerateAuditPlaybook: controller.generateAuditPlaybook,
                onClearAuditPlaybook: controller.clearAuditPlaybook,
                onGenerateReleaseReadiness: controller.generateReleaseReadiness,
                onClearReleaseReadiness: controller.clearReleaseReadiness,
                onGenerateRuntimeDiagnostics: controller.generateRuntimeDiagnostics,
                onClearRuntimeDiagnostics: controller.clearRuntimeDiagnostics,
                onGenerateStrategicOutcomePack: controller.generateStrategicOutcomePack,
                onGenerateCurrentBaselineSafeExpansionPack:
                    controller.generateCurrentBaselineSafeExpansionPack,
                onGenerateSelfDevelopmentPack:
                    controller.generateSelfDevelopmentPack,
                onGenerateAutonomousQaPack:
                    controller.generateAutonomousQaPack,
                onGenerateAutonomousQaCsv:
                    controller.generateAutonomousQaCsv,
                onGenerateMergeReadinessRunbook:
                    controller.generateMergeReadinessRunbook,
                onGenerateNamedBaselineManifest:
                    controller.generateNamedBaselineManifest,
                onGenerateOperationalIntegrationStage:
                    controller.generateOperationalIntegrationStagePack,
                onGenerateSmartExplorerUserGuide:
                    controller.generateSmartExplorerUserGuide,
                onGenerateSmartExplorerQuickStart:
                    controller.generateSmartExplorerQuickStart,
                onGenerateOperationalAcceptanceChecklist:
                    controller.generateOperationalAcceptanceChecklist,
                onGenerateActualRuntimeWiringStage:
                    controller.generateActualRuntimeWiringStagePack,
                onGenerateAnalyzerClosureReport:
                    controller.generateAnalyzerClosureReport,
                onGenerateActualRuntimeWiringCsv:
                    controller.generateActualRuntimeWiringCsv,
                onGenerateIntegratedFinalStageQzReport:
                    controller.generateIntegratedFinalStageQzReport,
                onGenerateIntegratedFinalStageQzCsv:
                    controller.generateIntegratedFinalStageQzCsv,
                onGenerateIntegratedFinalUserGuideQz:
                    controller.generateIntegratedFinalUserGuideQz,
                onGenerateIntegratedFinalOperationsManualQz:
                    controller.generateIntegratedFinalOperationsManualQz,
                onGeneratePostQzOperationalClosureReport:
                    controller.generatePostQzOperationalClosureReport,
                onGeneratePostQzOperationalClosureCsv:
                    controller.generatePostQzOperationalClosureCsv,
                onGeneratePostQzExplorerIntegrationInstructions:
                    controller.generatePostQzExplorerIntegrationInstructions,
                onGeneratePostQzFinalUserGuideAddendum:
                    controller.generatePostQzFinalUserGuideAddendum,
                onGenerateAiDocumentIntelligenceStageReport:
                    controller.generateAiDocumentIntelligenceStageReport,
                onGenerateAiDocumentIntelligenceStageCsv:
                    controller.generateAiDocumentIntelligenceStageCsv,
                onGenerateAiDocumentIntelligenceSqlDraft:
                    controller.generateAiDocumentIntelligenceSqlDraft,
                onGenerateAiDocumentIntelligenceIntegrationInstructions:
                    controller.generateAiDocumentIntelligenceIntegrationInstructions,
                onGenerateAiDocumentIntelligenceUserGuideAddendum:
                    controller.generateAiDocumentIntelligenceUserGuideAddendum,
                onGenerateSpatialVerificationStageReport:
                    controller.generateSpatialVerificationStageReport,
                onGenerateSpatialVerificationStageCsv:
                    controller.generateSpatialVerificationStageCsv,
                onGenerateSpatialVerificationSqlDraft:
                    controller.generateSpatialVerificationSqlDraft,
                onGenerateSpatialVerificationIntegrationInstructions:
                    controller.generateSpatialVerificationIntegrationInstructions,
                onGenerateSpatialVerificationUserGuideAddendum:
                    controller.generateSpatialVerificationUserGuideAddendum,
                onGenerateLocalAnalyzerContract:
                    controller.generateLocalAnalyzerContract,
                onGenerateSelfDevelopmentCsv:
                    controller.generateSelfDevelopmentCsv,
                onGenerateReviewQueueCsv: controller.generateReviewQueueCsv,
                onGenerateGazetteerCsv: controller.generateGazetteerCsv,
                onClearExportText: controller.clearExportText,
                onCopyText: (text) async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم النسخ.')),
                  );
                },
              ),
              const SizedBox(height: 14),
              _RecentAuditRequestsPanel(
                state: state,
                onRefresh: controller.loadRecentAuditRequests,
                onOpenAuditDashboard: () =>
                    context.push('/admin/explorer-gap-audits'),
              ),
              if (state.actionMessage != null) ...[
                const SizedBox(height: 12),
                _Banner.success(state.actionMessage!),
              ],
              if (state.actionErrorMessage != null) ...[
                const SizedBox(height: 12),
                _Banner.error(state.actionErrorMessage!),
              ],
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                _Banner.error(state.errorMessage!),
              ],
              if (state.reportText != null) ...[
                const SizedBox(height: 14),
                _ReportPanel(
                  reportText: state.reportText!,
                  onCopy: () async {
                    await Clipboard.setData(
                      ClipboardData(text: state.reportText!),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ التقرير.')),
                    );
                  },
                  onClose: controller.clearReport,
                ),
              ],
              const SizedBox(height: 16),
              if (!state.hasQuery && !state.isLoading) const _IntroPanel(),
              if (state.hasQuery && !state.isLoading && state.results.isEmpty)
                const _EmptyPanel(),
              if (state.results.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1080;
                    final filters = _FilterPanel(
                      state: state,
                      onSeverityChanged: controller.setSeverityFilter,
                      onMinConfidenceChanged: controller.setMinConfidence,
                      onOnlyNeedsReviewChanged: controller.toggleOnlyNeedsReview,
                      onOnlyWithoutSpatialReferenceChanged:
                          controller.toggleOnlyWithoutSpatialReference,
                      onOnlyWithoutLinkedParcelsChanged:
                          controller.toggleOnlyWithoutLinkedParcels,
                      onOnlyMissingEndowmentChanged:
                          controller.toggleOnlyMissingEndowment,
                      onClearFilters: controller.clearFilters,
                    );

                    final list = _ResultsList(
                      results: state.filteredResults,
                      selectedResultId: state.selectedResult?.id,
                      onSelected: controller.selectResult,
                    );

                    final details = _ResultDetails(
                      result: state.selectedResult,
                      generatedHypothesis: state.generatedHypothesis,
                      onOpenMap: _openMap,
                      onOpenHistory: _openHistory,
                      onOpenWaqf: _openWaqf,
                      onOpenAudit: _openAudit,
                      onCreateAuditRequest: (result) async {
                        final request =
                            await controller.createAuditRequest(result);
                        if (!context.mounted || request == null) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم إنشاء طلب تدقيق ذكي: ${request.title}',
                            ),
                          ),
                        );
                      },
                      onGenerateHypothesis: (result) {
                        final hypothesis =
                            controller.generateLocalHypothesis(result);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم إنشاء ${hypothesis.titleAr} كفرضية محلية للمراجعة.',
                            ),
                          ),
                        );
                      },
                    );

                    if (!wide) {
                      return Column(
                        children: [
                          filters,
                          const SizedBox(height: 14),
                          list,
                          const SizedBox(height: 16),
                          details,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: filters),
                        const SizedBox(width: 14),
                        Expanded(flex: 5, child: list),
                        const SizedBox(width: 14),
                        Expanded(flex: 4, child: details),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveExplorerRuntimeRoute(String route) {
    if (!widget.embeddedInExplorer) return route;

    final uri = Uri.tryParse(route);
    if (uri == null) return route;

    if (uri.path == '/map' || uri.path.startsWith('/map/')) {
      final query = <String, String>{
        ...uri.queryParameters,
        'source': 'embedded_smart_explorer',
      };

      final segments = uri.pathSegments;
      if (segments.length > 1 && !query.containsKey('assetId')) {
        query['assetId'] = segments[1];
      }

      return Uri(
        path: _mapBasePath,
        queryParameters: query,
      ).toString();
    }

    return route;
  }

  void _openMap(SmartExplorerResult result) {
    final target = Uri(
      path: _mapBasePath,
      queryParameters: {
        'q': result.mapQuery,
        'assetId': result.id,
        if (widget.embeddedInExplorer) 'source': 'embedded_smart_explorer',
      },
    ).toString();
    context.push(target);
  }

  void _openHistory(SmartExplorerResult result) {
    final query = Uri.encodeQueryComponent(result.mapQuery);
    context.push(
      '/history?mode=waqf&q=$query&waqfId=${Uri.encodeQueryComponent(result.id)}',
    );
  }

  void _openWaqf(SmartExplorerResult result) {
    if (result.id.isEmpty) return;
    context.push('/waqf/${Uri.encodeComponent(result.id)}');
  }

  void _openAudit(SmartExplorerResult result) {
    final query = Uri.encodeQueryComponent(result.titleAr);
    context.push(
      '/admin/explorer-gap-audits?q=$query&assetId=${Uri.encodeQueryComponent(result.id)}',
    );
  }
}


class _EmbeddedExplorerRuntimeBanner extends StatelessWidget {
  const _EmbeddedExplorerRuntimeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PwfColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PwfColors.primaryBlue.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.hub_outlined,
            color: PwfColors.primaryBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تشغيل مدمج داخل Mustakshif Explorer',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'هذه الصفحة تعمل الآن كجزء من المستكشف، وتفتح النتائج على خريطة المراجعة ولوحة المراجعة ضمن shell المستكشف. توصيات الطبقات تبقى قراءة/تحضير فقط ولا تعدّل activeLayers.',
                  style: TextStyle(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.queryController,
    required this.isLoading,
    required this.onChanged,
    required this.onSearch,
  });

  final TextEditingController queryController;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0B2C5D), Color(0xFF123D7A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2C5D).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            spacing: 12,
            children: [
              const _HeaderTitle(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 17,
                      color: Color(0xFFD4AF37),
                    ),
                    SizedBox(width: 7),
                    Text(
                      'اقتراحات ذكية غير سيادية',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: queryController,
            onChanged: onChanged,
            onSubmitted: (_) => onSearch(),
            textInputAction: TextInputAction.search,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText:
                  'ابحث باسم الأصل، الرمز الوطني، الوقف الأم، التجمع، الحوض أو القطعة...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
              prefixIcon: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Icon(Icons.search, color: Colors.white),
              suffixIcon: IconButton(
                onPressed: isLoading ? null : onSearch,
                icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFD4AF37)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المستكشف الذكي للأوقاف والتاريخ المكاني',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'تحليل فجوات، أولوية مراجعة، فرضيات محلية، وتدقيق دون تعديل الجداول السيادية.',
          style: TextStyle(
            color: Color(0xFFE2E8F0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.state});

  final SmartExplorerState state;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricCard(
          label: 'النتائج',
          value: '${state.results.length}',
          icon: Icons.inventory_2_outlined,
          color: PwfColors.primaryBlue,
        ),
        _MetricCard(
          label: 'بعد الفلترة',
          value: '${state.filteredResults.length}',
          icon: Icons.filter_alt_outlined,
          color: const Color(0xFF0F766E),
        ),
        _MetricCard(
          label: 'إشارات الفجوات',
          value: '${state.totalSignals}',
          icon: Icons.report_problem_outlined,
          color: const Color(0xFFC77700),
        ),
        _MetricCard(
          label: 'حرجة',
          value: '${state.criticalSignals}',
          icon: Icons.warning_amber_rounded,
          color: PwfColors.royalRed,
        ),
        _MetricCard(
          label: 'بلا تمثيل مكاني',
          value: '${state.assetsWithoutGeometry}',
          icon: Icons.location_off_outlined,
          color: const Color(0xFF7C3AED),
        ),
        _MetricCard(
          label: 'بلا قطع مرتبطة',
          value: '${state.assetsWithoutParcels}',
          icon: Icons.grid_4x4_outlined,
          color: const Color(0xFF047857),
        ),
        _MetricCard(
          label: 'متوسط الثقة',
          value: '${state.averageConfidence.round()}%',
          icon: Icons.speed_outlined,
          color: const Color(0xFF1D4ED8),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionConsole extends StatelessWidget {
  const _ActionConsole({
    required this.state,
    required this.onGenerateReport,
    required this.onClearReport,
    required this.onCreateBatchAuditRequests,
  });

  final SmartExplorerState state;
  final VoidCallback onGenerateReport;
  final VoidCallback onClearReport;
  final VoidCallback onCreateBatchAuditRequests;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 10,
        spacing: 10,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_graph_outlined, color: PwfColors.primaryBlue),
              const SizedBox(width: 8),
              const Text(
                'لوحة التحليل السريع',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              _InfoChip(
                label: '${state.reviewQueue.length} في قائمة الأولوية',
                icon: Icons.priority_high_outlined,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: state.filteredResults.isEmpty ? null : onGenerateReport,
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('توليد تقرير'),
              ),
              OutlinedButton.icon(
                onPressed: state.reportText == null ? null : onClearReport,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('إخفاء التقرير'),
              ),
              FilledButton.icon(
                onPressed: state.isCreatingBatchRequests || state.reviewQueue.isEmpty
                    ? null
                    : onCreateBatchAuditRequests,
                icon: state.isCreatingBatchRequests
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.playlist_add_check_circle_outlined, size: 18),
                label: const Text('إنشاء أول 5 طلبات تدقيق'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExplorerServicesBridgePanel extends StatelessWidget {
  const _ExplorerServicesBridgePanel({
    required this.snapshot,
    required this.onPrepareMap,
    required this.onActivateRecommendedLayers,
    required this.onPrepareSelectionBox,
    required this.onCopyReport,
    required this.onDownloadCsv,
    required this.onOpenCrossMapLink,
    required this.onPrepareAuditContext,
    required this.onCopyAuditHandoff,
    required this.onDownloadAuditCsv,
    required this.onCreateRealAuditRequest,
    required this.onCreateRealAuditTask,
    required this.onOpenGapAudits,
    required this.onOpenAuditTasks,
  });

  final SmartExplorerBridgeSnapshot snapshot;
  final VoidCallback onPrepareMap;
  final VoidCallback onActivateRecommendedLayers;
  final VoidCallback onPrepareSelectionBox;
  final VoidCallback onCopyReport;
  final VoidCallback onDownloadCsv;
  final ValueChanged<SmartExplorerCrossMapLink> onOpenCrossMapLink;
  final VoidCallback onPrepareAuditContext;
  final VoidCallback onCopyAuditHandoff;
  final VoidCallback onDownloadAuditCsv;
  final Future<void> Function() onCreateRealAuditRequest;
  final Future<void> Function() onCreateRealAuditTask;
  final VoidCallback onOpenGapAudits;
  final VoidCallback onOpenAuditTasks;

  @override
  Widget build(BuildContext context) {
    final result = snapshot.selectedResult;
    final runtime = snapshot.runtimeInfo;

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              const _SectionTitle(
                icon: Icons.hub_outlined,
                title: 'جسر خدمات المستكشف',
              ),
              _InfoChip(
                label: snapshot.audience.labelAr,
                icon: Icons.admin_panel_settings_outlined,
                color: const Color(0xFF0F766E),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            snapshot.bridgeStatusAr,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: 8),
            Text(
              result.titleAr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: 'الهدف: ${snapshot.targetLabelAr}',
                icon: Icons.place_outlined,
              ),
              _InfoChip(
                label: 'BBOX: ${snapshot.selectionBboxLabelAr}',
                icon: Icons.crop_free_outlined,
                color: const Color(0xFF7C3AED),
              ),
              _InfoChip(
                label: 'مطابقة طبقات: ${snapshot.matchingRecommendedLayerKeys.length}',
                icon: Icons.layers_outlined,
                color: const Color(0xFFC77700),
              ),
              _InfoChip(
                label: 'معالم النطاق: ${snapshot.selectedFeaturesInBox.length}',
                icon: Icons.table_rows_outlined,
                color: const Color(0xFF047857),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final cards = [
                _BridgeStatusCard(
                  title: 'الخريطة',
                  value: snapshot.runtimeSummaryAr,
                  icon: Icons.map_outlined,
                ),
                _BridgeStatusCard(
                  title: 'الطبقات المحجوبة',
                  value: snapshot.blockedLayerKeys.isEmpty
                      ? 'لا توجد طبقات محجوبة حاليًا'
                      : snapshot.blockedLayerKeys.join('، '),
                  icon: Icons.visibility_off_outlined,
                ),
                _BridgeStatusCard(
                  title: 'آخر Identify',
                  value: snapshot.identifyFeatureTitle ?? 'لا توجد نتيجة تعريف بعد',
                  icon: Icons.ads_click_outlined,
                ),
                _BridgeStatusCard(
                  title: 'حد العناصر / التبسيط',
                  value:
                      '${runtime.featureLimit} عنصر • ${runtime.simplifyMeters.toStringAsFixed(0)}م تبسيط',
                  icon: Icons.tune_outlined,
                ),
              ];

              if (!wide) {
                return Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      if (card != cards.last) const SizedBox(height: 8),
                    ],
                  ],
                );
              }

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: cards
                    .map(
                      (card) => SizedBox(
                        width: (constraints.maxWidth - 10) / 2,
                        child: card,
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
          if (snapshot.matchingRecommendedLayerKeys.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'الطبقات المقترحة المطابقة: ${snapshot.matchingRecommendedLayerKeys.join('، ')}',
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: snapshot.canOpenOnMap ? onPrepareMap : null,
                icon: const Icon(Icons.open_in_new_outlined, size: 18),
                label: const Text('افتح على الخريطة'),
              ),
              OutlinedButton.icon(
                onPressed: snapshot.hasRecommendedLayerMatches
                    ? onActivateRecommendedLayers
                    : null,
                icon: const Icon(Icons.layers_outlined, size: 18),
                label: const Text('جهّز توصيات الطبقات'),
              ),
              OutlinedButton.icon(
                onPressed: snapshot.hasTargetPoint ? onPrepareSelectionBox : null,
                icon: const Icon(Icons.select_all_outlined, size: 18),
                label: const Text('جهّز BBOX حول الهدف'),
              ),
              OutlinedButton.icon(
                onPressed: onCopyReport,
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                label: const Text('نسخ تقرير الجسر'),
              ),
              OutlinedButton.icon(
                onPressed: onDownloadCsv,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('CSV'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BridgeStatusCard(
            title: 'إغلاق الربط العميق',
            value: snapshot.bridgeDeepLinkSummaryAr,
            icon: Icons.route_outlined,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final link in snapshot.crossMapLinks)
                OutlinedButton.icon(
                  onPressed: snapshot.hasSelectedResult
                      ? () => onOpenCrossMapLink(link)
                      : null,
                  icon: Icon(_iconForBridgeLink(link.id), size: 18),
                  label: Text(link.titleAr),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _BridgeStatusCard(
            title: 'حزمة التدقيق',
            value:
                '${snapshot.auditDomainAr} • ${snapshot.auditPriorityAr} • ${snapshot.auditSourceType}',
            icon: Icons.fact_check_outlined,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: snapshot.hasSelectedResult ? onPrepareAuditContext : null,
                icon: const Icon(Icons.center_focus_strong_outlined, size: 18),
                label: const Text('جهّز سياق التدقيق'),
              ),
              OutlinedButton.icon(
                onPressed: snapshot.hasSelectedResult ? onCopyAuditHandoff : null,
                icon: const Icon(Icons.assignment_outlined, size: 18),
                label: const Text('نسخ حزمة التدقيق'),
              ),
              OutlinedButton.icon(
                onPressed: snapshot.hasSelectedResult ? onDownloadAuditCsv : null,
                icon: const Icon(Icons.download_for_offline_outlined, size: 18),
                label: const Text('CSV تدقيق'),
              ),
              FilledButton.icon(
                onPressed: snapshot.hasSelectedResult
                    ? () => onCreateRealAuditRequest()
                    : null,
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('إنشاء طلب فعلي'),
              ),
              FilledButton.icon(
                onPressed: snapshot.hasSelectedResult
                    ? () => onCreateRealAuditTask()
                    : null,
                icon: const Icon(Icons.add_task_outlined, size: 18),
                label: const Text('إنشاء طلب + مهمة'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenGapAudits,
                icon: const Icon(Icons.rule_folder_outlined, size: 18),
                label: const Text('لوحة الفجوات'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenAuditTasks,
                icon: const Icon(Icons.task_alt_outlined, size: 18),
                label: const Text('مهام التدقيق'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Bridge M ينشئ طلب التدقيق فعليًا، ويمكنه قبول الطلب وإنشاء مهمة تدقيق عند توفر SQL/RPC/RBAC. عند فشل RPC يبقى تقرير التوريث وCSV متاحين كمسار آمن.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForBridgeLink(String id) {
  return switch (id) {
    'modern_map' => Icons.map_outlined,
    'historical_spatial' => Icons.history_edu_outlined,
    'waqf_history' => Icons.account_balance_outlined,
    'historical_admin' => Icons.account_tree_outlined,
    _ => Icons.open_in_new_outlined,
  };
}

class _BridgeStatusCard extends StatelessWidget {
  const _BridgeStatusCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: PwfColors.primaryBlue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _SmartExplorerWorkflowGateway extends StatelessWidget {
  const _SmartExplorerWorkflowGateway({
    required this.state,
    required this.onLoadSampleDocument,
    required this.onAnalyzeDocument,
    required this.onGenerateInvestigationReport,
    required this.onGenerateAiDocumentIntelligenceStageReport,
    required this.onGenerateSpatialVerificationStageReport,
    required this.onGenerateEvidenceMatrix,
    required this.onGenerateDecisionBoard,
    required this.onGenerateReviewWorkflow,
    required this.onGenerateSmartExplorerQuickStart,
  });

  final SmartExplorerState state;
  final VoidCallback onLoadSampleDocument;
  final VoidCallback onAnalyzeDocument;
  final VoidCallback onGenerateInvestigationReport;
  final VoidCallback onGenerateAiDocumentIntelligenceStageReport;
  final VoidCallback onGenerateSpatialVerificationStageReport;
  final VoidCallback onGenerateEvidenceMatrix;
  final VoidCallback onGenerateDecisionBoard;
  final VoidCallback onGenerateReviewWorkflow;
  final VoidCallback onGenerateSmartExplorerQuickStart;

  @override
  Widget build(BuildContext context) {
    final hasDocument = state.documentDraft.trim().isNotEmpty;
    final hasResults = state.filteredResults.isNotEmpty;
    final hasEvidence = state.documentAnalysis != null || state.evidenceMatrix != null;
    final canBuildDecision = hasResults || hasEvidence || state.readinessAssessments.isNotEmpty;

    final workflows = <_SmartWorkflowCard>[
      _SmartWorkflowCard(
        icon: Icons.travel_explore_outlined,
        title: 'أبحث عن أصل أو إشارة مكانية',
        description: 'استخدم مربع البحث أعلى الصفحة للعثور على وقف، موقع، حوض، أو قرينة مكانية ثم افتح النتيجة على الخريطة.',
        input: 'اسم وقف، موقع، حوض، قطعة، أو وصف مختصر.',
        output: 'قائمة نتائج قابلة للفتح على الخريطة أو الإحالة للتدقيق.',
        primaryLabel: 'افتح خريطة العمل',
        onPrimary: () => context.go('/admin/mustakshif/review-map?source=smart_explorer_workflow_search'),
        secondaryLabel: hasResults ? 'تقرير تحقيق' : 'ابدأ بالبحث أولًا',
        onSecondary: hasResults ? onGenerateInvestigationReport : null,
      ),
      _SmartWorkflowCard(
        icon: Icons.document_scanner_outlined,
        title: 'أحلل وثيقة أو صورة OCR',
        description: 'الصق نص الوثيقة أو نتيجة OCR لاستخراج المسميات والقرائن، ثم اربطها بنتائج البحث أو لوحة المراجعة.',
        input: 'نص وثيقة، حجة، وصف حدود، أو مخرجات OCR.',
        output: 'مسميات وقرائن، ثم تقرير ذكاء وثائق قابل للمراجعة.',
        primaryLabel: hasDocument ? 'حلّل النص الآن' : 'ضع مثال وثيقة',
        onPrimary: hasDocument ? onAnalyzeDocument : onLoadSampleDocument,
        secondaryLabel: 'حزمة ذكاء الوثائق',
        onSecondary: onGenerateAiDocumentIntelligenceStageReport,
      ),
      _SmartWorkflowCard(
        icon: Icons.polyline_outlined,
        title: 'أتحقق من نقطة أو حدود أو مخطط',
        description: 'مسار التحقق المكاني والمساحي يجهز مطابقة النقاط والحدود والمخططات مع التسوية دون اعتمادها كحقيقة نهائية.',
        input: 'نقطة، حدود، رقم قطعة، PDF/DWG، أو وصف مجاورين.',
        output: 'تقرير تحقق مكاني ومساحي + توصية إحالة عند وجود تعارض.',
        primaryLabel: 'ابدأ التحقق المكاني',
        onPrimary: onGenerateSpatialVerificationStageReport,
        secondaryLabel: 'افتح الخريطة',
        onSecondary: () => context.go('/admin/mustakshif/review-map?source=smart_explorer_spatial_workflow'),
      ),
      _SmartWorkflowCard(
        icon: Icons.schema_outlined,
        title: 'أبني مصفوفة أدلة وقرار',
        description: 'يجمع نتائج البحث والوثائق والفرضيات في مصفوفة أدلة ثم يخرج لوحة قرار قابلة للمراجعة البشرية.',
        input: 'نتائج بحث و/أو تحليل وثيقة.',
        output: 'مصفوفة أدلة، جاهزية، لوحة قرار، وسجل مراجعة.',
        primaryLabel: 'مصفوفة أدلة',
        onPrimary: (hasResults && state.documentAnalysis != null) ? onGenerateEvidenceMatrix : null,
        secondaryLabel: 'لوحة قرار',
        onSecondary: canBuildDecision ? onGenerateDecisionBoard : null,
      ),
      _SmartWorkflowCard(
        icon: Icons.fact_check_outlined,
        title: 'أحوّل النتيجة إلى مراجعة وتكليف',
        description: 'ينقل الناتج من التحليل إلى مسار مراجعة بشري، مع إمكانية فتح لوحة المراجعة أو بناء Workflow مراجعة.',
        input: 'نتيجة بحث أو تحليل أو مصفوفة أدلة.',
        output: 'مسار مراجعة، طلب تدقيق، أو قرار قبول/استكمال/رفض.',
        primaryLabel: 'افتح لوحة المراجعة',
        onPrimary: () => context.go('/admin/mustakshif/review-board?source=smart_explorer_workflow_review'),
        secondaryLabel: 'Workflow مراجعة',
        onSecondary: (hasResults || hasEvidence) ? onGenerateReviewWorkflow : null,
      ),
      _SmartWorkflowCard(
        icon: Icons.school_outlined,
        title: 'أحتاج إرشادًا سريعًا',
        description: 'يعرض دليل استخدام مختصر يشرح أين تبدأ، ومتى تستخدم كل مسار، وما النتيجة المتوقعة.',
        input: 'لا يحتاج مدخلات.',
        output: 'دليل سريع داخل التقرير/المخرجات.',
        primaryLabel: 'بدء سريع',
        onPrimary: onGenerateSmartExplorerQuickStart,
        secondaryLabel: 'مركز الخدمات',
        onSecondary: () => context.go('/admin/explorer-suite/operations?source=smart_explorer_quick_help'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ابدأ من رحلة عمل واضحة. الأدوات التفصيلية موجودة بالأسفل لكنها مطوية حتى لا تختلط على المستخدم التشغيلي.',
          style: TextStyle(
            color: Color(0xFF475569),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final cardWidth = wide
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final workflow in workflows)
                  SizedBox(width: cardWidth, child: workflow),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SmartWorkflowCard extends StatelessWidget {
  const _SmartWorkflowCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.input,
    required this.output,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String description;
  final String input;
  final String output;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: PwfColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: PwfColors.primaryBlue, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          _WorkflowMetaLine(
            icon: Icons.input_outlined,
            label: 'المدخلات',
            value: input,
          ),
          const SizedBox(height: 8),
          _WorkflowMetaLine(
            icon: Icons.output_outlined,
            label: 'الناتج',
            value: output,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onPrimary,
                icon: const Icon(Icons.play_arrow_outlined, size: 18),
                label: Text(primaryLabel),
              ),
              OutlinedButton.icon(
                onPressed: onSecondary,
                icon: const Icon(Icons.open_in_new_outlined, size: 18),
                label: Text(secondaryLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkflowMetaLine extends StatelessWidget {
  const _WorkflowMetaLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UnifiedIntelligencePanel extends StatelessWidget {
  const _UnifiedIntelligencePanel({
    required this.state,
    required this.documentController,
    required this.onDocumentChanged,
    required this.onLoadSampleDocument,
    required this.onAnalyzeDocument,
    required this.onClearDocumentAnalysis,
    required this.onGenerateRoutePlan,
    required this.onClearRoutePlan,
    required this.onGenerateInvestigationReport,
    required this.onClearInvestigationReport,
    required this.onGenerateGazetteerDraft,
    required this.onClearGazetteerDraft,
    required this.onGenerateEvidenceMatrix,
    required this.onClearEvidenceMatrix,
    required this.onGenerateReadinessAssessments,
    required this.onClearReadinessAssessments,
    required this.onGenerateDecisionBoard,
    required this.onClearDecisionBoard,
    required this.onGenerateFieldChecklist,
    required this.onClearFieldChecklist,
    required this.onGenerateRiskRegister,
    required this.onClearRiskRegister,
    required this.onGenerateQaScenarios,
    required this.onClearQaScenarios,
    required this.onGenerateHandoffPacket,
    required this.onClearHandoffPacket,
    required this.onGenerateWorkspaceSnapshot,
    required this.onClearWorkspaceSnapshot,
    required this.onGenerateWorkPackages,
    required this.onClearWorkPackages,
    required this.onGenerateLayerRecommendations,
    required this.onClearLayerRecommendations,
    required this.onGenerateValidationProtocol,
    required this.onClearValidationProtocol,
    required this.onGenerateKnowledgeCards,
    required this.onClearKnowledgeCards,
    required this.onGenerateExecutiveBrief,
    required this.onClearExecutiveBrief,
    required this.onGenerateInvestigationSession,
    required this.onClearInvestigationSession,
    required this.onGenerateHypothesisComparison,
    required this.onClearHypothesisComparison,
    required this.onGenerateDataLineage,
    required this.onClearDataLineage,
    required this.onGenerateClosureGate,
    required this.onClearClosureGate,
    required this.onGenerateFinalIntegrationMemo,
    required this.onClearFinalIntegrationMemo,
    required this.onGenerateActionPlan,
    required this.onClearActionPlan,
    required this.onGenerateStakeholderMatrix,
    required this.onClearStakeholderMatrix,
    required this.onGenerateDecisionLog,
    required this.onClearDecisionLog,
    required this.onGenerateExportBundle,
    required this.onClearExportBundle,
    required this.onGenerateQualityScorecard,
    required this.onClearQualityScorecard,
    required this.onGenerateReviewWorkflow,
    required this.onClearReviewWorkflow,
    required this.onGenerateAssumptionLedger,
    required this.onClearAssumptionLedger,
    required this.onGenerateCrossSystemBridgePlan,
    required this.onClearCrossSystemBridgePlan,
    required this.onGenerateExpectedOutcomes,
    required this.onClearExpectedOutcomes,
    required this.onGenerateSourceAcquisitionPlan,
    required this.onClearSourceAcquisitionPlan,
    required this.onGenerateConfidenceZones,
    required this.onClearConfidenceZones,
    required this.onGenerateTemporalAdminTrace,
    required this.onClearTemporalAdminTrace,
    required this.onGenerateAuditPlaybook,
    required this.onClearAuditPlaybook,
    required this.onGenerateReleaseReadiness,
    required this.onClearReleaseReadiness,
    required this.onGenerateRuntimeDiagnostics,
    required this.onClearRuntimeDiagnostics,
    required this.onGenerateStrategicOutcomePack,
    required this.onGenerateCurrentBaselineSafeExpansionPack,
    required this.onGenerateSelfDevelopmentPack,
    required this.onGenerateAutonomousQaPack,
    required this.onGenerateAutonomousQaCsv,
    required this.onGenerateMergeReadinessRunbook,
    required this.onGenerateNamedBaselineManifest,
    required this.onGenerateOperationalIntegrationStage,
    required this.onGenerateSmartExplorerUserGuide,
    required this.onGenerateSmartExplorerQuickStart,
    required this.onGenerateOperationalAcceptanceChecklist,
    required this.onGenerateActualRuntimeWiringStage,
    required this.onGenerateAnalyzerClosureReport,
    required this.onGenerateActualRuntimeWiringCsv,
    required this.onGenerateIntegratedFinalStageQzReport,
    required this.onGenerateIntegratedFinalStageQzCsv,
    required this.onGenerateIntegratedFinalUserGuideQz,
    required this.onGenerateIntegratedFinalOperationsManualQz,
    required this.onGeneratePostQzOperationalClosureReport,
    required this.onGeneratePostQzOperationalClosureCsv,
    required this.onGeneratePostQzExplorerIntegrationInstructions,
    required this.onGeneratePostQzFinalUserGuideAddendum,
    required this.onGenerateAiDocumentIntelligenceStageReport,
    required this.onGenerateAiDocumentIntelligenceStageCsv,
    required this.onGenerateAiDocumentIntelligenceSqlDraft,
    required this.onGenerateAiDocumentIntelligenceIntegrationInstructions,
    required this.onGenerateAiDocumentIntelligenceUserGuideAddendum,
    required this.onGenerateSpatialVerificationStageReport,
    required this.onGenerateSpatialVerificationStageCsv,
    required this.onGenerateSpatialVerificationSqlDraft,
    required this.onGenerateSpatialVerificationIntegrationInstructions,
    required this.onGenerateSpatialVerificationUserGuideAddendum,
    required this.onGenerateLocalAnalyzerContract,
    required this.onGenerateSelfDevelopmentCsv,
    required this.onGenerateReviewQueueCsv,
    required this.onGenerateGazetteerCsv,
    required this.onClearExportText,
    required this.onCopyText,
  });

  final SmartExplorerState state;
  final TextEditingController documentController;
  final ValueChanged<String> onDocumentChanged;
  final VoidCallback onLoadSampleDocument;
  final VoidCallback onAnalyzeDocument;
  final VoidCallback onClearDocumentAnalysis;
  final VoidCallback onGenerateRoutePlan;
  final VoidCallback onClearRoutePlan;
  final VoidCallback onGenerateInvestigationReport;
  final VoidCallback onClearInvestigationReport;
  final VoidCallback onGenerateGazetteerDraft;
  final VoidCallback onClearGazetteerDraft;
  final VoidCallback onGenerateEvidenceMatrix;
  final VoidCallback onClearEvidenceMatrix;
  final VoidCallback onGenerateReadinessAssessments;
  final VoidCallback onClearReadinessAssessments;
  final VoidCallback onGenerateDecisionBoard;
  final VoidCallback onClearDecisionBoard;
  final VoidCallback onGenerateFieldChecklist;
  final VoidCallback onClearFieldChecklist;
  final VoidCallback onGenerateRiskRegister;
  final VoidCallback onClearRiskRegister;
  final VoidCallback onGenerateQaScenarios;
  final VoidCallback onClearQaScenarios;
  final VoidCallback onGenerateHandoffPacket;
  final VoidCallback onClearHandoffPacket;
  final VoidCallback onGenerateWorkspaceSnapshot;
  final VoidCallback onClearWorkspaceSnapshot;
  final VoidCallback onGenerateWorkPackages;
  final VoidCallback onClearWorkPackages;
  final VoidCallback onGenerateLayerRecommendations;
  final VoidCallback onClearLayerRecommendations;
  final VoidCallback onGenerateValidationProtocol;
  final VoidCallback onClearValidationProtocol;
  final VoidCallback onGenerateKnowledgeCards;
  final VoidCallback onClearKnowledgeCards;
  final VoidCallback onGenerateExecutiveBrief;
  final VoidCallback onClearExecutiveBrief;
  final VoidCallback onGenerateInvestigationSession;
  final VoidCallback onClearInvestigationSession;
  final VoidCallback onGenerateHypothesisComparison;
  final VoidCallback onClearHypothesisComparison;
  final VoidCallback onGenerateDataLineage;
  final VoidCallback onClearDataLineage;
  final VoidCallback onGenerateClosureGate;
  final VoidCallback onClearClosureGate;
  final VoidCallback onGenerateFinalIntegrationMemo;
  final VoidCallback onClearFinalIntegrationMemo;
  final VoidCallback onGenerateActionPlan;
  final VoidCallback onClearActionPlan;
  final VoidCallback onGenerateStakeholderMatrix;
  final VoidCallback onClearStakeholderMatrix;
  final VoidCallback onGenerateDecisionLog;
  final VoidCallback onClearDecisionLog;
  final VoidCallback onGenerateExportBundle;
  final VoidCallback onClearExportBundle;
  final VoidCallback onGenerateQualityScorecard;
  final VoidCallback onClearQualityScorecard;
  final VoidCallback onGenerateReviewWorkflow;
  final VoidCallback onClearReviewWorkflow;
  final VoidCallback onGenerateAssumptionLedger;
  final VoidCallback onClearAssumptionLedger;
  final VoidCallback onGenerateCrossSystemBridgePlan;
  final VoidCallback onClearCrossSystemBridgePlan;
  final VoidCallback onGenerateExpectedOutcomes;
  final VoidCallback onClearExpectedOutcomes;
  final VoidCallback onGenerateSourceAcquisitionPlan;
  final VoidCallback onClearSourceAcquisitionPlan;
  final VoidCallback onGenerateConfidenceZones;
  final VoidCallback onClearConfidenceZones;
  final VoidCallback onGenerateTemporalAdminTrace;
  final VoidCallback onClearTemporalAdminTrace;
  final VoidCallback onGenerateAuditPlaybook;
  final VoidCallback onClearAuditPlaybook;
  final VoidCallback onGenerateReleaseReadiness;
  final VoidCallback onClearReleaseReadiness;
  final VoidCallback onGenerateRuntimeDiagnostics;
  final VoidCallback onClearRuntimeDiagnostics;
  final VoidCallback onGenerateStrategicOutcomePack;
  final VoidCallback onGenerateCurrentBaselineSafeExpansionPack;
  final VoidCallback onGenerateSelfDevelopmentPack;
  final VoidCallback onGenerateAutonomousQaPack;
  final VoidCallback onGenerateAutonomousQaCsv;
  final VoidCallback onGenerateMergeReadinessRunbook;
  final VoidCallback onGenerateNamedBaselineManifest;
  final VoidCallback onGenerateOperationalIntegrationStage;
  final VoidCallback onGenerateSmartExplorerUserGuide;
  final VoidCallback onGenerateSmartExplorerQuickStart;
  final VoidCallback onGenerateOperationalAcceptanceChecklist;
  final VoidCallback onGenerateActualRuntimeWiringStage;
  final VoidCallback onGenerateAnalyzerClosureReport;
  final VoidCallback onGenerateActualRuntimeWiringCsv;
  final VoidCallback onGenerateIntegratedFinalStageQzReport;
  final VoidCallback onGenerateIntegratedFinalStageQzCsv;
  final VoidCallback onGenerateIntegratedFinalUserGuideQz;
  final VoidCallback onGenerateIntegratedFinalOperationsManualQz;
  final VoidCallback onGeneratePostQzOperationalClosureReport;
  final VoidCallback onGeneratePostQzOperationalClosureCsv;
  final VoidCallback onGeneratePostQzExplorerIntegrationInstructions;
  final VoidCallback onGeneratePostQzFinalUserGuideAddendum;
  final VoidCallback onGenerateAiDocumentIntelligenceStageReport;
  final VoidCallback onGenerateAiDocumentIntelligenceStageCsv;
  final VoidCallback onGenerateAiDocumentIntelligenceSqlDraft;
  final VoidCallback onGenerateAiDocumentIntelligenceIntegrationInstructions;
  final VoidCallback onGenerateAiDocumentIntelligenceUserGuideAddendum;
  final VoidCallback onGenerateSpatialVerificationStageReport;
  final VoidCallback onGenerateSpatialVerificationStageCsv;
  final VoidCallback onGenerateSpatialVerificationSqlDraft;
  final VoidCallback onGenerateSpatialVerificationIntegrationInstructions;
  final VoidCallback onGenerateSpatialVerificationUserGuideAddendum;
  final VoidCallback onGenerateLocalAnalyzerContract;
  final VoidCallback onGenerateSelfDevelopmentCsv;
  final VoidCallback onGenerateReviewQueueCsv;
  final VoidCallback onGenerateGazetteerCsv;
  final VoidCallback onClearExportText;
  final ValueChanged<String> onCopyText;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            spacing: 8,
            children: [
              const _SectionTitle(
                icon: Icons.hub_outlined,
                title: 'المستكشف الذكي — رحلات عمل تشغيلية',
              ),
              _InfoChip(
                label: 'بحث + وثائق + تحقق + مراجعة',
                icon: Icons.auto_awesome_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: documentController,
            onChanged: onDocumentChanged,
            minLines: 3,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText:
                  'الصق نص وثيقة/حجة/وصف حدود لاستخراج المسميات والقرائن الوصفية...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: PwfColors.primaryBlue),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SmartExplorerWorkflowGateway(
            state: state,
            onLoadSampleDocument: onLoadSampleDocument,
            onAnalyzeDocument: onAnalyzeDocument,
            onGenerateInvestigationReport: onGenerateInvestigationReport,
            onGenerateAiDocumentIntelligenceStageReport:
                onGenerateAiDocumentIntelligenceStageReport,
            onGenerateSpatialVerificationStageReport:
                onGenerateSpatialVerificationStageReport,
            onGenerateEvidenceMatrix: onGenerateEvidenceMatrix,
            onGenerateDecisionBoard: onGenerateDecisionBoard,
            onGenerateReviewWorkflow: onGenerateReviewWorkflow,
            onGenerateSmartExplorerQuickStart: onGenerateSmartExplorerQuickStart,
          ),
          const SizedBox(height: 12),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ExpansionTile(
                initiallyExpanded: false,
                maintainState: true,
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                leading: const Icon(
                  Icons.build_circle_outlined,
                  color: PwfColors.primaryBlue,
                ),
                title: const Text(
                  'الأدوات التفصيلية والمتقدمة',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: const Text(
                  'افتح هذا القسم فقط عند الحاجة إلى CSV، SQL sandbox، Runbook، أو مخرجات تدقيق متخصصة.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child:
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: onLoadSampleDocument,
                            icon: const Icon(Icons.note_add_outlined, size: 18),
                            label: const Text('مثال وثيقة'),
                          ),
                          FilledButton.icon(
                            onPressed:
                                state.documentDraft.trim().isEmpty ? null : onAnalyzeDocument,
                            icon: state.isAnalyzingDocument
                                ? const SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.find_in_page_outlined, size: 18),
                            label: const Text('تحليل النص'),
                          ),
                          OutlinedButton.icon(
                            onPressed: state.documentAnalysis == null
                                ? null
                                : onClearDocumentAnalysis,
                            icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                            label: const Text('مسح تحليل الوثيقة'),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                state.filteredResults.isEmpty ? null : onGenerateRoutePlan,
                            icon: const Icon(Icons.route_outlined, size: 18),
                            label: const Text('مسار تدقيق'),
                          ),
                          OutlinedButton.icon(
                            onPressed: state.routePlan == null ? null : onClearRoutePlan,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('إخفاء المسار'),
                          ),
                          FilledButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.routePlan == null)
                                ? null
                                : onGenerateInvestigationReport,
                            icon: const Icon(Icons.assignment_outlined, size: 18),
                            label: const Text('تقرير تحقيق موحد'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.documentAnalysis == null && state.filteredResults.isEmpty)
                                ? null
                                : onGenerateGazetteerDraft,
                            icon: const Icon(Icons.travel_explore_outlined, size: 18),
                            label: const Text('قاموس مسميات'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.documentAnalysis == null || state.filteredResults.isEmpty)
                                ? null
                                : onGenerateEvidenceMatrix,
                            icon: const Icon(Icons.schema_outlined, size: 18),
                            label: const Text('مصفوفة أدلة'),
                          ),
                          OutlinedButton.icon(
                            onPressed: state.filteredResults.isEmpty
                                ? null
                                : onGenerateReadinessAssessments,
                            icon: const Icon(Icons.fact_check_outlined, size: 18),
                            label: const Text('تقييم الجاهزية'),
                          ),
                          FilledButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null &&
                                    state.readinessAssessments.isEmpty)
                                ? null
                                : onGenerateDecisionBoard,
                            icon: const Icon(Icons.rule_outlined, size: 18),
                            label: const Text('لوحة قرار'),
                          ),
                          OutlinedButton.icon(
                            onPressed: state.filteredResults.isEmpty && state.documentAnalysis == null
                                ? null
                                : onGenerateFieldChecklist,
                            icon: const Icon(Icons.checklist_rtl_outlined, size: 18),
                            label: const Text('قائمة تدقيق'),
                          ),
                          OutlinedButton.icon(
                            onPressed: state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null
                                ? null
                                : onGenerateRiskRegister,
                            icon: const Icon(Icons.warning_amber_outlined, size: 18),
                            label: const Text('سجل مخاطر'),
                          ),
                          OutlinedButton.icon(
                            onPressed: state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null &&
                                    state.riskRegister == null
                                ? null
                                : onGenerateQaScenarios,
                            icon: const Icon(Icons.bug_report_outlined, size: 18),
                            label: const Text('اختبارات QA'),
                          ),
                          FilledButton.icon(
                            onPressed: state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.fieldChecklist == null &&
                                    state.riskRegister == null
                                ? null
                                : onGenerateHandoffPacket,
                            icon: const Icon(Icons.inventory_2_outlined, size: 18),
                            label: const Text('حزمة توريث'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.decisionBoard == null)
                                ? null
                                : onGenerateWorkspaceSnapshot,
                            icon: const Icon(Icons.inventory_outlined, size: 18),
                            label: const Text('لقطة عمل'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null &&
                                    state.readinessAssessments.isEmpty)
                                ? null
                                : onGenerateWorkPackages,
                            icon: const Icon(Icons.workspaces_outline, size: 18),
                            label: const Text('حزم عمل'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null)
                                ? null
                                : onGenerateLayerRecommendations,
                            icon: const Icon(Icons.layers_outlined, size: 18),
                            label: const Text('طبقات مقترحة'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null &&
                                    state.riskRegister == null)
                                ? null
                                : onGenerateValidationProtocol,
                            icon: const Icon(Icons.verified_outlined, size: 18),
                            label: const Text('بروتوكول تحقق'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null)
                                ? null
                                : onGenerateKnowledgeCards,
                            icon: const Icon(Icons.style_outlined, size: 18),
                            label: const Text('بطاقات معرفة'),
                          ),
                          FilledButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.workPackages == null &&
                                    state.layerRecommendations == null &&
                                    state.validationProtocol == null &&
                                    state.knowledgeCards == null)
                                ? null
                                : onGenerateExecutiveBrief,
                            icon: const Icon(Icons.summarize_outlined, size: 18),
                            label: const Text('موجز تنفيذي'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null)
                                ? null
                                : onGenerateInvestigationSession,
                            icon: const Icon(Icons.timeline_outlined, size: 18),
                            label: const Text('جلسة تحقيق'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null)
                                ? null
                                : onGenerateHypothesisComparison,
                            icon: const Icon(Icons.compare_arrows_outlined, size: 18),
                            label: const Text('مقارنة فرضيات'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.gazetteerEntries.isEmpty &&
                                    state.evidenceMatrix == null)
                                ? null
                                : onGenerateDataLineage,
                            icon: const Icon(Icons.account_tree_outlined, size: 18),
                            label: const Text('أثر البيانات'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.riskRegister == null &&
                                    state.validationProtocol == null)
                                ? null
                                : onGenerateClosureGate,
                            icon: const Icon(Icons.task_alt_outlined, size: 18),
                            label: const Text('بوابة إغلاق'),
                          ),
                          FilledButton.icon(
                            onPressed: (state.investigationSession == null &&
                                    state.hypothesisComparison == null &&
                                    state.dataLineage == null &&
                                    state.closureGate == null)
                                ? null
                                : onGenerateFinalIntegrationMemo,
                            icon: const Icon(Icons.integration_instructions_outlined, size: 18),
                            label: const Text('مذكرة دمج'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.fieldChecklist == null &&
                                    state.workPackages == null &&
                                    state.validationProtocol == null &&
                                    state.closureGate == null)
                                ? null
                                : onGenerateActionPlan,
                            icon: const Icon(Icons.playlist_add_check_outlined, size: 18),
                            label: const Text('خطة إجراءات'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null)
                                ? null
                                : onGenerateStakeholderMatrix,
                            icon: const Icon(Icons.groups_2_outlined, size: 18),
                            label: const Text('أصحاب العلاقة'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.decisionBoard == null &&
                                    state.closureGate == null &&
                                    state.actionPlan == null &&
                                    state.filteredResults.isEmpty)
                                ? null
                                : onGenerateDecisionLog,
                            icon: const Icon(Icons.fact_check_outlined, size: 18),
                            label: const Text('سجل قرارات'),
                          ),
                          FilledButton.icon(
                            onPressed: (state.actionPlan == null &&
                                    state.stakeholderMatrix == null &&
                                    state.decisionLog == null &&
                                    state.closureGate == null &&
                                    state.finalIntegrationMemoText == null &&
                                    state.handoffPacketText == null)
                                ? null
                                : onGenerateExportBundle,
                            icon: const Icon(Icons.inventory_2_outlined, size: 18),
                            label: const Text('حزمة تسليم'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null &&
                                    state.riskRegister == null &&
                                    state.closureGate == null)
                                ? null
                                : onGenerateQualityScorecard,
                            icon: const Icon(Icons.scoreboard_outlined, size: 18),
                            label: const Text('بطاقة جودة'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.qualityScorecard == null &&
                                    state.closureGate == null)
                                ? null
                                : onGenerateReviewWorkflow,
                            icon: const Icon(Icons.account_tree_outlined, size: 18),
                            label: const Text('مسار مراجعة'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null &&
                                    state.hypothesisComparison == null)
                                ? null
                                : onGenerateAssumptionLedger,
                            icon: const Icon(Icons.psychology_alt_outlined, size: 18),
                            label: const Text('سجل افتراضات'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.actionPlan == null &&
                                    state.closureGate == null &&
                                    state.exportBundle == null)
                                ? null
                                : onGenerateCrossSystemBridgePlan,
                            icon: const Icon(Icons.hub_outlined, size: 18),
                            label: const Text('ربط الأنظمة'),
                          ),
                          FilledButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null &&
                                    state.qualityScorecard == null &&
                                    state.closureGate == null)
                                ? null
                                : onGenerateExpectedOutcomes,
                            icon: const Icon(Icons.insights_outlined, size: 18),
                            label: const Text('نتائج متوقعة'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null &&
                                    state.assumptionLedger == null)
                                ? null
                                : onGenerateSourceAcquisitionPlan,
                            icon: const Icon(Icons.source_outlined, size: 18),
                            label: const Text('تحصيل مصادر'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null)
                                ? null
                                : onGenerateConfidenceZones,
                            icon: const Icon(Icons.radar_outlined, size: 18),
                            label: const Text('مناطق ثقة'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.gazetteerEntries.isEmpty)
                                ? null
                                : onGenerateTemporalAdminTrace,
                            icon: const Icon(Icons.history_edu_outlined, size: 18),
                            label: const Text('أثر زمني'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.sourceAcquisitionPlan == null &&
                                    state.confidenceZones == null &&
                                    state.closureGate == null)
                                ? null
                                : onGenerateAuditPlaybook,
                            icon: const Icon(Icons.menu_book_outlined, size: 18),
                            label: const Text('دليل تدقيق'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.qualityScorecard == null &&
                                    state.closureGate == null &&
                                    state.sourceAcquisitionPlan == null &&
                                    state.auditPlaybook == null)
                                ? null
                                : onGenerateReleaseReadiness,
                            icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                            label: const Text('جاهزية إصدار'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null &&
                                    state.qualityScorecard == null &&
                                    state.sourceAcquisitionPlan == null &&
                                    state.auditPlaybook == null &&
                                    state.releaseReadiness == null)
                                ? null
                                : onGenerateRuntimeDiagnostics,
                            icon: const Icon(Icons.monitor_heart_outlined, size: 18),
                            label: const Text('تشخيص تشغيل'),
                          ),
                          FilledButton.icon(
                            onPressed: (state.expectedOutcomes == null &&
                                    state.sourceAcquisitionPlan == null &&
                                    state.confidenceZones == null &&
                                    state.temporalAdminTrace == null &&
                                    state.auditPlaybook == null &&
                                    state.releaseReadiness == null)
                                ? null
                                : onGenerateStrategicOutcomePack,
                            icon: const Icon(Icons.folder_copy_outlined, size: 18),
                            label: const Text('حزمة استراتيجية'),
                          ),
                          FilledButton.icon(
                            onPressed: (state.filteredResults.isEmpty &&
                                    state.documentAnalysis == null &&
                                    state.evidenceMatrix == null &&
                                    state.qualityScorecard == null &&
                                    state.runtimeDiagnostics == null)
                                ? null
                                : onGenerateCurrentBaselineSafeExpansionPack,
                            icon: const Icon(Icons.security_update_good_outlined, size: 18),
                            label: const Text('حزمة baseline آمنة'),
                          ),
                          FilledButton.icon(
                            onPressed: onGenerateSelfDevelopmentPack,
                            icon: const Icon(Icons.precision_manufacturing_outlined, size: 18),
                            label: const Text('حزمة تطوير ذاتي'),
                          ),
                          FilledButton.icon(
                            onPressed: onGenerateAutonomousQaPack,
                            icon: const Icon(Icons.verified_outlined, size: 18),
                            label: const Text('QA ذاتي'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateMergeReadinessRunbook,
                            icon: const Icon(Icons.rule_folder_outlined, size: 18),
                            label: const Text('Runbook دمج'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateNamedBaselineManifest,
                            icon: const Icon(Icons.badge_outlined, size: 18),
                            label: const Text('بيان baseline المسمى'),
                          ),
                          FilledButton.icon(
                            onPressed: onGenerateOperationalIntegrationStage,
                            icon: const Icon(Icons.hub_outlined, size: 18),
                            label: const Text('مرحلة اندماج تشغيلية'),
                          ),
                          FilledButton.icon(
                            onPressed: onGenerateActualRuntimeWiringStage,
                            icon: const Icon(Icons.cable_outlined, size: 18),
                            label: const Text('ربط runtime فعلي'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateAnalyzerClosureReport,
                            icon: const Icon(Icons.fact_check_outlined, size: 18),
                            label: const Text('إغلاق analyzer'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateActualRuntimeWiringCsv,
                            icon: const Icon(Icons.dataset_outlined, size: 18),
                            label: const Text('CSV runtime'),
                          ),
                          FilledButton.icon(
                            onPressed: onGenerateIntegratedFinalStageQzReport,
                            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                            label: const Text('المرحلة النهائية Q→Z'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateIntegratedFinalStageQzCsv,
                            icon: const Icon(Icons.view_timeline_outlined, size: 18),
                            label: const Text('CSV Q→Z'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateIntegratedFinalUserGuideQz,
                            icon: const Icon(Icons.school_outlined, size: 18),
                            label: const Text('دليل Q→Z'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateIntegratedFinalOperationsManualQz,
                            icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
                            label: const Text('تشغيل Q→Z'),
                          ),
                          FilledButton.icon(
                            onPressed: onGeneratePostQzOperationalClosureReport,
                            icon: const Icon(Icons.task_alt_outlined, size: 18),
                            label: const Text('إغلاق Post-QZ'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGeneratePostQzOperationalClosureCsv,
                            icon: const Icon(Icons.table_rows_outlined, size: 18),
                            label: const Text('CSV Post-QZ'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGeneratePostQzExplorerIntegrationInstructions,
                            icon: const Icon(Icons.integration_instructions_outlined, size: 18),
                            label: const Text('تعليمات الدمج'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGeneratePostQzFinalUserGuideAddendum,
                            icon: const Icon(Icons.library_books_outlined, size: 18),
                            label: const Text('ملحق الدليل'),
                          ),
                          FilledButton.icon(
                            onPressed: onGenerateAiDocumentIntelligenceStageReport,
                            icon: const Icon(Icons.document_scanner_outlined, size: 18),
                            label: const Text('ذكاء الوثائق'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateAiDocumentIntelligenceStageCsv,
                            icon: const Icon(Icons.table_chart_outlined, size: 18),
                            label: const Text('CSV ذكاء الوثائق'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateAiDocumentIntelligenceSqlDraft,
                            icon: const Icon(Icons.storage_outlined, size: 18),
                            label: const Text('SQL AI'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateAiDocumentIntelligenceIntegrationInstructions,
                            icon: const Icon(Icons.integration_instructions_outlined, size: 18),
                            label: const Text('تعليمات AI'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateAiDocumentIntelligenceUserGuideAddendum,
                            icon: const Icon(Icons.psychology_alt_outlined, size: 18),
                            label: const Text('دليل AI'),
                          ),
                          FilledButton.icon(
                            onPressed: onGenerateSpatialVerificationStageReport,
                            icon: const Icon(Icons.polyline_outlined, size: 18),
                            label: const Text('التحقق المكاني'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateSpatialVerificationStageCsv,
                            icon: const Icon(Icons.table_chart_outlined, size: 18),
                            label: const Text('CSV التحقق المكاني'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateSpatialVerificationSqlDraft,
                            icon: const Icon(Icons.storage_outlined, size: 18),
                            label: const Text('SQL مكاني'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateSpatialVerificationIntegrationInstructions,
                            icon: const Icon(Icons.integration_instructions_outlined, size: 18),
                            label: const Text('تعليمات مكاني'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateSpatialVerificationUserGuideAddendum,
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('دليل مكاني'),
                          ),
                          FilledButton.icon(
                            onPressed: onGenerateSmartExplorerUserGuide,
                            icon: const Icon(Icons.menu_book_outlined, size: 18),
                            label: const Text('دليل استخدام'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateSmartExplorerQuickStart,
                            icon: const Icon(Icons.flash_on_outlined, size: 18),
                            label: const Text('بدء سريع'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateOperationalAcceptanceChecklist,
                            icon: const Icon(Icons.playlist_add_check_circle_outlined, size: 18),
                            label: const Text('Checklist قبول'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateAutonomousQaCsv,
                            icon: const Icon(Icons.checklist_rtl_outlined, size: 18),
                            label: const Text('CSV QA'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateLocalAnalyzerContract,
                            icon: const Icon(Icons.integration_instructions_outlined, size: 18),
                            label: const Text('عقد المحلل المحلي'),
                          ),
                          OutlinedButton.icon(
                            onPressed: onGenerateSelfDevelopmentCsv,
                            icon: const Icon(Icons.table_chart_outlined, size: 18),
                            label: const Text('CSV التطوير الذاتي'),
                          ),
                          OutlinedButton.icon(
                            onPressed: state.filteredResults.isEmpty ? null : onGenerateReviewQueueCsv,
                            icon: const Icon(Icons.table_view_outlined, size: 18),
                            label: const Text('CSV المراجعة'),
                          ),
                          OutlinedButton.icon(
                            onPressed: state.gazetteerEntries.isEmpty ? null : onGenerateGazetteerCsv,
                            icon: const Icon(Icons.file_download_outlined, size: 18),
                            label: const Text('CSV المسميات'),
                          ),
                        ],
                      ),
                  ),
                ],
              ),
            ),
          ),
          if (state.documentAnalysis != null) ...[
            const SizedBox(height: 14),
            _DocumentAnalysisView(analysis: state.documentAnalysis!),
          ],
          if (state.gazetteerEntries.isNotEmpty) ...[
            const SizedBox(height: 14),
            _GazetteerDraftView(
              entries: state.gazetteerEntries,
              onClear: onClearGazetteerDraft,
            ),
          ],
          if (state.evidenceMatrix != null) ...[
            const SizedBox(height: 14),
            _EvidenceMatrixView(
              matrix: state.evidenceMatrix!,
              onClear: onClearEvidenceMatrix,
            ),
          ],
          if (state.readinessAssessments.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ReadinessAssessmentView(
              assessments: state.readinessAssessments,
              onClear: onClearReadinessAssessments,
            ),
          ],
          if (state.decisionBoard != null) ...[
            const SizedBox(height: 14),
            _DecisionBoardView(
              board: state.decisionBoard!,
              onClear: onClearDecisionBoard,
            ),
          ],
          if (state.fieldChecklist != null) ...[
            const SizedBox(height: 14),
            _FieldChecklistView(
              checklist: state.fieldChecklist!,
              onClear: onClearFieldChecklist,
            ),
          ],
          if (state.riskRegister != null) ...[
            const SizedBox(height: 14),
            _RiskRegisterView(
              register: state.riskRegister!,
              onClear: onClearRiskRegister,
            ),
          ],
          if (state.qaScenarios.isNotEmpty) ...[
            const SizedBox(height: 14),
            _QaScenariosView(
              scenarios: state.qaScenarios,
              onClear: onClearQaScenarios,
            ),
          ],
          if (state.workPackages != null) ...[
            const SizedBox(height: 14),
            _WorkPackagesView(
              packages: state.workPackages!,
              onClear: onClearWorkPackages,
            ),
          ],
          if (state.layerRecommendations != null) ...[
            const SizedBox(height: 14),
            _LayerRecommendationsView(
              recommendations: state.layerRecommendations!,
              onClear: onClearLayerRecommendations,
            ),
          ],
          if (state.validationProtocol != null) ...[
            const SizedBox(height: 14),
            _ValidationProtocolView(
              protocol: state.validationProtocol!,
              onClear: onClearValidationProtocol,
            ),
          ],
          if (state.knowledgeCards != null) ...[
            const SizedBox(height: 14),
            _KnowledgeCardsView(
              cards: state.knowledgeCards!,
              onClear: onClearKnowledgeCards,
            ),
          ],
          if (state.executiveBriefText != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'الموجز التنفيذي للمستكشف الذكي',
              text: state.executiveBriefText!,
              onCopy: () => onCopyText(state.executiveBriefText!),
              onClose: onClearExecutiveBrief,
            ),
          ],
          if (state.investigationSession != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'جلسة تحقيق المستكشف الذكي',
              text: state.investigationSession!.toReportText(),
              onCopy: () => onCopyText(state.investigationSession!.toReportText()),
              onClose: onClearInvestigationSession,
            ),
          ],
          if (state.hypothesisComparison != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'مقارنة فرضيات المستكشف الذكي',
              text: state.hypothesisComparison!.toReportText(),
              onCopy: () => onCopyText(state.hypothesisComparison!.toReportText()),
              onClose: onClearHypothesisComparison,
            ),
          ],
          if (state.dataLineage != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'أثر بيانات المستكشف الذكي',
              text: state.dataLineage!.toReportText(),
              onCopy: () => onCopyText(state.dataLineage!.toReportText()),
              onClose: onClearDataLineage,
            ),
          ],
          if (state.closureGate != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'بوابة إغلاق المستكشف الذكي',
              text: state.closureGate!.toReportText(),
              onCopy: () => onCopyText(state.closureGate!.toReportText()),
              onClose: onClearClosureGate,
            ),
          ],
          if (state.finalIntegrationMemoText != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'مذكرة دمج المستكشف الذكي',
              text: state.finalIntegrationMemoText!,
              onCopy: () => onCopyText(state.finalIntegrationMemoText!),
              onClose: onClearFinalIntegrationMemo,
            ),
          ],
          if (state.actionPlan != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'خطة إجراءات المستكشف الذكي',
              text: state.actionPlan!.toReportText(),
              onCopy: () => onCopyText(state.actionPlan!.toReportText()),
              onClose: onClearActionPlan,
            ),
          ],
          if (state.stakeholderMatrix != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'مصفوفة أصحاب العلاقة',
              text: state.stakeholderMatrix!.toReportText(),
              onCopy: () => onCopyText(state.stakeholderMatrix!.toReportText()),
              onClose: onClearStakeholderMatrix,
            ),
          ],
          if (state.decisionLog != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'سجل قرارات المستكشف الذكي',
              text: state.decisionLog!.toReportText(),
              onCopy: () => onCopyText(state.decisionLog!.toReportText()),
              onClose: onClearDecisionLog,
            ),
          ],
          if (state.exportBundle != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'حزمة تصدير/تسليم المستكشف الذكي',
              text: state.exportBundle!.toReportText(),
              onCopy: () => onCopyText(state.exportBundle!.toReportText()),
              onClose: onClearExportBundle,
            ),
          ],
          if (state.qualityScorecard != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'بطاقة جودة المستكشف الذكي',
              text: state.qualityScorecard!.toReportText(),
              onCopy: () => onCopyText(state.qualityScorecard!.toReportText()),
              onClose: onClearQualityScorecard,
            ),
          ],
          if (state.reviewWorkflow != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'مسار مراجعة المستكشف الذكي',
              text: state.reviewWorkflow!.toReportText(),
              onCopy: () => onCopyText(state.reviewWorkflow!.toReportText()),
              onClose: onClearReviewWorkflow,
            ),
          ],
          if (state.assumptionLedger != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'سجل افتراضات المستكشف الذكي',
              text: state.assumptionLedger!.toReportText(),
              onCopy: () => onCopyText(state.assumptionLedger!.toReportText()),
              onClose: onClearAssumptionLedger,
            ),
          ],
          if (state.crossSystemBridgePlan != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'خطة ربط المستكشف الذكي مع الأنظمة',
              text: state.crossSystemBridgePlan!.toReportText(),
              onCopy: () => onCopyText(state.crossSystemBridgePlan!.toReportText()),
              onClose: onClearCrossSystemBridgePlan,
            ),
          ],
          if (state.expectedOutcomes != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'ملف النتائج المتوقعة',
              text: state.expectedOutcomes!.toReportText(),
              onCopy: () => onCopyText(state.expectedOutcomes!.toReportText()),
              onClose: onClearExpectedOutcomes,
            ),
          ],
          if (state.sourceAcquisitionPlan != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'خطة تحصيل المصادر والأدلة',
              text: state.sourceAcquisitionPlan!.toReportText(),
              onCopy: () => onCopyText(state.sourceAcquisitionPlan!.toReportText()),
              onClose: onClearSourceAcquisitionPlan,
            ),
          ],
          if (state.confidenceZones != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'مناطق الثقة المكانية',
              text: state.confidenceZones!.toReportText(),
              onCopy: () => onCopyText(state.confidenceZones!.toReportText()),
              onClose: onClearConfidenceZones,
            ),
          ],
          if (state.temporalAdminTrace != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'الأثر الإداري الزمني',
              text: state.temporalAdminTrace!.toReportText(),
              onCopy: () => onCopyText(state.temporalAdminTrace!.toReportText()),
              onClose: onClearTemporalAdminTrace,
            ),
          ],
          if (state.auditPlaybook != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'دليل التدقيق التشغيلي',
              text: state.auditPlaybook!.toReportText(),
              onCopy: () => onCopyText(state.auditPlaybook!.toReportText()),
              onClose: onClearAuditPlaybook,
            ),
          ],
          if (state.releaseReadiness != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'جاهزية إصدار المستكشف الذكي',
              text: state.releaseReadiness!.toReportText(),
              onCopy: () => onCopyText(state.releaseReadiness!.toReportText()),
              onClose: onClearReleaseReadiness,
            ),
          ],
          if (state.runtimeDiagnostics != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'تشخيص تشغيل المستكشف الذكي',
              text: state.runtimeDiagnostics!.toReportText(),
              onCopy: () => onCopyText(state.runtimeDiagnostics!.toReportText()),
              onClose: onClearRuntimeDiagnostics,
            ),
          ],
          if (state.handoffPacketText != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'حزمة توريث المستكشف الذكي',
              text: state.handoffPacketText!,
              onCopy: () => onCopyText(state.handoffPacketText!),
              onClose: onClearHandoffPacket,
            ),
          ],
          if (state.workspaceSnapshotText != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'لقطة عمل المستكشف الذكي',
              text: state.workspaceSnapshotText!,
              onCopy: () => onCopyText(state.workspaceSnapshotText!),
              onClose: onClearWorkspaceSnapshot,
            ),
          ],
          if (state.exportText != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'نص تصدير / CSV',
              text: state.exportText!,
              onCopy: () => onCopyText(state.exportText!),
              onClose: onClearExportText,
            ),
          ],
          if (state.routePlan != null) ...[
            const SizedBox(height: 14),
            _RoutePlanView(plan: state.routePlan!),
          ],
          if (state.investigationReportText != null) ...[
            const SizedBox(height: 14),
            _MiniTextReportView(
              title: 'تقرير التحقيق الموحد',
              text: state.investigationReportText!,
              onCopy: () => onCopyText(state.investigationReportText!),
              onClose: onClearInvestigationReport,
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentAnalysisView extends StatelessWidget {
  const _DocumentAnalysisView({required this.analysis});

  final SmartExplorerDocumentAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: 'ثقة الوثيقة ${analysis.confidencePercent}%',
                icon: Icons.speed_outlined,
                color: _confidenceColor(analysis.confidencePercent),
              ),
              _InfoChip(
                label: '${analysis.entities.length} مسميات',
                icon: Icons.sell_outlined,
              ),
              _InfoChip(
                label: '${analysis.boundaryClues.length} قرائن حدود',
                icon: Icons.border_outer_outlined,
                color: const Color(0xFFC77700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            analysis.summaryAr,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
          if (analysis.entities.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.entities.take(18).map((entity) {
                return _InfoChip(
                  label:
                      '${entity.value} — ${entity.typeLabelAr} (${entity.scorePercent}%)',
                  icon: Icons.label_outline,
                  color: const Color(0xFF0F766E),
                );
              }).toList(growable: false),
            ),
          ],
          if (analysis.boundaryClues.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'قرائن الحدود:',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            ...analysis.boundaryClues.take(6).map(
                  (clue) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $clue',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
          ],
          if (analysis.spatialHypotheses.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'فرضيات مكانية من النص:',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            ...analysis.spatialHypotheses.take(6).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $item',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _GazetteerDraftView extends StatelessWidget {
  const _GazetteerDraftView({
    required this.entries,
    required this.onClear,
  });

  final List<SmartExplorerGazetteerEntry> entries;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              _SectionTitle(
                icon: Icons.travel_explore_outlined,
                title: 'قاموس المسميات المسودة (${entries.length})',
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('إخفاء'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entries.take(24).map((entry) {
              return _InfoChip(
                label:
                    '${entry.value} — ${entry.typeLabelAr} (${entry.confidencePercent}%)',
                icon: Icons.label_important_outline,
                color: entry.confidencePercent >= 70
                    ? const Color(0xFF0F766E)
                    : const Color(0xFFC77700),
              );
            }).toList(growable: false),
          ),
          if (entries.length > 24) ...[
            const SizedBox(height: 8),
            Text(
              'تم عرض أول 24 مدخلًا من أصل ${entries.length}. استخدم CSV المسميات لنسخ القائمة كاملة.',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EvidenceMatrixView extends StatelessWidget {
  const _EvidenceMatrixView({
    required this.matrix,
    required this.onClear,
  });

  final SmartExplorerEvidenceMatrix matrix;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              _SectionTitle(
                icon: Icons.schema_outlined,
                title: matrix.summaryAr,
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('إخفاء'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!matrix.hasLinks)
            const Text(
              'أدخل نص وثيقة وشغّل بحثًا مرتبطًا حتى تظهر روابط الأدلة.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w800,
              ),
            )
          else
            ...matrix.topLinks.take(10).map((link) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _InfoChip(
                          label: '${link.entityValue} — ${link.entityTypeLabelAr}',
                          icon: Icons.sell_outlined,
                        ),
                        _InfoChip(
                          label: '${link.scoreLabelAr} ${link.matchScore}%',
                          icon: Icons.speed_outlined,
                          color: link.isStrong
                              ? const Color(0xFF0F766E)
                              : const Color(0xFFC77700),
                        ),
                        if (link.hasConflict)
                          _InfoChip(
                            label: 'يوجد تعارض',
                            icon: Icons.warning_amber_rounded,
                            color: const Color(0xFFB22222),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      link.resultTitleAr,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'حقول مطابقة: ${link.matchedFields.isEmpty ? 'لا توجد' : link.matchedFields.join('، ')}',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (link.conflicts.isNotEmpty)
                      Text(
                        'تعارضات: ${link.conflicts.join(' / ')}',
                        style: const TextStyle(
                          color: Color(0xFFB22222),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Text(
                      link.recommendationAr,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ReadinessAssessmentView extends StatelessWidget {
  const _ReadinessAssessmentView({
    required this.assessments,
    required this.onClear,
  });

  final List<SmartExplorerReadinessAssessment> assessments;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              _SectionTitle(
                icon: Icons.fact_check_outlined,
                title: 'تقييم جاهزية النتائج (${assessments.length})',
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('إخفاء'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...assessments.take(8).map((item) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                        label: '${item.overallScore}% — ${item.readinessLabelAr}',
                        icon: Icons.speed_outlined,
                        color: _confidenceColor(item.overallScore),
                      ),
                      _InfoChip(
                        label: 'الخريطة ${item.publicMapScore}%',
                        icon: Icons.map_outlined,
                      ),
                      _InfoChip(
                        label: 'الميدان ${item.fieldAuditScore}%',
                        icon: Icons.route_outlined,
                      ),
                      _InfoChip(
                        label: 'التاريخ ${item.historyScore}%',
                        icon: Icons.timeline_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.titleAr,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (item.blockers.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'العوائق: ${item.blockers.join(' / ')}',
                      style: const TextStyle(
                        color: Color(0xFFB22222),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'التالي: ${item.nextActions.take(2).join(' / ')}',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RoutePlanView extends StatelessWidget {
  const _RoutePlanView({required this.plan});

  final SmartExplorerRoutePlan plan;

  @override
  Widget build(BuildContext context) {
    if (plan.isEmpty) {
      return const Text(
        'لا توجد نقاط كافية لبناء مسار تدقيق ضمن النتائج الحالية.',
        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.route_outlined,
            title: plan.summaryAr,
          ),
          const SizedBox(height: 8),
          ...plan.stops.take(12).map((stop) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: PwfColors.primaryBlue.withValues(alpha: 0.10),
                    child: Text(
                      '${stop.order}',
                      style: const TextStyle(
                        color: PwfColors.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.titleAr,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${stop.locationLabelAr} — ${stop.priorityLabelAr}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          stop.reasonAr,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DecisionBoardView extends StatelessWidget {
  const _DecisionBoardView({
    required this.board,
    required this.onClear,
  });

  final SmartExplorerDecisionBoard board;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              _SectionTitle(
                icon: Icons.rule_outlined,
                title: board.summaryAr,
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('إخفاء'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (board.isEmpty)
            const Text(
              'لا توجد قرارات تشغيلية مقترحة ضمن النطاق الحالي.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w800,
              ),
            )
          else
            ...board.topItems.map((item) {
              final color = item.isUrgent
                  ? PwfColors.royalRed
                  : item.priority >= 70
                      ? const Color(0xFFC77700)
                      : PwfColors.primaryBlue;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _InfoChip(
                          label: item.priorityLabelAr,
                          icon: Icons.priority_high_outlined,
                          color: color,
                        ),
                        _InfoChip(
                          label: item.domainAr,
                          icon: Icons.category_outlined,
                        ),
                        if (item.resultTitleAr != null)
                          _InfoChip(
                            label: item.resultTitleAr!,
                            icon: Icons.account_balance_outlined,
                            color: const Color(0xFF0F766E),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.titleAr,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.descriptionAr,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الإجراء: ${item.actionAr}',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _WorkPackagesView extends StatelessWidget {
  const _WorkPackagesView({
    required this.packages,
    required this.onClear,
  });

  final SmartExplorerWorkPackageSet packages;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              _SectionTitle(
                icon: Icons.workspaces_outline,
                title: packages.summaryAr,
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('إخفاء'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (packages.isEmpty)
            const Text(
              'لا توجد حزم عمل ضمن النطاق الحالي.',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800),
            )
          else
            ...packages.topPackages.map((item) {
              final color = item.isUrgent
                  ? PwfColors.royalRed
                  : item.priority >= 70
                      ? const Color(0xFFC77700)
                      : PwfColors.primaryBlue;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _InfoChip(label: item.priorityLabelAr, icon: Icons.priority_high_outlined, color: color),
                        _InfoChip(label: item.domainAr, icon: Icons.category_outlined),
                        _InfoChip(label: item.ownerRoleAr, icon: Icons.groups_outlined, color: const Color(0xFF0F766E)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(item.titleAr, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(item.objectiveAr, style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('المخرج: ${item.expectedOutputAr}', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
                    if (item.actions.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ...item.actions.take(3).map((action) => Text('• $action', style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700))),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _LayerRecommendationsView extends StatelessWidget {
  const _LayerRecommendationsView({
    required this.recommendations,
    required this.onClear,
  });

  final SmartExplorerLayerRecommendationSet recommendations;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              _SectionTitle(icon: Icons.layers_outlined, title: recommendations.summaryAr),
              TextButton.icon(onPressed: onClear, icon: const Icon(Icons.close, size: 18), label: const Text('إخفاء')),
            ],
          ),
          const SizedBox(height: 8),
          if (recommendations.isEmpty)
            const Text('لا توجد توصيات طبقات ضمن النطاق الحالي.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recommendations.topRecommendations.map((item) {
                final color = item.isRequired ? PwfColors.royalRed : PwfColors.primaryBlue;
                return Container(
                  width: 310,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.16)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoChip(label: item.priorityLabelAr, icon: Icons.flag_outlined, color: color),
                      const SizedBox(height: 6),
                      Text(item.titleAr, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(item.reasonAr, style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('الاستخدام: ${item.whenToUseAr}', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800)),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _ValidationProtocolView extends StatelessWidget {
  const _ValidationProtocolView({
    required this.protocol,
    required this.onClear,
  });

  final SmartExplorerValidationProtocol protocol;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              _SectionTitle(icon: Icons.verified_outlined, title: protocol.summaryAr),
              TextButton.icon(onPressed: onClear, icon: const Icon(Icons.close, size: 18), label: const Text('إخفاء')),
            ],
          ),
          const SizedBox(height: 8),
          ...protocol.gates.map((gate) {
            final color = gate.status == SmartExplorerValidationStatus.blocked
                ? PwfColors.royalRed
                : gate.status == SmartExplorerValidationStatus.warning
                    ? const Color(0xFFC77700)
                    : gate.status == SmartExplorerValidationStatus.pass
                        ? const Color(0xFF0F766E)
                        : PwfColors.primaryBlue;
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(label: gate.status.labelAr, icon: Icons.verified_outlined, color: color),
                      _InfoChip(label: gate.domainAr, icon: Icons.category_outlined),
                      if (gate.isBlocking) _InfoChip(label: 'مانعة', icon: Icons.block_outlined, color: PwfColors.royalRed),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(gate.titleAr, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(gate.descriptionAr, style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('الإجراء التالي: ${gate.nextActionAr}', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _KnowledgeCardsView extends StatelessWidget {
  const _KnowledgeCardsView({
    required this.cards,
    required this.onClear,
  });

  final SmartExplorerKnowledgeCardSet cards;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              _SectionTitle(icon: Icons.style_outlined, title: cards.summaryAr),
              TextButton.icon(onPressed: onClear, icon: const Icon(Icons.close, size: 18), label: const Text('إخفاء')),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cards.topCards.map((card) {
              final color = _confidenceColor(card.confidence);
              return Container(
                width: 320,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _InfoChip(label: card.typeAr, icon: Icons.label_outline, color: color),
                        _InfoChip(label: '${card.confidence}% — ${card.confidenceLabelAr}', icon: Icons.speed_outlined, color: color),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(card.titleAr, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(card.summaryAr, style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('سؤال المراجعة: ${card.reviewQuestionAr}', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
                  ],
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}


class _MiniTextReportView extends StatelessWidget {
  const _MiniTextReportView({
    required this.title,
    required this.text,
    required this.onCopy,
    required this.onClose,
  });

  final String title;
  final String text;
  final VoidCallback onCopy;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('نسخ'),
                  ),
                  TextButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('إغلاق'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: SingleChildScrollView(
              child: SelectableText(
                text,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontWeight: FontWeight.w600,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.state,
    required this.onSeverityChanged,
    required this.onMinConfidenceChanged,
    required this.onOnlyNeedsReviewChanged,
    required this.onOnlyWithoutSpatialReferenceChanged,
    required this.onOnlyWithoutLinkedParcelsChanged,
    required this.onOnlyMissingEndowmentChanged,
    required this.onClearFilters,
  });

  final SmartExplorerState state;
  final ValueChanged<SmartExplorerSeverityFilter> onSeverityChanged;
  final ValueChanged<int> onMinConfidenceChanged;
  final ValueChanged<bool> onOnlyNeedsReviewChanged;
  final ValueChanged<bool> onOnlyWithoutSpatialReferenceChanged;
  final ValueChanged<bool> onOnlyWithoutLinkedParcelsChanged;
  final ValueChanged<bool> onOnlyMissingEndowmentChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final filters = state.filters;
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _SectionTitle(
                icon: Icons.filter_alt_outlined,
                title: 'فلاتر التدقيق',
              ),
              if (filters.hasActiveFilters)
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: Text('مسح (${filters.activeCount})'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SmartExplorerSeverityFilter.values.map((item) {
              return ChoiceChip(
                label: Text(item.labelAr),
                selected: filters.severity == item,
                onSelected: (_) => onSeverityChanged(item),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          const Text(
            'حد الثقة الأدنى',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [0, 40, 65, 85].map((value) {
              return ChoiceChip(
                label: Text(value == 0 ? 'الكل' : '$value%+'),
                selected: filters.minConfidence == value,
                onSelected: (_) => onMinConfidenceChanged(value),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 8),
          _FilterSwitch(
            title: 'نتائج تحتاج مراجعة فقط',
            value: filters.onlyNeedsReview,
            onChanged: onOnlyNeedsReviewChanged,
          ),
          _FilterSwitch(
            title: 'بلا تمثيل مكاني فقط',
            value: filters.onlyWithoutSpatialReference,
            onChanged: onOnlyWithoutSpatialReferenceChanged,
          ),
          _FilterSwitch(
            title: 'بلا قطع مرتبطة فقط',
            value: filters.onlyWithoutLinkedParcels,
            onChanged: onOnlyWithoutLinkedParcelsChanged,
          ),
          _FilterSwitch(
            title: 'بلا وقف أم فقط',
            value: filters.onlyMissingEndowment,
            onChanged: onOnlyMissingEndowmentChanged,
          ),
        ],
      ),
    );
  }
}

class _FilterSwitch extends StatelessWidget {
  const _FilterSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.results,
    required this.selectedResultId,
    required this.onSelected,
  });

  final List<SmartExplorerResult> results;
  final String? selectedResultId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const _PanelCard(
        child: Text(
          'لا توجد نتائج ضمن الفلاتر الحالية.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Column(
      children: results.map((result) {
        final selected = result.id == selectedResultId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ResultCard(
            result: result,
            selected: selected,
            onTap: () => onSelected(result.id),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.selected,
    required this.onTap,
  });

  final SmartExplorerResult result;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor(result.topSeverity);
    final confidenceColor = _confidenceColor(result.confidenceScore);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? PwfColors.primaryBlue : const Color(0xFFE2E8F0),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: PwfColors.primaryBlue.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.psychology_alt_outlined, color: severityColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.titleAr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      if (result.subtitleAr.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          result.subtitleAr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: 'ثقة ${result.confidenceScore}%',
                  icon: Icons.speed_outlined,
                  color: confidenceColor,
                ),
                _InfoChip(
                  label: result.topSeverityLabelAr,
                  icon: Icons.report_problem_outlined,
                  color: severityColor,
                ),
                _InfoChip(
                  label: 'أولوية ${result.reviewPriorityLabelAr}',
                  icon: Icons.flag_outlined,
                  color: severityColor,
                ),
                if (result.assetCode.isNotEmpty)
                  _InfoChip(
                    label: result.assetCode,
                    icon: Icons.qr_code_2_outlined,
                  ),
              ],
            ),
            if (result.gapSignals.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                result.gapSignals.take(3).map((e) => e.titleAr).join('، '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultDetails extends StatelessWidget {
  const _ResultDetails({
    required this.result,
    required this.generatedHypothesis,
    required this.onOpenMap,
    required this.onOpenHistory,
    required this.onOpenWaqf,
    required this.onOpenAudit,
    required this.onCreateAuditRequest,
    required this.onGenerateHypothesis,
  });

  final SmartExplorerResult? result;
  final SmartExplorerHypothesis? generatedHypothesis;
  final ValueChanged<SmartExplorerResult> onOpenMap;
  final ValueChanged<SmartExplorerResult> onOpenHistory;
  final ValueChanged<SmartExplorerResult> onOpenWaqf;
  final ValueChanged<SmartExplorerResult> onOpenAudit;
  final ValueChanged<SmartExplorerResult> onCreateAuditRequest;
  final ValueChanged<SmartExplorerResult> onGenerateHypothesis;

  @override
  Widget build(BuildContext context) {
    final item = result;
    if (item == null) {
      return const _PanelCard(
        child: Text(
          'اختر نتيجة لعرض تفاصيل التحليل والفرضيات.',
          style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
        ),
      );
    }

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.manage_search_outlined,
            title: item.titleAr,
          ),
          const SizedBox(height: 8),
          Text(
            item.recommendedActionAr,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: 'الثقة ${item.confidenceScore}% - ${item.confidenceLabelAr}',
                icon: Icons.speed_outlined,
                color: _confidenceColor(item.confidenceScore),
              ),
              _InfoChip(
                label: 'أولوية ${item.reviewPriorityLabelAr}',
                icon: Icons.flag_outlined,
                color: _severityColor(item.topSeverity),
              ),
              _InfoChip(
                label: 'قطع: ${item.linkedParcelsCount}',
                icon: Icons.grid_4x4_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => onOpenMap(item),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('عرض على الخريطة'),
              ),
              OutlinedButton.icon(
                onPressed: () => onOpenHistory(item),
                icon: const Icon(Icons.timeline_outlined, size: 18),
                label: const Text('فتح التاريخ'),
              ),
              OutlinedButton.icon(
                onPressed: () => onOpenWaqf(item),
                icon: const Icon(Icons.account_balance_outlined, size: 18),
                label: const Text('تفاصيل الوقف'),
              ),
              OutlinedButton.icon(
                onPressed: () => onOpenAudit(item),
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('لوحة التدقيق'),
              ),
              FilledButton.icon(
                onPressed: () => onGenerateHypothesis(item),
                icon: const Icon(Icons.lightbulb_outline, size: 18),
                label: const Text('فرضية محلية'),
              ),
              FilledButton.icon(
                onPressed: item.needsReview ? () => onCreateAuditRequest(item) : null,
                icon: const Icon(Icons.add_task_outlined, size: 18),
                label: const Text('طلب تدقيق'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionTitle(
            icon: Icons.rule_folder_outlined,
            title: 'إشارات الفجوات',
          ),
          const SizedBox(height: 8),
          if (item.gapSignals.isEmpty)
            const Text(
              'لا توجد فجوات ظاهرة ضمن القواعد الحالية.',
              style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.w800),
            )
          else
            ...item.gapSignals.map((signal) => _SignalTile(signal: signal)),
          const SizedBox(height: 16),
          const _SectionTitle(
            icon: Icons.psychology_outlined,
            title: 'الفرضيات المقترحة',
          ),
          const SizedBox(height: 8),
          if (item.hypotheses.isEmpty && generatedHypothesis == null)
            const Text(
              'لا توجد فرضيات حالية. يمكن إنشاء فرضية محلية من الأزرار أعلاه.',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
            )
          else ...[
            ...item.hypotheses.map((hypothesis) => _HypothesisCard(hypothesis: hypothesis)),
            if (generatedHypothesis != null)
              _HypothesisCard(hypothesis: generatedHypothesis!),
          ],
        ],
      ),
    );
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({required this.signal});

  final SmartExplorerGapSignal signal;

  @override
  Widget build(BuildContext context) {
    final color = signal.color(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(signal.icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${signal.titleAr} • ${signal.severityLabelAr}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  signal.descriptionAr,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  signal.recommendedActionAr,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HypothesisCard extends StatelessWidget {
  const _HypothesisCard({required this.hypothesis});

  final SmartExplorerHypothesis hypothesis;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1D4ED8).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1D4ED8).withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${hypothesis.titleAr} • ${hypothesis.intentLabelAr}',
            style: const TextStyle(
              color: Color(0xFF1D4ED8),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hypothesis.summaryAr,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: 'ثقة ${hypothesis.confidencePercent}%',
                icon: Icons.speed_outlined,
              ),
              _InfoChip(
                label: hypothesis.statusLabelAr,
                icon: Icons.assignment_late_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldChecklistView extends StatelessWidget {
  const _FieldChecklistView({
    required this.checklist,
    required this.onClear,
  });

  final SmartExplorerFieldChecklist checklist;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF047857).withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              _SectionTitle(
                icon: Icons.checklist_rtl_outlined,
                title: checklist.summaryAr,
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('إخفاء'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (checklist.isEmpty)
            const Text(
              'لا توجد بنود تدقيق ميداني ضمن النطاق الحالي.',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: checklist.topItems.map((item) {
                final color = item.isUrgent
                    ? PwfColors.royalRed
                    : item.priority >= 70
                        ? const Color(0xFFC77700)
                        : const Color(0xFF047857);
                return Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.16)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _InfoChip(
                            label: item.priorityLabelAr,
                            icon: Icons.priority_high_outlined,
                            color: color,
                          ),
                          _InfoChip(
                            label: item.domainAr,
                            icon: Icons.category_outlined,
                          ),
                          if (item.requiresPhoto)
                            const _InfoChip(
                              label: 'صورة/دليل ميداني',
                              icon: Icons.photo_camera_outlined,
                              color: Color(0xFF0F766E),
                            ),
                          if (item.requiresDocumentReview)
                            const _InfoChip(
                              label: 'مراجعة وثائق',
                              icon: Icons.description_outlined,
                              color: Color(0xFF7C3AED),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.titleAr,
                        style: TextStyle(color: color, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.instructionAr,
                        style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الدليل المطلوب: ${item.evidenceRequiredAr}',
                        style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'النطاق: ${item.locationLabelAr}',
                        style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _RiskRegisterView extends StatelessWidget {
  const _RiskRegisterView({
    required this.register,
    required this.onClear,
  });

  final SmartExplorerRiskRegister register;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PwfColors.royalRed.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              _SectionTitle(
                icon: Icons.warning_amber_outlined,
                title: register.summaryAr,
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('إخفاء'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (register.isEmpty)
            const Text(
              'لا توجد مخاطر تشغيلية ظاهرة ضمن النطاق الحالي.',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800),
            )
          else
            ...register.topRisks.map((risk) {
              final color = risk.score >= 20
                  ? PwfColors.royalRed
                  : risk.score >= 12
                      ? const Color(0xFFC77700)
                      : PwfColors.primaryBlue;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _InfoChip(
                          label: risk.scoreLabelAr,
                          icon: Icons.speed_outlined,
                          color: color,
                        ),
                        _InfoChip(
                          label: risk.domainAr,
                          icon: Icons.category_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(risk.titleAr, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(risk.descriptionAr, style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('التخفيف: ${risk.mitigationAr}', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _QaScenariosView extends StatelessWidget {
  const _QaScenariosView({
    required this.scenarios,
    required this.onClear,
  });

  final List<SmartExplorerQaScenario> scenarios;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              _SectionTitle(
                icon: Icons.bug_report_outlined,
                title: 'سيناريوهات اختبار المستكشف الذكي (${scenarios.length})',
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('إخفاء'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...scenarios.map((scenario) {
            final color = scenario.priority >= 85
                ? PwfColors.royalRed
                : scenario.priority >= 70
                    ? const Color(0xFFC77700)
                    : PwfColors.primaryBlue;
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _InfoChip(label: scenario.priorityLabelAr, icon: Icons.priority_high_outlined, color: color),
                      _InfoChip(label: scenario.domainAr, icon: Icons.category_outlined),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(scenario.titleAr, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  ...scenario.testSteps.take(5).map((step) => Text('• $step', style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700))),
                  const SizedBox(height: 4),
                  Text('المتوقع: ${scenario.expectedEvidenceAr}', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
                  Text('إشارة الفشل: ${scenario.failureSignalAr}', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}


class _RecentAuditRequestsPanel extends StatelessWidget {
  const _RecentAuditRequestsPanel({
    required this.state,
    required this.onRefresh,
    required this.onOpenAuditDashboard,
  });

  final SmartExplorerState state;
  final VoidCallback onRefresh;
  final VoidCallback onOpenAuditDashboard;

  @override
  Widget build(BuildContext context) {
    final requests = state.recentAuditRequests;

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fact_check_outlined, color: PwfColors.primaryBlue),
                  const SizedBox(width: 8),
                  const Text(
                    'آخر طلبات تدقيق المستكشف',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    label: '${state.openAuditRequests} مفتوحة',
                    icon: Icons.pending_actions_outlined,
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: state.isLoadingAuditRequests ? null : onRefresh,
                    icon: state.isLoadingAuditRequests
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    label: const Text('تحديث'),
                  ),
                  TextButton.icon(
                    onPressed: onOpenAuditDashboard,
                    icon: const Icon(Icons.open_in_new_outlined, size: 18),
                    label: const Text('فتح اللوحة'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (requests.isEmpty && !state.isLoadingAuditRequests)
            const Text(
              'لا توجد طلبات تدقيق حديثة ظاهرة حاليًا.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: requests
                  .take(8)
                  .map((request) => _AuditRequestChip(request: request))
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _AuditRequestChip extends StatelessWidget {
  const _AuditRequestChip({required this.request});

  final ExplorerGapAuditRequest request;

  @override
  Widget build(BuildContext context) {
    final danger = request.severity == 'critical' || request.severity == 'high';
    final color = danger ? PwfColors.royalRed : PwfColors.primaryBlue;
    final title = request.title.trim().isEmpty ? 'طلب تدقيق' : request.title;

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt_outlined, size: 16, color: color),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              '$title — ${request.displayStatus}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportPanel extends StatelessWidget {
  const _ReportPanel({
    required this.reportText,
    required this.onCopy,
    required this.onClose,
  });

  final String reportText;
  final VoidCallback onCopy;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              const _SectionTitle(
                icon: Icons.description_outlined,
                title: 'تقرير النطاق الحالي',
              ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('نسخ'),
                  ),
                  TextButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('إغلاق'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 260),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                reportText,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontWeight: FontWeight.w600,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPanel extends StatelessWidget {
  const _IntroPanel();

  @override
  Widget build(BuildContext context) {
    return const _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.tips_and_updates_outlined,
            title: 'ابدأ البحث الذكي',
          ),
          SizedBox(height: 8),
          Text(
            'اكتب اسم أصل وقفي، رمزًا وطنيًا، اسم وقف أم، تجمعًا أو إشارة مكانية. سيولّد النظام إشارات فجوات وفرضيات مراجعة غير سيادية قابلة للتحويل إلى طلبات تدقيق.',
            style: TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) {
    return const _PanelCard(
      child: Text(
        'لا توجد نتائج. جرّب رمزًا وطنيًا، اسم الوقف، اسم الأصل، أو التجمع.',
        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: PwfColors.primaryBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.icon,
    this.color = PwfColors.primaryBlue,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner._({
    required this.message,
    required this.icon,
    required this.color,
  });

  factory _Banner.success(String message) {
    return _Banner._(
      message: message,
      icon: Icons.check_circle_outline,
      color: const Color(0xFF047857),
    );
  }

  factory _Banner.error(String message) {
    return _Banner._(
      message: message,
      icon: Icons.error_outline,
      color: PwfColors.royalRed,
    );
  }

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

Color _severityColor(SmartExplorerSignalSeverity? severity) {
  switch (severity) {
    case SmartExplorerSignalSeverity.critical:
      return PwfColors.royalRed;
    case SmartExplorerSignalSeverity.high:
      return const Color(0xFFC77700);
    case SmartExplorerSignalSeverity.medium:
      return const Color(0xFF1D4ED8);
    case SmartExplorerSignalSeverity.low:
      return const Color(0xFF047857);
    case null:
      return const Color(0xFF64748B);
  }
}

Color _confidenceColor(int score) {
  if (score >= 85) return const Color(0xFF047857);
  if (score >= 65) return const Color(0xFF1D4ED8);
  if (score >= 40) return const Color(0xFFC77700);
  return PwfColors.royalRed;
}

class _SmartExplorerServiceOrientationPanel extends StatelessWidget {
  const _SmartExplorerServiceOrientationPanel({
    required this.onOpenServices,
    required this.onOpenMap,
    required this.onOpenReview,
  });

  final VoidCallback onOpenServices;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PwfColors.primaryGold.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: PwfColors.primaryGold.withValues(alpha: 0.14),
                child: const Icon(Icons.account_tree_outlined, color: PwfColors.primaryGold),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'المستكشف الذكي ضمن مركز خدمات المستكشف',
                  style: TextStyle(fontWeight: FontWeight.w900, color: PwfColors.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'هذه الصفحة مخصصة للتحليل الذكي فقط. ابدأ من مركز الخدمات إذا كنت لا تعرف الأداة المناسبة؛ فهو يرتب البحث، قراءة الخريطة، التحقق المكاني، ذكاء الوثائق، والمراجعة حسب المهمة والنتيجة المتوقعة.',
            style: TextStyle(color: Color(0xFF475569), height: 1.55, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onOpenServices,
                icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
                label: const Text('مركز الخدمات'),
                style: FilledButton.styleFrom(
                  backgroundColor: PwfColors.primaryGold,
                  foregroundColor: const Color(0xFF111827),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onOpenMap,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('خريطة العمل'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenReview,
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('لوحة المراجعة'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
