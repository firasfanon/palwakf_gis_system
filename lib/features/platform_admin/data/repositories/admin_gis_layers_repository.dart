// lib/features/platform_admin/data/repositories/admin_gis_layers_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/admin_gis_layer_row.dart';

final adminGisLayersRepositoryProvider =
    Provider<AdminGisLayersRepository>((ref) {
  return AdminGisLayersRepository(ref.watch(supabaseClientProvider));
});

class AdminGisLayersRepository {
  final SupabaseClient _client;
  AdminGisLayersRepository(this._client);

  Never _rethrowFriendly(Object error) {
    if (error is PostgrestException && error.code == '42501') {
      throw StateError(
          'صلاحية التعديل على gis.gis_layers غير مفعلة للمستخدم الحالي. '
          'نفّذ أولًا ملف SQL: lib/SQL/patch_gis_layers_admin_grants_v43.sql '
          'ثم تأكد من تطبيق سياسات RLS في lib/SQL/patch_gis_layers_admin_rls.sql.');
    }
    throw error;
  }

  Future<List<AdminGisLayerRow>> fetchAll() async {
    final q = _client.schema('gis').from('gis_layers').select();
    try {
      final res = await q.order('category').order('display_order').order('key');
      return (res as List)
          .map((e) =>
              AdminGisLayerRow.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      // Backward compatible when display_order doesn't exist yet.
      final res = await q.order('category').order('key');
      return (res as List)
          .map((e) =>
              AdminGisLayerRow.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }
  }

  /// Move a layer within its category (display_order swap) using RPC.
  ///
  /// NOTE: Call RPC name without schema prefix.
  Future<void> moveLayer({
    required String layerId,
    required int dir,
  }) async {
    await _client.schema('gis').rpc('rpc_gis_layers_move', params: {
      'p_layer_id': layerId,
      'p_dir': dir,
    });
  }

  /// Sync missing geometry tables/views from schema into gis.gis_layers.
  /// Returns number of inserted definitions.
  Future<int> syncLayersFromSchema({
    String schema = 'gis',
    String unitId = '00000000-0000-0000-0000-000000000000',
  }) async {
    final res =
        await _client.schema('gis').rpc('rpc_sync_layers_from_schema', params: {
      'p_schema': schema,
      'p_unit_id': unitId,
    });
    if (res is num) return res.toInt();
    return int.tryParse('$res') ?? 0;
  }

  Future<void> setFlags({
    required AdminGisLayerRow layer,
    bool? isPublic,
    bool? isActive,
  }) async {
    final patch = <String, dynamic>{
      if (isPublic != null) 'is_public': isPublic,
      if (isActive != null) 'is_active': isActive,
    };
    if (patch.isEmpty) return;

    try {
      PostgrestFilterBuilder<dynamic> q =
          _client.schema('gis').from('gis_layers').update(patch);

      final id = layer.id;
      final unitId = layer.unitId;

      if (id != null && id.isNotEmpty) {
        q = q.eq('id', id);
      } else {
        q = q.eq('key', layer.key);
        if (unitId != null && unitId.isNotEmpty) {
          q = q.eq('unit_id', unitId);
        }
      }

      await q;
    } catch (error) {
      _rethrowFriendly(error);
    }
  }

  Future<void> updateLayerSettings({
    required AdminGisLayerRow layer,
    String? nameAr,
    String? nameEn,
    LayerCategory? category,
    double? defaultOpacity,
    bool? compareEnabled,
  }) async {
    final nextStyle = Map<String, dynamic>.from(layer.style);
    if (defaultOpacity != null) {
      nextStyle['defaultOpacity'] = defaultOpacity.clamp(0.1, 1.0);
    }
    if (compareEnabled != null) {
      nextStyle['compareEnabled'] = compareEnabled;
    }

    final patch = <String, dynamic>{
      if (nameAr != null) 'name_ar': nameAr.trim(),
      if (nameEn != null)
        'name_en': nameEn.trim().isEmpty ? null : nameEn.trim(),
      if (category != null) 'category': category.name,
      'style': nextStyle,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _updateLayer(layer, patch);
  }

  Future<void> resetLayerStyleDefaults({
    required AdminGisLayerRow layer,
  }) async {
    final style = Map<String, dynamic>.from(layer.style);
    style['defaultOpacity'] = 1.0;
    if (layer.isRasterXyz && layer.category != LayerCategory.core) {
      style['compareEnabled'] = true;
    } else {
      style.remove('compareEnabled');
    }
    await _updateLayer(layer, {
      'style': style,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> _updateLayer(
      AdminGisLayerRow layer, Map<String, dynamic> patch) async {
    try {
      PostgrestFilterBuilder<dynamic> q =
          _client.schema('gis').from('gis_layers').update(patch);
      final id = layer.id;
      final unitId = layer.unitId;
      if (id != null && id.isNotEmpty) {
        q = q.eq('id', id);
      } else {
        q = q.eq('key', layer.key);
        if (unitId != null && unitId.isNotEmpty) {
          q = q.eq('unit_id', unitId);
        }
      }
      await q;
    } catch (error) {
      _rethrowFriendly(error);
    }
  }

  /// Bulk update flags for multiple layers.
  ///
  /// Uses `id IN (...)` when possible to reduce requests.
  /// Falls back to per-row update if `id` is missing.
  Future<void> bulkSetFlags({
    required List<AdminGisLayerRow> layers,
    bool? isPublic,
    bool? isActive,
  }) async {
    final patch = <String, dynamic>{
      if (isPublic != null) 'is_public': isPublic,
      if (isActive != null) 'is_active': isActive,
    };
    if (patch.isEmpty || layers.isEmpty) return;

    final ids = layers
        .map((l) => l.id)
        .where((id) => id != null && id!.isNotEmpty)
        .map((id) => id!)
        .toList();

    // Update in chunks to avoid overly long requests.
    const chunkSize = 100;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(
          i, (i + chunkSize) > ids.length ? ids.length : (i + chunkSize));
      if (chunk.isEmpty) continue;

      try {
        PostgrestFilterBuilder<dynamic> q =
            _client.schema('gis').from('gis_layers').update(patch);
        q = q.inFilter('id', chunk);
        await q;
      } catch (error) {
        _rethrowFriendly(error);
      }
    }

    // Fallback for rows without id
    final withoutId =
        layers.where((l) => l.id == null || l.id!.isEmpty).toList();
    for (final l in withoutId) {
      await setFlags(layer: l, isPublic: isPublic, isActive: isActive);
    }
  }
}
