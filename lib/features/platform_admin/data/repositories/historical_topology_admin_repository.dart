import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/models/historical_admin_relation_review_row.dart';
import '../../domain/models/historical_admin_review_metric.dart';
import '../../domain/models/historical_admin_spatial_link_review_row.dart';
import '../../domain/models/historical_gap_summary_item.dart';
import '../../domain/models/historical_topology_queue_row.dart';

final historicalTopologyAdminRepositoryProvider =
    Provider<HistoricalTopologyAdminRepository>((ref) {
  return HistoricalTopologyAdminRepository(ref.watch(supabaseClientProvider));
});

class HistoricalTopologyAdminRepository {
  final SupabaseClient _client;
  HistoricalTopologyAdminRepository(this._client);

  Future<List<HistoricalAdminReviewMetric>> fetchSummary() async {
    final res = await _client
        .schema('topology')
        .from('v_historical_admin_review_summary')
        .select()
        .order('metric');
    return (res as List)
        .map((e) => HistoricalAdminReviewMetric.fromJson(
            (e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<List<HistoricalGapSummaryItem>> fetchGapSummary() async {
    final res = await _client
        .schema('topology')
        .from('v_historical_gap_summary_final')
        .select()
        .order('final_gap_reason');
    return (res as List)
        .map((e) => HistoricalGapSummaryItem.fromJson(
            (e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<List<HistoricalAdminRelationReviewRow>> fetchRelations() async {
    final res = await _client
        .schema('topology')
        .from('v_historical_admin_relations_review_labeled')
        .select()
        .order('source_period_id')
        .order('source_code')
        .order('relation_type')
        .order('target_period_id')
        .order('target_code');

    return (res as List)
        .map((e) => HistoricalAdminRelationReviewRow.fromJson(
            (e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<List<HistoricalAdminSpatialLinkReviewRow>> fetchSpatialLinks() async {
    final res = await _client
        .schema('topology')
        .from('v_historical_admin_spatial_links_review')
        .select()
        .order('hau_period_id')
        .order('historical_admin_code')
        .order('is_primary', ascending: false)
        .order('confidence', ascending: false);

    return (res as List)
        .map((e) => HistoricalAdminSpatialLinkReviewRow.fromJson(
            (e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<List<HistoricalTopologyQueueRow>> fetchQueueRows() async {
    final res = await _client
        .schema('topology')
        .from('historical_topology_review_queue')
        .select()
        .order('period_id')
        .order('code');
    return (res as List)
        .map((e) => HistoricalTopologyQueueRow.fromJson(
            (e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<List<HistoricalTopologyQueueRow>> fetchAppliedEvents() async {
    final res = await _client
        .schema('topology')
        .from('historical_topology_review_queue')
        .select()
        .not('applied_at', 'is', null)
        .order('applied_at', ascending: false)
        .order('id', ascending: false);
    return (res as List)
        .map((e) => HistoricalTopologyQueueRow.fromJson(
            (e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> updateRelation({
    required int relationId,
    required String relationType,
    required double confidence,
    required bool isActive,
    String? notes,
  }) async {
    await _client.schema('topology').from('historical_admin_relations').update({
      'relation_type': relationType,
      'confidence': confidence,
      'is_active': isActive,
      'notes': notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', relationId);
  }

  Future<void> updateSpatialLink({
    required int spatialLinkId,
    required String matchMethod,
    required double confidence,
    required bool isPrimary,
    String? notes,
  }) async {
    final current = await _client
        .schema('topology')
        .from('historical_admin_spatial_links')
        .select('historical_admin_unit_id')
        .eq('id', spatialLinkId)
        .maybeSingle();

    if (current == null) {
      throw StateError('تعذر العثور على الرابط المكاني المطلوب.');
    }

    final historicalAdminUnitId = current['historical_admin_unit_id'];

    if (isPrimary) {
      await _client
          .schema('topology')
          .from('historical_admin_spatial_links')
          .update({
        'is_primary': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('historical_admin_unit_id', historicalAdminUnitId);
    }

    await _client
        .schema('topology')
        .from('historical_admin_spatial_links')
        .update({
      'match_method': matchMethod,
      'confidence': confidence,
      'is_primary': isPrimary,
      'notes': notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', spatialLinkId);
  }

  Future<void> updateQueueRow({
    required int queueId,
    required String decisionStatus,
    String? suggestedEventFamily,
    String? reviewNote,
    String? relationDirection,
    String? approvedRelationType,
    double? confidence,
    String? adminNotes,
    int? candidateTargetUnitId,
    String? candidateTargetCode,
    int? candidateTargetPeriodId,
    String? candidateTargetPeriodTitleAr,
  }) async {
    await _client
        .schema('topology')
        .from('historical_topology_review_queue')
        .update({
      'decision_status': decisionStatus,
      'suggested_event_family': suggestedEventFamily,
      'review_note': reviewNote,
      'relation_direction': relationDirection,
      'approved_relation_type': approvedRelationType,
      'confidence': confidence,
      'admin_notes': adminNotes,
      'candidate_target_unit_id': candidateTargetUnitId,
      'candidate_target_code': candidateTargetCode,
      'candidate_target_period_id': candidateTargetPeriodId,
      'candidate_target_period_title_ar': candidateTargetPeriodTitleAr,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', queueId);
  }

  Future<void> quickSetQueueStatus(
      {required int queueId, required String decisionStatus}) async {
    await _client
        .schema('topology')
        .from('historical_topology_review_queue')
        .update({
      'decision_status': decisionStatus,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', queueId);
  }

  Future<void> batchSetQueueStatus(
      {required List<int> queueIds, required String decisionStatus}) async {
    if (queueIds.isEmpty) return;
    await _client
        .schema('topology')
        .from('historical_topology_review_queue')
        .update({
      'decision_status': decisionStatus,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).inFilter('id', queueIds);
  }

  Future<int> applyApprovedQueueRows(
      List<HistoricalTopologyQueueRow> rows) async {
    var appliedCount = 0;
    for (final row in rows) {
      if (!row.isApprovedPendingApply) continue;
      final relationType = row.approvedRelationType;
      final candidateTargetUnitId =
          int.tryParse(row.candidateTargetUnitId ?? '');
      final queueUnitId = int.tryParse(row.historicalAdminUnitId);
      if (relationType == null ||
          candidateTargetUnitId == null ||
          queueUnitId == null) {
        continue;
      }

      final int sourceId;
      final int targetId;
      if (row.queueIsTarget) {
        sourceId = candidateTargetUnitId;
        targetId = queueUnitId;
      } else {
        sourceId = queueUnitId;
        targetId = candidateTargetUnitId;
      }

      final existing = await _client
          .schema('topology')
          .from('historical_admin_relations')
          .select('id')
          .eq('source_historical_admin_unit_id', sourceId)
          .eq('target_historical_admin_unit_id', targetId)
          .eq('relation_type', relationType)
          .maybeSingle();

      int relationId;
      if (existing != null && existing['id'] != null) {
        relationId = (existing['id'] as num).toInt();
      } else {
        final inserted = await _client
            .schema('topology')
            .from('historical_admin_relations')
            .insert({
              'source_historical_admin_unit_id': sourceId,
              'target_historical_admin_unit_id': targetId,
              'relation_type': relationType,
              'confidence': row.confidence ?? 0.9,
              'notes': row.adminNotes,
            })
            .select('id')
            .single();
        relationId = (inserted['id'] as num).toInt();
      }

      await _client
          .schema('topology')
          .from('historical_topology_review_queue')
          .update({
        'applied_at': DateTime.now().toUtc().toIso8601String(),
        'applied_relation_id': relationId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', row.id);
      appliedCount += 1;
    }
    return appliedCount;
  }
}
