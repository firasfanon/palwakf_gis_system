import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/models/historical_admin_relation_crud_row.dart';
import '../../domain/models/historical_admin_spatial_link_row.dart';
import '../../domain/models/historical_admin_unit_row.dart';
import '../../domain/models/historical_manual_predecessor_map_row.dart';
import '../../domain/models/historical_period_row.dart';
import '../../domain/models/historical_topology_queue_row.dart';

final historicalCrudAdminRepositoryProvider = Provider<HistoricalCrudAdminRepository>((ref) {
  return HistoricalCrudAdminRepository(ref.watch(supabaseClientProvider));
});

class HistoricalCrudAdminRepository {
  final SupabaseClient _client;
  HistoricalCrudAdminRepository(this._client);

  Future<List<HistoricalPeriodRow>> fetchPeriods() async {
    final res = await _client.rpc('rpc_historical_period_list_v1');
    return (res as List)
        .map((e) => HistoricalPeriodRow.fromJson((e as Map).cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.periodNo.compareTo(b.periodNo));
  }

  Future<void> savePeriod({
    int? id,
    required String titleAr,
    String? titleEn,
    int? startYear,
    int? endYear,
    int? orderIndex,
    bool isDefault = false,
  }) async {
    throw UnsupportedError(
      'Historical periods are now managed from hist.period_registry via SQL registry, not public.historical_periods.',
    );
  }

  Future<void> deletePeriod(int id) async {
    throw UnsupportedError(
      'Historical periods are now managed from hist.period_registry via SQL registry, not public.historical_periods.',
    );
  }

  Future<List<HistoricalAdminUnitRow>> fetchUnits() async {
    final unitsRes = await _client
        .schema('public')
        .from('historical_admin_units')
        .select('id, code, period_id, origin_community_code, parent_id')
        .order('period_id')
        .order('code');

    final periodsRes = await _client
        .schema('public')
        .from('historical_periods')
        .select('id, title_ar, start_year, end_year');

    final periodsById = <int, Map<String, dynamic>>{};
    for (final raw in (periodsRes as List)) {
      final row = (raw as Map).cast<String, dynamic>();
      final id = row['id'];
      if (id is num) periodsById[id.toInt()] = row;
    }

    return (unitsRes as List).map((e) {
      final unit = (e as Map).cast<String, dynamic>();
      final periodId = unit['period_id'];
      final period = periodId is num ? periodsById[periodId.toInt()] : null;
      return HistoricalAdminUnitRow.fromJson({
        ...unit,
        'period_title_ar': period?['title_ar'],
        'period_start_year': period?['start_year'],
        'period_end_year': period?['end_year'],
      });
    }).toList();
  }

  Future<void> saveUnit({
    int? id,
    required String code,
    required int periodId,
    String? originCommunityCode,
    int? parentId,
  }) async {
    final payload = {
      'code': code,
      'period_id': periodId,
      'origin_community_code': originCommunityCode,
      'parent_id': parentId,
    };
    if (id == null) {
      await _client.schema('public').from('historical_admin_units').insert(payload);
    } else {
      await _client.schema('public').from('historical_admin_units').update(payload).eq('id', id);
    }
  }

  Future<void> deleteUnit(int id) async {
    await _client.schema('public').from('historical_admin_units').delete().eq('id', id);
  }

  Future<List<HistoricalAdminRelationCrudRow>> fetchRelationTableRows() async {
    final res = await _client
        .schema('topology')
        .from('historical_admin_relations')
        .select('id, source_historical_admin_unit_id, target_historical_admin_unit_id, relation_type, confidence, is_active, notes')
        .order('id', ascending: false);
    return (res as List)
        .map((e) => HistoricalAdminRelationCrudRow.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> saveRelation({
    int? id,
    required int sourceHistoricalAdminUnitId,
    required int targetHistoricalAdminUnitId,
    required String relationType,
    required double confidence,
    required bool isActive,
    String? notes,
  }) async {
    final payload = {
      'source_historical_admin_unit_id': sourceHistoricalAdminUnitId,
      'target_historical_admin_unit_id': targetHistoricalAdminUnitId,
      'relation_type': relationType,
      'confidence': confidence,
      'is_active': isActive,
      'notes': notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (id == null) {
      await _client.schema('topology').from('historical_admin_relations').insert(payload);
    } else {
      await _client.schema('topology').from('historical_admin_relations').update(payload).eq('id', id);
    }
  }

  Future<void> deleteRelation(int id) async {
    await _client.schema('topology').from('historical_admin_relations').delete().eq('id', id);
  }

  Future<List<HistoricalTopologyQueueRow>> fetchQueueTableRows() async {
    final res = await _client.schema('topology').from('historical_topology_review_queue').select().order('period_id').order('code');
    return (res as List)
        .map((e) => HistoricalTopologyQueueRow.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> saveQueueRow({
    int? id,
    required int historicalAdminUnitId,
    required String code,
    required int periodId,
    required String finalGapReason,
    String? periodTitleAr,
    String? originCommunityCode,
    String? suggestedEventFamily,
    String? reviewNote,
    String? relationDirection,
    String? decisionStatus,
    String? approvedRelationType,
    double? confidence,
    String? adminNotes,
    int? candidateTargetUnitId,
    String? candidateTargetCode,
    int? candidateTargetPeriodId,
    String? candidateTargetPeriodTitleAr,
  }) async {
    final payload = {
      'historical_admin_unit_id': historicalAdminUnitId,
      'code': code,
      'period_id': periodId,
      'period_title_ar': periodTitleAr,
      'origin_community_code': originCommunityCode,
      'final_gap_reason': finalGapReason,
      'suggested_event_family': suggestedEventFamily,
      'review_note': reviewNote,
      'relation_direction': relationDirection,
      'decision_status': decisionStatus,
      'approved_relation_type': approvedRelationType,
      'confidence': confidence,
      'admin_notes': adminNotes,
      'candidate_target_unit_id': candidateTargetUnitId,
      'candidate_target_code': candidateTargetCode,
      'candidate_target_period_id': candidateTargetPeriodId,
      'candidate_target_period_title_ar': candidateTargetPeriodTitleAr,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (id == null) {
      await _client.schema('topology').from('historical_topology_review_queue').insert(payload);
    } else {
      await _client.schema('topology').from('historical_topology_review_queue').update(payload).eq('id', id);
    }
  }

  Future<void> deleteQueueRow(int id) async {
    await _client.schema('topology').from('historical_topology_review_queue').delete().eq('id', id);
  }

  Future<List<HistoricalManualPredecessorMapRow>> fetchManualMappings() async {
    final res = await _client.schema('topology').from('historical_manual_predecessor_map').select().order('review_queue_id').order('id');
    return (res as List)
        .map((e) => HistoricalManualPredecessorMapRow.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> saveManualMapping({
    int? id,
    required int reviewQueueId,
    required int targetUnitId,
    required String targetCode,
    required int targetPeriodId,
    String? targetPeriodTitleAr,
    required int sourceUnitId,
    required String sourceCode,
    required int sourcePeriodId,
    String? sourcePeriodTitleAr,
    required String suggestedRelationType,
    required double confidence,
    String? notes,
    required bool isSelected,
  }) async {
    if (isSelected) {
      await _client.schema('topology').from('historical_manual_predecessor_map').update({
        'is_selected': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('review_queue_id', reviewQueueId);
    }

    final payload = {
      'review_queue_id': reviewQueueId,
      'target_unit_id': targetUnitId,
      'target_code': targetCode,
      'target_period_id': targetPeriodId,
      'target_period_title_ar': targetPeriodTitleAr,
      'source_unit_id': sourceUnitId,
      'source_code': sourceCode,
      'source_period_id': sourcePeriodId,
      'source_period_title_ar': sourcePeriodTitleAr,
      'suggested_relation_type': suggestedRelationType,
      'confidence': confidence,
      'notes': notes,
      'is_selected': isSelected,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (id == null) {
      await _client.schema('topology').from('historical_manual_predecessor_map').insert(payload);
    } else {
      await _client.schema('topology').from('historical_manual_predecessor_map').update(payload).eq('id', id);
    }
  }

  Future<void> deleteManualMapping(int id) async {
    await _client.schema('topology').from('historical_manual_predecessor_map').delete().eq('id', id);
  }

  Future<List<HistoricalAdminSpatialLinkRow>> fetchSpatialLinkTableRows() async {
    final res = await _client
        .schema('topology')
        .from('historical_admin_spatial_links')
        .select('id, historical_admin_unit_id, hist_level, hist_period_no, hist_admin_no, match_method, confidence, is_primary, notes')
        .order('historical_admin_unit_id')
        .order('hist_period_no');
    return (res as List)
        .map((e) => HistoricalAdminSpatialLinkRow.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> saveSpatialLink({
    int? id,
    required int historicalAdminUnitId,
    required String histLevel,
    required int histPeriodNo,
    required int histAdminNo,
    required String matchMethod,
    required double confidence,
    required bool isPrimary,
    String? notes,
  }) async {
    if (isPrimary) {
      await _client.schema('topology').from('historical_admin_spatial_links').update({
        'is_primary': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('historical_admin_unit_id', historicalAdminUnitId);
    }

    final payload = {
      'historical_admin_unit_id': historicalAdminUnitId,
      'hist_level': histLevel,
      'hist_period_no': histPeriodNo,
      'hist_admin_no': histAdminNo,
      'match_method': matchMethod,
      'confidence': confidence,
      'is_primary': isPrimary,
      'notes': notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (id == null) {
      await _client.schema('topology').from('historical_admin_spatial_links').insert(payload);
    } else {
      await _client.schema('topology').from('historical_admin_spatial_links').update(payload).eq('id', id);
    }
  }

  Future<void> deleteSpatialLink(int id) async {
    await _client.schema('topology').from('historical_admin_spatial_links').delete().eq('id', id);
  }
}
