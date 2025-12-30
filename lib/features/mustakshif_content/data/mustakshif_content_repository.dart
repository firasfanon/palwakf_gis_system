import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums/mustakshif_content_type.dart';
import '../domain/enums/mustakshif_publish_status.dart';
import '../domain/models/mustakshif_content_item.dart';


class MustakshifContentRepository {
  MustakshifContentRepository(this._client);

  final SupabaseClient _client;

  Future<List<MustakshifContentItem>> fetchList({
    required MustakshifContentType type,
    required bool adminMode,
    int? historicalPeriodId,
    int limit = 50,
    int offset = 0,
  }) async {
    final table = type.tableName;

    final query = _client.from(table).select();

    // Soft delete filter
    query.isFilter('deleted_at', null);

    if (historicalPeriodId != null) {
      query.eq('historical_period_id', historicalPeriodId);
    }

    if (!adminMode) {
      query.eq('status', MustakshifPublishStatus.published.value);
      // publish_date <= now OR null
      query.or('publish_date.is.null,publish_date.lte.${DateTime.now().toUtc().toIso8601String()}');
      if (type == MustakshifContentType.announcements) {
        // not expired
        query.or('expire_at.is.null,expire_at.gt.${DateTime.now().toUtc().toIso8601String()}');
      }
    }

    if (type == MustakshifContentType.announcements) {
      query.order('is_pinned', ascending: false);
      query.order('priority', ascending: false);
      query.order('publish_date', ascending: false, nullsFirst: false);
      query.order('created_at', ascending: false);
    } else {
      query.order('publish_date', ascending: false, nullsFirst: false);
      query.order('created_at', ascending: false);
    }

    if (limit <= 0) return <MustakshifContentItem>[];
    final from = offset < 0 ? 0 : offset;
    final to = from + limit - 1;
    query.range(from, to);

    final res = await query;
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map((m) => MustakshifContentItem.fromMap(type, m)).toList();
  }

  Future<MustakshifContentItem?> fetchById({
    required MustakshifContentType type,
    required String id,
  }) async {
    final table = type.tableName;
    final res = await _client
        .from(table)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (res == null) return null;
    return MustakshifContentItem.fromMap(type, (res as Map).cast<String, dynamic>());
  }

  Future<MustakshifContentItem> upsert({
    required MustakshifContentItem item,
  }) async {
    final table = item.type.tableName;

    final payload = <String, dynamic>{
      'id': item.id, // will be ignored if empty/invalid; admin screens will generate temp id for new.
      ...item.toUpsertMap(),
    }..removeWhere((k, v) => v == null);

    // If id is empty (new item), omit id entirely to let DB generate uuid.
    if (payload['id'] == '') {
      payload.remove('id');
    }

    final res = await _client.from(table).upsert(payload).select().single();
    return MustakshifContentItem.fromMap(item.type, (res as Map).cast<String, dynamic>());
  }

  Future<void> softDelete({
    required MustakshifContentType type,
    required String id,
  }) async {
    final table = type.tableName;
    await _client
        .from(table)
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }
}
