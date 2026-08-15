import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/models/historical_style_admin_rows.dart';

final historyStylesAdminRepositoryProvider =
    Provider<HistoryStylesAdminRepository>((ref) {
  return HistoryStylesAdminRepository(ref.watch(supabaseClientProvider));
});

class HistoryStylesAdminRepository {
  final SupabaseClient _client;
  HistoryStylesAdminRepository(this._client);

  List<T> _mapRows<T>(dynamic res, T Function(Map<String, dynamic>) mapper) {
    return (res as List)
        .map((e) => mapper((e as Map).cast<String, dynamic>()))
        .toList();
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> _castJson(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  Future<List<HistoricalStyleProfileRow>> fetchProfiles() async {
    final res = await _client.rpc('rpc_history_style_profiles_list_v1');
    return _mapRows(res, HistoricalStyleProfileRow.fromJson);
  }

  Future<List<HistoricalAdminLevelOptionRow>> fetchLevels() async {
    final res = await _client.rpc('rpc_history_style_levels_v1');
    return (res as List).map((raw) {
      final row = (raw as Map).cast<String, dynamic>();
      return HistoricalAdminLevelOptionRow(
        levelKey: (row['level_key'] ?? '').toString(),
        levelNameAr: (row['label_ar'] ?? '').toString(),
        levelNameEn: null,
        levelScope: null,
      );
    }).toList();
  }

  Future<List<HistoricalPeriodStyleOptionRow>> fetchPeriods() async {
    final res = await _client.rpc('rpc_history_style_periods_v1');
    return (res as List).map((raw) {
      final row = (raw as Map).cast<String, dynamic>();
      return HistoricalPeriodStyleOptionRow(
        periodNo: _toInt(row['period_no']) ?? 0,
        titleAr: (row['ontology_label_ar'] ?? '').toString(),
        isOperational: row['is_operational'] == true,
        defaultLevelKey: row['default_level_key']?.toString(),
        periodKind: row['period_kind']?.toString(),
      );
    }).toList();
  }

  Future<List<HistoricalLevelStyleDefaultRow>> fetchLevelDefaults() async {
    final res = await _client.rpc('rpc_history_level_style_defaults_list_v1');
    return (res as List).map((raw) {
      final row = (raw as Map).cast<String, dynamic>();
      return HistoricalLevelStyleDefaultRow(
        levelKey: (row['level_key'] ?? '').toString(),
        levelNameAr: (row['level_label_ar'] ?? row['level_key'] ?? '').toString(),
        profileKey: row['profile_key']?.toString(),
        profileNameAr: row['profile_name_ar']?.toString(),
        overrideStyleJson: _castJson(row['override_style_json']),
        isActive: row['is_active'] == true,
        notes: row['notes']?.toString(),
      );
    }).toList();
  }

  Future<List<HistoricalPeriodLevelStyleOverrideRow>> fetchPeriodLevelOverrides() async {
    final res = await _client.rpc('rpc_history_period_level_styles_list_v1');
    return (res as List).map((raw) {
      final row = (raw as Map).cast<String, dynamic>();
      return HistoricalPeriodLevelStyleOverrideRow(
        periodNo: _toInt(row['period_no']) ?? 0,
        periodTitleAr: (row['period_label_ar'] ?? '').toString(),
        levelKey: (row['level_key'] ?? '').toString(),
        levelNameAr: (row['level_label_ar'] ?? row['level_key'] ?? '').toString(),
        profileKey: row['profile_key']?.toString(),
        profileNameAr: row['profile_name_ar']?.toString(),
        overrideStyleJson: _castJson(row['override_style_json']),
        isActive: row['is_active'] == true,
        notes: row['notes']?.toString(),
      );
    }).toList();
  }

  Future<List<HistoricalFeatureStyleOverrideRow>> fetchFeatureOverrides() async {
    final res = await _client.rpc('rpc_history_feature_style_overrides_list_v1');
    return (res as List).map((raw) {
      final row = (raw as Map).cast<String, dynamic>();
      return HistoricalFeatureStyleOverrideRow(
        id: _toInt(row['id']) ?? 0,
        periodNo: _toInt(row['period_no']),
        periodTitleAr: row['period_label_ar']?.toString(),
        levelKey: (row['level_key'] ?? '').toString(),
        levelNameAr: (row['level_label_ar'] ?? row['level_key'] ?? '').toString(),
        sourceTable: (row['source_table'] ?? '').toString(),
        sourceId: (row['source_id'] ?? '').toString(),
        profileKey: row['profile_key']?.toString(),
        profileNameAr: row['profile_name_ar']?.toString(),
        overrideStyleJson: _castJson(row['override_style_json']),
        isActive: row['is_active'] == true,
        notes: row['notes']?.toString(),
      );
    }).toList();
  }

  Future<void> saveProfile({
    String? originalProfileKey,
    required String profileKey,
    required String profileNameAr,
    String? profileNameEn,
    required String styleScope,
    required Map<String, dynamic> styleJson,
    required bool isSystem,
    required bool isActive,
    String? notes,
  }) async {
    final targetKey = originalProfileKey ?? profileKey;

    if (originalProfileKey != null && originalProfileKey != profileKey) {
      await _client.rpc(
        'rpc_history_style_profile_delete_v1',
        params: {'p_profile_key': originalProfileKey},
      );
    }

    await _client.rpc(
      'rpc_history_style_profile_upsert_v1',
      params: {
        'p_profile_key': targetKey == originalProfileKey ? targetKey : profileKey,
        'p_profile_name_ar': profileNameAr,
        'p_profile_name_en': profileNameEn,
        'p_style_scope': styleScope,
        'p_style_json': styleJson,
        'p_is_system': isSystem,
        'p_is_active': isActive,
        'p_notes': notes,
      },
    );
  }

  Future<void> deleteProfile(String profileKey) async {
    await _client.rpc(
      'rpc_history_style_profile_delete_v1',
      params: {'p_profile_key': profileKey},
    );
  }

  Future<void> saveLevelDefault({
    required String levelKey,
    String? profileKey,
    required Map<String, dynamic> overrideStyleJson,
    required bool isActive,
    String? notes,
  }) async {
    await _client.rpc(
      'rpc_history_level_style_default_upsert_v1',
      params: {
        'p_level_key': levelKey,
        'p_profile_key': profileKey,
        'p_override_style_json': overrideStyleJson,
        'p_is_active': isActive,
        'p_notes': notes,
      },
    );
  }

  Future<void> savePeriodLevelOverride({
    required int periodNo,
    required String levelKey,
    String? profileKey,
    required Map<String, dynamic> overrideStyleJson,
    required bool isActive,
    String? notes,
  }) async {
    await _client.rpc(
      'rpc_history_period_level_style_upsert_v1',
      params: {
        'p_period_no': periodNo,
        'p_level_key': levelKey,
        'p_profile_key': profileKey,
        'p_override_style_json': overrideStyleJson,
        'p_is_active': isActive,
        'p_notes': notes,
      },
    );
  }

  Future<void> deletePeriodLevelOverride({
    required int periodNo,
    required String levelKey,
  }) async {
    await _client.rpc(
      'rpc_history_period_level_style_delete_v1',
      params: {
        'p_period_no': periodNo,
        'p_level_key': levelKey,
      },
    );
  }

  Future<void> saveFeatureOverride({
    int? id,
    int? periodNo,
    required String levelKey,
    required String sourceTable,
    required String sourceId,
    String? profileKey,
    required Map<String, dynamic> overrideStyleJson,
    required bool isActive,
    String? notes,
  }) async {
    await _client.rpc(
      'rpc_history_feature_style_override_upsert_v1',
      params: {
        'p_id': id,
        'p_period_no': periodNo,
        'p_level_key': levelKey,
        'p_source_table': sourceTable,
        'p_source_id': sourceId,
        'p_profile_key': profileKey,
        'p_override_style_json': overrideStyleJson,
        'p_is_active': isActive,
        'p_notes': notes,
      },
    );
  }

  Future<void> deleteFeatureOverride(int id) async {
    await _client.rpc(
      'rpc_history_feature_style_override_delete_v1',
      params: {'p_id': id},
    );
  }
}
