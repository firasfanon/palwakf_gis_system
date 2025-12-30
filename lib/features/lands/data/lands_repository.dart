// lib/features/lands/data/lands_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/waqf_land.dart';

abstract class ILandsRepository {
  Future<List<WaqfLand>> getLands({
    String? searchQuery,
    int limit,
    int offset,
  });

  Future<WaqfLand?> getLandById(int id);

  Future<WaqfLand> createLand(WaqfLand land);

  Future<WaqfLand> updateLand(WaqfLand land);

  Future<void> deleteLand(int id);
}

class SupabaseLandsRepository implements ILandsRepository {
  SupabaseLandsRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'waqf_lands';

  @override
  Future<List<WaqfLand>> getLands({
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client.from(_table).select();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or(
        'pwf_code.ilike.%$q%,name_ar.ilike.%$q%,name_en.ilike.%$q%',
      );
    }

    final from = offset;
    final to = offset + limit - 1;

    final data = await query.range(from, to);

    final list = List<Map<String, dynamic>>.from(data as List);
    return list.map(WaqfLand.fromMap).toList();
  }

  @override
  Future<WaqfLand?> getLandById(int id) async {
    final data =
    await _client.from(_table).select().eq('id', id).maybeSingle();

    if (data == null) return null;
    return WaqfLand.fromMap(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<WaqfLand> createLand(WaqfLand land) async {
    final insertData = land.toMapForInsert();
    final data = await _client
        .from(_table)
        .insert(insertData)
        .select()
        .single();

    return WaqfLand.fromMap(Map<String, dynamic>.from(data as Map));
  }

  @override
  @override
  Future<WaqfLand> updateLand(WaqfLand land) async {
    if (land.id == null) {
      throw ArgumentError('updateLand requires land.id to be non-null');
    }

    final updateData = land.toMapForUpdate();
    final data = await _client
        .from(_table)
        .update(updateData)
        .eq('id', land.id!) // لاحظ علامة التعجب هنا
        .select()
        .single();

    return WaqfLand.fromMap(Map<String, dynamic>.from(data as Map));
  }


  @override
  Future<void> deleteLand(int id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
