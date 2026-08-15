import 'package:flutter/material.dart';

import '../../../history_explorer/data/repositories/waqf_asset_repository_impl.dart';
import '../../../history_explorer/domain/models/waqf_asset_model.dart';
import '../../../map/data/repositories/map_feedback_repository.dart';
import '../../domain/models/smart_explorer_decision_board.dart';
import '../../domain/models/smart_explorer_document_analysis.dart';
import '../../domain/models/smart_explorer_evidence_matrix.dart';
import '../../domain/models/smart_explorer_field_checklist.dart';
import '../../domain/models/smart_explorer_gazetteer_entry.dart';
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
import '../../domain/models/smart_explorer_current_baseline_guard.dart';
import '../../domain/models/smart_explorer_self_development_pack.dart';
import '../../domain/models/smart_explorer_local_analyzer_contract.dart';
import '../../domain/models/smart_explorer_autonomous_qa_pack.dart';
import '../../domain/models/smart_explorer_operational_stage_pack.dart';
import '../../domain/models/smart_explorer_runtime_wiring_stage_pack.dart';
import '../../domain/models/smart_explorer_integrated_final_stage_pack.dart';
import '../../domain/models/smart_explorer_post_qz_operational_closure_pack.dart';
import '../../domain/models/smart_explorer_ai_document_intelligence_stage_pack.dart';
import '../../domain/models/smart_explorer_spatial_verification_stage_pack.dart';

/// Read-only orchestration repository for Smart Explorer.
///
/// This repository reuses the existing waqf asset repository. It generates
/// local audit signals only and does not write to sovereign tables. The only
/// persisted operation remains creating an explorer gap audit request through
/// the already-approved GIS feedback/audit RPC path.
class SmartExplorerRepository {
  SmartExplorerRepository({
    required WaqfAssetRepositoryImpl waqfAssetRepository,
    required MapFeedbackRepository mapFeedbackRepository,
  })  : _waqfAssetRepository = waqfAssetRepository,
        _mapFeedbackRepository = mapFeedbackRepository;

  final WaqfAssetRepositoryImpl _waqfAssetRepository;
  final MapFeedbackRepository _mapFeedbackRepository;

  Future<List<ExplorerGapAuditRequest>> listRecentAuditRequests({
    int limit = 8,
  }) {
    return _mapFeedbackRepository.listExplorerGapAuditRequests(
      status: null,
      domain: null,
      limit: limit,
      offset: 0,
    );
  }

  Future<ExplorerGapAuditRequest> createAuditRequestFromResult(
    SmartExplorerResult result, {
    String? reporterNote,
  }) {
    final primarySeverity = _primarySeverity(result);
    final sample = result.evidenceLines.take(16).toList(growable: true);

    return _mapFeedbackRepository.createExplorerGapAuditRequest(
      ExplorerGapAuditSubmission(
        domain: 'smart_explorer',
        severity: primarySeverity,
        title: 'تدقيق ذكي: ${result.titleAr}',
        detail: _auditDetail(result),
        recommendedAction: result.recommendedActionAr,
        sample: sample,
        explorerMode: 'smart_explorer',
        priority: _priorityForSeverity(primarySeverity),
        reporterNote: reporterNote,
        context: <String, dynamic>{
          'source': 'smart_explorer_big_batch_b',
          'asset_id': result.id,
          'asset_code': result.assetCode,
          'asset_title': result.titleAr,
          'endowment_name': result.endowmentName,
          'governorate': result.governorate,
          'community': result.community,
          'lgu': result.lgu,
          'confidence_score': result.confidenceScore,
          'review_score': result.reviewScore,
          'review_priority': result.reviewPriorityLabelAr,
          'top_severity': result.topSeverityLabelAr,
          'gap_codes': result.gapSignals.map((signal) => signal.code).toList(),
          'gap_severities': result.gapSignals
              .map((signal) => signal.severityCode)
              .toList(growable: false),
          'hypothesis_intents': result.hypotheses
              .map((hypothesis) => hypothesis.intentLabelAr)
              .toList(growable: false),
          'has_geometry': result.hasGeometry,
          'has_center': result.hasCenter,
          'has_centroid': result.hasCentroid,
          'linked_parcels_count': result.linkedParcelsCount,
        },
      ),
    );
  }

  Future<List<ExplorerGapAuditRequest>> createAuditRequestsFromResults(
    List<SmartExplorerResult> results, {
    int limit = 5,
  }) async {
    final queue = results
        .where((item) => item.needsReview)
        .toList(growable: false)
      ..sort((a, b) => b.reviewScore.compareTo(a.reviewScore));

    final created = <ExplorerGapAuditRequest>[];
    for (final result in queue.take(limit)) {
      final request = await createAuditRequestFromResult(
        result,
        reporterNote: 'إنشاء جماعي من المستكشف الذكي حسب أولوية المراجعة.',
      );
      created.add(request);
    }
    return created;
  }

  Future<List<SmartExplorerResult>> search({
    required String query,
    int limit = 60,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const <SmartExplorerResult>[];

    final assets = await _waqfAssetRepository.searchByNameOrNationalCode(
      query: trimmedQuery,
      limit: limit,
    );

    final results = assets.map(_fromAsset).toList(growable: true);
    return results;
  }

  SmartExplorerDocumentAnalysis analyzeDocumentText(String text) {
    final original = text.trim();
    final normalized = _normalizeDocumentText(original);
    if (normalized.isEmpty) {
      return SmartExplorerDocumentAnalysis(
        originalText: original,
        normalizedText: normalized,
        entities: const <SmartExplorerDocumentEntity>[],
        boundaryClues: const <String>[],
        directionClues: const <String>[],
        timeClues: const <String>[],
        spatialHypotheses: const <String>[],
        confidence: 0,
        createdAt: DateTime.now(),
      );
    }

    final entities = <SmartExplorerDocumentEntity>[];
    entities.addAll(_extractEntities(
      normalized,
      RegExp(r'(?:وقف|أوقاف)\s+([^\n،.;]{2,48})'),
      SmartExplorerDocumentEntityType.waqf,
      'ذكر وقف/أوقاف في النص',
      0.82,
    ));
    entities.addAll(_extractEntities(
      normalized,
      RegExp(r'(?:قرية|مدينة|بلدة|خربة|أراضي|ظاهر)\s+([^\n،.;]{2,42})'),
      SmartExplorerDocumentEntityType.place,
      'ذكر موقع أو نطاق إداري/تاريخي',
      0.74,
    ));
    entities.addAll(_extractEntities(
      normalized,
      RegExp(r'(?:حوض|الحوض|قطعة|القطعة|رقم)\s*([0-9٠-٩A-Za-zأ-ي\-/ ]{1,28})'),
      SmartExplorerDocumentEntityType.parcel,
      'ذكر حوض/قطعة/رقم مرجعي',
      0.70,
    ));
    entities.addAll(_extractEntities(
      normalized,
      RegExp(r'(?:طريق|وادي|عين|بئر|جبل|مقام|مسجد|مقبرة)\s+([^\n،.;]{2,42})'),
      SmartExplorerDocumentEntityType.landmark,
      'ذكر معلم وصفي أو طبيعي',
      0.64,
    ));

    final boundaryClues = _extractBoundaryClues(normalized);
    final directionClues = _extractDirectionClues(normalized);
    final timeClues = _extractTimeClues(normalized);
    final uniqueEntities = _dedupeEntities(entities);
    final hypotheses = _buildDocumentSpatialHypotheses(
      entities: uniqueEntities,
      boundaryClues: boundaryClues,
      directionClues: directionClues,
      timeClues: timeClues,
    );

    final confidence = _documentConfidence(
      entityCount: uniqueEntities.length,
      boundaryCount: boundaryClues.length,
      directionCount: directionClues.length,
      timeCount: timeClues.length,
    );

    return SmartExplorerDocumentAnalysis(
      originalText: original,
      normalizedText: normalized,
      entities: uniqueEntities,
      boundaryClues: boundaryClues,
      directionClues: directionClues,
      timeClues: timeClues,
      spatialHypotheses: hypotheses,
      confidence: confidence,
      createdAt: DateTime.now(),
    );
  }

  SmartExplorerRoutePlan buildRoutePlan(
    List<SmartExplorerResult> results, {
    int limit = 12,
  }) {
    final queue = results
        .where((item) => item.needsReview)
        .toList(growable: false)
      ..sort((a, b) {
        final gov = a.governorate.compareTo(b.governorate);
        if (gov != 0) return gov;
        final community = a.community.compareTo(b.community);
        if (community != 0) return community;
        return b.reviewScore.compareTo(a.reviewScore);
      });

    final stops = <SmartExplorerRouteStop>[];
    var order = 1;
    for (final result in queue.take(limit)) {
      stops.add(SmartExplorerRouteStop.fromResult(order: order, result: result));
      order++;
    }

    return SmartExplorerRoutePlan(
      stops: stops,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'نتائج البحث/الفلاتر الحالية',
    );
  }

  String buildInvestigationReport({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerRoutePlan? routePlan,
    List<SmartExplorerGazetteerEntry>? gazetteerEntries,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    List<SmartExplorerReadinessAssessment>? readinessAssessments,
  }) {
    final buffer = StringBuffer()
      ..writeln('تقرير تحقيق مكاني/تاريخي — المستكشف الذكي')
      ..writeln('تاريخ التوليد: ${DateTime.now().toIso8601String()}')
      ..writeln('هذه مخرجات تحليل غير سيادية تحتاج مراجعة واعتمادًا بشريًا.')
      ..writeln('---')
      ..writeln('أولًا: ملخص نتائج الأصول')
      ..writeln('عدد النتائج ضمن النطاق: ${results.length}')
      ..writeln('نتائج تحتاج مراجعة: ${results.where((item) => item.needsReview).length}')
      ..writeln('بلا تمثيل مكاني: ${results.where((item) => !item.hasAnySpatialReference).length}')
      ..writeln('بلا قطع مرتبطة: ${results.where((item) => !item.hasLinkedParcels).length}')
      ..writeln('---');

    if (documentAnalysis != null) {
      buffer
        ..writeln('ثانيًا: تحليل الوثيقة/النص')
        ..writeln(documentAnalysis.summaryAr)
        ..writeln('المسميات/الكيانات:');
      for (final entity in documentAnalysis.entities.take(20)) {
        buffer.writeln(
          '- ${entity.value} [${entity.typeLabelAr}] — ثقة ${entity.scorePercent}%',
        );
      }
      if (documentAnalysis.boundaryClues.isNotEmpty) {
        buffer.writeln('قرائن الحدود:');
        for (final clue in documentAnalysis.boundaryClues.take(12)) {
          buffer.writeln('- $clue');
        }
      }
      if (documentAnalysis.spatialHypotheses.isNotEmpty) {
        buffer.writeln('فرضيات مكانية نصية:');
        for (final item in documentAnalysis.spatialHypotheses.take(10)) {
          buffer.writeln('- $item');
        }
      }
      buffer.writeln('---');
    }

    if (gazetteerEntries != null && gazetteerEntries.isNotEmpty) {
      buffer
        ..writeln('ثالثًا: قاموس المسميات المسودة')
        ..writeln('عدد المداخل: ${gazetteerEntries.length}');
      for (final entry in gazetteerEntries.take(20)) {
        buffer.writeln(
          '- ${entry.value} [${entry.typeLabelAr}] — ثقة ${entry.confidencePercent}% — ${entry.sourceLabelAr}',
        );
      }
      buffer.writeln('---');
    }

    if (evidenceMatrix != null && evidenceMatrix.hasLinks) {
      buffer
        ..writeln('رابعًا: مصفوفة الأدلة')
        ..writeln(evidenceMatrix.summaryAr);
      for (final link in evidenceMatrix.topLinks.take(10)) {
        buffer.writeln(
          '- ${link.entityValue} ↔ ${link.resultTitleAr} — ${link.matchScore}% — ${link.recommendationAr}',
        );
      }
      buffer.writeln('---');
    }

    if (readinessAssessments != null && readinessAssessments.isNotEmpty) {
      buffer
        ..writeln('خامسًا: تقييم الجاهزية')
        ..writeln('أقل النتائج جاهزية:');
      for (final item in readinessAssessments.take(10)) {
        buffer.writeln(
          '- ${item.titleAr} — ${item.overallScore}% — ${item.readinessLabelAr}',
        );
        if (item.blockers.isNotEmpty) {
          buffer.writeln('  عوائق: ${item.blockers.take(3).join(' / ')}');
        }
      }
      buffer.writeln('---');
    }

    if (routePlan != null && routePlan.stops.isNotEmpty) {
      buffer
        ..writeln('مسار تدقيق ميداني مقترح')
        ..writeln(routePlan.summaryAr);
      for (final stop in routePlan.stops) {
        buffer.writeln(
          '${stop.order}. ${stop.titleAr} — ${stop.locationLabelAr} — ${stop.priorityLabelAr}',
        );
        buffer.writeln('   السبب: ${stop.reasonAr}');
      }
      buffer.writeln('---');
    }

    buffer.writeln('توصية ختامية');
    if (results.any((item) => !item.hasAnySpatialReference && !item.hasLinkedParcels)) {
      buffer.writeln('الأولوية لطلبات التدقيق ذات الفجوات المكانية والقطعية المركبة.');
    } else if (results.any((item) => item.needsReview)) {
      buffer.writeln('يوصى بمراجعة الفجوات عالية/متوسطة الشدة قبل أي اعتماد تشغيلي.');
    } else {
      buffer.writeln('لا تظهر فجوات حرجة ضمن قواعد الفحص الحالية، مع بقاء الاعتماد البشري مطلوبًا.');
    }

    return buffer.toString();
  }

  List<SmartExplorerGazetteerEntry> buildGazetteerDraft({
    SmartExplorerDocumentAnalysis? documentAnalysis,
    required List<SmartExplorerResult> results,
    int limit = 40,
  }) {
    final entries = <SmartExplorerGazetteerEntry>[];
    if (documentAnalysis != null) {
      entries.addAll(
        documentAnalysis.entities.map(SmartExplorerGazetteerEntry.fromEntity),
      );
    }
    entries.addAll(
      results.take(20).map(SmartExplorerGazetteerEntry.fromResult),
    );

    final seen = <String>{};
    final unique = <SmartExplorerGazetteerEntry>[];
    for (final entry in entries) {
      final key = '${entry.typeLabelAr}:${entry.normalizedValue}';
      if (entry.normalizedValue.length < 2) continue;
      if (seen.add(key)) unique.add(entry);
      if (unique.length >= limit) break;
    }

    unique.sort((a, b) => b.confidencePercent.compareTo(a.confidencePercent));
    return unique;
  }

  SmartExplorerEvidenceMatrix buildEvidenceMatrix({
    required SmartExplorerDocumentAnalysis? documentAnalysis,
    required List<SmartExplorerResult> results,
  }) {
    final analysis = documentAnalysis;
    if (analysis == null || analysis.entities.isEmpty || results.isEmpty) {
      return SmartExplorerEvidenceMatrix(
        links: const <SmartExplorerEvidenceLink>[],
        generatedAt: DateTime.now(),
      );
    }

    final links = <SmartExplorerEvidenceLink>[];
    for (final entity in analysis.entities) {
      final needle = SmartExplorerGazetteerEntry.normalize(entity.value);
      if (needle.length < 2) continue;
      for (final result in results.take(80)) {
        final matchedFields = <String>[];
        final conflicts = <String>[];
        var score = 0;

        void testField(String label, String value, int weight) {
          final normalized = SmartExplorerGazetteerEntry.normalize(value);
          if (normalized.isEmpty) return;
          if (normalized.contains(needle) || needle.contains(normalized)) {
            score += weight;
            matchedFields.add(label);
          }
        }

        testField('اسم الأصل', result.titleAr, 38);
        testField('الوقف الأم', result.endowmentName, 34);
        testField('المحافظة', result.governorate, 18);
        testField('التجمع', result.community, 26);
        testField('الهيئة المحلية', result.lgu, 20);
        testField('نوع الأصل', result.assetType, 10);
        testField('الرمز الوطني', result.assetCode, 22);

        if (entity.type == SmartExplorerDocumentEntityType.parcel &&
            !result.hasLinkedParcels) {
          conflicts.add('الوثيقة تذكر حوض/قطعة لكن النتيجة بلا قطع مرتبطة.');
          score -= 12;
        }
        if ((entity.type == SmartExplorerDocumentEntityType.place ||
                entity.type == SmartExplorerDocumentEntityType.landmark) &&
            !result.hasAnySpatialReference) {
          conflicts.add('القرينة مكانية لكن النتيجة بلا تمثيل مكاني ظاهر.');
          score -= 10;
        }
        if (entity.type == SmartExplorerDocumentEntityType.waqf &&
            result.endowmentName.trim().isEmpty) {
          conflicts.add('الوثيقة تذكر وقفًا لكن النتيجة بلا وقف أم ظاهر.');
          score -= 10;
        }

        final boundedScore = score.clamp(0, 100).toInt();
        if (boundedScore == 0 && conflicts.isEmpty) continue;
        links.add(SmartExplorerEvidenceLink(
          entityValue: entity.value,
          entityTypeLabelAr: entity.typeLabelAr,
          resultId: result.id,
          resultTitleAr: result.titleAr,
          assetCode: result.assetCode,
          matchScore: boundedScore,
          matchedFields: matchedFields,
          conflicts: conflicts,
          recommendationAr: _evidenceRecommendation(
            boundedScore: boundedScore,
            conflicts: conflicts,
            result: result,
          ),
        ));
      }
    }

    links.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return SmartExplorerEvidenceMatrix(
      links: links.take(60).toList(growable: false),
      generatedAt: DateTime.now(),
    );
  }

  List<SmartExplorerReadinessAssessment> assessReadiness(
    List<SmartExplorerResult> results, {
    int limit = 40,
  }) {
    final assessments = results
        .take(limit)
        .map(SmartExplorerReadinessAssessment.fromResult)
        .toList(growable: true);
    assessments.sort((a, b) => a.overallScore.compareTo(b.overallScore));
    return assessments;
  }

  String buildReviewQueueCsv(List<SmartExplorerResult> results) {
    final buffer = StringBuffer()
      ..writeln('asset_id,asset_code,title,governorate,community,lgu,confidence,review_score,priority,top_severity,recommended_action');
    for (final result in results.where((item) => item.needsReview)) {
      buffer.writeln([
        _csv(result.id),
        _csv(result.assetCode),
        _csv(result.titleAr),
        _csv(result.governorate),
        _csv(result.community),
        _csv(result.lgu),
        result.confidenceScore,
        result.reviewScore,
        _csv(result.reviewPriorityLabelAr),
        _csv(result.topSeverityLabelAr),
        _csv(result.recommendedActionAr),
      ].join(','));
    }
    return buffer.toString();
  }

  String buildGazetteerCsv(List<SmartExplorerGazetteerEntry> entries) {
    final buffer = StringBuffer()
      ..writeln('value,normalized,type,source,confidence,suggested_query,notes');
    for (final entry in entries) {
      buffer.writeln([
        _csv(entry.value),
        _csv(entry.normalizedValue),
        _csv(entry.typeLabelAr),
        _csv(entry.sourceLabelAr),
        entry.confidencePercent,
        _csv(entry.suggestedQuery),
        _csv(entry.notesAr),
      ].join(','));
    }
    return buffer.toString();
  }

  String buildTextReport(List<SmartExplorerResult> results) {
    if (results.isEmpty) {
      return 'تقرير المستكشف الذكي\nلا توجد نتائج ضمن النطاق الحالي.';
    }

    final totalSignals = results.fold<int>(
      0,
      (sum, item) => sum + item.gapSignals.length,
    );
    final highOrCritical = results.where((item) {
      return item.hasSeverity(SmartExplorerSignalSeverity.critical) ||
          item.hasSeverity(SmartExplorerSignalSeverity.high);
    }).length;
    final withoutSpatial =
        results.where((item) => !item.hasAnySpatialReference).length;
    final withoutParcels = results.where((item) => !item.hasLinkedParcels).length;

    final buffer = StringBuffer()
      ..writeln('تقرير المستكشف الذكي للأوقاف والتاريخ المكاني')
      ..writeln('النطاق: نتائج البحث/الفلاتر الحالية')
      ..writeln('عدد النتائج: ${results.length}')
      ..writeln('إشارات الفجوات: $totalSignals')
      ..writeln('نتائج عالية/حرجة: $highOrCritical')
      ..writeln('بلا تمثيل مكاني: $withoutSpatial')
      ..writeln('بلا قطع مرتبطة: $withoutParcels')
      ..writeln('---');

    for (final result in results.take(25)) {
      buffer
        ..writeln(result.compactAuditSummary)
        ..writeln('---');
    }

    if (results.length > 25) {
      buffer.writeln('تم اختصار التقرير إلى أول 25 نتيجة.');
    }
    return buffer.toString();
  }

  SmartExplorerResult _fromAsset(WaqfAssetModel asset) {
    final linkedParcelsCount = asset.linkedParcelsCount ?? asset.parcelIds.length;
    final subtitle = <String>[
      _text(asset.assetType),
      _text(asset.communityName),
      _text(asset.currentGovernorate),
    ].where((item) => item.isNotEmpty).join(' • ');

    final draft = SmartExplorerResult(
      id: _text(asset.waqfAssetId).isNotEmpty
          ? _text(asset.waqfAssetId)
          : _text(asset.nationalAssetCode),
      titleAr: _text(asset.displayLabel).isNotEmpty
          ? _text(asset.displayLabel)
          : 'أصل وقفي غير مسمى',
      subtitleAr: subtitle,
      assetCode: _text(asset.nationalAssetCode),
      endowmentName: _text(asset.endowmentName),
      governorate: _text(asset.currentGovernorate),
      community: _text(asset.communityName),
      lgu: _text(asset.currentLgu),
      assetType: _text(asset.assetType),
      status: _text(asset.status),
      usage: _text(asset.usage),
      hasGeometry: asset.hasGeometry,
      hasCenter: asset.hasCenter,
      hasCentroid: asset.hasCentroid,
      linkedParcelsCount: linkedParcelsCount,
      gapSignals: const <SmartExplorerGapSignal>[],
      hypotheses: const <SmartExplorerHypothesis>[],
      raw: asset,
    );

    final signals = _buildSignals(draft);
    final hypotheses = _buildRuleHypotheses(draft, signals);
    return draft.copyWith(gapSignals: signals, hypotheses: hypotheses);
  }

  List<SmartExplorerGapSignal> _buildSignals(SmartExplorerResult result) {
    final signals = <SmartExplorerGapSignal>[];

    if (result.assetCode.trim().isEmpty) {
      signals.add(const SmartExplorerGapSignal(
        code: 'missing_national_asset_code',
        titleAr: 'الرمز الوطني غير ظاهر',
        descriptionAr:
            'لا يظهر رمز وطني للأصل في نتيجة البحث، وهذا يضعف الربط والطباعة والبحث.',
        severity: SmartExplorerSignalSeverity.high,
        recommendedActionAr:
            'مراجعة مصدر awqaf_system لأن إصدار الرمز الوطني ليس من صلاحية المستكشف.',
        icon: Icons.qr_code_2_outlined,
        weight: 3,
      ));
    }

    if (!result.hasAnySpatialReference) {
      signals.add(const SmartExplorerGapSignal(
        code: 'missing_spatial_reference',
        titleAr: 'الأصل بلا تمثيل مكاني',
        descriptionAr:
            'لا توجد هندسة أو مركز أو centroid ظاهر في نتيجة البحث الحالية.',
        severity: SmartExplorerSignalSeverity.critical,
        recommendedActionAr:
            'إنشاء طلب تدقيق مكاني وربطه بقطعة أو نقطة مرجعية.',
        icon: Icons.location_off_outlined,
        weight: 5,
      ));
    } else if (!result.hasGeometry && (result.hasCenter || result.hasCentroid)) {
      signals.add(const SmartExplorerGapSignal(
        code: 'point_only_asset',
        titleAr: 'تمثيل نقطي فقط',
        descriptionAr:
            'يوجد مركز/centroid لكن لا توجد هندسة أصل أو قطعة مرتبطة في النتيجة.',
        severity: SmartExplorerSignalSeverity.medium,
        recommendedActionAr:
            'مراجعة الربط مع قطع التسوية أو طبقة الأصل الوقفي.',
        icon: Icons.add_location_alt_outlined,
        weight: 2,
      ));
    }

    if (!result.hasLinkedParcels) {
      signals.add(const SmartExplorerGapSignal(
        code: 'missing_linked_parcels',
        titleAr: 'لا توجد قطع مرتبطة',
        descriptionAr: 'عدد القطع المرتبطة يساوي صفرًا أو غير ظاهر في النتيجة.',
        severity: SmartExplorerSignalSeverity.high,
        recommendedActionAr: 'البحث عن مطابقة محتملة في طبقات التسوية/الأحواض.',
        icon: Icons.grid_4x4_outlined,
        weight: 4,
      ));
    }

    if (!result.hasAnySpatialReference && !result.hasLinkedParcels) {
      signals.add(const SmartExplorerGapSignal(
        code: 'weak_location_and_parcel_context',
        titleAr: 'فجوة مكانية ومِلْكية مركبة',
        descriptionAr:
            'الأصل بلا تمثيل مكاني وبلا قطع مرتبطة، لذلك يحتاج مسار تدقيق أولوية.',
        severity: SmartExplorerSignalSeverity.critical,
        recommendedActionAr:
            'فتح طلب تدقيق عاجل قبل أي عرض عام أو اعتماد تحليلي للأصل.',
        icon: Icons.warning_amber_rounded,
        weight: 5,
      ));
    }

    if (result.governorate.trim().isEmpty) {
      signals.add(const SmartExplorerGapSignal(
        code: 'missing_governorate',
        titleAr: 'المحافظة غير مكتملة',
        descriptionAr: 'لا تظهر محافظة حديثة مرتبطة بالأصل في نتيجة البحث.',
        severity: SmartExplorerSignalSeverity.medium,
        recommendedActionAr: 'استكمال السياق الإداري من core قبل اعتماد النتيجة.',
        icon: Icons.map_outlined,
        weight: 2,
      ));
    }

    if (result.community.trim().isEmpty) {
      signals.add(const SmartExplorerGapSignal(
        code: 'missing_community',
        titleAr: 'التجمع غير مكتمل',
        descriptionAr: 'لا يظهر تجمع حديث مرتبط بالأصل في نتيجة البحث.',
        severity: SmartExplorerSignalSeverity.medium,
        recommendedActionAr: 'استكمال السياق الإداري قبل الاعتماد.',
        icon: Icons.account_tree_outlined,
        weight: 2,
      ));
    }

    if (result.lgu.trim().isEmpty) {
      signals.add(const SmartExplorerGapSignal(
        code: 'missing_lgu',
        titleAr: 'الهيئة المحلية غير مكتملة',
        descriptionAr: 'لا تظهر هيئة محلية حديثة مرتبطة بالأصل.',
        severity: SmartExplorerSignalSeverity.low,
        recommendedActionAr: 'استكمال الربط الإداري الحديث عند توفر المرجع.',
        icon: Icons.apartment_outlined,
        weight: 1,
      ));
    }

    if (result.endowmentName.trim().isEmpty) {
      signals.add(const SmartExplorerGapSignal(
        code: 'missing_reference_endowment',
        titleAr: 'الوقف الأم غير ظاهر',
        descriptionAr:
            'لا يظهر اسم الوقف المرجعي/الأم في نتيجة البحث الحالية.',
        severity: SmartExplorerSignalSeverity.high,
        recommendedActionAr:
            'مراجعة الربط بين الأصل الوقفي والوقف المرجعي داخل awqaf_system.',
        icon: Icons.account_balance_outlined,
        weight: 4,
      ));
    }

    if (result.assetType.trim().isEmpty || _looksUnknown(result.assetType)) {
      signals.add(const SmartExplorerGapSignal(
        code: 'missing_asset_type',
        titleAr: 'نوع الأصل غير واضح',
        descriptionAr: 'نوع الأصل الوقفي غير ظاهر أو يبدو غير محدد.',
        severity: SmartExplorerSignalSeverity.medium,
        recommendedActionAr:
            'استكمال نوع الأصل لضبط الفلاتر والتحليل والتقارير.',
        icon: Icons.category_outlined,
        weight: 2,
      ));
    }

    if (result.status.trim().isEmpty || _looksUnknown(result.status)) {
      signals.add(const SmartExplorerGapSignal(
        code: 'missing_asset_status',
        titleAr: 'حالة الأصل غير واضحة',
        descriptionAr: 'لا تظهر حالة تشغيلية/مرجعية واضحة للأصل.',
        severity: SmartExplorerSignalSeverity.low,
        recommendedActionAr:
            'استكمال حالة الأصل في مصدره السيادي عند مراجعة السجل.',
        icon: Icons.info_outline,
        weight: 1,
      ));
    }

    if (result.hasGeometry && !result.hasCentroid && !result.hasCenter) {
      signals.add(const SmartExplorerGapSignal(
        code: 'geometry_without_center',
        titleAr: 'هندسة بلا مركز ظاهر',
        descriptionAr:
            'توجد هندسة لكن لا يظهر centroid أو مركز يسهل التركيز على الخريطة.',
        severity: SmartExplorerSignalSeverity.low,
        recommendedActionAr:
            'توليد centroid تشغيلي للعرض دون تعديل الأصل السيادي مباشرة.',
        icon: Icons.center_focus_strong_outlined,
        weight: 1,
      ));
    }

    if (result.endowmentName.isNotEmpty && result.weakSpatialContext) {
      signals.add(const SmartExplorerGapSignal(
        code: 'historical_lineage_review_candidate',
        titleAr: 'مرشح لمراجعة السلالة الوقفية',
        descriptionAr:
            'يوجد وقف أم ظاهر لكن السياق المكاني/القطعي ضعيف، ما يجعله مرشحًا للمراجعة التاريخية.',
        severity: SmartExplorerSignalSeverity.medium,
        recommendedActionAr:
            'فتح الأصل في مستكشف التاريخ ومراجعة علاقته بالوقف الأم والتجمع.',
        icon: Icons.timeline_outlined,
        weight: 2,
      ));
    }

    return signals;
  }

  List<SmartExplorerHypothesis> _buildRuleHypotheses(
    SmartExplorerResult result,
    List<SmartExplorerGapSignal> signals,
  ) {
    if (signals.isEmpty) return const <SmartExplorerHypothesis>[];

    final hypotheses = <SmartExplorerHypothesis>[];
    if (signals.any((signal) => signal.code.contains('spatial') || signal.code.contains('geometry'))) {
      hypotheses.add(SmartExplorerHypothesis(
        id: 'spatial-${result.id}-${signals.length}',
        titleAr: 'فرضية ربط مكاني',
        summaryAr:
            'السجل يحتاج اختبار موقع أو مركز أو هندسة قبل الاعتماد المكاني.',
        confidence: result.confidenceScore / 100,
        evidence: result.evidenceLines,
        status: SmartExplorerHypothesisStatus.needsReview,
        intent: SmartExplorerHypothesisIntent.spatialLinking,
      ));
    }

    if (signals.any((signal) => signal.code.contains('parcel'))) {
      hypotheses.add(SmartExplorerHypothesis(
        id: 'parcel-${result.id}-${signals.length}',
        titleAr: 'فرضية مطابقة قطع',
        summaryAr:
            'قد يحتاج الأصل إلى مطابقة مع طبقات التسوية أو الأحواض قبل إغلاق الفجوة.',
        confidence: result.confidenceScore / 100,
        evidence: result.evidenceLines,
        status: SmartExplorerHypothesisStatus.needsReview,
        intent: SmartExplorerHypothesisIntent.parcelMatching,
      ));
    }

    if (signals.any((signal) => signal.code.contains('endowment'))) {
      hypotheses.add(SmartExplorerHypothesis(
        id: 'endowment-${result.id}-${signals.length}',
        titleAr: 'فرضية ربط الوقف الأم',
        summaryAr:
            'ربط الأصل بالوقف المرجعي يحتاج مراجعة من مصدر awqaf_system.',
        confidence: result.confidenceScore / 100,
        evidence: result.evidenceLines,
        status: SmartExplorerHypothesisStatus.needsReview,
        intent: SmartExplorerHypothesisIntent.endowmentReference,
      ));
    }

    if (hypotheses.isEmpty) {
      hypotheses.add(SmartExplorerHypothesis(
        id: 'quality-${result.id}-${signals.length}',
        titleAr: 'فرضية تدقيق جودة',
        summaryAr:
            'توجد ${signals.length} إشارة تحتاج مراجعة قبل اعتبار النتيجة مكتملة.',
        confidence: result.confidenceScore / 100,
        evidence: result.evidenceLines,
        status: SmartExplorerHypothesisStatus.needsReview,
        intent: SmartExplorerHypothesisIntent.qualityReview,
      ));
    }

    return hypotheses.take(4).toList(growable: true);
  }

  String _auditDetail(SmartExplorerResult result) {
    final buffer = StringBuffer()
      ..writeln('تم إنشاء هذا الطلب من المستكشف الذكي كاقتراح تدقيق غير سيادي.')
      ..writeln()
      ..writeln(result.compactAuditSummary)
      ..writeln()
      ..writeln('الأدلة المختصرة:');
    for (final line in result.evidenceLines.take(20)) {
      buffer.writeln('- $line');
    }
    return buffer.toString();
  }

  String _primarySeverity(SmartExplorerResult result) {
    final severity = result.topSeverity;
    switch (severity) {
      case SmartExplorerSignalSeverity.critical:
        return 'critical';
      case SmartExplorerSignalSeverity.high:
        return 'high';
      case SmartExplorerSignalSeverity.medium:
        return 'medium';
      case SmartExplorerSignalSeverity.low:
        return 'low';
      case null:
        return 'low';
    }
  }

  String _priorityForSeverity(String severity) {
    switch (severity) {
      case 'critical':
        return 'urgent';
      case 'high':
        return 'high';
      case 'medium':
        return 'normal';
      default:
        return 'low';
    }
  }

  String _normalizeDocumentText(String text) {
    return text
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<SmartExplorerDocumentEntity> _extractEntities(
    String text,
    RegExp pattern,
    SmartExplorerDocumentEntityType type,
    String evidence,
    double score,
  ) {
    final items = <SmartExplorerDocumentEntity>[];
    for (final match in pattern.allMatches(text)) {
      final value = _cleanEntityValue(match.group(1) ?? '');
      if (value.length < 2) continue;
      items.add(SmartExplorerDocumentEntity(
        value: value,
        type: type,
        evidence: evidence,
        score: score,
      ));
    }
    return items;
  }

  List<SmartExplorerDocumentEntity> _dedupeEntities(
    List<SmartExplorerDocumentEntity> entities,
  ) {
    final seen = <String>{};
    final out = <SmartExplorerDocumentEntity>[];
    for (final item in entities) {
      final key = '${item.type.name}:${item.value.trim().toLowerCase()}';
      if (seen.add(key)) out.add(item);
    }
    return out;
  }

  String _cleanEntityValue(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^(في|من|الى|إلى|على|عن|بـ|ب|ال)+\s+'), '')
        .replaceAll(RegExp(r'[،.;:]+$'), '')
        .trim();
  }

  List<String> _extractBoundaryClues(String text) {
    final patterns = <RegExp>[
      RegExp(r'(?:يحدها|يحده|حدها|حده)\s+[^.،;]{4,90}'),
      RegExp(r'(?:من الشرق|شرقا|شرقًا|من الغرب|غربا|غربًا|من الشمال|شمالا|شمالًا|من الجنوب|جنوبا|جنوبًا)\s+[^.،;]{3,70}'),
      RegExp(r'(?:ملاصق|بجوار|قرب|مقابل|تابع ل|ضمن أراضي)\s+[^.،;]{3,70}'),
    ];
    return _extractUniquePhrases(text, patterns, limit: 18);
  }

  List<String> _extractDirectionClues(String text) {
    final directions = <String>[
      'شرق',
      'شرقي',
      'شرقًا',
      'شرقا',
      'غرب',
      'غربي',
      'غربًا',
      'غربا',
      'شمال',
      'شمالي',
      'شمالًا',
      'شمالا',
      'جنوب',
      'جنوبي',
      'جنوبًا',
      'جنوبا',
    ];
    final found = <String>[];
    for (final direction in directions) {
      if (text.contains(direction) && !found.contains(direction)) {
        found.add(direction);
      }
    }
    return found;
  }

  List<String> _extractTimeClues(String text) {
    final patterns = <RegExp>[
      RegExp(r'(?:سنة|عام|تاريخ)\s+[0-9٠-٩]{3,4}'),
      RegExp(r'[0-9٠-٩]{1,2}\s*/\s*[0-9٠-٩]{1,2}\s*/\s*[0-9٠-٩]{2,4}'),
      RegExp(r'(?:عثماني|انتداب|أردني|تسوية|طابو)'),
    ];
    return _extractUniquePhrases(text, patterns, limit: 12);
  }

  List<String> _extractUniquePhrases(
    String text,
    List<RegExp> patterns, {
    int limit = 20,
  }) {
    final seen = <String>{};
    final out = <String>[];
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        final value = _cleanEntityValue(match.group(0) ?? '');
        if (value.length < 3) continue;
        if (seen.add(value.toLowerCase())) out.add(value);
        if (out.length >= limit) return out;
      }
    }
    return out;
  }

  List<String> _buildDocumentSpatialHypotheses({
    required List<SmartExplorerDocumentEntity> entities,
    required List<String> boundaryClues,
    required List<String> directionClues,
    required List<String> timeClues,
  }) {
    final hypotheses = <String>[];
    final places = entities
        .where((item) => item.type == SmartExplorerDocumentEntityType.place)
        .map((item) => item.value)
        .toList(growable: true);
    final waqfs = entities
        .where((item) => item.type == SmartExplorerDocumentEntityType.waqf)
        .map((item) => item.value)
        .toList(growable: true);
    final parcels = entities
        .where((item) => item.type == SmartExplorerDocumentEntityType.parcel)
        .map((item) => item.value)
        .toList(growable: true);

    if (places.isNotEmpty && boundaryClues.isNotEmpty) {
      hypotheses.add(
        'اختبار نطاق ${places.first} مع قرائن الحدود المستخرجة لتحديد منطقة احتمال أولية.',
      );
    }
    if (waqfs.isNotEmpty && places.isNotEmpty) {
      hypotheses.add(
        'مقارنة ${waqfs.first} مع الأصول الوقفية الظاهرة في/حول ${places.first}.',
      );
    }
    if (parcels.isNotEmpty) {
      hypotheses.add(
        'مطابقة الحوض/القطعة (${parcels.first}) مع طبقات التسوية أو الأحواض قبل اعتماد الموقع.',
      );
    }
    if (directionClues.length >= 2) {
      hypotheses.add(
        "استخدام الاتجاهات (${directionClues.take(4).join('، ')}) لبناء نطاق احتمالي لا نقطة قطعية.",
      );
    }
    if (timeClues.isNotEmpty) {
      hypotheses.add(
        'مراجعة الفترة/المصدر التاريخي (${timeClues.first}) قبل ربط النص بالحدود الحديثة.',
      );
    }
    if (hypotheses.isEmpty && entities.isNotEmpty) {
      hypotheses.add('استخدام المسميات المستخرجة كبذور بحث داخل الخريطة الحديثة ومستكشف التاريخ.');
    }
    return hypotheses;
  }

  double _documentConfidence({
    required int entityCount,
    required int boundaryCount,
    required int directionCount,
    required int timeCount,
  }) {
    var score = 0.18;
    score += (entityCount.clamp(0, 8) * 0.07);
    score += (boundaryCount.clamp(0, 5) * 0.06);
    score += (directionCount.clamp(0, 4) * 0.035);
    score += (timeCount.clamp(0, 3) * 0.025);
    return score.clamp(0, 0.92).toDouble();
  }

  String _evidenceRecommendation({
    required int boundedScore,
    required List<String> conflicts,
    required SmartExplorerResult result,
  }) {
    if (boundedScore >= 70 && conflicts.isEmpty) {
      return 'رابط قوي؛ يصلح كنقطة بدء للمراجعة البشرية أو فتح الأصل على الخريطة.';
    }
    if (boundedScore >= 45) {
      return 'رابط متوسط؛ يحتاج اختبارًا مكانيًا ومقارنة مع الطبقات قبل الاعتماد.';
    }
    if (conflicts.isNotEmpty || result.needsReview) {
      return 'رابط ضعيف/متعارض؛ يوصى بفتح طلب تدقيق أو البحث بقرائن إضافية.';
    }
    return 'قرينة أولية فقط؛ استخدمها كبذرة بحث لا كدليل اعتماد.';
  }

  String sampleDocumentText() {
    return 'حجة وقف تتعلق بأرض من أراضي بيت لحم، يحدها شرقًا طريق الخليل، وغربًا أراضي وقف خاسكي سلطان، وشمالًا وادٍ معروف، وجنوبًا أراضي القرية. ورد في النص ذكر حوض رقم 12 وقطعة رقم 45 وقرب مسجد قديم.';
  }

  SmartExplorerDecisionBoard buildDecisionBoard({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    List<SmartExplorerReadinessAssessment>? readinessAssessments,
    SmartExplorerRoutePlan? routePlan,
  }) {
    final items = <SmartExplorerDecisionItem>[];
    final reviewQueue = results.where((item) => item.needsReview).toList(growable: false)
      ..sort((a, b) => b.reviewScore.compareTo(a.reviewScore));

    for (final result in reviewQueue.take(8)) {
      final topSignal = result.gapSignals.isEmpty ? null : result.gapSignals.first;
      items.add(SmartExplorerDecisionItem(
        titleAr: 'تدقيق أصل: ${result.titleAr}',
        descriptionAr: topSignal == null
            ? 'نتيجة تحتاج مراجعة حسب درجة الثقة والأولوية.'
            : '${topSignal.titleAr}: ${topSignal.descriptionAr}',
        actionAr: result.recommendedActionAr,
        priority: result.reviewScore.clamp(0, 100).toInt(),
        domainAr: 'الأصول الوقفية',
        resultId: result.id,
        resultTitleAr: result.titleAr,
      ));
    }

    if (documentAnalysis != null && documentAnalysis.hasEvidence) {
      items.add(SmartExplorerDecisionItem(
        titleAr: 'مراجعة قرائن الوثيقة',
        descriptionAr:
            'النص يحتوي ${documentAnalysis.evidenceCount} قرينة ومسميات تحتاج مطابقة مع الخريطة والتاريخ.',
        actionAr: 'بناء قاموس مسميات ومصفوفة أدلة قبل تحويل أي نتيجة إلى اعتماد.',
        priority: (documentAnalysis.confidencePercent + 10).clamp(35, 90).toInt(),
        domainAr: 'الوثائق',
      ));
    }

    if (evidenceMatrix != null && evidenceMatrix.hasLinks) {
      final weakLinks = evidenceMatrix.weakLinks;
      final strongLinks = evidenceMatrix.strongLinks;
      items.add(SmartExplorerDecisionItem(
        titleAr: 'اعتماد مسار مطابقة الأدلة',
        descriptionAr:
            'مصفوفة الأدلة أنتجت $strongLinks روابط قوية و$weakLinks روابط ضعيفة بين الوثيقة والنتائج.',
        actionAr: strongLinks > 0
            ? 'افتح الروابط القوية على الخريطة ثم أنشئ طلب تدقيق للروابط المتعارضة.'
            : 'أدخل قرائن أكثر أو غيّر عبارة البحث قبل الاعتماد.',
        priority: strongLinks > 0 ? 72 : 48,
        domainAr: 'مصفوفة الأدلة',
      ));
    }

    final lowReadiness = (readinessAssessments ?? const <SmartExplorerReadinessAssessment>[])
        .where((item) => item.overallScore < 65)
        .toList(growable: false);
    if (lowReadiness.isNotEmpty) {
      items.add(SmartExplorerDecisionItem(
        titleAr: 'إغلاق عوائق الجاهزية',
        descriptionAr:
            'هناك ${lowReadiness.length} نتيجة غير جاهزة للعرض/التاريخ/الحوكمة ضمن النطاق الحالي.',
        actionAr: 'ابدأ بأقل النتائج جاهزية، واستعمل طلبات التدقيق بدل تعديل السجلات مباشرة.',
        priority: 78,
        domainAr: 'الجاهزية',
      ));
    }

    if (routePlan != null && routePlan.stops.isNotEmpty) {
      items.add(SmartExplorerDecisionItem(
        titleAr: 'تحضير جولة تدقيق ميداني',
        descriptionAr: routePlan.summaryAr,
        actionAr: 'راجع ترتيب النقاط حسب المحافظة/التجمع ثم صدّر التقرير للفريق المختص.',
        priority: 64,
        domainAr: 'الميدان',
      ));
    }

    return SmartExplorerDecisionBoard(
      items: items,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'نتائج البحث والفلاتر الحالية',
    );
  }

  String buildWorkspaceSnapshot({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    List<SmartExplorerReadinessAssessment>? readinessAssessments,
    SmartExplorerRoutePlan? routePlan,
    SmartExplorerDecisionBoard? decisionBoard,
  }) {
    final buffer = StringBuffer()
      ..writeln('لقطة عمل المستكشف الذكي')
      ..writeln('وقت التوليد: ${DateTime.now().toIso8601String()}')
      ..writeln('النطاق/البحث: ${query.trim().isEmpty ? 'غير محدد' : query.trim()}')
      ..writeln('هذه لقطة عمل غير سيادية للمراجعة والتوريث فقط.')
      ..writeln('---')
      ..writeln('النتائج: ${results.length}')
      ..writeln('تحتاج مراجعة: ${results.where((item) => item.needsReview).length}')
      ..writeln('بلا تمثيل مكاني: ${results.where((item) => !item.hasAnySpatialReference).length}')
      ..writeln('بلا قطع مرتبطة: ${results.where((item) => !item.hasLinkedParcels).length}');

    if (documentAnalysis != null) {
      buffer
        ..writeln('---')
        ..writeln('الوثيقة: ${documentAnalysis.summaryAr}')
        ..writeln('المسميات: ${documentAnalysis.entities.length}')
        ..writeln('قرائن الحدود: ${documentAnalysis.boundaryClues.length}');
    }

    if (evidenceMatrix != null) {
      buffer
        ..writeln('---')
        ..writeln('مصفوفة الأدلة: ${evidenceMatrix.summaryAr}');
    }

    if (readinessAssessments != null && readinessAssessments.isNotEmpty) {
      buffer
        ..writeln('---')
        ..writeln('أقل 5 نتائج جاهزية:');
      final sorted = List<SmartExplorerReadinessAssessment>.from(readinessAssessments)
        ..sort((a, b) => a.overallScore.compareTo(b.overallScore));
      for (final item in sorted.take(5)) {
        buffer.writeln('- ${item.titleAr}: ${item.overallScore}% — ${item.readinessLabelAr}');
      }
    }

    if (routePlan != null && routePlan.stops.isNotEmpty) {
      buffer
        ..writeln('---')
        ..writeln('المسار: ${routePlan.summaryAr}');
    }

    if (decisionBoard != null && !decisionBoard.isEmpty) {
      buffer
        ..writeln('---')
        ..writeln('لوحة القرار: ${decisionBoard.summaryAr}');
      for (final item in decisionBoard.topItems.take(8)) {
        buffer.writeln('- [${item.priorityLabelAr}] ${item.titleAr}: ${item.actionAr}');
      }
    }

    buffer
      ..writeln('---')
      ..writeln('نقطة الاستئناف المقترحة: ابدأ من أعلى بند في لوحة القرار أو أعلى نتيجة في قائمة الأولوية، دون تعديل الجداول السيادية مباشرة.');
    return buffer.toString();
  }

  SmartExplorerFieldChecklist buildFieldChecklist({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    List<SmartExplorerReadinessAssessment>? readinessAssessments,
  }) {
    final items = <SmartExplorerFieldChecklistItem>[];
    final queue = results.where((item) => item.needsReview).toList(growable: false)
      ..sort((a, b) => b.reviewScore.compareTo(a.reviewScore));

    for (final result in queue.take(12)) {
      final location = <String>[
        if (result.governorate.trim().isNotEmpty) result.governorate.trim(),
        if (result.community.trim().isNotEmpty) result.community.trim(),
        if (result.lgu.trim().isNotEmpty) result.lgu.trim(),
      ].join(' / ');
      final topSignal = result.gapSignals.isEmpty ? null : result.gapSignals.first;
      items.add(SmartExplorerFieldChecklistItem(
        titleAr: 'تحقق ميداني: ${result.titleAr}',
        instructionAr: topSignal == null
            ? 'راجع الأصل ميدانيًا وتحقق من موقعه وسياقه قبل أي اعتماد.'
            : topSignal.recommendedActionAr,
        evidenceRequiredAr: !result.hasAnySpatialReference
            ? 'صورة/إحداثية تقريبية/وصف حدود من الفريق الميداني.'
            : !result.hasLinkedParcels
                ? 'مطابقة قطعة/حوض أو سبب عدم وجود ربط تسوية.'
                : 'ملاحظة تدقيق تؤكد سلامة البيانات الحالية.',
        domainAr: 'الأصول الوقفية',
        priority: result.reviewScore.clamp(20, 100).toInt(),
        locationLabelAr: location.trim().isEmpty ? 'سياق إداري غير مكتمل' : location,
        resultId: result.id,
        resultTitleAr: result.titleAr,
        assetCode: result.assetCode,
        requiresPhoto: !result.hasAnySpatialReference || !result.hasLinkedParcels,
        requiresDocumentReview: result.endowmentName.trim().isEmpty || result.assetCode.trim().isEmpty,
      ));
    }

    if (documentAnalysis != null && documentAnalysis.hasEvidence) {
      items.add(SmartExplorerFieldChecklistItem(
        titleAr: 'مطابقة قرائن الوثيقة',
        instructionAr: 'راجع المسميات والاتجاهات والحدود المستخرجة من النص مع الخريطة الحديثة ومستكشف التاريخ.',
        evidenceRequiredAr: 'تحديد أي مسمى تم اعتماده كمفتاح بحث، وأي قرينة تم استبعادها وسبب الاستبعاد.',
        domainAr: 'الوثائق',
        priority: (documentAnalysis.confidencePercent + 12).clamp(45, 92).toInt(),
        locationLabelAr: 'نطاق الوثيقة',
        requiresDocumentReview: true,
      ));
    }

    if (evidenceMatrix != null && evidenceMatrix.hasLinks) {
      final weak = evidenceMatrix.weakLinks;
      items.add(SmartExplorerFieldChecklistItem(
        titleAr: 'اختبار روابط مصفوفة الأدلة',
        instructionAr: 'ابدأ بالروابط القوية، ثم افتح طلبات تدقيق للروابط الضعيفة أو المتعارضة.',
        evidenceRequiredAr: 'نتيجة اختبار كل رابط: مقبول مبدئيًا / يحتاج تدقيق / مستبعد.',
        domainAr: 'مصفوفة الأدلة',
        priority: weak > 0 ? 76 : 62,
        locationLabelAr: 'نطاق نتائج البحث',
        requiresDocumentReview: true,
      ));
    }

    final lowReadiness = (readinessAssessments ?? const <SmartExplorerReadinessAssessment>[])
        .where((item) => item.overallScore < 65)
        .toList(growable: false)
      ..sort((a, b) => a.overallScore.compareTo(b.overallScore));
    for (final item in lowReadiness.take(8)) {
      items.add(SmartExplorerFieldChecklistItem(
        titleAr: 'إغلاق عائق جاهزية: ${item.titleAr}',
        instructionAr: item.nextActions.isEmpty
            ? 'استكمل عوائق الجاهزية قبل العرض أو التوريث.'
            : item.nextActions.first,
        evidenceRequiredAr: item.blockers.isEmpty
            ? 'ملاحظة مراجعة تؤكد الجاهزية.'
            : item.blockers.join('، '),
        domainAr: 'الجاهزية',
        priority: (100 - item.overallScore).clamp(35, 95).toInt(),
        locationLabelAr: item.assetCode.trim().isEmpty ? 'أصل بلا رمز ظاهر' : item.assetCode,
        resultId: item.resultId,
        resultTitleAr: item.titleAr,
        assetCode: item.assetCode,
        requiresPhoto: item.fieldAuditScore < 65,
        requiresDocumentReview: item.historyScore < 65 || item.governanceScore < 65,
      ));
    }

    return SmartExplorerFieldChecklist(
      items: items,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'نتائج البحث والتحليل الحالية',
    );
  }

  SmartExplorerRiskRegister buildRiskRegister({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    List<SmartExplorerReadinessAssessment>? readinessAssessments,
  }) {
    final risks = <SmartExplorerRiskItem>[];

    final noSpatial = results.where((item) => !item.hasAnySpatialReference).length;
    if (noSpatial > 0) {
      risks.add(SmartExplorerRiskItem(
        titleAr: 'أصول بلا تمثيل مكاني',
        descriptionAr: 'يوجد $noSpatial أصلًا بلا نقطة/مركز/هندسة ضمن النطاق الحالي.',
        mitigationAr: 'إنتاج طلبات تدقيق وربط مبدئي قبل استخدامها في العرض العام أو التقارير.',
        domainAr: 'المكان',
        severity: 5,
        likelihood: noSpatial >= 5 ? 5 : 4,
      ));
    }

    final noParcels = results.where((item) => !item.hasLinkedParcels).length;
    if (noParcels > 0) {
      risks.add(SmartExplorerRiskItem(
        titleAr: 'ربط قطع غير مكتمل',
        descriptionAr: 'يوجد $noParcels أصلًا بلا قطع مرتبطة ظاهرة.',
        mitigationAr: 'مطابقة التسوية/الأحواض أو توثيق سبب غياب الربط بدل افتراض الملكية.',
        domainAr: 'التسوية/القطع',
        severity: 4,
        likelihood: noParcels >= 5 ? 5 : 3,
      ));
    }

    final missingReference = results.where((item) => item.missingReferenceContext).length;
    if (missingReference > 0) {
      risks.add(SmartExplorerRiskItem(
        titleAr: 'مرجع وقفي أو رمز وطني ناقص',
        descriptionAr: 'يوجد $missingReference نتيجة ينقصها وقف أم أو رمز وطني ظاهر.',
        mitigationAr: 'التحقق من awqaf_system كمصدر الحقيقة وعدم توليد أي رمز داخل المستكشف.',
        domainAr: 'الحوكمة',
        severity: 5,
        likelihood: 3,
      ));
    }

    if (documentAnalysis != null && documentAnalysis.hasEvidence && documentAnalysis.confidencePercent < 65) {
      risks.add(SmartExplorerRiskItem(
        titleAr: 'وثيقة بقرائن غير كافية',
        descriptionAr: 'تحليل الوثيقة أعطى ثقة ${documentAnalysis.confidencePercent}% فقط.',
        mitigationAr: 'طلب صورة أوضح/نص أطول/مصدر إضافي قبل بناء فرضية مكانية قوية.',
        domainAr: 'الوثائق',
        severity: 3,
        likelihood: 4,
      ));
    }

    if (evidenceMatrix != null && evidenceMatrix.weakLinks > 0) {
      risks.add(SmartExplorerRiskItem(
        titleAr: 'روابط دليل ضعيفة',
        descriptionAr: 'مصفوفة الأدلة تحتوي ${evidenceMatrix.weakLinks} روابط ضعيفة.',
        mitigationAr: 'لا تعتمد الروابط الضعيفة؛ استخدمها كبذور بحث أو افتح طلب تدقيق.',
        domainAr: 'الأدلة',
        severity: 3,
        likelihood: 4,
      ));
    }

    final lowReadiness = (readinessAssessments ?? const <SmartExplorerReadinessAssessment>[])
        .where((item) => item.overallScore < 40)
        .length;
    if (lowReadiness > 0) {
      risks.add(SmartExplorerRiskItem(
        titleAr: 'نتائج غير جاهزة للتوريث',
        descriptionAr: 'يوجد $lowReadiness نتيجة جاهزيتها أقل من 40%.',
        mitigationAr: 'ابدأ بقائمة التدقيق الميداني ولا تنقل النتائج إلى تقرير نهائي.',
        domainAr: 'التوريث',
        severity: 4,
        likelihood: 4,
      ));
    }

    return SmartExplorerRiskRegister(
      risks: risks,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'نطاق العمل الحالي',
    );
  }

  List<SmartExplorerQaScenario> buildQaScenarios({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerRiskRegister? riskRegister,
  }) {
    final scenarios = <SmartExplorerQaScenario>[
      SmartExplorerQaScenario(
        titleAr: 'اختبار البحث والنتائج',
        testSteps: const <String>[
          'نفّذ بحثًا باسم أصل أو رمز وطني.',
          'تحقق أن النتائج تظهر كبطاقات دون تحميل طبقات ثقيلة.',
          'افتح أول نتيجة على الخريطة ثم عد للمستكشف الذكي.',
        ],
        expectedEvidenceAr: 'نتائج ظاهرة، وعدادات صحيحة، ولا يوجد overflow أو شاشة حمراء.',
        failureSignalAr: 'فشل البحث أو اختفاء القائمة أو توقف الصفحة عند نتائج كثيرة.',
        priority: 75,
        domainAr: 'تشغيل الواجهة',
      ),
      SmartExplorerQaScenario(
        titleAr: 'اختبار عدم الكتابة السيادية',
        testSteps: const <String>[
          'أنشئ فرضية محلية أو تقريرًا.',
          'تحقق أن النتيجة بقيت داخل المستكشف الذكي.',
          'أنشئ طلب تدقيق فقط عند الحاجة.',
        ],
        expectedEvidenceAr: 'لا تعديل مباشر على waqf_assets أو endowments أو core.',
        failureSignalAr: 'أي تعديل مباشر أو اعتماد تلقائي يعد خطأ حوكميًا.',
        priority: 95,
        domainAr: 'الحوكمة',
      ),
    ];

    if (documentAnalysis != null && documentAnalysis.hasEvidence) {
      scenarios.add(SmartExplorerQaScenario(
        titleAr: 'اختبار تحليل الوثيقة',
        testSteps: const <String>[
          'الصق نص وثيقة يحتوي اسم وقف وموقع وحدود.',
          'شغّل تحليل النص.',
          'راجع المسميات والاتجاهات والفرضيات النصية.',
        ],
        expectedEvidenceAr: 'استخراج مسميات وقرائن مع درجة ثقة ورسالة مراجعة بشرية.',
        failureSignalAr: 'خلط المسميات أو اعتبار النص موقعًا قطعيًا.',
        priority: 80,
        domainAr: 'الوثائق',
      ));
    }

    if (evidenceMatrix != null && evidenceMatrix.hasLinks) {
      scenarios.add(SmartExplorerQaScenario(
        titleAr: 'اختبار مصفوفة الأدلة',
        testSteps: const <String>[
          'شغّل مصفوفة الأدلة بعد البحث وتحليل الوثيقة.',
          'راجع الروابط القوية والضعيفة.',
          'تأكد أن الروابط الضعيفة لا تُعرض كاعتماد نهائي.',
        ],
        expectedEvidenceAr: 'درجات مطابقة واضحة وتوصية مراجعة لكل رابط.',
        failureSignalAr: 'عرض رابط ضعيف كدليل قطعي أو غياب التعارضات.',
        priority: 78,
        domainAr: 'الأدلة',
      ));
    }

    if (riskRegister != null && riskRegister.criticalRisks > 0) {
      scenarios.add(SmartExplorerQaScenario(
        titleAr: 'اختبار المخاطر الحرجة',
        testSteps: const <String>[
          'ولّد سجل المخاطر.',
          'راجع البنود الحرجة.',
          'تأكد أن لوحة القرار وقائمة التدقيق تعطيها أولوية.',
        ],
        expectedEvidenceAr: 'المخاطر الحرجة تظهر بوضوح مع إجراء تخفيف.',
        failureSignalAr: 'خطر حرج لا يظهر في القرار أو التوريث.',
        priority: 88,
        domainAr: 'المخاطر',
      ));
    }

    if (results.any((item) => item.needsReview)) {
      scenarios.add(SmartExplorerQaScenario(
        titleAr: 'اختبار إنشاء طلبات التدقيق',
        testSteps: const <String>[
          'اختر نتيجة تحتاج مراجعة.',
          'أنشئ طلب تدقيق من النتيجة.',
          'افتح /admin/explorer-gap-audits وتحقق من ظهور الطلب.',
        ],
        expectedEvidenceAr: 'طلب تدقيق جديد دون تعديل مباشر على بيانات الأصل.',
        failureSignalAr: 'فشل إنشاء الطلب أو إنشاء طلب بلا عنوان/سياق.',
        priority: 82,
        domainAr: 'طلبات التدقيق',
      ));
    }

    return scenarios;
  }

  String buildHandoffPacket({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    List<SmartExplorerReadinessAssessment>? readinessAssessments,
    SmartExplorerRoutePlan? routePlan,
    SmartExplorerDecisionBoard? decisionBoard,
    SmartExplorerFieldChecklist? fieldChecklist,
    SmartExplorerRiskRegister? riskRegister,
    List<SmartExplorerQaScenario> qaScenarios = const <SmartExplorerQaScenario>[],
    SmartExplorerWorkPackageSet? workPackages,
    SmartExplorerLayerRecommendationSet? layerRecommendations,
    SmartExplorerValidationProtocol? validationProtocol,
    SmartExplorerKnowledgeCardSet? knowledgeCards,
  }) {
    final buffer = StringBuffer()
      ..writeln('حزمة توريث المستكشف الذكي')
      ..writeln('وقت التوليد: ${DateTime.now().toIso8601String()}')
      ..writeln('النطاق: ${query.trim().isEmpty ? 'غير محدد' : query.trim()}')
      ..writeln('ملاحظة: هذه حزمة غير سيادية، ولا تعتمد أي تعديل مباشر على الجداول المرجعية.')
      ..writeln('---')
      ..writeln('النتائج: ${results.length}')
      ..writeln('نتائج تحتاج مراجعة: ${results.where((item) => item.needsReview).length}')
      ..writeln('بلا تمثيل مكاني: ${results.where((item) => !item.hasAnySpatialReference).length}')
      ..writeln('بلا قطع مرتبطة: ${results.where((item) => !item.hasLinkedParcels).length}');

    final topResults = results.where((item) => item.needsReview).toList(growable: false)
      ..sort((a, b) => b.reviewScore.compareTo(a.reviewScore));
    if (topResults.isNotEmpty) {
      buffer..writeln('---')..writeln('أعلى نتائج تحتاج مراجعة:');
      for (final item in topResults.take(8)) {
        buffer.writeln('- ${item.titleAr} | ${item.assetCode.isEmpty ? 'بلا رمز ظاهر' : item.assetCode} | ${item.reviewPriorityLabelAr} | ${item.recommendedActionAr}');
      }
    }

    if (documentAnalysis != null) {
      buffer
        ..writeln('---')
        ..writeln('تحليل الوثيقة: ${documentAnalysis.summaryAr}')
        ..writeln('الثقة: ${documentAnalysis.confidencePercent}%')
        ..writeln('المسميات: ${documentAnalysis.entities.map((e) => e.value).take(10).join('، ')}');
    }

    if (evidenceMatrix != null) {
      buffer..writeln('---')..writeln('مصفوفة الأدلة: ${evidenceMatrix.summaryAr}');
      for (final link in evidenceMatrix.topLinks.take(6)) {
        buffer.writeln('- ${link.entityValue} ⇐ ${link.resultTitleAr} | ${link.matchScore}% | ${link.recommendationAr}');
      }
    }

    if (readinessAssessments != null && readinessAssessments.isNotEmpty) {
      final sorted = List<SmartExplorerReadinessAssessment>.from(readinessAssessments)
        ..sort((a, b) => a.overallScore.compareTo(b.overallScore));
      buffer..writeln('---')..writeln('أقل النتائج جاهزية:');
      for (final item in sorted.take(6)) {
        buffer.writeln('- ${item.titleAr}: ${item.overallScore}% — ${item.readinessLabelAr}');
      }
    }

    if (riskRegister != null && !riskRegister.isEmpty) {
      buffer..writeln('---')..writeln('سجل المخاطر: ${riskRegister.summaryAr}');
      for (final risk in riskRegister.topRisks.take(6)) {
        buffer.writeln('- [${risk.scoreLabelAr}] ${risk.titleAr}: ${risk.mitigationAr}');
      }
    }

    if (fieldChecklist != null && !fieldChecklist.isEmpty) {
      buffer..writeln('---')..writeln('قائمة التدقيق: ${fieldChecklist.summaryAr}');
      for (final item in fieldChecklist.topItems.take(8)) {
        buffer.writeln('- [${item.priorityLabelAr}] ${item.titleAr}: ${item.evidenceRequiredAr}');
      }
    }

    if (routePlan != null && routePlan.stops.isNotEmpty) {
      buffer..writeln('---')..writeln('مسار التدقيق: ${routePlan.summaryAr}');
    }

    if (decisionBoard != null && !decisionBoard.isEmpty) {
      buffer..writeln('---')..writeln('لوحة القرار: ${decisionBoard.summaryAr}');
    }

    if (workPackages != null && !workPackages.isEmpty) {
      buffer..writeln('---')..writeln('حزم العمل: ${workPackages.summaryAr}');
      for (final item in workPackages.topPackages.take(6)) {
        buffer.writeln('- [${item.priorityLabelAr}] ${item.titleAr}: ${item.expectedOutputAr}');
      }
    }

    if (layerRecommendations != null && !layerRecommendations.isEmpty) {
      buffer..writeln('---')..writeln('توصيات الطبقات: ${layerRecommendations.summaryAr}');
      for (final item in layerRecommendations.topRecommendations.take(6)) {
        buffer.writeln('- [${item.priorityLabelAr}] ${item.titleAr}: ${item.reasonAr}');
      }
    }

    if (validationProtocol != null && !validationProtocol.isEmpty) {
      buffer..writeln('---')..writeln('بروتوكول التحقق: ${validationProtocol.summaryAr}');
      for (final gate in validationProtocol.gates) {
        buffer.writeln('- [${gate.status.labelAr}] ${gate.titleAr}: ${gate.nextActionAr}');
      }
    }

    if (knowledgeCards != null && !knowledgeCards.isEmpty) {
      buffer..writeln('---')..writeln('بطاقات المعرفة: ${knowledgeCards.summaryAr}');
      for (final card in knowledgeCards.topCards.take(6)) {
        buffer.writeln('- ${card.titleAr} — ${card.typeAr}: ${card.reviewQuestionAr}');
      }
    }

    if (qaScenarios.isNotEmpty) {
      buffer..writeln('---')..writeln('سيناريوهات الاختبار:');
      for (final scenario in qaScenarios.take(8)) {
        buffer.writeln('- [${scenario.priorityLabelAr}] ${scenario.titleAr}: ${scenario.expectedEvidenceAr}');
      }
    }

    buffer
      ..writeln('---')
      ..writeln('نقطة الاستئناف: ابدأ بالمخاطر الحرجة، ثم قائمة التدقيق، ثم أعلى نتيجة في لوحة القرار. أي اعتماد نهائي يجب أن يمر بمراجعة بشرية ومسار تدقيق.');
    return buffer.toString();
  }


  SmartExplorerWorkPackageSet buildWorkPackages({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    List<SmartExplorerReadinessAssessment>? readinessAssessments,
    SmartExplorerRiskRegister? riskRegister,
  }) {
    final packages = <SmartExplorerWorkPackage>[];
    final reviewQueue = results.where((item) => item.needsReview).toList(growable: false)
      ..sort((a, b) => b.reviewScore.compareTo(a.reviewScore));

    if (reviewQueue.any((item) => !item.hasAnySpatialReference)) {
      packages.add(SmartExplorerWorkPackage(
        id: 'spatial-linking-${DateTime.now().millisecondsSinceEpoch}',
        titleAr: 'حزمة ربط مكاني للأصول بلا تمثيل',
        objectiveAr: 'تحويل الأصول التي لا تملك نقطة/هندسة إلى ملفات تدقيق قابلة للعمل دون تعديل المصدر السيادي.',
        domainAr: 'المكان',
        priority: 92,
        relatedResultIds: reviewQueue.where((item) => !item.hasAnySpatialReference).take(12).map((item) => item.id).toList(growable: false),
        ownerRoleAr: 'فريق GIS / التدقيق الميداني',
        actions: const <String>[
          'فرز الأصول بلا تمثيل مكاني حسب المحافظة والتجمع.',
          'فتح طلب تدقيق لكل أصل عالي الأولوية بدل تعديل waqf_assets مباشرة.',
          'جمع إحداثية تقريبية أو وصف حدود أو صورة ميدانية.',
          'مراجعة النتيجة على الخريطة الحديثة قبل أي اعتماد.',
        ],
        expectedOutputAr: 'قائمة أصول مرشحة للربط المكاني مع دليل مراجعة لكل أصل.',
        acceptanceCriteria: const <String>[
          'لكل أصل طلب تدقيق أو سبب استبعاد واضح.',
          'لا يوجد تعديل مباشر على الجداول السيادية.',
          'تم توثيق مصدر الدليل الميداني أو الوصفي.',
        ],
      ));
    }

    if (reviewQueue.any((item) => !item.hasLinkedParcels)) {
      packages.add(SmartExplorerWorkPackage(
        id: 'parcel-matching-${DateTime.now().millisecondsSinceEpoch}',
        titleAr: 'حزمة مطابقة القطع والأحواض',
        objectiveAr: 'تجهيز مراجعة منظمة للأصول التي تظهر بلا قطع مرتبطة أو بسياق قطعي ضعيف.',
        domainAr: 'التسوية/القطع',
        priority: 86,
        relatedResultIds: reviewQueue.where((item) => !item.hasLinkedParcels).take(12).map((item) => item.id).toList(growable: false),
        ownerRoleAr: 'فريق التسوية / GIS',
        actions: const <String>[
          'مطابقة أسماء الأحواض والقطع مع طبقات التسوية أو natural blocks.',
          'تمييز حالة: مطابق / محتمل / لا توجد قطعة / يحتاج وثيقة إضافية.',
          'ربط النتيجة بطلب تدقيق لا بتعديل مباشر.',
        ],
        expectedOutputAr: 'مصفوفة مطابقة أولية بين الأصل والقطعة/الحوض مع درجة ثقة.',
        acceptanceCriteria: const <String>[
          'كل مطابقة تحمل مصدرًا وسببًا.',
          'النتائج المحتملة لا تُعامل كاعتماد نهائي.',
        ],
      ));
    }

    final missingReference = reviewQueue.where((item) => item.missingReferenceContext).toList(growable: false);
    if (missingReference.isNotEmpty) {
      packages.add(SmartExplorerWorkPackage(
        id: 'reference-governance-${DateTime.now().millisecondsSinceEpoch}',
        titleAr: 'حزمة استكمال المرجع السيادي',
        objectiveAr: 'فرز الأصول التي ينقصها رمز وطني أو وقف أم ظاهر وإعادتها لمسار awqaf_system.',
        domainAr: 'الحوكمة',
        priority: 82,
        relatedResultIds: missingReference.take(12).map((item) => item.id).toList(growable: false),
        ownerRoleAr: 'فريق awqaf_system / حوكمة البيانات',
        actions: const <String>[
          'مراجعة الرمز الوطني والوقف الأم من مصدر awqaf_system.',
          'تحديد هل النقص عرضي في RPC أم نقص فعلي في المصدر.',
          'تسجيل طلب تدقيق مرجعي عند الحاجة.',
        ],
        expectedOutputAr: 'قائمة استكمال مرجعي لا تولّد رموزًا داخل المستكشف.',
        acceptanceCriteria: const <String>[
          'أي رمز وطني يصدر فقط من awqaf_system.',
          'كل نقص موثق بسبب واضح.',
        ],
      ));
    }

    if (documentAnalysis != null && documentAnalysis.hasEvidence) {
      packages.add(SmartExplorerWorkPackage(
        id: 'document-evidence-${DateTime.now().millisecondsSinceEpoch}',
        titleAr: 'حزمة مطابقة الوثيقة مع الخريطة',
        objectiveAr: 'تحويل المسميات والحدود المستخرجة من الوثيقة إلى أسئلة مراجعة قابلة للاختبار.',
        domainAr: 'الوثائق',
        priority: documentAnalysis.confidencePercent >= 70 ? 74 : 62,
        ownerRoleAr: 'باحث تاريخي / مدقق وثائق',
        actions: const <String>[
          'مراجعة المسميات المستخرجة واستبعاد الضوضاء النصية.',
          'اختبار قرائن الاتجاه والحدود مع طبقات الخريطة.',
          'بناء مصفوفة أدلة قبل أي فرضية موقع.',
        ],
        expectedOutputAr: 'قائمة مسميات وقرائن مقبولة/مستبعدة مع سبب المراجعة.',
        acceptanceCriteria: const <String>[
          'لا تُحوّل قرينة وصفية إلى موقع قطعي.',
          'كل مسمى يحمل مصدرًا وسؤال مراجعة.',
        ],
      ));
    }

    if (evidenceMatrix != null && evidenceMatrix.hasLinks) {
      packages.add(SmartExplorerWorkPackage(
        id: 'evidence-links-${DateTime.now().millisecondsSinceEpoch}',
        titleAr: 'حزمة اختبار روابط الأدلة',
        objectiveAr: 'مراجعة الروابط القوية والضعيفة بين الوثيقة ونتائج الأصول.',
        domainAr: 'الأدلة',
        priority: evidenceMatrix.weakLinks > 0 ? 78 : 66,
        actions: const <String>[
          'اعتماد الروابط القوية كبداية مراجعة لا كقرار نهائي.',
          'فتح طلبات تدقيق للروابط المتعارضة.',
          'إعادة البحث عند غياب الروابط القوية.',
        ],
        expectedOutputAr: 'قرار مراجعة لكل رابط: مقبول مبدئيًا / يحتاج تدقيق / مستبعد.',
        acceptanceCriteria: const <String>[
          'كل رابط ضعيف له سبب واضح.',
          'لا يتم اعتماد رابط بلا دليل مكاني أو وثائقي مساعد.',
        ],
      ));
    }

    final lowReadiness = (readinessAssessments ?? const <SmartExplorerReadinessAssessment>[])
        .where((item) => item.overallScore < 65)
        .toList(growable: false);
    if (lowReadiness.isNotEmpty) {
      packages.add(SmartExplorerWorkPackage(
        id: 'readiness-closure-${DateTime.now().millisecondsSinceEpoch}',
        titleAr: 'حزمة إغلاق عوائق الجاهزية',
        objectiveAr: 'رفع جاهزية النتائج قبل عرضها أو توريثها إلى مرحلة لاحقة.',
        domainAr: 'الجاهزية',
        priority: 76,
        relatedResultIds: lowReadiness.take(12).map((item) => item.resultId).toList(growable: false),
        actions: const <String>[
          'بدء العمل بأقل النتائج جاهزية.',
          'تمييز عوائق الخريطة والتاريخ والحوكمة.',
          'تحديث حزمة التوريث بعد إغلاق كل عائق.',
        ],
        expectedOutputAr: 'قائمة جاهزية محدثة مع عوائق مغلقة أو مؤجلة.',
        acceptanceCriteria: const <String>[
          'لا توجد نتيجة حرجة غير مفسرة في التوريث.',
          'كل عائق له قرار: مغلق / مؤجل / يحتاج مصدر إضافي.',
        ],
      ));
    }

    packages.sort((a, b) => b.priority.compareTo(a.priority));
    return SmartExplorerWorkPackageSet(
      packages: packages,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'نطاق المستكشف الذكي الحالي',
    );
  }

  SmartExplorerLayerRecommendationSet buildLayerRecommendations({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
  }) {
    final items = <SmartExplorerLayerRecommendation>[];
    void addUnique(SmartExplorerLayerRecommendation item) {
      if (items.any((existing) => existing.layerKey == item.layerKey)) return;
      items.add(item);
    }

    if (results.any((item) => !item.hasAnySpatialReference)) {
      addUnique(const SmartExplorerLayerRecommendation(
        layerKey: 'waqf_assets_points_or_centroids',
        titleAr: 'نقاط/مراكز الأصول الوقفية',
        reasonAr: 'يوجد أصول بلا تمثيل مكاني أو تحتاج اختبار مركز مبدئي.',
        whenToUseAr: 'عند فتح النتيجة على الخريطة الحديثة أو تجهيز جولة ميدانية.',
        weight: 92,
        isRequired: true,
      ));
    }
    if (results.any((item) => !item.hasLinkedParcels)) {
      addUnique(const SmartExplorerLayerRecommendation(
        layerKey: 'settlement_parcels',
        titleAr: 'قطع التسوية',
        reasonAr: 'يوجد أصول بلا قطع مرتبطة، ويجب اختبار المطابقة قبل أي اعتماد.',
        whenToUseAr: 'عند مراجعة الربط القطعي أو الأحواض.',
        weight: 88,
        isRequired: true,
      ));
      addUnique(const SmartExplorerLayerRecommendation(
        layerKey: 'natural_blocks_overview',
        titleAr: 'الأحواض الطبيعية/Overview',
        reasonAr: 'يساعد على اختبار قرائن الحوض قبل تحميل التفاصيل الثقيلة.',
        whenToUseAr: 'في الزوم البعيد أو عند البحث بنطاق إداري واسع.',
        weight: 72,
      ));
    }
    if (results.any((item) => item.missingAdministrativeContext)) {
      addUnique(const SmartExplorerLayerRecommendation(
        layerKey: 'modern_admin_boundaries',
        titleAr: 'الحدود الإدارية الحديثة',
        reasonAr: 'بعض النتائج ينقصها محافظة/تجمع/هيئة محلية.',
        whenToUseAr: 'لفحص اتساق السياق الإداري الحديث.',
        weight: 84,
        isRequired: true,
      ));
    }
    if (documentAnalysis != null && documentAnalysis.hasEvidence) {
      addUnique(const SmartExplorerLayerRecommendation(
        layerKey: 'historical_admin_overlays',
        titleAr: 'الطبقات الإدارية التاريخية',
        reasonAr: 'النص يحتوي قرائن وصفية/تاريخية يجب اختبارها ضمن فترتها قبل إسقاطها على الحديث.',
        whenToUseAr: 'عند وجود اسم قرية قديم أو تبعية تاريخية أو وصف حدود.',
        weight: 80,
        isRequired: true,
      ));
      addUnique(const SmartExplorerLayerRecommendation(
        layerKey: 'landmarks_reference',
        titleAr: 'المعالم المرجعية',
        reasonAr: 'الوثيقة قد تذكر طريقًا أو واديًا أو مسجدًا أو مقبرة كقرائن موقع.',
        whenToUseAr: 'لاختبار القرب المكاني لا لاستخلاص موقع قطعي.',
        weight: 68,
      ));
    }
    if (evidenceMatrix != null && evidenceMatrix.hasLinks) {
      addUnique(const SmartExplorerLayerRecommendation(
        layerKey: 'identify_enabled_layers',
        titleAr: 'طبقات Identify/Popup المفعلة',
        reasonAr: 'مصفوفة الأدلة تحتاج فحص حقول الطبقة وربطها بالقرائن.',
        whenToUseAr: 'عند فتح الرابط القوي أو الضعيف على الخريطة.',
        weight: 66,
      ));
    }

    items.sort((a, b) => b.weight.compareTo(a.weight));
    return SmartExplorerLayerRecommendationSet(
      recommendations: items,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'نطاق الخريطة/الوثيقة الحالي',
    );
  }

  SmartExplorerValidationProtocol buildValidationProtocol({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerRiskRegister? riskRegister,
  }) {
    final gates = <SmartExplorerValidationGate>[];
    final hasResults = results.isNotEmpty;
    final noSpatial = results.any((item) => !item.hasAnySpatialReference);
    final noParcels = results.any((item) => !item.hasLinkedParcels);
    final missingReference = results.any((item) => item.missingReferenceContext);

    gates.add(SmartExplorerValidationGate(
      titleAr: 'بوابة مصدر الحقيقة',
      descriptionAr: missingReference
          ? 'توجد نتائج ينقصها رمز وطني أو وقف أم، ولا يجوز استكمالها داخل المستكشف.'
          : 'لا تظهر فجوة مرجعية حرجة ضمن نتائج البحث الحالية.',
      status: missingReference
          ? SmartExplorerValidationStatus.blocked
          : SmartExplorerValidationStatus.pass,
      isBlocking: missingReference,
      requiredEvidenceAr: 'تأكيد من awqaf_system عند نقص الرمز الوطني أو الوقف الأم.',
      nextActionAr: missingReference
          ? 'افتح حزمة استكمال مرجعي أو طلب تدقيق مرجعي.'
          : 'استمر مع الفحص المكاني والتاريخي.',
      domainAr: 'الحوكمة',
    ));

    gates.add(SmartExplorerValidationGate(
      titleAr: 'بوابة التمثيل المكاني',
      descriptionAr: noSpatial
          ? 'توجد أصول بلا تمثيل مكاني؛ لا تصلح للعرض العام كمواضع مؤكدة.'
          : hasResults ? 'كل النتائج الحالية لديها تمثيل مكاني أولي.' : 'لا توجد نتائج لاختبار التمثيل المكاني.',
      status: noSpatial
          ? SmartExplorerValidationStatus.blocked
          : hasResults ? SmartExplorerValidationStatus.pass : SmartExplorerValidationStatus.pending,
      isBlocking: noSpatial,
      requiredEvidenceAr: 'نقطة/مركز/هندسة أو طلب تدقيق يفسر غيابها.',
      nextActionAr: noSpatial
          ? 'أنشئ طلبات تدقيق للأصول بلا تمثيل مكاني.'
          : 'اختبر القرب والتقاطع عند الحاجة.',
      domainAr: 'المكان',
    ));

    gates.add(SmartExplorerValidationGate(
      titleAr: 'بوابة الربط القطعي',
      descriptionAr: noParcels
          ? 'توجد أصول بلا قطع مرتبطة؛ لا تعتمد الملكية/المساحة من الخريطة دون مراجعة.'
          : hasResults ? 'لا تظهر فجوة ربط قطعي في النطاق الحالي.' : 'لا توجد نتائج لاختبار الربط القطعي.',
      status: noParcels
          ? SmartExplorerValidationStatus.warning
          : hasResults ? SmartExplorerValidationStatus.pass : SmartExplorerValidationStatus.pending,
      requiredEvidenceAr: 'مطابقة قطعة/حوض أو سبب موثق لغياب الربط.',
      nextActionAr: noParcels
          ? 'استخدم حزمة مطابقة القطع والأحواض وطبقات التسوية.'
          : 'انتقل إلى فحص الأدلة.',
      domainAr: 'التسوية',
    ));

    final docReady = documentAnalysis != null && documentAnalysis.hasEvidence;
    gates.add(SmartExplorerValidationGate(
      titleAr: 'بوابة الوثيقة والقرائن',
      descriptionAr: docReady
          ? 'الوثيقة تحتوي قرائن قابلة للمراجعة لكنها غير قطعية.'
          : 'لا توجد وثيقة محللة أو لا توجد قرائن كافية.',
      status: docReady
          ? SmartExplorerValidationStatus.warning
          : SmartExplorerValidationStatus.pending,
      requiredEvidenceAr: 'نص الوثيقة، مصدرها، وأسماء القرائن المقبولة/المستبعدة.',
      nextActionAr: docReady
          ? 'أنشئ قاموس مسميات ومصفوفة أدلة.'
          : 'أدخل نص وثيقة أو اترك البوابة مؤجلة.',
      domainAr: 'الوثائق',
    ));

    final evidenceOk = evidenceMatrix != null && evidenceMatrix.strongLinks > 0;
    gates.add(SmartExplorerValidationGate(
      titleAr: 'بوابة مصفوفة الأدلة',
      descriptionAr: evidenceOk
          ? 'توجد روابط قوية قابلة للمراجعة البشرية.'
          : 'لا توجد روابط قوية كافية بين الوثيقة والنتائج.',
      status: evidenceOk
          ? SmartExplorerValidationStatus.warning
          : SmartExplorerValidationStatus.pending,
      requiredEvidenceAr: 'روابط مصفوفة الأدلة مع حقول المطابقة والتعارضات.',
      nextActionAr: evidenceOk
          ? 'افتح الروابط القوية على الخريطة وراجع الضعيفة.'
          : 'أعد البحث أو أدخل قرائن أكثر تحديدًا.',
      domainAr: 'الأدلة',
    ));

    final criticalRisk = riskRegister != null && riskRegister.criticalRisks > 0;
    gates.add(SmartExplorerValidationGate(
      titleAr: 'بوابة المخاطر التشغيلية',
      descriptionAr: criticalRisk
          ? 'توجد مخاطر حرجة يجب إغلاقها أو توثيق تأجيلها.'
          : 'لا تظهر مخاطر حرجة ضمن سجل المخاطر الحالي.',
      status: criticalRisk
          ? SmartExplorerValidationStatus.blocked
          : SmartExplorerValidationStatus.pass,
      isBlocking: criticalRisk,
      requiredEvidenceAr: 'سجل مخاطر محدث وقرار تخفيف/تأجيل لكل خطر حرج.',
      nextActionAr: criticalRisk
          ? 'ابدأ بالمخاطر الحرجة قبل التوريث النهائي.'
          : 'يمكن توليد موجز تنفيذي أو حزمة توريث.',
      domainAr: 'المخاطر',
    ));

    return SmartExplorerValidationProtocol(
      gates: gates,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'نطاق المستكشف الذكي الحالي',
    );
  }

  SmartExplorerKnowledgeCardSet buildKnowledgeCards({
    SmartExplorerDocumentAnalysis? documentAnalysis,
    required List<SmartExplorerResult> results,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
  }) {
    final cards = <SmartExplorerKnowledgeCard>[];
    if (documentAnalysis != null) {
      for (final entity in documentAnalysis.entities.take(20)) {
        cards.add(SmartExplorerKnowledgeCard(
          titleAr: entity.value,
          typeAr: entity.typeLabelAr,
          summaryAr: 'مسمى مستخرج من الوثيقة بدرجة ثقة ${entity.scorePercent}%.',
          confidence: entity.scorePercent,
          sources: <String>['نص الوثيقة', entity.evidence],
          reviewQuestionAr: 'هل يمثل هذا المسمى موقعًا/وقفًا/معلمًا يمكن اختباره على الخريطة؟',
        ));
      }
    }

    for (final result in results.take(20)) {
      cards.add(SmartExplorerKnowledgeCard(
        titleAr: result.titleAr,
        typeAr: 'أصل وقفي',
        summaryAr: result.compactAuditSummary,
        confidence: result.confidenceScore,
        sources: <String>['نتائج البحث في مرجع الأصول', 'قواعد فجوات المستكشف الذكي'],
        reviewQuestionAr: result.needsReview
            ? 'ما الدليل المطلوب لإغلاق فجوات هذا الأصل؟'
            : 'هل تكفي البيانات الحالية لاستخدامه كنقطة سياق؟',
        relatedResultId: result.id,
        relatedResultTitleAr: result.titleAr,
      ));
    }

    if (evidenceMatrix != null) {
      for (final link in evidenceMatrix.topLinks.take(12)) {
        cards.add(SmartExplorerKnowledgeCard(
          titleAr: '${link.entityValue} ↔ ${link.resultTitleAr}',
          typeAr: 'رابط دليل',
          summaryAr: link.recommendationAr,
          confidence: link.matchScore,
          sources: <String>['مصفوفة الأدلة', 'حقول مطابقة: ${link.matchedFields.join('، ')}'],
          reviewQuestionAr: link.hasConflict
              ? 'هل التعارض يمنع استخدام الرابط أم يفتح طلب تدقيق؟'
              : 'هل الرابط قوي بما يكفي لبدء مراجعة بشرية؟',
          relatedResultId: link.resultId,
          relatedResultTitleAr: link.resultTitleAr,
        ));
      }
    }

    cards.sort((a, b) => b.confidence.compareTo(a.confidence));
    return SmartExplorerKnowledgeCardSet(
      cards: cards.take(50).toList(growable: false),
      generatedAt: DateTime.now(),
      scopeLabelAr: 'نطاق المعرفة المؤقتة للمراجعة',
    );
  }

  String buildExecutiveBrief({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerRiskRegister? riskRegister,
    SmartExplorerValidationProtocol? validationProtocol,
    SmartExplorerWorkPackageSet? workPackages,
    SmartExplorerLayerRecommendationSet? layerRecommendations,
    SmartExplorerKnowledgeCardSet? knowledgeCards,
  }) {
    final buffer = StringBuffer()
      ..writeln('موجز تنفيذي — المستكشف الذكي للأوقاف والتاريخ المكاني')
      ..writeln('وقت التوليد: ${DateTime.now().toIso8601String()}')
      ..writeln('النطاق: ${query.trim().isEmpty ? 'غير محدد' : query.trim()}')
      ..writeln('تنبيه: هذا الموجز غير سيادي ولا يعتمد أي تعديل مباشر على الجداول المرجعية.')
      ..writeln('---')
      ..writeln('النتائج: ${results.length}')
      ..writeln('تحتاج مراجعة: ${results.where((item) => item.needsReview).length}')
      ..writeln('بلا تمثيل مكاني: ${results.where((item) => !item.hasAnySpatialReference).length}')
      ..writeln('بلا قطع مرتبطة: ${results.where((item) => !item.hasLinkedParcels).length}');

    if (documentAnalysis != null) {
      buffer
        ..writeln('---')
        ..writeln('تحليل الوثيقة: ${documentAnalysis.summaryAr}')
        ..writeln('ثقة الوثيقة: ${documentAnalysis.confidencePercent}%');
    }

    if (evidenceMatrix != null) {
      buffer
        ..writeln('---')
        ..writeln('الأدلة: ${evidenceMatrix.summaryAr}');
    }

    if (riskRegister != null) {
      buffer
        ..writeln('---')
        ..writeln('المخاطر: ${riskRegister.summaryAr}');
    }

    if (validationProtocol != null) {
      buffer
        ..writeln('---')
        ..writeln('التحقق: ${validationProtocol.summaryAr}');
      for (final gate in validationProtocol.gates) {
        buffer.writeln('- [${gate.status.labelAr}] ${gate.titleAr}: ${gate.nextActionAr}');
      }
    }

    if (workPackages != null) {
      buffer
        ..writeln('---')
        ..writeln('حزم العمل: ${workPackages.summaryAr}');
      for (final item in workPackages.topPackages.take(6)) {
        buffer.writeln('- [${item.priorityLabelAr}] ${item.titleAr}: ${item.expectedOutputAr}');
      }
    }

    if (layerRecommendations != null) {
      buffer
        ..writeln('---')
        ..writeln('الطبقات المقترحة: ${layerRecommendations.summaryAr}');
      for (final item in layerRecommendations.topRecommendations.take(6)) {
        buffer.writeln('- [${item.priorityLabelAr}] ${item.titleAr}: ${item.reasonAr}');
      }
    }

    if (knowledgeCards != null) {
      buffer
        ..writeln('---')
        ..writeln('بطاقات المعرفة: ${knowledgeCards.summaryAr}');
      for (final item in knowledgeCards.topCards.take(8)) {
        buffer.writeln('- ${item.titleAr} (${item.typeAr}) — ${item.confidenceLabelAr}: ${item.reviewQuestionAr}');
      }
    }

    buffer
      ..writeln('---')
      ..writeln('قرار الاستئناف المقترح: نفّذ أول حزمة عمل عاجلة، ثم أعد توليد بروتوكول التحقق والموجز التنفيذي قبل الدمج النهائي.');
    return buffer.toString();
  }



  SmartExplorerInvestigationSession buildInvestigationSession({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    List<SmartExplorerReadinessAssessment> readinessAssessments = const <SmartExplorerReadinessAssessment>[],
    SmartExplorerRiskRegister? riskRegister,
    SmartExplorerValidationProtocol? validationProtocol,
    SmartExplorerWorkPackageSet? workPackages,
  }) {
    final scope = query.trim().isEmpty ? 'نطاق غير محدد' : query.trim();
    final hasResults = results.isNotEmpty;
    final hasDocument = documentAnalysis != null && documentAnalysis.hasEvidence;
    final hasEvidence = evidenceMatrix != null && evidenceMatrix.hasLinks;
    final hasReadiness = readinessAssessments.isNotEmpty;
    final hasRisk = riskRegister != null && !riskRegister.isEmpty;
    final hasValidation = validationProtocol != null && !validationProtocol.isEmpty;
    final hasPackages = workPackages != null && !workPackages.isEmpty;
    final blockers = <String>[];
    if (!hasResults) blockers.add('لا توجد نتائج أصول ضمن النطاق.');
    if (!hasDocument) blockers.add('لا توجد قرائن وثائقية كافية.');
    if (!hasEvidence) blockers.add('لم تُبنَ مصفوفة أدلة تربط الوثيقة بالنتائج.');
    if (hasRisk && riskRegister.overallScore >= 20) blockers.add('سجل المخاطر مرتفع ويحتاج مراجعة.');
    if (hasValidation && validationProtocol.blockingGates > 0) blockers.add('بروتوكول التحقق يحتوي بوابات مانعة.');

    final stages = <SmartExplorerInvestigationStage>[
      SmartExplorerInvestigationStage(
        titleAr: 'تهيئة نطاق البحث',
        status: hasResults ? SmartExplorerStageStatus.ready : SmartExplorerStageStatus.blocked,
        ownerRoleAr: 'مدقق المستكشف',
        reasonAr: hasResults ? 'تم العثور على ${results.length} نتيجة.' : 'لا توجد نتائج بحث كافية بعد.',
        nextActionAr: hasResults ? 'انتقل إلى تحليل الفجوات والأدلة.' : 'ابحث باسم أصل/وقف/رمز وطني أو نطاق إداري.',
        evidence: results.take(5).map((item) => item.titleAr).toList(growable: false),
      ),
      SmartExplorerInvestigationStage(
        titleAr: 'تحليل الوثيقة والقرائن',
        status: hasDocument ? SmartExplorerStageStatus.ready : SmartExplorerStageStatus.pending,
        ownerRoleAr: 'مدقق الوثائق',
        reasonAr: hasDocument ? documentAnalysis.summaryAr : 'لم يتم إدخال أو تحليل نص وثيقة غني بالقرائن.',
        nextActionAr: hasDocument ? 'قارن القرائن مع النتائج الحالية.' : 'أدخل نص وثيقة أو وصف حدود ثم شغل تحليل النص.',
        evidence: documentAnalysis?.spatialHypotheses.take(5).toList(growable: false) ?? const <String>[],
      ),
      SmartExplorerInvestigationStage(
        titleAr: 'مصفوفة الأدلة والمطابقة',
        status: hasEvidence ? SmartExplorerStageStatus.active : SmartExplorerStageStatus.pending,
        ownerRoleAr: 'فريق GIS/التدقيق',
        reasonAr: hasEvidence ? evidenceMatrix.summaryAr : 'لم يتم بناء روابط أدلة بعد.',
        nextActionAr: hasEvidence ? 'راجع أقوى الروابط وأضعفها قبل أي توريث.' : 'شغل مصفوفة الأدلة بعد توفر نتائج ووثيقة.',
        evidence: evidenceMatrix?.links.take(5).map((item) => "${item.entityValue} ↔ ${item.resultTitleAr}").toList(growable: false) ?? const <String>[],
      ),
      SmartExplorerInvestigationStage(
        titleAr: 'تقييم الجاهزية والمخاطر',
        status: hasReadiness || hasRisk ? SmartExplorerStageStatus.active : SmartExplorerStageStatus.pending,
        ownerRoleAr: 'مسؤول الحوكمة',
        reasonAr: hasRisk ? riskRegister.summaryAr : 'تقييم الجاهزية أو المخاطر غير مكتمل.',
        nextActionAr: hasRisk ? 'أغلق البنود الحرجة قبل التوريث.' : 'ولّد تقييم الجاهزية وسجل المخاطر.',
        evidence: blockers,
      ),
      SmartExplorerInvestigationStage(
        titleAr: 'التحقق والإغلاق',
        status: hasValidation && validationProtocol.blockingGates == 0
            ? SmartExplorerStageStatus.ready
            : SmartExplorerStageStatus.blocked,
        ownerRoleAr: 'مدير المستكشف',
        reasonAr: hasValidation ? validationProtocol.summaryAr : 'لم يتم بناء بروتوكول تحقق بعد.',
        nextActionAr: hasPackages ? 'نفذ أول حزم العمل ثم أعد التحقق.' : 'ولّد حزم العمل وبروتوكول التحقق.',
        evidence: validationProtocol?.gates.map((gate) => '${gate.titleAr}: ${gate.status.labelAr}').take(6).toList(growable: false) ?? const <String>[],
      ),
    ];

    return SmartExplorerInvestigationSession(
      sessionId: 'sx-${DateTime.now().millisecondsSinceEpoch}',
      scopeLabelAr: scope,
      generatedAt: DateTime.now(),
      stages: stages,
      nextActionAr: blockers.isNotEmpty
          ? 'ابدأ بإغلاق: ${blockers.first}'
          : 'النطاق جاهز مبدئيًا للتوريث التشغيلي مع اعتماد بشري.',
    );
  }

  SmartExplorerHypothesisComparison buildHypothesisComparison({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
  }) {
    final candidates = <SmartExplorerHypothesisCandidate>[];
    for (final result in results.take(12)) {
      final evidence = <String>[
        ...result.evidenceLines.take(5),
        if (result.hasAnySpatialReference) 'يوجد تمثيل مكاني/مركز قابل للعرض.',
        if (result.hasLinkedParcels) 'يوجد ربط قطع/حوض مبدئي.',
      ];
      final contradictions = <String>[
        if (!result.hasAnySpatialReference) 'لا يوجد تمثيل مكاني كافٍ.',
        if (!result.hasLinkedParcels) 'لا توجد قطع مرتبطة.',
        if (result.missingAdministrativeContext) 'السياق الإداري ناقص.',
        if (result.endowmentName.trim().isEmpty) 'الوقف الأم غير ظاهر.',
      ];
      final score = (result.confidenceScore + result.reviewScore ~/ 3 - contradictions.length * 6).clamp(0, 100).toInt();
      candidates.add(SmartExplorerHypothesisCandidate(
        id: 'asset-${result.id}',
        titleAr: result.titleAr,
        sourceAr: 'نتيجة أصل وقفي من المستكشف',
        score: score,
        recommendedUseAr: contradictions.isEmpty
            ? 'مرشح للعرض والمقارنة بعد مراجعة بشرية.'
            : 'مرشح كتذكرة تدقيق وليس كاعتماد نهائي.',
        evidence: evidence,
        contradictions: contradictions,
      ));
    }

    if (documentAnalysis != null) {
      for (final hypothesis in documentAnalysis.spatialHypotheses.take(8)) {
        candidates.add(SmartExplorerHypothesisCandidate(
          id: 'doc-${candidates.length + 1}',
          titleAr: hypothesis,
          sourceAr: 'فرضية من نص الوثيقة',
          score: documentAnalysis.confidencePercent.clamp(0, 100).toInt(),
          recommendedUseAr: 'تستخدم لتوجيه البحث والخريطة الاحتمالية ولا تعتمد وحدها.',
          evidence: documentAnalysis.entities.take(6).map((entity) => '${entity.value} — ${entity.typeLabelAr}').toList(growable: false),
          contradictions: documentAnalysis.confidencePercent < 55
              ? const <String>['ثقة الوثيقة منخفضة وتحتاج قرائن إضافية.']
              : const <String>[],
        ));
      }
    }

    if (evidenceMatrix != null && evidenceMatrix.hasLinks) {
      for (final link in evidenceMatrix.links.take(8)) {
        candidates.add(SmartExplorerHypothesisCandidate(
          id: 'evidence-${candidates.length + 1}',
          titleAr: "${link.entityValue} ↔ ${link.resultTitleAr}",
          sourceAr: 'رابط مصفوفة أدلة',
          score: link.matchScore.clamp(0, 100).toInt(),
          recommendedUseAr: 'راجع الرابط داخل الخريطة والوثيقة قبل تحويله إلى طلب تدقيق.',
          evidence: link.matchedFields.take(6).toList(growable: false),
          contradictions: link.conflicts.take(4).toList(growable: false),
        ));
      }
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return SmartExplorerHypothesisComparison(
      candidates: candidates.take(30).toList(growable: false),
      generatedAt: DateTime.now(),
      scopeLabelAr: 'نطاق المقارنة الحالي',
    );
  }

  SmartExplorerDataLineage buildDataLineage({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    List<SmartExplorerGazetteerEntry> gazetteerEntries = const <SmartExplorerGazetteerEntry>[],
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    List<SmartExplorerReadinessAssessment> readinessAssessments = const <SmartExplorerReadinessAssessment>[],
    SmartExplorerKnowledgeCardSet? knowledgeCards,
  }) {
    final items = <SmartExplorerLineageItem>[];
    if (results.isNotEmpty) {
      items.add(SmartExplorerLineageItem(
        labelAr: 'نتائج الأصول الوقفية (${results.length})',
        sourceAr: 'WaqfAssetRepository / قراءة من مصادر المستكشف القائمة',
        governance: SmartExplorerLineageGovernance.sovereign,
        allowedUseAr: 'عرض، بحث، انتقال إلى الخريطة والتاريخ، وفتح طلب تدقيق.',
        warningAr: 'لا يتم تعديل الأصل الوقفي من المستكشف الذكي.',
      ));
    }
    if (documentAnalysis != null) {
      items.add(SmartExplorerLineageItem(
        labelAr: 'تحليل نص الوثيقة',
        sourceAr: 'تحليل محلي rule-based داخل الواجهة',
        governance: SmartExplorerLineageGovernance.reviewOnly,
        allowedUseAr: 'اقتراح قرائن ومسميات وفرضيات للمراجعة.',
        warningAr: 'ليس OCR رسميًا ولا اعتمادًا وثائقيًا نهائيًا.',
      ));
    }
    if (gazetteerEntries.isNotEmpty) {
      items.add(SmartExplorerLineageItem(
        labelAr: 'قاموس المسميات المسودة (${gazetteerEntries.length})',
        sourceAr: 'مشتق من الوثيقة والنتائج الحالية',
        governance: SmartExplorerLineageGovernance.derived,
        allowedUseAr: 'بناء قائمة مراجعة للمسميات التاريخية.',
        warningAr: 'لا ينشئ سجل Gazetteer سيادي دون اعتماد لاحق.',
      ));
    }
    if (evidenceMatrix != null) {
      items.add(SmartExplorerLineageItem(
        labelAr: 'مصفوفة الأدلة (${evidenceMatrix.links.length})',
        sourceAr: 'مطابقة محلية بين القرائن والنتائج',
        governance: SmartExplorerLineageGovernance.derived,
        allowedUseAr: 'ترتيب روابط المراجعة وتحديد التعارضات.',
        warningAr: 'تحتاج تحقق GIS/وثائقي قبل أي قرار.',
      ));
    }
    if (readinessAssessments.isNotEmpty) {
      items.add(SmartExplorerLineageItem(
        labelAr: 'تقييم الجاهزية (${readinessAssessments.length})',
        sourceAr: 'حساب داخلي فوق نتائج البحث',
        governance: SmartExplorerLineageGovernance.operational,
        allowedUseAr: 'ترتيب الأولويات والتدقيق الميداني.',
        warningAr: 'لا يمثل اعتمادًا نهائيًا للأصل أو الوقف الأم.',
      ));
    }
    if (knowledgeCards != null && !knowledgeCards.isEmpty) {
      items.add(SmartExplorerLineageItem(
        labelAr: 'بطاقات المعرفة (${knowledgeCards.totalCards})',
        sourceAr: 'تلخيص تشغيلي من المسميات والأصول والأدلة',
        governance: SmartExplorerLineageGovernance.reviewOnly,
        allowedUseAr: 'أسئلة مراجعة ومعرفة مؤقتة للمحقق.',
        warningAr: 'لا تضاف إلى Knowledge Base إلا عبر مسار مراجعة لاحق.',
      ));
    }
    return SmartExplorerDataLineage(
      items: items,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'أثر بيانات المستكشف الذكي',
    );
  }

  SmartExplorerClosureGate buildClosureGate({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerRiskRegister? riskRegister,
    SmartExplorerValidationProtocol? validationProtocol,
    SmartExplorerWorkPackageSet? workPackages,
  }) {
    final gates = <SmartExplorerClosureGateItem>[];
    final hasResults = results.isNotEmpty;
    final hasDocument = documentAnalysis != null && documentAnalysis.hasEvidence;
    final hasEvidence = evidenceMatrix != null && evidenceMatrix.hasLinks;
    final hasRisk = riskRegister != null && !riskRegister.isEmpty;
    final highRisk = hasRisk && riskRegister.overallScore >= 20;
    final validationBlocked = validationProtocol != null && validationProtocol.blockingGates > 0;
    final hasPackages = workPackages != null && !workPackages.isEmpty;

    gates.add(SmartExplorerClosureGateItem(
      titleAr: 'نطاق البحث',
      descriptionAr: hasResults ? 'توجد نتائج ضمن النطاق الحالي.' : 'لا توجد نتائج كافية.',
      status: hasResults ? SmartExplorerClosureGateStatus.pass : SmartExplorerClosureGateStatus.blocked,
      nextActionAr: hasResults ? 'استمر بالتقييم.' : 'نفذ بحثًا أو وسّع النطاق.',
      isBlocking: !hasResults,
    ));
    gates.add(SmartExplorerClosureGateItem(
      titleAr: 'الأدلة الوثائقية',
      descriptionAr: hasDocument ? documentAnalysis.summaryAr : 'لم يتم تحليل وثيقة كافية.',
      status: hasDocument ? SmartExplorerClosureGateStatus.pass : SmartExplorerClosureGateStatus.warning,
      nextActionAr: hasDocument ? 'اربط القرائن بالنتائج.' : 'أدخل وثيقة/وصف حدود أو اعتبر النطاق مكانيًا فقط.',
      isBlocking: false,
    ));
    gates.add(SmartExplorerClosureGateItem(
      titleAr: 'مصفوفة الأدلة',
      descriptionAr: hasEvidence ? evidenceMatrix.summaryAr : 'لا توجد مصفوفة أدلة.',
      status: hasEvidence ? SmartExplorerClosureGateStatus.pass : SmartExplorerClosureGateStatus.warning,
      nextActionAr: hasEvidence ? 'راجع الروابط الأقوى.' : 'ولّد مصفوفة أدلة عند توفر وثيقة ونتائج.',
      isBlocking: false,
    ));
    gates.add(SmartExplorerClosureGateItem(
      titleAr: 'المخاطر التشغيلية',
      descriptionAr: hasRisk ? riskRegister.summaryAr : 'لم يتم بناء سجل مخاطر.',
      status: highRisk ? SmartExplorerClosureGateStatus.blocked : SmartExplorerClosureGateStatus.pass,
      nextActionAr: highRisk ? 'أغلق المخاطر الحرجة قبل التوريث.' : 'استمر مع التنبيه للمخاطر المتوسطة.',
      isBlocking: highRisk,
    ));
    gates.add(SmartExplorerClosureGateItem(
      titleAr: 'بروتوكول التحقق',
      descriptionAr: validationProtocol?.summaryAr ?? 'بروتوكول التحقق غير مولد.',
      status: validationBlocked ? SmartExplorerClosureGateStatus.blocked : SmartExplorerClosureGateStatus.pass,
      nextActionAr: validationBlocked ? 'أغلق البوابات المانعة.' : 'وثّق نتائج التحقق قبل أي اعتماد.',
      isBlocking: validationBlocked,
    ));
    gates.add(SmartExplorerClosureGateItem(
      titleAr: 'حزم العمل',
      descriptionAr: hasPackages ? workPackages.summaryAr : 'حزم العمل غير مولدة.',
      status: hasPackages ? SmartExplorerClosureGateStatus.pass : SmartExplorerClosureGateStatus.warning,
      nextActionAr: hasPackages ? 'ابدأ بأعلى حزمة أولوية.' : 'ولّد حزم العمل لتحديد مسار الإغلاق.',
      isBlocking: false,
    ));

    var score = 100;
    score -= gates.where((gate) => gate.status == SmartExplorerClosureGateStatus.blocked).length * 22;
    score -= gates.where((gate) => gate.status == SmartExplorerClosureGateStatus.warning).length * 10;
    score -= results.where((item) => item.needsReview).take(10).length * 2;
    score = score.clamp(0, 100).toInt();

    return SmartExplorerClosureGate(
      gates: gates,
      readinessScore: score,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'إغلاق تشغيلي للنطاق الحالي',
    );
  }

  SmartExplorerActionPlan buildActionPlan({
    required List<SmartExplorerResult> results,
    SmartExplorerFieldChecklist? fieldChecklist,
    SmartExplorerWorkPackageSet? workPackages,
    SmartExplorerValidationProtocol? validationProtocol,
    SmartExplorerClosureGate? closureGate,
    SmartExplorerRiskRegister? riskRegister,
  }) {
    final items = <SmartExplorerActionPlanItem>[];

    for (final result in results.where((item) => item.needsReview).take(10)) {
      items.add(SmartExplorerActionPlanItem(
        titleAr: 'إغلاق مراجعة ${result.titleAr}',
        domainAr: 'الأصول الوقفية',
        actionAr: result.recommendedActionAr,
        requiredEvidenceAr: result.evidenceLines.take(3).join(' | '),
        acceptanceCriteriaAr: 'توثيق القرار البشري وتحويله إلى طلب تدقيق عند الحاجة دون تعديل سيادي مباشر.',
        ownerRoleAr: 'مدقق مستكشف الوقف',
        priority: result.reviewScore.clamp(35, 100).toInt(),
        status: result.hasAnySpatialReference
            ? SmartExplorerActionStatus.pendingEvidence
            : SmartExplorerActionStatus.blocked,
        relatedResultId: result.id,
        relatedResultTitleAr: result.titleAr,
      ));
    }

    for (final item in fieldChecklist?.topItems.take(8) ?? const <SmartExplorerFieldChecklistItem>[]) {
      items.add(SmartExplorerActionPlanItem(
        titleAr: item.titleAr,
        domainAr: item.domainAr,
        actionAr: item.instructionAr,
        requiredEvidenceAr: item.evidenceRequiredAr,
        acceptanceCriteriaAr: 'إرفاق الدليل المطلوب وتحديث حالة طلب التدقيق المرتبط.',
        ownerRoleAr: item.requiresPhoto ? 'فريق التدقيق الميداني' : 'مدقق الوثائق',
        priority: item.priority,
        status: item.requiresPhoto || item.requiresDocumentReview
            ? SmartExplorerActionStatus.pendingEvidence
            : SmartExplorerActionStatus.ready,
        relatedResultId: item.resultId,
        relatedResultTitleAr: item.resultTitleAr,
      ));
    }

    for (final package in workPackages?.topPackages.take(6) ?? const <SmartExplorerWorkPackage>[]) {
      items.add(SmartExplorerActionPlanItem(
        titleAr: package.titleAr,
        domainAr: package.domainAr,
        actionAr: package.actions.take(3).join(' | '),
        requiredEvidenceAr: package.acceptanceCriteria.take(3).join(' | '),
        acceptanceCriteriaAr: package.expectedOutputAr,
        ownerRoleAr: package.ownerRoleAr,
        priority: package.priority,
        status: SmartExplorerActionStatus.ready,
      ));
    }

    if (validationProtocol != null) {
      for (final gate in validationProtocol.gates.where((gate) => gate.isBlocking).take(5)) {
        items.add(SmartExplorerActionPlanItem(
          titleAr: 'إغلاق بوابة تحقق: ${gate.titleAr}',
          domainAr: gate.domainAr,
          actionAr: gate.nextActionAr,
          requiredEvidenceAr: gate.requiredEvidenceAr,
          acceptanceCriteriaAr: 'تحويل حالة البوابة من مانعة إلى مقبولة أو تحذيرية بعد المراجعة.',
          ownerRoleAr: 'مشرف جودة البيانات',
          priority: 90,
          status: SmartExplorerActionStatus.blocked,
        ));
      }
    }

    if (closureGate != null && closureGate.blockingCount > 0) {
      items.add(SmartExplorerActionPlanItem(
        titleAr: 'منع التوريث قبل إغلاق بوابة الإغلاق',
        domainAr: 'حوكمة التشغيل',
        actionAr: closureGate.summaryAr,
        requiredEvidenceAr: 'تقرير بوابة الإغلاق وسجل المخاطر وبروتوكول التحقق.',
        acceptanceCriteriaAr: 'عدم وجود موانع قبل تسليم النطاق كجاهز للتكامل.',
        ownerRoleAr: 'مدير مستكشف الوقف',
        priority: 95,
        status: SmartExplorerActionStatus.blocked,
      ));
    }

    if (riskRegister != null && riskRegister.overallScore >= 12) {
      items.add(SmartExplorerActionPlanItem(
        titleAr: 'خفض مستوى المخاطر التشغيلية',
        domainAr: 'المخاطر',
        actionAr: riskRegister.summaryAr,
        requiredEvidenceAr: 'إغلاق أعلى المخاطر وتوثيق المعالجة.',
        acceptanceCriteriaAr: 'انخفاض التقييم العام إلى متوسط أو منخفض قبل الإغلاق.',
        ownerRoleAr: 'مشرف المراجعة',
        priority: riskRegister.overallScore >= 20 ? 92 : 76,
        status: SmartExplorerActionStatus.pendingEvidence,
      ));
    }

    return SmartExplorerActionPlan(
      items: items,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'خطة إجراءات تشغيلية للمستكشف الذكي',
    );
  }

  SmartExplorerStakeholderMatrix buildStakeholderMatrix({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerRiskRegister? riskRegister,
    SmartExplorerClosureGate? closureGate,
  }) {
    final items = <SmartExplorerStakeholderItem>[
      const SmartExplorerStakeholderItem(
        roleAr: 'مدقق مستكشف الوقف',
        responsibilityAr: 'مراجعة نتائج البحث وإشارات الفجوات وتحويل المناسب إلى طلبات تدقيق.',
        inputNeededAr: 'نتائج الأصول، إشارات الفجوات، التقرير التشغيلي.',
        outputExpectedAr: 'قرار مراجعة أو طلب تدقيق غير سيادي.',
        reviewStageAr: 'المراجعة الأولى',
      ),
      const SmartExplorerStakeholderItem(
        roleAr: 'مشرف GIS',
        responsibilityAr: 'اختبار الفرضيات على الطبقات والحدود ونتائج Identify/Popup.',
        inputNeededAr: 'الأصل، الهندسة/المركز، الطبقات المقترحة، مصفوفة الأدلة.',
        outputExpectedAr: 'تعليق مكاني أو توصية ربط/تصحيح.',
        reviewStageAr: 'التحقق المكاني',
      ),
      const SmartExplorerStakeholderItem(
        roleAr: 'مدقق الوثائق التاريخية',
        responsibilityAr: 'تدقيق المسميات والقرائن النصية والحدود الوصفية.',
        inputNeededAr: 'نص الوثيقة، القاموس المسودة، القرائن والفرضيات.',
        outputExpectedAr: 'تصنيف الدليل ودرجة الثقة وملاحظات الاستكمال.',
        reviewStageAr: 'مراجعة الوثيقة',
      ),
      const SmartExplorerStakeholderItem(
        roleAr: 'مشرف جودة البيانات',
        responsibilityAr: 'التمييز بين المخرجات المشتقة والمصادر السيادية ومراقبة عدم الخلط.',
        inputNeededAr: 'أثر البيانات، بروتوكول التحقق، بوابة الإغلاق.',
        outputExpectedAr: 'قرار جاهزية للتوريث أو إعادة فتح المراجعة.',
        reviewStageAr: 'حوكمة الجودة',
        needsApproval: true,
      ),
    ];

    if (results.any((item) => !item.hasLinkedParcels)) {
      items.add(const SmartExplorerStakeholderItem(
        roleAr: 'فريق مطابقة القطع والأحواض',
        responsibilityAr: 'مراجعة ربط الأصل بالحوض/القطعة أو سبب غياب الربط.',
        inputNeededAr: 'الأصل، الرمز الوطني، الحوض، القطعة، الطبقات المقترحة.',
        outputExpectedAr: 'مطابقة مقترحة أو توصية استكمال.',
        reviewStageAr: 'مطابقة القطع',
      ));
    }
    if (documentAnalysis != null && documentAnalysis.hasEvidence) {
      items.add(const SmartExplorerStakeholderItem(
        roleAr: 'خبير التاريخ الوقفي',
        responsibilityAr: 'مراجعة العلاقات التاريخية بين الوقف الأم والمكان والمرحلة الزمنية.',
        inputNeededAr: 'قرائن الوثيقة، المسميات، الفرضيات، السلالة التاريخية.',
        outputExpectedAr: 'رأي تاريخي غير سيادي يدعم أو يضعف الفرضية.',
        reviewStageAr: 'المراجعة التاريخية',
      ));
    }
    if ((riskRegister?.overallScore ?? 0) >= 12 || (closureGate?.blockingCount ?? 0) > 0) {
      items.add(const SmartExplorerStakeholderItem(
        roleAr: 'مدير مستكشف الوقف',
        responsibilityAr: 'اعتماد مسار الإغلاق التشغيلي أو إعادة النطاق للمراجعة.',
        inputNeededAr: 'سجل المخاطر، بوابة الإغلاق، خطة الإجراءات.',
        outputExpectedAr: 'قرار توريث/تأجيل/تصعيد.',
        reviewStageAr: 'قرار الإغلاق',
        needsApproval: true,
      ));
    }
    if (evidenceMatrix != null && evidenceMatrix.hasLinks) {
      items.add(const SmartExplorerStakeholderItem(
        roleAr: 'فريق الأدلة والمطابقة',
        responsibilityAr: 'تدقيق روابط القرائن مع الأصول واكتشاف التعارضات.',
        inputNeededAr: 'مصفوفة الأدلة وروابطها الأعلى ثقة.',
        outputExpectedAr: 'اعتماد رابط كفرضية مراجعة أو رفضه.',
        reviewStageAr: 'تدقيق الأدلة',
      ));
    }

    return SmartExplorerStakeholderMatrix(
      items: items,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'أصحاب علاقة مراجعة المستكشف الذكي',
    );
  }

  SmartExplorerDecisionLog buildDecisionLog({
    required List<SmartExplorerResult> results,
    SmartExplorerDecisionBoard? decisionBoard,
    SmartExplorerClosureGate? closureGate,
    SmartExplorerActionPlan? actionPlan,
  }) {
    final entries = <SmartExplorerDecisionLogEntry>[];
    for (final item in decisionBoard?.topItems.take(8) ?? const <SmartExplorerDecisionItem>[]) {
      entries.add(SmartExplorerDecisionLogEntry(
        titleAr: item.titleAr,
        rationaleAr: item.descriptionAr,
        impactAr: item.domainAr,
        nextStepAr: item.actionAr,
        status: item.isUrgent
            ? SmartExplorerDecisionLogStatus.acceptedForReview
            : SmartExplorerDecisionLogStatus.proposed,
      ));
    }

    if (closureGate != null) {
      entries.add(SmartExplorerDecisionLogEntry(
        titleAr: 'قرار بوابة الإغلاق',
        rationaleAr: closureGate.summaryAr,
        impactAr: closureGate.canProceed ? 'يمكن التوريث مع حفظ التحفظات.' : 'لا يتم التوريث قبل إغلاق الموانع.',
        nextStepAr: closureGate.canProceed ? 'تجهيز حزمة التسليم.' : 'تنفيذ خطة الإجراءات وإعادة التقييم.',
        status: closureGate.canProceed
            ? SmartExplorerDecisionLogStatus.acceptedForReview
            : SmartExplorerDecisionLogStatus.blocked,
      ));
    }

    if (actionPlan != null && !actionPlan.isEmpty) {
      entries.add(SmartExplorerDecisionLogEntry(
        titleAr: 'اعتماد خطة الإجراءات كمخرج مراجعة',
        rationaleAr: actionPlan.summaryAr,
        impactAr: 'تنظيم العمل دون إنشاء تعديل سيادي مباشر.',
        nextStepAr: 'تنفيذ البنود الأعلى أولوية وتحويل الجاهز إلى طلبات تدقيق.',
        status: SmartExplorerDecisionLogStatus.proposed,
      ));
    }

    if (results.isEmpty) {
      entries.add(const SmartExplorerDecisionLogEntry(
        titleAr: 'لا توجد نتائج بحث كافية',
        rationaleAr: 'النطاق الحالي لا يحتوي نتائج أصل وقفي قابلة للتحليل.',
        impactAr: 'لا يمكن بناء قرار تشغيلي متين.',
        nextStepAr: 'توسيع البحث أو إدخال وثيقة/قرائن مكانية.',
        status: SmartExplorerDecisionLogStatus.deferred,
      ));
    }

    return SmartExplorerDecisionLog(
      entries: entries,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'سجل قرارات تشغيلية للمستكشف الذكي',
    );
  }

  SmartExplorerQualityScorecard buildQualityScorecard({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerReadinessAssessment? weakestReadiness,
    SmartExplorerRiskRegister? riskRegister,
    SmartExplorerClosureGate? closureGate,
  }) {
    final items = <SmartExplorerQualityScoreItem>[];
    final total = results.length;
    final withSpatial = results.where((item) => item.hasAnySpatialReference).length;
    final withParcels = results.where((item) => item.hasLinkedParcels).length;
    final withEndowment = results.where((item) => item.endowmentName.trim().isNotEmpty).length;
    final avgConfidence = total == 0
        ? 0
        : (results.fold<int>(0, (sum, item) => sum + item.confidenceScore) / total).round();

    items.add(SmartExplorerQualityScoreItem(
      titleAr: 'ثقة نتائج البحث',
      score: avgConfidence.clamp(0, 100).toInt(),
      noteAr: total == 0 ? 'لا توجد نتائج.' : 'متوسط الثقة المحسوب من $total نتيجة.',
      nextActionAr: avgConfidence >= 70 ? 'استمر بالمراجعة.' : 'وسّع البحث أو أضف قرائن وثائقية.',
    ));
    items.add(SmartExplorerQualityScoreItem(
      titleAr: 'التمثيل المكاني',
      score: total == 0 ? 0 : ((withSpatial / total) * 100).round(),
      noteAr: '$withSpatial من $total نتائج لها تمثيل مكاني أو مركز.',
      nextActionAr: 'أغلق فجوات الأصول بلا تمثيل مكاني عبر طلبات تدقيق.',
      relatedSeverity: SmartExplorerSignalSeverity.critical,
    ));
    items.add(SmartExplorerQualityScoreItem(
      titleAr: 'الربط بالقطع/الأحواض',
      score: total == 0 ? 0 : ((withParcels / total) * 100).round(),
      noteAr: '$withParcels من $total نتائج لها قطع مرتبطة.',
      nextActionAr: 'راجع الأصول بلا قطع عبر طبقات التسوية والأحواض.',
      relatedSeverity: SmartExplorerSignalSeverity.high,
    ));
    items.add(SmartExplorerQualityScoreItem(
      titleAr: 'الوقف الأم والسياق المرجعي',
      score: total == 0 ? 0 : ((withEndowment / total) * 100).round(),
      noteAr: '$withEndowment من $total نتائج يظهر فيها الوقف الأم.',
      nextActionAr: 'استكمل الربط المرجعي من awqaf_system فقط.',
    ));
    items.add(SmartExplorerQualityScoreItem(
      titleAr: 'الأدلة الوثائقية',
      score: documentAnalysis == null ? 35 : documentAnalysis.confidencePercent.clamp(0, 100).toInt(),
      noteAr: documentAnalysis == null ? 'لم يتم تحليل وثيقة.' : documentAnalysis.summaryAr,
      nextActionAr: 'أضف وثيقة أو وصف حدود ثم اربطها بمصفوفة الأدلة.',
    ));
    items.add(SmartExplorerQualityScoreItem(
      titleAr: 'مصفوفة الأدلة',
      score: evidenceMatrix == null
          ? 35
          : (evidenceMatrix.strongLinks * 18 + evidenceMatrix.links.where((item) => item.matchScore >= 40 && item.matchScore < 70).length * 10).clamp(35, 100).toInt(),
      noteAr: evidenceMatrix == null ? 'لا توجد مصفوفة أدلة.' : evidenceMatrix.summaryAr,
      nextActionAr: 'راجع الروابط الضعيفة والتعارضات قبل التوريث.',
    ));
    if (riskRegister != null) {
      final riskScore = (100 - (riskRegister.overallScore * 4)).clamp(0, 100).toInt();
      items.add(SmartExplorerQualityScoreItem(
        titleAr: 'المخاطر التشغيلية',
        score: riskScore,
        noteAr: riskRegister.summaryAr,
        nextActionAr: 'أغلق المخاطر الحرجة قبل اعتماد النطاق كمغلق.',
      ));
    }
    if (closureGate != null) {
      items.add(SmartExplorerQualityScoreItem(
        titleAr: 'بوابة الإغلاق',
        score: closureGate.readinessScore.clamp(0, 100).toInt(),
        noteAr: closureGate.summaryAr,
        nextActionAr: closureGate.canProceed ? 'جهز حزمة التوريث.' : 'أغلق الموانع ثم أعد التقييم.',
      ));
    }
    if (weakestReadiness != null) {
      items.add(SmartExplorerQualityScoreItem(
        titleAr: 'أضعف جاهزية تفصيلية',
        score: weakestReadiness.overallScore.clamp(0, 100).toInt(),
        noteAr: '${weakestReadiness.titleAr} — ${weakestReadiness.readinessLabelAr}',
        nextActionAr: weakestReadiness.nextActions.isEmpty
            ? 'راجع العوائق التفصيلية قبل التوريث.'
            : weakestReadiness.nextActions.take(3).join(' | '),
      ));
    }

    final overall = items.isEmpty
        ? 0
        : (items.fold<int>(0, (sum, item) => sum + item.score) / items.length).round();
    return SmartExplorerQualityScorecard(
      items: items,
      overallScore: overall.clamp(0, 100).toInt(),
      generatedAt: DateTime.now(),
      scopeLabelAr: 'بطاقة جودة تشغيلية للنطاق الحالي',
    );
  }

  SmartExplorerReviewWorkflow buildReviewWorkflow({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerClosureGate? closureGate,
    SmartExplorerActionPlan? actionPlan,
  }) {
    final hasResults = results.isNotEmpty;
    final hasDocument = documentAnalysis != null && documentAnalysis.hasEvidence;
    final hasEvidence = evidenceMatrix != null && evidenceMatrix.hasLinks;
    final score = qualityScorecard?.overallScore ?? 0;
    final blocked = closureGate != null && !closureGate.canProceed;
    final steps = <SmartExplorerReviewWorkflowStep>[
      SmartExplorerReviewWorkflowStep(
        order: 1,
        titleAr: 'تثبيت نطاق البحث',
        ownerRoleAr: 'مدقق مستكشف الوقف',
        inputAr: 'عبارة البحث ونتائج الأصول الحالية.',
        outputAr: 'نطاق مراجعة محدد وقابل للتكرار.',
        exitCriteriaAr: 'وجود نتائج أو قرار واضح بتوسيع النطاق.',
        status: hasResults ? SmartExplorerWorkflowStatus.ready : SmartExplorerWorkflowStatus.blocked,
      ),
      SmartExplorerReviewWorkflowStep(
        order: 2,
        titleAr: 'تدقيق التمثيل المكاني والقطع',
        ownerRoleAr: 'مشرف GIS / فريق مطابقة القطع',
        inputAr: 'إشارات الفجوات والطبقات المقترحة ونتائج Identify.',
        outputAr: 'قرار ربط/استكمال/رفض فرضية مكانية.',
        exitCriteriaAr: 'إغلاق الأصول بلا تمثيل أو بلا قطع بطلبات تدقيق.',
        status: results.any((item) => !item.hasAnySpatialReference || !item.hasLinkedParcels)
            ? SmartExplorerWorkflowStatus.waitingInput
            : SmartExplorerWorkflowStatus.ready,
      ),
      SmartExplorerReviewWorkflowStep(
        order: 3,
        titleAr: 'مراجعة الوثيقة والقرائن',
        ownerRoleAr: 'مدقق الوثائق التاريخية',
        inputAr: 'نص الوثيقة، المسميات، قرائن الحدود والاتجاهات.',
        outputAr: 'قائمة قرائن مصنفة حسب الثقة.',
        exitCriteriaAr: 'تحويل القرائن إلى مصفوفة أدلة أو توثيق سبب ضعفها.',
        status: hasDocument ? SmartExplorerWorkflowStatus.ready : SmartExplorerWorkflowStatus.waitingInput,
      ),
      SmartExplorerReviewWorkflowStep(
        order: 4,
        titleAr: 'مقارنة الأدلة والفرضيات',
        ownerRoleAr: 'فريق الأدلة والمطابقة',
        inputAr: 'مصفوفة الأدلة ومقارنة الفرضيات.',
        outputAr: 'فرضية مرجحة أو قائمة تعارضات.',
        exitCriteriaAr: 'توثيق سبب الترجيح أو الرفض.',
        status: hasEvidence ? SmartExplorerWorkflowStatus.ready : SmartExplorerWorkflowStatus.waitingInput,
      ),
      SmartExplorerReviewWorkflowStep(
        order: 5,
        titleAr: 'قرار الجودة والإغلاق',
        ownerRoleAr: 'مشرف جودة البيانات / مدير مستكشف الوقف',
        inputAr: 'بطاقة الجودة، بوابة الإغلاق، خطة الإجراءات.',
        outputAr: 'توريث تشغيلي أو إعادة فتح مراجعة.',
        exitCriteriaAr: 'لا توجد موانع عالية أو حرجة دون خطة معالجة.',
        status: blocked || score < 55 ? SmartExplorerWorkflowStatus.blocked : SmartExplorerWorkflowStatus.ready,
      ),
      SmartExplorerReviewWorkflowStep(
        order: 6,
        titleAr: 'تحويل الجاهز إلى طلبات تدقيق',
        ownerRoleAr: 'مدقق مستكشف الوقف',
        inputAr: 'خطة الإجراءات وسجل القرارات.',
        outputAr: 'طلبات تدقيق عبر المسار الحالي فقط.',
        exitCriteriaAr: 'كل بند جاهز له طلب أو ملاحظة توريث.',
        status: actionPlan != null && !actionPlan.isEmpty
            ? SmartExplorerWorkflowStatus.ready
            : SmartExplorerWorkflowStatus.reviewOnly,
      ),
    ];
    return SmartExplorerReviewWorkflow(
      steps: steps,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'مسار مراجعة تشغيلية للنطاق الحالي',
    );
  }

  SmartExplorerAssumptionLedger buildAssumptionLedger({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerHypothesisComparison? hypothesisComparison,
  }) {
    final items = <SmartExplorerAssumptionItem>[];
    for (final result in results.where((item) => item.needsReview).take(10)) {
      items.add(SmartExplorerAssumptionItem(
        assumptionAr: 'الأصل "${result.titleAr}" قابل للإغلاق عبر ${result.recommendedActionAr}',
        sourceAr: 'إشارات الفجوات في نتائج البحث',
        reasonAr: 'الاستنتاج مبني على حقول ظاهرة وليس على مراجعة بشرية أو وثيقة معتمدة.',
        verificationAr: 'افتح الخريطة والطبقات المقترحة وأنشئ طلب تدقيق عند الحاجة.',
        impactIfWrongAr: 'قد يؤدي إلى ربط مكاني أو مرجعي غير دقيق إن عومل كحقيقة.',
        riskLevel: result.reviewScore.clamp(35, 95).toInt(),
      ));
    }
    if (documentAnalysis != null) {
      for (final hypothesis in documentAnalysis.spatialHypotheses.take(6)) {
        items.add(SmartExplorerAssumptionItem(
          assumptionAr: hypothesis,
          sourceAr: 'تحليل نص الوثيقة',
          reasonAr: 'الفرضية مستخرجة من نص وصفي وقد تحتوي أسماء أو حدود غير موحدة.',
          verificationAr: 'اربطها بقاموس المسميات ومصفوفة الأدلة ثم اعرضها على خبير تاريخي.',
          impactIfWrongAr: 'قد توجه البحث إلى نطاق مكاني غير صحيح.',
          riskLevel: documentAnalysis.confidencePercent < 60 ? 78 : 58,
        ));
      }
    }
    if (evidenceMatrix != null) {
      for (final link in evidenceMatrix.links.where((item) => item.matchScore < 60).take(6)) {
        items.add(SmartExplorerAssumptionItem(
          assumptionAr: 'وجود علاقة محتملة بين "${link.entityValue}" و"${link.resultTitleAr}"',
          sourceAr: 'مصفوفة الأدلة',
          reasonAr: 'درجة المطابقة دون مستوى الثقة العالي.',
          verificationAr: 'راجع الحقول المطابقة والتعارضات قبل تحويلها إلى طلب تدقيق.',
          impactIfWrongAr: 'قد يربط دليلًا وثائقيًا بأصل غير مقصود.',
          riskLevel: 70,
        ));
      }
    }
    if (hypothesisComparison != null) {
      for (final item in hypothesisComparison.candidates.take(4)) {
        items.add(SmartExplorerAssumptionItem(
          assumptionAr: item.titleAr,
          sourceAr: 'مقارنة الفرضيات',
          reasonAr: item.contradictions.isEmpty ? 'لا توجد تعارضات مسجلة، لكن الفرضية بحاجة مراجعة.' : item.contradictions.take(3).join(' | '),
          verificationAr: 'راجع الأدلة المؤيدة والمعارضة قبل الترجيح.',
          impactIfWrongAr: 'قد يتم توريث فرضية أقل قوة من بدائلها.',
          riskLevel: item.score < 60 ? 76 : 52,
        ));
      }
    }
    return SmartExplorerAssumptionLedger(
      items: items,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'سجل افتراضات مراجعة للنطاق الحالي',
    );
  }

  SmartExplorerCrossSystemBridgePlan buildCrossSystemBridgePlan({
    required List<SmartExplorerResult> results,
    SmartExplorerActionPlan? actionPlan,
    SmartExplorerClosureGate? closureGate,
    SmartExplorerExportBundle? exportBundle,
  }) {
    final hasResults = results.isNotEmpty;
    final needsReview = results.any((item) => item.needsReview);
    final hasActions = actionPlan != null && !actionPlan.isEmpty;
    final canProceed = closureGate == null || closureGate.canProceed;
    final items = <SmartExplorerCrossSystemBridgeItem>[
      SmartExplorerCrossSystemBridgeItem(
        systemLabelAr: 'Mustakshif / الخريطة الحديثة',
        bridgeChannelAr: 'فتح النتيجة على الخريطة أو Identify/Popup',
        inputAr: 'assetId أو عبارة البحث وطبقات الفحص المقترحة.',
        outputAr: 'تحقق بصري/مكاني وقرار مراجعة.',
        activationConditionAr: hasResults ? 'متاح فور وجود نتائج.' : 'يتطلب نتائج بحث.',
        guardrailAr: 'لا يتم تعديل هندسة أو طبقة من هذه الصفحة.',
        status: hasResults ? SmartExplorerBridgeStatus.ready : SmartExplorerBridgeStatus.blocked,
      ),
      SmartExplorerCrossSystemBridgeItem(
        systemLabelAr: 'History Explorer',
        bridgeChannelAr: 'فتح سياق waqf في مستكشف التاريخ',
        inputAr: 'الأصل الوقفي أو الوقف الأم أو قرائن الوثيقة.',
        outputAr: 'مراجعة السلالة التاريخية والمرحلة الإدارية.',
        activationConditionAr: hasResults ? 'متاح من تفاصيل النتيجة.' : 'يتطلب أصلًا أو قرينة.',
        guardrailAr: 'المخرجات تاريخية/تحليلية وليست تحديثًا سياديًا.',
        status: hasResults ? SmartExplorerBridgeStatus.ready : SmartExplorerBridgeStatus.pendingContract,
      ),
      const SmartExplorerCrossSystemBridgeItem(
        systemLabelAr: 'awqaf_system',
        bridgeChannelAr: 'قراءة مصدر الحقيقة فقط',
        inputAr: 'waqf_asset_id أو national_asset_code.',
        outputAr: 'مراجعة مرجعية للوقف الأم والأصل.',
        activationConditionAr: 'بعد اعتماد RPC/Repo قراءة مناسبة.',
        guardrailAr: 'لا يكتب المستكشف الذكي في waqf_assets أو endowments.',
        status: SmartExplorerBridgeStatus.pendingContract,
      ),
      SmartExplorerCrossSystemBridgeItem(
        systemLabelAr: 'Explorer Gap Audits',
        bridgeChannelAr: 'إنشاء طلب تدقيق عبر المسار الحالي',
        inputAr: 'نتيجة ذكية أو بند من خطة الإجراءات.',
        outputAr: 'طلب تدقيق قابل للمراجعة.',
        activationConditionAr: needsReview || hasActions ? 'متاح عند وجود فجوات أو إجراءات.' : 'يتطلب فجوات مراجعة.',
        guardrailAr: 'طلب التدقيق لا يعدل مصدر الحقيقة.',
        status: (needsReview || hasActions) ? SmartExplorerBridgeStatus.ready : SmartExplorerBridgeStatus.later,
      ),
      const SmartExplorerCrossSystemBridgeItem(
        systemLabelAr: 'tasks_system',
        bridgeChannelAr: 'تحويل لاحق لمهمة تشغيلية',
        inputAr: 'حزمة تسليم أو خطة إجراءات.',
        outputAr: 'مهمة متابعة عند تثبيت عقد tasks_system.',
        activationConditionAr: 'بعد تثبيت عقد المهام والصلاحيات.',
        guardrailAr: 'مؤجل ولا يتم إنشاؤه من هذه الدفعة.',
        status: SmartExplorerBridgeStatus.later,
      ),
      SmartExplorerCrossSystemBridgeItem(
        systemLabelAr: 'الأرشفة/المعرفة',
        bridgeChannelAr: 'حفظ لاحق لحزمة التصدير كمصدر مراجعة',
        inputAr: exportBundle == null ? 'حزمة تسليم غير مولدة.' : 'حزمة تسليم نصية جاهزة.',
        outputAr: 'مرجع معرفة قابل للفهرسة لاحقًا.',
        activationConditionAr: canProceed ? 'بعد مراجعة بشرية.' : 'بعد إغلاق بوابة الإغلاق.',
        guardrailAr: 'لا يتم التخزين الآلي قبل اعتماد مسار المعرفة.',
        status: exportBundle == null ? SmartExplorerBridgeStatus.pendingContract : SmartExplorerBridgeStatus.ready,
      ),
    ];
    return SmartExplorerCrossSystemBridgePlan(
      items: items,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'خطة ربط تشغيلية غير منفذة',
    );
  }

  SmartExplorerExportBundle buildExportBundle({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerActionPlan? actionPlan,
    SmartExplorerStakeholderMatrix? stakeholderMatrix,
    SmartExplorerDecisionLog? decisionLog,
    SmartExplorerClosureGate? closureGate,
    SmartExplorerDataLineage? dataLineage,
    String? finalIntegrationMemoText,
    String? handoffPacketText,
    String? executiveBriefText,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerReviewWorkflow? reviewWorkflow,
    SmartExplorerAssumptionLedger? assumptionLedger,
    SmartExplorerCrossSystemBridgePlan? crossSystemBridgePlan,
  }) {
    final scopeText = query.trim().isEmpty ? 'غير محدد' : query.trim();
    final sections = <SmartExplorerExportSection>[
      SmartExplorerExportSection(
        titleAr: 'ملخص النطاق',
        bodyAr: <String>[
          'النطاق: $scopeText',
          'عدد النتائج: ${results.length}',
          'تحتاج مراجعة: ${results.where((item) => item.needsReview).length}',
        ].join('\n'),
      ),
    ];
    if (executiveBriefText != null && executiveBriefText.trim().isNotEmpty) {
      sections.add(SmartExplorerExportSection(titleAr: 'الموجز التنفيذي', bodyAr: executiveBriefText));
    }
    if (actionPlan != null) {
      sections.add(SmartExplorerExportSection(titleAr: 'خطة الإجراءات', bodyAr: actionPlan.toReportText()));
    }
    if (stakeholderMatrix != null) {
      sections.add(SmartExplorerExportSection(titleAr: 'مصفوفة أصحاب العلاقة', bodyAr: stakeholderMatrix.toReportText()));
    }
    if (decisionLog != null) {
      sections.add(SmartExplorerExportSection(titleAr: 'سجل القرارات', bodyAr: decisionLog.toReportText()));
    }
    if (closureGate != null) {
      sections.add(SmartExplorerExportSection(titleAr: 'بوابة الإغلاق', bodyAr: closureGate.toReportText()));
    }
    if (dataLineage != null) {
      sections.add(SmartExplorerExportSection(titleAr: 'أثر البيانات', bodyAr: dataLineage.toReportText()));
    }
    if (finalIntegrationMemoText != null && finalIntegrationMemoText.trim().isNotEmpty) {
      sections.add(SmartExplorerExportSection(titleAr: 'مذكرة الدمج', bodyAr: finalIntegrationMemoText));
    }
    if (qualityScorecard != null) {
      sections.add(SmartExplorerExportSection(titleAr: 'بطاقة الجودة', bodyAr: qualityScorecard.toReportText()));
    }
    if (reviewWorkflow != null) {
      sections.add(SmartExplorerExportSection(titleAr: 'مسار المراجعة', bodyAr: reviewWorkflow.toReportText()));
    }
    if (assumptionLedger != null) {
      sections.add(SmartExplorerExportSection(titleAr: 'سجل الافتراضات', bodyAr: assumptionLedger.toReportText()));
    }
    if (crossSystemBridgePlan != null) {
      sections.add(SmartExplorerExportSection(titleAr: 'خطة الربط مع الأنظمة', bodyAr: crossSystemBridgePlan.toReportText()));
    }
    if (handoffPacketText != null && handoffPacketText.trim().isNotEmpty) {
      sections.add(SmartExplorerExportSection(titleAr: 'حزمة التوريث', bodyAr: handoffPacketText));
    }

    return SmartExplorerExportBundle(
      sections: sections,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'حزمة تسليم تشغيلية للمستكشف الذكي',
    );
  }

  SmartExplorerExpectedOutcomes buildExpectedOutcomes({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    List<SmartExplorerReadinessAssessment>? readinessAssessments,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerClosureGate? closureGate,
  }) {
    final items = <SmartExplorerExpectedOutcomeItem>[];
    final needsReview = results.where((item) => item.needsReview).length;
    final withoutSpatial = results.where((item) => !item.hasAnySpatialReference).length;
    final withoutParcels = results.where((item) => !item.hasLinkedParcels).length;
    final missingEndowment = results.where((item) => _looksUnknown(item.endowmentName)).length;

    items.add(
      SmartExplorerExpectedOutcomeItem(
        titleAr: 'قائمة عمل لفجوات الأصول الوقفية',
        descriptionAr: 'تحويل نتائج البحث إلى قائمة مراجعة مرتبة بدل عرض سجلات خام.',
        category: SmartExplorerOutcomeCategory.dataQuality,
        horizonLabelAr: 'فوري داخل النسخة الحالية',
        indicatorAr: '$needsReview نتيجة تحتاج مراجعة من أصل ${results.length}.',
        evidenceSourceAr: 'إشارات الفجوات وقائمة أولوية المراجعة.',
        riskIfMissingAr: 'تبقى الفجوات مبعثرة ولا تتحول إلى إجراءات تدقيق واضحة.',
      ),
    );

    if (withoutSpatial > 0) {
      items.add(
        SmartExplorerExpectedOutcomeItem(
          titleAr: 'إغلاق فجوات التمثيل المكاني',
          descriptionAr: 'تحديد الأصول التي لا تملك نقطة/هندسة أو تملك تمثيلًا ناقصًا.',
          category: SmartExplorerOutcomeCategory.mapReadiness,
          horizonLabelAr: 'فوري ثم ميداني',
          indicatorAr: '$withoutSpatial أصل بلا تمثيل مكاني كافٍ.',
          evidenceSourceAr: 'حقول المركز والهندسة ومؤشرات SmartExplorerResult.',
          riskIfMissingAr: 'الخريطة تعرض صورة ناقصة وقد تقود إلى قرارات مكانية غير دقيقة.',
        ),
      );
    }

    if (withoutParcels > 0) {
      items.add(
        SmartExplorerExpectedOutcomeItem(
          titleAr: 'إغلاق فجوة الربط بالقطع/الأحواض',
          descriptionAr: 'تمييز الأصول التي تحتاج مطابقة مع قطع التسوية أو الأحواض.',
          category: SmartExplorerOutcomeCategory.dataQuality,
          horizonLabelAr: 'قصير المدى',
          indicatorAr: '$withoutParcels أصل بلا قطع مرتبطة.',
          evidenceSourceAr: 'linkedParcelsCount وفرضيات مطابقة القطع.',
          riskIfMissingAr: 'يبقى الأصل ظاهرًا كمرجع عام دون سند مكاني تفصيلي كافٍ.',
        ),
      );
    }

    if (missingEndowment > 0) {
      items.add(
        SmartExplorerExpectedOutcomeItem(
          titleAr: 'تحسين الربط مع الوقف الأم',
          descriptionAr: 'إظهار الأصول التي تحتاج مراجعة مرجعية مع awqaf_system.',
          category: SmartExplorerOutcomeCategory.governance,
          horizonLabelAr: 'قصير المدى',
          indicatorAr: '$missingEndowment أصل بلا وقف أم ظاهر.',
          evidenceSourceAr: 'endowmentName وسجل الافتراضات وبطاقة الجودة.',
          riskIfMissingAr: 'يضعف الفصل بين الأصل الوقفي والوقف المرجعي الأم.',
        ),
      );
    }

    if (documentAnalysis != null) {
      items.add(
        SmartExplorerExpectedOutcomeItem(
          titleAr: 'تحويل النصوص الوصفية إلى قرائن مراجعة',
          descriptionAr: 'استخراج مسميات وقرائن حدود واتجاهات من نص الوثيقة دون OCR خارجي في هذه الدفعة.',
          category: SmartExplorerOutcomeCategory.documentIntelligence,
          horizonLabelAr: 'فوري / rule-based',
          indicatorAr: '${documentAnalysis.entities.length} مسميات و${documentAnalysis.boundaryClues.length} قرائن حدود.',
          evidenceSourceAr: 'تحليل النص، قاموس المسميات، ومصفوفة الأدلة.',
          riskIfMissingAr: 'تبقى الوثائق خارج دورة الفحص المكاني ولا تُستخدم في الترجيح.',
        ),
      );
    }

    if (evidenceMatrix != null && evidenceMatrix.hasLinks) {
      items.add(
        SmartExplorerExpectedOutcomeItem(
          titleAr: 'ربط القرائن بالأصول المرشحة',
          descriptionAr: 'استخدام مصفوفة الأدلة لتفسير لماذا رُشح أصل أو استُبعد.',
          category: SmartExplorerOutcomeCategory.documentIntelligence,
          horizonLabelAr: 'فوري',
          indicatorAr: '${evidenceMatrix.links.length} رابط دليل قابل للمراجعة.',
          evidenceSourceAr: 'SmartExplorerEvidenceMatrix.',
          riskIfMissingAr: 'تصبح الفرضيات غير قابلة للتدقيق أو التفسير.',
        ),
      );
    }

    if (readinessAssessments != null && readinessAssessments.isNotEmpty) {
      final weak = readinessAssessments.where((item) => item.overallScore < 65).length;
      items.add(
        SmartExplorerExpectedOutcomeItem(
          titleAr: 'تصنيف جاهزية النتائج قبل التوريث',
          descriptionAr: 'تحديد ما يصلح للخريطة العامة أو التدقيق الميداني أو التاريخ أو الحوكمة.',
          category: SmartExplorerOutcomeCategory.governance,
          horizonLabelAr: 'فوري',
          indicatorAr: '$weak نتيجة دون عتبة الجاهزية الكافية.',
          evidenceSourceAr: 'تقييم الجاهزية وبطاقة الجودة.',
          riskIfMissingAr: 'قد يتم توريث نتائج غير ناضجة إلى المستكشف أو فرق التدقيق.',
        ),
      );
    }

    items.add(
      SmartExplorerExpectedOutcomeItem(
        titleAr: 'تجهيز مسار الذكاء المتقدم لاحقًا',
        descriptionAr: 'تثبيت الحوكمة والمخرجات قبل إضافة OCR أو LLM أو تخزين معرفي سيادي.',
        category: SmartExplorerOutcomeCategory.aiRoadmap,
        horizonLabelAr: 'لاحقًا بعد اعتماد الحوكمة',
        indicatorAr: qualityScorecard == null
            ? 'بطاقة الجودة لم تُولد بعد.'
            : 'بطاقة الجودة الحالية: ${qualityScorecard.overallScore}%.',
        evidenceSourceAr: 'بطاقة الجودة، سجل الافتراضات، خطة ربط الأنظمة، وبوابة الإغلاق.',
        riskIfMissingAr: 'إدخال AI متقدم قبل ضبط الحوكمة قد يخلط الاقتراح بالحقيقة السيادية.',
      ),
    );

    if (closureGate != null) {
      items.add(
        SmartExplorerExpectedOutcomeItem(
          titleAr: 'قرار إغلاق أو استمرار واضح',
          descriptionAr: 'تحديد هل النطاق جاهز للتسليم أم يحتاج تحصيل أدلة إضافية.',
          category: SmartExplorerOutcomeCategory.governance,
          horizonLabelAr: 'فوري',
          indicatorAr: closureGate.summaryAr,
          evidenceSourceAr: 'بوابة الإغلاق وسجل المخاطر.',
          riskIfMissingAr: 'يبقى القرار التشغيلي مفتوحًا دون نقطة استئناف واضحة.',
        ),
      );
    }

    return SmartExplorerExpectedOutcomes(
      items: items,
      generatedAt: DateTime.now(),
      scopeLabelAr: results.isEmpty ? 'تحليل عام للمستكشف الذكي' : 'نتائج البحث الحالية',
    );
  }

  SmartExplorerSourceAcquisitionPlan buildSourceAcquisitionPlan({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerAssumptionLedger? assumptionLedger,
  }) {
    final items = <SmartExplorerSourceAcquisitionItem>[];

    if (results.any((item) => !item.hasAnySpatialReference)) {
      items.add(
        const SmartExplorerSourceAcquisitionItem(
          titleAr: 'مصدر هندسي للأصول بلا تمثيل مكاني',
          sourceTypeLabelAr: 'GIS / رفع ميداني / طبقة مرجعية',
          priorityLabelAr: 'عالية',
          reasonAr: 'توجد أصول بلا نقطة أو هندسة كافية.',
          suggestedLocationAr: 'طبقات الأصول، البلاغات الميدانية، ملفات الرفع، أو مراجعة GIS.',
          closureCriterionAr: 'توفير نقطة/نطاق مرجح ومصدره ودرجة الثقة قبل الاعتماد.',
        ),
      );
    }

    if (results.any((item) => !item.hasLinkedParcels)) {
      items.add(
        const SmartExplorerSourceAcquisitionItem(
          titleAr: 'مصدر مطابقة قطع وأحواض',
          sourceTypeLabelAr: 'قطع تسوية / أحواض / جداول ربط',
          priorityLabelAr: 'عالية',
          reasonAr: 'توجد أصول بلا قطع مرتبطة.',
          suggestedLocationAr: 'طبقات التسوية والأحواض الطبيعية وملفات الربط في المستكشف.',
          closureCriterionAr: 'تحديد القطعة/الحوض أو توثيق سبب عدم توفر الربط.',
        ),
      );
    }

    if (results.any((item) => _looksUnknown(item.endowmentName))) {
      items.add(
        const SmartExplorerSourceAcquisitionItem(
          titleAr: 'مصدر ربط الوقف الأم',
          sourceTypeLabelAr: 'awqaf_system / وثائق مرجعية',
          priorityLabelAr: 'متوسطة إلى عالية',
          reasonAr: 'بعض الأصول لا يظهر لها وقف أم واضح.',
          suggestedLocationAr: 'مرجع الوقف والأوقاف الأم وسجلات الواقفين.',
          closureCriterionAr: 'تأكيد الوقف الأم أو تسجيل ملاحظة مراجعة دون تعديل سيادي مباشر.',
        ),
      );
    }

    if (documentAnalysis != null && documentAnalysis.confidencePercent < 70) {
      items.add(
        const SmartExplorerSourceAcquisitionItem(
          titleAr: 'نسخة أوضح من الوثيقة أو نص محقق',
          sourceTypeLabelAr: 'وثيقة / OCR لاحق / تفريغ يدوي',
          priorityLabelAr: 'متوسطة',
          reasonAr: 'ثقة تحليل النص دون عتبة 70%.',
          suggestedLocationAr: 'الأرشيف، صور الوثائق، ملفات PDF، أو تفريغ يدوي موثق.',
          closureCriterionAr: 'رفع جودة النص أو إسناد كل قرينة بمصدر واضح.',
        ),
      );
    }

    if (evidenceMatrix == null || !evidenceMatrix.hasLinks) {
      items.add(
        const SmartExplorerSourceAcquisitionItem(
          titleAr: 'قرائن ربط إضافية بين النص والخريطة',
          sourceTypeLabelAr: 'معالم / حدود / خرائط قديمة',
          priorityLabelAr: 'متوسطة',
          reasonAr: 'لا توجد روابط كافية في مصفوفة الأدلة.',
          suggestedLocationAr: 'خرائط تاريخية، أسماء مواضع، معالم طبيعية، وطبقات الطرق/الأودية.',
          closureCriterionAr: 'وجود رابط دليل واحد على الأقل لكل فرضية رئيسية.',
        ),
      );
    }

    if (assumptionLedger != null && !assumptionLedger.isEmpty) {
      items.add(
        SmartExplorerSourceAcquisitionItem(
          titleAr: 'مصادر تحقق للافتراضات المسجلة',
          sourceTypeLabelAr: 'مراجعة بشرية / وثائق / GIS',
          priorityLabelAr: 'متغيرة حسب الافتراض',
          reasonAr: assumptionLedger.summaryAr,
          suggestedLocationAr: 'سجل الافتراضات، مصفوفة الأدلة، وبوابة الإغلاق.',
          closureCriterionAr: 'كل افتراض مؤثر يجب أن يتحول إلى دليل مؤيد أو قرار استبعاد.',
        ),
      );
    }

    return SmartExplorerSourceAcquisitionPlan(
      items: items,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'نطاق تحصيل الأدلة للمستكشف الذكي',
    );
  }

  SmartExplorerConfidenceZoneSet buildConfidenceZones({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
  }) {
    final zones = <SmartExplorerConfidenceZone>[];

    final byGovernorate = <String, int>{};
    for (final result in results) {
      final key = result.governorate.trim().isEmpty ? 'غير محدد' : result.governorate.trim();
      byGovernorate[key] = (byGovernorate[key] ?? 0) + 1;
    }

    for (final entry in byGovernorate.entries.take(6)) {
      zones.add(
        SmartExplorerConfidenceZone(
          labelAr: 'نطاق محافظة/منطقة: ${entry.key}',
          zoneTypeLabelAr: 'نطاق إداري مرجح',
          confidencePercent: entry.key == 'غير محدد' ? 35 : 68,
          basisAr: 'تكرار ${entry.value} نتيجة ضمن نفس النطاق الإداري.',
          requiredLayersAr: const <String>[
            'حدود المحافظات',
            'حدود الهيئات المحلية',
            'الأصول الوقفية',
          ],
          nextTestAr: 'افتح الخريطة الحديثة وراجع التوزيع حسب BBOX وZoom قبل اعتماد أي نطاق.',
        ),
      );
    }

    if (documentAnalysis != null) {
      for (final entity in documentAnalysis.entities.take(8)) {
        zones.add(
          SmartExplorerConfidenceZone(
            labelAr: 'نطاق قرينة وثيقة: ${entity.value}',
            zoneTypeLabelAr: entity.typeLabelAr,
            confidencePercent: entity.scorePercent,
            basisAr: entity.evidence,
            requiredLayersAr: const <String>[
              'البحث المكاني',
              'المعالم الوصفية',
              'الطبقات التاريخية عند الحاجة',
            ],
            nextTestAr: 'ابحث عن المسمى في الخريطة وقارنه مع نتائج الأصول ومصفوفة الأدلة.',
          ),
        );
      }
    }

    if (evidenceMatrix != null && evidenceMatrix.hasLinks) {
      for (final link in evidenceMatrix.links.take(5)) {
        zones.add(
          SmartExplorerConfidenceZone(
            labelAr: 'منطقة دليل: ${link.entityValue}',
            zoneTypeLabelAr: 'رابط دليل بين وثيقة وأصل',
            confidencePercent: link.matchScore,
            basisAr: 'مطابقة مع ${link.resultTitleAr} عبر ${link.matchedFields.join('، ')}.',
            requiredLayersAr: const <String>[
              'Identify',
              'Popup',
              'طبقة الأصل الوقفي',
              'طبقة القطع/الأحواض',
            ],
            nextTestAr: link.conflicts.isEmpty
                ? 'اختبر القرب والاحتواء والتقاطع عند تفعيل الطبقات المناسبة.'
                : 'ابدأ بحل التعارضات قبل ترقية الثقة.',
          ),
        );
      }
    }

    return SmartExplorerConfidenceZoneSet(
      zones: zones,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'مناطق ثقة وصفية للنطاق الحالي',
    );
  }

  SmartExplorerTemporalAdminTrace buildTemporalAdminTrace({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    List<SmartExplorerGazetteerEntry>? gazetteerEntries,
  }) {
    final steps = <SmartExplorerTemporalAdminStep>[
      const SmartExplorerTemporalAdminStep(
        periodLabelAr: 'الأصل الوقفي التاريخي',
        adminUnitLabelAr: 'وقف أم / نطاق وصفي',
        evidenceAr: 'يُستنتج من اسم الوقف أو الوثيقة أو السجل التاريخي إن توفر.',
        certaintyLabelAr: 'بحاجة مصدر',
        nextActionAr: 'تثبيت مصدر الوقف الأم قبل إسقاطه على الخريطة الحديثة.',
      ),
    ];

    if (documentAnalysis != null && documentAnalysis.entities.isNotEmpty) {
      steps.add(
        SmartExplorerTemporalAdminStep(
          periodLabelAr: 'الوثيقة المدخلة',
          adminUnitLabelAr: documentAnalysis.entities.take(4).map((e) => e.value).join(' / '),
          evidenceAr: 'مسميات مستخرجة من النص وقابلة للمراجعة.',
          certaintyLabelAr: documentAnalysis.confidencePercent >= 70 ? 'متوسطة إلى عالية' : 'منخفضة إلى متوسطة',
          nextActionAr: 'مراجعة المسميات في قاموس المسميات ومقارنتها بالحدود التاريخية.',
        ),
      );
    }

    final communities = results
        .map((item) => item.community.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .take(5)
        .toList(growable: false);
    if (communities.isNotEmpty) {
      steps.add(
        SmartExplorerTemporalAdminStep(
          periodLabelAr: 'السياق الإداري الحديث',
          adminUnitLabelAr: communities.join(' / '),
          evidenceAr: 'حقول التجمع/الهيئة/المحافظة في نتائج الأصول الحالية.',
          certaintyLabelAr: 'تشغيلي قابل للمراجعة',
          nextActionAr: 'مطابقة التجمعات الحديثة مع السلالة التاريخية قبل أي اعتماد.',
        ),
      );
    }

    if (gazetteerEntries != null && gazetteerEntries.isNotEmpty) {
      steps.add(
        SmartExplorerTemporalAdminStep(
          periodLabelAr: 'قاموس المسميات المسودة',
          adminUnitLabelAr: gazetteerEntries.take(6).map((e) => e.value).join(' / '),
          evidenceAr: 'مدخلات قاموس مشتقة من الوثيقة والنتائج وليست مرجعًا سياديًا.',
          certaintyLabelAr: 'مسودة',
          nextActionAr: 'ترقية المدخلات فقط بعد إسنادها بمصدر واضح.',
        ),
      );
    }

    steps.add(
      const SmartExplorerTemporalAdminStep(
        periodLabelAr: 'الربط مع الأصول الحديثة',
        adminUnitLabelAr: 'waqf_asset_id / national_asset_code',
        evidenceAr: 'نتائج البحث الحالية وروابط القطع والأحواض إن وجدت.',
        certaintyLabelAr: 'مشروط بجودة الربط المكاني',
        nextActionAr: 'لا يُعدل السجل السيادي إلا عبر مسار الاعتماد المناسب.',
      ),
    );

    return SmartExplorerTemporalAdminTrace(
      steps: steps,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'سلالة إدارية/زمنية مسودة',
    );
  }

  SmartExplorerAuditPlaybook buildAuditPlaybook({
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerSourceAcquisitionPlan? sourcePlan,
    SmartExplorerConfidenceZoneSet? confidenceZones,
    SmartExplorerClosureGate? closureGate,
  }) {
    final steps = <SmartExplorerAuditPlaybookStep>[
      const SmartExplorerAuditPlaybookStep(
        order: 1,
        titleAr: 'تثبيت نطاق البحث',
        ownerAr: 'مدقق مستكشف الوقف',
        inputAr: 'عبارة البحث والفلاتر الحالية',
        actionAr: 'تحديد هل النطاق أصل/وقف/تجمع/وثيقة قبل متابعة التحليل.',
        outputAr: 'نطاق مراجعة واضح',
        stopCriterionAr: 'لا يبدأ التحليل إذا كان النطاق غامضًا جدًا.',
      ),
      SmartExplorerAuditPlaybookStep(
        order: 2,
        titleAr: 'فرز فجوات الأصول',
        ownerAr: 'مدقق بيانات',
        inputAr: '${results.length} نتيجة و${results.where((item) => item.needsReview).length} نتيجة تحتاج مراجعة',
        actionAr: 'فرز النتائج حسب الشدة والثقة والربط المكاني والقطع.',
        outputAr: 'قائمة أولوية مراجعة',
        stopCriterionAr: 'كل نتيجة حرجة يجب أن تملك إجراءً تاليًا.',
      ),
    ];

    if (documentAnalysis != null) {
      steps.add(
        SmartExplorerAuditPlaybookStep(
          order: steps.length + 1,
          titleAr: 'مراجعة الوثيقة والمسميات',
          ownerAr: 'مدقق وثائق/تاريخ',
          inputAr: '${documentAnalysis.entities.length} مسميات مستخرجة',
          actionAr: 'تدقيق المسميات والقرائن وتحويل الضعيف منها إلى طلب تحصيل مصدر.',
          outputAr: 'قاموس مسميات مسودة مؤيد بملاحظات',
          stopCriterionAr: 'أي قرينة مؤثرة يجب أن ترتبط بمصدر أو توضع كسجل افتراض.',
        ),
      );
    }

    if (sourcePlan != null && !sourcePlan.isEmpty) {
      steps.add(
        SmartExplorerAuditPlaybookStep(
          order: steps.length + 1,
          titleAr: 'تحصيل المصادر الناقصة',
          ownerAr: 'مشرف جودة البيانات',
          inputAr: sourcePlan.summaryAr,
          actionAr: 'توزيع بنود تحصيل المصادر قبل رفع درجة الثقة.',
          outputAr: 'مصادر مؤيدة أو قرار استبعاد موثق',
          stopCriterionAr: 'لا ترقية لفرضية بلا مصدر أو ملاحظة مراجعة.',
        ),
      );
    }

    if (confidenceZones != null && !confidenceZones.isEmpty) {
      steps.add(
        SmartExplorerAuditPlaybookStep(
          order: steps.length + 1,
          titleAr: 'اختبار مناطق الثقة على الخريطة',
          ownerAr: 'مشرف GIS',
          inputAr: '${confidenceZones.totalZones} منطقة وصفية',
          actionAr: 'فحص المناطق باستخدام BBOX/Zoom/Identify والطبقات المقترحة.',
          outputAr: 'تأكيد/استبعاد كل منطقة',
          stopCriterionAr: 'أي منطقة منخفضة الثقة لا تُعرض للجمهور.',
        ),
      );
    }

    steps.add(
      SmartExplorerAuditPlaybookStep(
        order: steps.length + 1,
        titleAr: 'قرار الإغلاق أو التوريث',
        ownerAr: 'مدير المستكشف',
        inputAr: closureGate?.summaryAr ?? 'بوابة الإغلاق غير مولدة بعد',
        actionAr: 'تحديد هل النطاق جاهز للتسليم أو يحتاج جولة مراجعة جديدة.',
        outputAr: 'قرار تشغيل واضح ونقطة استئناف',
        stopCriterionAr: 'لا يتم تحويل أي مخرج إلى حقيقة سيادية من داخل المستكشف الذكي.',
      ),
    );

    return SmartExplorerAuditPlaybook(
      steps: steps,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'دليل تشغيل للنطاق الحالي',
    );
  }

  SmartExplorerReleaseReadiness buildReleaseReadiness({
    required List<SmartExplorerResult> results,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerClosureGate? closureGate,
    SmartExplorerSourceAcquisitionPlan? sourcePlan,
    SmartExplorerAuditPlaybook? auditPlaybook,
  }) {
    final gates = <SmartExplorerReleaseGate>[
      SmartExplorerReleaseGate(
        titleAr: 'عدم استخدام Riverpod القديم',
        statusLabelAr: 'مغلق نصيًا داخل feature المستكشف الذكي',
        isBlocking: false,
        noteAr: 'الدفعة تستخدم NotifierProvider والاستيراد الحديث لـ Riverpod.',
        requiredActionAr: 'إعادة الفحص بعد الدمج الكامل.',
      ),
      const SmartExplorerReleaseGate(
        titleAr: 'عدم الكتابة في الجداول السيادية',
        statusLabelAr: 'مغلق في نطاق الدفعة',
        isBlocking: false,
        noteAr: 'لا توجد SQL أو تحديث مباشر لـ waqf_assets/endowments/core.',
        requiredActionAr: 'أي تخزين لاحق يجب أن يمر عبر جدول اقتراحات/مراجعة.',
      ),
      SmartExplorerReleaseGate(
        titleAr: 'جاهزية الجودة التشغيلية',
        statusLabelAr: qualityScorecard == null
            ? 'غير مقاسة'
            : '${qualityScorecard.overallScore}%',
        isBlocking: qualityScorecard != null && qualityScorecard.overallScore < 60,
        noteAr: qualityScorecard?.summaryAr ?? 'ولّد بطاقة الجودة قبل اعتماد التوسع.',
        requiredActionAr: 'إغلاق بوابات الجودة الضعيفة قبل تفعيل أدوات أكثر حساسية.',
      ),
      SmartExplorerReleaseGate(
        titleAr: 'بوابة الإغلاق',
        statusLabelAr: closureGate?.summaryAr ?? 'غير مولدة',
        isBlocking: closureGate != null && closureGate.blockingCount > 0,
        noteAr: closureGate?.summaryAr ?? 'تحتاج توليد بوابة الإغلاق.',
        requiredActionAr: 'معالجة الموانع قبل التوريث.',
      ),
      SmartExplorerReleaseGate(
        titleAr: 'تحصيل المصادر',
        statusLabelAr: sourcePlan == null ? 'غير مولد' : '${sourcePlan.totalItems} بند',
        isBlocking: sourcePlan != null && sourcePlan.totalItems > 4,
        noteAr: sourcePlan?.summaryAr ?? 'تحتاج خطة تحصيل مصادر عند وجود فجوات.',
        requiredActionAr: 'إغلاق البنود عالية الأولوية أولًا.',
      ),
      SmartExplorerReleaseGate(
        titleAr: 'دليل التدقيق',
        statusLabelAr: auditPlaybook == null ? 'غير مولد' : '${auditPlaybook.totalSteps} خطوات',
        isBlocking: false,
        noteAr: auditPlaybook?.summaryAr ?? 'يفضل توليد دليل التدقيق قبل التسليم.',
        requiredActionAr: 'إرفاق الدليل بحزمة التسليم عند نهاية الجلسة.',
      ),
    ];

    final blocking = gates.where((gate) => gate.isBlocking).length;
    return SmartExplorerReleaseReadiness(
      gates: gates,
      generatedAt: DateTime.now(),
      scopeLabelAr: 'جاهزية توسع المستكشف الذكي',
      recommendationAr: blocking == 0
          ? 'يمكن متابعة التطوير التشغيلي مع استمرار منع الكتابة السيادية.'
          : 'أوقف التوسع الحساس وأغلق $blocking بوابات مانعة أولًا.',
    );
  }

  SmartExplorerRuntimeDiagnostics buildRuntimeDiagnostics({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerSourceAcquisitionPlan? sourcePlan,
    SmartExplorerAuditPlaybook? auditPlaybook,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    final items = <SmartExplorerRuntimeDiagnosticItem>[];

    items.add(
      SmartExplorerRuntimeDiagnosticItem(
        titleAr: 'نطاق البحث',
        level: query.trim().isEmpty
            ? SmartExplorerRuntimeDiagnosticLevel.warning
            : SmartExplorerRuntimeDiagnosticLevel.pass,
        isBlocking: false,
        statusAr: query.trim().isEmpty ? 'غير محدد' : 'محدد',
        evidenceAr: query.trim().isEmpty
            ? 'لا توجد عبارة بحث حالية.'
            : 'عبارة البحث الحالية: ${query.trim()}',
        nextActionAr: query.trim().isEmpty
            ? 'نفّذ بحثًا قبل إنتاج حزم تسليم أو مراجعة.'
            : 'استمر في الفلترة وتوليد أدلة المراجعة.',
      ),
    );

    final reviewCount = results.where((item) => item.needsReview).length;
    items.add(
      SmartExplorerRuntimeDiagnosticItem(
        titleAr: 'قائمة المراجعة',
        level: results.isEmpty
            ? SmartExplorerRuntimeDiagnosticLevel.warning
            : SmartExplorerRuntimeDiagnosticLevel.pass,
        isBlocking: false,
        statusAr: results.isEmpty
            ? 'لا توجد نتائج'
            : '$reviewCount من ${results.length} نتيجة تحتاج مراجعة',
        evidenceAr: 'النتائج بعد الفلترة: ${results.length}',
        nextActionAr: results.isEmpty
            ? 'نفّذ بحثًا أو خفف الفلاتر قبل إنشاء طلبات تدقيق.'
            : 'ابدأ من النتائج الأعلى في reviewScore.',
      ),
    );

    final hasDocumentEvidence = documentAnalysis != null &&
        (documentAnalysis.entities.isNotEmpty ||
            documentAnalysis.boundaryClues.isNotEmpty ||
            documentAnalysis.spatialHypotheses.isNotEmpty);
    items.add(
      SmartExplorerRuntimeDiagnosticItem(
        titleAr: 'أدلة الوثيقة',
        level: hasDocumentEvidence
            ? SmartExplorerRuntimeDiagnosticLevel.pass
            : SmartExplorerRuntimeDiagnosticLevel.warning,
        isBlocking: false,
        statusAr: hasDocumentEvidence ? 'متوفرة' : 'غير كافية',
        evidenceAr: documentAnalysis == null
            ? 'لم يتم تحليل نص وثيقة.'
            : 'كيانات: ${documentAnalysis.entities.length}، قرائن حدود: ${documentAnalysis.boundaryClues.length}، فرضيات: ${documentAnalysis.spatialHypotheses.length}',
        nextActionAr: hasDocumentEvidence
            ? 'اربط الأدلة مع مصفوفة الأدلة ثم راجع التعارضات.'
            : 'الصق نص وثيقة أو استخدم مثال الوثيقة لتوليد قرائن.',
      ),
    );

    final hasEvidenceLinks = evidenceMatrix != null && evidenceMatrix.hasLinks;
    items.add(
      SmartExplorerRuntimeDiagnosticItem(
        titleAr: 'مصفوفة الأدلة',
        level: hasEvidenceLinks
            ? SmartExplorerRuntimeDiagnosticLevel.pass
            : SmartExplorerRuntimeDiagnosticLevel.warning,
        isBlocking: false,
        statusAr: hasEvidenceLinks ? 'روابط متوفرة' : 'لا توجد روابط كافية',
        evidenceAr: evidenceMatrix == null
            ? 'لم يتم توليد مصفوفة أدلة.'
            : 'عدد الروابط: ${evidenceMatrix.links.length}',
        nextActionAr: hasEvidenceLinks
            ? 'راجع الروابط القوية والتعارضات قبل أي تصعيد.'
            : 'ولّد مصفوفة الأدلة بعد وجود نتائج ووثيقة.',
      ),
    );

    final qualityScore = qualityScorecard?.overallScore;
    items.add(
      SmartExplorerRuntimeDiagnosticItem(
        titleAr: 'جودة التشغيل',
        level: qualityScore == null
            ? SmartExplorerRuntimeDiagnosticLevel.warning
            : qualityScore < 60
                ? SmartExplorerRuntimeDiagnosticLevel.blocking
                : SmartExplorerRuntimeDiagnosticLevel.pass,
        isBlocking: qualityScore != null && qualityScore < 60,
        statusAr: qualityScore == null ? 'غير مقاسة' : '$qualityScore%',
        evidenceAr: qualityScorecard?.summaryAr ?? 'لم يتم توليد بطاقة جودة.',
        nextActionAr: qualityScore == null
            ? 'ولّد بطاقة جودة قبل تسليم النطاق.'
            : qualityScore < 60
                ? 'أغلق أسباب الضعف قبل التوسع أو التوريث النهائي.'
                : 'اربط بطاقة الجودة بحزمة التسليم.',
      ),
    );

    final missingSources = sourcePlan?.totalItems ?? 0;
    items.add(
      SmartExplorerRuntimeDiagnosticItem(
        titleAr: 'تحصيل المصادر',
        level: missingSources > 4
            ? SmartExplorerRuntimeDiagnosticLevel.blocking
            : sourcePlan == null || missingSources > 0
                ? SmartExplorerRuntimeDiagnosticLevel.warning
                : SmartExplorerRuntimeDiagnosticLevel.pass,
        isBlocking: missingSources > 4,
        statusAr: sourcePlan == null ? 'غير مولد' : '$missingSources بند',
        evidenceAr: sourcePlan?.summaryAr ?? 'لم يتم توليد خطة تحصيل مصادر.',
        nextActionAr: missingSources > 4
            ? 'أوقف التوسع وأغلق المصادر عالية الأولوية.'
            : 'وثق المصادر المتبقية داخل التوريث.',
      ),
    );

    final releaseBlocking = releaseReadiness?.blockingGates ?? 0;
    items.add(
      SmartExplorerRuntimeDiagnosticItem(
        titleAr: 'جاهزية الإصدار',
        level: releaseReadiness == null
            ? SmartExplorerRuntimeDiagnosticLevel.warning
            : releaseBlocking > 0
                ? SmartExplorerRuntimeDiagnosticLevel.blocking
                : SmartExplorerRuntimeDiagnosticLevel.pass,
        isBlocking: releaseBlocking > 0,
        statusAr: releaseReadiness == null
            ? 'غير مولدة'
            : '$releaseBlocking بوابات مانعة',
        evidenceAr: releaseReadiness?.summaryAr ?? 'لم يتم توليد جاهزية الإصدار.',
        nextActionAr: releaseBlocking > 0
            ? 'أغلق بوابات الإصدار قبل دمج دفعة جديدة.'
            : 'أرفق تقرير الجاهزية بالحزمة النهائية.',
      ),
    );

    items.add(
      SmartExplorerRuntimeDiagnosticItem(
        titleAr: 'دليل التدقيق',
        level: auditPlaybook == null || auditPlaybook.isEmpty
            ? SmartExplorerRuntimeDiagnosticLevel.warning
            : SmartExplorerRuntimeDiagnosticLevel.pass,
        isBlocking: false,
        statusAr: auditPlaybook == null
            ? 'غير مولد'
            : '${auditPlaybook.totalSteps} خطوات',
        evidenceAr: auditPlaybook?.summaryAr ?? 'لا يوجد دليل تدقيق حالي.',
        nextActionAr: 'احتفظ بدليل التدقيق كملحق تشغيل لا كقرار سيادي.',
      ),
    );

    final blocking = items.where((item) => item.isBlocking).length;
    return SmartExplorerRuntimeDiagnostics(
      items: items,
      generatedAt: DateTime.now(),
      scopeLabelAr: query.trim().isEmpty ? 'نطاق غير محدد' : query.trim(),
      recommendationAr: blocking == 0
          ? 'يمكن متابعة التطوير التشغيلي، مع إبقاء الاعتماد النهائي خارج المستكشف الذكي.'
          : 'أوقف التوسع الحساس حتى إغلاق $blocking موانع تشغيل.',
    );
  }

  String buildStrategicOutcomePack({
    required SmartExplorerExpectedOutcomes? expectedOutcomes,
    required SmartExplorerSourceAcquisitionPlan? sourcePlan,
    required SmartExplorerConfidenceZoneSet? confidenceZones,
    required SmartExplorerTemporalAdminTrace? temporalTrace,
    required SmartExplorerAuditPlaybook? auditPlaybook,
    required SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    final buffer = StringBuffer()
      ..writeln('الحزمة الاستراتيجية الموسعة للمستكشف الذكي')
      ..writeln('وقت التوليد: ${DateTime.now().toIso8601String()}')
      ..writeln('تنبيه: هذه الحزمة تشغيلية/مراجعة ولا تعتمد أي سجل سيادي.')
      ..writeln('---');

    if (expectedOutcomes != null) {
      buffer..writeln(expectedOutcomes.toReportText())..writeln('---');
    }
    if (sourcePlan != null) {
      buffer..writeln(sourcePlan.toReportText())..writeln('---');
    }
    if (confidenceZones != null) {
      buffer..writeln(confidenceZones.toReportText())..writeln('---');
    }
    if (temporalTrace != null) {
      buffer..writeln(temporalTrace.toReportText())..writeln('---');
    }
    if (auditPlaybook != null) {
      buffer..writeln(auditPlaybook.toReportText())..writeln('---');
    }
    if (releaseReadiness != null) {
      buffer..writeln(releaseReadiness.toReportText())..writeln('---');
    }
    return buffer.toString();
  }

  String buildFinalIntegrationMemo({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerInvestigationSession? investigationSession,
    SmartExplorerHypothesisComparison? hypothesisComparison,
    SmartExplorerDataLineage? dataLineage,
    SmartExplorerClosureGate? closureGate,
    SmartExplorerWorkPackageSet? workPackages,
    SmartExplorerValidationProtocol? validationProtocol,
  }) {
    final buffer = StringBuffer()
      ..writeln('مذكرة دمج المستكشف الذكي مع المستكشف')
      ..writeln('وقت التوليد: ${DateTime.now().toIso8601String()}')
      ..writeln('النطاق: ${query.trim().isEmpty ? 'غير محدد' : query.trim()}')
      ..writeln('تنبيه: المذكرة تشغيلية ولا تنشئ قرارًا سياديًا.')
      ..writeln('---')
      ..writeln('النتائج الحالية: ${results.length}')
      ..writeln('تحتاج مراجعة: ${results.where((item) => item.needsReview).length}')
      ..writeln('بلا تمثيل مكاني: ${results.where((item) => !item.hasAnySpatialReference).length}')
      ..writeln('بلا قطع مرتبطة: ${results.where((item) => !item.hasLinkedParcels).length}');
    if (investigationSession != null) {
      buffer
        ..writeln('---')
        ..writeln('جلسة التحقيق: ${investigationSession.summaryAr}')
        ..writeln('التالي: ${investigationSession.nextActionAr}');
    }
    if (hypothesisComparison != null) {
      buffer
        ..writeln('---')
        ..writeln('مقارنة الفرضيات: ${hypothesisComparison.summaryAr}');
    }
    if (dataLineage != null) {
      buffer
        ..writeln('---')
        ..writeln('أثر البيانات: ${dataLineage.summaryAr}');
    }
    if (closureGate != null) {
      buffer
        ..writeln('---')
        ..writeln('بوابة الإغلاق: ${closureGate.summaryAr}');
    }
    if (validationProtocol != null) {
      buffer
        ..writeln('---')
        ..writeln('التحقق: ${validationProtocol.summaryAr}');
    }
    if (workPackages != null && !workPackages.isEmpty) {
      buffer
        ..writeln('---')
        ..writeln('أول حزم العمل:');
      for (final package in workPackages.topPackages.take(5)) {
        buffer.writeln('- [${package.priorityLabelAr}] ${package.titleAr}: ${package.expectedOutputAr}');
      }
    }
    buffer
      ..writeln('---')
      ..writeln('قرار الدمج المقترح: أبقِ المخرجات داخل المستكشف الذكي كطبقة مراجعة، ثم حوّل البنود الجاهزة إلى طلبات تدقيق عبر المسار الحالي فقط.')
      ..writeln('خارج النطاق: OCR، LLM خارجي، تعديل waqf_assets/endowments/core، أو اعتماد تلقائي.');
    return buffer.toString();
  }


  SmartExplorerCurrentBaselineGuard buildCurrentBaselineGuard({
    required String query,
  }) {
    final protectedFiles = <String>[
      'lib/router.dart',
      'lib/features/map/**',
      'lib/features/map/presentation/pages/map_page.dart',
      'lib/features/map/presentation/providers/map_provider.dart',
      'lib/features/map/presentation/widgets/toolbox/tool_sections/search_section.dart',
      'lib/features/map/data/repositories/gis_lookup_repository.dart',
      'lib/features/map/data/repositories/lookup_repository.dart',
      'lib/features/map/presentation/providers/lookup_providers.dart',
    ];

    final overlayFiles = <String>[
      'lib/features/smart_explorer/domain/models/smart_explorer_current_baseline_guard.dart',
      'lib/features/smart_explorer/data/repositories/smart_explorer_repository.dart',
      'lib/features/smart_explorer/application/controllers/smart_explorer_controller.dart',
      'lib/features/smart_explorer/presentation/pages/admin_smart_explorer_page.dart',
      'docs/smart_explorer/**',
      'instructions/**',
    ];

    final items = <SmartExplorerBaselineGuardItem>[
      const SmartExplorerBaselineGuardItem(
        titleAr: 'الراوتر العام للمنصة',
        pathPattern: 'lib/router.dart',
        status: SmartExplorerBaselineGuardStatus.blocked,
        reasonAr: 'الملف في الحزمة السابقة أقدم من baseline الحالي للمستكشف، واستبداله قد يحذف مسارات أحدث.',
        decisionAr: 'لا يتم نسخه من هذه الدفعة.',
        nextActionAr: 'يدمج أي route جديد يدويًا فقط إذا كان غير موجود في baseline الحالي.',
      ),
      const SmartExplorerBaselineGuardItem(
        titleAr: 'صفحة الخريطة الحديثة',
        pathPattern: 'lib/features/map/presentation/pages/map_page.dart',
        status: SmartExplorerBaselineGuardStatus.blocked,
        reasonAr: 'سلوك الزوم والطبقات في baseline الحالي أحدث من الحزمة المتاحة.',
        decisionAr: 'حماية كاملة من overwrite.',
        nextActionAr: 'استخدم الخريطة الحالية كمصدر حقيقة، والمستكشف الذكي يرسل سياقًا/تقريرًا فقط.',
      ),
      const SmartExplorerBaselineGuardItem(
        titleAr: 'مزود حالة الخريطة',
        pathPattern: 'lib/features/map/presentation/providers/map_provider.dart',
        status: SmartExplorerBaselineGuardStatus.blocked,
        reasonAr: 'أي downgrade قد يكسر قاعدة navigation-only وzoom-driven loading.',
        decisionAr: 'لا استبدال ولا patch مباشر من المستكشف الذكي.',
        nextActionAr: 'أي احتياج تكاملي يفتح كتذكرة تدقيق/دمج منفصلة.',
      ),
      const SmartExplorerBaselineGuardItem(
        titleAr: 'قسم البحث داخل صندوق أدوات الخريطة',
        pathPattern: 'lib/features/map/presentation/widgets/toolbox/tool_sections/search_section.dart',
        status: SmartExplorerBaselineGuardStatus.blocked,
        reasonAr: 'سلوك اختيار المحافظة/التجمع/الهيئة/الحوض/القطعة ملاحي فقط في baseline الحالي.',
        decisionAr: 'لا يغير المستكشف الذكي هذا السلوك.',
        nextActionAr: 'استخدم تقارير handoff لتغذية الاختبار، لا لتبديل الملف.',
      ),
      const SmartExplorerBaselineGuardItem(
        titleAr: 'مستودعات lookup/RPC للخريطة',
        pathPattern: 'lib/features/map/data/repositories/*lookup*',
        status: SmartExplorerBaselineGuardStatus.blocked,
        reasonAr: 'توقيع RPC ومصادر GIS في baseline الحالي أحدث وغير مضمون مطابقته للحزمة.',
        decisionAr: 'المستكشف الذكي لا يغير عقود GIS.',
        nextActionAr: 'توليد قائمة متطلبات فقط، ثم تطبيقها لاحقًا فوق ملفات baseline الحالي.',
      ),
      const SmartExplorerBaselineGuardItem(
        titleAr: 'ملفات smart_explorer الداخلية',
        pathPattern: 'lib/features/smart_explorer/**',
        status: SmartExplorerBaselineGuardStatus.safe,
        reasonAr: 'الدفعة تضيف أدوات تحليل/تصدير وتشخيص داخل نطاق المستكشف الذكي.',
        decisionAr: 'تطبق كـ overlay انتقائي.',
        nextActionAr: 'شغّل flutter analyze بعد الدمج المحلي.',
      ),
      const SmartExplorerBaselineGuardItem(
        titleAr: 'وثائق التشغيل والتوريث',
        pathPattern: 'docs/smart_explorer/** + instructions/**',
        status: SmartExplorerBaselineGuardStatus.safe,
        reasonAr: 'لا تؤثر على runtime وتوثق قرار عدم استبدال الخريطة/البحث/الراوتر.',
        decisionAr: 'تضاف إلى baseline.',
        nextActionAr: 'اعتمادها كملحق للحزمة القادمة.',
      ),
    ];

    return SmartExplorerCurrentBaselineGuard(
      generatedAt: DateTime.now(),
      scopeLabelAr: query.trim().isEmpty ? 'نطاق غير محدد' : query.trim(),
      items: items,
      overlayFiles: overlayFiles,
      nonOverwriteFiles: protectedFiles,
      integrationStepsAr: const <String>[
        'ابدأ من baseline الحالي الموجود محليًا لدى المستخدم، لا من حزمة الخريطة الأقدم.',
        'انسخ ملفات lib/features/smart_explorer فقط من overlay إن لم تكن أحدث محليًا.',
        'لا تنسخ lib/router.dart ولا أي ملف تحت lib/features/map من هذه الحزمة.',
        'شغّل flutter analyze ثم افتح /admin/smart-explorer فقط.',
        'اختبر توليد الحزم النصية، CSV، طلبات التدقيق، وروابط الانتقال دون تعديل activeLayers.',
        'إذا احتاجت الخريطة تعديلًا، افتح Batch منفصل فوق baseline الحالي للخريطة وبـ diff موضعي.',
      ],
      recommendationAr: 'التطوير مسموح كـ overlay للمستكشف الذكي فقط؛ الخريطة والبحث والراوتر تبقى من baseline الحالي للمستكشف.',
    );
  }

  String buildCurrentBaselineSafeExpansionPack({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerReviewWorkflow? reviewWorkflow,
    SmartExplorerAssumptionLedger? assumptionLedger,
    SmartExplorerSourceAcquisitionPlan? sourcePlan,
    SmartExplorerConfidenceZoneSet? confidenceZones,
    SmartExplorerTemporalAdminTrace? temporalTrace,
    SmartExplorerAuditPlaybook? auditPlaybook,
    SmartExplorerReleaseReadiness? releaseReadiness,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
  }) {
    final guard = buildCurrentBaselineGuard(query: query);
    final needsReview = results.where((item) => item.needsReview).length;
    final noGeometry = results.where((item) => !item.hasAnySpatialReference).length;
    final noParcels = results.where((item) => !item.hasLinkedParcels).length;
    final critical = results.fold<int>(
      0,
      (sum, item) => sum + item.severityCount(SmartExplorerSignalSeverity.critical),
    );

    final buffer = StringBuffer()
      ..writeln('حزمة تطوير آمنة فوق baseline الحالي للمستكشف الذكي')
      ..writeln('وقت التوليد: ${DateTime.now().toIso8601String()}')
      ..writeln('النطاق: ${query.trim().isEmpty ? 'غير محدد' : query.trim()}')
      ..writeln('تنبيه حاكم: لا تستبدل ملفات الخريطة أو البحث أو الراوتر من أي حزمة أقدم من baseline الحالي.')
      ..writeln('---')
      ..writeln(guard.toReportText())
      ..writeln('---')
      ..writeln('ملخص نتائج المستكشف الذكي الحالية:')
      ..writeln('- النتائج: ${results.length}')
      ..writeln('- تحتاج مراجعة: $needsReview')
      ..writeln('- إشارات حرجة: $critical')
      ..writeln('- بلا تمثيل مكاني: $noGeometry')
      ..writeln('- بلا قطع مرتبطة: $noParcels')
      ..writeln('- متوسط الثقة: ${results.isEmpty ? 0 : (results.fold<int>(0, (sum, item) => sum + item.confidenceScore) / results.length).round()}%')
      ..writeln('---')
      ..writeln('عقد تكامل الخريطة دون overwrite:')
      ..writeln('1. المستكشف الذكي ينتج سياقًا تشغيليًا فقط: assetId/query/evidence/reviewPriority.')
      ..writeln('2. الانتقال إلى الخريطة يتم عبر route/query موجود في baseline الحالي، دون تغيير router من هذه الحزمة.')
      ..writeln('3. الاختيارات داخل الخريطة تبقى navigation-only: انتقال/تركيز/fitBounds فقط.')
      ..writeln('4. طبقات المحافظات/التجمعات/الهيئات/الأحواض/التسوية تخضع للزوم والـ bbox حسب baseline الحالي.')
      ..writeln('5. أي طلب لتفعيل طبقة مرجعية مؤقتة يجب أن يأتي من منطق الخريطة الحالي لا من smart_explorer.')
      ..writeln('---')
      ..writeln('سجل المصادر والتحقق:');

    if (documentAnalysis == null) {
      buffer.writeln('- تحليل الوثيقة: غير مولد.');
    } else {
      buffer
        ..writeln('- تحليل الوثيقة: ${documentAnalysis.entities.length} كيان، ثقة ${documentAnalysis.confidencePercent}%.')
        ..writeln('- قرائن حدود: ${documentAnalysis.boundaryClues.length}, اتجاه: ${documentAnalysis.directionClues.length}, زمن: ${documentAnalysis.timeClues.length}.');
    }
    if (evidenceMatrix == null) {
      buffer.writeln('- مصفوفة الأدلة: غير مولدة.');
    } else {
      buffer.writeln('- مصفوفة الأدلة: ${evidenceMatrix.links.length} رابط أدلة.');
    }
    buffer.writeln('- بطاقة الجودة: ${qualityScorecard?.summaryAr ?? 'غير مولدة'}');
    buffer.writeln('- مسار المراجعة: ${reviewWorkflow?.summaryAr ?? 'غير مولد'}');
    buffer.writeln('- سجل الافتراضات: ${assumptionLedger?.summaryAr ?? 'غير مولد'}');
    buffer.writeln('- تحصيل المصادر: ${sourcePlan?.summaryAr ?? 'غير مولد'}');
    buffer.writeln('- مناطق الثقة: ${confidenceZones?.summaryAr ?? 'غير مولدة'}');
    buffer.writeln('- الأثر الإداري الزمني: ${temporalTrace?.summaryAr ?? 'غير مولد'}');
    buffer.writeln('- دليل التدقيق: ${auditPlaybook?.summaryAr ?? 'غير مولد'}');
    buffer.writeln('- جاهزية الإصدار: ${releaseReadiness?.summaryAr ?? 'غير مولدة'}');
    buffer.writeln('- تشخيص التشغيل: ${runtimeDiagnostics?.summaryAr ?? 'غير مولد'}');

    buffer
      ..writeln('---')
      ..writeln('قائمة فحص الدمج المحلي:')
      ..writeln('[ ] تطبيق overlay smart_explorer فقط.')
      ..writeln('[ ] عدم نسخ lib/router.dart من هذه الحزمة.')
      ..writeln('[ ] عدم نسخ أي ملف داخل lib/features/map من هذه الحزمة.')
      ..writeln('[ ] flutter clean اختياري إذا ظهرت كاشات قديمة.')
      ..writeln('[ ] flutter pub get.')
      ..writeln('[ ] flutter analyze.')
      ..writeln('[ ] فتح /admin/smart-explorer.')
      ..writeln('[ ] توليد حارس baseline الحالي.')
      ..writeln('[ ] توليد حزمة آمنة فوق baseline الحالي.')
      ..writeln('[ ] البحث عن نتيجة وربطها بتدقيق دون تعديل السجلات السيادية.')
      ..writeln('[ ] اختبار روابط الخريطة دون استبدال router/map/search.')
      ..writeln('---')
      ..writeln('Error Record احترازي:')
      ..writeln('- الخطأ المتكرر: بناء دفعة فوق حزمة أقدم ثم اعتبارها baseline.')
      ..writeln('- السبب: عدم توفر baseline الحالي الكامل في بيئة التنفيذ.')
      ..writeln('- الحل: إخراج overlay لا يحتوي ملفات الخريطة/البحث/الراوتر، وتوثيق المسارات المحمية.')
      ..writeln('- آخر baseline مستقر حسب المستخدم: baseline الحالي للمستكشف محليًا، وليس الحزمة الأقدم المرسلة.')
      ..writeln('---')
      ..writeln('القرار: هذه الحزمة تطوير كبير للمستكشف الذكي، لكنها ليست ترقية للخريطة. أي تطوير للخريطة يجب أن يبدأ من baseline الحالي للخريطة عند المستخدم.');

    return buffer.toString();
  }


  SmartExplorerSelfDevelopmentPack buildSelfDevelopmentPack({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerSourceAcquisitionPlan? sourcePlan,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    final missingGeometry = results.where((item) => !item.hasAnySpatialReference).length;
    final missingParcels = results.where((item) => !item.hasLinkedParcels).length;
    final reviewItems = results.where((item) => item.needsReview).length;
    final hasAnalyzerSeed = documentAnalysis != null || evidenceMatrix != null;
    final workItems = <SmartExplorerSelfDevelopmentItem>[
      SmartExplorerSelfDevelopmentItem(
        titleAr: 'تثبيت overlay فوق baseline الحالي فقط',
        priority: SmartExplorerSelfDevelopmentPriority.high,
        statusAr: 'إلزامي قبل أي دمج',
        isBlocking: true,
        reasonAr: 'ملفات الخريطة والبحث والراوتر لدى المستخدم أحدث من الحزم السابقة.',
        nextActionAr: 'طبّق ملفات smart_explorer فقط وتجاهل أي map/router من الحزم القديمة.',
      ),
      SmartExplorerSelfDevelopmentItem(
        titleAr: 'إغلاق نتائج بلا مرجع مكاني',
        priority: missingGeometry > 0
            ? SmartExplorerSelfDevelopmentPriority.high
            : SmartExplorerSelfDevelopmentPriority.low,
        statusAr: '$missingGeometry نتيجة بلا هندسة أو مركز واضح.',
        isBlocking: missingGeometry > 0,
        reasonAr: 'المستكشف لا يعتمد كتحليل مكاني إذا بقيت نتائج بلا مرجع مكاني أولي.',
        nextActionAr: 'وجّه النتائج إلى قائمة مراجعة وربطها بقرائن وثيقة أو gazetteer قبل map handoff.',
      ),
      SmartExplorerSelfDevelopmentItem(
        titleAr: 'إغلاق نتائج بلا قطع مرتبطة',
        priority: missingParcels > 0
            ? SmartExplorerSelfDevelopmentPriority.medium
            : SmartExplorerSelfDevelopmentPriority.low,
        statusAr: '$missingParcels نتيجة بلا ربط قطع.',
        isBlocking: false,
        reasonAr: 'ربط القطع مساعد لا سيادي، لكنه مطلوب لرفع جودة الفرضيات.',
        nextActionAr: 'استخدم مصفوفة الأدلة وقائمة التدقيق قبل إنشاء طلبات audit.',
      ),
      SmartExplorerSelfDevelopmentItem(
        titleAr: 'إعداد مدخلات المحلل المحلي',
        priority: hasAnalyzerSeed
            ? SmartExplorerSelfDevelopmentPriority.medium
            : SmartExplorerSelfDevelopmentPriority.high,
        statusAr: hasAnalyzerSeed ? 'توجد بذور تحليل.' : 'لا توجد بذور تحليل كافية.',
        isBlocking: !hasAnalyzerSeed,
        reasonAr: 'أي analyzer لاحق يحتاج وثيقة/أدلة/مسميات لا مجرد نتائج بحث.',
        nextActionAr: 'ولّد تحليل الوثيقة ومصفوفة الأدلة ثم عقد المحلل المحلي.',
      ),
      SmartExplorerSelfDevelopmentItem(
        titleAr: 'مراجعة queue قبل إنشاء طلبات تدقيق',
        priority: reviewItems > 0
            ? SmartExplorerSelfDevelopmentPriority.medium
            : SmartExplorerSelfDevelopmentPriority.low,
        statusAr: '$reviewItems نتيجة ضمن قائمة المراجعة.',
        isBlocking: false,
        reasonAr: 'الكتابة الوحيدة المسموحة تكون عبر مسار audit المعتمد، لا عبر تحديث مصادر الحقيقة.',
        nextActionAr: 'راجع أعلى النتائج ثم أنشئ طلبات تدقيق فقط عند وجود سبب واضح.',
      ),
    ];

    final guardRails = <String>[
      'لا تستبدل lib/router.dart من أي overlay سابق.',
      'لا تستبدل lib/features/map/** من أي overlay سابق.',
      'لا تعدّل activeLayers من داخل smart_explorer.',
      'أوامر البحث/الاختيار داخل الخريطة تبقى navigation-only: zoom/focus/fitBounds فقط.',
      'أي كتابة إنتاجية تمر عبر audit/review queue، لا عبر waqf_assets مباشرة.',
      'awqaf_system/core/waqf مصادر سيادية، وmustakshif للتحليل والمراجعة فقط.',
    ];

    final localAnalyzerInputs = <String>[
      'query الحالي: ${query.trim().isEmpty ? 'غير محدد' : query.trim()}',
      'عدد النتائج المرشحة: ${results.length}',
      'عدد نتائج قائمة المراجعة: $reviewItems',
      'تحليل الوثيقة: ${documentAnalysis == null ? 'غير مولد' : '${documentAnalysis.entities.length} مسميات / ثقة ${documentAnalysis.confidencePercent}%'}',
      'مصفوفة الأدلة: ${evidenceMatrix == null ? 'غير مولدة' : '${evidenceMatrix.links.length} روابط'}',
      'بطاقة الجودة: ${qualityScorecard?.summaryAr ?? 'غير مولدة'}',
      'تشخيص التشغيل: ${runtimeDiagnostics?.summaryAr ?? 'غير مولد'}',
      'خطة المصادر: ${sourcePlan?.summaryAr ?? 'غير مولدة'}',
      'جاهزية الإصدار: ${releaseReadiness?.summaryAr ?? 'غير مولدة'}',
    ];

    final acceptanceChecks = <String>[
      'تطبيق overlay على baseline الحالي دون نسخ map/router/search.',
      'flutter pub get.',
      'flutter analyze بدون أخطاء compile.',
      'فتح /admin/smart-explorer.',
      'تشغيل بحث ذكي فعلي.',
      'توليد تشخيص تشغيل.',
      'توليد حزمة baseline آمنة.',
      'توليد حزمة التطوير الذاتي هذه.',
      'اختبار زر bridge للخريطة دون تعديل سلوك الطبقات.',
      'تأكيد أن أي إنشاء سجلات يذهب إلى audit workflow فقط.',
    ];

    final errorRecords = <String>[
      'الخطأ: استخدام حزمة أقدم تحتوي map/router فوق baseline أحدث.',
      'الأثر: احتمال فقدان سلوك navigation-only أو كسر الراوتر.',
      'الحل في Batch M: overlay لا يحتوي map/router ويضيف أدوات تصدير داخل smart_explorer فقط.',
      'آخر baseline مستقر: baseline الحالي المحلي لدى المستخدم، وليس الحزمة الأقدم.',
    ];

    final nextPatchPlan = <String>[
      'Batch N: تطبيق overlay على baseline الحالي الفعلي وفحص analyzer محلي.',
      'Batch O: تحويل مخرجات التطوير الذاتي إلى Review Board actions عند وصول ملفات المستكشف.',
      'Batch P: ربط analyzer بعقد RPC/Storage staging بعد اعتماد RBAC إنتاجي.',
      'Batch Q: إغلاق cutover plan دون المساس بمصادر الحقيقة السيادية.',
    ];

    final summary = results.isEmpty
        ? 'الحزمة جاهزة كتوسعة ذاتية لكنها تحتاج نتائج بحث فعلية لإخراج queue تشغيلي.'
        : 'الحزمة حللت ${results.length} نتيجة، $reviewItems منها تحتاج مراجعة، و$missingGeometry بلا مرجع مكاني.';

    return SmartExplorerSelfDevelopmentPack(
      generatedAt: DateTime.now(),
      scopeLabelAr: query.trim().isEmpty ? 'نطاق غير محدد' : query.trim(),
      summaryAr: summary,
      guardRails: guardRails,
      workItems: workItems,
      acceptanceChecks: acceptanceChecks,
      errorRecords: errorRecords,
      localAnalyzerInputs: localAnalyzerInputs,
      nextPatchPlan: nextPatchPlan,
    );
  }

  SmartExplorerLocalAnalyzerContract buildLocalAnalyzerContract({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
  }) {
    return SmartExplorerLocalAnalyzerContract(
      generatedAt: DateTime.now(),
      scopeLabelAr: query.trim().isEmpty ? 'نطاق غير محدد' : query.trim(),
      contractItems: <SmartExplorerLocalAnalyzerContractItem>[
        SmartExplorerLocalAnalyzerContractItem(
          nameAr: 'نطاق البحث الحالي',
          formatAr: 'نص عربي/إنجليزي قصير',
          sourceAr: 'SmartExplorerState.query',
          noteAr: query.trim().isEmpty ? 'غائب حاليًا.' : 'متوفر.',
          isRequired: true,
          isBlockingWhenMissing: query.trim().isEmpty,
        ),
        SmartExplorerLocalAnalyzerContractItem(
          nameAr: 'نتائج المستكشف المرشحة',
          formatAr: 'List<SmartExplorerResult>',
          sourceAr: 'repository.search + filters',
          noteAr: 'العدد الحالي: ${results.length}.',
          isRequired: true,
          isBlockingWhenMissing: results.isEmpty,
        ),
        SmartExplorerLocalAnalyzerContractItem(
          nameAr: 'تحليل الوثيقة',
          formatAr: 'SmartExplorerDocumentAnalysis',
          sourceAr: 'analyzeDocumentDraft',
          noteAr: documentAnalysis == null
              ? 'غير مولد؛ مطلوب للتحليل التاريخي/المكاني الجاد.'
              : '${documentAnalysis.entities.length} مسميات و${documentAnalysis.boundaryClues.length} قرائن حدود.',
          isRequired: true,
          isBlockingWhenMissing: documentAnalysis == null,
        ),
        SmartExplorerLocalAnalyzerContractItem(
          nameAr: 'مصفوفة الأدلة',
          formatAr: 'SmartExplorerEvidenceMatrix',
          sourceAr: 'buildEvidenceMatrix',
          noteAr: evidenceMatrix == null
              ? 'غير مولدة؛ تقلل قابلية التحقق.'
              : '${evidenceMatrix.links.length} روابط أدلة.',
          isRequired: true,
          isBlockingWhenMissing: evidenceMatrix == null,
        ),
        SmartExplorerLocalAnalyzerContractItem(
          nameAr: 'بطاقة الجودة',
          formatAr: 'SmartExplorerQualityScorecard',
          sourceAr: 'buildQualityScorecard',
          noteAr: qualityScorecard?.summaryAr ?? 'غير مولدة.',
          isRequired: false,
          isBlockingWhenMissing: false,
        ),
        SmartExplorerLocalAnalyzerContractItem(
          nameAr: 'تشخيص التشغيل',
          formatAr: 'SmartExplorerRuntimeDiagnostics',
          sourceAr: 'buildRuntimeDiagnostics',
          noteAr: runtimeDiagnostics?.summaryAr ?? 'غير مولد.',
          isRequired: false,
          isBlockingWhenMissing: false,
        ),
      ],
      rejectedInputs: <String>[
        'أي SQL مباشر يعدّل waqf_assets أو awqaf_system أو core.',
        'أي ملف map/router/search قديم من overlay سابق.',
        'أي نتيجة OCR بلا مصدر أو ثقة أو مراجعة بشرية.',
        'أي تغيير activeLayers من داخل smart_explorer.',
      ],
      routingRules: <String>[
        'نتائج بلا هندسة: review queue قبل الخريطة.',
        'نتائج بلا قطع: evidence matrix ثم audit request اختياري.',
        'نتائج عالية الثقة: map handoff فقط دون كتابة سيادية.',
        'نتائج متعارضة تاريخيًا: mustakshif review board قبل أي اعتماد.',
      ],
      productionCutoverBlocks: <String>[
        'غياب RBAC إنتاجي مثبت لمسارات mustakshif/write.',
        'غياب Storage policy للمرفقات والأدلة.',
        'غياب flutter analyze محلي بعد تطبيق overlay.',
        'غياب قبول يدوي لسلوك الخريطة navigation-only بعد الدمج.',
      ],
    );
  }

  String buildSelfDevelopmentCsv({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerSourceAcquisitionPlan? sourcePlan,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildSelfDevelopmentPack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      sourcePlan: sourcePlan,
      releaseReadiness: releaseReadiness,
    ).toCsvText();
  }


  SmartExplorerAutonomousQaPack buildAutonomousQaPack({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerSourceAcquisitionPlan? sourcePlan,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    final scope = query.trim().isEmpty ? 'غير محدد' : query.trim();
    final total = results.length;
    final needsReview = results.where((item) => item.needsReview).length;
    final missingGeometry = results.where((item) => !item.hasAnySpatialReference).length;
    final missingParcels = results.where((item) => !item.hasLinkedParcels).length;
    final criticalSignals = results.fold<int>(
      0,
      (sum, item) => sum + item.severityCount(SmartExplorerSignalSeverity.critical),
    );
    final averageConfidence = total == 0
        ? 0
        : (results.fold<int>(0, (sum, item) => sum + item.confidenceScore) / total).round();
    final hasDocumentSeed = documentAnalysis != null && documentAnalysis.entities.isNotEmpty;
    final hasEvidenceSeed = evidenceMatrix != null && evidenceMatrix.links.isNotEmpty;
    final hasRuntimeBlocking = (runtimeDiagnostics?.blockingItems ?? 0) > 0;
    final hasQualitySignal = qualityScorecard != null;
    final hasSourcePlan = sourcePlan != null;
    final hasReleaseReadiness = releaseReadiness != null;

    SmartExplorerAutonomousQaLevel levelFor({
      required bool blocking,
      required bool warning,
    }) {
      if (blocking) return SmartExplorerAutonomousQaLevel.blocking;
      if (warning) return SmartExplorerAutonomousQaLevel.warning;
      return SmartExplorerAutonomousQaLevel.pass;
    }

    final gates = <SmartExplorerAutonomousQaGate>[
      SmartExplorerAutonomousQaGate(
        titleAr: 'حماية baseline الحالي من downgrade',
        level: SmartExplorerAutonomousQaLevel.pass,
        isBlocking: false,
        measureAr: 'المخرجات الجديدة مسماة باسم المستكشف الذكي ولا تتضمن map/router.',
        evidenceAr: 'قاعدة الاستبعاد: lib/router.dart و lib/features/map/**.',
        nextActionAr: 'طبّق baseline overlay فوق baseline الحالي فقط ولا تنسخ ملفات الخريطة.',
      ),
      SmartExplorerAutonomousQaGate(
        titleAr: 'كفاية نطاق البحث',
        level: levelFor(blocking: total == 0, warning: total < 5 && total > 0),
        isBlocking: total == 0,
        measureAr: '$total نتيجة ضمن النطاق.',
        evidenceAr: total == 0
            ? 'لا توجد نتائج يمكن اختبارها.'
            : 'يوجد نطاق عمل قابل للتحليل.',
        nextActionAr: total == 0
            ? 'نفّذ بحثًا أوليًا قبل توليد قرارات تشغيلية.'
            : 'تابع توليد QA/أدلة/مراجعة حسب الأولوية.',
      ),
      SmartExplorerAutonomousQaGate(
        titleAr: 'موانع التمثيل المكاني',
        level: levelFor(blocking: missingGeometry > 0, warning: false),
        isBlocking: missingGeometry > 0,
        measureAr: '$missingGeometry من أصل $total بلا هندسة أو مركز أو centroid.',
        evidenceAr: missingGeometry > 0
            ? 'لا يجوز إرسال هذه النتائج كهدف خريطة نهائي.'
            : 'كل النتائج الحالية تحمل مرجعًا مكانيًا أو لا توجد نتائج.',
        nextActionAr: missingGeometry > 0
            ? 'حوّلها إلى review queue مع قرائن وثيقة/مسميات قبل handoff للخريطة.'
            : 'استخدم map handoff دون تعديل منطق الخريطة.',
      ),
      SmartExplorerAutonomousQaGate(
        titleAr: 'جودة ربط القطع',
        level: levelFor(blocking: false, warning: missingParcels > 0),
        isBlocking: false,
        measureAr: '$missingParcels نتيجة بلا قطع مرتبطة.',
        evidenceAr: 'ربط القطع مساعد ولا يصبح مصدر حقيقة سياديًا من smart_explorer.',
        nextActionAr: missingParcels > 0
            ? 'عالجها عبر مصفوفة الأدلة ومسار التدقيق لا عبر كتابة مباشرة في waqf_assets.'
            : 'حافظ على الربط كقرينة مساعدة.',
      ),
      SmartExplorerAutonomousQaGate(
        titleAr: 'الإشارات الحرجة وقائمة المراجعة',
        level: levelFor(blocking: criticalSignals > 0, warning: needsReview > 0),
        isBlocking: criticalSignals > 0,
        measureAr: '$criticalSignals إشارة حرجة، و$needsReview نتيجة تحتاج مراجعة.',
        evidenceAr: 'الإشارات الحرجة تمنع الاعتماد الآلي وتفرض review board.',
        nextActionAr: criticalSignals > 0
            ? 'أنشئ طلب تدقيق فقط، ولا تعتمد النتيجة كحقيقة.'
            : needsReview > 0
                ? 'راجع الأولويات قبل إنشاء طلبات التدقيق.'
                : 'لا توجد قائمة مراجعة ضاغطة حاليًا.',
      ),
      SmartExplorerAutonomousQaGate(
        titleAr: 'بذور الوثائق والأدلة',
        level: levelFor(blocking: !hasDocumentSeed && !hasEvidenceSeed, warning: !hasDocumentSeed || !hasEvidenceSeed),
        isBlocking: !hasDocumentSeed && !hasEvidenceSeed,
        measureAr: 'وثيقة: ${hasDocumentSeed ? 'موجودة' : 'غير موجودة'}، مصفوفة أدلة: ${hasEvidenceSeed ? 'موجودة' : 'غير موجودة'}.',
        evidenceAr: 'المحلل المحلي يحتاج بذور تحقق ولا يكفي بحث الأسماء فقط.',
        nextActionAr: !hasDocumentSeed && !hasEvidenceSeed
            ? 'ولّد تحليل الوثيقة أو مصفوفة الأدلة قبل analyzer closure.'
            : 'استكمل ربط الأدلة بمخرجات QA.',
      ),
      SmartExplorerAutonomousQaGate(
        titleAr: 'تشخيص التشغيل',
        level: levelFor(blocking: hasRuntimeBlocking, warning: runtimeDiagnostics == null),
        isBlocking: hasRuntimeBlocking,
        measureAr: runtimeDiagnostics?.summaryAr ?? 'لم يتم توليد تشخيص تشغيل.',
        evidenceAr: runtimeDiagnostics == null
            ? 'غياب التشخيص ليس خطأ compile لكنه يضعف قرار الدمج.'
            : 'التشخيص مولد من workspace الحالي.',
        nextActionAr: hasRuntimeBlocking
            ? 'أغلق موانع التشخيص قبل توسيع الدفعة.'
            : 'ولّد التشخيص بعد كل نطاق عمل مهم.',
      ),
      SmartExplorerAutonomousQaGate(
        titleAr: 'اكتمال حزمة readiness',
        level: levelFor(
          blocking: false,
          warning: !hasQualitySignal || !hasSourcePlan || !hasReleaseReadiness,
        ),
        isBlocking: false,
        measureAr: 'جودة: ${hasQualitySignal ? 'نعم' : 'لا'}، مصادر: ${hasSourcePlan ? 'نعم' : 'لا'}، إصدار: ${hasReleaseReadiness ? 'نعم' : 'لا'}.',
        evidenceAr: 'هذه عناصر مساعدة لاعتماد overlay وليست شرط compile.',
        nextActionAr: 'ولّد بطاقة الجودة وخطة المصادر وجاهزية الإصدار قبل تسليم حزمة نهائية واسعة.',
      ),
      SmartExplorerAutonomousQaGate(
        titleAr: 'متوسط الثقة',
        level: levelFor(blocking: false, warning: total > 0 && averageConfidence < 55),
        isBlocking: false,
        measureAr: '$averageConfidence% متوسط ثقة.',
        evidenceAr: 'انخفاض الثقة ينقل النتائج إلى مراجعة، لا إلى اعتماد مباشر.',
        nextActionAr: averageConfidence < 55 && total > 0
            ? 'اربط نتائج البحث بقرائن وثيقة أو مصادر تاريخية.'
            : 'استمر في المسار الحالي مع توثيق مصادر الثقة.',
      ),
    ];

    final mergeControls = <String>[
      'تطبيق ملفات lib/features/smart_explorer/** فقط من baseline overlay.',
      'عدم نسخ lib/router.dart من أي مخرجات مستكشف ذكي.',
      'عدم نسخ lib/features/map/** من أي مخرجات مستكشف ذكي.',
      'عدم تغيير activeLayers أو zoom-driven/bbox behavior من smart_explorer.',
      'تشغيل flutter analyze بعد الدمج المحلي وإرجاع الأخطاء إن ظهرت.',
      'فتح /admin/smart-explorer واختبار أزرار: QA ذاتي، CSV QA، Runbook دمج، بيان baseline المسمى.',
    ];

    final namingControls = <String>[
      'كل ZIP جديد يبدأ بـ PALWAKF_SMART_EXPLORER_المستكشف_الذكي.',
      'كل handoff يبدأ بـ SESSION_HANDOFF_SMART_EXPLORER_المستكشف_الذكي.',
      'كل changelog يبدأ بـ BASELINE_CHANGELOG_SMART_EXPLORER_المستكشف_الذكي.',
      'لا تستخدم اسم EXPLORER وحده في مخرجات المستكشف الذكي.',
      'لا تستخدم اسم MUSTAKSHIF_ORIGINAL أو ORIGINAL_EXPLORER لحزم smart_explorer.',
    ];

    final localCommands = <String>[
      'flutter pub get',
      'flutter analyze',
      'flutter run -d chrome',
      'اختبار /admin/smart-explorer',
      'اختبار نسخ exportText وتنزيل CSV إن كان تنزيل المتصفح متاحًا',
    ];

    final blockingNotes = <String>[
      'waqf_assets يبقى الكيان التشغيلي المركزي، ولا يتم تحديثه من هذه الحزمة.',
      'awqaf_system Master Data، وmustakshif للتحليل والمراجعة فقط.',
      'أي ربط خريطة يتم كتقرير/سياق ولا يبدل ملفات الخريطة الحالية.',
      if (criticalSignals > 0) 'توجد إشارات حرجة؛ ممنوع اعتماد النتائج دون Review Board.',
      if (missingGeometry > 0) 'توجد نتائج بلا تمثيل مكاني؛ ممنوع handoff خريطة نهائي لها.',
      if (runtimeDiagnostics == null) 'لم يولد تشخيص التشغيل بعد؛ يفضل توليده قبل التسليم النهائي.',
    ];

    final nextBatchPlan = <String>[
      'إضافة لوحة intake لنتائج flutter analyze عندما يرسلها المستخدم.',
      'إضافة مصنف أخطاء متكرر يربط الخطأ بالملف والسبب والحل وآخر baseline مستقر.',
      'إضافة runbook اعتماد إنتاجي read-only قبل أي SQL/RPC جديد.',
      'تحضير حزمة دمج نهائية عند توفر baseline الحالي الكامل من المستكشف الأصلي.',
    ];

    return SmartExplorerAutonomousQaPack(
      generatedAt: DateTime.now(),
      scopeLabelAr: scope,
      summaryAr:
          'QA ذاتي: ${gates.where((gate) => gate.level == SmartExplorerAutonomousQaLevel.pass).length} مغلق، ${gates.where((gate) => gate.level == SmartExplorerAutonomousQaLevel.warning).length} تنبيه، ${gates.where((gate) => gate.level == SmartExplorerAutonomousQaLevel.blocking).length} مانع.',
      gates: gates,
      mergeControls: mergeControls,
      namingControls: namingControls,
      localCommands: localCommands,
      blockingNotes: blockingNotes,
      nextBatchPlan: nextBatchPlan,
    );
  }

  String buildAutonomousQaCsv({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerSourceAcquisitionPlan? sourcePlan,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildAutonomousQaPack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      sourcePlan: sourcePlan,
      releaseReadiness: releaseReadiness,
    ).toCsvText();
  }

  String buildMergeReadinessRunbook({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
  }) {
    final guard = buildCurrentBaselineGuard(query: query);
    final qa = buildAutonomousQaPack(
      query: query,
      results: results,
      runtimeDiagnostics: runtimeDiagnostics,
    );
    final buffer = StringBuffer()
      ..writeln('Runbook دمج المستكشف الذكي فوق baseline الحالي')
      ..writeln('وقت التوليد: ${DateTime.now().toIso8601String()}')
      ..writeln('النطاق: ${query.trim().isEmpty ? 'غير محدد' : query.trim()}')
      ..writeln('قرار QA: ${qa.readinessLabelAr}')
      ..writeln('---')
      ..writeln('1) قاعدة الدمج')
      ..writeln('- استخدم baseline الحالي للمستكشف الأصلي كمصدر حقيقة للخريطة والبحث والراوتر.')
      ..writeln('- طبّق فقط ملفات المستكشف الذكي والوثائق المرفقة في هذه الحزمة.')
      ..writeln('- لا تنسخ أي ملف من lib/features/map/** أو lib/router.dart.')
      ..writeln('---')
      ..writeln('2) حارس baseline')
      ..writeln(guard.toReportText())
      ..writeln('---')
      ..writeln('3) QA قبل الدمج')
      ..writeln(qa.toReportText())
      ..writeln('---')
      ..writeln('4) قبول محلي')
      ..writeln('[ ] flutter pub get')
      ..writeln('[ ] flutter analyze')
      ..writeln('[ ] فتح /admin/smart-explorer')
      ..writeln('[ ] توليد QA ذاتي')
      ..writeln('[ ] توليد Runbook دمج')
      ..writeln('[ ] توليد بيان baseline المسمى')
      ..writeln('[ ] اختبار عدم كسر الخريطة الحالية')
      ..writeln('---')
      ..writeln('5) قرار')
      ..writeln('إذا ظهرت أخطاء analyzer، عالجها موضعيًا داخل smart_explorer فقط ما لم يثبت أن الخطأ من baseline الحالي.');
    return buffer.toString();
  }

  SmartExplorerNamedBaselineManifest buildNamedBaselineManifest() {
    return SmartExplorerNamedBaselineManifest(
      generatedAt: DateTime.now(),
      batchLabelAr: 'Smart Explorer 2 — Big Batch N — Autonomous QA Baseline',
      allowedOutputPrefixes: const <String>[
        'PALWAKF_SMART_EXPLORER_المستكشف_الذكي_',
        'SESSION_HANDOFF_SMART_EXPLORER_المستكشف_الذكي_',
        'BASELINE_CHANGELOG_SMART_EXPLORER_المستكشف_الذكي_',
        'NEXT_SESSION_PROMPT_SMART_EXPLORER_المستكشف_الذكي_',
      ],
      forbiddenOutputLabels: const <String>[
        'PALWAKF_EXPLORER_ONLY',
        'MUSTAKSHIF_ORIGINAL',
        'ORIGINAL_EXPLORER_BASELINE',
        'MAP_BASELINE_FROM_SMART_EXPLORER',
      ],
      includedPathRules: const <String>[
        'lib/features/smart_explorer/**',
        'docs/smart_explorer/**',
        'instructions/**',
        'BASELINE_CHANGELOG_SMART_EXPLORER_المستكشف_الذكي_*.md',
        'SESSION_HANDOFF_SMART_EXPLORER_المستكشف_الذكي_*.md',
      ],
      excludedPathRules: const <String>[
        'lib/router.dart',
        'lib/features/map/**',
        '*.diff',
        'أي ملف يحمل اسم المستكشف الأصلي دون smart_explorer',
      ],
      releaseNotes: const <String>[
        'هذه الحزمة baseline overlay للمستكشف الذكي فقط.',
        'تحديثات الخريطة والبحث والراوتر يجب أن تأتي من baseline الحالي للمستكشف الأصلي.',
        'لا يوجد SQL إنتاجي ولا RLS جديد ولا تعديل مباشر على waqf_assets.',
        'يجب تشغيل flutter analyze محليًا بعد الدمج.',
      ],
    );
  }

  String buildNamedBaselineManifestText() {
    return buildNamedBaselineManifest().toReportText();
  }


  SmartExplorerOperationalStagePack buildOperationalIntegrationStagePack({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    final scope = query.trim().isEmpty ? 'نطاق عام داخل المستكشف الذكي' : query.trim();
    final total = results.length;
    final reviewQueue = results.where((result) => result.needsReview).length;
    final criticalSignals = results
        .expand((result) => result.gapSignals)
        .where((signal) => signal.severityCode == 'critical')
        .length;
    final missingGeometry = results.where((result) => !result.hasGeometry).length;
    final hasEvidence = evidenceMatrix != null || documentAnalysis != null;
    final hasRuntime = runtimeDiagnostics != null;
    final releaseLabel = releaseReadiness == null ? 'غير مولدة' : 'مولدة';

    SmartExplorerAcceptanceLevel levelFor({required bool blocking, required bool warning}) {
      if (blocking) return SmartExplorerAcceptanceLevel.blocking;
      if (warning) return SmartExplorerAcceptanceLevel.warning;
      return SmartExplorerAcceptanceLevel.pass;
    }

    final tracks = <SmartExplorerOperationalTrack>[
      const SmartExplorerOperationalTrack(
        titleAr: 'دمج الواجهة داخل صفحة المستكشف الذكي',
        goalAr: 'توفير أدوات التشغيل من نفس الصفحة دون إنشاء مسار منفصل أو shell جديد.',
        statusLabelAr: 'جاهز كـ read-only overlay',
        ownerBoundaryAr: 'smart_explorer فقط، مع احترام route الحالي من baseline المستكشف.',
        outputs: <String>[
          'أزرار تشغيل',
          'تقارير نصية',
          'CSV مساعد',
          'دليل استخدام داخل المشروع',
        ],
      ),
      const SmartExplorerOperationalTrack(
        titleAr: 'ربط المراجعة والتدقيق',
        goalAr: 'تحويل نتائج البحث إلى سياق تدقيق قابل للمتابعة دون اعتماد تلقائي.',
        statusLabelAr: 'جاهز للتشغيل المقيد',
        ownerBoundaryAr: 'الكتابة تبقى عبر مسار Explorer Gap Audit المعتمد فقط.',
        outputs: <String>[
          'حزمة توريث',
          'سجل قرارات',
          'بوابة إغلاق',
          'حزمة تسليم',
        ],
      ),
      const SmartExplorerOperationalTrack(
        titleAr: 'تشغيل المعرفة والدليل',
        goalAr: 'تزويد المستخدمين بدليل استعمال وتدريب وتشخيص مشاكل داخل المشروع.',
        statusLabelAr: 'مضاف في هذه المرحلة',
        ownerBoundaryAr: 'وثائق docs/smart_explorer وأدوات exportText داخل الصفحة.',
        outputs: <String>[
          'دليل استخدام',
          'بطاقة بدء سريع',
          'Checklist قبول',
          'Troubleshooting',
        ],
      ),
      const SmartExplorerOperationalTrack(
        titleAr: 'حماية الخريطة والبحث والراوتر',
        goalAr: 'منع أي تراجع في baseline المستكشف الأصلي بعد نجاح الاندماج.',
        statusLabelAr: 'محمي',
        ownerBoundaryAr: 'لا يملك smart_explorer استبدال lib/router.dart أو lib/features/map/**.',
        outputs: <String>[
          'حارس baseline',
          'بيان تسمية',
          'موانع دمج',
        ],
      ),
    ];

    final gates = <SmartExplorerAcceptanceGate>[
      SmartExplorerAcceptanceGate(
        titleAr: 'سلامة scope الملفات',
        level: SmartExplorerAcceptanceLevel.pass,
        measureAr: 'التطوير محصور في lib/features/smart_explorer/** و docs/instructions.',
        evidenceAr: 'لا حاجة لاستبدال الخريطة أو الراوتر في هذه المرحلة.',
        nextActionAr: 'طبّق الحزمة فوق baseline الحالي ثم شغّل analyzer محليًا.',
      ),
      SmartExplorerAcceptanceGate(
        titleAr: 'توفر نتائج تشغيلية',
        level: levelFor(blocking: false, warning: total == 0),
        measureAr: 'عدد النتائج الحالية: $total.',
        evidenceAr: total == 0
            ? 'يمكن تشغيل المرحلة دون نتائج، لكن قبول الاندماج يحتاج سيناريو بحث فعلي.'
            : 'توجد نتائج يمكن بناء تقارير التشغيل عليها.',
        nextActionAr: total == 0 ? 'نفذ بحثًا تجريبيًا مثل اسم وقف/موقع قبل قبول التشغيل.' : 'راجع طابور النتائج ذات الأولوية.',
      ),
      SmartExplorerAcceptanceGate(
        titleAr: 'طابور المراجعة',
        level: levelFor(blocking: criticalSignals > 0, warning: reviewQueue > 0),
        measureAr: '$reviewQueue نتيجة تحتاج مراجعة، $criticalSignals إشارات حرجة.',
        evidenceAr: 'المستكشف الذكي لا يعتمد النتائج الحرجة تلقائيًا.',
        nextActionAr: criticalSignals > 0
            ? 'وجّه النتائج الحرجة إلى Review Board قبل أي اعتماد.'
            : 'أنشئ طلبات تدقيق للنتائج ذات الأولوية عند الحاجة.',
      ),
      SmartExplorerAcceptanceGate(
        titleAr: 'الأدلة والوثائق',
        level: levelFor(blocking: false, warning: !hasEvidence),
        measureAr: hasEvidence ? 'توجد أدلة/تحليل وثيقة.' : 'لا توجد مصفوفة أدلة أو تحليل وثيقة بعد.',
        evidenceAr: 'الأدلة شرط جودة لا شرط تشغيل أولي.',
        nextActionAr: hasEvidence ? 'اربط الأدلة بسجل القرار.' : 'حلل وثيقة أو ولّد مصفوفة أدلة قبل التسليم النهائي.',
      ),
      SmartExplorerAcceptanceGate(
        titleAr: 'الهندسة والتمثيل المكاني',
        level: levelFor(blocking: false, warning: missingGeometry > 0),
        measureAr: '$missingGeometry نتيجة بلا هندسة من أصل $total.',
        evidenceAr: 'غياب الهندسة يمنع اعتماد توجيه خريطة نهائي لكنه لا يمنع التقرير.',
        nextActionAr: missingGeometry > 0
            ? 'استخدم حزمة التدقيق أو المصادر لتصحيح الربط المكاني.'
            : 'استمر إلى اختبار الفتح على الخريطة الحالية.',
      ),
      SmartExplorerAcceptanceGate(
        titleAr: 'تشخيص التشغيل',
        level: levelFor(blocking: false, warning: !hasRuntime),
        measureAr: runtimeDiagnostics?.summaryAr ?? 'لم يتم توليد تشخيص تشغيل في الحالة الحالية.',
        evidenceAr: 'التشخيص يساعد في قرار cutover ولا يكتب بيانات.',
        nextActionAr: hasRuntime ? 'احفظ التشخيص ضمن حزمة التسليم.' : 'ولّد تشخيص تشغيل قبل الاندماج التشغيلي النهائي.',
      ),
      SmartExplorerAcceptanceGate(
        titleAr: 'جاهزية الإصدار',
        level: levelFor(blocking: false, warning: releaseReadiness == null),
        measureAr: 'حالة الجاهزية: $releaseLabel.',
        evidenceAr: 'جاهزية الإصدار تلخص جودة التشغيل ومخاطر الاعتماد.',
        nextActionAr: releaseReadiness == null ? 'ولّد جاهزية إصدار بعد بطاقة الجودة ودليل التدقيق.' : 'اربطها ببوابة الإغلاق.',
      ),
    ];

    final cutoverSteps = <String>[
      'نسخ ملفات lib/features/smart_explorer/** فقط فوق baseline المستكشف الحالي.',
      'نسخ docs/smart_explorer/** و instructions/** لتثبيت دليل الاستخدام والتشغيل.',
      'عدم نسخ lib/router.dart أو lib/features/map/** من أي حزمة مستكشف ذكي.',
      'تشغيل flutter pub get ثم flutter analyze محليًا.',
      'فتح /admin/smart-explorer واختبار البحث، تحليل الوثيقة، حزمة التسليم، دليل الاستخدام، Checklist القبول.',
      'تشغيل سيناريو بحث واقعي، ثم توليد QA ذاتي وتشخيص تشغيل وجاهزية إصدار.',
      'اعتماد read-only أولًا، ثم تفعيل إنشاء طلبات التدقيق فقط إذا كانت RPC موجودة ومجربة.',
    ];

    final runtimeRules = <String>[
      'waqf_assets هو الكيان التشغيلي المركزي والربط يكون عبر waqf_asset_id عند توفره.',
      'awqaf_system Master Data، وmustakshif للتحليل والمراجعة فقط.',
      'النتائج الذكية توصيات وقرائن، وليست قرارات سيادية مباشرة.',
      'أوامر القوائم والخريطة navigation-only ولا تغير activeLayers.',
      'لا SQL إنتاجي ولا RLS جديد داخل هذه المرحلة.',
      'أي خطأ متكرر يوثق في Error Record مع السبب والملف والحل وآخر baseline مستقر.',
    ];

    final blockingNotes = <String>[
      if (criticalSignals > 0) 'توجد إشارات حرجة ويجب عرضها على Review Board قبل الاعتماد.',
      if (missingGeometry > 0) 'توجد نتائج بلا هندسة؛ لا تعتمد توجيه الخريطة لها دون تدقيق.',
      if (!hasEvidence) 'مصفوفة الأدلة غير مولدة بعد؛ يوصى بتوليدها قبل التسليم النهائي.',
      if (!hasRuntime) 'تشخيص التشغيل غير مولد؛ يوصى بتوليده قبل cutover.',
      'المرحلة الحالية تؤهل الاندماج التشغيلي لكنها لا تستبدل baseline المستكشف الأصلي.',
    ];

    final nextOperatorActions = <String>[
      'ولّد دليل الاستخدام من الزر الجديد واحفظه في وثائق المشروع.',
      'ولّد Checklist القبول وشغّلها على baseline المستكشف الحالي.',
      'أرسل أخطاء flutter analyze إن ظهرت لعلاجها موضعيًا.',
      'بعد قبول التشغيل read-only، انتقل إلى مرحلة الربط الفعلي مع Review Board والتدقيق.',
    ];

    return SmartExplorerOperationalStagePack(
      generatedAt: DateTime.now(),
      stageLabelAr: 'SMART_EXPLORER / المستكشف الذكي — Integrated Stage O — Operational User Guide Baseline',
      scopeLabelAr: scope,
      summaryAr: 'مرحلة متكاملة تجهز المستكشف الذكي للاندماج التشغيلي داخل المستكشف الحالي مع دليل استخدام وقبول تشغيل.',
      integrationTracks: tracks,
      acceptanceGates: gates,
      cutoverSteps: cutoverSteps,
      runtimeRules: runtimeRules,
      blockingNotes: blockingNotes,
      nextOperatorActions: nextOperatorActions,
    );
  }

  SmartExplorerUserGuidePack buildUserGuidePack() {
    return SmartExplorerUserGuidePack(
      generatedAt: DateTime.now(),
      titleAr: 'دليل استخدام المستكشف الذكي داخل مستكشف PalWakf',
      audienceAr: 'مشغلو المستكشف، فرق التدقيق، الإدارة، ومطورو PalWakf',
      quickStartSteps: const <String>[
        'افتح المسار /admin/smart-explorer من داخل منصة PalWakf.',
        'اكتب اسم وقف أو موقع أو رقم مرجعي في مربع البحث.',
        'راجع بطاقة النتيجة: الثقة، الأولوية، الفجوات، والتمثيل المكاني.',
        'حلل وثيقة أو نصًا تاريخيًا عند توفر مصدر داعم.',
        'ولّد مصفوفة أدلة، بطاقة جودة، تشخيص تشغيل، ثم حزمة تسليم.',
        'استخدم أزرار الجسر للتجهيز للخريطة أو التدقيق دون تعديل طبقات الخريطة مباشرة.',
        'عند وجود فجوة مؤكدة، أنشئ طلب تدقيق عبر مسار Explorer Gap Audit فقط.',
      ],
      workflows: const <SmartExplorerUserWorkflow>[
        SmartExplorerUserWorkflow(
          titleAr: 'بحث وقف أو موقع',
          goalAr: 'العثور على أصول أو قرائن مرتبطة باسم أو نطاق جغرافي.',
          inputs: <String>['اسم الوقف', 'اسم الموقع', 'رقم وطني أو مرجع داخلي'],
          steps: <String>[
            'إدخال الاستعلام في مربع البحث.',
            'تصفية النتائج حسب الأولوية أو مستوى الثقة.',
            'فتح النتيجة الأعلى ومراجعة الفجوات.',
            'توليد فرضية أو تقرير مختصر إذا كانت النتيجة تحتاج متابعة.',
          ],
          outputs: <String>['نتائج مرتبة', 'فجوات مراجعة', 'حزمة تقرير'],
        ),
        SmartExplorerUserWorkflow(
          titleAr: 'تحليل وثيقة تاريخية أو وصفية',
          goalAr: 'استخراج قرائن مكانية وزمنية من نص غير منظم.',
          inputs: <String>['نص وثيقة', 'وصف حدود', 'أسماء معالم', 'أرقام قطع أو أحواض'],
          steps: <String>[
            'لصق النص في صندوق تحليل الوثيقة.',
            'تشغيل التحليل ومراجعة الكيانات المستخرجة.',
            'توليد Gazetteer ومصفوفة أدلة عند الحاجة.',
            'عدم اعتماد النتيجة إلا بعد مراجعة بشرية للمصدر.',
          ],
          outputs: <String>['كيانات', 'قرائن حدودية', 'فرضيات مكانية', 'مصفوفة أدلة'],
        ),
        SmartExplorerUserWorkflow(
          titleAr: 'تحضير تدقيق تشغيلي',
          goalAr: 'تحويل نتيجة مشكوك فيها إلى طلب تدقيق قابل للمتابعة.',
          inputs: <String>['نتيجة تحتاج مراجعة', 'مصفوفة أدلة', 'سبب الفجوة'],
          steps: <String>[
            'توليد سجل مخاطر أو QA.',
            'توليد Checklist ميداني أو دليل تدقيق.',
            'إنشاء طلب تدقيق إذا كان المسار مفعلًا ومجربًا.',
            'متابعة الطلب من لوحة gap audits أو audit tasks.',
          ],
          outputs: <String>['طلب تدقيق', 'سياق مراجعة', 'إجراء مقترح'],
        ),
        SmartExplorerUserWorkflow(
          titleAr: 'تسليم حزمة قرار',
          goalAr: 'إعداد مخرجات منظمة للمدير أو لجنة المراجعة.',
          inputs: <String>['نتائج', 'أدلة', 'جودة', 'بوابة إغلاق'],
          steps: <String>[
            'توليد بطاقة الجودة وجاهزية الإصدار.',
            'توليد سجل قرارات وحزمة تسليم.',
            'نسخ النص أو تنزيل CSV عند توفره.',
            'إرفاق المخرجات في ملف الجلسة أو نظام المهام.',
          ],
          outputs: <String>['حزمة تسليم', 'قرار مراجعة', 'توريث جلسة'],
        ),
      ],
      roles: const <SmartExplorerUserRoleGuide>[
        SmartExplorerUserRoleGuide(
          roleAr: 'مشغل المستكشف',
          descriptionAr: 'ينفذ البحث والتحليل الأولي ويولد التقارير.',
          allowedActions: <String>['بحث', 'تصفية', 'تحليل وثيقة', 'توليد تقارير'],
          forbiddenActions: <String>['اعتماد سيادي نهائي', 'تعديل الخريطة', 'تغيير activeLayers'],
        ),
        SmartExplorerUserRoleGuide(
          roleAr: 'مراجع الأدلة',
          descriptionAr: 'يفحص مصفوفة الأدلة والفرضيات والفجوات.',
          allowedActions: <String>['مراجعة الأدلة', 'تحديد أولوية', 'طلب تدقيق'],
          forbiddenActions: <String>['تعديل master data مباشرة', 'اعتماد مصدر غير موثق'],
        ),
        SmartExplorerUserRoleGuide(
          roleAr: 'مدير النظام',
          descriptionAr: 'يتابع الجاهزية والتكامل والقبول المحلي.',
          allowedActions: <String>['تشغيل analyzer', 'اعتماد baseline', 'متابعة الأخطاء'],
          forbiddenActions: <String>['نسخ router/map من حزمة smart_explorer', 'تجاوز RLS/RBAC'],
        ),
      ],
      safetyRules: const <String>[
        'كل مخرجات المستكشف الذكي قرائن تشغيلية حتى تعتمدها جهة مراجعة.',
        'لا يجوز تعديل waqf_assets أو awqaf_system مباشرة من أدوات المستكشف الذكي.',
        'أي انتقال للخريطة يكون navigation-only ولا يغير طبقات الخريطة العامة.',
        'كل خطأ analyzer يوثق في Error Record قبل علاجه إذا كان متكررًا.',
        'كل baseline باسم المستكشف الذكي يجب أن يميز نفسه عن المستكشف الأصلي.',
      ],
      troubleshooting: const <SmartExplorerTroubleshootingItem>[
        SmartExplorerTroubleshootingItem(
          symptomAr: 'لا تظهر نتائج البحث',
          causeAr: 'الاستعلام قصير أو repository لا يعيد أصولًا من مصدر الوقف.',
          solutionAr: 'استخدم كلمة أطول أو اسمًا رسميًا أو تحقق من ربط WaqfAssetRepository.',
          escalationAr: 'أرسل نتيجة flutter analyze وسجل network/RPC إن وجد.',
        ),
        SmartExplorerTroubleshootingItem(
          symptomAr: 'زر الخريطة لا ينتقل كما هو متوقع',
          causeAr: 'النتيجة بلا هندسة أو baseline الخريطة الحالي لا يستقبل السياق.',
          solutionAr: 'ولّد تشخيص التشغيل وتحقق من hasGeometry/hasCenter ثم اختبر الخريطة الحالية.',
          escalationAr: 'لا تستبدل map files؛ عالج الجسر أو context فقط.',
        ),
        SmartExplorerTroubleshootingItem(
          symptomAr: 'أخطاء analyzer بعد الدمج',
          causeAr: 'اختلاف أسماء models/providers بين baseline الحالي وحزمة overlay.',
          solutionAr: 'عالج الاستيرادات والأنواع داخل smart_explorer موضعيًا.',
          escalationAr: 'أرسل الأخطاء كاملة مع اسم baseline المستقر الأخير.',
        ),
        SmartExplorerTroubleshootingItem(
          symptomAr: 'التنزيل غير مدعوم في المتصفح',
          causeAr: 'قيود بيئة Flutter Web أو الخدمة المتاحة.',
          solutionAr: 'استخدم النسخ إلى الحافظة كمسار بديل.',
          escalationAr: 'اختبر ExplorerExportDownloadService في المتصفح الحقيقي.',
        ),
      ],
      trainingExercises: const <String>[
        'ابحث عن وقف معروف ثم ولّد مصفوفة أدلة وبطاقة جودة.',
        'الصق وصف حدود تاريخي واستخرج الكيانات والفرضيات.',
        'اختر نتيجة بلا هندسة وولّد سجل مخاطر وخطة إجراء.',
        'ولّد دليل الاستخدام وChecklist القبول ثم قارنهما بنتيجة flutter analyze.',
      ],
    );
  }

  String buildUserGuideText() => buildUserGuidePack().toGuideText();

  String buildUserQuickStartText() => buildUserGuidePack().toQuickStartText();

  String buildOperationalAcceptanceChecklistText({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildOperationalIntegrationStagePack(
      query: query,
      results: results,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toChecklistText();
  }


  SmartExplorerRuntimeWiringStagePack buildActualRuntimeWiringStagePack({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    final scope = query.trim().isEmpty
        ? 'نطاق تشغيل عام داخل المستكشف الذكي'
        : query.trim();
    final total = results.length;
    final reviewQueue = results.where((result) => result.needsReview).length;
    final missingGeometry = results.where((result) => !result.hasGeometry).length;
    final withMapAnchor = results
        .where((result) => result.hasGeometry || result.hasCenter || result.hasCentroid)
        .length;
    final criticalSignals = results
        .expand((result) => result.gapSignals)
        .where((signal) => signal.severityCode == 'critical')
        .length;
    final hasAnalyzerSeed = documentAnalysis != null || evidenceMatrix != null;
    final hasQuality = qualityScorecard != null;
    final hasRuntime = runtimeDiagnostics != null;
    final hasRelease = releaseReadiness != null;

    SmartExplorerRuntimeWiringLevel levelFor({
      required bool blocking,
      required bool warning,
    }) {
      if (blocking) return SmartExplorerRuntimeWiringLevel.blocking;
      if (warning) return SmartExplorerRuntimeWiringLevel.warning;
      return SmartExplorerRuntimeWiringLevel.pass;
    }

    final runtimeLevel = smartExplorerRuntimeLevelFromDiagnostics(runtimeDiagnostics);
    final runtimeBlocking = runtimeLevel == SmartExplorerRuntimeWiringLevel.blocking;

    final tracks = <SmartExplorerRuntimeWiringTrack>[
      SmartExplorerRuntimeWiringTrack(
        titleAr: 'ربط نتائج المستكشف الذكي بسياق المستكشف الحالي',
        sourceAr: 'SmartExplorerResult + filteredResults',
        targetAr: 'لوحة المستكشف الحالي عبر exportText وسياق read-only',
        wiringModeAr: 'تشغيل داخل صفحة /admin/smart-explorer دون إنشاء route جديد ودون استبدال router.',
        statusAr: total == 0 ? 'جاهز بنيويًا ويحتاج سيناريو بحث' : 'جاهز للتجربة التشغيلية',
        blockerAr: total == 0 ? 'غياب سيناريو نتائج يمنع قبول runtime الكامل.' : 'لا يوجد مانع بنيوي من جهة المستكشف الذكي.',
        outputs: <String>[
          'حزمة تسليم',
          'تقرير تشغيل',
          'CSV مراجعة',
          'سياق تدقيق',
        ],
      ),
      SmartExplorerRuntimeWiringTrack(
        titleAr: 'ربط الخريطة عبر عقد navigation-only',
        sourceAr: 'hasGeometry / hasCenter / hasCentroid داخل النتائج',
        targetAr: 'baseline الخريطة الحالي في المستكشف الأصلي',
        wiringModeAr: 'تجهيز سياق انتقال فقط؛ لا تشغيل طبقات ولا تعديل activeLayers ولا نسخ lib/features/map/**.',
        statusAr: withMapAnchor == 0 ? 'يحتاج نتائج ذات مرجع مكاني' : 'جاهز لاختبار الانتقال',
        blockerAr: missingGeometry > 0 ? 'بعض النتائج بلا هندسة ولا تقبل اعتماد zoom نهائي.' : 'لا يوجد مانع مكاني ظاهر.',
        outputs: <String>[
          'سجل نتائج قابلة للانتقال',
          'تحذير نتائج بلا هندسة',
          'تعليمات اختبار الخريطة الحالية',
        ],
      ),
      SmartExplorerRuntimeWiringTrack(
        titleAr: 'ربط Review Board / Gap Audit',
        sourceAr: 'needsReview + gapSignals + createAuditRequestFromResult',
        targetAr: 'مسار Explorer Gap Audit المعتمد فقط',
        wiringModeAr: 'إنشاء طلبات تدقيق عند الحاجة عبر RPC/Repository الموجود دون أي كتابة مباشرة في core/waqf.',
        statusAr: reviewQueue == 0 ? 'لا يوجد طابور مراجعة حالي' : 'جاهز للتشغيل المقيد',
        blockerAr: criticalSignals > 0 ? 'الإشارات الحرجة تتطلب Review Board قبل الاعتماد.' : 'لا يوجد مانع تدقيق مباشر.',
        outputs: <String>[
          'طلبات تدقيق',
          'أولوية مراجعة',
          'سياق مصدر/دليل',
        ],
      ),
      SmartExplorerRuntimeWiringTrack(
        titleAr: 'ربط analyzer المحلي وإغلاق مخرجاته',
        sourceAr: 'تحليل الوثائق + مصفوفة الأدلة + بطاقة الجودة + التشخيص',
        targetAr: 'حزمة QA وتشخيص التشغيل داخل المستكشف الذكي',
        wiringModeAr: 'إغلاق analyzer كمدخل read-only ينتج توصيات ولا يكتب master data.',
        statusAr: hasAnalyzerSeed && hasQuality && hasRuntime ? 'جاهز للإغلاق المرحلي' : 'مفتوح جزئيًا',
        blockerAr: hasAnalyzerSeed ? 'لا يوجد مانع analyzer أساسي.' : 'غياب تحليل وثيقة/مصفوفة أدلة يمنع إغلاق analyzer الكامل.',
        outputs: <String>[
          'Analyzer closure',
          'Error Record',
          'QA gates',
          'Runtime wiring CSV',
        ],
      ),
    ];

    final analyzerClosures = <SmartExplorerAnalyzerClosureItem>[
      SmartExplorerAnalyzerClosureItem(
        titleAr: 'مدخلات analyzer',
        statusAr: hasAnalyzerSeed ? 'متوفرة' : 'غير مكتملة',
        isClosed: hasAnalyzerSeed,
        evidenceAr: hasAnalyzerSeed
            ? 'يوجد تحليل وثيقة أو مصفوفة أدلة في الحالة الحالية.'
            : 'لم يتم توليد تحليل وثيقة أو مصفوفة أدلة بعد.',
        nextActionAr: hasAnalyzerSeed
            ? 'اربط المدخلات ببطاقة الجودة والتشخيص.'
            : 'شغل تحليل وثيقة أو ولّد مصفوفة أدلة قبل إغلاق analyzer.',
      ),
      SmartExplorerAnalyzerClosureItem(
        titleAr: 'جودة مخرجات analyzer',
        statusAr: hasQuality ? 'مقاسة' : 'غير مقاسة',
        isClosed: hasQuality,
        evidenceAr: hasQuality
            ? 'تم توليد بطاقة جودة للمخرجات.'
            : 'بطاقة الجودة غير مولدة في الحالة الحالية.',
        nextActionAr: hasQuality
            ? 'استخدمها في قرار الجاهزية.'
            : 'ولّد بطاقة جودة بعد النتائج/الأدلة.',
      ),
      SmartExplorerAnalyzerClosureItem(
        titleAr: 'تشخيص runtime',
        statusAr: hasRuntime ? runtimeDiagnostics.summaryAr : 'غير مولد',
        isClosed: hasRuntime && !runtimeBlocking,
        evidenceAr: hasRuntime
            ? 'blocking=${runtimeDiagnostics.blockingItems}, warning=${runtimeDiagnostics.warningItems}'
            : 'لا يوجد SmartExplorerRuntimeDiagnostics في الحالة الحالية.',
        nextActionAr: hasRuntime
            ? (runtimeBlocking ? 'أغلق موانع التشخيص قبل الاندماج التشغيلي.' : 'احفظ التشخيص في حزمة التسليم.')
            : 'ولّد تشخيص تشغيل قبل cutover.',
      ),
      SmartExplorerAnalyzerClosureItem(
        titleAr: 'جاهزية الإصدار',
        statusAr: hasRelease ? 'مولدة' : 'غير مولدة',
        isClosed: hasRelease,
        evidenceAr: hasRelease
            ? 'جاهزية الإصدار موجودة وتدعم قرار Stage P.'
            : 'لا توجد جاهزية إصدار في الحالة الحالية.',
        nextActionAr: hasRelease
            ? 'اربطها ببوابة الإغلاق والتسليم.'
            : 'ولّد جاهزية إصدار بعد بطاقة الجودة ودليل التدقيق.',
      ),
    ];

    final gates = <SmartExplorerRuntimeWiringGate>[
      SmartExplorerRuntimeWiringGate(
        titleAr: 'سلامة نطاق الملفات',
        level: SmartExplorerRuntimeWiringLevel.pass,
        isBlocking: false,
        measureAr: 'Stage P محصور في smart_explorer/docs/instructions.',
        evidenceAr: 'لا يحتاج router أو map أو search baseline من المستكشف الذكي.',
        nextActionAr: 'طبق baseline فوق المستكشف الحالي مع منع استبدال lib/router.dart و lib/features/map/**.',
      ),
      SmartExplorerRuntimeWiringGate(
        titleAr: 'نتائج runtime قابلة للاختبار',
        level: levelFor(blocking: false, warning: total == 0),
        isBlocking: false,
        measureAr: 'عدد النتائج: $total.',
        evidenceAr: total == 0
            ? 'لا يمكن إثبات التشغيل الفعلي دون سيناريو بحث.'
            : 'توجد نتائج يمكن اختبارها داخل الصفحة.',
        nextActionAr: total == 0 ? 'شغل بحثًا واقعيًا قبل القبول النهائي.' : 'اختبر كل زر runtime على النتيجة الأعلى.',
      ),
      SmartExplorerRuntimeWiringGate(
        titleAr: 'جاهزية الربط المكاني',
        level: levelFor(blocking: false, warning: missingGeometry > 0 || withMapAnchor == 0),
        isBlocking: false,
        measureAr: '$withMapAnchor نتيجة لها مرجع انتقال، $missingGeometry نتيجة بلا هندسة.',
        evidenceAr: 'الربط المكاني يبقى navigation-only ويعتمد baseline الخريطة الحالي.',
        nextActionAr: withMapAnchor == 0
            ? 'اختبر على نتيجة لها مركز/هندسة قبل قبول map handoff.'
            : 'نفذ اختبار انتقال دون تشغيل/إطفاء طبقات.',
      ),
      SmartExplorerRuntimeWiringGate(
        titleAr: 'طابور التدقيق والمراجعة',
        level: levelFor(blocking: criticalSignals > 0, warning: reviewQueue > 0),
        isBlocking: criticalSignals > 0,
        measureAr: '$reviewQueue نتيجة تحتاج مراجعة، $criticalSignals إشارات حرجة.',
        evidenceAr: 'لا اعتماد تلقائي للنتائج الحرجة أو ذات الفجوات.',
        nextActionAr: criticalSignals > 0
            ? 'أرسل النتائج الحرجة إلى Review Board قبل cutover.'
            : 'أنشئ طلبات تدقيق للنتائج ذات الأولوية عند الحاجة.',
      ),
      SmartExplorerRuntimeWiringGate(
        titleAr: 'إغلاق analyzer',
        level: levelFor(blocking: false, warning: !hasAnalyzerSeed || !hasQuality),
        isBlocking: false,
        measureAr: "مدخلات analyzer=${hasAnalyzerSeed ? 'نعم' : 'لا'}، الجودة=${hasQuality ? 'نعم' : 'لا'}.",
        evidenceAr: 'إغلاق analyzer شرط لقبول التشغيل الكامل وليس شرطًا لعرض الصفحة.',
        nextActionAr: hasAnalyzerSeed && hasQuality
            ? 'احفظ Analyzer Closure ضمن baseline.'
            : 'ولّد الأدلة وبطاقة الجودة قبل الاندماج التشغيلي الكامل.',
      ),
      SmartExplorerRuntimeWiringGate(
        titleAr: 'تشخيص التشغيل',
        level: runtimeLevel,
        isBlocking: runtimeBlocking,
        measureAr: runtimeDiagnostics?.summaryAr ?? 'لم يتم توليد التشخيص.',
        evidenceAr: runtimeDiagnostics == null
            ? 'غياب التشخيص يعطي تنبيهًا لا مانعًا.'
            : 'blocking=${runtimeDiagnostics.blockingItems}, warning=${runtimeDiagnostics.warningItems}.',
        nextActionAr: runtimeDiagnostics == null
            ? 'ولّد تشخيص تشغيل قبل الاعتماد.'
            : (runtimeBlocking ? 'أغلق الموانع أولًا.' : 'احفظ التقرير ضمن التسليم.'),
      ),
    ];

    final hasBlocking = gates.any((gate) => gate.isBlocking);
    final hasWarnings = gates.any((gate) => gate.level == SmartExplorerRuntimeWiringLevel.warning);
    final decision = hasBlocking
        ? 'غير جاهز للاندماج التشغيلي الكامل بسبب موانع مراجعة.'
        : hasWarnings
            ? 'جاهز كتجربة تشغيل مقيدة مع تنبيهات يجب إغلاقها قبل الاعتماد النهائي.'
            : 'جاهز للاندماج التشغيلي المقيد داخل المستكشف الحالي.';

    return SmartExplorerRuntimeWiringStagePack(
      generatedAt: DateTime.now(),
      stageLabelAr: 'SMART_EXPLORER / المستكشف الذكي — Integrated Stage P — Actual Runtime Wiring + Analyzer Closure',
      scopeLabelAr: scope,
      decisionLabelAr: decision,
      summaryAr: 'مرحلة P تربط مخرجات المستكشف الذكي تشغيليًا مع baseline المستكشف الحالي عبر عقود read-only ومراجعة، وتغلق analyzer دون أي كتابة سيادية مباشرة.',
      runtimeTracks: tracks,
      analyzerClosures: analyzerClosures,
      acceptanceGates: gates,
      wiringBoundaries: const <String>[
        'لا نسخ أو تعديل lib/router.dart من baseline المستكشف الذكي.',
        'لا نسخ أو تعديل lib/features/map/** من baseline المستكشف الذكي.',
        'لا تعديل activeLayers أو zoom/bbox loaders أو search_section من هذه المرحلة.',
        'الكتابة الوحيدة المقبولة هي مسار Explorer Gap Audit المجرب عند وجود RPC/RBAC.',
        'كل مخرجات analyzer قرائن تشغيلية ولا تعتمد waqf_assets أو awqaf_system تلقائيًا.',
        'أي اعتماد نهائي يحتاج Review Board وسجل قرار ومصدر موثق.',
      ],
      cutoverSteps: const <String>[
        'طبّق baseline Stage P فوق آخر baseline فعلي للمستكشف الحالي.',
        'تحقق أن router/map/search لم تتغير من حزمة المستكشف الذكي.',
        'شغل flutter analyze محليًا.',
        'افتح /admin/smart-explorer من shell المستكشف الحالي.',
        'نفذ بحثًا واقعيًا ثم ولّد Runtime Wiring وAnalyzer Closure وCSV Runtime.',
        'اختبر إنشاء طلب تدقيق واحد فقط عند الحاجة وبعد التأكد من RPC/RBAC.',
        'وثق أي خطأ في Error Record ثم عالجه موضعيًا داخل smart_explorer فقط.',
      ],
      errorRecords: const <SmartExplorerRuntimeWiringErrorRecord>[
        SmartExplorerRuntimeWiringErrorRecord(
          code: 'SE-P-001',
          titleAr: 'استبدال غير مقصود لملفات الخريطة أو الراوتر',
          reasonAr: 'تطبيق حزمة smart_explorer كأنها baseline كامل للمستكشف الأصلي.',
          files: <String>['lib/router.dart', 'lib/features/map/**'],
          failureAr: 'تراجع سلوك navigation-only أو تعطل routes الحالية.',
          resolutionAr: 'استرجاع ملفات المستكشف الحالي وتطبيق smart_explorer فقط.',
          lastStableBaselineAr: 'Stage O / baseline المستكشف الحالي قبل Stage P',
        ),
        SmartExplorerRuntimeWiringErrorRecord(
          code: 'SE-P-002',
          titleAr: 'اعتماد analyzer دون أدلة كافية',
          reasonAr: 'تشغيل النتائج الذكية دون مصفوفة أدلة أو بطاقة جودة.',
          files: <String>['smart_explorer_repository.dart', 'admin_smart_explorer_page.dart'],
          failureAr: 'نتائج غير قابلة للدفاع أمام Review Board.',
          resolutionAr: 'توليد Evidence Matrix وQuality Scorecard قبل إغلاق analyzer.',
          lastStableBaselineAr: 'Stage O Operational User Guide Baseline',
        ),
        SmartExplorerRuntimeWiringErrorRecord(
          code: 'SE-P-003',
          titleAr: 'خلط أسماء ملفات المستكشف الذكي مع المستكشف الأصلي',
          reasonAr: 'استخدام أسماء عامة للـ baseline أو handoff.',
          files: <String>['README', 'SESSION_HANDOFF', 'BASELINE_CHANGELOG'],
          failureAr: 'ارتباك في الدمج وتطبيق ملف خاطئ.',
          resolutionAr: 'استخدام بادئة PALWAKF_SMART_EXPLORER_المستكشف_الذكي في كل المخرجات.',
          lastStableBaselineAr: 'Big Batch N Named Baseline Manifest',
        ),
      ],
      nextActions: const <String>[
        'إرسال ناتج flutter analyze إن ظهر خطأ بعد التطبيق الفعلي.',
        'اختبار سيناريو بحث واحد على الأقل وسيناريو تحليل وثيقة واحد.',
        'اعتماد التشغيل read-only أولًا ثم تفعيل طلبات التدقيق تدريجيًا.',
        'تجهيز Stage Q لربط Review Board evidence timeline إذا أثبت Stage P الاستقرار.',
      ],
    );
  }

  String buildActualRuntimeWiringStageReport({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildActualRuntimeWiringStagePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toReportText();
  }

  String buildAnalyzerClosureReport({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildActualRuntimeWiringStagePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toAnalyzerClosureText();
  }

  String buildActualRuntimeWiringCsv({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildActualRuntimeWiringStagePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toCsv();
  }


  SmartExplorerIntegratedFinalStagePack buildIntegratedFinalStageQzPack({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    final trimmedQuery = query.trim();
    final total = results.length;
    final reviewQueue = results.where((item) => item.needsReview).length;
    final criticalSignals = results
        .expand((item) => item.gapSignals)
        .where((signal) => signal.severityCode == 'critical')
        .length;
    final mapAnchored = results
        .where((item) => item.hasAnySpatialReference || item.hasGeometry || item.hasCenter || item.hasCentroid)
        .length;
    final missingGeometry = results.where((item) => !item.hasGeometry).length;
    final linkedParcels = results.where((item) => item.hasLinkedParcels || item.linkedParcelsCount > 0).length;
    final hasDocument = documentAnalysis != null;
    final hasEvidence = evidenceMatrix != null;
    final hasQuality = qualityScorecard != null;
    final hasRuntime = runtimeDiagnostics != null;
    final hasRelease = releaseReadiness != null;
    final runtimeBlocking = (runtimeDiagnostics?.blockingItems ?? 0) > 0;
    final runtimeWarnings = (runtimeDiagnostics?.warningItems ?? 0) > 0;

    SmartExplorerIntegratedStageLevel levelFor({
      required bool blocking,
      required bool warning,
    }) {
      if (blocking) return SmartExplorerIntegratedStageLevel.blocking;
      if (warning) return SmartExplorerIntegratedStageLevel.warning;
      return SmartExplorerIntegratedStageLevel.pass;
    }

    String stageStatus({required bool closed, required bool warning}) {
      if (closed && !warning) return 'مغلق تشغيليًا';
      if (closed && warning) return 'مغلق مع تنبيهات';
      return 'مفتوح للتدقيق';
    }

    final stages = <SmartExplorerIntegratedStageSegment>[
      SmartExplorerIntegratedStageSegment(
        code: 'Q',
        titleAr: 'Review Board Evidence Timeline + Runtime Acceptance Hardening',
        goalAr: 'تثبيت مسار مراجعة زمني للأدلة والقرارات قبل اعتماد أي نتيجة ذكية.',
        statusAr: stageStatus(closed: total > 0 && hasRuntime, warning: reviewQueue > 0 || criticalSignals > 0),
        isClosed: total > 0 && hasRuntime && criticalSignals == 0,
        evidenceAr: '$total نتيجة، $reviewQueue في طابور المراجعة، $criticalSignals إشارات حرجة.',
        outputs: const <String>[
          'Evidence Timeline Register',
          'Runtime Acceptance Matrix',
          'Operator Decision Log',
        ],
        acceptanceActionAr: criticalSignals > 0
            ? 'أرسل الإشارات الحرجة إلى Review Board قبل أي cutover.'
            : 'احفظ timeline ضمن سجل المرحلة وصدّر CSV عند التشغيل.',
      ),
      SmartExplorerIntegratedStageSegment(
        code: 'R',
        titleAr: 'Actual Explorer Runtime Context Binding',
        goalAr: 'ربط نتائج المستكشف الذكي بسياق المستكشف الحالي دون تعديل الخريطة أو الراوتر.',
        statusAr: stageStatus(closed: mapAnchored > 0, warning: mapAnchored < total),
        isClosed: total > 0 && mapAnchored > 0,
        evidenceAr: '$mapAnchored نتيجة لها مرجع انتقال من أصل $total، و$missingGeometry نتيجة بلا هندسة كاملة.',
        outputs: const <String>[
          'Explorer Context Adapter Contract',
          'Safe Deep Link Contract',
          'Current Target Summary',
        ],
        acceptanceActionAr: mapAnchored == 0
            ? 'اختبر على نتيجة لها مركز/هندسة أو مرجع إداري قبل القبول.'
            : 'نفذ اختبار انتقال navigation-only دون تغيير activeLayers.',
      ),
      SmartExplorerIntegratedStageSegment(
        code: 'T',
        titleAr: 'Analyzer Real Input/Output Closure',
        goalAr: 'تثبيت مدخلات ومخرجات analyzer بصيغة قابلة للتحقق ومنع النتائج الحرة غير المهيكلة.',
        statusAr: stageStatus(closed: hasDocument || hasEvidence || hasQuality, warning: !hasEvidence || !hasQuality),
        isClosed: hasEvidence && hasQuality,
        evidenceAr: 'تحليل وثيقة=${hasDocument ? 'نعم' : 'لا'}، مصفوفة أدلة=${hasEvidence ? 'نعم' : 'لا'}، بطاقة جودة=${hasQuality ? 'نعم' : 'لا'}.',
        outputs: const <String>[
          'Analyzer Input Schema',
          'Analyzer Output Schema',
          'Analyzer Validation Rules',
          'Repeated Error Registry',
        ],
        acceptanceActionAr: hasEvidence && hasQuality
            ? 'اعتمد analyzer كقرائن مراجعة فقط واحفظ سجل الأخطاء المتكرر.'
            : 'ولّد Evidence Matrix وQuality Scorecard قبل إغلاق analyzer.',
      ),
      SmartExplorerIntegratedStageSegment(
        code: 'U',
        titleAr: 'Evidence Attachments + Export Closure',
        goalAr: 'تحويل المخرجات إلى حزمة تصدير وأرشفة قابلة للتتبع.',
        statusAr: stageStatus(closed: hasEvidence || total > 0, warning: !hasEvidence),
        isClosed: total > 0 && hasEvidence,
        evidenceAr: 'مصدر الأدلة الحالي: ${hasEvidence ? 'مصفوفة أدلة مولدة' : 'نتائج تشغيل فقط'}.',
        outputs: const <String>[
          'Evidence Attachment Contract',
          'Export Manifest',
          'CSV Evidence Index',
          'Attachment Storage Policy',
        ],
        acceptanceActionAr: hasEvidence
            ? 'اربط أي مرفق لاحق بسطر timeline وقرار المشغل.'
            : 'أضف مصفوفة أدلة قبل اعتماد export كأرشيف مراجعة.',
      ),
      SmartExplorerIntegratedStageSegment(
        code: 'V',
        titleAr: 'Operational UX Hardening',
        goalAr: 'تقليل ازدحام الواجهة وتثبيت رسائل المشغل وحالات القبول.',
        statusAr: 'مغلق هيكليًا ضمن لوحة المستكشف الذكي',
        isClosed: true,
        evidenceAr: 'أزرار Q→Z مضافة كمخرجات exportText ولا تحتاج state جديد أو router.',
        outputs: const <String>[
          'Operational Action Groups',
          'Operator Warning Labels',
          'Final User Guide Addendum',
        ],
        acceptanceActionAr: 'اختبر قابلية القراءة داخل /admin/smart-explorer بعد التطبيق الفعلي.',
      ),
      SmartExplorerIntegratedStageSegment(
        code: 'W',
        titleAr: 'End-to-End UAT Pack',
        goalAr: 'تجهيز سيناريو قبول كامل من البحث حتى المراجعة والتصدير.',
        statusAr: stageStatus(closed: total > 0 && hasRuntime, warning: !hasEvidence || !hasQuality),
        isClosed: total > 0 && hasRuntime,
        evidenceAr: 'الاستعلام: ${trimmedQuery.isEmpty ? 'غير محدد' : trimmedQuery}، Runtime=${hasRuntime ? 'مولد' : 'غير مولد'}.',
        outputs: const <String>[
          'UAT Scenario Pack',
          'Operator Test Scripts',
          'Known Issues Register',
          'Rollback Notes',
        ],
        acceptanceActionAr: 'نفذ سيناريو UAT واحد على الأقل وسجل المخرجات في changelog.',
      ),
      SmartExplorerIntegratedStageSegment(
        code: 'X',
        titleAr: 'Pilot Readiness / تشغيل تجريبي',
        goalAr: 'تحديد نطاق تشغيل تجريبي محدود ومراقبة الأداء والأخطاء.',
        statusAr: stageStatus(closed: hasRuntime && total > 0 && criticalSignals == 0, warning: runtimeWarnings || reviewQueue > 0),
        isClosed: hasRuntime && total > 0 && criticalSignals == 0,
        evidenceAr: 'Runtime=${hasRuntime ? 'نعم' : 'لا'}، تنبيهات=${runtimeDiagnostics?.warningItems ?? 0}، مراجعة=$reviewQueue.',
        outputs: const <String>[
          'Pilot Scope Definition',
          'Pilot User Roles',
          'Pilot Error Record',
          'Pilot Exit Criteria',
        ],
        acceptanceActionAr: criticalSignals > 0
            ? 'لا تبدأ pilot قبل إغلاق الإشارات الحرجة.'
            : 'ابدأ pilot محدودًا بصلاحيات قراءة/مراجعة فقط.',
      ),
      SmartExplorerIntegratedStageSegment(
        code: 'Y',
        titleAr: 'Production Cutover Preparation',
        goalAr: 'تحضير الانتقال للإنتاج بشروط rollback وصلاحيات نهائية واضحة.',
        statusAr: stageStatus(closed: hasRelease && !runtimeBlocking && criticalSignals == 0, warning: !hasRelease || runtimeWarnings),
        isClosed: hasRelease && !runtimeBlocking && criticalSignals == 0,
        evidenceAr: 'Release Readiness=${hasRelease ? 'موجودة' : 'غير موجودة'}، runtime blocking=${runtimeDiagnostics?.blockingItems ?? 0}.',
        outputs: const <String>[
          'Production Cutover Checklist',
          'Rollback Plan',
          'Final RBAC Matrix Placeholder',
          'Final Runtime Contract',
        ],
        acceptanceActionAr: hasRelease
            ? 'راجع RBAC/RPC فعليًا قبل cutover الإنتاجي.'
            : 'ولّد Release Readiness قبل أي قرار إنتاج.',
      ),
      SmartExplorerIntegratedStageSegment(
        code: 'Z',
        titleAr: 'Final Stabilization + Governance Closure',
        goalAr: 'تجميع baseline النهائي والتوريث والـ changelog ودليل التشغيل.',
        statusAr: 'مغلق توثيقيًا في هذه الحزمة مع بقاء اختبار flutter analyze محليًا إلزاميًا',
        isClosed: true,
        evidenceAr: 'تم توليد تقرير Q→Z، CSV، دليل استخدام، دليل تشغيل، handoff، changelog، SHA256.',
        outputs: const <String>[
          'Final Smart Explorer Baseline',
          'Final Session Handoff',
          'Final Changelog',
          'Final Operations Manual',
        ],
        acceptanceActionAr: 'اعتمد baseline فقط بعد نجاح flutter analyze وUAT محلي.',
      ),
    ];

    final gates = <SmartExplorerIntegratedAcceptanceGate>[
      SmartExplorerIntegratedAcceptanceGate(
        titleAr: 'حماية ملفات المستكشف الأصلي',
        level: SmartExplorerIntegratedStageLevel.pass,
        isBlocking: false,
        measureAr: 'لا تعديل على router/map/search من داخل المستكشف الذكي.',
        evidenceAr: 'النطاق محصور في features/smart_explorer/docs/instructions.',
        nextActionAr: 'طبّق الحزمة فوق baseline الحالي مع منع overwrite للمستكشف الأصلي.',
      ),
      SmartExplorerIntegratedAcceptanceGate(
        titleAr: 'جاهزية بيانات التشغيل',
        level: levelFor(blocking: false, warning: total == 0),
        isBlocking: false,
        measureAr: 'عدد النتائج: $total.',
        evidenceAr: total == 0 ? 'لا توجد نتيجة بحث مثبتة لهذه اللقطة.' : 'توجد نتائج قابلة للاختبار.',
        nextActionAr: total == 0 ? 'نفذ بحثًا واقعيًا قبل UAT.' : 'اختبر أعلى نتيجة في review queue.',
      ),
      SmartExplorerIntegratedAcceptanceGate(
        titleAr: 'Review Board قبل الاعتماد',
        level: levelFor(blocking: criticalSignals > 0, warning: reviewQueue > 0),
        isBlocking: criticalSignals > 0,
        measureAr: '$criticalSignals إشارة حرجة، $reviewQueue نتيجة تحتاج مراجعة.',
        evidenceAr: 'لا اعتماد تلقائي لنتائج ذكية أو analyzer.',
        nextActionAr: criticalSignals > 0
            ? 'أغلق الإشارات الحرجة عبر Review Board.'
            : 'سجل قرار المشغل لكل نتيجة تحتاج مراجعة.',
      ),
      SmartExplorerIntegratedAcceptanceGate(
        titleAr: 'إغلاق analyzer والأدلة',
        level: levelFor(blocking: false, warning: !hasEvidence || !hasQuality),
        isBlocking: false,
        measureAr: 'Evidence=${hasEvidence ? 'نعم' : 'لا'}، Quality=${hasQuality ? 'نعم' : 'لا'}.',
        evidenceAr: 'المحلل لا يكتب في waqf_assets ولا awqaf_system.',
        nextActionAr: hasEvidence && hasQuality
            ? 'احفظ schema والـ validation ضمن دليل التشغيل.'
            : 'ولّد الأدلة والجودة قبل Pilot واسع.',
      ),
      SmartExplorerIntegratedAcceptanceGate(
        titleAr: 'ربط السياق المكاني',
        level: levelFor(blocking: false, warning: mapAnchored == 0 || linkedParcels == 0),
        isBlocking: false,
        measureAr: '$mapAnchored مرجع انتقال، $linkedParcels ربط قطع.',
        evidenceAr: 'كل الانتقالات navigation-only دون تغيير activeLayers.',
        nextActionAr: mapAnchored == 0
            ? 'اختبر نتيجة ذات مرجع مكاني قبل اعتماد R.'
            : 'وثق نتيجة الانتقال في UAT.',
      ),
      SmartExplorerIntegratedAcceptanceGate(
        titleAr: 'جاهزية الإنتاج',
        level: levelFor(blocking: runtimeBlocking || criticalSignals > 0, warning: !hasRelease || runtimeWarnings),
        isBlocking: runtimeBlocking || criticalSignals > 0,
        measureAr: 'Runtime blocking=${runtimeDiagnostics?.blockingItems ?? 0}، Release=${hasRelease ? 'نعم' : 'لا'}.',
        evidenceAr: 'Stage Y لا يعني cutover إنتاجي دون RBAC/RPC فعليين.',
        nextActionAr: runtimeBlocking
            ? 'أغلق موانع runtime قبل الإنتاج.'
            : 'نفذ UAT وPilot قبل أي cutover.',
      ),
    ];

    final hasBlocking = gates.any((gate) => gate.isBlocking);
    final hasWarnings = gates.any((gate) => gate.level == SmartExplorerIntegratedStageLevel.warning);
    final decision = hasBlocking
        ? 'غير جاهز للإنتاج أو pilot الواسع؛ الحزمة صالحة كتجميع تطويري وتحتاج إغلاق موانع.'
        : hasWarnings
            ? 'جاهز كمرحلة اندماج تشغيلية وتجربة محدودة مع تنبيهات قبول يجب إغلاقها.'
            : 'جاهز كحزمة اندماج تشغيلية كاملة تمهيدًا لـ UAT/Pilot مقيد.';

    return SmartExplorerIntegratedFinalStagePack(
      generatedAt: DateTime.now(),
      stageLabelAr: 'SMART_EXPLORER / المستكشف الذكي — Integrated Final Stage Q→Z — Operational Merger Baseline',
      scopeLabelAr: 'تنفيذ المراحل Q وR وT وU وV وW وX وY وZ دفعة واحدة داخل المستكشف الذكي فقط.',
      decisionLabelAr: decision,
      summaryAr: 'هذه الحزمة تغلق المسار التشغيلي للمستكشف الذكي من Timeline الأدلة حتى دليل التشغيل النهائي، مع منع أي تعديل مباشر على الخريطة أو الراوتر أو مصادر البيانات السيادية.',
      stageSegments: stages,
      acceptanceGates: gates,
      artifacts: const <SmartExplorerIntegratedArtifact>[
        SmartExplorerIntegratedArtifact(
          nameAr: 'Review Board Evidence Timeline',
          typeAr: 'سجل مراجعة',
          ownerAr: 'مشغل المستكشف / Review Board',
          statusAr: 'مولد ضمن تقرير Q→Z',
          acceptanceAr: 'يُقبل بعد اختبار نتيجة واحدة على الأقل.',
        ),
        SmartExplorerIntegratedArtifact(
          nameAr: 'Analyzer I/O Validation Contract',
          typeAr: 'عقد تحقق',
          ownerAr: 'فريق المستكشف الذكي',
          statusAr: 'مقيد بالمراجعة ولا يكتب سياديًا',
          acceptanceAr: 'يُقبل بعد وجود Evidence Matrix وQuality Scorecard.',
        ),
        SmartExplorerIntegratedArtifact(
          nameAr: 'Evidence Attachment + Export Manifest',
          typeAr: 'تصدير وأرشفة',
          ownerAr: 'المشغل التشغيلي',
          statusAr: 'جاهز كعقد تشغيل',
          acceptanceAr: 'يُقبل بعد ربط كل مرفق بسطر timeline.',
        ),
        SmartExplorerIntegratedArtifact(
          nameAr: 'UAT / Pilot / Cutover Pack',
          typeAr: 'قبول وتشغيل',
          ownerAr: 'فريق المنصة',
          statusAr: 'جاهز للتطبيق المحلي',
          acceptanceAr: 'لا يعتمد إنتاجيًا دون flutter analyze وUAT وRBAC/RPC.',
        ),
      ],
      runtimeRules: const <String>[
        'المستكشف الذكي لا يستبدل lib/router.dart.',
        'المستكشف الذكي لا يستبدل lib/features/map/**.',
        'اختيارات الخريطة تبقى navigation-only ولا تعدل activeLayers.',
        'نتائج analyzer قرائن مراجعة وليست مصدر حقيقة سيادي.',
        'waqf_assets هو مركز الربط التشغيلي عند الانتقال لربط سيادي فعلي.',
        'awqaf_system يبقى Master Data، وmustakshif للتحليل والمراجعة.',
        'public مخصص للـ views/RPC wrappers فقط عند الحاجة.',
        'أي كتابة تشغيلية تمر عبر مسار Review Board/Gap Audit المصرح فقط.',
      ],
      cutoverRunbook: const <String>[
        'احفظ baseline الحالي للمستكشف الأصلي قبل تطبيق حزمة المستكشف الذكي.',
        'طبّق ملفات features/smart_explorer والوثائق فقط.',
        'امنع overwrite لأي ملف map أو router أو search من المستكشف الأصلي.',
        'شغل flutter analyze محليًا وسجل النتائج في Error Record إن وجدت.',
        'افتح /admin/smart-explorer وشغّل بحثًا واقعيًا.',
        'ولّد Runtime Wiring ثم Integrated Q→Z ثم CSV Q→Z.',
        'نفذ UAT واحدًا على نتيجة لها سياق مكاني وتحتاج مراجعة.',
        'لا تنتقل إلى Pilot إلا بعد إغلاق الموانع الحرجة.',
        'لا تنتقل إلى Production Cutover إلا بعد RBAC/RPC فعليين وRollback Plan.',
      ],
      errorRecords: const <SmartExplorerIntegratedErrorRecord>[
        SmartExplorerIntegratedErrorRecord(
          code: 'SE-QZ-001',
          titleAr: 'اعتماد إنتاجي قبل UAT/Pilot',
          reasonAr: 'اعتبار تقرير Q→Z مساويًا للتشغيل الإنتاجي النهائي.',
          files: <String>['/admin/smart-explorer', 'docs/smart_explorer/**'],
          failureAr: 'نتائج غير مجربة أو غير قابلة للدفاع عند مراجعة الأدلة.',
          resolutionAr: 'تنفيذ UAT ثم Pilot محدود قبل Production Cutover.',
          lastStableBaselineAr: 'Stage P Runtime Wiring Analyzer Closure Baseline',
        ),
        SmartExplorerIntegratedErrorRecord(
          code: 'SE-QZ-002',
          titleAr: 'خلط Timeline الأدلة مع مصدر الحقيقة',
          reasonAr: 'اعتبار evidence timeline بديلًا عن awqaf_system أو waqf_assets.',
          files: <String>['smart_explorer_integrated_final_stage_pack.dart'],
          failureAr: 'اعتماد بيانات تحليلية كمصدر سيادي.',
          resolutionAr: 'إبقاء timeline كمسار مراجعة وتحويل الاعتماد النهائي لمصدر سيادي.',
          lastStableBaselineAr: 'Stage P Runtime Wiring Analyzer Closure Baseline',
        ),
        SmartExplorerIntegratedErrorRecord(
          code: 'SE-QZ-003',
          titleAr: 'تغيير سلوك الخريطة أثناء الدمج',
          reasonAr: 'نسخ ملفات خريطة أو بحث من حزمة المستكشف الذكي فوق baseline المستكشف الأصلي.',
          files: <String>['lib/router.dart', 'lib/features/map/**'],
          failureAr: 'كسر navigation-only أو zoom/bbox layer behavior.',
          resolutionAr: 'استرجاع ملفات المستكشف الأصلي وتطبيق ملفات smart_explorer فقط.',
          lastStableBaselineAr: 'Current Explorer Baseline قبل تطبيق Q→Z',
        ),
      ],
      finalNextActions: const <String>[
        'تشغيل flutter analyze محليًا بعد تطبيق baseline.',
        'تنفيذ UAT كامل وتوثيق النتيجة داخل Error Record / Changelog.',
        'تثبيت RBAC/RPC الفعلي قبل أي قطع إنتاجي.',
        'تجميع أي أخطاء متكررة في سجل واحد وتحديث دليل الاستخدام.',
        'اعتماد ZIP الحالي كحزمة المستكشف الذكي النهائية لهذه المرحلة فقط.',
      ],
    );
  }

  String buildIntegratedFinalStageQzReport({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildIntegratedFinalStageQzPack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toReportText();
  }

  String buildIntegratedFinalStageQzCsv({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildIntegratedFinalStageQzPack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toCsv();
  }

  String buildIntegratedFinalUserGuideQzText({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildIntegratedFinalStageQzPack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toUserGuideText();
  }

  String buildIntegratedFinalOperationsManualQzText({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildIntegratedFinalStageQzPack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toOperationsManualText();
  }


  SmartExplorerPostQzOperationalClosurePack buildPostQzOperationalClosurePack({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    final total = results.length;
    final reviewQueue = results.where((item) => item.needsReview).length;
    final criticalSignals = results
        .expand((item) => item.gapSignals)
        .where((signal) => signal.severityCode == 'critical')
        .length;
    final mapAnchored = results
        .where((item) => item.hasAnySpatialReference || item.hasGeometry || item.hasCenter || item.hasCentroid)
        .length;
    final hasEvidence = evidenceMatrix != null;
    final hasQuality = qualityScorecard != null;
    final hasRuntime = runtimeDiagnostics != null;
    final hasRelease = releaseReadiness != null;
    final hasDocument = documentAnalysis != null;
    final runtimeBlocking = (runtimeDiagnostics?.blockingItems ?? 0) > 0;
    final runtimeWarnings = (runtimeDiagnostics?.warningItems ?? 0) > 0;
    final hasOperationalInput = total > 0 || hasDocument || hasEvidence || hasQuality || hasRuntime || hasRelease;

    SmartExplorerPostQzGateLevel levelFor({
      required bool blocking,
      required bool warning,
    }) {
      if (blocking) return SmartExplorerPostQzGateLevel.blocking;
      if (warning) return SmartExplorerPostQzGateLevel.warning;
      return SmartExplorerPostQzGateLevel.pass;
    }

    final closureGates = <SmartExplorerPostQzClosureGate>[
      SmartExplorerPostQzClosureGate(
        titleAr: 'اكتمال حزمة المستكشف الذكي داخليًا',
        level: SmartExplorerPostQzGateLevel.pass,
        isBlocking: false,
        measureAr: 'Stage O/P/Q→Z وPost-QZ Closure متاحة كأزرار وتقارير داخل smart_explorer.',
        evidenceAr: 'النطاق محصور في lib/features/smart_explorer والوثائق والتعليمات.',
        nextActionAr: 'طبّق الحزمة فوق baseline المستكشف الأصلي واختبر الصفحة.',
      ),
      SmartExplorerPostQzClosureGate(
        titleAr: 'مدخلات تشغيل واقعية',
        level: levelFor(blocking: false, warning: !hasOperationalInput),
        isBlocking: false,
        measureAr: 'وجود نتائج بحث أو تحليل وثيقة أو مصفوفة أدلة أو تشخيص runtime.',
        evidenceAr: 'نتائج=$total، وثيقة=${hasDocument ? 'نعم' : 'لا'}، أدلة=${hasEvidence ? 'نعم' : 'لا'}، جودة=${hasQuality ? 'نعم' : 'لا'}، Runtime=${hasRuntime ? 'نعم' : 'لا'}.',
        nextActionAr: hasOperationalInput
            ? 'نفذ UAT على نفس المدخلات وسجل exportText/CSV.'
            : 'شغّل سيناريو بحث أو عينة وثيقة قبل قرار pilot.',
      ),
      SmartExplorerPostQzClosureGate(
        titleAr: 'سلامة سياق الخريطة',
        level: levelFor(blocking: false, warning: total > 0 && mapAnchored == 0),
        isBlocking: false,
        measureAr: 'وجود نتائج لها مرجع مكاني دون تعديل activeLayers أو صناديق البحث.',
        evidenceAr: '$mapAnchored نتيجة قابلة للربط المكاني من أصل $total.',
        nextActionAr: mapAnchored > 0
            ? 'اختبر deep link/انتقال navigation-only من المستكشف الأصلي.'
            : 'استخدم نتيجة لها centroid/geometry أو مرجع إداري في UAT.',
      ),
      SmartExplorerPostQzClosureGate(
        titleAr: 'إغلاق Review Board قبل الاعتماد',
        level: levelFor(blocking: criticalSignals > 0, warning: reviewQueue > 0),
        isBlocking: criticalSignals > 0,
        measureAr: 'كل إشارة حرجة أو نتيجة تحتاج مراجعة يجب أن تدخل Review Board أو Error Record.',
        evidenceAr: 'طابور مراجعة=$reviewQueue، إشارات حرجة=$criticalSignals.',
        nextActionAr: criticalSignals > 0
            ? 'لا تعتمد pilot/cutover قبل إنشاء طلبات تدقيق للإشارات الحرجة.'
            : 'صدّر CSV المراجعة واحفظ قرار المشغل.',
      ),
      SmartExplorerPostQzClosureGate(
        titleAr: 'إغلاق analyzer والنتائج غير المهيكلة',
        level: levelFor(blocking: false, warning: !hasEvidence || !hasQuality),
        isBlocking: false,
        measureAr: 'وجود Evidence Matrix وQuality Scorecard أو بديل مراجعة موثق.',
        evidenceAr: 'أدلة=${hasEvidence ? 'نعم' : 'لا'}، جودة=${hasQuality ? 'نعم' : 'لا'}.',
        nextActionAr: hasEvidence && hasQuality
            ? 'اعتمد analyzer كمساعد مراجعة فقط وليس مصدر حقيقة.'
            : 'ولّد Evidence Matrix وQuality Scorecard قبل pilot الواسع.',
      ),
      SmartExplorerPostQzClosureGate(
        titleAr: 'جاهزية runtime/release',
        level: levelFor(blocking: runtimeBlocking, warning: !hasRuntime || !hasRelease || runtimeWarnings),
        isBlocking: runtimeBlocking,
        measureAr: 'لا توجد بنود runtime مانعة، وRelease Readiness موجودة عند قرار cutover.',
        evidenceAr: 'Runtime=${hasRuntime ? 'نعم' : 'لا'}، Release=${hasRelease ? 'نعم' : 'لا'}، موانع=${runtimeDiagnostics?.blockingItems ?? 0}، تنبيهات=${runtimeDiagnostics?.warningItems ?? 0}.',
        nextActionAr: runtimeBlocking
            ? 'أغلق موانع runtime قبل أي اعتماد.'
            : 'نفذ flutter analyze وUAT بعد الدمج في المستكشف الأصلي.',
      ),
      SmartExplorerPostQzClosureGate(
        titleAr: 'إلزام اختبار المستكشف الأصلي',
        level: SmartExplorerPostQzGateLevel.warning,
        isBlocking: false,
        measureAr: 'الاختبار النهائي يجب أن يتم داخل baseline المستكشف الأصلي لأنه يملك router/map/RBAC.',
        evidenceAr: 'المستكشف الذكي لا يستبدل router أو map ولا يستطيع تأكيد analyzer محلي خارج مشروع المستكشف الأصلي.',
        nextActionAr: 'على المستكشف الأصلي تشغيل flutter analyze وفتح /admin/smart-explorer وإرفاق النتائج.',
      ),
    ];

    final hasBlockingGate = closureGates.any((gate) => gate.isBlocking);
    final decision = hasBlockingGate
        ? 'إغلاق داخلي مكتمل، لكن الاعتماد التشغيلي موقوف حتى إغلاق الموانع.'
        : 'إغلاق داخلي مكتمل وجاهز للتطبيق والاختبار داخل المستكشف الأصلي.';

    return SmartExplorerPostQzOperationalClosurePack(
      generatedAt: DateTime.now(),
      stageLabelAr: 'SMART_EXPLORER / المستكشف الذكي — Post-QZ Operational Closure + Integration Instructions',
      decisionLabelAr: decision,
      acceptanceDecisionAr: hasBlockingGate
          ? 'لا يتم pilot/cutover قبل إغلاق Review Board أو موانع runtime.'
          : 'لا توجد أعمال تطوير تأسيسية متبقية داخل المستكشف الذكي؛ المتبقي اختبار قبول داخل المستكشف الأصلي.',
      summaryAr: 'هذه الحزمة تغلق الأعمال المتبقية بعد Q→Z وتحوّلها إلى تعليمات دمج واختبار وتشغيل للمستكشف الأصلي دون تعديل الخريطة أو الراوتر.',
      integrationRules: const <String>[
        'المستكشف الذكي يقرأ السياق ويولد تقارير ومراجعات ولا يملك الخريطة أو الراوتر.',
        'لا تستبدل lib/router.dart من هذه الحزمة.',
        'لا تستبدل lib/features/map/** من هذه الحزمة.',
        'لا تعدل activeLayers من المستكشف الذكي.',
        'صناديق البحث تبقى navigation-only: zoom/focus/fitBounds/moveCamera فقط.',
        'أي كتابة مستقبلية تمر عبر Review/RPC wrappers وليس الجداول السيادية مباشرة.',
        'awqaf_system هو Master Data، وmustakshif للتحليل والمراجعة، وpublic للـ wrappers فقط.',
      ],
      closureGates: closureGates,
      testScenarios: <SmartExplorerPostQzTestScenario>[
        SmartExplorerPostQzTestScenario(
          code: 'UAT-01',
          titleAr: 'فتح صفحة المستكشف الذكي بعد الدمج',
          goalAr: 'التأكد أن /admin/smart-explorer تعمل داخل shell الحالي.',
          steps: const <String>[
            'شغّل flutter analyze.',
            'افتح التطبيق على Chrome.',
            'انتقل إلى /admin/smart-explorer.',
            'تأكد من ظهور أزرار Q→Z وPost-QZ Closure.',
          ],
          acceptanceAr: 'لا crash، لا route error، ولا RBAC blocking غير مقصود.',
        ),
        SmartExplorerPostQzTestScenario(
          code: 'UAT-02',
          titleAr: 'تشغيل تقرير الإغلاق النهائي',
          goalAr: 'التأكد أن التقرير يظهر في exportText ويمكن نسخه/تصديره.',
          steps: const <String>[
            'نفذ بحثًا واقعيًا أو اترك الصفحة بلا نتائج لاختبار الحالة الفارغة.',
            'اضغط Post-QZ Closure.',
            'اضغط CSV Post-QZ.',
            'انسخ التقرير واحفظه في سجل UAT.',
          ],
          acceptanceAr: 'التقرير والـ CSV يظهران دون overflow حرج أو أخطاء console.',
        ),
        SmartExplorerPostQzTestScenario(
          code: 'UAT-03',
          titleAr: 'سلامة الخريطة والبحث',
          goalAr: 'التأكد أن المستكشف الذكي لم يغير activeLayers أو behavior الخاص بالخريطة.',
          steps: const <String>[
            'افتح صفحة الخريطة قبل وبعد تشغيل المستكشف الذكي.',
            'اختبر صناديق البحث.',
            'تأكد أنها تنفذ zoom/focus فقط.',
            'قارن activeLayers قبل وبعد الاختبار.',
          ],
          acceptanceAr: 'لا تغيير طبقات من المستكشف الذكي، ولا إعادة تفعيل/تعطيل طبقات بواسطة البحث.',
        ),
        SmartExplorerPostQzTestScenario(
          code: 'UAT-04',
          titleAr: 'Review/Evidence/Export Closure',
          goalAr: 'اختبار مخرجات المراجعة والأدلة والتصدير دون كتابة سيادية مباشرة.',
          steps: const <String>[
            'ولّد Evidence Matrix إن كانت المدخلات متاحة.',
            'ولّد Q→Z ثم Post-QZ Closure.',
            'راجع بوابات Review Board.',
            'صدّر CSV واحفظه مع ملف الاختبار.',
          ],
          acceptanceAr: 'أي نتيجة تحتاج مراجعة تظهر كقرار/تنبيه ولا تعتمد تلقائيًا.',
        ),
      ],
      explorerInstructions: const <String>[
        'انسخ ملفات lib/features/smart_explorer/** من هذه الحزمة فوق نسخة المستكشف الأصلي الحالية بعد أخذ نسخة احتياطية.',
        'انسخ docs/smart_explorer/** وinstructions/** ووثائق handoff/changelog إلى مجلدات المشروع المناسبة.',
        'لا تنسخ أي router أو map من حزم المستكشف الذكي حتى لو وُجدت تاريخيًا في حزم قديمة.',
        'شغّل flutter analyze واحفظ الناتج في flutter_analyze_after_post_qz_closure.txt.',
        'افتح /admin/smart-explorer واختبر أزرار Q→Z وPost-QZ Closure وCSV Post-QZ وتعليمات الدمج.',
        'اختبر الخريطة بعد التشغيل وتأكد أن navigation-only وactiveLayers لم تتغير.',
        'وثق أي خطأ في Error Record يشمل السبب، الملفات، ما فشل، الحل، وآخر baseline مستقر.',
        'إذا نجح الاختبار، اعتبر هذه الحزمة نقطة baseline نهائية للمستكشف الذكي داخل المستكشف الأصلي.',
      ],
      errorRecords: const <SmartExplorerPostQzErrorRecord>[
        SmartExplorerPostQzErrorRecord(
          code: 'POST-QZ-ER-001',
          titleAr: 'استبدال ملفات الخريطة أو الراوتر بالخطأ',
          reasonAr: 'تطبيق حزمة المستكشف الذكي كـ full project overwrite بدل smart_explorer-only overlay.',
          files: <String>['lib/router.dart', 'lib/features/map/**'],
          failureAr: 'تعطل routes أو تغير سلوك navigation-only أو activeLayers.',
          resolutionAr: 'استرجع ملفات المستكشف الأصلي ثم أعد تطبيق lib/features/smart_explorer فقط.',
          lastStableBaselineAr: 'Current Explorer Baseline قبل تطبيق المستكشف الذكي',
        ),
        SmartExplorerPostQzErrorRecord(
          code: 'POST-QZ-ER-002',
          titleAr: 'اعتماد analyzer كمصدر حقيقة',
          reasonAr: 'اعتبار تقرير المستكشف الذكي نتيجة نهائية بدل قرينة مراجعة.',
          files: <String>['lib/features/smart_explorer/**', 'review/evidence flows'],
          failureAr: 'قبول نتائج غير مهيكلة أو غير مراجعة.',
          resolutionAr: 'اجعل كل نتيجة حرجة تمر عبر Review Board/Evidence Timeline.',
          lastStableBaselineAr: 'Q→Z Operational Merger Baseline',
        ),
        SmartExplorerPostQzErrorRecord(
          code: 'POST-QZ-ER-003',
          titleAr: 'اختبار غير موثق بعد الدمج',
          reasonAr: 'تشغيل الصفحة دون حفظ flutter analyze وUAT logs.',
          files: <String>['docs/smart_explorer/**', 'instructions/**'],
          failureAr: 'صعوبة توريث الحالة أو معرفة آخر baseline مستقر.',
          resolutionAr: 'احفظ analyze/UAT/error screenshots وأضفها إلى changelog.',
          lastStableBaselineAr: 'Post-QZ Operational Closure Baseline',
        ),
      ],
      finalArtifacts: const <SmartExplorerPostQzArtifact>[
        SmartExplorerPostQzArtifact(
          nameAr: 'Post-QZ Operational Closure Report',
          ownerAr: 'المستكشف الذكي',
          statusAr: 'جاهز',
          pathHintAr: 'زر Post-QZ Closure داخل /admin/smart-explorer',
          acceptanceAr: 'يُقبل بعد ظهوره في exportText دون crash.',
        ),
        SmartExplorerPostQzArtifact(
          nameAr: 'Post-QZ CSV',
          ownerAr: 'المستكشف الذكي',
          statusAr: 'جاهز',
          pathHintAr: 'زر CSV Post-QZ',
          acceptanceAr: 'يُحفظ مع سجل UAT.',
        ),
        SmartExplorerPostQzArtifact(
          nameAr: 'تعليمات دمج المستكشف الأصلي',
          ownerAr: 'المستكشف الذكي/المستكشف الأصلي',
          statusAr: 'جاهزة للتطبيق',
          pathHintAr: 'docs/smart_explorer وREADME داخل baseline',
          acceptanceAr: 'يتبعها المستكشف الأصلي عند الدمج والاختبار.',
        ),
        SmartExplorerPostQzArtifact(
          nameAr: 'ملحق دليل الاستخدام النهائي',
          ownerAr: 'المستكشف الذكي',
          statusAr: 'جاهز',
          pathHintAr: 'docs/smart_explorer',
          acceptanceAr: 'يضاف إلى دليل المستخدم التشغيلي.',
        ),
      ],
    );
  }

  String buildPostQzOperationalClosureReport({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildPostQzOperationalClosurePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toReportText();
  }

  String buildPostQzOperationalClosureCsv({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildPostQzOperationalClosurePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toCsv();
  }

  String buildPostQzExplorerIntegrationInstructionsText({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildPostQzOperationalClosurePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toExplorerIntegrationInstructionsText();
  }

  String buildPostQzFinalUserGuideAddendumText({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildPostQzOperationalClosurePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toFinalUserGuideAddendumText();
  }


  SmartExplorerAiDocumentIntelligenceStagePack buildAiDocumentIntelligenceStagePack({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    final hasDocumentText = documentAnalysis != null &&
        documentAnalysis.normalizedText.trim().isNotEmpty;
    final hasEvidence = evidenceMatrix != null &&
        evidenceMatrix.links.isNotEmpty;
    final hasResults = results.isNotEmpty;
    final readinessWarnings = <String>[
      if (!hasDocumentText) 'لا توجد وثيقة محللة بعد؛ OCR/LLM سيبقى عقدًا تشغيليًا حتى إدخال وثائق فعلية.',
      if (!hasEvidence) 'لا توجد مصفوفة أدلة فعلية بعد؛ RAG يحتاج citations ومصادر مراجعة.',
      if (!hasResults) 'لا توجد نتائج بحث حالية؛ الربط مع waqf_asset_id سيبقى اختياريًا.',
      if (runtimeDiagnostics == null) 'يفضل تشغيل تشخيص التشغيل قبل AI-OCR-LLM.',
    ];
    final readinessLabel = readinessWarnings.isEmpty
        ? 'جاهز للتطبيق التجريبي المقيد بعد مراجعة SQL/RBAC/RLS'
        : 'جاهز كعقد تنفيذي مع فجوات تشغيلية: ${readinessWarnings.length}';

    return SmartExplorerAiDocumentIntelligenceStagePack(
      generatedAt: DateTime.now(),
      stageLabelAr: 'SMART_EXPLORER / المستكشف الذكي — AI-OCR-LLM-RAG Review Board Stage AI-1→AI-6',
      queryAr: query,
      readinessLabelAr: readinessLabel,
      stages: const <SmartExplorerAiStageItem>[
        SmartExplorerAiStageItem(
          code: 'AI-1',
          titleAr: 'OCR Intake Foundation',
          statusAr: 'منفذ كعقد ونموذج تشغيل، ويتطلب محرك OCR فعلي عند الدمج',
          descriptionAr: 'تأسيس استقبال الوثائق وربطها بسياق المستكشف دون اعتبار النص الناتج حقيقة سيادية.',
          outputsAr: <String>[
            'document_intake داخل mustakshif',
            'ocr_jobs كطابور تشغيل',
            'ربط اختياري مع waqf_asset_id وسياق الخريطة',
            'حفظ حالة الوثيقة من draft إلى review أو approved',
          ],
          blockersAr: <String>[
            'عدم وجود ملف/وثيقة فعلية',
            'غياب سياسة التخزين',
            'غياب RBAC لإنشاء OCR jobs',
          ],
        ),
        SmartExplorerAiStageItem(
          code: 'AI-2',
          titleAr: 'OCR Review Workflow',
          statusAr: 'منفذ كمسار مراجعة ونموذج جداول',
          descriptionAr: 'مراجعة النص الخام والمصحح قبل إرساله لأي تحليل لغوي أو RAG.',
          outputsAr: <String>[
            'ocr_results للنص الخام والثقة والجودة',
            'ocr_review_events لقبول/تصحيح/رفض النص',
            'منع استخدام raw OCR مباشرة في الأدلة',
          ],
          blockersAr: <String>[
            'نسبة ثقة منخفضة دون مراجعة بشرية',
            'وثيقة تالفة أو خط يد غير مقروء',
            'غياب reviewer_note عند الرفض أو التصحيح',
          ],
        ),
        SmartExplorerAiStageItem(
          code: 'AI-3',
          titleAr: 'LLM Structured Analysis',
          statusAr: 'منفذ كعقد تحليل مهيكل، وليس LLM حر',
          descriptionAr: 'تحليل النص المراجع لاستخراج كيانات وتواريخ ومواقع ومخاطر، مع نتيجة JSON قابلة للتدقيق.',
          outputsAr: <String>[
            'llm_analysis_jobs',
            'llm_analysis_results',
            'extracted_entities / temporal_clues / spatial_clues',
            'requires_review=true كافتراضي',
          ],
          blockersAr: <String>[
            'لا تحليل LLM على OCR غير مراجع',
            'لا قبول لنتيجة بلا confidence_score',
            'لا قبول لنتيجة بلا risk_flags عند وجود تعارض',
          ],
        ),
        SmartExplorerAiStageItem(
          code: 'AI-4',
          titleAr: 'RAG Knowledge Layer',
          statusAr: 'منفذ كعقد citations ومصفوفة مصادر',
          descriptionAr: 'إجبار كل نتيجة LLM على مصدر أو excerpt أو مرجع داخلي قابل للمراجعة.',
          outputsAr: <String>[
            'rag_citations',
            'citation_type',
            'source_schema/source_table/source_id',
            'excerpt وconfidence_score',
          ],
          blockersAr: <String>[
            'نتيجة بلا citation',
            'مصدر غير موثوق أو غير قابل للتتبع',
            'استخدام ذاكرة LLM كدليل مستقل',
          ],
        ),
        SmartExplorerAiStageItem(
          code: 'AI-5',
          titleAr: 'Evidence Timeline Integration',
          statusAr: 'منفذ كمرشح أدلة قابل للمراجعة',
          descriptionAr: 'تحويل نتائج OCR/LLM/RAG إلى evidence candidates لا إلى تحديث سيادي.',
          outputsAr: <String>[
            'evidence_candidates',
            'candidate_status=review كافتراضي',
            'proposed_action_ar بدلاً من تحديث مباشر',
            'ربط قابل للمراجعة مع waqf_asset_id',
          ],
          blockersAr: <String>[
            'أي محاولة تحديث core/waqf/awqaf_system مباشرة',
            'غياب review decision',
            'عدم وضوح proposed_action_ar',
          ],
        ),
        SmartExplorerAiStageItem(
          code: 'AI-6',
          titleAr: 'AI Audit + Safety',
          statusAr: 'منفذ كعقد audit logs وError Records',
          descriptionAr: 'تسجيل أثر الذكاء الصناعي ومخاطره ومدخلاته ومخرجاته دون كشف أسرار أو إدخال نتائج غير مراجعة.',
          outputsAr: <String>[
            'ai_audit_logs',
            'risk_level',
            'input_digest/output_digest',
            'audit_payload',
          ],
          blockersAr: <String>[
            'تشغيل AI بلا audit log',
            'نتيجة عالية المخاطر بلا Review Board',
            'تخزين prompt/output حساس دون سياسة خصوصية',
          ],
        ),
      ],
      serviceBoundaries: const <SmartExplorerAiBoundaryItem>[
        SmartExplorerAiBoundaryItem(scopeAr: 'public', ruleAr: 'RPC wrappers فقط؛ لا جداول تشغيلية ولا منطق سيادي مباشر.'),
        SmartExplorerAiBoundaryItem(scopeAr: 'mustakshif', ruleAr: 'التحليل، المراجعة، OCR/LLM/RAG، candidate evidence، audit logs.'),
        SmartExplorerAiBoundaryItem(scopeAr: 'awqaf_system', ruleAr: 'Master Data فقط؛ لا يكتب AI فيه مباشرة.'),
        SmartExplorerAiBoundaryItem(scopeAr: 'core/waqf', ruleAr: 'مصادر سيادية؛ أي تعديل يمر عبر مسار رسمي منفصل وليس AI.'),
        SmartExplorerAiBoundaryItem(scopeAr: 'map/search/router', ruleAr: 'قراءة سياق فقط؛ لا activeLayers ولا تغيير navigation-only.'),
      ],
      requiredTables: const <SmartExplorerAiSchemaItem>[
        SmartExplorerAiSchemaItem(name: 'mustakshif.document_intake', purposeAr: 'استقبال الوثائق وربطها بسياق المستكشف', writePolicyAr: 'كتابة مراجعة عبر public wrapper فقط'),
        SmartExplorerAiSchemaItem(name: 'mustakshif.ocr_jobs', purposeAr: 'طابور تشغيل OCR', writePolicyAr: 'إنشاء job عبر wrapper وصلاحية AI/OCR'),
        SmartExplorerAiSchemaItem(name: 'mustakshif.ocr_results', purposeAr: 'حفظ النص الخام/المطبع ودرجة الثقة', writePolicyAr: 'كتابة من خدمة OCR أو RPC محمي'),
        SmartExplorerAiSchemaItem(name: 'mustakshif.ocr_review_events', purposeAr: 'مراجعة واعتماد/تصحيح/رفض OCR', writePolicyAr: 'كتابة reviewer فقط'),
        SmartExplorerAiSchemaItem(name: 'mustakshif.llm_analysis_jobs', purposeAr: 'طابور LLM المهيكل', writePolicyAr: 'لا ينشأ إلا على OCR مراجع أو مصدر موثق'),
        SmartExplorerAiSchemaItem(name: 'mustakshif.llm_analysis_results', purposeAr: 'نتائج تحليل LLM المهيكلة', writePolicyAr: 'كتابة خدمة محمية، requires_review=true'),
        SmartExplorerAiSchemaItem(name: 'mustakshif.rag_citations', purposeAr: 'مصادر RAG والاقتباسات', writePolicyAr: 'لا نتيجة بلا citation'),
        SmartExplorerAiSchemaItem(name: 'mustakshif.evidence_candidates', purposeAr: 'أدلة مقترحة للمراجعة', writePolicyAr: 'candidate_status=review كافتراضي'),
        SmartExplorerAiSchemaItem(name: 'mustakshif.ai_audit_logs', purposeAr: 'تدقيق AI والمدخلات/المخرجات', writePolicyAr: 'تسجيل إلزامي لكل job/نتيجة'),
      ],
      requiredRpcWrappers: const <SmartExplorerAiSchemaItem>[
        SmartExplorerAiSchemaItem(name: 'public.rpc_smart_explorer_create_document_intake_v1', purposeAr: 'إنشاء وثيقة مراجعة', writePolicyAr: 'wrapper فقط'),
        SmartExplorerAiSchemaItem(name: 'public.rpc_smart_explorer_create_ocr_job_v1', purposeAr: 'إنشاء OCR job', writePolicyAr: 'wrapper فقط'),
        SmartExplorerAiSchemaItem(name: 'public.rpc_smart_explorer_submit_ocr_review_v1', purposeAr: 'اعتماد/تصحيح OCR', writePolicyAr: 'wrapper فقط'),
        SmartExplorerAiSchemaItem(name: 'public.rpc_smart_explorer_create_llm_analysis_job_v1', purposeAr: 'إنشاء تحليل LLM مهيكل', writePolicyAr: 'wrapper فقط'),
        SmartExplorerAiSchemaItem(name: 'public.rpc_smart_explorer_submit_evidence_candidate_v1', purposeAr: 'اقتراح دليل Review Board', writePolicyAr: 'wrapper فقط'),
        SmartExplorerAiSchemaItem(name: 'public.rpc_smart_explorer_review_ai_evidence_candidate_v1', purposeAr: 'قبول/رفض الدليل المقترح', writePolicyAr: 'wrapper فقط'),
      ],
      reviewGates: const <SmartExplorerAiGateItem>[
        SmartExplorerAiGateItem(code: 'G-AI-01', titleAr: 'OCR confidence gate', acceptanceRuleAr: 'لا ينتقل النص إلى LLM قبل OCR review إذا كانت الثقة منخفضة أو الوثيقة تالفة.'),
        SmartExplorerAiGateItem(code: 'G-AI-02', titleAr: 'Structured LLM gate', acceptanceRuleAr: 'لا تقبل نتائج نص حر؛ المطلوب JSON/كيانات/مخاطر/ثقة.'),
        SmartExplorerAiGateItem(code: 'G-AI-03', titleAr: 'RAG citation gate', acceptanceRuleAr: 'كل نتيجة يجب أن تحمل citation أو excerpt أو مصدر داخلي.'),
        SmartExplorerAiGateItem(code: 'G-AI-04', titleAr: 'Review Board gate', acceptanceRuleAr: 'لا اعتماد بلا قبول مراجعة أو قرار طلب استكمال.'),
        SmartExplorerAiGateItem(code: 'G-AI-05', titleAr: 'Sovereign write gate', acceptanceRuleAr: 'لا كتابة في core/waqf/awqaf_system من AI مباشرة.'),
      ],
      integrationSteps: const <SmartExplorerAiIntegrationStep>[
        SmartExplorerAiIntegrationStep(order: 1, titleAr: 'تطبيق overlay', detailAr: 'انسخ smart_explorer/docs/instructions/sql_sandbox فقط فوق baseline الحالي.'),
        SmartExplorerAiIntegrationStep(order: 2, titleAr: 'عدم لمس الخريطة', detailAr: 'لا تنسخ map أو router ولا تغير activeLayers أو navigation-only.'),
        SmartExplorerAiIntegrationStep(order: 3, titleAr: 'تشغيل التحليل', detailAr: 'نفذ flutter analyze وافتح /admin/smart-explorer.'),
        SmartExplorerAiIntegrationStep(order: 4, titleAr: 'مراجعة SQL', detailAr: 'اقرأ SQL sandbox ولا تطبقه على الإنتاج قبل RBAC/RLS.'),
        SmartExplorerAiIntegrationStep(order: 5, titleAr: 'UAT', detailAr: 'اختبر أزرار ذكاء الوثائق وCSV وSQL وتعليمات AI.'),
      ],
      uatScenarios: const <SmartExplorerAiUatScenario>[
        SmartExplorerAiUatScenario(code: 'UAT-AI-01', titleAr: 'فتح أدوات AI', stepsAr: <String>['فتح /admin/smart-explorer', 'ضغط ذكاء الوثائق', 'نسخ التقرير'], acceptanceAr: 'يظهر تقرير AI-1→AI-6 دون crash.'),
        SmartExplorerAiUatScenario(code: 'UAT-AI-02', titleAr: 'CSV AI', stepsAr: <String>['ضغط CSV ذكاء الوثائق', 'فحص exportText'], acceptanceAr: 'يظهر CSV بالجداول والـ wrappers والبوابات.'),
        SmartExplorerAiUatScenario(code: 'UAT-AI-03', titleAr: 'SQL AI', stepsAr: <String>['ضغط SQL AI', 'مراجعة الجداول'], acceptanceAr: 'يظهر SQL draft ويذكر public/mustakshif بوضوح.'),
        SmartExplorerAiUatScenario(code: 'UAT-AI-04', titleAr: 'حماية الخريطة', stepsAr: <String>['تشغيل أدوات AI', 'العودة للخريطة'], acceptanceAr: 'لا تتغير activeLayers ولا سلوك navigation-only.'),
      ],
      errorRecords: const <SmartExplorerAiErrorRecord>[
        SmartExplorerAiErrorRecord(code: 'AI-ER-001', summaryAr: 'استعمال OCR خام كحقيقة', causeAr: 'غياب OCR review', resolutionAr: 'إجبار ocr_review_events قبل LLM/RAG', lastStableBaselineAr: 'Post-QZ Operational Closure'),
        SmartExplorerAiErrorRecord(code: 'AI-ER-002', summaryAr: 'نتيجة LLM بلا citation', causeAr: 'تحليل حر غير مرتبط بمصدر', resolutionAr: 'رفض النتيجة حتى إضافة rag_citations', lastStableBaselineAr: 'Post-QZ Operational Closure'),
        SmartExplorerAiErrorRecord(code: 'AI-ER-003', summaryAr: 'محاولة كتابة سيادية مباشرة', causeAr: 'خلط evidence candidate مع source of truth', resolutionAr: 'حصر الكتابة في mustakshif وعبر public wrappers', lastStableBaselineAr: 'Post-QZ Operational Closure'),
      ],
      finalArtifacts: const <SmartExplorerAiArtifact>[
        SmartExplorerAiArtifact(nameAr: 'AI Stage Report', pathHintAr: 'زر ذكاء الوثائق داخل /admin/smart-explorer'),
        SmartExplorerAiArtifact(nameAr: 'AI CSV', pathHintAr: 'زر CSV ذكاء الوثائق'),
        SmartExplorerAiArtifact(nameAr: 'AI SQL Draft', pathHintAr: 'زر SQL AI وملف sql_sandbox'),
        SmartExplorerAiArtifact(nameAr: 'AI Integration Instructions', pathHintAr: 'زر تعليمات AI وREADME الحزمة'),
      ],
    );
  }

  String buildAiDocumentIntelligenceStageReport({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildAiDocumentIntelligenceStagePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toReportText();
  }

  String buildAiDocumentIntelligenceStageCsv({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildAiDocumentIntelligenceStagePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toCsv();
  }

  String buildAiDocumentIntelligenceSqlDraftText({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildAiDocumentIntelligenceStagePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toSqlDraftText();
  }

  String buildAiDocumentIntelligenceIntegrationInstructionsText({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildAiDocumentIntelligenceStagePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toIntegrationInstructionsText();
  }

  String buildAiDocumentIntelligenceUserGuideAddendumText({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildAiDocumentIntelligenceStagePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toUserGuideAddendumText();
  }

  String _csv(Object? value) {
    final text = (value ?? '').toString().replaceAll('"', '""');
    return '"$text"';
  }

  bool _looksUnknown(String value) {
    final text = value.trim().toLowerCase();
    if (text.isEmpty) return true;
    return <String>{
      'unknown',
      'null',
      'n/a',
      'na',
      'غير محدد',
      'غير معروف',
      'بدون',
    }.contains(text);
  }

  String _text(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.toLowerCase() == 'null') return '';
    return text;
  }

  SmartExplorerSpatialVerificationStagePack buildSpatialVerificationStagePack({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    final blockers = <String>[
      if (runtimeDiagnostics == null) 'يفضل تشغيل تشخيص التشغيل قبل تنفيذ التحقق المكاني.',
      if (releaseReadiness == null) 'يفضل توليد جاهزية الإصدار قبل اعتماد أي cutover.',
      'يلزم تأكيد أسماء حقول جدول التسوية الفعلي قبل تطبيق RPC الإنتاجية.',
      'يلزم whitelisting للطبقات النقطية قبل batch matching.',
      'يلزم Review Board لأي نتيجة مطابقة أو مخطط مساحة قبل الربط مع waqf_asset_id.',
    ];

    final readiness = blockers.length <= 2
        ? 'جاهز للدمج التجريبي بعد مراجعة DBA/RBAC/RLS'
        : 'جاهز كعقد تنفيذ وواجهة تشغيل، ويحتاج إغلاق الحقول/RBAC قبل الإنتاج';

    return SmartExplorerSpatialVerificationStagePack(
      generatedAt: DateTime.now(),
      stageLabelAr: 'SMART_EXPLORER / المستكشف الذكي — Spatial Verification & Survey Plan Intelligence Stage SV-1→SV-6',
      queryAr: query,
      readinessLabelAr: readiness,
      scopeItems: const <SmartExplorerSpatialScopeItem>[
        SmartExplorerSpatialScopeItem(titleAr: 'أي طبقة نقطية', detailAr: 'مساجد، مقامات، مقابر، مواقع أثرية، خدمات، أو أي point layer مفعلة في المشروع.'),
        SmartExplorerSpatialScopeItem(titleAr: 'أي حدود مضلعية', detailAr: 'حدود مرسومة أو طبقة polygon تريد مقارنتها مع قطع التسوية.'),
        SmartExplorerSpatialScopeItem(titleAr: 'PDF/Image مخطط ورقي', detailAr: 'يحتاج OCR/georeferencing/control points قبل المقارنة.'),
        SmartExplorerSpatialScopeItem(titleAr: 'DWG/DXF', detailAr: 'يحتاج تحويل QGIS/OGR وتحديد CRS/طبقة الحدود قبل المقارنة.'),
        SmartExplorerSpatialScopeItem(titleAr: 'المجاورون', detailAr: 'استخراج القطع المجاورة، الحدود المشتركة، التداخل، الفراغات، ونوع العلاقة.'),
      ],
      stages: const <SmartExplorerSpatialStageItem>[
        SmartExplorerSpatialStageItem(
          code: 'SV-1',
          titleAr: 'Generic Point Layer Matching',
          statusAr: 'منفذ كعقد وواجهة تشغيل ومسودة SQL',
          descriptionAr: 'مطابقة أي طبقة نقطية داخل المشروع مع قطع التسوية عبر ST_Covers ثم ST_DWithin عند انحراف النقطة.',
          outputsAr: <String>['مرشحات مطابقة', 'حوض وقطعة ومساحة', 'درجة ثقة', 'حالة مراجعة'],
          blockersAr: <String>['طبقة غير موثقة الحقول', 'نقطة خارج tolerance', 'أكثر من قطعة مرشحة بلا مراجعة'],
        ),
        SmartExplorerSpatialStageItem(
          code: 'SV-2',
          titleAr: 'Point Survey Plan Generation',
          statusAr: 'منفذ كعقد ومخرج مخطط تحليلي',
          descriptionAr: 'توليد مخطط مساحة تحليلي للنقطة المطابقة يبين القطعة، الحوض، المساحة، موقع النقطة، والتنبيه القانوني.',
          outputsAr: <String>['GeoJSON plan', 'CSV metadata', 'plan_id', 'تنبيه قانوني'],
          blockersAr: <String>['لا candidate معتمد', 'لا geometry للقطعة', 'لا Review Board'],
        ),
        SmartExplorerSpatialStageItem(
          code: 'SV-3',
          titleAr: 'Boundary-to-Settlement Comparison',
          statusAr: 'منفذ كعقد مقارنة حدود',
          descriptionAr: 'مقارنة polygon مدخل مع قطع التسوية لحساب التداخل، الفرق، الخارج، الناقص، والانزياح.',
          outputsAr: <String>['overlap_area_m2', 'outside_area_m2', 'missing_area_m2', 'boundary_shift_m', 'comparison_score'],
          blockersAr: <String>['هندسة غير صالحة', 'SRID غير مؤكد', 'تداخل مع أكثر من جار بلا مراجعة'],
        ),
        SmartExplorerSpatialStageItem(
          code: 'SV-4',
          titleAr: 'PDF/Image Plan Intake',
          statusAr: 'منفذ كعقد intake/georeference/vector extraction',
          descriptionAr: 'استقبال مخطط PDF أو صورة، استخراج نص OCR عند الحاجة، ضبط مكاني عبر control points، ثم مطابقة الحدود المستخرجة.',
          outputsAr: <String>['document intake', 'control points', 'RMS error', 'extracted vectors', 'comparison report'],
          blockersAr: <String>['صورة غير واضحة', 'نقاط ضبط غير كافية', 'RMS error مرتفع'],
        ),
        SmartExplorerSpatialStageItem(
          code: 'SV-5',
          titleAr: 'DWG/DXF Plan Intake',
          statusAr: 'منفذ كعقد تحويل وتحقيق حدود',
          descriptionAr: 'استقبال DWG/DXF كمصدر مساحي، تحويله خارجيًا عبر QGIS/OGR إلى vectors، تحديد CRS، ثم المقارنة مع التسوية.',
          outputsAr: <String>['extracted_plan_vectors', 'boundary comparison', 'CRS/georeference notes', 'quality score'],
          blockersAr: <String>['DWG بلا CRS', 'خطوط غير مغلقة', 'طبقة حدود غير محددة'],
        ),
        SmartExplorerSpatialStageItem(
          code: 'SV-6',
          titleAr: 'Review Board + Export',
          statusAr: 'منفذ كعقد مراجعة وتصدير',
          descriptionAr: 'توجيه كل نتائج المطابقة والمخططات والتداخلات إلى Review Board قبل أي اعتماد أو ربط سيادي.',
          outputsAr: <String>['review event', 'generated survey plan', 'evidence timeline candidate', 'export manifest'],
          blockersAr: <String>['قرار مراجعة مفقود', 'تعارض بين GIS وOCR/RAG', 'محاولة تحديث مصدر سيادي مباشرة'],
        ),
      ],
      spatialEngines: const <SmartExplorerSpatialEngineItem>[
        SmartExplorerSpatialEngineItem(code: 'ENG-POINT', titleAr: 'Point in Settlement Parcel', functions: <String>['ST_Covers', 'ST_DWithin', 'ST_Distance', 'ST_ClosestPoint'], outputAr: 'مرشح قطعة/حوض للنقطة مع distance/confidence'),
        SmartExplorerSpatialEngineItem(code: 'ENG-BOUNDARY', titleAr: 'Boundary Difference', functions: <String>['ST_Intersection', 'ST_Difference', 'ST_SymDifference', 'ST_Area', 'ST_HausdorffDistance'], outputAr: 'تقرير تداخل وفروق وانزياح'),
        SmartExplorerSpatialEngineItem(code: 'ENG-ADJ', titleAr: 'Adjacency Validation', functions: <String>['ST_Touches', 'ST_Intersects', 'ST_Boundary', 'ST_Length', 'ST_Distance'], outputAr: 'تقرير مجاورين وحدود مشتركة/فراغ/تداخل'),
        SmartExplorerSpatialEngineItem(code: 'ENG-DOC', titleAr: 'Document Plan Intake', functions: <String>['OCR', 'Georeference control points', 'Vectorization', 'ST_MakeValid'], outputAr: 'مخطط ورقي مضبوط ومقارن مع التسوية'),
        SmartExplorerSpatialEngineItem(code: 'ENG-DWG', titleAr: 'DWG/DXF Intake', functions: <String>['ogr2ogr', 'QGIS polygonize', 'Reproject', 'Fix geometries'], outputAr: 'Vectors مستخرجة قابلة للمقارنة'),
      ],
      requiredTables: const <SmartExplorerSpatialSchemaItem>[
        SmartExplorerSpatialSchemaItem(name: 'mustakshif.spatial_document_intake', purposeAr: 'استقبال PDF/Image/DWG/DXF وبيانات المخطط', policyAr: 'تحليل ومراجعة فقط'),
        SmartExplorerSpatialSchemaItem(name: 'mustakshif.spatial_match_requests', purposeAr: 'طلبات المطابقة المكانية', policyAr: 'إنشاء عبر wrapper'),
        SmartExplorerSpatialSchemaItem(name: 'mustakshif.spatial_match_candidates', purposeAr: 'مرشحات مطابقة النقاط/الحدود مع التسوية', policyAr: 'Review required'),
        SmartExplorerSpatialSchemaItem(name: 'mustakshif.plan_georeference_control_points', purposeAr: 'نقاط ضبط المخططات الورقية', policyAr: 'مراجعة فنية'),
        SmartExplorerSpatialSchemaItem(name: 'mustakshif.plan_georeference_jobs', purposeAr: 'نتائج georeference وRMS error', policyAr: 'لا اعتماد عند RMS مرتفع'),
        SmartExplorerSpatialSchemaItem(name: 'mustakshif.extracted_plan_vectors', purposeAr: 'حدود مستخرجة من PDF/DWG/DXF', policyAr: 'مصدر تحليلي لا سيادي'),
        SmartExplorerSpatialSchemaItem(name: 'mustakshif.boundary_comparison_results', purposeAr: 'نتائج فرق الحدود والتداخل', policyAr: 'مراجعة إلزامية'),
        SmartExplorerSpatialSchemaItem(name: 'mustakshif.adjacency_validation_results', purposeAr: 'نتائج المجاورين والتعديات والفراغات', policyAr: 'مراجعة فنية'),
        SmartExplorerSpatialSchemaItem(name: 'mustakshif.generated_survey_plans', purposeAr: 'مخططات مساحة تحليلية ومخرجات تصدير', policyAr: 'ليست مخططًا رسميًا قبل الاعتماد'),
        SmartExplorerSpatialSchemaItem(name: 'mustakshif.spatial_verification_review_events', purposeAr: 'قرارات Review Board للمطابقة والمخططات', policyAr: 'بوابة الاعتماد/الرفض'),
      ],
      requiredRpcWrappers: const <SmartExplorerSpatialSchemaItem>[
        SmartExplorerSpatialSchemaItem(name: 'public.rpc_mustakshif_create_spatial_match_request_v1', purposeAr: 'إنشاء طلب مطابقة', policyAr: 'public wrapper فقط'),
        SmartExplorerSpatialSchemaItem(name: 'public.rpc_mustakshif_generate_point_to_parcel_candidates_v1', purposeAr: 'مطابقة نقطة مفردة مع التسوية', policyAr: 'يحتاج mapping حقول التسوية'),
        SmartExplorerSpatialSchemaItem(name: 'public.rpc_mustakshif_generate_layer_points_to_parcels_v1', purposeAr: 'مطابقة طبقة نقطية كاملة', policyAr: 'whitelisted layers فقط'),
        SmartExplorerSpatialSchemaItem(name: 'public.rpc_mustakshif_generate_polygon_boundary_comparison_v1', purposeAr: 'مقارنة حدود polygon مع التسوية', policyAr: 'تحليل ومراجعة'),
        SmartExplorerSpatialSchemaItem(name: 'public.rpc_mustakshif_create_spatial_document_intake_v1', purposeAr: 'تسجيل PDF/Image/DWG/DXF', policyAr: 'لا يثبت حدودًا رسميًا'),
        SmartExplorerSpatialSchemaItem(name: 'public.rpc_mustakshif_submit_plan_georeference_points_v1', purposeAr: 'تسجيل نقاط الضبط', policyAr: 'مراجعة فنية'),
        SmartExplorerSpatialSchemaItem(name: 'public.rpc_mustakshif_generate_document_plan_comparison_v1', purposeAr: 'مقارنة مخطط PDF/Image', policyAr: 'بعد georeference/vectorization'),
        SmartExplorerSpatialSchemaItem(name: 'public.rpc_mustakshif_generate_dwg_plan_comparison_v1', purposeAr: 'مقارنة DWG/DXF', policyAr: 'بعد تحويل QGIS/OGR'),
        SmartExplorerSpatialSchemaItem(name: 'public.rpc_mustakshif_generate_adjacency_validation_v1', purposeAr: 'تحليل المجاورين', policyAr: 'Review required'),
        SmartExplorerSpatialSchemaItem(name: 'public.rpc_mustakshif_generate_survey_plan_output_v1', purposeAr: 'توليد مخطط مساحة تحليلي', policyAr: 'not official until reviewed'),
        SmartExplorerSpatialSchemaItem(name: 'public.rpc_mustakshif_submit_spatial_verification_review_v1', purposeAr: 'قرار مراجعة مكاني', policyAr: 'Review Board فقط'),
        SmartExplorerSpatialSchemaItem(name: 'public.rpc_mustakshif_list_spatial_verification_results_v1', purposeAr: 'عرض النتائج', policyAr: 'قراءة مقيدة بالصلاحيات'),
      ],
      gates: const <SmartExplorerSpatialGateItem>[
        SmartExplorerSpatialGateItem(code: 'G-SV-01', titleAr: 'Source Layer Whitelist', ruleAr: 'لا batch matching لطبقة نقطية غير موثقة المصدر والحقول.'),
        SmartExplorerSpatialGateItem(code: 'G-SV-02', titleAr: 'SRID/CRS Gate', ruleAr: 'لا مقارنة حدود إذا كان SRID/CRS غير مؤكد أو التحويل غير موثق.'),
        SmartExplorerSpatialGateItem(code: 'G-SV-03', titleAr: 'Tolerance Gate', ruleAr: 'المطابقة nearest لا تعتمد عند تجاوز tolerance إلا كملاحظة فشل.'),
        SmartExplorerSpatialGateItem(code: 'G-SV-04', titleAr: 'Neighbor Conflict Gate', ruleAr: 'أي تداخل مع مجاور أو أكثر من مرشح ينتقل للمراجعة ولا يعتمد آليًا.'),
        SmartExplorerSpatialGateItem(code: 'G-SV-05', titleAr: 'Document Plan Gate', ruleAr: 'PDF/Image/DWG يحتاج georeference/vectorization quality قبل المقارنة.'),
        SmartExplorerSpatialGateItem(code: 'G-SV-06', titleAr: 'Sovereign Write Gate', ruleAr: 'لا كتابة في core/waqf/awqaf_system؛ الناتج مرشح مراجعة في mustakshif فقط.'),
      ],
      integrationSteps: const <SmartExplorerSpatialIntegrationStep>[
        SmartExplorerSpatialIntegrationStep(order: 1, titleAr: 'تطبيق overlay', detailAr: 'انسخ smart_explorer/docs/instructions/sql_sandbox فقط فوق baseline الحالي للمستكشف الأصلي.'),
        SmartExplorerSpatialIntegrationStep(order: 2, titleAr: 'حماية الخريطة', detailAr: 'لا تنسخ map أو router ولا تغير activeLayers أو navigation-only.'),
        SmartExplorerSpatialIntegrationStep(order: 3, titleAr: 'تأكيد حقول التسوية', detailAr: 'حدد أسماء حقول parcel_id/block_no/parcel_no/area/geom في جدول التسوية الفعلي.'),
        SmartExplorerSpatialIntegrationStep(order: 4, titleAr: 'تأكيد الطبقات النقطية', detailAr: 'جهّز whitelist للطبقات النقطية المسموح بمطابقتها وأسماء حقول id/name/geom.'),
        SmartExplorerSpatialIntegrationStep(order: 5, titleAr: 'اختبار واجهة المستكشف الذكي', detailAr: 'افتح /admin/smart-explorer واختبر أزرار التحقق المكاني وCSV وSQL وتعليمات مكاني.'),
        SmartExplorerSpatialIntegrationStep(order: 6, titleAr: 'مراجعة SQL', detailAr: 'لا تطبق SQL إنتاجيًا قبل مراجعة RLS/RBAC وDBA، فالملف sandbox draft.'),
      ],
      uatScenarios: const <SmartExplorerSpatialUatScenario>[
        SmartExplorerSpatialUatScenario(code: 'UAT-SV-01', titleAr: 'فتح أدوات التحقق المكاني', stepsAr: <String>['فتح /admin/smart-explorer', 'ضغط التحقق المكاني', 'نسخ التقرير'], acceptanceAr: 'يظهر تقرير SV-1→SV-6 دون crash.'),
        SmartExplorerSpatialUatScenario(code: 'UAT-SV-02', titleAr: 'CSV مكاني', stepsAr: <String>['ضغط CSV التحقق المكاني', 'فحص exportText'], acceptanceAr: 'يظهر CSV بالمراحل والجداول والـ wrappers.'),
        SmartExplorerSpatialUatScenario(code: 'UAT-SV-03', titleAr: 'SQL مكاني', stepsAr: <String>['ضغط SQL مكاني', 'مراجعة الجداول'], acceptanceAr: 'يظهر SQL draft ويحصر الجداول في mustakshif والـ wrappers في public.'),
        SmartExplorerSpatialUatScenario(code: 'UAT-SV-04', titleAr: 'حماية الخريطة', stepsAr: <String>['تشغيل أدوات SV', 'العودة للخريطة'], acceptanceAr: 'لا تتغير activeLayers ولا سلوك navigation-only.'),
        SmartExplorerSpatialUatScenario(code: 'UAT-SV-05', titleAr: 'تجربة بيانات حقيقية لاحقة', stepsAr: <String>['اختيار طبقة نقطية', 'مطابقة نقطة', 'مراجعة مرشح'], acceptanceAr: 'الناتج يظهر كمرشح review لا كاعتماد سيادي.'),
      ],
      errorRecords: const <SmartExplorerSpatialErrorRecord>[
        SmartExplorerSpatialErrorRecord(code: 'SV-ER-001', summaryAr: 'اعتماد نقطة خاطئة بسبب GPS ضعيف', causeAr: 'استخدام ST_Covers فقط أو tolerance غير مضبوط', resolutionAr: 'إضافة ST_DWithin مع distance/confidence وReview Board', lastStableBaselineAr: 'AI-OCR-LLM-RAG Review Board Stage'),
        SmartExplorerSpatialErrorRecord(code: 'SV-ER-002', summaryAr: 'مقارنة DWG بلا CRS', causeAr: 'ملف CAD محلي الإحداثيات', resolutionAr: 'إجبار CRS/georeference أو نقاط ضبط قبل المقارنة', lastStableBaselineAr: 'AI-OCR-LLM-RAG Review Board Stage'),
        SmartExplorerSpatialErrorRecord(code: 'SV-ER-003', summaryAr: 'اعتبار مخطط تحليلي رسميًا', causeAr: 'غياب legal notice وReview Board', resolutionAr: 'وسم كل مخرج analytical_not_official_until_reviewed', lastStableBaselineAr: 'AI-OCR-LLM-RAG Review Board Stage'),
        SmartExplorerSpatialErrorRecord(code: 'SV-ER-004', summaryAr: 'تداخل مع مجاور غير مرصود', causeAr: 'عدم تشغيل adjacency validation', resolutionAr: 'إلزام تقرير المجاورين عند boundary comparison', lastStableBaselineAr: 'AI-OCR-LLM-RAG Review Board Stage'),
      ],
      finalArtifacts: const <SmartExplorerSpatialArtifact>[
        SmartExplorerSpatialArtifact(nameAr: 'Spatial Verification Report', pathHintAr: 'زر التحقق المكاني داخل /admin/smart-explorer'),
        SmartExplorerSpatialArtifact(nameAr: 'Spatial Verification CSV', pathHintAr: 'زر CSV التحقق المكاني'),
        SmartExplorerSpatialArtifact(nameAr: 'Spatial SQL Draft', pathHintAr: 'زر SQL مكاني وملف sql_sandbox'),
        SmartExplorerSpatialArtifact(nameAr: 'Integration Instructions', pathHintAr: 'زر تعليمات مكاني وREADME الحزمة'),
        SmartExplorerSpatialArtifact(nameAr: 'User Guide Addendum', pathHintAr: 'زر دليل مكاني وdocs/smart_explorer'),
      ],
    );
  }

  String buildSpatialVerificationStageReport({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildSpatialVerificationStagePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toReportText();
  }

  String buildSpatialVerificationStageCsv({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildSpatialVerificationStagePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toCsv();
  }

  String buildSpatialVerificationSqlDraftText({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildSpatialVerificationStagePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toSqlDraftText();
  }

  String buildSpatialVerificationIntegrationInstructionsText({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildSpatialVerificationStagePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toIntegrationInstructionsText();
  }

  String buildSpatialVerificationUserGuideAddendumText({
    required String query,
    required List<SmartExplorerResult> results,
    SmartExplorerDocumentAnalysis? documentAnalysis,
    SmartExplorerEvidenceMatrix? evidenceMatrix,
    SmartExplorerQualityScorecard? qualityScorecard,
    SmartExplorerRuntimeDiagnostics? runtimeDiagnostics,
    SmartExplorerReleaseReadiness? releaseReadiness,
  }) {
    return buildSpatialVerificationStagePack(
      query: query,
      results: results,
      documentAnalysis: documentAnalysis,
      evidenceMatrix: evidenceMatrix,
      qualityScorecard: qualityScorecard,
      runtimeDiagnostics: runtimeDiagnostics,
      releaseReadiness: releaseReadiness,
    ).toUserGuideAddendumText();
  }

}
